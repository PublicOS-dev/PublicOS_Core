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
  '[{"inputs":[{"internalType":"address","name":"_moduleRegistryAddress","type":"address"}],"stateMutability":"nonpayable","type":"constructor"},{"inputs":[],"name":"AdminCapReached","type":"error"},{"inputs":[],"name":"AlreadyAdmin","type":"error"},{"inputs":[],"name":"ECDSAInvalidSignature","type":"error"},{"inputs":[{"internalType":"uint256","name":"length","type":"uint256"}],"name":"ECDSAInvalidSignatureLength","type":"error"},{"inputs":[{"internalType":"bytes32","name":"s","type":"bytes32"}],"name":"ECDSAInvalidSignatureS","type":"error"},{"inputs":[],"name":"InvalidAdmin","type":"error"},{"inputs":[],"name":"InvalidShortString","type":"error"},{"inputs":[],"name":"NotAdmin","type":"error"},{"inputs":[],"name":"NotAuthorized","type":"error"},{"inputs":[],"name":"RootNotResolvable","type":"error"},{"inputs":[{"internalType":"string","name":"str","type":"string"}],"name":"StringTooLong","type":"error"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"admin","type":"address"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"AdminAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"admin","type":"address"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"AdminRemoved","type":"event"},{"anonymous":false,"inputs":[],"name":"EIP712DomainChanged","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"bool","name":"on","type":"bool"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"InheritanceSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":false,"internalType":"uint256","name":"newMax","type":"uint256"}],"name":"MaxWalletsPerAccountSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"bytes32","name":"protocol","type":"bytes32"},{"indexed":false,"internalType":"bool","name":"registered","type":"bool"}],"name":"ProtocolRegistered","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":true,"internalType":"bytes32","name":"walletKey","type":"bytes32"},{"indexed":false,"internalType":"bytes32","name":"protocol","type":"bytes32"},{"indexed":false,"internalType":"uint64","name":"chainId","type":"uint64"},{"indexed":false,"internalType":"string","name":"label","type":"string"},{"indexed":false,"internalType":"enum IWalletDirectoryMemory.Verification","name":"verification","type":"uint8"}],"name":"WalletAdded","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":true,"internalType":"bytes32","name":"walletKey","type":"bytes32"},{"indexed":false,"internalType":"uint64","name":"chainId","type":"uint64"},{"indexed":true,"internalType":"address","name":"by","type":"address"}],"name":"WalletForceRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":true,"internalType":"bytes32","name":"walletKey","type":"bytes32"},{"indexed":false,"internalType":"uint64","name":"chainId","type":"uint64"},{"indexed":false,"internalType":"string","name":"oldLabel","type":"string"},{"indexed":false,"internalType":"string","name":"newLabel","type":"string"}],"name":"WalletLabelUpdated","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":true,"internalType":"bytes32","name":"walletKey","type":"bytes32"},{"indexed":false,"internalType":"uint64","name":"chainId","type":"uint64"}],"name":"WalletRemoved","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"internalType":"address","name":"account","type":"address"},{"indexed":true,"internalType":"bytes32","name":"walletKey","type":"bytes32"},{"indexed":false,"internalType":"uint64","name":"chainId","type":"uint64"},{"indexed":false,"internalType":"enum IWalletDirectoryMemory.WalletType","name":"oldWalletType","type":"uint8"},{"indexed":false,"internalType":"enum IWalletDirectoryMemory.WalletType","name":"newWalletType","type":"uint8"}],"name":"WalletTypeUpdated","type":"event"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"addAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"components":[{"internalType":"bytes32","name":"protocol","type":"bytes32"},{"internalType":"bytes","name":"addressData","type":"bytes"},{"internalType":"uint64","name":"chainId","type":"uint64"},{"internalType":"string","name":"label","type":"string"},{"internalType":"enum IWalletDirectoryMemory.WalletType","name":"walletType","type":"uint8"},{"internalType":"bytes","name":"proof","type":"bytes"},{"internalType":"enum IWalletDirectoryMemory.Verification","name":"verification","type":"uint8"}],"internalType":"struct IWalletDirectoryMemory.Wallet","name":"wallet","type":"tuple"},{"internalType":"uint256","name":"deadline","type":"uint256"}],"name":"addWallet","outputs":[{"internalType":"bytes32","name":"walletKey","type":"bytes32"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"orgAddress","type":"address"},{"components":[{"internalType":"bytes32","name":"protocol","type":"bytes32"},{"internalType":"bytes","name":"addressData","type":"bytes"},{"internalType":"uint64","name":"chainId","type":"uint64"},{"internalType":"string","name":"label","type":"string"},{"internalType":"enum IWalletDirectoryMemory.WalletType","name":"walletType","type":"uint8"},{"internalType":"bytes","name":"proof","type":"bytes"},{"internalType":"enum IWalletDirectoryMemory.Verification","name":"verification","type":"uint8"}],"internalType":"struct IWalletDirectoryMemory.Wallet","name":"wallet","type":"tuple"}],"name":"addWalletForOrg","outputs":[{"internalType":"bytes32","name":"walletKey","type":"bytes32"}],"stateMutability":"nonpayable","type":"function"},{"inputs":[],"name":"admins","outputs":[{"internalType":"address[]","name":"","type":"address[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"eip712Domain","outputs":[{"internalType":"bytes1","name":"fields","type":"bytes1"},{"internalType":"string","name":"name","type":"string"},{"internalType":"string","name":"version","type":"string"},{"internalType":"uint256","name":"chainId","type":"uint256"},{"internalType":"address","name":"verifyingContract","type":"address"},{"internalType":"bytes32","name":"salt","type":"bytes32"},{"internalType":"uint256[]","name":"extensions","type":"uint256[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"getMaxWalletsPerAccount","outputs":[{"internalType":"uint256","name":"","type":"uint256"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"protocol","type":"bytes32"},{"internalType":"bytes","name":"addressData","type":"bytes"}],"name":"getOwnerByAddress","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"getStoredWallets","outputs":[{"components":[{"internalType":"bytes32","name":"protocol","type":"bytes32"},{"internalType":"bytes","name":"addressData","type":"bytes"},{"internalType":"uint64","name":"chainId","type":"uint64"},{"internalType":"string","name":"label","type":"string"},{"internalType":"enum IWalletDirectoryMemory.WalletType","name":"walletType","type":"uint8"},{"internalType":"bytes","name":"proof","type":"bytes"},{"internalType":"enum IWalletDirectoryMemory.Verification","name":"verification","type":"uint8"}],"internalType":"struct IWalletDirectoryMemory.Wallet[]","name":"","type":"tuple[]"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"getWallets","outputs":[{"components":[{"internalType":"bytes32","name":"protocol","type":"bytes32"},{"internalType":"bytes","name":"addressData","type":"bytes"},{"internalType":"uint64","name":"chainId","type":"uint64"},{"internalType":"string","name":"label","type":"string"},{"internalType":"enum IWalletDirectoryMemory.WalletType","name":"walletType","type":"uint8"},{"internalType":"bytes","name":"proof","type":"bytes"},{"internalType":"enum IWalletDirectoryMemory.Verification","name":"verification","type":"uint8"}],"internalType":"struct IWalletDirectoryMemory.Wallet[]","name":"result","type":"tuple[]"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"inheritanceOn","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"isAdmin","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[{"internalType":"bytes32","name":"protocol","type":"bytes32"}],"name":"isProtocolRegistered","outputs":[{"internalType":"bool","name":"","type":"bool"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleRegistry","outputs":[{"internalType":"address","name":"","type":"address"}],"stateMutability":"view","type":"function"},{"inputs":[],"name":"moduleType","outputs":[{"internalType":"bytes32","name":"","type":"bytes32"}],"stateMutability":"pure","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"}],"name":"removeAdmin","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"walletKey","type":"bytes32"},{"internalType":"uint64","name":"chainId","type":"uint64"}],"name":"removeWallet","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"account","type":"address"},{"internalType":"bytes32","name":"walletKey","type":"bytes32"},{"internalType":"uint64","name":"chainId","type":"uint64"}],"name":"removeWalletFor","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"address","name":"orgAddress","type":"address"},{"internalType":"bytes32","name":"walletKey","type":"bytes32"},{"internalType":"uint64","name":"chainId","type":"uint64"}],"name":"removeWalletForOrg","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bool","name":"on","type":"bool"}],"name":"setInheritance","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"uint256","name":"newMax","type":"uint256"}],"name":"setMaxWalletsPerAccount","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"protocol","type":"bytes32"},{"internalType":"bool","name":"registered","type":"bool"}],"name":"setProtocolRegistered","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"walletKey","type":"bytes32"},{"internalType":"uint64","name":"chainId","type":"uint64"},{"internalType":"string","name":"newLabel","type":"string"}],"name":"updateWalletLabel","outputs":[],"stateMutability":"nonpayable","type":"function"},{"inputs":[{"internalType":"bytes32","name":"walletKey","type":"bytes32"},{"internalType":"uint64","name":"chainId","type":"uint64"},{"internalType":"enum IWalletDirectoryMemory.WalletType","name":"newType","type":"uint8"}],"name":"updateWalletType","outputs":[],"stateMutability":"nonpayable","type":"function"}]',
  'WalletDirectoryManager',
);

class WalletDirectoryManager extends _i1.GeneratedContract {
  WalletDirectoryManager({
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

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> addAdmin(
    ({_i2.EthereumAddress account}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[1];
    assert(checkSignature(function, '70480275'));
    final params = [args.account];
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
  Future<String> addWallet(
    ({dynamic wallet, BigInt deadline}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[2];
    assert(checkSignature(function, '8dcf95b5'));
    final params = [
      args.wallet,
      args.deadline,
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
  Future<String> addWalletForOrg(
    ({_i2.EthereumAddress orgAddress, dynamic wallet}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[3];
    assert(checkSignature(function, '08dd2d54'));
    final params = [
      args.orgAddress,
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
  Future<List<_i2.EthereumAddress>> admins(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[4];
    assert(checkSignature(function, 'a5de3619'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as List<dynamic>).cast<_i2.EthereumAddress>();
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<Eip712Domain> eip712Domain(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[5];
    assert(checkSignature(function, '84b0196e'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return Eip712Domain(response);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<BigInt> getMaxWalletsPerAccount(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[6];
    assert(checkSignature(function, 'cd15d1c7'));
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
  Future<_i2.EthereumAddress> getOwnerByAddress(
    ({_i3.Uint8List protocol, _i3.Uint8List addressData}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[7];
    assert(checkSignature(function, 'd7d923a4'));
    final params = [
      args.protocol,
      args.addressData,
    ];
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
  Future<dynamic> getStoredWallets(
    ({_i2.EthereumAddress account}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[8];
    assert(checkSignature(function, 'f82e9737'));
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
  Future<dynamic> getWallets(
    ({_i2.EthereumAddress account}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[9];
    assert(checkSignature(function, '422c29a4'));
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
  Future<bool> inheritanceOn(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[10];
    assert(checkSignature(function, '84a5bada'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> isAdmin(
    ({_i2.EthereumAddress account}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[11];
    assert(checkSignature(function, '24d7806c'));
    final params = [args.account];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<bool> isProtocolRegistered(
    ({_i3.Uint8List protocol}) args, {
    _i1.BlockNum? atBlock,
  }) async {
    final function = self.abi.functions[12];
    assert(checkSignature(function, '50782c3c'));
    final params = [args.protocol];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as bool);
  }

  /// The optional [atBlock] parameter can be used to view historical data. When
  /// set, the function will be evaluated in the specified block. By default, the
  /// latest on-chain block will be used.
  Future<_i2.EthereumAddress> moduleRegistry(
      {_i1.BlockNum? atBlock}) async {
    final function = self.abi.functions[13];
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
    final function = self.abi.functions[14];
    assert(checkSignature(function, '6465e69f'));
    final params = [];
    final response = await read(
      function,
      params,
      atBlock,
    );
    return (response[0] as _i3.Uint8List);
  }

  /// The optional [transaction] parameter can be used to override parameters
  /// like the gas price, nonce and max gas. The `data` and `to` fields will be
  /// set by the contract.
  Future<String> removeAdmin(
    ({_i2.EthereumAddress account}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[15];
    assert(checkSignature(function, '1785f53c'));
    final params = [args.account];
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
  Future<String> removeWallet(
    ({_i3.Uint8List walletKey, BigInt chainId}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[16];
    assert(checkSignature(function, '692608ef'));
    final params = [
      args.walletKey,
      args.chainId,
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
  Future<String> removeWalletFor(
    ({_i2.EthereumAddress account, _i3.Uint8List walletKey, BigInt chainId}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[17];
    assert(checkSignature(function, '70150267'));
    final params = [
      args.account,
      args.walletKey,
      args.chainId,
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
  Future<String> removeWalletForOrg(
    ({_i2.EthereumAddress orgAddress, _i3.Uint8List walletKey, BigInt chainId}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[18];
    assert(checkSignature(function, '33d30fc2'));
    final params = [
      args.orgAddress,
      args.walletKey,
      args.chainId,
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
  Future<String> setInheritance(
    ({bool on}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[19];
    assert(checkSignature(function, 'c5a66d2c'));
    final params = [args.on];
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
  Future<String> setMaxWalletsPerAccount(
    ({BigInt newMax}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[20];
    assert(checkSignature(function, '53dc01be'));
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
  Future<String> setProtocolRegistered(
    ({_i3.Uint8List protocol, bool registered}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[21];
    assert(checkSignature(function, '56586c4f'));
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
  Future<String> updateWalletLabel(
    ({_i3.Uint8List walletKey, BigInt chainId, String newLabel}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[22];
    assert(checkSignature(function, '7523acbc'));
    final params = [
      args.walletKey,
      args.chainId,
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
  Future<String> updateWalletType(
    ({_i3.Uint8List walletKey, BigInt chainId, BigInt newType}) args, {
    required _i1.Credentials credentials,
    _i1.Transaction? transaction,
  }) async {
    final function = self.abi.functions[23];
    assert(checkSignature(function, '0db29a1a'));
    final params = [
      args.walletKey,
      args.chainId,
      args.newType,
    ];
    return write(
      credentials,
      transaction,
      function,
      params,
    );
  }

  /// Returns a live stream of all AdminAdded events emitted by this contract.
  Stream<AdminAdded> adminAddedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('AdminAdded');
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
      return AdminAdded(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all AdminRemoved events emitted by this contract.
  Stream<AdminRemoved> adminRemovedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('AdminRemoved');
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
      return AdminRemoved(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all EIP712DomainChanged events emitted by this contract.
  Stream<EIP712DomainChanged> eIP712DomainChangedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('EIP712DomainChanged');
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
      return EIP712DomainChanged(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all InheritanceSet events emitted by this contract.
  Stream<InheritanceSet> inheritanceSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('InheritanceSet');
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
      return InheritanceSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all MaxWalletsPerAccountSet events emitted by this contract.
  Stream<MaxWalletsPerAccountSet> maxWalletsPerAccountSetEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('MaxWalletsPerAccountSet');
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
      return MaxWalletsPerAccountSet(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all ProtocolRegistered events emitted by this contract.
  Stream<ProtocolRegistered> protocolRegisteredEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('ProtocolRegistered');
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
      return ProtocolRegistered(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all WalletAdded events emitted by this contract.
  Stream<WalletAdded> walletAddedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('WalletAdded');
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
      return WalletAdded(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all WalletForceRemoved events emitted by this contract.
  Stream<WalletForceRemoved> walletForceRemovedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('WalletForceRemoved');
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
      return WalletForceRemoved(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all WalletLabelUpdated events emitted by this contract.
  Stream<WalletLabelUpdated> walletLabelUpdatedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('WalletLabelUpdated');
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
      return WalletLabelUpdated(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all WalletRemoved events emitted by this contract.
  Stream<WalletRemoved> walletRemovedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('WalletRemoved');
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
      return WalletRemoved(
        decoded,
        result,
      );
    });
  }

  /// Returns a live stream of all WalletTypeUpdated events emitted by this contract.
  Stream<WalletTypeUpdated> walletTypeUpdatedEvents({
    _i1.BlockNum? fromBlock,
    _i1.BlockNum? toBlock,
  }) {
    final event = self.event('WalletTypeUpdated');
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
      return WalletTypeUpdated(
        decoded,
        result,
      );
    });
  }
}

class Eip712Domain {
  Eip712Domain(List<dynamic> response)
      : fields = (response[0] as dynamic),
        name = (response[1] as String),
        version = (response[2] as String),
        chainId = (response[3] as BigInt),
        verifyingContract = (response[4] as _i2.EthereumAddress),
        salt = (response[5] as _i3.Uint8List),
        extensions = (response[6] as List<dynamic>).cast<BigInt>();

  final dynamic fields;

  final String name;

  final String version;

  final BigInt chainId;

  final _i2.EthereumAddress verifyingContract;

  final _i3.Uint8List salt;

  final List<BigInt> extensions;

}

class AdminAdded {
  AdminAdded(
    List<dynamic> response,
    this.event,
  )   : admin = (response[0] as _i2.EthereumAddress),
        by = (response[1] as _i2.EthereumAddress);

  final _i2.EthereumAddress admin;

  final _i2.EthereumAddress by;

  final _i1.FilterEvent event;
}

class AdminRemoved {
  AdminRemoved(
    List<dynamic> response,
    this.event,
  )   : admin = (response[0] as _i2.EthereumAddress),
        by = (response[1] as _i2.EthereumAddress);

  final _i2.EthereumAddress admin;

  final _i2.EthereumAddress by;

  final _i1.FilterEvent event;
}

class EIP712DomainChanged {
  EIP712DomainChanged(
    List<dynamic> response,
    this.event,
  );

  final _i1.FilterEvent event;
}

class InheritanceSet {
  InheritanceSet(
    List<dynamic> response,
    this.event,
  )   : on = (response[0] as bool),
        by = (response[1] as _i2.EthereumAddress);

  final bool on;

  final _i2.EthereumAddress by;

  final _i1.FilterEvent event;
}

class MaxWalletsPerAccountSet {
  MaxWalletsPerAccountSet(
    List<dynamic> response,
    this.event,
  )   : newMax = (response[0] as BigInt);

  final BigInt newMax;

  final _i1.FilterEvent event;
}

class ProtocolRegistered {
  ProtocolRegistered(
    List<dynamic> response,
    this.event,
  )   : protocol = (response[0] as _i3.Uint8List),
        registered = (response[1] as bool);

  final _i3.Uint8List protocol;

  final bool registered;

  final _i1.FilterEvent event;
}

class WalletAdded {
  WalletAdded(
    List<dynamic> response,
    this.event,
  )   : account = (response[0] as _i2.EthereumAddress),
        walletKey = (response[1] as _i3.Uint8List),
        protocol = (response[2] as _i3.Uint8List),
        chainId = (response[3] as BigInt),
        label = (response[4] as String),
        verification = (response[5] as BigInt);

  final _i2.EthereumAddress account;

  final _i3.Uint8List walletKey;

  final _i3.Uint8List protocol;

  final BigInt chainId;

  final String label;

  final BigInt verification;

  final _i1.FilterEvent event;
}

class WalletForceRemoved {
  WalletForceRemoved(
    List<dynamic> response,
    this.event,
  )   : account = (response[0] as _i2.EthereumAddress),
        walletKey = (response[1] as _i3.Uint8List),
        chainId = (response[2] as BigInt),
        by = (response[3] as _i2.EthereumAddress);

  final _i2.EthereumAddress account;

  final _i3.Uint8List walletKey;

  final BigInt chainId;

  final _i2.EthereumAddress by;

  final _i1.FilterEvent event;
}

class WalletLabelUpdated {
  WalletLabelUpdated(
    List<dynamic> response,
    this.event,
  )   : account = (response[0] as _i2.EthereumAddress),
        walletKey = (response[1] as _i3.Uint8List),
        chainId = (response[2] as BigInt),
        oldLabel = (response[3] as String),
        newLabel = (response[4] as String);

  final _i2.EthereumAddress account;

  final _i3.Uint8List walletKey;

  final BigInt chainId;

  final String oldLabel;

  final String newLabel;

  final _i1.FilterEvent event;
}

class WalletRemoved {
  WalletRemoved(
    List<dynamic> response,
    this.event,
  )   : account = (response[0] as _i2.EthereumAddress),
        walletKey = (response[1] as _i3.Uint8List),
        chainId = (response[2] as BigInt);

  final _i2.EthereumAddress account;

  final _i3.Uint8List walletKey;

  final BigInt chainId;

  final _i1.FilterEvent event;
}

class WalletTypeUpdated {
  WalletTypeUpdated(
    List<dynamic> response,
    this.event,
  )   : account = (response[0] as _i2.EthereumAddress),
        walletKey = (response[1] as _i3.Uint8List),
        chainId = (response[2] as BigInt),
        oldWalletType = (response[3] as BigInt),
        newWalletType = (response[4] as BigInt);

  final _i2.EthereumAddress account;

  final _i3.Uint8List walletKey;

  final BigInt chainId;

  final BigInt oldWalletType;

  final BigInt newWalletType;

  final _i1.FilterEvent event;
}
