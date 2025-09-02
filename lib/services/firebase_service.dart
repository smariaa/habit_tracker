import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/habit.dart';
import '../models/quote.dart';
import '../models/user_profile.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // AUTH METHODS
  Future<User?> signInWithEmail(String email, String password) async {
    final userCredential =
    await _auth.signInWithEmailAndPassword(email: email, password: password);
    return userCredential.user;
  }

  Future<User?> signUpWithEmail(String email, String password) async {
    final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email, password: password);
    return userCredential.user;
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;

  // USER PROFILE
  Future<void> createOrUpdateUser(UserProfile profile) async {
    final ref = _firestore.collection('users').doc(profile.uid);
    await ref.set(profile.toMap(), SetOptions(merge: true));
  }

  Future<UserProfile?> getUserProfile(String uid) async {
    final snap = await _firestore.collection('users').doc(uid).get();
    if (!snap.exists) return null;
    return UserProfile.fromMap(snap.data()!);
  }

  // HABITS
  CollectionReference habitCollection(String uid) =>
      _firestore.collection('users').doc(uid).collection('habits');

  Stream<List<Habit>> habitsStream(String uid) {
    return habitCollection(uid)
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) {
      return snap.docs
          .map((d) => Habit.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<void> addOrUpdateHabit(String uid, Habit h) async {
    final ref = habitCollection(uid).doc(h.id);
    await ref.set(h.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteHabit(String uid, String habitId) async {
    await habitCollection(uid).doc(habitId).delete();
  }

  // FAVORITE QUOTES
  CollectionReference favoritesCollection(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('favorites')
      .doc('quotes')
      .collection('items');

  Future<void> saveFavoriteQuote(String uid, Quote q) async {
    await favoritesCollection(uid).doc(q.id).set(q.toMap());
  }

  Future<void> removeFavoriteQuote(String uid, String quoteId) async {
    await favoritesCollection(uid).doc(quoteId).delete();
  }

  Stream<List<Quote>> favoriteQuotesStream(String uid) {
    return favoritesCollection(uid).snapshots().map((snap) {
      return snap.docs
          .map((d) => Quote.fromMap(d.data() as Map<String, dynamic>))
          .toList();
    });
  }

  Future<Set<String>> getFavoriteQuoteIds(String uid) async {
    final snap = await favoritesCollection(uid).get();
    return snap.docs.map((doc) => doc.id).toSet();
  }
}
