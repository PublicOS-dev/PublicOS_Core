import 'dart:convert';

/// A single action button in a bot-sent interactive menu.
/// Maps to XMTP's Action struct (coinbase.com/actions).
class InteractiveAction {
  final String id;
  final String label;
  final String? imageUrl;
  final String style; // "primary", "secondary", or "danger"

  const InteractiveAction({
    required this.id,
    required this.label,
    this.imageUrl,
    this.style = 'secondary',
  });

  factory InteractiveAction.fromJson(Map<String, dynamic> json) {
    return InteractiveAction(
      id: json['id'] as String,
      label: json['label'] as String,
      imageUrl: json['imageUrl'] as String?,
      style: (json['style'] as String?) ?? 'secondary',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'style': style,
      };
}

/// A menu sent by a bot: description text + tappable action buttons.
/// Decoded from coinbase.com/actions content type (JSON wire format).
class InteractiveMenu {
  final String id;
  final String description;
  final List<InteractiveAction> actions;

  const InteractiveMenu({
    required this.id,
    required this.description,
    required this.actions,
  });

  factory InteractiveMenu.fromJson(Map<String, dynamic> json) {
    final rawActions = json['actions'] as List?;
    final actions = <InteractiveAction>[];
    if (rawActions != null) {
      for (final a in rawActions) {
        if (a is Map<String, dynamic>) {
          actions.add(InteractiveAction.fromJson(a));
        }
      }
    }
    return InteractiveMenu(
      id: json['id'] as String,
      description: (json['description'] as String?) ?? '',
      actions: actions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'actions': actions.map((a) => a.toJson()).toList(),
      };

  /// Short preview for conversation lists.
  String get previewText =>
      description.isNotEmpty ? description : 'Menu';
}

/// A user's tap response to a bot menu.
/// Encoded as coinbase.com/intent content type (JSON wire format).
class InteractiveActionResponse {
  final String id; // References the Actions message ID
  final String actionId; // The selected action ID
  final Map<String, dynamic>? metadata;

  const InteractiveActionResponse({
    required this.id,
    required this.actionId,
    this.metadata,
  });

  factory InteractiveActionResponse.fromJson(Map<String, dynamic> json) {
    return InteractiveActionResponse(
      id: json['id'] as String,
      actionId: json['actionId'] as String,
      metadata: json['metadata'] != null
          ? Map<String, dynamic>.from(json['metadata'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'actionId': actionId,
        if (metadata != null) 'metadata': metadata,
      };

  /// Short preview for conversation lists.
  String get previewText => 'Tapped: $actionId';
}
