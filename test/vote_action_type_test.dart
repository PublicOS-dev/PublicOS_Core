// The Dart `VoteActionType` enum is a hand-kept mirror of the Solidity
// `IOrgManager.VoteActionType`. Every vote call sends `chainIndex`, so a shifted
// mirror sends the wrong vote. These pins are read off IOrgManager.sol; when the
// Solidity enum changes, change them in the same pass.

import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:publicos_core/src/core/extensions/publicos_governance.dart';

Uint8List _hex(String h) {
  final out = Uint8List(h.length ~/ 2);
  for (var i = 0; i < out.length; i++) {
    out[i] = int.parse(h.substring(i * 2, i * 2 + 2), radix: 16);
  }
  return out;
}

void main() {
  group('VoteActionType mirrors IOrgManager.VoteActionType', () {
    test('61 values, 0..60', () {
      expect(VoteActionType.values.length, 61);
    });

    test('positions across the whole list', () {
      const pins = <VoteActionType, int>{
        VoteActionType.setRecord: 0,
        VoteActionType.deleteRecord: 1,
        VoteActionType.addMember: 2,
        VoteActionType.setThreshold: 4,
        VoteActionType.executeSafeTx: 5,
        VoteActionType.registerAdditionalWallet: 9,
        VoteActionType.changeSafeThreshold: 15,
        VoteActionType.removeAppPointer: 20,
        VoteActionType.registerBSP: 21,
        VoteActionType.removeSocialServerPointer: 30,
        VoteActionType.requestParent: 31,
        VoteActionType.executeOnDescendantSafe: 35,
        VoteActionType.executeOnDescendant: 36,
        VoteActionType.removeAllVouches: 37,
        VoteActionType.accountCreationPaused: 42,
        VoteActionType.createOrgSubdomain: 43,
        VoteActionType.executeOnOwnSubSafe: 46,
        VoteActionType.setMultipleRecords: 47,
        VoteActionType.payDomain: 48,
        VoteActionType.changeName: 49,
        VoteActionType.setQuorumBps: 50,
        VoteActionType.setVoteDuration: 51,
        VoteActionType.setMaxOpenVotes: 52,
        VoteActionType.setWaitFullPeriod: 53,
        VoteActionType.payPenalties: 54,
        VoteActionType.setChildLock: 55,
        VoteActionType.setProposerCap: 56,
        VoteActionType.setVetoer: 57,
        VoteActionType.cancelVote: 58,
        VoteActionType.setCancelCooldown: 59,
        VoteActionType.deleteMultipleRecords: 60,
      };
      pins.forEach((type, n) {
        expect(type.index, n, reason: type.name);
        expect(type.chainIndex, BigInt.from(n), reason: type.name);
      });
    });
  });

  group('DELETE_MULTIPLE_RECORDS key list', () {
    // ethers: AbiCoder.encode(["string[]"], [["d1", "d3", "never-set"]])
    const reference =
        '0000000000000000000000000000000000000000000000000000000000000020'
        '0000000000000000000000000000000000000000000000000000000000000003'
        '0000000000000000000000000000000000000000000000000000000000000060'
        '00000000000000000000000000000000000000000000000000000000000000a0'
        '00000000000000000000000000000000000000000000000000000000000000e0'
        '0000000000000000000000000000000000000000000000000000000000000002'
        '6431000000000000000000000000000000000000000000000000000000000000'
        '0000000000000000000000000000000000000000000000000000000000000002'
        '6433000000000000000000000000000000000000000000000000000000000000'
        '0000000000000000000000000000000000000000000000000000000000000009'
        '6e657665722d7365740000000000000000000000000000000000000000000000';
    const keys = ['d1', 'd3', 'never-set'];

    test('encodes like abi.encode(string[])', () {
      expect(PublicOSGovernance.encodeDeleteRecordKeys(keys), _hex(reference));
    });

    test('decodes the same bytes back', () {
      expect(PublicOSGovernance.decodeDeleteRecordKeys(_hex(reference)), keys);
    });

    test('bytes that are not a key list decode to nothing', () {
      expect(PublicOSGovernance.decodeDeleteRecordKeys(const []), isEmpty);
      expect(PublicOSGovernance.decodeDeleteRecordKeys(const [1, 2, 3]), isEmpty);
    });
  });
}
