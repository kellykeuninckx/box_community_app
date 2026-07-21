import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'user_profile_service.dart';

class NotificationService {
  final _messaging = FirebaseMessaging.instance;
  final _profileService = UserProfileService();

  /// Vraag toestemming, en zorg dat het token (en toekomstige verversingen
  /// daarvan) worden bijgehouden bij het profiel van de ingelogde gebruiker.
  Future<void> initialize() async {
    print('[Meldingen] Toestemming vragen...');
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    print('[Meldingen] Toestemmingsstatus: ${settings.authorizationStatus}');

    if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('[Meldingen] Toestemming geweigerd, stoppen.');
      return;
    }

    if (Platform.isIOS) {
      // Zonder dit toont iOS geen banner voor binnenkomende meldingen
      // terwijl de app op de voorgrond staat.
      await _messaging.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      print('[Meldingen] Wachten op APNS-token...');
      String? apnsToken;
      for (var i = 0; i < 10; i++) {
        apnsToken = await _messaging.getAPNSToken();
        if (apnsToken != null) break;
        await Future.delayed(const Duration(milliseconds: 500));
      }
      print('[Meldingen] APNS-token: $apnsToken');
      if (apnsToken == null) {
        print('[Meldingen] Geen APNS-token gekregen, stoppen.');
        return;
      }
    }

    print('[Meldingen] FCM-token opvragen...');
    final token = await _messaging.getToken();
    print('[Meldingen] FCM-token: $token');

    if (token != null) {
      print('[Meldingen] Token opslaan in Firestore...');
      await _profileService.saveFcmToken(token);
      print('[Meldingen] Token opgeslagen!');
    } else {
      print('[Meldingen] FCM-token was null, niks opgeslagen.');
    }

    _messaging.onTokenRefresh.listen((newToken) {
      print('[Meldingen] Token ververst: $newToken');
      _profileService.saveFcmToken(newToken);
    });
  }
}