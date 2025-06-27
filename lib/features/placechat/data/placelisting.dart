class PlaceListing {
  String placeID;
  String name;
  String? lastVisitor;
  DateTime? timeLastAccessed;

  PlaceListing({
    required this.placeID,
    required this.name,
    this.lastVisitor,
    this.timeLastAccessed,
  });
}