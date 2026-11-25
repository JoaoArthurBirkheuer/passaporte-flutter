class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String photoUrl;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
  });

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'displayName': displayName,
    'email': email,
    'photoUrl': photoUrl,
  };

  factory UserModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return UserModel(
      uid: id ?? (map['uid'] as String? ?? ''),
      displayName: map['displayName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String? ?? map['photoURL'] as String? ?? '',
    );
  }
}
