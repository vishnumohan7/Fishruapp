import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import '../models/notification.dart';

/// Top-level function to handle background messages
/// Must be a top-level function, not a class method
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background message: ${message.messageId}');
  debugPrint('Message data: ${message.data}');
  debugPrint('Message notification: ${message.notification?.title}');
  
  // You can handle background notifications here
  // For example, save to local storage or update a database
}

class PushNotificationService {
  static final PushNotificationService _instance = PushNotificationService._internal();
  factory PushNotificationService() => _instance;
  PushNotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  String? _fcmToken;
  StreamSubscription<String>? _tokenStream;
  
  // Callback to handle when a notification is received
  Function(NotificationItem)? onNotificationReceived;
  
  // Callback to handle when a notification is tapped
  Function(NotificationItem)? onNotificationTapped;

  String? get fcmToken => _fcmToken;
  bool _isInitialized = false;

  /// Initialize push notification service
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('PushNotificationService already initialized');
      return;
    }

    try {
      // Request notification permissions
      await _requestPermissions();
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Set up FCM message handlers
      await _setupMessageHandlers();
      
      // Get FCM token
      await _getFCMToken();
      
      // Listen for token refresh
      _tokenStream = _firebaseMessaging.onTokenRefresh.listen((newToken) {
        debugPrint('FCM Token refreshed: $newToken');
        _fcmToken = newToken;
        // You can send this token to your backend here
        _onTokenRefresh(newToken);
      });
      
      _isInitialized = true;
      debugPrint('PushNotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing PushNotificationService: $e');
      rethrow;
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    try {
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
        provisional: false,
      );

      debugPrint('Notification permission status: ${settings.authorizationStatus}');
      
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('User granted notification permission');
      } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
        debugPrint('User granted provisional notification permission');
      } else {
        debugPrint('User denied notification permission');
      }
    } catch (e) {
      debugPrint('Error requesting notification permissions: $e');
    }
  }

  /// Initialize local notifications for foreground notifications
  Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const InitializationSettings initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channel for Android
    await _createNotificationChannel();
  }

  /// Create Android notification channel
  Future<void> _createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'freshbe_notifications', // id
      'Freshbe Notifications', // name
      description: 'Notifications for order updates, promotions, and more',
      importance: Importance.high,
      playSound: true,
      enableVibration: true,
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  /// Set up FCM message handlers
  Future<void> _setupMessageHandlers() async {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Received foreground message: ${message.messageId}');
      _handleForegroundMessage(message);
    });

    // Handle messages when app is opened from terminated state
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('App opened from notification: ${message.messageId}');
      _handleNotificationTap(message);
    });

    // Check if app was opened from a notification (terminated state)
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      debugPrint('App opened from terminated state via notification');
      _handleNotificationTap(initialMessage);
    }

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  /// Handle foreground messages (show local notification)
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    debugPrint('Handling foreground message: ${message.messageId}');
    
    final notification = _parseRemoteMessage(message);
    
    // Show local notification
    await _showLocalNotification(notification);
    
    // Notify listeners
    if (onNotificationReceived != null) {
      onNotificationReceived!(notification);
    }
  }

  /// Handle notification tap
  void _handleNotificationTap(RemoteMessage message) {
    debugPrint('Handling notification tap: ${message.messageId}');
    
    final notification = _parseRemoteMessage(message);
    
    // Notify listeners
    if (onNotificationTapped != null) {
      onNotificationTapped!(notification);
    }
  }

  /// Parse RemoteMessage to NotificationItem
  NotificationItem _parseRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final notification = message.notification;
    
    // Determine notification type from data or notification title
    NotificationType type = NotificationType.system;
    if (data.containsKey('type')) {
      final typeString = data['type'].toString().toLowerCase();
      switch (typeString) {
        case 'order':
          type = NotificationType.order;
          break;
        case 'promotion':
          type = NotificationType.promotion;
          break;
        case 'reminder':
          type = NotificationType.reminder;
          break;
        default:
          type = NotificationType.system;
      }
    }
    
    return NotificationItem(
      id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: notification?.title ?? data['title'] ?? 'Notification',
      message: notification?.body ?? data['message'] ?? data['body'] ?? '',
      type: type,
      createdAt: message.sentTime ?? DateTime.now(),
      isRead: false,
      data: data,
    );
  }

  /// Show local notification
  Future<void> _showLocalNotification(NotificationItem notification) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'freshbe_notifications',
      'Freshbe Notifications',
      channelDescription: 'Notifications for order updates, promotions, and more',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      enableVibration: true,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      notification.id.hashCode,
      notification.title,
      notification.message,
      details,
      payload: notification.id,
    );
  }

  /// Handle notification tap from local notification
  void _onNotificationTapped(NotificationResponse response) {
    debugPrint('Local notification tapped: ${response.payload}');
    
    if (response.payload != null) {
      // You can navigate to a specific screen based on the payload
      // This will be handled by the app's navigation logic
    }
  }

  /// Get FCM token
  Future<void> _getFCMToken() async {
    try {
      _fcmToken = await _firebaseMessaging.getToken();
      debugPrint('FCM Token: $_fcmToken');
      
      // Send token to your backend
      if (_fcmToken != null) {
        await _sendTokenToBackend(_fcmToken!);
      }
    } catch (e) {
      debugPrint('Error getting FCM token: $e');
    }
  }

  /// Send FCM token to backend
  Future<void> _sendTokenToBackend(String token) async {
    try {
      // TODO: Implement API call to send token to your backend
      // Example:
      // await BackendService().updateFCMToken(token);
      debugPrint('FCM Token should be sent to backend: $token');
    } catch (e) {
      debugPrint('Error sending FCM token to backend: $e');
    }
  }

  /// Handle token refresh
  void _onTokenRefresh(String newToken) {
    _sendTokenToBackend(newToken);
  }

  /// Subscribe to a topic
  Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      debugPrint('Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('Error subscribing to topic $topic: $e');
    }
  }

  /// Unsubscribe from a topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      debugPrint('Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('Error unsubscribing from topic $topic: $e');
    }
  }

  /// Delete FCM token (for logout)
  Future<void> deleteToken() async {
    try {
      await _firebaseMessaging.deleteToken();
      _fcmToken = null;
      debugPrint('FCM Token deleted');
    } catch (e) {
      debugPrint('Error deleting FCM token: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _tokenStream?.cancel();
    _isInitialized = false;
  }
}

