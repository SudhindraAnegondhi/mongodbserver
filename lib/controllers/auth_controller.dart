import 'dart:convert';
import 'package:mongoserver/mongoserver.dart';
import 'package:shelf/shelf.dart';
import 'package:mongoserver/utils/utils.dart';
import 'package:mongoserver/models/user.dart';
import 'package:mongoserver/db/query.dart';

class AuthController {
  final Request request;
  final context;
  AuthController(this.context, this.request);

  Future<Response> login({bool isAdmin = false}) async {
    if ((request.contentLength ?? -1) < 0) {
      returnError('Body is missing',
          statusCode: HttpStatus.internalServerError);
    }
    // TODO: implement basic authorization to pass username and password
    final params =
        json.decode(await request.readAsString()) as Map<String, dynamic>;

    if (params['username'] == null || params['password'] == null) {
      return returnError('username, password is required');
    }
  
    final Response response = await Query(context, 'user')
        .findOne(User.primaryKey, params['username']);
    if (response.statusCode != HttpStatus.ok) {
      return returnError('Authentication failed');
    }
    final user = User.fromMap(
        json.decode(await response.readAsString()) as Map<String, dynamic>);
    final hashedPassword = hashPassword(params['password'], user.salt);
    if (hashedPassword != user.hashedPassword) {
      return returnError('Authentication failed - 02');
    }
  

    String token = jwtToken();

    return Response(HttpStatus.ok, body: token);
  }
}

