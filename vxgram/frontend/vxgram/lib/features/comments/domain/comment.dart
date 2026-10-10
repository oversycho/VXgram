import 'package:equatable/equatable.dart';

class Comment extends Equatable {
  const Comment({required this.id, required this.userId, required this.username, this.avatarUrl, required this.body, required this.createdAt});
  final String id, userId, username, body; final String? avatarUrl; final DateTime createdAt;
  @override
  List<Object?> get props => [id];
}
