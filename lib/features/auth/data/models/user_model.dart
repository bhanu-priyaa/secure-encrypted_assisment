import '../../domain/entities/user.dart';

abstract final class UserModel {
  static User fromJson(Map<String, dynamic> json) => User(
    id: (json['id'] as num?)?.toInt() ?? 0,
    username: json['username'] as String? ?? '',
    email: json['email'] as String? ?? '',
    firstName: json['firstName'] as String? ?? '',
    lastName: json['lastName'] as String? ?? '',
    gender: json['gender'] as String? ?? '',
    image: json['image'] as String?,
  );

  static Map<String, dynamic> toJson(User user) => {
    'id': user.id,
    'username': user.username,
    'email': user.email,
    'firstName': user.firstName,
    'lastName': user.lastName,
    'gender': user.gender,
    'image': user.image,
  };
}
