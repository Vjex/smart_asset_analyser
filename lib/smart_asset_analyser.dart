/// Flutter Asset Analyser
/// 
/// A package to detect visually identical/similar assets in Flutter projects
/// using Deep Visual Embeddings (CLIP).

library smart_asset_analyser;

export 'src/models/asset_info.dart';
export 'src/models/similarity_group.dart';
export 'src/discovery/asset_discovery.dart';
export 'src/embeddings/embedding_service.dart';
export 'src/embeddings/python_bridge.dart';
export 'src/similarity/similarity_calculator.dart';
export 'src/report/html_generator.dart';

