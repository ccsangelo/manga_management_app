import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:manga_recommendation_app/bloc/search_bloc.dart';
import 'package:manga_recommendation_app/pages/home_page.dart';
import 'package:manga_recommendation_app/services/manga_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MyApp());
}

// App root with dark theme and BLoC provider
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Manga Management App',
      darkTheme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
      ),
      themeMode: ThemeMode.dark,
      home: BlocProvider(
        create: (_) => SearchBloc(mangaService: MangaService()),
        child: const HomePage(),
      ),
    );
  }
}
