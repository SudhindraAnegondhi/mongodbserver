import 'dart:io';
import 'dart:convert';
import 'package:args/args.dart';
import 'package:json_to_dart/json_to_dart.dart';

void schema(ArgResults results) async {
  print('MongoDb Server Version 0.0.1');
  print('Schema Processor');
  final args = results.command.arguments;
  final rest = results.rest;
  print(rest);
  for (int i = 0; i < args.length; i++) {
    if (args[i].startsWith('add')) {
      addSchema(args[i + 1]);
    }
  }
}

Future<bool> fileExists(String file) async {
  return await File('./schema/$file.dart').exists();
}

void addSchema(String arg) async {
  final data = json.decode(arg) as Map<String, dynamic>;

  final model = data['model'];
  final fields = data['fields'];
  final classGenerator = new ModelGenerator(model);
  DartCode dartCode = classGenerator.generateDartClasses(json.encode(fields));
  print(dartCode.code);
}
