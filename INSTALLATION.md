# Installation Guide

## Adding as Dev Dependency

### Option 1: From pub.dev (Recommended)

Once published, add to your Flutter project's `pubspec.yaml`:

```yaml
dev_dependencies:
  smart_asset_analyser: ^0.1.1
```

Then run:
```bash
flutter pub get
```

### Option 2: Local Path (For Development)

If you're developing or testing locally:

```yaml
dev_dependencies:
  smart_asset_analyser:
    path: /absolute/path/to/smart_asset_analyser
```

### Option 3: Git Repository

You can also use a Git repository:

```yaml
dev_dependencies:
  smart_asset_analyser:
    git:
      url: https://github.com/Vjex/smart_asset_analyser.git
      ref: main  # or specific tag/commit
```

## Complete Example

Here's a complete `pubspec.yaml` example:

```yaml
name: my_flutter_app
description: My Flutter application

publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

dev_dependencies:
  smart_asset_analyser: ^0.1.1
  flutter_test:
    sdk: flutter

flutter:
  uses-material-design: true
  
  assets:
    - assets/images/
    - assets/icons/
```

## After Installation

1. **Install Python Dependencies** (one-time):
   ```bash
   # Navigate to your project
   cd /path/to/your/flutter/project
   
   # Install Python dependencies
   # Note: You need to install these in the smart_asset_analyser package directory
   cd /path/to/smart_asset_analyser
   pip install -r requirements.txt
   ```

2. **Run the Analyser**:
   ```bash
   cd /path/to/your/flutter/project
   dart run smart_asset_analyser:analyse assets
   ```

## Why Dev Dependency?

This package is added as a `dev_dependency` because:
- It's a development tool, not needed at runtime
- It helps analyze and optimize assets during development
- It doesn't need to be included in the final app bundle
- Reduces app size by keeping it out of production builds

## Troubleshooting

### Package Not Found

If you get "package not found" error:
1. Make sure you ran `flutter pub get`
2. Check the package name is correct: `smart_asset_analyser`
3. Verify the version constraint matches published versions

### Python Dependencies

Remember: Python dependencies must be installed separately:
```bash
pip install -r requirements.txt
```

This is done in the package directory, not your project directory.

