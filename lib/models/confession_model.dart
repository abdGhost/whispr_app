class Confession {
  final String id;
  final String text;
  final String address;
  final String category;
  final int upvotes;
  final int commentsCount;
  final String timestamp;
  final String username;
  final Map<String, int>
  reactions; // ✅ updated to non-nullable with empty map default

  Confession({
    required this.id,
    required this.text,
    required this.address,
    required this.category,
    required this.upvotes,
    required this.commentsCount,
    required this.timestamp,
    required this.username,
    required this.reactions,
  });

  factory Confession.fromJson(Map<String, dynamic> json) {
    return Confession(
      id: json['_id'] ?? '',
      text: json['text'] ?? '',
      address: json['address'] ?? '',
      category: json['categoryId'] != null && json['categoryId']['name'] != null
          ? json['categoryId']['name']
          : '',
      upvotes: json['upvotes'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      timestamp: json['createdAt'] ?? '',
      username:
          json['authorId'] != null && json['authorId']['randomUsername'] != null
          ? json['authorId']['randomUsername']
          : 'Anonymous',
      reactions: json['reactions'] != null
          ? Map<String, int>.from(json['reactions'])
          : {}, // ✅ parse reactions safely as Map<String, int>
    );
  }
}
