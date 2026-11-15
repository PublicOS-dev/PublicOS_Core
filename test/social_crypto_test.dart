// The device side of social-push privacy, checked against the server side:
// a blob the home sealed (Go, crypto/aes + cipher.NewGCM, the layout of
// my_rss_server internal/notif/blob.go) opens here with the same K_s, and the
// envelope a throwaway key signs recovers to that key.

import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/src/models/activity_event.dart';
import 'package:publicos_core/src/models/social_notification.dart';
import 'package:publicos_core/src/utils/social_crypto.dart';
import 'package:web3dart/web3dart.dart'
    show
        MsgSignature,
        bytesToHex,
        bytesToUnsignedInt,
        ecRecover,
        hexToBytes,
        keccak256,
        publicKeyToAddress;

void main() {
  // Produced by Go's standard library with key = 32 × 0x11 and nonce 1..12
  // (scratch generator, same layout as the home's SealBlob).
  const goBlob =
      'AQIDBAUGBwgJCgsMht0HxgQS0Iu7K/gweuvFa6uArc6uzRXc/BNoTcdA1SqFtpUUt2mPLl33HMHDmtb3V8Qf72y0+s9k3cWHbqvo1b8EyXGJJCabqpbSYAXLq9y1pK+3UtTrSuLDOFgmiYwLNH5nf/eGTXb1E98bIjrKSqGmSodltuFWNMYcAeoIBbp/J9cOki3Q7QbdhvGMUSlGy2gtbWjCcqy8Nm0zH3PBe1gK9moq9zK0gqG2Jm3s7XsheqCv4c8Aa2KUtdLNT4nMEu03ZrRLFV3Yj7QyPw==';
  const plain =
      '{"kind":"reply","actor":"0x00000000000000000000000000000000000000B0","post_url":"https://d/p","item_url":"https://d/p#comment-1","inbox":"https://home","occurred_at":"2026-10-22T21:14:00Z"}';
  final key = Uint8List.fromList(List<int>.filled(32, 0x11));

  test('a blob sealed by the home (Go) opens with the same K_s', () {
    final fields = SocialCrypto.openBlobJson(key, goBlob);
    expect(fields['kind'], 'reply');
    expect(fields['actor'], '0x00000000000000000000000000000000000000B0');
    expect(fields['item_url'], 'https://d/p#comment-1');
    expect(fields['inbox'], 'https://home');
    expect(fields['occurred_at'], '2026-10-22T21:14:00Z');
  });

  test('a wrong key or a tampered blob does not open', () {
    final other = Uint8List.fromList(List<int>.filled(32, 0x22));
    expect(() => SocialCrypto.openBlob(other, goBlob), throwsA(anything));
    final raw = base64.decode(goBlob);
    raw[20] ^= 0x01;
    expect(() => SocialCrypto.openBlob(key, base64.encode(raw)),
        throwsA(anything));
    expect(() => SocialCrypto.openBlob(key.sublist(0, 16), goBlob),
        throwsArgumentError);
  });

  test('seal then open round-trips with a fresh nonce each time', () {
    final k = SocialCrypto.newKey();
    final a = SocialCrypto.sealBlob(k, utf8.encode('{"kind":"comment"}'));
    final b = SocialCrypto.sealBlob(k, utf8.encode('{"kind":"comment"}'));
    expect(a, isNot(b));
    expect(utf8.decode(SocialCrypto.openBlob(k, a)), '{"kind":"comment"}');
    expect(utf8.decode(SocialCrypto.openBlob(k, b)), '{"kind":"comment"}');
  });

  test('the Go layout is reproduced byte for byte with a fixed nonce', () {
    final nonce = Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]);
    expect(
        SocialCrypto.sealBlob(key, utf8.encode(plain), nonce: nonce), goBlob);
  });

  test(
      'an envelope signed by R recovers to R, names no account, sorts nested maps',
      () {
    final r = SocialCrypto.newThrowawayKey();
    const ticket = NotifTicket(
        handle: 'h',
        rPub: '0x00000000000000000000000000000000000000A1',
        slug: 'home',
        exp: 1761350400,
        sig: '0xdead');
    final env = SocialCrypto.envelopeSignedBy(
      r,
      action: 'social_register',
      target: 'POST push.publicos.dev/social/register',
      nonce: 'abcd',
      timestamp: 1761350000,
      data: {
        'token': 't',
        'handle': 'h',
        'ticket': ticket.toJson(),
        'kind': 'fcm'
      },
    );
    expect(env['session'], r.address.eip55With0x);
    expect(jsonEncode(env).contains('account_address'), isFalse);
    // Keys sorted at every level, as Go marshals them.
    final data = env['data'] as Map<String, dynamic>;
    expect(data.keys.toList(), ['handle', 'kind', 'ticket', 'token']);
    expect((data['ticket'] as Map).keys.toList(),
        ['exp', 'handle', 'r_pub', 'sig', 'slug']);
    // The signature recovers to R over the canonical bytes.
    final signed = Map<String, dynamic>.from(env)..remove('signature');
    final msg = utf8.encode(jsonEncode(signed));
    final prefix = utf8.encode('\x19Ethereum Signed Message:\n${msg.length}');
    final hash = keccak256(Uint8List.fromList([...prefix, ...msg]));
    final sigBytes = hexToBytes(env['signature'] as String);
    final v = sigBytes[64] >= 27 ? sigBytes[64] : sigBytes[64] + 27;
    final pub = ecRecover(
        hash,
        MsgSignature(bytesToUnsignedInt(sigBytes.sublist(0, 32)),
            bytesToUnsignedInt(sigBytes.sublist(32, 64)), v));
    expect(bytesToHex(publicKeyToAddress(pub), include0x: true).toLowerCase(),
        r.address.eip55With0x.toLowerCase());
  });

  test('ActivityEvent.social maps a blob or an inbox row to one row shape', () {
    final ev = ActivityEvent.social({
      'id': 'host:1',
      'from': 'host',
      'kind': 'reply',
      'actor': '0x00000000000000000000000000000000000000B0',
      'post_url': 'https://d/p',
      'item_url': 'https://d/p#comment-1',
      'occurred_at': '2026-10-22T21:14:00Z',
      'seq': 7,
    });
    expect(ev.eventType, 'social_reply');
    expect(ActivityEventType.isSocial(ev.eventType), isTrue);
    expect(ActivityEventType.socialKind(ev.eventType), 'reply');
    expect(ev.txHash, 'host:1');
    expect(ev.logIndex, 0);
    expect(ev.data['seq'], 7);
    expect(ev.data['item_url'], 'https://d/p#comment-1');
    expect(ev.timestamp,
        DateTime.utc(2026, 10, 22, 21, 14).millisecondsSinceEpoch);
    final n = SocialNotification.fromJson({
      'seq': 7,
      'id': 'host:1',
      'from': 'host',
      'kind': 'reply',
      'actor': '0x00000000000000000000000000000000000000B0',
      'post_url': 'https://d/p',
      'item_url': 'https://d/p#comment-1',
      'occurred_at': '2026-10-22T21:14:00Z',
      'received_at': '2026-10-22T21:14:01Z',
      'read': false,
    });
    final fromRow = ActivityEvent.social(n.toPushData());
    expect(fromRow.txHash, ev.txHash);
    expect(fromRow.eventType, ev.eventType);
    expect(fromRow.timestamp, ev.timestamp);
  });

  test('NotifTarget.wants defaults reactions off and the rest on', () {
    const t = NotifTarget(
        id: 'x',
        label: 'PublicOS',
        gateway: 'https://push.publicos.dev',
        handle: 'h',
        enabled: true,
        kinds: {},
        removable: false);
    expect(t.wants(SocialNotificationKind.reaction), isFalse);
    expect(t.wants(SocialNotificationKind.reply), isTrue);
    final t2 = NotifTarget.fromJson({
      'id': 'x',
      'gateway': 'g',
      'handle': 'h',
      'kinds': {'reaction': true, 'reply': false},
      'removable': true,
      'ticket': {
        'handle': 'h',
        'r_pub': '0x00000000000000000000000000000000000000A1',
        'slug': 's',
        'exp': 1761350400,
        'sig': '0x00'
      }
    });
    expect(t2.wants('reaction'), isTrue);
    expect(t2.wants('reply'), isFalse);
    expect(t2.ticket!.slug, 's');
    expect(t2.ticket!.isExpired, isTrue);
  });
}
