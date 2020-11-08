import 'dart:io';

const _projectDir = '/mongoserver';

class Io {
  String _home;
  String get home => _home;

  String _scriptPath() {
    if (_home == null) {
      var script = Platform.script.toString();
      if (script.startsWith("file://")) {
        script = script.substring(7);
      } else {
        final idx = script.indexOf("file:/");
        script = script.substring(idx + 5);
      }
      final index = script.indexOf(_projectDir);
      if (index == -1) {
        print('This must be run from the MongoServer project directory');
        exit(1);
      }
      _home = script.substring(0, index + _projectDir.length);
    }
    return _home;
  }

  String _filePath(String path, String filename) => path?.isEmpty ?? true
      ? _scriptPath() +
          '/' +
          (filename.contains('.') ? filename : '$filename.dart')
      : "${_scriptPath()}/lib/$path/${filename.contains('.') ? filename : '$filename.dart'}";

  String readFile(String path, String filename) =>
      new File(_filePath(path, filename)).readAsStringSync();

  void saveFile(String path, String filename, String contents) =>
      File(_filePath(path, filename))
          .writeAsStringSync(contents, mode: FileMode.write);
}
