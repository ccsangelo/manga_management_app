import 'package:freezed_annotation/freezed_annotation.dart';

part 'manga.freezed.dart';
part 'manga.g.dart';

// JSON parsing helpers
List<String> _extractNames(List<dynamic>? items) =>
    (items ?? [])
        .map((item) => (item['name'] as String).toLowerCase())
        .toList();

String? _extractImageUrl(Map<String, dynamic>? images) =>
    (images?['jpg'] as Map<String, dynamic>?)?['image_url'] as String?;

// Manga model
@freezed
class Manga with _$Manga {
  const factory Manga({
    @JsonKey(name: 'mal_id') required int malId,
    required String title,
    @JsonKey(fromJson: _extractNames) required List<String> genres,
    @JsonKey(fromJson: _extractNames) required List<String> themes,
    @JsonKey(fromJson: _extractNames) required List<String> demographics,
    @JsonKey(name: 'serializations', fromJson: _extractNames)
    required List<String> magazines,
    @Default('') String synopsis,
    @JsonKey(name: 'images', fromJson: _extractImageUrl) String? imageUrl,
    @Default(0.0) double score,
  }) = _Manga;

  factory Manga.fromJson(Map<String, dynamic> json) => _$MangaFromJson(json);
}
