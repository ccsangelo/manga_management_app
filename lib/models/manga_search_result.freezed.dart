// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'manga_search_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$MangaSearchResult {
  List<Manga> get results => throw _privateConstructorUsedError;
  int get currentPage => throw _privateConstructorUsedError;
  int get lastPage => throw _privateConstructorUsedError;
  bool get hasNextPage => throw _privateConstructorUsedError;

  /// Create a copy of MangaSearchResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MangaSearchResultCopyWith<MangaSearchResult> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MangaSearchResultCopyWith<$Res> {
  factory $MangaSearchResultCopyWith(
    MangaSearchResult value,
    $Res Function(MangaSearchResult) then,
  ) = _$MangaSearchResultCopyWithImpl<$Res, MangaSearchResult>;
  @useResult
  $Res call({
    List<Manga> results,
    int currentPage,
    int lastPage,
    bool hasNextPage,
  });
}

/// @nodoc
class _$MangaSearchResultCopyWithImpl<$Res, $Val extends MangaSearchResult>
    implements $MangaSearchResultCopyWith<$Res> {
  _$MangaSearchResultCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MangaSearchResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? results = null,
    Object? currentPage = null,
    Object? lastPage = null,
    Object? hasNextPage = null,
  }) {
    return _then(
      _value.copyWith(
            results: null == results
                ? _value.results
                : results // ignore: cast_nullable_to_non_nullable
                      as List<Manga>,
            currentPage: null == currentPage
                ? _value.currentPage
                : currentPage // ignore: cast_nullable_to_non_nullable
                      as int,
            lastPage: null == lastPage
                ? _value.lastPage
                : lastPage // ignore: cast_nullable_to_non_nullable
                      as int,
            hasNextPage: null == hasNextPage
                ? _value.hasNextPage
                : hasNextPage // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$MangaSearchResultImplCopyWith<$Res>
    implements $MangaSearchResultCopyWith<$Res> {
  factory _$$MangaSearchResultImplCopyWith(
    _$MangaSearchResultImpl value,
    $Res Function(_$MangaSearchResultImpl) then,
  ) = __$$MangaSearchResultImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    List<Manga> results,
    int currentPage,
    int lastPage,
    bool hasNextPage,
  });
}

/// @nodoc
class __$$MangaSearchResultImplCopyWithImpl<$Res>
    extends _$MangaSearchResultCopyWithImpl<$Res, _$MangaSearchResultImpl>
    implements _$$MangaSearchResultImplCopyWith<$Res> {
  __$$MangaSearchResultImplCopyWithImpl(
    _$MangaSearchResultImpl _value,
    $Res Function(_$MangaSearchResultImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of MangaSearchResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? results = null,
    Object? currentPage = null,
    Object? lastPage = null,
    Object? hasNextPage = null,
  }) {
    return _then(
      _$MangaSearchResultImpl(
        results: null == results
            ? _value._results
            : results // ignore: cast_nullable_to_non_nullable
                  as List<Manga>,
        currentPage: null == currentPage
            ? _value.currentPage
            : currentPage // ignore: cast_nullable_to_non_nullable
                  as int,
        lastPage: null == lastPage
            ? _value.lastPage
            : lastPage // ignore: cast_nullable_to_non_nullable
                  as int,
        hasNextPage: null == hasNextPage
            ? _value.hasNextPage
            : hasNextPage // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$MangaSearchResultImpl implements _MangaSearchResult {
  const _$MangaSearchResultImpl({
    required final List<Manga> results,
    required this.currentPage,
    required this.lastPage,
    required this.hasNextPage,
  }) : _results = results;

  final List<Manga> _results;
  @override
  List<Manga> get results {
    if (_results is EqualUnmodifiableListView) return _results;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_results);
  }

  @override
  final int currentPage;
  @override
  final int lastPage;
  @override
  final bool hasNextPage;

  @override
  String toString() {
    return 'MangaSearchResult(results: $results, currentPage: $currentPage, lastPage: $lastPage, hasNextPage: $hasNextPage)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MangaSearchResultImpl &&
            const DeepCollectionEquality().equals(other._results, _results) &&
            (identical(other.currentPage, currentPage) ||
                other.currentPage == currentPage) &&
            (identical(other.lastPage, lastPage) ||
                other.lastPage == lastPage) &&
            (identical(other.hasNextPage, hasNextPage) ||
                other.hasNextPage == hasNextPage));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_results),
    currentPage,
    lastPage,
    hasNextPage,
  );

  /// Create a copy of MangaSearchResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MangaSearchResultImplCopyWith<_$MangaSearchResultImpl> get copyWith =>
      __$$MangaSearchResultImplCopyWithImpl<_$MangaSearchResultImpl>(
        this,
        _$identity,
      );
}

abstract class _MangaSearchResult implements MangaSearchResult {
  const factory _MangaSearchResult({
    required final List<Manga> results,
    required final int currentPage,
    required final int lastPage,
    required final bool hasNextPage,
  }) = _$MangaSearchResultImpl;

  @override
  List<Manga> get results;
  @override
  int get currentPage;
  @override
  int get lastPage;
  @override
  bool get hasNextPage;

  /// Create a copy of MangaSearchResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MangaSearchResultImplCopyWith<_$MangaSearchResultImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
