#!/usr/bin/env dart
/**
 * Flutter Asset Analyser CLI
 * 
 * Detects visually identical/similar assets using Deep Visual Embeddings
 */

import 'dart:io';
import 'package:args/args.dart';
import 'package:smart_asset_analyser/src/cli/command_handler.dart';

void main(List<String> arguments) async {
  final parser = ArgParser();
  final analyseCommand = ArgParser();
  final assetsCommand = ArgParser();
  
  assetsCommand
          ..addOption(
            'threshold',
            abbr: 't',
            defaultsTo: '0.85',
            help: 'Similarity threshold (0.0-1.0)',
          )
          ..addOption(
            'min-similarity',
            abbr: 'm',
            defaultsTo: '85',
            help: 'Minimum similarity percentage (0-100)',
          )
          ..addOption(
            'output',
            abbr: 'o',
            defaultsTo: 'asset_report.html',
            help: 'Output HTML file path',
          )
          ..addOption(
            'types',
            defaultsTo: 'all',
            help: 'Asset types to scan: images,svgs,lottie (comma-separated, default: all)',
          )
          ..addOption(
            'exclude',
            help: 'Exclude files matching pattern (glob)',
          )
          ..addOption(
            'project-path',
            abbr: 'p',
            defaultsTo: '.',
            help: 'Flutter project path (default: current directory)',
          )
          ..addOption(
            'python-path',
            help: 'Path to Python executable (default: python3)',
          )
          ..addFlag(
            'use-server',
            defaultsTo: false,
            help: 'Use HTTP server mode for Python bridge',
          )
          ..addOption(
            'server-port',
            defaultsTo: '8000',
            help: 'HTTP server port (default: 8000)',
          )
          ..addOption(
            'parallel',
            defaultsTo: '4',
            help: 'Number of parallel workers (default: 4)',
          )
          ..addFlag(
            'cache-embeddings',
            defaultsTo: true,
            help: 'Cache embeddings to disk',
          )
          ..addFlag(
            'help',
            abbr: 'h',
            negatable: false,
            help: 'Show this help message',
          );
  
  analyseCommand.addCommand('assets', assetsCommand);
  parser.addCommand('analyse', analyseCommand);

  try {
    final results = parser.parse(arguments);

    if (arguments.isEmpty || arguments.contains('--help') || arguments.contains('-h')) {
      print('Flutter Asset Analyser');
      print('');
      print('Usage: dart run smart_asset_analyser:analyse assets [options]');
      print('');
      print('Analyse assets in a Flutter project for visual similarity.');
      print('');
      print(parser.usage);
      exit(0);
    }

    final command = results.command;
    if (command != null && command.name == 'analyse') {
      final subCommand = command.command;
      if (subCommand != null && subCommand.name == 'assets') {
        final handler = CommandHandler();
        await handler.handleAnalyseAssets(subCommand);
        exit(0);
      }
    }

    print('Unknown command. Use --help for usage information.');
    exit(1);
  } catch (e) {
    print('Error: $e');
    print('Use --help for usage information.');
    exit(1);
  }
}

