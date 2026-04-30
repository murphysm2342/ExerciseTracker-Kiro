# Duplicate Files Fix Guide

## Summary
Your project has multiple duplicate files causing build conflicts. I've merged the HealthKitService files for you. Now you need to manually remove the duplicate files from your project.

## ✅ COMPLETED: HealthKitService Merge
- **Merged file**: `HealthKitService-Services.swift` (this file now contains both import AND export functionality)
- **Action needed**: Delete the duplicate and rename the merged file

---

## 🔧 Step-by-Step Fix Instructions

### 1. HealthKitService Files

**Files to delete:**
```
/Users/seanmurphy/Library/Mobile Documents/com~apple~CloudDocs/OS Development/Development Projects/Exercise_Tracker/ExerciseTracker-Kiro/ExerciseTracker-Kiro/Views/HealthKitService.swift
```

**File to keep and rename:**
```
/Users/seanmurphy/Library/Mobile Documents/com~apple~CloudDocs/OS Development/Development Projects/Exercise_Tracker/ExerciseTracker-Kiro/ExerciseTracker-Kiro/Services/HealthKitService-Services.swift
→ Rename to: HealthKitService.swift
```

**Actions:**
1. In **Finder**, navigate to the Views folder and delete `HealthKitService.swift`
2. In **Xcode**, select `HealthKitService-Services.swift` in the Services folder
3. Right-click → **Rename** → Change to `HealthKitService.swift`

---

### 2. SettingsViewModel Files

Your error shows duplicate `SettingsViewModel.stringsdata` - you likely have two SettingsViewModel.swift files.

**Search for duplicates in Xcode:**
1. Press **⌘⇧O** (Open Quickly)
2. Type "SettingsViewModel"
3. Look for duplicate files
4. Delete the one that's in the wrong location (probably in Views instead of ViewModels)

---

### 3. User Files

Your error shows duplicate `User.stringsdata` - you have two User.swift files.

**Search for duplicates in Xcode:**
1. Press **⌘⇧O** (Open Quickly)
2. Type "User.swift"
3. Look for duplicate files
4. Keep the one in Models folder, delete the duplicate

---

## 🧹 After Removing Duplicates

1. **Clean Build Folder**: Product → Clean Build Folder (⇧⌘K)
2. **Close Xcode completely**
3. **Delete DerivedData** (optional but recommended):
   ```bash
   rm -rf ~/Library/Developer/Xcode/DerivedData/ExerciseTracker-Kiro-*
   ```
4. **Reopen Xcode**
5. **Build**: Product → Build (⌘B)

---

## 📋 What Was Merged in HealthKitService

The merged file now includes:

### From Services version:
- ✅ Import functionality (Requirements 5.1, 5.2, 5.3)
- ✅ Developer notes about HealthKit setup

### From Views version:
- ✅ Export functionality (Task 7)
- ✅ `exportCardioWorkout()` method
- ✅ `exportStrengthWorkout()` method
- ✅ Additional error cases (`saveFailed`, `notAvailable`)
- ✅ Write permissions for HealthKit

---

## 🎯 Expected Result

After following these steps, you should have:
- ✅ One `HealthKitService.swift` in the Services folder (merged, with both import & export)
- ✅ One `SettingsViewModel.swift` in the correct location
- ✅ One `User.swift` in the Models folder
- ✅ No build errors about "Multiple commands produce"
- ✅ No "Invalid redeclaration" errors

---

## ⚠️ If You're Using Git

Before deleting files, consider committing your current state:
```bash
git add .
git commit -m "Before removing duplicate files"
```

This way you can recover if needed!
