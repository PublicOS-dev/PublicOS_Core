import 'package:wallet/wallet.dart';

/// Represents a pointer (key-value pair) for an app
class AppPointer {
  final String type; // e.g., "url", "ipfs", "arweave"
  final String value;

  AppPointer({
    required this.type,
    required this.value,
  });

  factory AppPointer.fromJson(Map<String, dynamic> json) {
    return AppPointer(
      type: json['type'] as String,
      value: json['value'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'value': value,
    };
  }

  @override
  String toString() => 'AppPointer(type: $type, value: $value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppPointer &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          value == other.value;

  @override
  int get hashCode => type.hashCode ^ value.hashCode;
}

/// Represents an app bookmark stored on-chain
class AppBookmark {
  final String appName; // Unique identifier (on-chain key)
  final String displayName; // Human-readable name
  final EthereumAddress ownerAccountAddress; // Account that owns this app
  final EthereumAddress? storedBySessionAddress; // Session that stored it (optional)
  final List<AppPointer> pointers;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AppBookmark({
    required this.appName,
    required this.displayName,
    required this.ownerAccountAddress,
    this.storedBySessionAddress,
    this.pointers = const [],
    this.createdAt,
    this.updatedAt,
  });

  // Convenience getters for common pointer types
  String? get url => _getPointerValue('url');
  String? get ipfsHash => _getPointerValue('ipfs');
  String? get arweaveId => _getPointerValue('arweave');
  String? get description => _getPointerValue('description');
  String? get icon => _getPointerValue('icon');
  String? get category => _getPointerValue('category');

  String? _getPointerValue(String type) {
    try {
      return pointers.firstWhere((p) => p.type == type).value;
    } catch (_) {
      return null;
    }
  }

  AppPointer? getPointer(String type) {
    try {
      return pointers.firstWhere((p) => p.type == type);
    } catch (_) {
      return null;
    }
  }

  bool hasPointer(String type) {
    return pointers.any((p) => p.type == type);
  }

  AppBookmark copyWith({
    String? appName,
    String? displayName,
    EthereumAddress? ownerAccountAddress,
    EthereumAddress? storedBySessionAddress,
    List<AppPointer>? pointers,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return AppBookmark(
      appName: appName ?? this.appName,
      displayName: displayName ?? this.displayName,
      ownerAccountAddress: ownerAccountAddress ?? this.ownerAccountAddress,
      storedBySessionAddress: storedBySessionAddress ?? this.storedBySessionAddress,
      pointers: pointers ?? this.pointers,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory AppBookmark.fromJson(Map<String, dynamic> json) {
    return AppBookmark(
      appName: json['appName'] as String,
      displayName: json['displayName'] as String,
      ownerAccountAddress: EthereumAddress.fromHex(json['ownerAccountAddress'] as String),
      storedBySessionAddress: json['storedBySessionAddress'] != null
          ? EthereumAddress.fromHex(json['storedBySessionAddress'] as String)
          : null,
      pointers: (json['pointers'] as List<dynamic>?)
              ?.map((p) => AppPointer.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'appName': appName,
      'displayName': displayName,
      'ownerAccountAddress': ownerAccountAddress.eip55With0x,
      if (storedBySessionAddress != null) 'storedBySessionAddress': storedBySessionAddress!.eip55With0x,
      'pointers': pointers.map((p) => p.toJson()).toList(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'AppBookmark(appName: $appName, displayName: $displayName, owner: ${ownerAccountAddress.eip55With0x}, pointers: ${pointers.length})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppBookmark &&
          runtimeType == other.runtimeType &&
          appName == other.appName &&
          ownerAccountAddress == other.ownerAccountAddress;

  @override
  int get hashCode => appName.hashCode ^ ownerAccountAddress.hashCode;
}
