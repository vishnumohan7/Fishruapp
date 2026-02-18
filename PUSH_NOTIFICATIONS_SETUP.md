# Push Notifications Setup Guide

This guide will help you set up Firebase Cloud Messaging (FCM) for push notifications in your Flutter app.

## Prerequisites

1. A Firebase account (create one at https://firebase.google.com)
2. Flutter SDK installed
3. Android Studio (for Android setup)
4. Xcode (for iOS setup, if deploying to iOS)

## Step 1: Create a Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **"Add project"** or select an existing project
3. Enter your project name (e.g., "Freshbe")
4. Follow the setup wizard:
   - Enable/disable Google Analytics (optional)
   - Complete project creation

## Step 2: Add Android App to Firebase

1. In Firebase Console, click **"Add app"** → **Android**
2. Enter your package name: `com.dsg.fishru`
3. Enter app nickname (optional): "Freshbe Android"
4. Enter SHA-1 certificate fingerprint (optional, for Google Sign-In):
   ```bash
   # Debug keystore
   keytool -list -v -keystore ~/.android/debug.keystore -alias androiddebugkey -storepass android -keypass android
   
   # Release keystore (if you have one)
   keytool -list -v -keystore android/keystore.jks -alias your-key-alias
   ```
5. Click **"Register app"**
6. Download `google-services.json`
7. Place the file in: `android/app/google-services.json`

## Step 3: Add iOS App to Firebase (Optional - for iOS support)

1. In Firebase Console, click **"Add app"** → **iOS**
2. Enter your bundle ID (check `ios/Runner.xcodeproj` or `ios/Runner/Info.plist`)
3. Enter app nickname (optional): "Freshbe iOS"
4. Click **"Register app"**
5. Download `GoogleService-Info.plist`
6. Place the file in: `ios/Runner/GoogleService-Info.plist`
7. Open `ios/Runner.xcworkspace` in Xcode
8. Drag `GoogleService-Info.plist` into the `Runner` folder in Xcode

## Step 4: Install Dependencies

Run the following command to install the new dependencies:

```bash
flutter pub get
```

## Step 5: Verify Configuration Files

Make sure these files exist:

### Android
- ✅ `android/app/google-services.json` (downloaded from Firebase Console)

### iOS (if deploying to iOS)
- ✅ `ios/Runner/GoogleService-Info.plist` (downloaded from Firebase Console)

## Step 6: Build and Test

### Android

1. **Clean the project:**
   ```bash
   flutter clean
   ```

2. **Get dependencies:**
   ```bash
   flutter pub get
   ```

3. **Build the app:**
   ```bash
   flutter build apk --debug
   # or
   flutter run
   ```

4. **Test push notifications:**
   - Install the app on a physical device (push notifications don't work on emulators)
   - Check the console logs for the FCM token
   - Use Firebase Console → Cloud Messaging → Send test message

### iOS (if deploying to iOS)

1. **Open Xcode:**
   ```bash
   open ios/Runner.xcworkspace
   ```

2. **Configure signing:**
   - Select your development team
   - Enable push notifications capability

3. **Build and run:**
   ```bash
   flutter run
   ```

## Step 7: Send Test Notification

### Using Firebase Console

1. Go to Firebase Console → **Cloud Messaging**
2. Click **"Send your first message"** or **"New campaign"**
3. Enter notification title and text
4. Click **"Send test message"**
5. Enter your FCM token (check app logs or use the token from `NotificationProvider.fcmToken`)
6. Click **"Test"**

### Using cURL (for testing)

```bash
curl -X POST https://fcm.googleapis.com/v1/projects/YOUR_PROJECT_ID/messages:send \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "message": {
      "token": "YOUR_FCM_TOKEN",
      "notification": {
        "title": "Test Notification",
        "body": "This is a test notification from Firebase"
      },
      "data": {
        "type": "order",
        "order_id": "ORD-001"
      }
    }
  }'
```

## Step 8: Integrate with Backend (Optional)

To send notifications from your backend, you'll need to:

1. **Get the FCM token** from the app (stored in `NotificationProvider.fcmToken`)
2. **Send token to your backend** when user logs in
3. **Update `_sendTokenToBackend()` method** in `push_notification_service.dart`

Example backend integration:

```dart
// In push_notification_service.dart, update _sendTokenToBackend:
Future<void> _sendTokenToBackend(String token) async {
  try {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    if (userProvider.isLoggedIn) {
      await BackendService().updateFCMToken(
        userId: userProvider.user?.id,
        fcmToken: token,
      );
    }
  } catch (e) {
    debugPrint('Error sending FCM token to backend: $e');
  }
}
```

## Step 9: Handle Notification Taps

The push notification service automatically handles notification taps. To navigate to specific screens when a notification is tapped, update the `onNotificationTapped` callback in your app:

```dart
// Example: In your home screen or main app widget
_pushService.onNotificationTapped = (notification) {
  if (notification.type == NotificationType.order) {
    // Navigate to order details
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderDetailScreen(
          orderId: notification.data?['order_id'],
        ),
      ),
    );
  } else if (notification.type == NotificationType.promotion) {
    // Navigate to products screen
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductsScreen(),
      ),
    );
  }
};
```

## Troubleshooting

### Android Issues

1. **"google-services.json not found"**
   - Make sure `google-services.json` is in `android/app/` directory
   - Clean and rebuild: `flutter clean && flutter pub get`

2. **"Default FirebaseApp is not initialized"**
   - Check that `Firebase.initializeApp()` is called in `main.dart`
   - Verify `google-services.json` is correctly placed

3. **Notifications not showing**
   - Check device notification permissions
   - Verify notification channel is created (check logs)
   - Test on a physical device (emulators don't support push notifications)

4. **Build errors with Google Services plugin**
   - Make sure `com.google.gms.google-services` plugin is added in `android/app/build.gradle.kts`
   - Verify classpath is added in `android/build.gradle.kts`

### iOS Issues

1. **"GoogleService-Info.plist not found"**
   - Make sure the file is in `ios/Runner/` directory
   - Verify it's added to Xcode project

2. **Push notifications not working**
   - Enable Push Notifications capability in Xcode
   - Configure APNs certificates in Firebase Console
   - Test on a physical device (simulator doesn't support push notifications)

3. **Build errors**
   - Run `pod install` in `ios/` directory
   - Clean Xcode build folder: Product → Clean Build Folder

### General Issues

1. **FCM token is null**
   - Check Firebase initialization
   - Verify permissions are granted
   - Check device internet connection

2. **Notifications not received**
   - Verify FCM token is valid
   - Check Firebase Console for delivery status
   - Verify notification payload format

## Testing Checklist

- [ ] Firebase project created
- [ ] `google-services.json` added to `android/app/`
- [ ] `GoogleService-Info.plist` added to `ios/Runner/` (iOS only)
- [ ] Dependencies installed (`flutter pub get`)
- [ ] App builds successfully
- [ ] FCM token is generated (check logs)
- [ ] Test notification received from Firebase Console
- [ ] Notification appears when app is in foreground
- [ ] Notification appears when app is in background
- [ ] Notification tap navigates to correct screen
- [ ] Notification is saved to local storage

## Next Steps

1. **Set up notification topics** (for targeted notifications):
   ```dart
   // Subscribe to order updates
   await notificationProvider.subscribeToTopic('orders');
   
   // Subscribe to promotions
   await notificationProvider.subscribeToTopic('promotions');
   ```

2. **Integrate with your backend** to send notifications programmatically

3. **Add notification preferences** in user settings

4. **Set up notification scheduling** for order updates, reminders, etc.

## Additional Resources

- [Firebase Cloud Messaging Documentation](https://firebase.google.com/docs/cloud-messaging)
- [FlutterFire Documentation](https://firebase.flutter.dev/)
- [FCM Flutter Plugin](https://pub.dev/packages/firebase_messaging)
- [Local Notifications Plugin](https://pub.dev/packages/flutter_local_notifications)

## Support

If you encounter issues:
1. Check Firebase Console for error messages
2. Review app logs for FCM-related errors
3. Verify all configuration files are in place
4. Test on a physical device (not emulator/simulator)

