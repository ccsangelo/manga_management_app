// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'manga.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Manga _$MangaFromJson(Map<String, dynamic> json) {
  return _Manga.fromJson(json);
}

/// @nodoc
mixin _$Manga {
  @JsonKey(name: 'mal_id')
  int get malId => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _extractNames)
  List<String> get genres => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _extractNames)
  List<String> get themes => throw _privateConstructorUsedError;
  @JsonKey(fromJson: _extractNames)
  List<String> get demographics => throw _privateConstructorUsedError;
  @JsonKey(name: 'serializations', fromJson: _extractNames)
  List<String> get magazines => throw _privateConstructorUsedError;
  String get synopsis => throw _privateConstructorUsedError;
  @JsonKey(name: 'images', fromJson: _extractImageUrl)
  String? get imageUrl => throw _privateConstructorUsedError;
  double get score => throw _privateConstructorUsedError;

  /// Serializes this Manga to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Manga
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MangaCopyWith<Manga> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MangaCopyWith<$Res> {
  factory $MangaCopyWith(Manga value, $Res Function(Manga) then) =
      _$MangaCopyWithImpl<$Res, Manga>;
  @useResult
  $Res call({
    @JsonKey(name: 'mal_id') int malId,
    String title,
    @JsonKey(fromJson: _extractNames) List<String> genres,
    @JsonKey(fromJson: _extractNames) List<String> themes,
    @JsonKey(fromJson: _extractNames) List<String> demographics,
    @JsonKey(name: 'serializations', fromJson: _extractNames)
    List<String> magazines,
    String synopsis,
    @JsonKey(name: 'images', fromJson: _extractImageUrl) String? imageUrl,
    double score,
  });
}

/// @nodoc
class _$MangaCopyWithImpl<$Res, $Val extends Manga>
    implements $MangaCopyWith<$Res> {
  _$MangaCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Manga
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? malId = null,
    Object? title = null,
    Object? genres = null,
    Object? themes = null,
    Object? demographics = null,
    Object? magazines = null,
    Object? synopsis = null,
    Object? imageUrl = freezed,
    Object? score = null,
  }) {
    return _then(
      _value.copyWith(
            malId: null == malId
                ? _value.malId
                : malId // ignore: cast_nullable_to_non_nullable
                      as int,
            title: null == title
                ? _value.title
                : title // ignore: cast_nullable_to_non_nullable
                      as String,
            genres: null == genres
                ? _value.genres
                : genres // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            themes: null == themes
                ? _value.themes
                : themes // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            demographics: null == demographics
                ? _value.demographics
                : demographics // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            magazines: null == magazines
                ? _value.magazines
                : magazines // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            synopsis: null == synopsis
                ? _value.synopsis
                : synopsis // ignore: cast_nullable_to_non_nullable
                      as String,
            imageUrl: freezed == imageUrl
                ? _value.imageUrl
                : imageUrl // ignore: cast_nullable_to_non_nullable
                      as String?,
            score: null == score
                ? _value.score
                : score // ignore: cast_nullable_to_non_nullable
                      as double,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MangaImplCopyWith<$Res> implements $MangaCopyWith<$Res> {
  factory _$$MangaImplCopyWith(
    _$MangaImpl value,
    $Res Function(_$MangaImpl) then,
  ) = __$$MangaImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @JsonKey(name: 'mal_id') int malId,
    String title,
    @JsonKey(fromJson: _extractNames) List<String> genres,
    @JsonKey(fromJson: _extractNames) List<String> themes,
    @JsonKey(fromJson: _extractNames) List<String> demographics,
    @JsonKey(name: 'serializations', fromJson: _extractNames)
    List<String> magazines,
    String synopsis,
    @JsonKey(name: 'images', fromJson: _extractImageUrl) String? imageUrl,
    double score,
  });
}

/// @nodoc
class __$$MangaImplCopyWithImpl<$Res>
    extends _$MangaCopyWithImpl<$Res, _$MangaImpl>
    implements _$$MangaImplCopyWith<$Res> {
  __$$MangaImplCopyWithImpl(
    _$MangaImpl _value,
    $Res Function(_$MangaImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Manga
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? malId = null,
    Object? title = null,
    Object? genres = null,
    Object? themes = null,
    Object? demographics = null,
    Object? magazines = null,
    Object? synopsis = null,
    Object? imageUrl = freezed,
    Object? score = null,
  }) {
    return _then(
      _$MangaImpl(
        malId: null == malId
            ? _value.malId
            : malId // ignore: cast_nullable_to_non_nullable
                  as int,
        title: null == title
            ? _value.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        genres: null == genres
            ? _value._genres
            : genres // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        themes: null == themes
            ? _value._themes
            : themes // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        demographics: null == demographics
            ? _value._demographics
            : demographics // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        magazines: null == magazines
            ? _value._magazines
            : magazines // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        synopsis: null == synopsis
            ? _value.synopsis
            : synopsis // ignore: cast_nullable_to_non_nullable
                  as String,
        imageUrl: freezed == imageUrl
            ? _value.imageUrl
            : imageUrl // ignore: cast_nullable_to_non_nullable
                  as String?,
        score: null == score
            ? _value.score
            : score // ignore: cast_nullable_to_non_nullable
                  as double,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$MangaImpl implements _Manga {
  const _$MangaImpl({
    @JsonKey(name: 'mal_id') required this.malId,
    required this.title,
    @JsonKey(fromJson: _extractNames) required final List<String> genres,
    @JsonKey(fromJson: _extractNames) required final List<String> themes,
    @JsonKey(fromJson: _extractNames) required final List<String> demographics,
    @JsonKey(name: 'serializations', fromJson: _extractNames)
    required final List<String> magazines,
    this.synopsis = '',
    @JsonKey(name: 'images', fromJson: _extractImageUrl) this.imageUrl,
    this.score = 0.0,
  }) : _genres = genres,
       _themes = themes,
       _demographics = demographics,
       _magazines = magazines;

  factory _$MangaImpl.fromJson(Map<String, dynamic> json) =>
      _$$MangaImplFromJson(json);

  @override
  @JsonKey(name: 'mal_id')
  final int malId;
  @override
  final String title;
  final List<String> _genres;
  @override
  @JsonKey(fromJson: _extractNames)
  List<String> get genres {
    if (_genres is EqualUnmodifiableListView) return _genres;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_genres);
  }

  final List<String> _themes;
  @override
  @JsonKey(fromJson: _extractNames)
  List<String> get themes {
    if (_themes is EqualUnmodifiableListView) return _themes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_themes);
  }

  final List<String> _demographics;
  @override
  @JsonKey(fromJson: _extractNames)
  List<String> get demographics {
    if (_demographics is EqualUnmodifiableListView) return _demographics;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_demographics);
  }

  final List<String> _magazines;
  @override
  @JsonKey(name: 'serializations', fromJson: _extractNames)
  List<String> get magazines {
    if (_magazines is EqualUnmodifiableListView) return _magazines;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_magazines);
  }

  @override
  @JsonKey()
  final String synopsis;
  @override
  @JsonKey(name: 'images', fromJson: _extractImageUrl)
  final String? imageUrl;
  @override
  @JsonKey()
  final double score;

  @override
  String toString() {
    return 'Manga(malId: $malId, title: $title, genres: $genres, themes: $themes, demographics: $demographics, magazines: $magazines, synopsis: $synopsis, imageUrl: $imageUrl, score: $score)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MangaImpl &&
            (identical(other.malId, malId) || other.malId == malId) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(other._genres, _genres) &&
            const DeepCollectionEquality().equals(other._themes, _themes) &&
            const DeepCollectionEquality().equals(
              other._demographics,
              _demographics,
            ) &&
            const DeepCollectionEquality().equals(
              other._magazines,
              _magazines,
            ) &&
            (identical(other.synopsis, synopsis) ||
                other.synopsis == synopsis) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.score, score) || other.score == score));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    malId,
    title,
    const DeepCollectionEquality().hash(_genres),
    const DeepCollectionEquality().hash(_themes),
    const DeepCollectionEquality().hash(_demographics),
    const DeepCollectionEquality().hash(_magazines),
    synopsis,
    imageUrl,
    score,
  );

  /// Create a copy of Manga
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MangaImplCopyWith<_$MangaImpl> get copyWith =>
      __$$MangaImplCopyWithImpl<_$MangaImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MangaImplToJson(this);
  }
}

abstract class _Manga implements Manga {
  const factory _Manga({
    @JsonKey(name: 'mal_id') required final int malId,
    required final String title,
    @JsonKey(fromJson: _extractNames) required final List<String> genres,
    @JsonKey(fromJson: _extractNames) required final List<String> themes,
    @JsonKey(fromJson: _extractNames) required final List<String> demographics,
    @JsonKey(name: 'serializations', fromJson: _extractNames)
    required final List<String> magazines,
    final String synopsis,
    @JsonKey(name: 'images', fromJson: _extractImageUrl) final String? imageUrl,
    final double score,
  }) = _$MangaImpl;

  factory _Manga.fromJson(Map<String, dynamic> json) = _$MangaImpl.fromJson;

  @override
  @JsonKey(name: 'mal_id')
  int get malId;
  @override
  String get title;
  @override
  @JsonKey(fromJson: _extractNames)
  List<String> get genres;
  @override
  @JsonKey(fromJson: _extractNames)
  List<String> get themes;
  @override
  @JsonKey(fromJson: _extractNames)
  List<String> get demographics;
  @override
  @JsonKey(name: 'serializations', fromJson: _extractNames)
  List<String> get magazines;
  @override
  String get synopsis;
  @override
  @JsonKey(name: 'images', fromJson: _extractImageUrl)
  String? get imageUrl;
  @override
  double get score;

  /// Create a copy of Manga
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MangaImplCopyWith<_$MangaImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
