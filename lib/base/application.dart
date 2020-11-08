import 'dart:async';
import 'dart:io';
import 'package:mongo_dart/mongo_dart.dart' show Db;

import 'package:mongoserver/base/app_configuration.dart';
import 'package:mongoserver/mongoserver.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:mongoserver/base/service.dart';

import 'package:mongoserver/base/database.dart';

class ApplicationOptions {
  String configurationFilepath;
  int port;
  String address;
}

class Application {
  ApplicationOptions options = ApplicationOptions();
  AppConfiguration config;
  Function entryPoint;
  HttpServer server;
  Db db;
  Map<String, dynamic> state = {};

  static final Map<String, Application> _cache = <String, Application>{};
  static Map<String, dynamic> context() {
    if (_cache.containsKey('Application')) {
      final app = _cache['Application'];
      return {
        'options': app.options,
        'config': app.config,
        'db': app.db,
        'state': app.state,
      };
    }
    return {};
  }

  factory Application(
      {String configurationFilePath, int port, String address}) {
    if (_cache.containsKey('Application')) {
      return _cache['Applcation'];
    }
    _cache['Application'] =
        Application._getInstance(configurationFilePath, port, address);

    return _cache['Application'];
  }

  Application._getInstance(
      String configurationFilePath, int port, String address);

  Future<void> start({int numberOfInstances}) async {
    config = AppConfiguration(options.configurationFilepath);

    final address = (config.address ?? options.address).contains('localhost')
        ? InternetAddress.loopbackIPv4
        : await InternetAddress.lookup(config.address ?? options.address);
    final database = Database(config);
    db = await database.open();
    final service = Service(context(), modifyContext);

    // Load routes in to context

    server = await io.serve(service.withLog,
        address is List ? address[0] : address, config.port ?? options.port);
  }

  void modifyContext(String component, String key, dynamic item) {
    switch (component) {
      case 'config':
        if (key == 'model') {
          config.addModel(item);
        }
        break;
      case 'route':
        if (key == 'routes') {
          // item = Map<String, dynamic> route name, model instance ?? null
          state['routes'] = item;
        }
        break;
      case 'options':
        break;
    }
  }
}
