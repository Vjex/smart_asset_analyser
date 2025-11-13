# Publishing to pub.dev

## Current Status: ⚠️ NOT READY YET

The package has several issues that need to be fixed before publishing:

### Issues to Fix:

1. **Package Name Conflict**
   - Current name: `analyser` (conflicts with existing package)
   - Suggested: `flutter_asset_analyser` or `asset_similarity_analyser`

2. **Python Scripts Location**
   - Python scripts in `python/` folder won't be accessible when installed from pub.dev
   - Need to either:
     - Bundle Python scripts in the package
     - Provide installation script
     - Use a different approach (e.g., download scripts on first run)

3. **Missing Requirements**
   - CHANGELOG.md ✅ (created)
   - LICENSE ✅ (exists)
   - Repository URL (needs to be set to actual GitHub repo)
   - Homepage URL (needs to be set to actual GitHub repo)

4. **Import Paths**
   - All imports need to use the new package name
   - `lib/analyser.dart` should match package name

5. **Python Dependencies**
   - Users need to install Python dependencies separately
   - This is a limitation that should be clearly documented

## Steps to Publish

### 1. Fix Package Name

Update `pubspec.yaml`:
```yaml
name: flutter_asset_analyser  # or your preferred name
```

Update all imports:
```dart
import 'package:flutter_asset_analyser/...';
```

### 2. Handle Python Scripts

**Option A: Bundle in Package** (Recommended)
- Include `python/` folder in package
- Update code to find scripts relative to package location
- Document that Python dependencies must be installed separately

**Option B: Download on First Run**
- Download Python scripts from GitHub on first run
- More complex but cleaner separation

### 3. Update Repository URLs

Set actual GitHub repository:
```yaml
homepage: https://github.com/yourusername/flutter_asset_analyser
repository: https://github.com/yourusername/flutter_asset_analyser
```

### 4. Test Locally

```bash
# Test package structure
dart pub publish --dry-run

# Fix any issues
# Repeat until no errors
```

### 5. Publish

```bash
# Login to pub.dev
dart pub login

# Publish
dart pub publish
```

## Recommendations

### Before Publishing:

1. **Create GitHub Repository**
   - Create repo with proper README
   - Add all files
   - Set up proper structure

2. **Test Installation**
   - Test installing from pub.dev locally
   - Verify Python scripts are accessible
   - Test all functionality

3. **Documentation**
   - Clear installation instructions
   - Python dependency requirements
   - Troubleshooting guide

4. **Version Management**
   - Start with 0.1.0
   - Use semantic versioning
   - Update CHANGELOG.md

5. **Consider Package Name**
   - Check if name is available on pub.dev
   - Make it descriptive and unique
   - Consider SEO/discoverability

## Alternative: Keep as Local Package

If publishing is too complex, you can:
- Keep it as a local package
- Share via Git submodule
- Use as a private package
- Publish later when ready

## Current Blockers

1. ❌ Package name conflicts with existing package
2. ❌ Python scripts location not handled for pub.dev
3. ❌ Import paths need updating
4. ⚠️ Repository URLs are placeholders
5. ⚠️ Need to test installation from pub.dev

## Next Steps

1. Fix package name and imports
2. Handle Python scripts location
3. Update repository URLs
4. Test `dart pub publish --dry-run`
5. Create GitHub repository
6. Publish to pub.dev

