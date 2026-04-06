import 'package:flutter/material.dart';

// Placeholder page for reading status / library
class ReadingStatusPage extends StatelessWidget {
  const ReadingStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: const SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.menu_book, color: Colors.grey, size: 64),
              SizedBox(height: 16),
              Text(
                'Coming Soon',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Your reading list will appear here.',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
