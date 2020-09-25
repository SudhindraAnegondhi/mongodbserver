import 'dart:io';
import 'package:safe_config/safe_config.dart';

/// AppConfiguration
///
/// The server requires the following information to be set up
/// in [config.yaml]
/// [port] Port the server is funning from. 8888 is default
/// [address] host addrress to listen. Default localhost
/// [authsecret] to be used for basic auth
///
/// If field type specific handling of queries are not required,
/// ModelController can be used directly to handle requests.
/// However ModelController will handle only requests registered
/// through [models] entry in config.yaml. Model names separated by
/// commas in a single line will register the models.
///
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

  void addModel(String model) {
    if (!models.contains(model)) {
      models += ',$model';
    }
  }
}
