// @dart=3.0
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_local_variable, unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark
// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:web3dart/web3dart.dart' as _i1;
import 'package:wallet/wallet.dart' as _i2;
import 'dart:typed_data' as _i3;

final _contractAbi = _i1.ContractAbi.fromJson(
  '[{"inputs":[{"internalType":"address","name":"_moduleRegistryAddress","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newMax","type":"uint256"}],"name":"Memory_MaxWalletsPerAccountSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"walletKey","type":"bytes32"},{"indexed":true,"internalType":"address","name":"account","type":"address"}],"name":"Memory_OwnerByAddressSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"protocol","type":"bytes32"},{"indexed":false,"internalType":"bool","name":"registered","type":"bool"}],"name":"Memory_ProtocolRegistered","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":true,"internalType":"uint256","name":"index","type":"uint256"}],"name":"Memory_WalletLabelUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":true,"internalType":"uint256","name":"index","type":"uint256"}],"name":"Memory_WalletPopped","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":true,"internalType":"bytes32","name":"walletKey","type":"bytes32"},{"indexed":false,"internalType":"bytes32","name":"protocol","type":"bytes32"},{"indexed":false,"internalType":"uint64","name":"chainId","type":"uint64"}],"name":"Memory_WalletPushed","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":true,"internalType":"uint256","name":"index","type":"uint256"},{"indexed":false,"internalType":"enum IWalletDirectoryMemory.WalletType","name":"walletType","type":"uint8"}],"name":"Memory_WalletTypeUpdated","type":"event"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"index","type":"uint256"}],"name":"getWalletAt","outputs":[{"components":[{"internalType":"bytes32","name":"protocol","type":"bytes32"},{"internalType":"bytes","name":"addressData","type":"bytes"},{"internalType":"uint64","name":"chainId","type":"uint64"},{"internalType":"string","name":"label","type":"string"},{"internalType":"enum IWalletDirectoryMemory.WalletType","name":"walletType","type":"uint8"},{"internalType":"bytes","name":"proof","type":"bytes"},{"internalType":"enum IWalletDirectoryMemory.Verification","name":"verification","type":"uint8"}],"internalType":"struct IWalletDirectoryMemory.Wallet","name":"","type":"tuple"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"getWalletCount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"getWalletsAt","outputs":[{"components":[{"internalType":"bytes32","name":"protocol","type":"bytes32"},{"internalType":"bytes","name":"addressData","type":"bytes"},{"internalType":"uint64","name":"chainId","type":"uint64"},{"internalType":"string","name":"label","type":"string"},{"internalType":"enum IWalletDirectoryMemory.WalletType","name":"walletType","type":"uint8"},{"internalType":"bytes","name":"proof","type":"bytes"},{"internalType":"enum IWalletDirectoryMemory.Verification","name":"verification","type":"uint8"}],"internalType":"struct IWalletDirectoryMemory.Wallet[]","name":"","type":"tuple[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"maxWalletsPerAccount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleRegistry","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleType","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"name":"ownerByAddress","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"index","type":"uint256"}],"name":"popAndSwapWalletAt","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"components":[{"internalType":"bytes32","name":"protocol","type":"bytes32"},{"internalType":"bytes","name":"addressData","type":"bytes"},{"internalType":"uint64","name":"chainId","type":"uint64"},{"internalType":"string","name":"label","type":"string"},{"internalType":"enum IWalletDirectoryMemory.WalletType","name":"walletType","type":"uint8"},{"internalType":"bytes","name":"proof","type":"bytes"},{"internalType":"enum IWalletDirectoryMemory.Verification","name":"verification","type":"uint8"}],"internalType":"struct IWalletDirectoryMemory.Wallet","name":"wallet","type":"tuple"}],"name":"pushWalletData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"name":"registeredProtocols","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"uint256","name":"newMax","type":"uint256"}],"name":"setMaxWalletsPerAccountData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"walletKey","type":"bytes32"},{"internalType":"address","name":"account","type":"address"}],"name":"setOwnerByAddressData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"protocol","type":"bytes32"},{"internalType":"bool","name":"registered","type":"bool"}],"name":"setRegisteredProtocolData","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"index","type":"uint256"},{"internalType":"string","name":"newLabel","type":"string"}],"name":"updateWalletLabelAt","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"uint256","name":"index","type":"uint256"},{"internalType":"enum IWalletDirectoryMemory.WalletType","name":"newType","type":"uint8"}],"name":"updateWalletTypeAt","outputs":[],"stateMutability":"nonpayable","type":"function"}]',
  'WalletDirectoryMemory',
);

class WalletDirectoryMemory extends _i1.GeneratedContract {
  WalletDirectoryMemory({
    required _i2.EthereumAddress address,
    required _i1.Web3Client client,
    int? chainId,
  }) : super(
          _i1.DeployedContract(
            _contractAbi,
            address,
          ),
          client,
          chainId,
        );

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<dynamic> getWalletAt(
    ({_i2.EthereumAddress account, BigInt index}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '2d0bb75b'));
    final params = [
      args.account,
      args.index,
    ];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as dynamic);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> getWalletCount(
    ({_i2.EthereumAddress account}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, '878023d4'));
    final params = [args.account];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<dynamic> getWalletsAt(
    ({_i2.EthereumAddress account}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, '023144ee'));
    final params = [args.account];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as dynamic);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> maxWalletsPerAccount(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, '3b8ef8bb'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as BigInt);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i2.EthereumAddress> moduleRegistry(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, 'b95459e4'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i2.EthereumAddress);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i3.Uint8List> moduleType(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, '6465e69f'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i3.Uint8List);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i2.EthereumAddress> ownerByAddress(
    ({_i3.Uint8List arg0}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, 'adab500c'));
    final params = [args.arg0];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i2.EthereumAddress);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> popAndSwapWalletAt(
    ({_i2.EthereumAddress account, BigInt index}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, '11b4c692'));
    final params = [
      args.account,
      args.index,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> pushWalletData(
    ({_i2.EthereumAddress account, dynamic wallet}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[9];
    assert(checkSignature(function, 'd1e727c3'));
    final params = [
      args.account,
      args.wallet,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> registeredProtocols(
    ({_i3.Uint8List arg0}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[10];
    assert(checkSignature(function, '946b56c2'));
    final params = [args.arg0];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> setMaxWalletsPerAccountData(
    ({BigInt newMax}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[11];
    assert(checkSignature(function, '880ef962'));
    final params = [args.newMax];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> setOwnerByAddressData(
    ({_i3.Uint8List walletKey, _i2.EthereumAddress account}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[12];
    assert(checkSignature(function, '2270730c'));
    final params = [
      args.walletKey,
      args.account,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> setRegisteredProtocolData(
    ({_i3.Uint8List protocol, bool registered}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[13];
    assert(checkSignature(function, '22e3f03d'));
    final params = [
      args.protocol,
      args.registered,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> updateWalletLabelAt(
    ({_i2.EthereumAddress account, BigInt index, String newLabel}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[14];
    assert(checkSignature(function, '621c64b5'));
    final params = [
      args.account,
      args.index,
      args.newLabel,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> updateWalletTypeAt(
    ({_i2.EthereumAddress account, BigInt index, BigInt newType}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[15];
    assert(checkSignature(function, 'b3e08008'));
    final params = [
      args.account,
      args.index,
      args.newType,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// Returns a live stream of all Memory_MaxWalletsPerAccountSet events emitted by this contract.
  Stream<Memory_MaxWalletsPerAccountSet> memory_MaxWalletsPerAccountSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_MaxWalletsPerAccountSet');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_MaxWalletsPerAccountSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_OwnerByAddressSet events emitted by this contract.
  Stream<Memory_OwnerByAddressSet> memory_OwnerByAddressSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_OwnerByAddressSet');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_OwnerByAddressSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_ProtocolRegistered events emitted by this contract.
  Stream<Memory_ProtocolRegistered> memory_ProtocolRegisteredEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_ProtocolRegistered');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_ProtocolRegistered(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_WalletLabelUpdated events emitted by this contract.
  Stream<Memory_WalletLabelUpdated> memory_WalletLabelUpdatedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_WalletLabelUpdated');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_WalletLabelUpdated(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_WalletPopped events emitted by this contract.
  Stream<Memory_WalletPopped> memory_WalletPoppedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_WalletPopped');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_WalletPopped(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_WalletPushed events emitted by this contract.
  Stream<Memory_WalletPushed> memory_WalletPushedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_WalletPushed');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_WalletPushed(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all Memory_WalletTypeUpdated events emitted by this contract.
  Stream<Memory_WalletTypeUpdated> memory_WalletTypeUpdatedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('Memory_WalletTypeUpdated');
    final filter = _i1.FilterOptions.events(
      contract: self,
      event: event,
      fromBlock: fromBlock,
      toBlock: toBlock,
    );
    return client.events(filter).map((_i1.FilterEvent result) {
      final decoded = event.decodeResults(
        result.topics!,
        result.data!,
      );
      return Memory_WalletTypeUpdated(
        decoded,
        result,
      );
    });
  }
}

class Memory_MaxWalletsPerAccountSet {
  Memory_MaxWalletsPerAccountSet(
    List<dynamic> response,
    this.event,
  )   : newMax = (response[0] as BigInt);

  final BigInt newMax;

  final _i1.FilterEvent event;
}

class Memory_OwnerByAddressSet {
  Memory_OwnerByAddressSet(
    List<dynamic> response,
    this.event,
  )   : walletKey = (response[0] as _i3.Uint8List),
        account = (response[1] as _i2.EthereumAddress);

  final _i3.Uint8List walletKey;

  final _i2.EthereumAddress account;

  final _i1.FilterEvent event;
}

class Memory_ProtocolRegistered {
  Memory_ProtocolRegistered(
    List<dynamic> response,
    this.event,
  )   : protocol = (response[0] as _i3.Uint8List),
        registered = (response[1] as bool);

  final _i3.Uint8List protocol;

  final bool registered;

  final _i1.FilterEvent event;
}

class Memory_WalletLabelUpdated {
  Memory_WalletLabelUpdated(
    List<dynamic> response,
    this.event,
  )   : account = (response[0] as _i2.EthereumAddress),
        index = (response[1] as BigInt);

  final _i2.EthereumAddress account;

  final BigInt index;

  final _i1.FilterEvent event;
}

class Memory_WalletPopped {
  Memory_WalletPopped(
    List<dynamic> response,
    this.event,
  )   : account = (response[0] as _i2.EthereumAddress),
        index = (response[1] as BigInt);

  final _i2.EthereumAddress account;

  final BigInt index;

  final _i1.FilterEvent event;
}

class Memory_WalletPushed {
  Memory_WalletPushed(
    List<dynamic> response,
    this.event,
  )   : account = (response[0] as _i2.EthereumAddress),
        walletKey = (response[1] as _i3.Uint8List),
        protocol = (response[2] as _i3.Uint8List),
        chainId = (response[3] as BigInt);

  final _i2.EthereumAddress account;

  final _i3.Uint8List walletKey;

  final _i3.Uint8List protocol;

  final BigInt chainId;

  final _i1.FilterEvent event;
}

class Memory_WalletTypeUpdated {
  Memory_WalletTypeUpdated(
    List<dynamic> response,
    this.event,
  )   : account = (response[0] as _i2.EthereumAddress),
        index = (response[1] as BigInt),
        walletType = (response[2] as BigInt);

  final _i2.EthereumAddress account;

  final BigInt index;

  final BigInt walletType;

  final _i1.FilterEvent event;
}
