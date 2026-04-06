import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:manga_recommendation_app/services/manga_service.dart';

// Search page with genre search and random manga
class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _textController = TextEditingController();
  bool _nsfwEnabled = false;
  bool _isRandomLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _onSearch() {
    final keywords = _textController.text.trim();
    if (keywords.isEmpty) return;
    _textController.clear();
    context.push('/results', extra: {
      'keywords': keywords,
      'nsfwEnabled': _nsfwEnabled,
    });
  }

  Future<void> _onSurpriseMe() async {
    if (_isRandomLoading) return;
    setState(() => _isRandomLoading = true);
    final result = await context
        .read<MangaService>()
        .getRandom(nsfwEnabled: _nsfwEnabled);
    if (!mounted) return;
    setState(() => _isRandomLoading = false);
    result.fold(
      (error) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.redAccent),
      ),
      (manga) => context.push('/manga', extra: manga),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'NSFW',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: _nsfwEnabled,
                      onChanged: (value) =>
                          setState(() => _nsfwEnabled = value),
                      activeThumbColor: Colors.deepPurple,
                      inactiveThumbColor: Colors.grey[600],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  "What's on your mind?",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'e.g. romance, action, comedy',
                    hintStyle: TextStyle(color: Colors.grey[500]),
                    filled: true,
                    fillColor: const Color(0xFF1E1E1E),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24.0),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 14.0,
                    ),
                  ),
                  onSubmitted: (_) => _onSearch(),
                ),
                const SizedBox(height: 32),
                _buildActionButton(
                  label: 'Search',
                  isLoading: false,
                  disabled: _isRandomLoading,
                  onPressed: _onSearch,
                ),
                const SizedBox(height: 12),
                _buildActionButton(
                  label: 'Surprise Me!',
                  isLoading: _isRandomLoading,
                  disabled: _isRandomLoading,
                  onPressed: _onSurpriseMe,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required bool isLoading,
    required bool disabled,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.deepPurple,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.0),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14.0),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(label),
      ),
    );
  }
}
