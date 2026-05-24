class ReviewModel {
  final String id;
  final String authorName;
  final String authorAvatar;
  final double rating;
  final String comment;
  final String date;

  const ReviewModel({
    required this.id,
    required this.authorName,
    required this.authorAvatar,
    required this.rating,
    required this.comment,
    required this.date,
  });

  factory ReviewModel.fromJson(Map<String, dynamic> j) {
    return ReviewModel(
      id: j['id'] as String,
      authorName: (j['authorName'] as String?) ?? 'Anonymous',
      authorAvatar: (j['authorAvatar'] as String?) ?? '',
      rating: (j['rating'] as num).toDouble(),
      comment: (j['comment'] as String?) ?? '',
      date: _formatDate(j['createdAt'] as String?),
    );
  }

  static String _formatDate(String? isoDate) {
    if (isoDate == null) return '';
    final dt = DateTime.tryParse(isoDate);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    if (diff.inDays < 14) return '1 week ago';
    return '${(diff.inDays / 7).floor()} weeks ago';
  }
}
