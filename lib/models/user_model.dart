import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
@immutable
class UserModel {
  final String email;
  final String name;
  final String phoneNumber;
  final List<String> followers;
  final List<String> following;
  final String profilePic;
  final String bannerPic;
  final String uid;
  final String bio;
  final bool isTwitterBlue;
  const UserModel({
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.followers,
    required this.following,
    required this.profilePic,
    required this.bannerPic,
    required this.uid,
    required this.bio,
    required this.isTwitterBlue,
  });

  UserModel copyWith({
    String? email,
    String? name,
    String? phoneNumber,
    List<String>? followers,
    List<String>? following,
    String? profilePic,
    String? bannerPic,
    String? uid,
    String? bio,
    bool? isTwitterBlue,
  }) {
    return UserModel(
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      profilePic: profilePic ?? this.profilePic,
      bannerPic: bannerPic ?? this.bannerPic,
      uid: uid ?? this.uid,
      bio: bio ?? this.bio,
      isTwitterBlue: isTwitterBlue ?? this.isTwitterBlue,
    );
  }
 // Método para crear un objeto User a partir de un DocumentSnapshot
  static UserModel fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return UserModel(
      email: snapshot["email"],
      name: snapshot["name"],
      phoneNumber: snapshot["phoneNumber"],
      followers: List<String>.from(snapshot["followers"] ?? []),
      following: List<String>.from(snapshot["following"] ?? []),
      profilePic: snapshot["profilePic"],
      bannerPic: snapshot["bannerPic"],
      uid: snapshot["uid"],
      bio: snapshot["bio"],
      isTwitterBlue: snapshot["isTwitterBlue"] ?? false,
    );
  }

  // Método para convertir el objeto User a un mapa (para ser almacenado en Firestore, por ejemplo)
  Map<String, dynamic> toJson() => {
        "email": email,
        "name": name,
        "phoneNumber": phoneNumber,
        "followers": followers,
        "following": following,
        "profilePic": profilePic,
        "bannerPic": bannerPic,
        "uid": uid,
        "bio": bio,
        "isTwitterBlue": isTwitterBlue,
      };
  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'email': email});
    result.addAll({'name': name});
    result.addAll({'phoneNumber': phoneNumber});
    result.addAll({'followers': followers});
    result.addAll({'following': following});
    result.addAll({'profilePic': profilePic});
    result.addAll({'bannerPic': bannerPic});
    result.addAll({'bio': bio});
    result.addAll({'isTwitterBlue': isTwitterBlue});

    return result;
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {required String documentId}) {
  return UserModel(
    email: map['email'] ?? '',
    name: map['name'] ?? '',
    phoneNumber: map['phoneNumber'] ?? '',
    followers: List<String>.from(map['followers']),
    following: List<String>.from(map['following']),
    profilePic: map['profilePic'] ?? '',
    bannerPic: map['bannerPic'] ?? '',
    uid: documentId ?? '', 
    bio: map['bio'] ?? '',
    isTwitterBlue: map['isTwitterBlue'] ?? false,
  );
}

  @override
  String toString() {
    return 'UserModel(email: $email, name: $name, phoneNumber: $phoneNumber, followers: $followers, following: $following, profilePic: $profilePic, bannerPic: $bannerPic, uid: $uid, bio: $bio, isTwitterBlue: $isTwitterBlue)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is UserModel &&
        other.email == email &&
        other.name == name &&
        other.phoneNumber == phoneNumber &&
        listEquals(other.followers, followers) &&
        listEquals(other.following, following) &&
        other.profilePic == profilePic &&
        other.bannerPic == bannerPic &&
        other.uid == uid &&
        other.bio == bio &&
        other.isTwitterBlue == isTwitterBlue;
  }

  @override
  int get hashCode {
    return email.hashCode ^
        name.hashCode ^
        phoneNumber.hashCode ^
        followers.hashCode ^
        following.hashCode ^
        profilePic.hashCode ^
        bannerPic.hashCode ^
        uid.hashCode ^
        bio.hashCode ^
        isTwitterBlue.hashCode;
  }
}