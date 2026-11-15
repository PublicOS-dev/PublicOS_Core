import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/publicos_core.dart';
import 'package:http/http.dart' show Client;
import 'package:web3dart/web3dart.dart';

/// Provider allowlist: a root Safe transaction that changes a
/// BSP / SSP registry allowlist decodes to its method and arguments, so the
/// voting view can show it in words. Call data built from the binding's ABI.
void main() {
  final abi = BSPRegistryManager(
    address: EthereumAddress.fromHex('0x0000000000000000000000000000000000000001'),
    client: Web3Client('http://localhost', _NoHttp()),
  ).self.abi;
  const listed = '0x1234567890abcdef1234567890abcdef12345678';

  Map<String, dynamic> params(String fn, List<dynamic> args) => {
        'targetAddress': EthereumAddress.fromHex('0x0000000000000000000000000000000000000002'),
        'valueParam': BigInt.zero,
        'dataParam': abi.functions.firstWhere((f) => f.name == fn).encodeCall(args).toList(),
      };

  test('setRegistrationRestricted(true / false)', () {
    final on = SafeTransactionAnalyzer.analyzeTransaction(params('setRegistrationRestricted', [true]));
    expect(on.methodName, 'setRegistrationRestricted');
    expect(on.decodedParameters, {'restricted': true});
    final off = SafeTransactionAnalyzer.analyzeTransaction(params('setRegistrationRestricted', [false]));
    expect(off.decodedParameters, {'restricted': false});
  });

  test('setRegistrationAllowed(account, allowed)', () {
    final add = SafeTransactionAnalyzer.analyzeTransaction(
        params('setRegistrationAllowed', [EthereumAddress.fromHex(listed), true]));
    expect(add.methodName, 'setRegistrationAllowed');
    expect(add.decodedParameters, {'account': listed, 'allowed': true});
    final remove = SafeTransactionAnalyzer.analyzeTransaction(
        params('setRegistrationAllowed', [EthereumAddress.fromHex(listed), false]));
    expect(remove.decodedParameters, {'account': listed, 'allowed': false});
  });
}

class _NoHttp extends Fake implements Client {}
