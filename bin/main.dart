import 'package:args/args.dart';
import 'package:mongoserver/mongoserver.dart';
import 'package:mongoserver/base/application.dart';
import 'package:mongoserver/base/schema.dart';

Future main(List<String> arguments) async {
  final results = parseArgs(arguments);
  if (results.command.name == 'serve') {
    serve();
  }
  if (results.command.name == "schema") {
    schema(results);
  }
}

ArgResults parseArgs(List<String> arguments) {
  final parser = ArgParser(allowTrailingOptions: true);
  final command = ArgParser(allowTrailingOptions: true);
  parser.addOption('add', abbr: 'a', help: 'Json String of the model schema');
  parser.addOption('modify',
      abbr: 'm', help: 'Json string of the model schema to be modified');
  parser.addOption('drop', abbr: 'd', help: 'model name to be dropped');
  parser.addCommand('serve', command);
  parser.addCommand('schema', command);
  return parser.parse(arguments);
}

void serve() async {
  final app = Application()
    ..options.configurationFilepath = 'config.yaml'
    ..options.address = '0.0.0.0'
    ..options.port = 8888;

  final count = Platform.numberOfProcessors ~/ 3;
  await app.start(numberOfInstances: count > 0 ? count : 1);

  print('Application started on port: ${app.options.port}.');
  print('Use Ctrl-C (SIGINT) to stop running the application.');
}
