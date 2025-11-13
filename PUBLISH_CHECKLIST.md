# Pub.dev Publishing Checklist

## ❌ NOT READY YET - Critical Issues

### 🔴 Critical Blockers

1. **Python Scripts Location** ⚠️ **MAJOR ISSUE**
   - Python scripts in `python/` folder won't be accessible when package is installed from pub.dev
   - Current code looks for scripts relative to package location, which won't work
   - **Solution Needed**: 
     - Option A: Bundle Python scripts in package and find them via package path
     - Option B: Download scripts from GitHub on first run
     - Option C: Require users to clone repo separately (not ideal)

2. **Package Name** ✅ Fixed
   - Changed from `analyser` to `flutter_asset_analyser`
   - Need to verify name is available on pub.dev

3. **Import Paths** ✅ Fixed
   - Updated to use `flutter_asset_analyser`
   - Need to verify all imports are correct

4. **Repository URLs** ⚠️ **NEEDS UPDATE**
   - Currently placeholders: `https://github.com/yourusername/flutter_asset_analyser`
   - Must be set to actual GitHub repository

### ⚠️ Important Issues

5. **Python Dependencies** 
   - Users must install Python dependencies separately
   - This is a limitation that must be clearly documented
   - Consider providing installation script

6. **Testing**
   - Need to test installation from pub.dev
   - Verify all functionality works when installed as package
   - Test Python script location resolution

7. **Documentation**
   - README needs pub.dev specific instructions
   - Clear Python setup requirements
   - Installation troubleshooting

### ✅ Completed

- [x] LICENSE file exists
- [x] CHANGELOG.md created
- [x] Package name updated
- [x] Import paths updated
- [x] Basic documentation exists

## Required Steps Before Publishing

### 1. Fix Python Scripts Location

**Current Problem:**
```dart
// This won't work when installed from pub.dev
final scriptPath = path.join(
  path.dirname(Platform.script.toFilePath()),
  '..',
  'python',
  'clip_service.py',
);
```

**Solution:**
```dart
// Find scripts relative to package location
import 'package:flutter_asset_analyser/flutter_asset_analyser.dart';
import 'package:package_config/package_config.dart';

Future<String> _getPythonScriptPath(String scriptName) async {
  // Get package location
  final packageConfig = await findPackageConfig(Directory.current);
  final package = packageConfig?.packages['flutter_asset_analyser'];
  if (package != null) {
    final scriptPath = path.join(
      package.packageUriRoot.toFilePath(),
      'python',
      scriptName,
    );
    if (File(scriptPath).existsSync()) {
      return scriptPath;
    }
  }
  throw Exception('Python script not found: $scriptName');
}
```

### 2. Create GitHub Repository

1. Create repo on GitHub
2. Push all code
3. Update `pubspec.yaml` with actual URLs
4. Add proper README
5. Set up issues/tags

### 3. Test Installation

```bash
# Create test project
mkdir test_install
cd test_install
dart create .

# Add package
# Edit pubspec.yaml to add flutter_asset_analyser
dart pub get

# Test functionality
dart run flutter_asset_analyser:analyse assets
```

### 4. Update Documentation

- Add pub.dev specific installation instructions
- Document Python requirements clearly
- Add troubleshooting section
- Update all path references

### 5. Final Checks

```bash
# Validate package
dart pub publish --dry-run

# Check for issues
dart analyze

# Test locally
dart pub get
dart run flutter_asset_analyser:analyse assets --help
```

## Recommended Approach

### Option 1: Fix Python Scripts Location (Recommended)

1. Use `package_config` to find package location
2. Bundle Python scripts in package
3. Find scripts relative to package root
4. Document Python dependency installation

### Option 2: Download Scripts on First Run

1. Download Python scripts from GitHub on first run
2. Cache them locally
3. More complex but cleaner separation

### Option 3: Separate Python Package

1. Create separate Python package on PyPI
2. Install via pip
3. More complex setup for users

## Current Status Summary

| Item | Status | Notes |
|------|--------|-------|
| Package name | ✅ Fixed | Changed to `flutter_asset_analyser` |
| Import paths | ✅ Fixed | Updated to new name |
| LICENSE | ✅ Done | MIT License exists |
| CHANGELOG | ✅ Done | Created |
| Repository URLs | ❌ Placeholder | Need actual GitHub repo |
| Python scripts | ❌ **BLOCKER** | Won't work when installed from pub.dev |
| Testing | ❌ Not done | Need to test installation |
| Documentation | ⚠️ Partial | Needs pub.dev specific info |

## Recommendation

**DO NOT PUBLISH YET** until:

1. ✅ Python scripts location is fixed
2. ✅ GitHub repository is created
3. ✅ Repository URLs are updated
4. ✅ Installation is tested
5. ✅ Documentation is complete

The package is functional but has critical issues that will prevent it from working when installed from pub.dev.

