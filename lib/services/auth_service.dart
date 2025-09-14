import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:product_listing_app/models/user_model.dart';

class AuthService {
  Future<void> register(
    String name,
    String email,
    String password,
    File profileImage,
  ) async {
    try {
      final auth = FirebaseAuth.instance;
      UserCredential credentials = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credentials.user;
      if (firebaseUser == null) {
        throw Exception('User registration failed');
      }
      String base64Image = base64Encode(profileImage.readAsBytesSync());
      // firestore firebase storage
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .set({'name': name, 'email': email, 'profileImage': base64Image});
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  Future<UserModel?> login(String email, String password) async {
    final auth = FirebaseAuth.instance;
    try {
      UserCredential credentials = await auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = credentials.user;
      if (firebaseUser != null) {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(firebaseUser.uid)
            .withConverter<UserModel>(
              fromFirestore: (snap, _) => UserModel.fromJson(snap.data()!),
              toFirestore: (user, _) => user.toJson(),
            )
            .get();
        if (doc.exists) {
          final data = doc.data()!;
          return data;
        }
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<UserModel?> currentUser() async {
    final auth = FirebaseAuth.instance;
    final firebaseUser = auth.currentUser;
    if (firebaseUser != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .withConverter<UserModel>(
            fromFirestore: (snap, _) => UserModel.fromJson(snap.data()!),
            toFirestore: (user, _) => user.toJson(),
          )
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        return data;
      }
    }
    return null;
  }

  Future<void> updateProfile(String name) async {
    final auth = FirebaseAuth.instance;
    final firebaseUser = auth.currentUser;
    if (firebaseUser != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(firebaseUser.uid)
          .update({'name': name});
    }
  }

  Future<void> logout() async {
    final auth = FirebaseAuth.instance;
    await auth.signOut();
  }
}
