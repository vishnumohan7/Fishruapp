# Production Release Guide for Play Store

This guide will help you create a release bundle (AAB) for the Google Play Store.

## Step 1: Generate a Keystore (if you don't have one)

If you already have a keystore file, skip to Step 2.

Run the following command in your terminal:

```bash
keytool -genkey -v -keystore android/keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

You'll be prompted to enter:
- **Keystore password**: Choose a strong password (save this securely!)
- **Key password**: Can be same as keystore password or different
- **Your name and organization details**: Fill in as required

**IMPORTANT**: 
- Keep your keystore file (`keystore.jks`) and passwords safe!
- If you lose the keystore, you won't be able to update your app on Play Store
- Store backups in a secure location

## Step 2: Create key.properties File

1. Copy the template file:
   ```bash
   cp android/key.properties.template android/key.properties
   ```

2. Edit `android/key.properties` and fill in your actual values:
   ```
   storePassword=YOUR_KEYSTORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=upload
   storeFile=../keystore.jks
   ```

   Replace:
   - `YOUR_KEYSTORE_PASSWORD` with your keystore password
   - `YOUR_KEY_PASSWORD` with your key password
   - `upload` with your key alias (if you used a different one)
   - `../keystore.jks` with the path to your keystore file (relative to `android/app/`)

## Step 3: Update Version Number (if needed)

Edit `pubspec.yaml` and update the version:
```yaml
version: 1.0.0+1
```
- Format: `version: MAJOR.MINOR.PATCH+BUILD_NUMBER`
- For Play Store, increment the build number (+1, +2, etc.) for each release

## Step 4: Build the Release Bundle

Run the following command:

```bash
flutter build appbundle --release
```

The release bundle will be created at:
```
build/app/outputs/bundle/release/app-release.aab
```

## Step 5: Upload to Play Store

1. Go to [Google Play Console](https://play.google.com/console)
2. Select your app
3. Go to "Production" → "Create new release"
4. Upload the `app-release.aab` file
5. Fill in release notes and other required information
6. Review and publish

## Troubleshooting

### If build fails with signing errors:
- Verify `key.properties` file exists and has correct values
- Check that `keystore.jks` file exists at the specified path
- Ensure passwords are correct

### If you need to test the release build locally:
```bash
flutter build apk --release
```
This creates an APK (not AAB) that you can install directly on a device for testing.

## Security Notes

- **NEVER** commit `key.properties` or `keystore.jks` to version control
- These files are already added to `.gitignore`
- Keep backups of your keystore in a secure location
- Consider using Google Play App Signing for additional security

