enum CollectionType { frame, bubble, entrance }

extension CollectionTypeExtension on CollectionType {
  String get name {
    switch (this) {
      case CollectionType.frame:
        return 'frame';
      case CollectionType.bubble:
        return 'bubble';
      case CollectionType.entrance:
        return 'entrance';
    }
  }
}

class PurchaseCollectionRequest {
  final CollectionType type;
  final String name;

  PurchaseCollectionRequest({required this.type, required this.name});

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'name': name,
  };
}
