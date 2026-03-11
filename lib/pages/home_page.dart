import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:manga_recommendation_app/bloc/search_bloc.dart';
import 'package:manga_recommendation_app/bloc/search_event.dart';
import 'package:manga_recommendation_app/bloc/search_state.dart';
import 'package:manga_recommendation_app/pages/manga_info.dart';
import 'package:manga_recommendation_app/pages/results_page.dart';

// Main landing page with search input and surprise-me button
class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late TextEditingController textController;
  bool nsfwEnabled = false;

  @override
  void initState() {
    super.initState();
    textController = TextEditingController();
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<SearchBloc, SearchState>(
        listener: (context, state) {
          // Navigate to results on first-page search success
          if (state is SearchSuccess && state.currentPage == 1) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<SearchBloc>(),
                  child: ResultsPage(
                    results: state.results,
                    keywords: state.keywords,
                    nsfwEnabled: nsfwEnabled,
                  ),
                ),
              ),
            );
          }
          if (state is SearchFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
          // Navigate to detail page on random success
          if (state is RandomSuccess) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => RandomPage(manga: state.manga),
              ),
            );
          }
          if (state is RandomFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // NSFW toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'NSFW',
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: nsfwEnabled,
                      onChanged: (value) =>
                          setState(() => nsfwEnabled = value),
                      activeThumbColor: Colors.deepPurple,
                      inactiveThumbColor: Colors.grey[600],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Heading
                const Text(
                  "What's on your mind?",
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),

                // Search input
                TextField(
                  controller: textController,
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
                ),
                const SizedBox(height: 32),

                // Action buttons
                BlocBuilder<SearchBloc, SearchState>(
                  builder: (context, state) {
                    final isLoading = state is SearchLoading;
                    final isRandomLoading = state is RandomLoading;
                    return Column(
                      children: [
                        // Search button
                        _buildActionButton(
                          label: 'Search',
                          isLoading: isLoading,
                          disabled: isLoading || isRandomLoading,
                          onPressed: () {
                            final keywords = textController.text.trim();
                            if (keywords.isNotEmpty) {
                              context.read<SearchBloc>().add(
                                    SearchRequested(
                                      keywords,
                                      nsfwEnabled: nsfwEnabled,
                                    ),
                                  );
                              textController.clear();
                            }
                          },
                        ),
                        const SizedBox(height: 12),
                        // Surprise me button
                        _buildActionButton(
                          label: 'Surprise Me!',
                          isLoading: isRandomLoading,
                          disabled: isLoading || isRandomLoading,
                          onPressed: () {
                            context.read<SearchBloc>().add(
                                  RandomRequested(nsfwEnabled: nsfwEnabled),
                                );
                            textController.clear();
                          },
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Reusable full-width action button with loading spinner
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