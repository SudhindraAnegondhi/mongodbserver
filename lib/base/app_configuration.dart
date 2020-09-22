import 'dart:io';
import 'package:safe_config/safe_config.dart';

class AppConfiguration extends Configuration {
  @optionalConfiguration
  int port;
  @optionalConfiguration
  String address;
  String authsecret;
  @optionalConfiguration
  String models;
  AppConfiguration(String filename) : super.fromFile(File(filename));
  DatabaseConfiguration database;
}
