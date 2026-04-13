import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:manga_recommendation_app/bloc/auth/auth_state.dart';

// Hive-backed persistent preferences per user (NSFW toggle)
class UserPreferencesService extends ChangeNotifier {
  UserPreferencesService._();
  static final UserPreferencesService instance = UserPreferencesService._();

  static const _boxName = 'user_preferences';
  late final Box<String> _box;

  static Future<void> init() async {
    instance._box = await Hive.openBox<String>(_boxName);
  }

  // NSFW toggle (per user)
  bool getNsfwEnabled(String username) =>
      _box.get('nsfw_$username') == 'true';

  void setNsfwEnabled(String username, bool enabled) {
    _box.put('nsfw_$username', enabled.toString());
    notifyListeners();
  }

  // Returns current NSFW preference. Always false when not logged in.
  bool isNsfwEnabled(AuthState authState) {
    if (authState is AuthAuthenticated) {
      return getNsfwEnabled(authState.username);
    }
    return false;
  }

  // Onboarding — stored globally (not per user)
  bool get hasSeenOnboarding => _box.get('onboarding_seen') == 'true';

  void setOnboardingSeen() {
    _box.put('onboarding_seen', 'true');
  }
}
