import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String userId;
  final String studentId; // Internal account identifier
  final String name;
  final String email;
  final String phone;
  final String role; // 'user', 'staff' / 'kitchen', 'admin'
  final String profilePhoto; // Profile photo URL
  final double walletBalance; // Prepaid wallet balance in Firestore
  final DateTime createdAt;

  const UserModel({
    required this.userId,
    this.studentId = '',
    required this.name,
    required this.email,
    required this.phone,
    this.role = 'user',
    this.profilePhoto = '',
    this.walletBalance = 500.0,
    required this.createdAt,
  });

  String get memberId => studentId.isNotEmpty ? studentId : userId;

  bool get isUser => role == 'user' || role == 'student';
  bool get isStudent => isUser; // Backward-compatibility alias
  bool get isAdmin => role == 'admin';
  bool get isStaff => role == 'staff' || role == 'kitchen';
  bool get isKitchen => isStaff;

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'studentId': studentId,
      'memberId': studentId,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role == 'student' ? 'user' : role,
      'profilePhoto': profilePhoto,
      'photoUrl': profilePhoto,
      'walletBalance': walletBalance,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, [String? documentId]) {
    DateTime parseDate(dynamic value) {
      if (value is Timestamp) {
        return value.toDate();
      } else if (value is String) {
        return DateTime.tryParse(value) ?? DateTime.now();
      } else if (value is int) {
        return DateTime.fromMillisecondsSinceEpoch(value);
      }
      return DateTime.now();
    }

    final rawRole = (map['role'] ?? 'user').toString();
    final normalizedRole = rawRole == 'student' ? 'user' : rawRole;
    final idField = (map['studentId'] ?? map['memberId'] ?? '').toString();
    final photo = (map['profilePhoto'] ?? map['photoUrl'] ?? '').toString();
    final balance = (map['walletBalance'] as num?)?.toDouble() ?? 500.0;

    return UserModel(
      userId: (map['userId'] ?? documentId ?? '').toString(),
      studentId: idField,
      name: (map['name'] ?? '').toString(),
      email: (map['email'] ?? '').toString(),
      phone: (map['phone'] ?? '').toString(),
      role: normalizedRole,
      profilePhoto: photo,
      walletBalance: balance,
      createdAt: parseDate(map['createdAt']),
    );
  }

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() as Map<String, dynamic>?) ?? {};
    return UserModel.fromMap(data, doc.id);
  }

  UserModel copyWith({
    String? userId,
    String? studentId,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? profilePhoto,
    double? walletBalance,
    DateTime? createdAt,
  }) {
    return UserModel(
      userId: userId ?? this.userId,
      studentId: studentId ?? this.studentId,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role != null ? (role == 'student' ? 'user' : role) : this.role,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      walletBalance: walletBalance ?? this.walletBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
