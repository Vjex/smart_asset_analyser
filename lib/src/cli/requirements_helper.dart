import 'dart:io';
import 'package:path/path.dart' as path;
import '../embeddings/python_bridge.dart';

/// Helper to find and display requirements.txt location
class RequirementsHelper {
  static Future<void> showRequirementsPath(String projectRoot) async {
    final pythonBridge = PythonBridge(projectRoot: projectRoot);
    final pipCommand = PythonBridge.getPipCommand();
    
    print('🔍 Finding requirements.txt...');
    print('');
    
    final requirementsPath = await pythonBridge.getRequirementsTxtPath();
    if (requirementsPath != null) {
      print('✅ Found requirements.txt at:');
      print('   $requirementsPath');
      print('');
      print('📦 Install Python dependencies with:');
      if (pipCommand.contains(' -m ')) {
        print('   $pipCommand install -r "$requirementsPath"');
      } else {
        print('   $pipCommand install -r "$requirementsPath"');
      }
    } else {
      final packageLocation = await pythonBridge.getPackageLocation();
      print('⚠️  Could not automatically find requirements.txt');
      print('');
      print('📦 Package location: $packageLocation');
      if (packageLocation != 'unknown') {
        final altPath = path.join(packageLocation, 'requirements.txt');
        print('📄 Expected location: $altPath');
        if (File(altPath).existsSync()) {
          print('   ✅ File exists!');
          print('');
          print('Install with:');
          if (pipCommand.contains(' -m ')) {
            print('   $pipCommand install -r "$altPath"');
          } else {
            print('   $pipCommand install -r "$altPath"');
          }
        } else {
          print('   ❌ File not found');
        }
      }
      print('');
      print('📋 Manual installation:');
      if (pipCommand.contains(' -m ')) {
        print('   $pipCommand install torch transformers pillow numpy cairosvg lottie');
      } else {
        print('   $pipCommand install torch transformers pillow numpy cairosvg lottie');
      }
    }
  }
}

