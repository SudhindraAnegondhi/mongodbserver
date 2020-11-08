import 'dart:convert';
import 'package:mongoserver/mongoserver.dart';
import 'package:shelf/shelf.dart';
import 'package:mongoserver/utils/utils.dart';
import 'package:mongoserver/db/query.dart';

class AdminController {
  final context;
  final Request request;

  AdminController(this.context, this.request);

  Future<Response> routeRequest() async {
    if (!bearerAuthenticate(request)) {
      return Response(HttpStatus.unauthorized, body: 'You are not authorized');
    }
    final action = request.url.pathSegments[1].toLowerCase();
    final method = request.method.toUpperCase();
    final model = request.url.pathSegments.length == 3
        ? request.url.pathSegments[2]
        : null;

    switch (action) {
      case 'createindex':
        if (method == 'POST') {
          if (model != null) {
            return await createIndex(request, model);
          }
          Response(HttpStatus.badRequest, body: 'Wrong request method');
        }
        return Response(HttpStatus.badRequest, body: 'Collection required');
      case 'exists':
        if (method == 'GET') {
          if (model != null) {
            return await exists(request, model);
          }
          Response(HttpStatus.badRequest, body: 'Wrong request method');
        }

        return Response(HttpStatus.badRequest, body: 'Wrong request method');
      case 'schema':
        if (method == 'GET') {
          return await schema(request);
        }
        return Response(HttpStatus.badRequest, body: 'Wrong request method');
    }
    return Response.notFound('$action not found');
  }

  Future<Response> createIndex(Request request, String collection) async {
    final index = json.decode(await request.readAsString());
    return await Query(context, collection).createIndex(index);
  }

  Future<Response> exists(Request request, String model) async {
    final bool doesExist = await Query(context, model).collectionExists();
    return Response(
      doesExist ? HttpStatus.found : HttpStatus.notFound,
    );
  }

  Future<Response> schema(Request request) async {
    return null;
  }
}
