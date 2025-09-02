import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';
import '../services/firebase_service.dart';

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseService _fs = FirebaseService();
  UserProfile? _userProfile;
  bool isLoading = true;

  UserProfile? get user => _userProfile;
  bool get isLoggedIn => _auth.currentUser != null && _userProfile != null;

  Future<void> init() async {
    _auth.authStateChanges().listen((u) async {
      if (u == null) {
        _userProfile = null;
      } else {
        final prefs = await SharedPreferences.getInstance();
        final cachedDisplayName = prefs.getString('displayName_${u.uid}');
        final cachedEmail = prefs.getString('email_${u.uid}');
        if (cachedDisplayName != null && cachedEmail != null) {
          _userProfile = UserProfile(
            uid: u.uid,
            displayName: cachedDisplayName,
            email: cachedEmail,
          );
        } else {
          final profile = await _fs.getUserProfile(u.uid);
          if (profile != null) {
            _userProfile = profile;
          } else {
            _userProfile = UserProfile(
              uid: u.uid,
              displayName: u.displayName ?? '',
              email: u.email ?? '',
            );
            await _fs.createOrUpdateUser(_userProfile!);
          }
        }
      }
      isLoading = false;
      notifyListeners();
    });
  }

  Future<void> signUp(
      String displayName,
      String email,
      String password, {
        String? avatarUrl,
        String? gender,
        String? dob,
        String? height,
      }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    _userProfile = UserProfile(
      uid: uid,
      displayName: displayName,
      email: email,
      avatarUrl: avatarUrl,
      gender: gender,
      dob: dob,
      height: height,
    );
    await _fs.createOrUpdateUser(_userProfile!);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('displayName_$uid', displayName);
    await prefs.setString('email_$uid', email);

    notifyListeners();
  }

  Future<void> loginWithEmail(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    final uid = cred.user!.uid;
    final profile = await _fs.getUserProfile(uid);
    if (profile != null) {
      _userProfile = profile;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('displayName_$uid', profile.displayName);
      await prefs.setString('email_$uid', profile.email);
    } else {
      _userProfile = UserProfile(
        uid: uid,
        displayName: cred.user!.displayName ?? '',
        email: email,
      );
      await _fs.createOrUpdateUser(_userProfile!);
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _auth.signOut();
    _userProfile = null;
    notifyListeners();
  }

  Future<void> updateProfile(UserProfile updated) async {
    _userProfile = updated;
    await _fs.createOrUpdateUser(updated);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('displayName_${updated.uid}', updated.displayName);
    notifyListeners();
  }
}
