import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/src/models/message.dart';
import 'package:publicos_core/src/core/publicos_core.dart';

/// Tests for the message stream reconnection behavior.
///
/// These tests validate that:
/// 1. The broadcast messageStream delivers messages to listeners
/// 2. Stream closure (onDone) is detectable by consumers
/// 3. The stream status API works correctly
/// 4. Multiple listeners on the broadcast stream work independently
///
/// Note: Full integration tests of _subscribeToMessages() reconnection
/// require a live XMTP client. These tests validate the observable
/// stream behavior that consumers depend on.
void main() {
  group('Message broadcast stream behavior', () {
    late StreamController<Message> controller;

    setUp(() {
      // PublicOS uses a static broadcast StreamController.
      // We test the broadcast behavior pattern directly.
      controller = StreamController<Message>.broadcast();
    });

    tearDown(() {
      controller.close();
    });

    Message _makeMessage(String body, {int id = 1, String topic = 'test-topic'}) {
      return Message(
        id: id,
        idXmtp: 'xmtp-$id',
        xmtpConversationTopic: topic,
        timestamp: DateTime.now(),
        body: body,
        content: const MessageContent(type: MessageType.text, value: 'test'),
        senderAddress: '0xSender',
        senderInboxId: 'inbox-sender',
      );
    }

    test('broadcast stream delivers messages to single listener', () async {
      final messages = <Message>[];
      final sub = controller.stream.listen((msg) => messages.add(msg));

      controller.add(_makeMessage('hello'));
      controller.add(_makeMessage('world', id: 2));

      // Give microtasks time to process
      await Future.delayed(Duration.zero);

      expect(messages.length, 2);
      expect(messages[0].body, 'hello');
      expect(messages[1].body, 'world');

      await sub.cancel();
    });

    test('broadcast stream delivers to multiple independent listeners', () async {
      final listener1 = <Message>[];
      final listener2 = <Message>[];

      final sub1 = controller.stream.listen((msg) => listener1.add(msg));
      final sub2 = controller.stream.listen((msg) => listener2.add(msg));

      controller.add(_makeMessage('shared'));
      await Future.delayed(Duration.zero);

      expect(listener1.length, 1);
      expect(listener2.length, 1);
      expect(listener1[0].body, 'shared');
      expect(listener2[0].body, 'shared');

      // Cancel one listener, other should still receive
      await sub1.cancel();
      controller.add(_makeMessage('only-two', id: 2));
      await Future.delayed(Duration.zero);

      expect(listener1.length, 1); // No new message
      expect(listener2.length, 2); // Got the new message

      await sub2.cancel();
    });

    test('listener can detect stream errors', () async {
      final errors = <Object>[];
      final messages = <Message>[];

      final sub = controller.stream.listen(
        (msg) => messages.add(msg),
        onError: (e) => errors.add(e),
      );

      controller.add(_makeMessage('before-error'));
      controller.addError(Exception('connection lost'));
      controller.add(_makeMessage('after-error', id: 2));

      await Future.delayed(Duration.zero);

      expect(messages.length, 2);
      expect(errors.length, 1);
      expect(errors[0].toString(), contains('connection lost'));

      await sub.cancel();
    });
  });

  group('XMTP stream death simulation', () {
    test('source stream closing causes listener onDone to fire', () async {
      // Simulates what happens when XMTP Rust stream closes:
      // 1. Platform stream closes
      // 2. xmtp_flutter wrapper calls controller.close()
      // 3. Our subscription receives onDone

      final sourceController = StreamController<Map<String, dynamic>>();
      bool gotDone = false;
      int messageCount = 0;

      final sub = sourceController.stream.listen(
        (msg) => messageCount++,
        onDone: () => gotDone = true,
      );

      // Stream is alive, messages flow
      sourceController.add({'id': '1', 'body': 'hello'});
      await Future.delayed(Duration.zero);
      expect(messageCount, 1);
      expect(gotDone, false);

      // Stream dies (XMTP connection lost, app backgrounded, etc.)
      await sourceController.close();
      await Future.delayed(Duration.zero);

      expect(gotDone, true);
      await sub.cancel();
    });

    test('resubscribing after stream death restores message flow', () async {
      // Simulates the reconnection pattern:
      // 1. First stream works, then dies
      // 2. We create a new stream subscription
      // 3. Messages flow again

      StreamController<Map<String, dynamic>>? sourceController;
      StreamSubscription? activeSub;
      final allMessages = <Map<String, dynamic>>[];
      int doneCount = 0;

      void subscribe() {
        sourceController = StreamController<Map<String, dynamic>>();
        activeSub = sourceController!.stream.listen(
          (msg) => allMessages.add(msg),
          onDone: () {
            doneCount++;
            activeSub = null;
          },
        );
      }

      // First subscription
      subscribe();
      sourceController!.add({'id': '1', 'body': 'msg1'});
      await Future.delayed(Duration.zero);
      expect(allMessages.length, 1);

      // Stream dies
      await sourceController!.close();
      await Future.delayed(Duration.zero);
      expect(doneCount, 1);
      expect(activeSub, null);

      // Reconnect with new subscription
      subscribe();
      sourceController!.add({'id': '2', 'body': 'msg2-after-reconnect'});
      await Future.delayed(Duration.zero);
      expect(allMessages.length, 2);
      expect(allMessages[1]['body'], 'msg2-after-reconnect');

      // Clean up
      await sourceController!.close();
      await activeSub?.cancel();
    });

    test('broadcast stream survives source reconnection', () async {
      // The key insight: PublicOS.messageStreamController is a broadcast
      // controller that outlives the XMTP subscription. When the XMTP stream
      // dies and reconnects, the broadcast stream just keeps getting new
      // events pushed to it. Consumer listeners don't need to resubscribe.

      final broadcastController = StreamController<String>.broadcast();
      final consumerMessages = <String>[];

      // Consumer subscribes to the broadcast (like a chat screen)
      final consumerSub = broadcastController.stream.listen(
        (msg) => consumerMessages.add(msg),
      );

      // Simulate first XMTP source stream
      var source1 = StreamController<String>();
      var sourceSub = source1.stream.listen(
        (msg) => broadcastController.add(msg), // Forward to broadcast
        onDone: () {/* would trigger reconnect */},
      );

      source1.add('from-source-1');
      await Future.delayed(Duration.zero);
      expect(consumerMessages, ['from-source-1']);

      // Source stream dies
      await source1.close();
      await sourceSub.cancel();
      await Future.delayed(Duration.zero);

      // Reconnect: new source stream, same broadcast
      var source2 = StreamController<String>();
      sourceSub = source2.stream.listen(
        (msg) => broadcastController.add(msg),
        onDone: () {/* would trigger reconnect */},
      );

      source2.add('from-source-2-after-reconnect');
      await Future.delayed(Duration.zero);

      // Consumer got BOTH messages without resubscribing
      expect(consumerMessages, ['from-source-1', 'from-source-2-after-reconnect']);

      // Cleanup
      await consumerSub.cancel();
      await source2.close();
      await sourceSub.cancel();
      await broadcastController.close();
    });
  });

  group('PublicOS static stream state', () {
    test('messageStreamController is broadcast and persists', () {
      // The static stream is broadcast
      expect(PublicOS.messageStream.isBroadcast, true);
    });

    test('messageStream can be listened to multiple times', () {
      // Broadcast streams allow multiple simultaneous listeners
      final sub1 = PublicOS.messageStream.listen((_) {});
      final sub2 = PublicOS.messageStream.listen((_) {});

      // No exception thrown — both subscriptions active
      sub1.cancel();
      sub2.cancel();
    });

    test('messages pushed to controller reach stream listeners', () async {
      final received = <Message>[];
      final sub = PublicOS.messageStream.listen((msg) => received.add(msg));

      final testMessage = Message(
        id: 99,
        idXmtp: 'test-99',
        xmtpConversationTopic: 'test-topic',
        timestamp: DateTime.now(),
        body: 'stream test',
        content: const MessageContent(type: MessageType.text, value: 'test'),
        senderAddress: '0x123',
        senderInboxId: 'inbox-test',
      );

      PublicOS.messageStreamController.add(testMessage);
      await Future.delayed(Duration.zero);

      expect(received.length, 1);
      expect(received[0].body, 'stream test');
      expect(received[0].id, 99);

      await sub.cancel();
    });
  });

  group('Stream status API', () {
    test('PublicOSMessages exposes stream status getters', () {
      // These are compile-time checks that the API exists.
      // Full behavior requires XMTP client, so we just verify the API.
      expect(PublicOS.xmtpSubscription, isNull);
    });
  });
}
