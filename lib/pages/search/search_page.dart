import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_recommendation_app/bloc/auth/auth_bloc.dart';
import 'package:manga_recommendation_app/models/anime/anime.dart';
import 'package:manga_recommendation_app/models/genre/genre_item.dart';
import 'package:manga_recommendation_app/models/manga/manga.dart';
import 'package:manga_recommendation_app/services/manga/manga_service.dart';
import 'package:manga_recommendation_app/services/preferences/user_preferences_service.dart';

// Search page with filter modal, Adapted to Anime, and Rankings sections
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _textController = TextEditingController();
  bool _lastNsfw = false;

  // Section preview data
  List<Anime> _animePreview = [];
  List<Manga> _rankingsPreview = [];
  bool _animeLoading = true;
  bool _rankingsLoading = true;
  String? _animeError;
  String? _rankingsError;

  @override
  void initState() {
    super.initState();
    _loadSections();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  bool _currentNsfw() =>
      UserPreferencesService.instance.isNsfwEnabled(
        context.read<AuthBloc>().state,
      );

  void _scheduleReloadIfNeeded() {
    final nsfw = _currentNsfw();
    if (nsfw != _lastNsfw) {
      _lastNsfw = nsfw;
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted) _reloadRankingsPreview();
      });
    }
  }

  Future<void> _reloadRankingsPreview() async {
    setState(() {
      _rankingsLoading = true;
      _rankingsError = null;
    });
    final service = context.read<MangaService>();
    final nsfw = _currentNsfw();
    final mangaResult = await service.getTopMangaPaginated(nsfwEnabled: nsfw);
    if (!mounted) return;
    setState(() {
      _rankingsLoading = false;
      mangaResult.fold(
        (e) => _rankingsError = e,
        (r) => _rankingsPreview = r.results.take(10).toList(),
      );
    });
  }

  Future<void> _loadSections() async {
    final service = context.read<MangaService>();
    final nsfw = UserPreferencesService.instance.isNsfwEnabled(
      context.read<AuthBloc>().state,
    );

    // Load anime preview
    final animeResult = await service.getTopAnimePaginated();
    if (!mounted) return;
    setState(() {
      _animeLoading = false;
      animeResult.fold(
        (e) => _animeError = e,
        (r) => _animePreview = r.results.take(10).toList(),
      );
    });

    // Delay to respect Jikan rate limit (3 req/sec)
    await Future.delayed(const Duration(milliseconds: 400));

    // Load rankings preview
    final mangaResult = await service.getTopMangaPaginated(nsfwEnabled: nsfw);
    if (!mounted) return;
    setState(() {
      _rankingsLoading = false;
      mangaResult.fold(
        (e) => _rankingsError = e,
        (r) => _rankingsPreview = r.results.take(10).toList(),
      );
    });
  }

  void _onSearch() {
    final keywords = _textController.text.trim();
    if (keywords.isEmpty) return;
    _textController.clear();
    final nsfw = UserPreferencesService.instance.isNsfwEnabled(
      context.read<AuthBloc>().state,
    );
    context.push('/results', extra: {
      'keywords': keywords,
      'nsfwEnabled': nsfw,
    });
  }

  void _openFilterModal() {
    showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _FilterModal(mangaService: context.read<MangaService>()),
    ).then((result) {
      if (result != null && mounted) {
        final nsfw = UserPreferencesService.instance.isNsfwEnabled(
          context.read<AuthBloc>().state,
        );
        context.push('/results', extra: {
          'keywords': result['keywords'] as String,
          'nsfwEnabled': nsfw,
          'orMode': result['orMode'] as bool,
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: UserPreferencesService.instance,
      builder: (context, _) {
        _scheduleReloadIfNeeded();

        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              children: [
            // Search input with filter icon
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _textController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search genres, themes...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true,
                  fillColor: const Color(0xFF2A2A2A),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.tune, color: Colors.deepPurple),
                    onPressed: _openFilterModal,
                  ),
                ),
                onSubmitted: (_) => _onSearch(),
              ),
            ),
            const SizedBox(height: 24),

            // Adapted to Anime section
            _SectionHeader(
              title: 'Adapted to Anime',
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward,
                    color: Colors.grey, size: 20),
                onPressed: () => context.push('/adapted-anime'),
              ),
            ),
            _AnimePreview(
              anime: _animePreview,
              isLoading: _animeLoading,
              error: _animeError,
            ),
            const SizedBox(height: 24),

            // Rankings section
            _SectionHeader(
              title: 'Rankings',
              trailing: IconButton(
                icon: const Icon(Icons.arrow_forward,
                    color: Colors.grey, size: 20),
                onPressed: () => context.push('/rankings'),
              ),
            ),
            _MangaPreview(
              manga: _rankingsPreview,
              isLoading: _rankingsLoading,
              error: _rankingsError,
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
      },
    );
  }
}

// Section header matching home page style
class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          ?trailing,
        ],
      ),
    );
  }
}

// Horizontal anime card list
class _AnimePreview extends StatelessWidget {
  final List<Anime> anime;
  final bool isLoading;
  final String? error;

  const _AnimePreview({
    required this.anime,
    required this.isLoading,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 220,
        child: Center(
            child: CircularProgressIndicator(color: Colors.deepPurple)),
      );
    }
    if (error != null) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(error!,
              style: TextStyle(color: Colors.grey[400]),
              textAlign: TextAlign.center),
        ),
      );
    }
    if (anime.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
            child:
                Text('No anime found.', style: TextStyle(color: Colors.grey))),
      );
    }
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: anime.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, index) => _AnimeCard(anime: anime[index]),
      ),
    );
  }
}

class _AnimeCard extends StatelessWidget {
  final Anime anime;
  const _AnimeCard({required this.anime});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 130,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 170,
              width: 130,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  anime.imageUrl != null
                      ? Image.network(
                          anime.imageUrl!,
                          height: 170,
                          width: 130,
                          fit: BoxFit.cover,
                          loadingBuilder: (_, child, progress) =>
                              progress == null ? child : _placeholder(),
                          errorBuilder: (_, _, _) => _placeholder(),
                        )
                      : _placeholder(),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black87],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                  if (anime.score > 0)
                    Positioned(
                      bottom: 4,
                      right: 6,
                      child: Text(
                        anime.score.toStringAsFixed(1),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            anime.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 170,
      width: 130,
      color: const Color(0xFF2A2A2A),
      child: const Icon(Icons.movie, color: Colors.grey, size: 32),
    );
  }
}

// Horizontal manga card list
class _MangaPreview extends StatelessWidget {
  final List<Manga> manga;
  final bool isLoading;
  final String? error;

  const _MangaPreview({
    required this.manga,
    required this.isLoading,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 220,
        child: Center(
            child: CircularProgressIndicator(color: Colors.deepPurple)),
      );
    }
    if (error != null) {
      return SizedBox(
        height: 220,
        child: Center(
          child: Text(error!,
              style: TextStyle(color: Colors.grey[400]),
              textAlign: TextAlign.center),
        ),
      );
    }
    if (manga.isEmpty) {
      return const SizedBox(
        height: 220,
        child: Center(
            child:
                Text('No manga found.', style: TextStyle(color: Colors.grey))),
      );
    }
    return SizedBox(
      height: 220,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: manga.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (_, index) => _MangaCard(manga: manga[index]),
      ),
    );
  }
}

class _MangaCard extends StatelessWidget {
  final Manga manga;
  const _MangaCard({required this.manga});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/manga', extra: manga),
      child: SizedBox(
        width: 130,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 170,
                width: 130,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    manga.imageUrl != null
                        ? Image.network(
                            manga.imageUrl!,
                            height: 170,
                            width: 130,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, progress) =>
                                progress == null ? child : _placeholder(),
                            errorBuilder: (_, _, _) => _placeholder(),
                          )
                        : _placeholder(),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black87],
                          stops: [0.5, 1.0],
                        ),
                      ),
                    ),
                    if (manga.score > 0)
                      Positioned(
                        bottom: 4,
                        right: 6,
                        child: Text(
                          manga.score.toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              manga.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      height: 170,
      width: 130,
      color: const Color(0xFF2A2A2A),
      child: const Icon(Icons.menu_book, color: Colors.grey, size: 32),
    );
  }
}

// ─── Filter Modal ───────────────────────────────────────────────────────────

class _FilterModal extends StatefulWidget {
  final MangaService mangaService;
  const _FilterModal({required this.mangaService});

  @override
  State<_FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<_FilterModal> {
  static const _sections = [
    ('Genres', 'genres'),
    ('Explicit Genres', 'explicit_genres'),
    ('Themes', 'themes'),
    ('Demographics', 'demographics'),
  ];

  final Map<String, List<GenreItem>> _data = {};
  final Map<String, bool> _loading = {};
  final Map<String, String?> _errors = {};

  final Set<String> _selectedNames = {};
  bool _orMode = false; // false = AND, true = OR

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    final seenNames = <String>{};
    for (var i = 0; i < _sections.length; i++) {
      final filter = _sections[i].$2;
      setState(() => _loading[filter] = true);
      // Delay between every request to avoid Jikan rate-limit issues
      if (i > 0) {
        await Future.delayed(const Duration(milliseconds: 400));
      }
      final result = await widget.mangaService.getMangaGenres(filter: filter);
      if (!mounted) return;
      setState(() {
        _loading[filter] = false;
        result.fold(
          (error) => _errors[filter] = error,
          (items) {
            // Deduplicate: remove items whose name already appeared in
            // an earlier section (Jikan CDN sometimes returns stale data).
            final unique = items
                .where((item) => seenNames.add(item.name))
                .toList();
            _data[filter] = unique;
          },
        );
      });
    }
  }

  void _toggleGenre(String name) {
    setState(() {
      if (_selectedNames.contains(name)) {
        _selectedNames.remove(name);
      } else {
        _selectedNames.add(name);
      }
    });
  }

  void _onSearch() {
    if (_selectedNames.isEmpty) return;
    Navigator.of(context).pop({
      'keywords': _selectedNames.join(', '),
      'orMode': _orMode,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1E1E),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 8, 0),
            child: Row(
              children: [
                const Text(
                  'Browse by Category',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // AND / OR toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _ModeChip(
                  label: 'AND',
                  description: 'All selected',
                  selected: !_orMode,
                  onTap: () => setState(() => _orMode = false),
                ),
                const SizedBox(width: 8),
                _ModeChip(
                  label: 'OR',
                  description: 'Any selected',
                  selected: _orMode,
                  onTap: () => setState(() => _orMode = true),
                ),
              ],
            ),
          ),

          const Divider(color: Color(0xFF333333), height: 1),

          // Scrollable genre sections
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final section in _sections) ...[
                    _buildSection(
                      title: section.$1,
                      items: _data[section.$2],
                      isLoading: _loading[section.$2] ?? true,
                      error: _errors[section.$2],
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ),

          // Search button
          const Divider(color: Color(0xFF333333), height: 1),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedNames.isEmpty ? null : _onSearch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey[800],
                  disabledForegroundColor: Colors.grey[600],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  _selectedNames.isEmpty
                      ? 'Select genres to search'
                      : 'Search (${_selectedNames.length} selected)',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<GenreItem>? items,
    required bool isLoading,
    required String? error,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const SizedBox(
            height: 32,
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.deepPurple),
              ),
            ),
          )
        else if (error != null)
          Text(error,
              style: TextStyle(color: Colors.grey[500], fontSize: 12))
        else if (items != null)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items.map((item) {
              final isSelected = _selectedNames.contains(item.name);
              return GestureDetector(
                onTap: () => _toggleGenre(item.name),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Colors.deepPurple
                        : const Color(0xFF2A2A2A),
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: Colors.deepPurpleAccent, width: 1)
                        : null,
                  ),
                  child: Text(
                    item.name,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.grey[300],
                      fontSize: 13,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

// AND/OR mode selector chip
class _ModeChip extends StatelessWidget {
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({
    required this.label,
    required this.description,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? Colors.deepPurple : const Color(0xFF2A2A2A),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '$label — $description',
          style: TextStyle(
            color: selected ? Colors.white : Colors.grey[400],
            fontSize: 12,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
