import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/anime.dart';
import '../repositories/anime_repository.dart';

class AppStateProvider extends ChangeNotifier {
  final AnimeRepository _repository = AnimeRepository();

  List<Anime> _animeList = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  int _currentPage = 1;
  bool _hasMore = true;

  bool _isSearchMode = false;

  List<Anime> _favorites = [];
  static const String _storageKey = 'favorite_anime_list';

  String _selectedGenre = "All";

  String _homeSearchQuery = "";
  String _favoriteSearchQuery = "";
  Timer? _searchDebounce;

  List<Anime> get animeList => _animeList;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  bool get hasMore => _hasMore;
  int get currentPage => _currentPage;
  bool get isSearchMode => _isSearchMode;
  List<Anime> get favorites => _favorites;
  String get selectedGenre => _selectedGenre;
  String get homeSearchQuery => _homeSearchQuery;
  String get favoriteSearchQuery => _favoriteSearchQuery;

  AppStateProvider() {
    _loadFavorites();
    fetchTopAnime();
  }


  Future<void> fetchTopAnime({int page = 1}) async {
    _isLoading = true;
    _errorMessage = null;
    _isSearchMode = false;
    _currentPage = 1;
    _hasMore = true;
    notifyListeners();

    try {
      _animeList = await _repository.getTopAnime(page: page);
    } catch (e) {
      _errorMessage = 'Failed to load anime: $e';
      debugPrint('Error fetching anime: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMoreAnime() async {
    if (_isLoadingMore || !_hasMore || _isSearchMode || _isLoading) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      _currentPage++;
      final newAnime = await _repository.getTopAnime(page: _currentPage);

      if (newAnime.isEmpty) {
        _hasMore = false;
        debugPrint('📄 No more anime to load (reached end)');
      } else {
        _animeList.addAll(newAnime);
        debugPrint('📄 Loaded page $_currentPage: ${newAnime.length} anime');
      }
    } catch (e) {
      _errorMessage = 'Failed to load more: $e';
      debugPrint('Error loading more anime: $e');
      _currentPage--;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> searchAnimeFromAPI(String query) async {
    if (query.trim().isEmpty) {
      await fetchTopAnime();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    _isSearchMode = true;
    _hasMore = false;
    notifyListeners();

    try {
      _animeList = await _repository.searchAnime(query);
      debugPrint('🔍 Search results: ${_animeList.length} anime');
    } catch (e) {
      _errorMessage = 'Search failed: $e';
      debugPrint('Error searching anime: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Anime?> getAnimeById(int malId) async {
    try {
      return await _repository.getAnimeById(malId);
    } catch (e) {
      debugPrint('Error fetching anime by ID: $e');
      return null;
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? favoritesJson = prefs.getString(_storageKey);

      if (favoritesJson != null) {
        final List<dynamic> decoded = json.decode(favoritesJson);
        _favorites = decoded.map((item) {
          return Anime.fromFavoritesJson(item);
        }).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading favorites: $e');
    }
  }

  Future<void> _saveFavorites() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> favoritesJson =
      _favorites.map((anime) => anime.toJson()).toList();

      await prefs.setString(_storageKey, json.encode(favoritesJson));
    } catch (e) {
      debugPrint('Error saving favorites: $e');
    }
  }

  bool isFavorite(int malId) {
    return _favorites.any((anime) => anime.malId == malId);
  }

  void toggleFavorite(Anime anime) {
    if (isFavorite(anime.malId)) {
      removeFavorite(anime.malId);
    } else {
      addFavorite(anime);
    }
  }

  void addFavorite(Anime anime) {
    if (!isFavorite(anime.malId)) {
      _favorites.add(anime);
      _saveFavorites();
      notifyListeners();
    }
  }

  void removeFavorite(int malId) {
    _favorites.removeWhere((anime) => anime.malId == malId);
    _saveFavorites();
    notifyListeners();
  }

  int get favoritesCount => _favorites.length;

  void setSelectedGenre(String genre) {
    _selectedGenre = genre;
    notifyListeners();
  }

  void setHomeSearchQuery(String query) {
    _homeSearchQuery = query;
    notifyListeners();

    _searchDebounce?.cancel();

    _searchDebounce = Timer(const Duration(milliseconds: 800), () {
      if (query.trim().isNotEmpty) {
        searchAnimeFromAPI(query);
      } else {
        fetchTopAnime();
      }
    });
  }

  void setFavoriteSearchQuery(String query) {
    _favoriteSearchQuery = query;
    notifyListeners();
  }

  List<Anime> getFilteredAnimeForHome() {
    List<Anime> result = _animeList;

    if (_selectedGenre != "All") {
      result = result.where((anime) {
        return anime.genres.any(
                (genre) => genre.toLowerCase() == _selectedGenre.toLowerCase()
        );
      }).toList();
    }

    if (_homeSearchQuery.isNotEmpty) {
      result = result.where((anime) {
        return anime.title.toLowerCase().contains(_homeSearchQuery.toLowerCase());
      }).toList();
    }

    return result;
  }

  List<Anime> getFilteredFavorites() {
    List<Anime> result = _favorites;

    if (_favoriteSearchQuery.isNotEmpty) {
      result = result.where((anime) {
        return anime.title.toLowerCase().contains(_favoriteSearchQuery.toLowerCase());
      }).toList();
    }

    return result;
  }
}