class CollectionNameRequest {
  final String name;
  CollectionNameRequest(this.name);

  Map<String, dynamic> toJson() => {'name': name};
}