# Setup Instructions - iOSWeather

## ⚠️ IMPORTANT: SPM Dependencies Required

This project **WILL NOT BUILD** until you add the Swift Package Manager dependencies. Follow these instructions carefully.

## Step-by-Step Setup

### Step 1: Open the Project

```bash
cd /Users/juancarlossuarezmarin/Desktop/front/ios/iosWeather
open iosWeather.xcodeproj
```

### Step 2: Add Alamofire (Required)

1. In Xcode, go to **File → Add Package Dependencies...**
2. In the search field (top right), paste:
   ```
   https://github.com/Alamofire/Alamofire.git
   ```
3. Click **Add Package**
4. In the "Dependency Rule" dropdown, select **"Up to Next Major Version"**
5. Enter version: **5.0.0** (it will use 5.x.x)
6. Click **Add Package**
7. In the "Add to Target" dialog:
   - ✅ Check **iosWeather** (main app target)
   - ❌ Uncheck **iosWeatherTests**
   - ❌ Uncheck **iosWeatherUITests**
8. Click **Add Package**

### Step 3: Add Kingfisher (Required)

1. In Xcode, go to **File → Add Package Dependencies...**
2. In the search field (top right), paste:
   ```
   https://github.com/onevcat/Kingfisher.git
   ```
3. Click **Add Package**
4. In the "Dependency Rule" dropdown, select **"Up to Next Major Version"**
5. Enter version: **7.0.0** (it will use 7.x.x)
6. Click **Add Package**
7. In the "Add to Target" dialog:
   - ✅ Check **iosWeather** (main app target)
   - ❌ Uncheck **iosWeatherTests**
   - ❌ Uncheck **iosWeatherUITests**
8. Click **Add Package**

### Step 4: Verify Dependencies

After adding both packages, verify they're installed:

1. In Xcode's Project Navigator (left sidebar), look for:
   ```
   iosWeather
   ├── Dependencies
   │   ├── Alamofire
   │   └── Kingfisher
   ```

2. Or check in: **File → Packages → Package.resolved**

### Step 5: Build the Project

1. Select a simulator: **iPhone 15** or **iPhone 15 Pro**
2. Press **Cmd+B** to build
3. Wait for SPM to resolve and download packages (first time only)
4. Build should succeed ✅

### Step 6: Run the App

1. Press **Cmd+R** or click the ▶️ Run button
2. When prompted, **Allow** location access
3. The app should launch successfully! 🎉

## Troubleshooting

### ❌ "No such module 'Alamofire'" error

**Solution:**
1. File → Packages → Reset Package Caches
2. File → Packages → Resolve Package Versions
3. Clean build folder: Shift+Cmd+K
4. Build again: Cmd+B

### ❌ "Cannot find type 'Session' in scope"

**Solution:**
- Make sure you added Alamofire to the **iosWeather** target (not test targets)
- Check: Project Settings → iosWeather target → General → Frameworks, Libraries, and Embedded Content

### ❌ Package resolution takes too long

**Solution:**
- Check your internet connection
- Xcode may be downloading the packages (can take 1-2 minutes first time)
- Check progress in the top bar of Xcode

### ❌ "Info.plist not found" or location not working

**Solution:**
The `Info.plist` file is already created at:
```
iosWeather/Info.plist
```

Make sure it's added to the target:
1. Select `Info.plist` in Project Navigator
2. In File Inspector (right sidebar), check that **Target Membership** includes "iosWeather"

## Alternative: Command Line Setup

If you prefer command line (advanced):

```bash
# This won't work as SPM packages must be added through Xcode UI for app projects
# You MUST use the Xcode GUI to add packages
```

## Verification Checklist

Before running the app, verify:

- ✅ Alamofire appears in Project Navigator under Dependencies
- ✅ Kingfisher appears in Project Navigator under Dependencies
- ✅ Project builds without errors (Cmd+B)
- ✅ Info.plist exists in iosWeather/ folder
- ✅ Simulator is selected (not "Any iOS Device")

## Next Steps

Once setup is complete:

1. **Run the app** (Cmd+R)
2. **Grant location permission** when prompted
3. **Explore the three tabs**:
   - Current: GPS-based weather
   - Search: City search
   - History: Search history

4. **Run tests** (Cmd+U)
   - All ViewModel tests should pass
   - Uses mock implementations

## Need Help?

If you encounter issues:

1. Check the **CLAUDE.md** file for detailed architecture documentation
2. Check the **README.md** file for feature overview
3. Review error messages carefully
4. Try cleaning and rebuilding

## Summary

This project requires manual SPM package addition because:
- It's an Xcode app project (not a Swift package)
- SPM dependencies for app projects must be added via Xcode UI
- The `.xcodeproj` file will be updated automatically

After adding Alamofire and Kingfisher, the project is fully ready to build and run! 🚀
