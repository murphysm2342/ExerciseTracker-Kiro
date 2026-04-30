# Required Info.plist Configuration

Add these entries to your `Info.plist` file for HealthKit integration:

```xml
<!-- HealthKit Usage Descriptions (Required for Task 7) -->
<key>NSHealthShareUsageDescription</key>
<string>This app needs access to read your workout data from the Health app to import your cardio sessions.</string>

<key>NSHealthUpdateUsageDescription</key>
<string>This app needs permission to save your workout sessions to the Health app for tracking and analysis.</string>
```

## Xcode Project Configuration

1. Open your project in Xcode
2. Select your app target
3. Go to "Signing & Capabilities" tab
4. Click "+ Capability"
5. Add "HealthKit"
6. Ensure these options are checked:
   - ✅ Clinical Health Records
   - ✅ Background Delivery (optional, for background sync)

## Privacy Manifest (if required)

If your app requires a Privacy Manifest file, ensure HealthKit is declared:

```json
{
  "NSPrivacyAccessedAPITypes": [
    {
      "NSPrivacyAccessedAPIType": "NSPrivacyAccessedAPICategoryHealthKit",
      "NSPrivacyAccessedAPITypeReasons": [
        "Importing and exporting workout sessions"
      ]
    }
  ]
}
```

## Testing HealthKit Integration

### Simulator Testing
HealthKit functionality is **limited in the Simulator**. You can:
- Request permissions ✅
- Save data ✅
- Read data ✅

But you won't see the same Health app UI as on a real device.

### Device Testing (Recommended)
For full testing:
1. Use a physical iPhone or iPad
2. Ensure Health app is set up
3. Test both import and export flows
4. Verify workouts appear in Health app

### Debug Mode
To test without actual HealthKit:
```swift
// In your app initialization or debug settings
let mockHealthKitService = MockHealthKitService()
// Use this for testing UI without requiring HealthKit permissions
```

## Common Issues

### Permission Denied
If users deny HealthKit permissions:
- They must go to Settings > Privacy > Health > [Your App] to enable
- App cannot programmatically check if user explicitly denied (Apple privacy feature)
- Show helpful error messages directing users to Settings

### Data Not Appearing in Health App
- Verify permissions were granted for both read AND write
- Check that the workout data is valid (duration > 0, valid dates, etc.)
- Ensure HealthKit capability is enabled in Xcode
- Restart Health app to refresh data

### Build Errors
If you get build errors about missing HealthKit:
1. Verify HealthKit framework is added to your target
2. Check that `import HealthKit` statements are present
3. Ensure HealthKit capability is enabled
4. Clean build folder (Shift+Cmd+K)

## Verification Checklist

- [ ] Info.plist contains NSHealthShareUsageDescription
- [ ] Info.plist contains NSHealthUpdateUsageDescription
- [ ] HealthKit capability is enabled in project
- [ ] HealthKit framework is imported in relevant files
- [ ] App builds without errors
- [ ] Permissions are requested on first use
- [ ] Workouts successfully export to Health app
- [ ] Workouts can be imported from Health app
