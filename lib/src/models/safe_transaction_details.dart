import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';
import 'package:publicos_core/src/models/contact.dart';
import 'package:publicos_core/src/utils/log.dart';

/// Represents detailed information about a Safe transaction
class SafeTransactionDetails {
  final String to;
  final BigInt value;
  final String data;
  final TransactionType type;
  final Contact? toContact;
  final Contact? fromContact;
  final String? methodName;
  final Map<String, dynamic>? decodedParameters;

  SafeTransactionDetails({
    required this.to,
    required this.value,
    required this.data,
    required this.type,
    this.toContact,
    this.fromContact,
    this.methodName,
    this.decodedParameters,
  });

  bool get isEthTransfer => type == TransactionType.ethTransfer;
  bool get isContractCall => type == TransactionType.contractCall;
  
  double get ethValue => value.toDouble() / 1e18;
  
  String get displayValue => ethValue > 0 ? '${ethValue.toStringAsFixed(4)} ETH' : '0 ETH';
  
  String get formattedTo {
    if (to.length > 10) {
      return '${to.substring(0, 6)}...${to.substring(to.length - 4)}';
    }
    return to;
  }
}

enum TransactionType {
  ethTransfer,
  contractCall,
  unknown,
}

/// Utility class for analyzing Safe transaction data
class SafeTransactionAnalyzer {
  /// Analyze transaction parameters to determine transaction type and details
  static SafeTransactionDetails analyzeTransaction(Map<String, dynamic> parameters) {
    // Extract parameters from the vote parameters
    final targetAddress = parameters['targetAddress'];
    final valueParam = parameters['valueParam'] as BigInt?;
    final dataParam = parameters['dataParam'] as List<int>?;
    
    String to = (targetAddress is EthereumAddress) ? targetAddress.eip55With0x : '0x0';
    BigInt value = valueParam ?? BigInt.zero;
    String data = dataParam != null ? bytesToHex(dataParam, include0x: true) : '0x';
    
    TransactionType type = _determineTransactionType(value, data);
    String? methodName = _extractMethodName(data);
    Map<String, dynamic>? decodedParameters = _decodeParameters(data);
    
    return SafeTransactionDetails(
      to: to,
      value: value,
      data: data,
      type: type,
      methodName: methodName,
      decodedParameters: decodedParameters,
    );
  }
  
  /// Determine the transaction type based on value and data
  static TransactionType _determineTransactionType(BigInt value, String data) {
    if (value > BigInt.zero && (data == '0x' || data.length <= 2)) {
      return TransactionType.ethTransfer;
    } else if (data.length > 2) {
      return TransactionType.contractCall;
    } else {
      return TransactionType.unknown;
    }
  }
  
  /// Extract method name from transaction data (first 4 bytes)
  static String? _extractMethodName(String data) {
    if (data.length < 10) return null; // Need at least 0x + 8 chars for method signature
    
    String methodSignature = data.substring(2, 10).toLowerCase();
    
    // Common method signatures
    Map<String, String> knownMethods = {
      'a9059cbb': 'transfer',
      '23b872dd': 'transferFrom',
      '095ea7b3': 'approve',
      '40c10f19': 'mint',
      '42966c68': 'burn',
      '18160ddd': 'totalSupply',
      '70a08231': 'balanceOf',
      '8da5cb5b': 'owner',
      'f2fde38b': 'transferOwnership',
      // Provider allowlist: BSP / SSP registry Managers. The target
      // address tells which registry; the apps compare it to PublicOSBsp's.
      'af1d3711': 'setRegistrationRestricted',
      '64f9360a': 'setRegistrationAllowed',
    };
    
    return knownMethods[methodSignature] ?? 'Unknown Method';
  }
  
  /// Attempt to decode common parameter patterns
  static Map<String, dynamic>? _decodeParameters(String data) {
    if (data.length < 10) return null;
    
    String methodSignature = data.substring(2, 10).toLowerCase();
    String parameters = data.substring(10);
    
    try {
      switch (methodSignature) {
        case 'a9059cbb': // transfer(address,uint256)
          if (parameters.length >= 128) {
            String toAddress = '0x' + parameters.substring(24, 64);
            String amountHex = parameters.substring(64, 128);
            BigInt amount = BigInt.parse(amountHex, radix: 16);
            return {
              'to': toAddress,
              'amount': amount,
            };
          }
          break;
        case '23b872dd': // transferFrom(address,address,uint256)
          if (parameters.length >= 192) {
            String fromAddress = '0x' + parameters.substring(24, 64);
            String toAddress = '0x' + parameters.substring(88, 128);
            String amountHex = parameters.substring(128, 192);
            BigInt amount = BigInt.parse(amountHex, radix: 16);
            return {
              'from': fromAddress,
              'to': toAddress,
              'amount': amount,
            };
          }
          break;
        case 'af1d3711': // setRegistrationRestricted(bool)
          if (parameters.length >= 64) {
            return {
              'restricted': BigInt.parse(parameters.substring(0, 64), radix: 16) != BigInt.zero,
            };
          }
          break;
        case '64f9360a': // setRegistrationAllowed(address,bool)
          if (parameters.length >= 128) {
            return {
              'account': '0x${parameters.substring(24, 64)}',
              'allowed': BigInt.parse(parameters.substring(64, 128), radix: 16) != BigInt.zero,
            };
          }
          break;
      }
    } catch (e) {
      Log.e('Safe', 'Error decoding parameters: $e');
    }
    
    return null;
  }
}