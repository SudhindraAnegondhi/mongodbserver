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
  final String model;
  ModelController(this.context, this.request,
      {this.model, Map<String, dynamic> modelTypeMap})
      : models = context['config'].models.split(',') {
    context['model'] = model;
    context['modelTypeMap'] = modelTypeMap;
  }

  Future<Response> route(String path) async {
    if (!bearerAuthenticate(request)) {
      return Response(HttpStatus.unauthorized, body: 'You are not authorized');
    }

    final method = request.method.toUpperCase();
    final parts = path?.split('/') ?? null;

    String collectionName = model != null
        ? model
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
    return returnError('$method not supported');
  }

  Future<Response> get(String collection, String id) async {
    Response response;
    if (id != null) {
      final ObjectId oid = ObjectId.fromHexString(id);
      response = await Query(context, collection).findOne('_id', oid);
    } else {
      response =
          await Query(context, collection).find(request.url.queryParameters);
    }

    return Response(response.statusCode,
        body: json.encode(await response.readAsString()));
  }
}
