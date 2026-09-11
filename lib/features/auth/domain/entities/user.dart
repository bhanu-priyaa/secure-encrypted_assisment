import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.username,
    required this.email,
    required this.firstName,
    required this.lastName,
    required this.gender,
    this.image,
  });

  final int id;
  final String username;
  final String email;
  final String firstName;
  final String lastName;
  final String gender;
  final String? image;

  String get fullName => '$firstName $lastName'.trim();

  String get initials {
    final first = firstName.isNotEmpty ? firstName[0] : '';
    final last = lastName.isNotEmpty ? lastName[0] : '';
    final combined = '$first$last'.trim();
    if (combined.isNotEmpty) return combined.toUpperCase();
    return username.isNotEmpty ? username[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props => [id, username, email, firstName, lastName, gender, image];
}
