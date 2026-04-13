import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:manga_recommendation_app/bloc/auth/auth_bloc.dart';
import 'package:manga_recommendation_app/bloc/auth/auth_event.dart';
import 'package:manga_recommendation_app/bloc/home/home_cubit.dart';
import 'package:manga_recommendation_app/bloc/register/register_bloc.dart';
import 'package:manga_recommendation_app/config/app_theme.dart';
import 'package:manga_recommendation_app/config/router.dart';
import 'package:manga_recommendation_app/services/auth/auth_service.dart';
import 'package:manga_recommendation_app/services/auth/email_verification_service.dart';
import 'package:manga_recommendation_app/services/manga/manga_service.dart';
import 'package:manga_recommendation_app/services/manga/manga_status_service.dart';
import 'package:manga_recommendation_app/services/preferences/user_preferences_service.dart';
import 'package:manga_recommendation_app/services/auth/user_service.dart';
import 'package:path_provider/path_provider.dart';

// App initialization
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Hive.initFlutter();
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(
      (await getApplicationDocumentsDirectory()).path,
    ),
  );
  await MangaStatusService.init();
  await MangaService.init();
  await UserPreferencesService.init();
  final userService = await UserService.init();
  runApp(MyApp(userService: userService));
}

// Root widget
class MyApp extends StatefulWidget {
  final UserService userService;
  const MyApp({super.key, required this.userService});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AuthBloc _authBloc;
  late final RegisterBloc _registerBloc;
  late final MangaService _mangaService;
  late final HomeCubit _homeCubit;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authBloc = AuthBloc(authService: AuthService(userService: widget.userService))
      ..add(CheckAuthEvent());
    _registerBloc = RegisterBloc(
      userService: widget.userService,
      emailVerificationService: EmailVerificationService(),
    );
    _mangaService = MangaService();
    _homeCubit = HomeCubit(mangaService: _mangaService)..load();
    _router = createRouter(_authBloc);
  }

  @override
  void dispose() {
    _authBloc.close();
    _registerBloc.close();
    _homeCubit.close();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: _mangaService,
      child: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: _authBloc),
          BlocProvider.value(value: _registerBloc),
          BlocProvider.value(value: _homeCubit),
        ],
        child: MaterialApp.router(
          title: 'Manga Management App',
          routerConfig: _router,
          darkTheme: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.deepPurple,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: AppColors.background,
            textTheme: appTextTheme,
          ),
          themeMode: ThemeMode.dark,
        ),
      ),
    );
  }
}
