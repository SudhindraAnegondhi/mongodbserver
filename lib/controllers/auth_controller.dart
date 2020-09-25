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
    Response response;
    if ((request.contentLength ?? -1) < 0) {
      returnError('Body is missing',
          statusCode: HttpStatus.internalServerError);
    }

    final params =
        json.decode(await request.readAsString()) as Map<String, dynamic>;

    if (params['username'] == null || params['password'] == null) {
      return returnError('username, password is required');
    }

    response = await Query(context, 'user')
        .findOne(User().primaryKey, params['username']);
    if (response.statusCode != HttpStatus.ok) {
      return returnError('Authentication failed');
    }
    final userMap =  json.decode(await response.readAsString()) as Map<String, dynamic>;
    final user = User.fromMap(userMap);
    final hashedPassword = hashPassword(params['password'], user.salt);
    if (hashedPassword != user.hashedPassword) {
      return returnError('Authentication failed - 02');
    }
    userMap.remove('salt');
    userMap.remove('hashedPassword');

    final body = json.encode({
      'token': jwtToken(user.isAdmin),
      'user': userMap,
    });
    
    return Response(HttpStatus.ok, body: body);
  }
}
