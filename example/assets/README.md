# Example Assets

This folder contains example assets for testing the smart_asset_analyser.

## Structure

- `images/` - Sample image files (PNG, JPG, WebP)
- `icons/` - SVG icon files
- `animations/` - Lottie JSON animation files

## Adding Test Assets

To test the analyser, add some assets here:

1. **Images**: Add PNG, JPG, or WebP files to `images/`
2. **SVGs**: Add SVG files to `icons/`
3. **Lottie**: Add Lottie JSON files to `animations/`

## Testing Duplicate Detection

To test duplicate detection:
1. Add the same or similar images to test similarity detection
2. Run the analyser: `dart run smart_asset_analyser:analyse assets`
3. Check the generated `asset_report.html` for similar assets

## Note

This is just an example. In a real project, you would have your actual assets here.

