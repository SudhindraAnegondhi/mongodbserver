import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:mongoserver/mongoserver.dart';
import 'package:shelf/shelf.dart';
import 'package:mongoserver/base/model_register.dart';
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
  dynamic model;
  final Map<String, dynamic> modelSchema = {};
  ModelController(this.context, this.request, {this.model})
      : models = context['config'].models.split(',') {
    context['model'] = model;
  }

  Future<Response> routeRequest() async {
    if (!bearerAuthenticate(request)) {
      return Response(HttpStatus.unauthorized, body: 'You are not authorized');
    }

    final method = request.method.toUpperCase();
    final parts = request.url.pathSegments; //path?.split('/') ?? null;
    model = model ?? ModelRegister().instance(parts[0]);
    String collectionName = model != null
        ? model.name
        : (parts != null
            ? models.firstWhere((element) => element == parts[0],
                orElse: () => null)
            : null);

    if (model != null) {
      modelSchema['name'] = collectionName;
      modelSchema['fields'] = model.toMap();
      modelSchema['types'] = model.typeMap();
    }
    if (collectionName == null) {
      return returnError('${request.url.path} not found');
    }

    if (method == 'GET') {
      ObjectId id;
      if (parts.length == 2) {
        try {
          id = ObjectId.fromHexString(parts[1]);
        } catch (e) {}
      }
      return await get(collectionName, id);
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
    if (method == 'DELETE') {
      return await delete(collectionName, request);
    }
    return returnError('$method not supported');
  }

  Future<Response> delete(String collectionName, Request request) async {
    if (request.url.queryParameters.isEmpty) {
      return returnError('Delete requires document identification');
    }
    return await Query(context, collectionName)
        .delete(request.url.queryParameters);
  }

  Future<Response> get(String collectionName, [ObjectId id]) async {
    Response response;

    if (id != null) {
      response = await Query(context, collectionName).findOne('_id', id);
    } else {
      response = await Query(context, collectionName)
          .find(request.url.queryParameters);
    }
    if (modelSchema.isEmpty && response.statusCode == HttpStatus.ok) {
      final body = json.decode(await response.readAsString());
      fillupSchema(collectionName, body is List ? body[0] : body);
    }

    return Response(response.statusCode, body: await response.readAsString());
  }

  /// Creates a validation schema from document
  /// required when a model is not registered with the server but just allowed
  void fillupSchema(String model, Map<String, dynamic> document) {
    modelSchema['name'] = model;
    modelSchema['fields'] = document;
    modelSchema['types'] =
        document.map((k, v) => MapEntry(k, v.runtimeType.toString()));
  }

  Future<Response> post(String collectionName, Request request) async {
    final body = await request.readAsString();
    var documents;
    try {
      documents = json.decode(body);
    } on FormatException catch (e) {
      return returnError(e.toString(), statusCode: HttpStatus.badRequest);
    }
    if (modelSchema.isEmpty) {
      fillupSchema(model, documents is List ? documents[0] : documents);
    }
    if (modelSchema != null) {
      final document = Map<String, dynamic>.from(
          documents is List ? documents[0] : documents);
      document.removeWhere((k, v) => k == '_id');
      List documentKeys = document.keys.toList();
      documentKeys.sort((a, b) => a.compareTo(b));
      final modelKeys = List.from(modelSchema['fields'].keys.toList());
      modelKeys.sort((a, b) => a.compareTo(b));
      if (modelKeys.length != documentKeys.length) {
        return returnError('Save document structure is not same as model');
      }
      for (int i = 0; i < modelKeys.length; i++) {
        if (modelKeys[i] != documentKeys[i]) {
          return returnError('Save document structure is not same as model');
        }
      }
    }
    if (documents is List) {
      return await Query(context, collectionName).insertAll(
          documents.map((doc) => Map<String, dynamic>.from(doc)).toList());
    }
    return await Query(context, collectionName)
        .insert(documents, id: model?.primaryKey);
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
          (request.url.queryParameters.remove('multiupdate') ?? 'false') ==
              'true',
    );
  }
}
