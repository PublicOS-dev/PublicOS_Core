class Member {
  final String inboxId;
  final dynamic addresses; // Can be String or List

  Member({required this.inboxId, required this.addresses});

  factory Member.fromJson(Map<String, dynamic> json) {
    return Member(
      inboxId: json['inboxId'] as String,
      addresses: json['addresses'], // Remove the String cast
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'inboxId': inboxId,
      'addresses': addresses,
    };
  }

  // Helper method to get main address
  String get mainAddress {
    if (addresses is String) return addresses as String;
    if (addresses is List) return (addresses as List).first.toString();
    return '';
  }
}