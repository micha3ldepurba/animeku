class Anime {
  final int malId;
  final String title;
  final String? imageUrl;
  final String? largeImageUrl;
  final List<String> genres;
  final double? score;
  final int? episodes;
  final String? synopsis;
  final String? type;
  final int? year;
  final String? status;
  final String? ageRating;

  const Anime({
    required this.malId,
    required this.title,
    this.imageUrl,
    this.largeImageUrl,
    this.genres = const [],
    this.score,
    this.episodes,
    this.synopsis,
    this.type,
    this.year,
    this.status,
    this.ageRating,
  });

  factory Anime.fromJson(Map<String, dynamic> json) {
    List<String> genreList = [];
    if (json['genres'] != null) {
      genreList = (json['genres'] as List)
          .map((genre) => genre['name'] as String)
          .toList();
    }

    return Anime(
      malId: json['mal_id'] as int,
      title: json['title'] as String,
      imageUrl: json['images']?['jpg']?['image_url'] as String?,
      largeImageUrl: json['images']?['jpg']?['large_image_url'] as String?,
      genres: genreList,
      score: (json['score'] as num?)?.toDouble(),
      episodes: json['episodes'] as int?,
      synopsis: json['synopsis'] as String?,
      type: json['type'] as String?,
      year: json['year'] as int?,
      status: json['status'] as String?,
      ageRating: json['rating'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mal_id': malId,
      'title': title,
      'image_url': imageUrl,
      'large_image_url': largeImageUrl,
      'genres': genres,
      'score': score,
      'episodes': episodes,
      'synopsis': synopsis,
      'type': type,
      'year': year,
      'status': status,
      'age_rating': ageRating,
    };
  }

  factory Anime.fromFavoritesJson(Map<String, dynamic> json) {
    return Anime(
      malId: json['mal_id'] as int,
      title: json['title'] as String,
      imageUrl: json['image_url'] as String?,
      largeImageUrl: json['large_image_url'] as String?,
      genres: (json['genres'] as List?)?.cast<String>() ?? [],
      score: (json['score'] as num?)?.toDouble(),
      episodes: json['episodes'] as int?,
      synopsis: json['synopsis'] as String?,
      type: json['type'] as String?,
      year: json['year'] as int?,
      status: json['status'] as String?,
      ageRating: json['age_rating'] as String?,
    );
  }

  bool get isAppropriateContent {
    if (ageRating != null && ageRating!.startsWith('Rx')) {
      return false;
    }
    return true;
  }

  String get id => malId.toString();
  String get imagePath => imageUrl ?? '';
  String get genre => genres.join(', ');
  String get rating => score?.toStringAsFixed(2) ?? 'N/A';
  String get totalEpisodes => episodes?.toString() ?? 'Unknown';
  String get description => synopsis ?? 'No description available';
}