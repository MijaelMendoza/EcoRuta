import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

@immutable
class UserModel {
  final String email;
  final String name;
  final String phoneNumber;
  final String birthDate;
  final bool pumaKatari;
  final bool teleferico;
  final String password;
  final String uid;
  final String profilePic;
  final String role;  // Agregado el campo role

  const UserModel({
    required this.email,
    required this.name,
    required this.phoneNumber,
    required this.birthDate,
    required this.pumaKatari,
    required this.teleferico,
    required this.password,
    required this.uid,
    required this.profilePic,
    required this.role,  // Inicializar el campo role
  });

  UserModel copyWith({
    String? email,
    String? name,
    String? phoneNumber,
    String? birthDate,
    bool? pumaKatari,
    bool? teleferico,
    String? password,
    String? uid,
    String? profilePic,
    String? role,  // Agregar role a copyWith
  }) {
    return UserModel(
      email: email ?? this.email,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      birthDate: birthDate ?? this.birthDate,
      pumaKatari: pumaKatari ?? this.pumaKatari,
      teleferico: teleferico ?? this.teleferico,
      password: password ?? this.password,
      uid: uid ?? this.uid,
      profilePic: profilePic ?? this.profilePic,
      role: role ?? this.role,  // Copiar el campo role
    );
  }

  static UserModel fromSnap(DocumentSnapshot snap) {
    var snapshot = snap.data() as Map<String, dynamic>;

    return UserModel(
      email: snapshot["email"],
      name: snapshot["name"],
      phoneNumber: snapshot["phoneNumber"],
      birthDate: snapshot["birthDate"],
      pumaKatari: snapshot["pumaKatari"],
      teleferico: snapshot["teleferico"],
      password: snapshot["password"],
      uid: snapshot["uid"],
      profilePic: snapshot["profilePic"],
      role: snapshot["role"],  // Asignar el campo role
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {required String documentId}) {
    return UserModel(
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phoneNumber: map['phoneNumber'] ?? '',
      birthDate: map['birthDate'] ?? '',
      pumaKatari: map['pumaKatari'] ?? false,
      teleferico: map['teleferico'] ?? false,
      password: map['password'] ?? '',
      uid: documentId,
      profilePic: map['profilePic'] ?? '',
      role: map['role'] ?? '',  // Asignar el campo role
    );
  }

  Map<String, dynamic> toJson() => {
        "email": email,
        "name": name,
        "phoneNumber": phoneNumber,
        "birthDate": birthDate,
        "pumaKatari": pumaKatari,
        "teleferico": teleferico,
        "password": password,
        "uid": uid,
        "profilePic": profilePic,
        "role": role,  // Incluir el campo role en el JSON
      };
}
