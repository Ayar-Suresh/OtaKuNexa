// anime_model.dart

class AnimeModel {
  final AnimeData data;

  AnimeModel({required this.data});

  factory AnimeModel.fromJson(Map<String, dynamic> json) {
    return AnimeModel(data: AnimeData.fromJson(json['data']));
  }

  Map<String, dynamic> toJson() {
    return {'data': data.toJson()};
  }
}

class AnimeData {
  final int malId;
  final String url;
  final AnimeImages images;
  final AnimeTrailer trailer;
  final bool approved;
  final List<AnimeTitle> titles;
  final String title;
  final String titleEnglish;
  final String titleJapanese;
  final List<String> titleSynonyms;
  final String type;
  final String source;
  final int? episodes;
  final String status;
  final bool airing;
  final AnimeAired aired;
  final String duration;
  final String rating;
  final double score;
  final int scoredBy;
  final int rank;
  final int popularity;
  final int members;
  final int favorites;
  final String synopsis;
  final String background;
  final String season;
  final int year;
  final AnimeBroadcast broadcast;
  final List<AnimeProducer> producers;
  final List<AnimeProducer> licensors;
  final List<AnimeStudio> studios;
  final List<AnimeGenre> genres;
  final List<AnimeGenre> explicitGenres;
  final List<AnimeGenre> themes;
  final List<AnimeGenre> demographics;

  AnimeData({
    required this.malId,
    required this.url,
    required this.images,
    required this.trailer,
    required this.approved,
    required this.titles,
    required this.title,
    required this.titleEnglish,
    required this.titleJapanese,
    required this.titleSynonyms,
    required this.type,
    required this.source,
    this.episodes,
    required this.status,
    required this.airing,
    required this.aired,
    required this.duration,
    required this.rating,
    required this.score,
    required this.scoredBy,
    required this.rank,
    required this.popularity,
    required this.members,
    required this.favorites,
    required this.synopsis,
    required this.background,
    required this.season,
    required this.year,
    required this.broadcast,
    required this.producers,
    required this.licensors,
    required this.studios,
    required this.genres,
    required this.explicitGenres,
    required this.themes,
    required this.demographics,
  });

  factory AnimeData.fromJson(Map<String, dynamic> json) {
    return AnimeData(
      malId: json['mal_id'] ?? 0,
      url: json['url'] ?? '',
      images: AnimeImages.fromJson(json['images'] ?? {}),
      trailer: AnimeTrailer.fromJson(json['trailer'] ?? {}),
      approved: json['approved'] ?? false,
      titles:
          (json['titles'] as List<dynamic>?)
              ?.map((title) => AnimeTitle.fromJson(title))
              .toList() ??
          [],
      title: json['title'] ?? '',
      titleEnglish: json['title_english'] ?? '',
      titleJapanese: json['title_japanese'] ?? '',
      titleSynonyms: List<String>.from(json['title_synonyms'] ?? []),
      type: json['type'] ?? '',
      source: json['source'] ?? '',
      episodes: json['episodes'],
      status: json['status'] ?? '',
      airing: json['airing'] ?? false,
      aired: AnimeAired.fromJson(json['aired'] ?? {}),
      duration: json['duration'] ?? '',
      rating: json['rating'] ?? '',
      score: (json['score'] as num?)?.toDouble() ?? 0.0,
      scoredBy: json['scored_by'] ?? 0,
      rank: json['rank'] ?? 0,
      popularity: json['popularity'] ?? 0,
      members: json['members'] ?? 0,
      favorites: json['favorites'] ?? 0,
      synopsis: json['synopsis'] ?? '',
      background: json['background'] ?? '',
      season: json['season'] ?? '',
      year: json['year'] ?? 0,
      broadcast: AnimeBroadcast.fromJson(json['broadcast'] ?? {}),
      producers:
          (json['producers'] as List<dynamic>?)
              ?.map((prod) => AnimeProducer.fromJson(prod))
              .toList() ??
          [],
      licensors:
          (json['licensors'] as List<dynamic>?)
              ?.map((lic) => AnimeProducer.fromJson(lic))
              .toList() ??
          [],
      studios:
          (json['studios'] as List<dynamic>?)
              ?.map((studio) => AnimeStudio.fromJson(studio))
              .toList() ??
          [],
      genres:
          (json['genres'] as List<dynamic>?)
              ?.map((genre) => AnimeGenre.fromJson(genre))
              .toList() ??
          [],
      explicitGenres:
          (json['explicit_genres'] as List<dynamic>?)
              ?.map((genre) => AnimeGenre.fromJson(genre))
              .toList() ??
          [],
      themes:
          (json['themes'] as List<dynamic>?)
              ?.map((theme) => AnimeGenre.fromJson(theme))
              .toList() ??
          [],
      demographics:
          (json['demographics'] as List<dynamic>?)
              ?.map((demo) => AnimeGenre.fromJson(demo))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'mal_id': malId,
      'url': url,
      'images': images.toJson(),
      'trailer': trailer.toJson(),
      'approved': approved,
      'titles': titles.map((title) => title.toJson()).toList(),
      'title': title,
      'title_english': titleEnglish,
      'title_japanese': titleJapanese,
      'title_synonyms': titleSynonyms,
      'type': type,
      'source': source,
      'episodes': episodes,
      'status': status,
      'airing': airing,
      'aired': aired.toJson(),
      'duration': duration,
      'rating': rating,
      'score': score,
      'scored_by': scoredBy,
      'rank': rank,
      'popularity': popularity,
      'members': members,
      'favorites': favorites,
      'synopsis': synopsis,
      'background': background,
      'season': season,
      'year': year,
      'broadcast': broadcast.toJson(),
      'producers': producers.map((prod) => prod.toJson()).toList(),
      'licensors': licensors.map((lic) => lic.toJson()).toList(),
      'studios': studios.map((studio) => studio.toJson()).toList(),
      'genres': genres.map((genre) => genre.toJson()).toList(),
      'explicit_genres': explicitGenres.map((genre) => genre.toJson()).toList(),
      'themes': themes.map((theme) => theme.toJson()).toList(),
      'demographics': demographics.map((demo) => demo.toJson()).toList(),
    };
  }
}

// Nested Models
class AnimeImages {
  final AnimeImage jpg;
  final AnimeImage webp;

  AnimeImages({required this.jpg, required this.webp});

  factory AnimeImages.fromJson(Map<String, dynamic> json) {
    return AnimeImages(
      jpg: AnimeImage.fromJson(json['jpg'] ?? {}),
      webp: AnimeImage.fromJson(json['webp'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'jpg': jpg.toJson(), 'webp': webp.toJson()};
  }
}

class AnimeImage {
  final String imageUrl;
  final String smallImageUrl;
  final String largeImageUrl;

  AnimeImage({
    required this.imageUrl,
    required this.smallImageUrl,
    required this.largeImageUrl,
  });

  factory AnimeImage.fromJson(Map<String, dynamic> json) {
    return AnimeImage(
      imageUrl: json['image_url'] ?? '',
      smallImageUrl: json['small_image_url'] ?? '',
      largeImageUrl: json['large_image_url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image_url': imageUrl,
      'small_image_url': smallImageUrl,
      'large_image_url': largeImageUrl,
    };
  }
}

class AnimeTrailer {
  final String? youtubeId;
  final String? url;
  final String? embedUrl;
  final AnimeTrailerImages images;

  AnimeTrailer({this.youtubeId, this.url, this.embedUrl, required this.images});

  factory AnimeTrailer.fromJson(Map<String, dynamic> json) {
    return AnimeTrailer(
      youtubeId: json['youtube_id'],
      url: json['url'],
      embedUrl: json['embed_url'],
      images: AnimeTrailerImages.fromJson(json['images'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'youtube_id': youtubeId,
      'url': url,
      'embed_url': embedUrl,
      'images': images.toJson(),
    };
  }
}

class AnimeTrailerImages {
  final String? imageUrl;
  final String? smallImageUrl;
  final String? mediumImageUrl;
  final String? largeImageUrl;
  final String? maximumImageUrl;

  AnimeTrailerImages({
    this.imageUrl,
    this.smallImageUrl,
    this.mediumImageUrl,
    this.largeImageUrl,
    this.maximumImageUrl,
  });

  factory AnimeTrailerImages.fromJson(Map<String, dynamic> json) {
    return AnimeTrailerImages(
      imageUrl: json['image_url'],
      smallImageUrl: json['small_image_url'],
      mediumImageUrl: json['medium_image_url'],
      largeImageUrl: json['large_image_url'],
      maximumImageUrl: json['maximum_image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'image_url': imageUrl,
      'small_image_url': smallImageUrl,
      'medium_image_url': mediumImageUrl,
      'large_image_url': largeImageUrl,
      'maximum_image_url': maximumImageUrl,
    };
  }
}

class AnimeTitle {
  final String type;
  final String title;

  AnimeTitle({required this.type, required this.title});

  factory AnimeTitle.fromJson(Map<String, dynamic> json) {
    return AnimeTitle(type: json['type'] ?? '', title: json['title'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'title': title};
  }
}

class AnimeAired {
  final DateTime? from;
  final DateTime? to;
  final AnimeAiredProp prop;
  final String string;

  AnimeAired({this.from, this.to, required this.prop, required this.string});

  factory AnimeAired.fromJson(Map<String, dynamic> json) {
    return AnimeAired(
      from: json['from'] != null ? DateTime.parse(json['from']) : null,
      to: json['to'] != null ? DateTime.parse(json['to']) : null,
      prop: AnimeAiredProp.fromJson(json['prop'] ?? {}),
      string: json['string'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'from': from?.toIso8601String(),
      'to': to?.toIso8601String(),
      'prop': prop.toJson(),
      'string': string,
    };
  }
}

class AnimeAiredProp {
  final AnimeAiredDate from;
  final AnimeAiredDate to;

  AnimeAiredProp({required this.from, required this.to});

  factory AnimeAiredProp.fromJson(Map<String, dynamic> json) {
    return AnimeAiredProp(
      from: AnimeAiredDate.fromJson(json['from'] ?? {}),
      to: AnimeAiredDate.fromJson(json['to'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {'from': from.toJson(), 'to': to.toJson()};
  }
}

class AnimeAiredDate {
  final int? day;
  final int? month;
  final int? year;

  AnimeAiredDate({this.day, this.month, this.year});

  factory AnimeAiredDate.fromJson(Map<String, dynamic> json) {
    return AnimeAiredDate(
      day: json['day'],
      month: json['month'],
      year: json['year'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'day': day, 'month': month, 'year': year};
  }
}

class AnimeBroadcast {
  final String day;
  final String time;
  final String timezone;
  final String string;

  AnimeBroadcast({
    required this.day,
    required this.time,
    required this.timezone,
    required this.string,
  });

  factory AnimeBroadcast.fromJson(Map<String, dynamic> json) {
    return AnimeBroadcast(
      day: json['day'] ?? '',
      time: json['time'] ?? '',
      timezone: json['timezone'] ?? '',
      string: json['string'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'day': day, 'time': time, 'timezone': timezone, 'string': string};
  }
}

class AnimeProducer {
  final int malId;
  final String type;
  final String name;
  final String url;

  AnimeProducer({
    required this.malId,
    required this.type,
    required this.name,
    required this.url,
  });

  factory AnimeProducer.fromJson(Map<String, dynamic> json) {
    return AnimeProducer(
      malId: json['mal_id'] ?? 0,
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'mal_id': malId, 'type': type, 'name': name, 'url': url};
  }
}

class AnimeStudio {
  final int malId;
  final String type;
  final String name;
  final String url;

  AnimeStudio({
    required this.malId,
    required this.type,
    required this.name,
    required this.url,
  });

  factory AnimeStudio.fromJson(Map<String, dynamic> json) {
    return AnimeStudio(
      malId: json['mal_id'] ?? 0,
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'mal_id': malId, 'type': type, 'name': name, 'url': url};
  }
}

class AnimeGenre {
  final int malId;
  final String type;
  final String name;
  final String url;

  AnimeGenre({
    required this.malId,
    required this.type,
    required this.name,
    required this.url,
  });

  factory AnimeGenre.fromJson(Map<String, dynamic> json) {
    return AnimeGenre(
      malId: json['mal_id'] ?? 0,
      type: json['type'] ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'mal_id': malId, 'type': type, 'name': name, 'url': url};
  }
}
