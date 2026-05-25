class UserProgress {
  final int id;
  final String userId;
  final String itemType;
  final int itemId;
  final String status;
  final int correctCount;
  final int wrongCount;
  final DateTime nextReviewAt;
  final DateTime lastReviewedAt;

  const UserProgress({
    required this.id,
    required this.userId,
    required this.itemType,
    required this.itemId,
    required this.status,
    required this.correctCount,
    required this.wrongCount,
    required this.nextReviewAt,
    required this.lastReviewedAt,
  });

  factory UserProgress.fromJson(Map<String, dynamic> json) => UserProgress(
        id:             json['id'] as int,
        userId:         json['user_id'] as String,
        itemType:       json['item_type'] as String,
        itemId:         json['item_id'] as int,
        status:         json['status'] as String,
        correctCount:   json['correct_count'] as int,
        wrongCount:     json['wrong_count'] as int,
        nextReviewAt:   DateTime.parse(json['next_review_at'] as String),
        lastReviewedAt: DateTime.parse(json['last_reviewed_at'] as String),
      );

  bool get isDue => nextReviewAt.isBefore(DateTime.now());
}
