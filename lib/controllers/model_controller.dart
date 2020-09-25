import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:mongoserver/mongoserver.dart';
import 'package:shelf/shelf.dart';
import 'package:mongoserver/utils/utils.dart';
import 'package:mongoserver/db/query.dart';

/// [ModelController] is capabale of handling all requests for [registered] models
/// Model Registration is by adding to a comma separated list of Models the server
/// is expected to handle through the Model Controller.
///
/// Each Model however can also extend ModelController, to get better handling of queries
/// or model specific logic. Invoke super class constructor passing context, request,
/// modelname and model's type map.
/// for example
///
/// class UserController extends ModelController {
/// UserController(Map<String, dynamic> context, request) :
///    super(context, request, model: 'user', modelTypeMap: User.typeMap);
/// }

class ModelController {
  final Request request;
  final context;
  List<String> models;
  final dynamic model;
  ModelController(this.context, this.request, {this.model})
      : models = context['config'].models.split(',') {
    context['model'] = model;
  }

  Future<Response> routeRequest() async {
    if (RegExp(r'.*\/.*').hasMatch(request.url.path)) {
      String collectionName = request.url.path.split('/').first;
      String id = request.url.path.split('/').last;
      return await get(collectionName, id);
    }
    return await routePath(request.url.path);
  }

  Future<Response> routePath(String path) async {
    if (!bearerAuthenticate(request)) {
      return Response(HttpStatus.unauthorized, body: 'You are not authorized');
    }

    final method = request.method.toUpperCase();
    final parts = path?.split('/') ?? null;

    String collectionName = model != null
        ? model.name
        : (parts != null
            ? models.firstWhere((element) => element == parts[0],
                orElse: () => null)
            : null);
    if (collectionName == null) {
      return returnError('$path not registered as a model');
    }

    if (method == 'GET') {
      return await get(collectionName, parts.length == 2 ? parts[1] : null);
    }
    if (method == 'POST') {
      return await post(collectionName, request);
    }
    if (method == 'PUT') {
      return await put(collectionName, request);
    }
    if (method == 'PATCH') {
      return await patch(collectionName, request);
    }
    return returnError('$method not supported');
  }

  Future<Response> get(String collectionName, String id) async {
    Response response;
    if (id != null) {
      final ObjectId oid = ObjectId.fromHexString(id);
      response = await Query(context, collectionName).findOne('_id', oid);
    } else {
      response = await Query(context, collectionName)
          .find(request.url.queryParameters);
    }

    return Response(response.statusCode,
        body: json.encode(await response.readAsString()));
  }

  Future<Response> post(String collectionName, Request request) async {
    final Map<String, dynamic> document =
        json.decode(await request.readAsString());
    return await Query(context, collectionName)
        .insert(document, id: model.primaryKey);
  }

  Future<Response> put(String collectionName, Request request) async {
    final Map<String, dynamic> document =
        json.decode(await request.readAsString());

    return await Query(context, collectionName).save(document);
  }

  Future<Response> patch(
    String collectionName,
    Request request,
  ) async {
    final Map<String, dynamic> document =
        json.decode(await request.readAsString());

    final _id = document['_id'];
    if (model != null) {
      document.removeWhere((key, value) =>
          model.noUpdate.contains(key) || !model.typeMap.containsKey(key));
    }
    return await Query(context, collectionName).update(
      document,
      request.url.hasQuery ? request.url.queryParameters : {'_id': _id},
      upsert:
          (request.url.queryParameters.remove('upsert') ?? 'false') == 'true',
      multiUpdate:
          (request.url.queryParameters.remove('multiUpdate') ?? 'false') ==
              'true',
    );
  }
}
