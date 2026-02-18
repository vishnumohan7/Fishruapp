# How to Send Test Push Notification - Step by Step

## Method 1: Firebase Console - Cloud Messaging Section

### Step-by-Step:

1. **Go to Firebase Console:**
   - Navigate to: https://console.firebase.google.com/
   - Select your "freshbe" project

2. **Open Cloud Messaging:**
   - In the left sidebar, look for **"Engage"** section
   - Click on **"Cloud Messaging"** (or "Messaging")
   - If you don't see it, try: **"Messaging"** or **"Notifications"**

3. **Send Test Message:**
   - You should see a button: **"Send your first message"** or **"New campaign"**
   - Click on it
   - Look for a tab or button: **"Send test message"** or **"Test"**
   - If you see "New campaign", click it and look for "Test" option

### Alternative Navigation:

If you can't find Cloud Messaging in the sidebar:

1. **Direct URL:**
   ```
   https://console.firebase.google.com/project/freshbe/notification
   ```

2. **Or via Project Settings:**
   - Click the gear icon ⚙️ (Settings) in left sidebar
   - Go to **"Cloud Messaging"** tab
   - Look for **"Send test message"** option

## Method 2: Using Firebase Console - Notifications

1. **Go to:** https://console.firebase.google.com/project/freshbe
2. **Look for:** "Notifications" or "Messaging" in the left sidebar
3. **Click:** "New notification" or "Create notification"
4. **Select:** "Test message" option

## Method 3: Using cURL (Command Line)

If you can't find the test option in the console, you can use cURL:

### Prerequisites:
- Get your FCM token from app logs
- Get a Firebase access token (for authentication)

### Steps:

1. **Get Firebase Access Token:**
   - Go to: https://console.firebase.google.com/project/freshbe/settings/serviceaccounts/adminsdk
   - Click "Generate new private key"
   - Download the JSON file
   - Use this to get an access token (or use Firebase Admin SDK)

2. **Send notification using cURL:**
   ```bash
   curl -X POST https://fcm.googleapis.com/v1/projects/freshbe/messages:send \
     -H "Authorization: Bearer YOUR_ACCESS_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "message": {
         "token": "YOUR_FCM_TOKEN",
         "notification": {
           "title": "Test Notification",
           "body": "This is a test from Firebase!"
         }
       }
     }'
   ```

## Method 4: Using Firebase Admin SDK (Backend)

If you have a backend server, you can send test notifications programmatically.

## Method 5: Create a Campaign and Target Single Device

1. **Go to Cloud Messaging**
2. **Click "New campaign"**
3. **Select "Firebase Notification messages"**
4. **Fill in notification details**
5. **In "Target" section:**
   - Select **"Single device"**
   - Paste your FCM token
6. **Schedule:** Select "Send now"
7. **Publish**

## Method 6: Use Firebase CLI (If Installed)

```bash
# Install Firebase CLI if not installed
npm install -g firebase-tools

# Login
firebase login

# Send test message
firebase messaging:send \
  --token YOUR_FCM_TOKEN \
  --title "Test" \
  --body "Test notification"
```

## Quick Visual Guide - Where to Click:

### Option A: Left Sidebar Navigation
```
Firebase Console
├── Engage
│   └── Cloud Messaging ← Click here
│       └── "Send your first message" button
│           └── "Send test message" tab
```

### Option B: Settings Route
```
Firebase Console
├── ⚙️ Settings (gear icon)
│   └── Cloud Messaging tab
│       └── "Send test message" option
```

### Option C: Direct URL
```
https://console.firebase.google.com/project/freshbe/notification
```

## Troubleshooting: Can't Find "Send Test Message"

### Issue 1: Different Console Layout
- Firebase Console UI may vary
- Look for: "New campaign", "Create notification", or "Test" buttons
- Check the top-right area for action buttons

### Issue 2: Permissions
- Make sure you have "Editor" or "Owner" role
- Check project permissions in Settings → Users and permissions

### Issue 3: API Not Enabled
- Verify Cloud Messaging API is enabled (✅ You have this)
- Check: Project Settings → Cloud Messaging → Firebase Cloud Messaging API (V1) should show "Enabled"

## Recommended: Use Method 5 (Campaign with Single Device)

This is the most reliable method:

1. **Go to:** Cloud Messaging → New campaign
2. **Select:** Firebase Notification messages
3. **Enter:**
   - Notification title: "Test"
   - Notification text: "Testing push notifications"
4. **Target:** Single device → Enter your FCM token
5. **Schedule:** Send now
6. **Review and publish**

## Quick Test Script

If you want to test programmatically, here's a simple Dart script you can run:

```dart
// test_notification.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

Future<void> sendTestNotification(String fcmToken, String accessToken) async {
  final url = Uri.parse(
    'https://fcm.googleapis.com/v1/projects/freshbe/messages:send'
  );
  
  final response = await http.post(
    url,
    headers: {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({
      'message': {
        'token': fcmToken,
        'notification': {
          'title': 'Test Notification',
          'body': 'This is a test from your app!',
        },
      },
    }),
  );
  
  print('Response: ${response.statusCode}');
  print('Body: ${response.body}');
}
```

## What to Do Right Now:

1. **First, get your FCM token:**
   - Run the app: `flutter run`
   - Check console for: `🔔 FCM Token for testing: [token]`
   - Copy that token

2. **Then try these in order:**
   - **Option 1:** Go to: https://console.firebase.google.com/project/freshbe/notification
   - **Option 2:** Look for "New campaign" button in Cloud Messaging
   - **Option 3:** Use Method 5 (Campaign with Single Device)

3. **If still can't find it:**
   - Take a screenshot of your Firebase Console
   - Check what options you see in the Cloud Messaging page
   - The UI might have changed or be in a different location

## Need Help?

If you still can't find the option, let me know:
- What do you see when you go to Cloud Messaging?
- What buttons/options are visible?
- I can guide you based on what you see!

