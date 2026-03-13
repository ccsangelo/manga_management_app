// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'manga.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$MangaImpl _$$MangaImplFromJson(Map<String, dynamic> json) => _$MangaImpl(
  malId: (json['mal_id'] as num).toInt(),
  title: json['title'] as String,
  genres: _extractNames(json['genres'] as List?),
  themes: _extractNames(json['themes'] as List?),
  demographics: _extractNames(json['demographics'] as List?),
  magazines: _extractNames(json['serializations'] as List?),
  synopsis: json['synopsis'] as String? ?? '',
  imageUrl: _extractImageUrl(json['images'] as Map<String, dynamic>?),
  score: (json['score'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$$MangaImplToJson(_$MangaImpl instance) =>
    <String, dynamic>{
      'mal_id': instance.malId,
      'title': instance.title,
      'genres': instance.genres,
      'themes': instance.themes,
      'demographics': instance.demographics,
      'serializations': instance.magazines,
      'synopsis': instance.synopsis,
      'images': instance.imageUrl,
      'score': instance.score,
    };
