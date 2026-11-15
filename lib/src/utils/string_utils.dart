import 'dart:typed_data';

/// Converts a hexadecimal string (optionally prefixed with '0x') to a Uint8List.
Uint8List StringToBytes(String hex) {
  String normalizedHex = hex; // Remove 0x prefix if present
  if (normalizedHex.length % 2 != 0) {
    normalizedHex = '0$normalizedHex'; // Pad with a leading zero if odd length
  }

  final List<int> list = [];
  for (int i = 0; i < normalizedHex.length; i += 2) {
    try {
      list.add(int.parse(normalizedHex.substring(i, i + 2), radix: 16));
    } catch (e) {
      // It's good to provide more context in the error message.
      throw FormatException('Invalid hexadecimal string: $hex. Normalized: $normalizedHex. Error at index $i.', e);
    }
  }
  return Uint8List.fromList(list);
}

/// Converts a Uint8List to a hexadecimal string.
/// Includes a '0x' prefix by default.
String bytesToHex(Uint8List bytes) {
  final StringBuffer buffer = StringBuffer();

  for (int byte in bytes) {
    buffer.write(byte.toRadixString(16).padLeft(2, '0'));
  }
  return buffer.toString();
}

/// Converts a Uint8List (representing a bytes32) to a user-friendly string representation.
/// This will be a 64-character hex string without the '0x' prefix.
String bytes32ToString(Uint8List bytes) {
  String result = bytesToHex(bytes);

  if (result.length < 64) {
    result = result.padLeft(64, '0');
  } else if (result.length > 64) {
    // Truncate to 64 characters (representing the first 32 bytes)
    // if the input byte array was longer than 32 bytes.
    result = result.substring(0, 64);
  }
  return result;
}

/// Shortens a string to the format "prefix...suffix", optionally handling "0x" for addresses.
///
/// [value]: The string to shorten.
/// [isAddress]: If true, and value starts with "0x", the prefixLength applies after "0x".
/// [prefixLength]: The number of characters to show at the beginning.
/// [suffixLength]: The number of characters to show at the end.
String shortenString(String value, {bool isAddress = false, int prefixLength = 4, int suffixLength = 4}) {
  String effectiveValue = value;
  String hexPrefix = "";

  if (isAddress && value.toLowerCase().startsWith('0x')) {
    hexPrefix = value.substring(0, 2);
    effectiveValue = value.substring(2);
  }

  final totalLength = prefixLength + suffixLength + 3; // 3 for "..."

  if (effectiveValue.length <= prefixLength + suffixLength) { // If it's short enough, no need to shorten
    return value; // Return original value with prefix if any
  }

  if (effectiveValue.length <= totalLength && !isAddress) { // If it's short but not an address, return as is
      return value;
  }


  final prefix = effectiveValue.substring(0, prefixLength);
  final suffix = effectiveValue.substring(effectiveValue.length - suffixLength);

  return "$hexPrefix$prefix...$suffix";
}
