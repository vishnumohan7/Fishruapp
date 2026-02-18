# Debug Build Size Optimization

## Changes Made

### 1. ABI Filtering (Most Important)
- **Limited all builds to `arm64-v8a` only** in `defaultConfig.ndk` in `android/app/build.gradle.kts`
- This reduces APK size by ~40–50% since it excludes:
  - `armeabi-v7a` (32-bit ARM)
  - `x86` and `x86_64` (Intel emulators)
- Most modern Android devices use `arm64-v8a`
- **If the debug APK is still ~140 MB**, force a single ABI from the command line:
  ```bash
  flutter build apk --debug --target-platform android-arm64
  ```
  Output will be under `build/app/outputs/flutter-apk/` and should be ~50–80 MB.

### 2. ABI Splits for Release Builds
- Added ABI splits for release builds
- Creates separate APKs for each architecture
- Reduces individual APK size

### 3. Packaging Optimizations
- Added resource exclusions to remove unnecessary META-INF files
- Reduces APK size by removing duplicate license/notice files

### 4. Gradle Performance Optimizations
- Enabled parallel builds
- Enabled build caching
- Enabled configure-on-demand
- Enabled R8 full mode

## Expected Results

- **Before**: ~194 MB
- **After**: ~50-70 MB (for arm64-v8a only)
- **Reduction**: ~60-75% size reduction

## Building

### Debug build (smaller size)
```bash
# Rely on Gradle ABI filter (arm64-v8a only)
flutter build apk --debug
# Or force single ABI explicitly (if APK is still large)
flutter build apk --debug --target-platform android-arm64
```

### Profile build (smaller than debug, good for testing)
```bash
flutter build apk --profile --target-platform android-arm64
```

### Release build (smallest; for distribution)
```bash
# Single APK (arm64 only with current config)
flutter build apk --release --obfuscate --split-debug-info=build/app/outputs/symbols

# Or split per ABI (if you re-enable multiple ABIs)
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols
```

## Testing on Different Devices

### If you need to test on 32-bit devices:
1. Edit `android/app/build.gradle.kts`
2. Change `ndk { abiFilters += listOf("arm64-v8a") }` to:
   ```kotlin
   ndk { abiFilters += listOf("arm64-v8a", "armeabi-v7a") }
   ```

### If you need to test on x86 emulators:
1. Edit `android/app/build.gradle.kts`
2. Change `ndk { abiFilters += listOf("arm64-v8a") }` to:
   ```kotlin
   ndk { abiFilters += listOf("arm64-v8a", "x86", "x86_64") }
   ```

## Additional Optimizations (Optional)

If you need even smaller debug builds, consider:

1. **Remove unused dependencies** - Review `pubspec.yaml` and remove any unused packages
2. **Optimize images** - Compress images in `assets/images/`
3. **Use App Bundle** - For distribution, use `flutter build appbundle` instead of APK
4. **Profile mode** - Use `flutter build apk --profile` for testing (smaller than debug, but with some optimizations)

## Notes

- Debug builds are inherently larger than release builds due to:
  - Debug symbols
  - Unoptimized code
  - Development tools
- The ABI filtering is the most significant optimization
- Release builds will be much smaller (~20-30 MB) due to code shrinking and optimization

