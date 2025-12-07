import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/anime.dart';
class AnimeRepository {
  static const String _baseUrl = 'https://api.jikan.moe/v4';

  final http.Client _client = http.Client();

  Future<List<Anime>> getTopAnime({int page = 1}) async {
    try {
      final url = Uri.parse('$_baseUrl/top/anime').replace(
        queryParameters: {'page': page.toString()},
      );

      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        final List<dynamic> animeDataList = jsonData['data'] as List;

        final animeList = animeDataList.map((animeJson) {
          return Anime.fromJson(animeJson as Map<String, dynamic>);
        }).toList();

        await Future.delayed(const Duration(milliseconds: 400));

        return animeList.where((anime) => anime.isAppropriateContent).toList();

      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please wait a moment and try again.');
      } else if (response.statusCode == 404) {
        throw Exception('Top anime data not found.');
      } else {
        throw Exception('Failed to load top anime. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: $e');
    }
  }

  Future<List<Anime>> searchAnime(String query, {int limit = 20}) async {
    try {
      if (query.trim().isEmpty) {
        return [];
      }

      final url = Uri.parse('$_baseUrl/anime').replace(
        queryParameters: {
          'q': query.trim(),
          'limit': limit.toString(),
        },
      );

      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        final List<dynamic> animeDataList = jsonData['data'] as List;

        final animeList = animeDataList.map((animeJson) {
          return Anime.fromJson(animeJson as Map<String, dynamic>);
        }).toList();

        await Future.delayed(const Duration(milliseconds: 400));

        return animeList.where((anime) => anime.isAppropriateContent).toList();

      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please wait a moment and try again.');
      } else if (response.statusCode == 404) {
        return [];
      } else {
        throw Exception('Failed to search anime. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: $e');
    }
  }

  Future<Anime> getAnimeById(int malId) async {
    try {
      final url = Uri.parse('$_baseUrl/anime/$malId');

      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonData = json.decode(response.body);

        final Map<String, dynamic> animeData = jsonData['data'] as Map<String, dynamic>;

        final anime = Anime.fromJson(animeData);

        await Future.delayed(const Duration(milliseconds: 400));

        return anime;

      } else if (response.statusCode == 429) {
        throw Exception('Rate limit exceeded. Please wait a moment and try again.');
      } else if (response.statusCode == 404) {
        throw Exception('Anime with ID $malId not found.');
      } else {
        throw Exception('Failed to load anime details. Status: ${response.statusCode}');
      }
    } catch (e) {
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Network error: $e');
    }
  }

  void dispose() {
    _client.close();
  }
}