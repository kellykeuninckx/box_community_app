import 'package:firebase_messaging/firebase_messaging.dart';
import 'user_profile_service.dart';

class NotificationService {
  final _messaging = FirebaseMessaging.instance;
  final _profileService = UserProfileService();

  /// Vraag toestemming, en zorg dat het token (en toekomstige verversingen
  /// daarvan) worden bijgehouden bij het profiel van de ingelogde gebruiker.
  Future<void> initialize() async {
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    final token = await _messaging.getToken();
    if (token != null) {
      await _profileService.saveFcmToken(token);
    }

    _messaging.onTokenRefresh.listen((newToken) {
      _profileService.saveFcmToken(newToken);
    });
  }
}