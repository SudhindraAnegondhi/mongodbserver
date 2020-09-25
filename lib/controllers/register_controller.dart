import 'dart:convert';
import 'package:mongoserver/mongoserver.dart';
import 'package:shelf/shelf.dart';
import 'package:mongoserver/utils/utils.dart';
import 'package:mongoserver/models/user.dart';
import 'package:mongoserver/db/query.dart';

class RegisterController {
  final Request request;
  final context;
  RegisterController(this.context, this.request);

  Future<Response> createUser({bool isAdmin = false}) async {
    if ((request.contentLength ?? -1) < 0) {
      returnError('Body is missing',
          statusCode: HttpStatus.internalServerError);
    }
    // ignore: todo
    // TODO implement basic authorization to pass username and password
    final params =
        json.decode(await request.readAsString()) as Map<String, dynamic>;

    if (params['username'] == null || params['password'] == null) {
      return returnError('username, password is required');
    }
    if (!isPasswordOk(params['password'])) {
      return returnError(_passwordRules);
    }
    final user = User(
      username: params['username'],
      isAdmin: isAdmin,
    );
    user.salt = generateRandomSalt();
    user.hashedPassword = hashPassword(params['password'], user.salt);
    Response response;
    response =
        await Query(context, 'user').insert(user.toMap(), id: User().primaryKey);
    if (response.statusCode != HttpStatus.ok) {
      return response;
    }
    response =
        await Query(context, 'user').findOne(User().primaryKey, user.username);
    if (response.statusCode != HttpStatus.ok) {
      return response;
    }
    return Response(HttpStatus.ok,
        body: json.encode(await response.readAsString()));
  }
}

const _passwordRules =
    "Password must be  6 characters or more, one each of upper and lowercase letter, special character and a number. ";

bool isPasswordOk(String password) {
  final reg = RegExp(
      r"(?=^.{6,}$)(?=.*\d)(?=.*[!@#$%^&*]+)(?![.\n])(?=.*[A-Z])(?=.*[a-z]).*$");
  return reg.hasMatch(password);
}
