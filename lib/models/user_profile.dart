class UserProfile {
  final String uid;
  String displayName;
  String email;
  String? avatarUrl;
  String? gender;
  String? dob;
  String? height;

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.avatarUrl,
    this.gender,
    this.dob,
    this.height,
  });

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'avatarUrl': avatarUrl,
      'gender': gender,
      'dob': dob,
      'height': height,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      uid: map['uid'] ?? '',
      displayName: map['displayName'] ?? map['name'] ?? '',
      email: map['email'] ?? '',
      avatarUrl: map['avatarUrl'],
      gender: map['gender'],
      dob: map['dob'],
      height: map['height'],
    );
  }
}
