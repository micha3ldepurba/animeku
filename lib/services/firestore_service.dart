import 'package:anime_verse/models/anime.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection reference
  CollectionReference _usersCollection() {
    return _firestore.collection('users');
  }

  // Get favorites stream
  Stream<List<Anime>> getFavoritesStream(String userId) {
    return _usersCollection()
        .doc(userId)
        .collection('favorites')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Anime.fromFavoritesJson(doc.data());
      }).toList();
    });
  }

  // Add favorite
  Future<void> addFavorite(String userId, Anime anime) async {
    await _usersCollection()
        .doc(userId)
        .collection('favorites')
        .doc(anime.malId.toString())
        .set(anime.toJson())
        .catchError((error) {
          debugPrint('Error adding favorite: $error');
        }
    );
  }

  // Remove favorite
  Future<void> removeFavorite(String userId, int animeId) async {
    await _usersCollection()
        .doc(userId)
        .collection('favorites')
        .doc(animeId.toString())
        .delete();
  }

  // Check if favorite exists (optional helper, though stream usually handles UI state)
  Future<bool> isFavorite(String userId, int animeId) async {
    final doc = await _usersCollection()
        .doc(userId)
        .collection('favorites')
        .doc(animeId.toString())
        .get();
    return doc.exists;
  }
}