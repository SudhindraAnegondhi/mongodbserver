import 'package:mongoserver/mongoserver.dart';
import 'package:mongoserver/base/application.dart';

Future main() async {
  final app = Application()
    ..options.configurationFilepath = 'config.yaml'
    ..options.address = '0.0.0.0'
    ..options.port = 8888;
    
  final count = Platform.numberOfProcessors ~/ 3;
  await app.start(numberOfInstances: count > 0 ? count : 1);
  
  print('Application started on port: ${app.options.port}.');
  print('Use Ctrl-C (SIGINT) to stop running the application.');
}
