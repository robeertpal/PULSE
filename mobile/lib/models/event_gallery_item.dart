class EventGalleryItem {
  final int id;
  final String title;
  final String imageUrl;
  final int displayOrder;

  EventGalleryItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.displayOrder,
  });

  factory EventGalleryItem.fromJson(Map<String, dynamic> json) {
    return EventGalleryItem(
      id: json['id'],
      title: json['title'],
      imageUrl: json['image_url'],
      displayOrder: json['display_order'] ?? 0,
    );
  }
}
