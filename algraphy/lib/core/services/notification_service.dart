import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'notification_store.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    // 1. Request Permission
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      if (kDebugMode) {
        print('User granted permission');
      }
    } else {
      if (kDebugMode) {
        print('User declined or has not accepted permission');
      }
    }

    // 2. Initialize Local Notifications (for foreground notifications on Android)
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification click here
        if (kDebugMode) {
          print("Notification clicked: ${response.payload}");
        }
      },
    );

    // 2.5 Create High Importance Channel for Android
    if (!kIsWeb && Platform.isAndroid) {
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'algraphy_notifications',
        'Algraphy Notifications',
        description: 'Main channel for Algraphy notifications',
        importance: Importance.max,
      );

      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _localNotifications.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();

      await androidImplementation?.createNotificationChannel(channel);
    }

    // 3. Handle Foreground Messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Got a message whilst in the foreground!');
        print('Message data: ${message.data}');
      }

      if (message.notification != null) {
        if (kDebugMode) {
          print('Message also contained a notification: ${message.notification}');
        }
        // 1. Instantly update in-memory store (badge + open panel update immediately)
        NotificationStore().addForegroundNotification(
          message.notification!.title ?? '',
          message.notification!.body ?? '',
          type: message.data['type'] ?? 'general',
          referenceId: message.data['task_id'] ?? message.data['room_id'],
        );
        // 2. After 1s, sync with server (confirms DB write & gets real IDs)
        Future.delayed(const Duration(seconds: 1), () {
          NotificationStore().fetchNotifications();
        });
        _showLocalNotification(message);
      }
    });

    // 4. Handle Background/Terminated Messages (Interaction)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('A new onMessageOpenedApp event was published!');
      }
      // Refresh store when user taps a background notification
      NotificationStore().fetchNotifications();
    });

    // 5. Get Initial Message (if app was opened from a terminated state via notification)
    RemoteMessage? initialMessage = await _messaging.getInitialMessage();
    if (initialMessage != null) {
      // Handle the initial message
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    // Only show local notifications on mobile for now
    if (kIsWeb) return;

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'algraphy_notifications',
      'Algraphy Notifications',
      channelDescription: 'Main channel for Algraphy notifications',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      platformChannelSpecifics,
      payload: message.data.toString(),
    );
  }

  Future<String?> getFCMToken() async {
    return await _messaging.getToken(vapidKey: "BIWYYQ0nFpZxpsXVAN26bPpAEaEgOzGwzTaM3tGvmfAhpusUwtjYSSTzJh9dodw-2InLr0itpR_4Zk0fYdAd7wI");
  }
}

// Global background message handler
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyCq31TfSN_aa9YkfCQ8JHXFC5F9iPXwKZI",
        authDomain: "al-graphy-pro.firebaseapp.com",
        projectId: "al-graphy-pro",
        storageBucket: "al-graphy-pro.firebasestorage.app",
        messagingSenderId: "620504539920",
        appId: "1:620504539920:web:f0ae5c4b8c208d93bbbb95",
      ),
    );
  } else {
    await Firebase.initializeApp();
  }
  
  if (kDebugMode) {
    print("Handling a background message: ${message.messageId}");
  }
}
