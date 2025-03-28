import 'user.dart';

class Review {
  final int id;
  final User user;
  final String title;
  final String content;
  final int rating;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.user,
    required this.title,
    required this.content,
    required this.rating,
    required this.createdAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id'],
      user: User.fromJson({
        'id': json['user'],
        'email': json['user_name'] ?? '',
        'first_name': (json['user_name'] ?? '').split(' ').first,
        'last_name': (json['user_name'] ?? '').split(' ').length > 1 
            ? (json['user_name'] ?? '').split(' ').last 
            : '',
        'phone': null,
        'date_joined': json['created_at'],
        'is_active': true,
        'is_staff': false,
      }),
      title: json['title'],
      content: json['content'],
      rating: json['rating'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user': user.id,
      'user_name': user.name,
      'title': title,
      'content': content,
      'rating': rating,
      'created_at': createdAt.toIso8601String(),
    };
  }
}