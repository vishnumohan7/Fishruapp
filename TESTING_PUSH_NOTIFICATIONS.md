# Testing Push Notifications - Quick Start Guide

## Prerequisites Checklist

Before testing, make sure you have:

- [ ] Firebase project created (✅ You have "freshbe" project)
- [ ] Firebase Cloud Messaging API (V1) enabled (✅ Enabled in your console)
- [ ] `google-services.json` file downloaded and placed in `android/app/`
- [ ] Physical Android device (push notifications don't work on emulators)
- [ ] App built and installed on the device

## Step 1: Verify Configuration File

1. **Check if `google-services.json` exists:**
   ```bash
   ls android/app/google-services.json
   ```

2. **If missing, download it:**
   - Go to Firebase Console → Project Settings
   - Scroll to "Your apps" section
   - Click on your Android app (package: `com.dsg.fishru`)
   - Download `google-services.json`
   - Place it in: `android/app/google-services.json`

## Step 2: Build and Install the App

1. **Clean the project:**
   ```bash
   flutter clean
   flutter pub get
   ```

2. **Connect your physical Android device:**
   ```bash
   # Check if device is connected
   adb devices
   ```

3. **Run the app:**
   ```bash
   flutter run
   ```

   Or build and install:
   ```bash
   flutter build apk --debug
   adb install build/app/outputs/flutter-apk/app-debug.apk
   ```

## Step 3: Get the FCM Token

Once the app is running, check the console logs for the FCM token:

**Look for this in the console:**
```
FCM Token: [a-long-token-string-here]
```

**Or add this to your code temporarily to display the token:**

In `lib/main.dart`, after push notifications are initialized, you can print it:

```dart
// In _initializeApp method, after initializePushNotifications:
final notificationProvider = context.read<NotificationProvider>();
if (notificationProvider.fcmToken != null) {
  print('🔔 FCM Token: ${notificationProvider.fcmToken}');
  // You can also show it in a dialog for easy copying
}
```

**Alternative: Check in NotificationProvider**

The token is available via:
```dart
final notificationProvider = Provider.of<NotificationProvider>(context);
print('FCM Token: ${notificationProvider.fcmToken}');
```

## Step 4: Send Test Notification via Firebase Console

### Method 1: Send Test Message (Easiest)

1. **Go to Firebase Console:**
   - Navigate to: https://console.firebase.google.com/
   - Select your "freshbe" project

2. **Open Cloud Messaging:**
   - Click on "Cloud Messaging" in the left sidebar
   - Or go to: Project Settings → Cloud Messaging

3. **Send Test Message:**
   - Click **"Send your first message"** or **"New campaign"**
   - Click **"Send test message"** tab
   - Paste your FCM token in the "FCM registration token" field
   - Enter:
     - **Title:** "Test Notification"
     - **Text:** "This is a test push notification!"
   - Click **"Test"**

4. **Check your device:**
   - You should see the notification appear on your device
   - If app is in foreground: notification appears in the app
   - If app is in background: notification appears in notification tray
   - If app is closed: notification appears in notification tray

### Method 2: Create a Campaign

1. **In Cloud Messaging, click "New campaign"**
2. **Select "Firebase Notification messages"**
3. **Fill in:**
   - Notification title
   - Notification text
   - Optional: Add image, action buttons
4. **Target:**
   - Select "Single device" and enter your FCM token
   - Or select "User segment" for broader testing
5. **Schedule:** Send now or schedule for later
6. **Review and publish**

## Step 5: Test Different App States

### Test 1: App in Foreground
1. Open the app
2. Send a test notification
3. **Expected:** Notification appears in the app UI (local notification)

### Test 2: App in Background
1. Press home button (app goes to background)
2. Send a test notification
3. **Expected:** Notification appears in notification tray

### Test 3: App Closed/Terminated
1. Swipe away the app from recent apps
2. Send a test notification
3. **Expected:** Notification appears in notification tray
4. Tap the notification
5. **Expected:** App opens

## Step 6: Test Notification Data Payload

To test with custom data (for navigation, etc.):

1. **In Firebase Console → Cloud Messaging:**
   - Click "Send test message"
   - Enter your FCM token
   - Click **"Add custom data"**
   - Add key-value pairs:
     ```
     Key: type
     Value: order
     
     Key: order_id
     Value: ORD-001
     ```
   - Send the notification

2. **Check app logs:**
   - The notification should be parsed and saved
   - Check `NotificationProvider` for the new notification
   - Verify the data is correctly stored

## Step 7: Verify Notification Handling

### Check Notification Storage

1. **Open the app**
2. **Navigate to:** Profile → Notifications
3. **Verify:** The push notification appears in the list
4. **Test actions:**
   - Tap notification → Should mark as read
   - Swipe to dismiss → Should remove from list

### Check Console Logs

Look for these log messages:

```
✅ PushNotificationService initialized successfully
✅ FCM Token: [token]
✅ Received foreground message: [message-id]
✅ Handling notification tap: [message-id]
```

## Troubleshooting

### Issue: "FCM Token is null"

**Solutions:**
1. Check Firebase initialization in `main.dart`
2. Verify `google-services.json` is in correct location
3. Check device internet connection
4. Verify notification permissions are granted
5. Check console logs for errors

### Issue: "Notifications not received"

**Solutions:**
1. **Verify FCM token is correct:**
   - Copy token from logs
   - Make sure no extra spaces

2. **Check Firebase Console:**
   - Verify Cloud Messaging API is enabled (✅ You have this)
   - Check if notification was sent successfully

3. **Check device:**
   - Make sure device has internet connection
   - Check if Do Not Disturb mode is enabled
   - Verify notification permissions are granted

4. **Check app state:**
   - Test with app in different states (foreground/background/closed)

### Issue: "Build errors"

**Solutions:**
1. **Clean and rebuild:**
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Verify `google-services.json`:**
   - Check file exists in `android/app/`
   - Verify package name matches: `com.dsg.fishru`

3. **Check Gradle sync:**
   - In Android Studio: File → Sync Project with Gradle Files

### Issue: "Notification appears but doesn't navigate"

**Solutions:**
1. Check `onNotificationTapped` callback in your code
2. Verify notification data payload is correct
3. Check navigation logic in notification handler

## Quick Test Commands

```bash
# 1. Clean and get dependencies
flutter clean && flutter pub get

# 2. Check device connection
adb devices

# 3. Run app and watch logs
flutter run

# 4. Filter FCM logs only
flutter run | grep -i "fcm\|notification\|token"
```

## Testing Checklist

- [ ] `google-services.json` file in place
- [ ] App builds successfully
- [ ] App runs on physical device
- [ ] FCM token is generated (check logs)
- [ ] Test notification sent from Firebase Console
- [ ] Notification received when app is in foreground
- [ ] Notification received when app is in background
- [ ] Notification received when app is closed
- [ ] Notification tap opens the app
- [ ] Notification appears in app's notification list
- [ ] Notification data is correctly parsed

## Next Steps After Testing

Once basic testing works:

1. **Integrate with backend:**
   - Send FCM token to your backend when user logs in
   - Update `_sendTokenToBackend()` method

2. **Set up notification topics:**
   ```dart
   // Subscribe to order updates
   await notificationProvider.subscribeToTopic('orders');
   ```

3. **Add notification preferences:**
   - Let users enable/disable notifications
   - Allow users to choose notification types

4. **Test production:**
   - Build release APK
   - Test on production Firebase project
   - Verify notifications work in production

## Useful Firebase Console Links

- **Cloud Messaging:** https://console.firebase.google.com/project/freshbe/notification
- **Project Settings:** https://console.firebase.google.com/project/freshbe/settings/general
- **FCM API Status:** https://status.firebase.google.com/

## Support

If you encounter issues:
1. Check Firebase Console for delivery status
2. Review app logs for error messages
3. Verify all configuration files are correct
4. Test on a different device

---

**Your Sender ID:** `237806922916` (from Firebase Console)

Use this Sender ID if you need to configure anything manually or for backend integration.

