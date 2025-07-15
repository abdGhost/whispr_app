class Confession {
  final String id;
  final String text;
  final String address;
  final String categoryId;
  final String categoryName;
  final int upvotes;
  int commentsCount;
  final String timestamp;
  final String username;
  Map<String, int> reactions;
  bool isReact; // 🔧 NEW FIELD

  Confession({
    required this.id,
    required this.text,
    required this.address,
    required this.categoryId,
    required this.categoryName,
    required this.upvotes,
    required this.commentsCount,
    required this.timestamp,
    required this.username,
    required this.reactions,
    required this.isReact, // 🔧 NEW FIELD
  });

  factory Confession.fromJson(Map<String, dynamic> json) {
    // Handle categoryId as object or string (API vs WebSocket)
    String parsedCategoryId = '';
    String parsedCategoryName = '';

    if (json['categoryId'] is Map) {
      parsedCategoryId = json['categoryId']['_id'] ?? '';
      parsedCategoryName = json['categoryId']['name'] ?? '';
    } else if (json['categoryId'] is String) {
      parsedCategoryId = json['categoryId'];
      parsedCategoryName = ''; // WebSocket event has no name field
    }

    // Handle authorId as object or string (API vs WebSocket)
    String parsedUsername = 'Anonymous';
    if (json['authorId'] is Map) {
      parsedUsername = json['authorId']['randomUsername'] ?? 'Anonymous';
    } else if (json['authorId'] is String) {
      parsedUsername =
          'Anonymous'; // WebSocket event sends only ID, no username
    }

    return Confession(
      id: json['_id'] ?? '',
      text: json['text'] ?? '',
      address: json['address'] ?? '',
      categoryId: parsedCategoryId,
      categoryName: parsedCategoryName,
      upvotes: json['upvotes'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      timestamp: json['createdAt'] ?? '',
      username: parsedUsername,
      reactions: json['reactions'] != null
          ? Map<String, int>.from(json['reactions'])
          : {},
      isReact: json['isReact'] ?? false, // 🔧 parse isReact safely
    );
  }
}
