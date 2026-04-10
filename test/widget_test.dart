import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mocktail/mocktail.dart';

import 'package:manga_recommendation_app/bloc/auth/auth_bloc.dart';
import 'package:manga_recommendation_app/bloc/auth/auth_event.dart';
import 'package:manga_recommendation_app/bloc/auth/auth_state.dart';
import 'package:manga_recommendation_app/bloc/home/home_cubit.dart';
import 'package:manga_recommendation_app/bloc/register/register_bloc.dart';
import 'package:manga_recommendation_app/bloc/register/register_event.dart';
import 'package:manga_recommendation_app/bloc/register/register_state.dart';
import 'package:manga_recommendation_app/pages/auth/login_page.dart';
import 'package:manga_recommendation_app/pages/auth/user_page.dart';
import 'package:manga_recommendation_app/services/auth/auth_service.dart';
import 'package:manga_recommendation_app/services/auth/email_verification_service.dart';
import 'package:manga_recommendation_app/services/manga/manga_service.dart';
import 'package:manga_recommendation_app/services/manga/manga_status_service.dart';
import 'package:manga_recommendation_app/services/preferences/user_preferences_service.dart';
import 'package:manga_recommendation_app/services/auth/user_service.dart';

// Service mocks (for bloc unit tests)
class MockAuthService extends Mock implements AuthService {}

class MockUserService extends Mock implements UserService {}

class MockEmailVerificationService extends Mock
    implements EmailVerificationService {}

// Bloc mock (for widget tests)
class MockAuthBloc extends Mock implements AuthBloc {}

class MockMangaService extends Mock implements MangaService {}

// Fallback values
class FakeAuthEvent extends Fake implements AuthEvent {}

void main() {
  setUpAll(() async {
    registerFallbackValue(FakeAuthEvent());
    Hive.init('build/test_cache/widget');
    await UserPreferencesService.init();
    await MangaStatusService.init();
  });

  // ===================== AuthBloc Unit Tests =====================
  group('AuthBloc', () {
    late MockAuthService mockAuthService;

    setUp(() {
      mockAuthService = MockAuthService();
    });

    AuthBloc buildBloc() => AuthBloc(authService: mockAuthService);

    test('initial state is AuthLoading', () {
      final bloc = buildBloc();
      expect(bloc.state, isA<AuthLoading>());
      bloc.close();
    });

    test('emits [AuthAuthenticated] on CheckAuthEvent when token exists', () {
      when(() => mockAuthService.getValidToken())
          .thenAnswer((_) async => 'valid_token');
      final bloc = buildBloc();

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthAuthenticated>()
              .having((s) => s.token, 'token', 'valid_token'),
        ]),
      );

      bloc.add(CheckAuthEvent());
    });

    test('emits [AuthUnauthenticated] on CheckAuthEvent when no token', () {
      when(() => mockAuthService.getValidToken())
          .thenAnswer((_) async => null);
      final bloc = buildBloc();

      expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthUnauthenticated>()]),
      );

      bloc.add(CheckAuthEvent());
    });

    test('emits [AuthLoading, AuthAuthenticated] on successful login', () {
      when(() => mockAuthService.hasActiveSession())
          .thenAnswer((_) async => false);
      when(() => mockAuthService.login('user', 'pass'))
          .thenAnswer((_) async => const Right('token123'));
      final bloc = buildBloc();

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthAuthenticated>()
              .having((s) => s.token, 'token', 'token123'),
        ]),
      );

      bloc.add(LoginEvent(username: 'user', password: 'pass'));
    });

    test('emits [AuthLoading, AuthError] on failed login', () {
      when(() => mockAuthService.hasActiveSession())
          .thenAnswer((_) async => false);
      when(() => mockAuthService.login('user', 'wrong'))
          .thenAnswer((_) async => const Left('Invalid username or password'));
      final bloc = buildBloc();

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthError>().having(
            (s) => s.message,
            'message',
            'Invalid username or password',
          ),
        ]),
      );

      bloc.add(LoginEvent(username: 'user', password: 'wrong'));
    });

    test('logs out existing session and sets sessionTakenOver', () {
      when(() => mockAuthService.hasActiveSession())
          .thenAnswer((_) async => true);
      when(() => mockAuthService.logout()).thenAnswer((_) async {});
      when(() => mockAuthService.login('user', 'pass'))
          .thenAnswer((_) async => const Right('token'));
      final bloc = buildBloc();

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<AuthLoading>(),
          isA<AuthAuthenticated>().having(
            (s) => s.sessionTakenOver,
            'sessionTakenOver',
            true,
          ),
        ]),
      );

      bloc.add(LoginEvent(username: 'user', password: 'pass'));
    });

    test('emits [AuthUnauthenticated] on LogoutEvent', () {
      when(() => mockAuthService.logout()).thenAnswer((_) async {});
      final bloc = buildBloc();

      expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthUnauthenticated>()]),
      );

      bloc.add(LogoutEvent());
    });

    test('emits [AuthUnauthenticated] on ClearAuthErrorEvent', () {
      final bloc = buildBloc();

      expectLater(
        bloc.stream,
        emitsInOrder([isA<AuthUnauthenticated>()]),
      );

      bloc.add(ClearAuthErrorEvent());
    });
  });

  // ===================== RegisterBloc Unit Tests =====================
  group('RegisterBloc', () {
    late MockUserService mockUserService;
    late MockEmailVerificationService mockEmailService;

    setUp(() {
      mockUserService = MockUserService();
      mockEmailService = MockEmailVerificationService();
    });

    RegisterBloc buildBloc() => RegisterBloc(
          userService: mockUserService,
          emailVerificationService: mockEmailService,
        );

    test('emits [RegisterLoading, RegisterError] when username is taken', () {
      when(() => mockUserService.isUsernameTaken('taken')).thenReturn(true);
      final bloc = buildBloc();

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<RegisterLoading>(),
          isA<RegisterError>().having(
            (s) => s.message,
            'message',
            'Username is already taken',
          ),
        ]),
      );

      bloc.add(RegisterSubmitted(
        email: 'test@test.com',
        username: 'taken',
        password: 'pass123',
      ));
    });

    test('emits [RegisterLoading, RegisterCodeSent] on valid submission', () {
      when(() => mockUserService.isUsernameTaken('newuser')).thenReturn(false);
      when(() => mockEmailService.sendVerificationCode('test@test.com'))
          .thenAnswer((_) async => const Right(null));
      final bloc = buildBloc();

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<RegisterLoading>(),
          isA<RegisterCodeSent>()
              .having((s) => s.email, 'email', 'test@test.com'),
        ]),
      );

      bloc.add(RegisterSubmitted(
        email: 'test@test.com',
        username: 'newuser',
        password: 'pass123',
      ));
    });

    test('full flow: submit → code sent → verify → verified', () {
      when(() => mockUserService.isUsernameTaken('newuser')).thenReturn(false);
      when(() => mockEmailService.sendVerificationCode('test@test.com'))
          .thenAnswer((_) async => const Right(null));
      when(() => mockEmailService.verifyCode('123456')).thenReturn(true);
      when(() => mockUserService.saveUser(
            'test@test.com',
            'newuser',
            'pass123',
          )).thenAnswer((_) async {});
      final bloc = buildBloc();

      expectLater(
        bloc.stream,
        emitsInOrder([
          isA<RegisterLoading>(),
          isA<RegisterCodeSent>(),
          isA<RegisterLoading>(),
          isA<RegisterVerified>()
              .having((s) => s.username, 'username', 'newuser')
              .having((s) => s.password, 'password', 'pass123'),
        ]),
      );

      bloc.add(RegisterSubmitted(
        email: 'test@test.com',
        username: 'newuser',
        password: 'pass123',
      ));
      bloc.add(VerificationCodeSubmitted('123456'));
    });
  });

  // ===================== LoginPage Widget Tests =====================
  group('LoginPage', () {
    late MockAuthBloc mockAuthBloc;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      when(() => mockAuthBloc.stream)
          .thenAnswer((_) => Stream<AuthState>.empty());
      when(() => mockAuthBloc.isClosed).thenReturn(false);
      when(() => mockAuthBloc.close()).thenAnswer((_) async {});
    });

    Widget buildLoginPage() {
      return MaterialApp(
        theme: ThemeData.dark(),
        home: BlocProvider<AuthBloc>.value(
          value: mockAuthBloc,
          child: const LoginPage(),
        ),
      );
    }

    testWidgets('renders form fields and login button', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthUnauthenticated());
      await tester.pumpWidget(buildLoginPage());

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
    });

    testWidgets('shows error message on AuthError state', (tester) async {
      when(() => mockAuthBloc.state)
          .thenReturn(AuthError(message: 'Invalid credentials'));
      await tester.pumpWidget(buildLoginPage());

      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('toggles password visibility icon', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthUnauthenticated());
      await tester.pumpWidget(buildLoginPage());

      expect(find.byIcon(Icons.visibility_off), findsOneWidget);

      await tester.tap(find.byIcon(Icons.visibility_off));
      await tester.pump();

      expect(find.byIcon(Icons.visibility), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off), findsNothing);
    });

    testWidgets('shows loading indicator during AuthLoading', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthLoading());
      await tester.pumpWidget(buildLoginPage());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Log In'), findsNothing);
    });

    testWidgets('validates empty fields on submit', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthUnauthenticated());
      await tester.pumpWidget(buildLoginPage());

      await tester.tap(find.text('Log In'));
      await tester.pump();

      expect(find.text('Username is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('dispatches LoginEvent on valid submit', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthUnauthenticated());
      await tester.pumpWidget(buildLoginPage());

      await tester.enterText(find.byType(TextFormField).first, 'testuser');
      await tester.enterText(find.byType(TextFormField).last, 'testpass');
      await tester.tap(find.text('Log In'));
      await tester.pump();

      verify(() => mockAuthBloc.add(any(that: isA<LoginEvent>()))).called(1);
    });
  });

  // ===================== UserPage Widget Tests =====================
  group('UserPage', () {
    late MockAuthBloc mockAuthBloc;
    late HomeCubit homeCubit;

    setUp(() {
      mockAuthBloc = MockAuthBloc();
      when(() => mockAuthBloc.stream)
          .thenAnswer((_) => Stream<AuthState>.empty());
      when(() => mockAuthBloc.isClosed).thenReturn(false);
      when(() => mockAuthBloc.close()).thenAnswer((_) async {});
      homeCubit = HomeCubit(mangaService: MockMangaService());
    });

    Widget buildUserPage() {
      return MaterialApp(
        theme: ThemeData.dark(),
        home: MultiBlocProvider(
          providers: [
            BlocProvider<AuthBloc>.value(value: mockAuthBloc),
            BlocProvider<HomeCubit>.value(value: homeCubit),
          ],
          child: const UserPage(),
        ),
      );
    }

    testWidgets('shows login form when unauthenticated', (tester) async {
      when(() => mockAuthBloc.state).thenReturn(AuthUnauthenticated());
      await tester.pumpWidget(buildUserPage());

      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('Log in to your account'), findsOneWidget);
    });

    testWidgets('shows profile with logout when authenticated', (tester) async {
      when(() => mockAuthBloc.state)
          .thenReturn(AuthAuthenticated(token: 'token', username: 'testuser'));
      await tester.pumpWidget(buildUserPage());

      expect(find.text('Log Out'), findsOneWidget);
      expect(find.byType(TextFormField), findsNothing);
    });

    testWidgets('dispatches LogoutEvent on logout tap', (tester) async {
      when(() => mockAuthBloc.state)
          .thenReturn(AuthAuthenticated(token: 'token', username: 'testuser'));
      await tester.pumpWidget(buildUserPage());

      await tester.tap(find.text('Log Out'));
      await tester.pump();

      verify(() => mockAuthBloc.add(any(that: isA<LogoutEvent>()))).called(1);
    });
  });
}
