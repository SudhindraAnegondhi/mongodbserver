import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:mongoserver/controllers/auth_controller.dart';
import 'package:mongoserver/controllers/model_controller.dart';
import 'package:mongoserver/controllers/register_controller.dart';
import 'package:mongoserver/models/user.dart';
import 'package:mongoserver/utils/utils.dart';

class Service {
  // The [Router] can be used to create a handler, which can be used with
  // [shelf_io.serve].
  final context;
  final Function modifyContext;
  Service(this.context, this.modifyContext);

  Handler get handler {
    final router = Router();

    router.post('/register', (Request request) async {
      return await RegisterController(context, request).createUser();
    });

    router.post('/auth/token', (Request request) async {
      return await AuthController(context, request).login();
    });

    router.post('/allow/<model>', (Request request, String model) {
      if (!bearerAuthenticate(request, isAdmin: true)) {
        return Response(HttpStatus.unauthorized,
            body: 'You are not authorized');
      }
      final List<String> models = context['config'].models.split(',');
      if (models.indexWhere((element) => element == model) == -1) {
        context['config'].models += ',$model';
        modifyContext('config', 'model', model);
        return Response.ok('$model is allowed until service restarts.');
      }
      return Response.ok('$model is already registered');
    });

    router.get('/user/<id>', (Request request, String path) async {
      return await ModelController(context, request, model: User())
          .routeRequest();
    });

    router.all('/user', (Request request) async {
      // allow only admins
      if (!bearerAuthenticate(request, isAdmin: true)) {
        return Response(HttpStatus.unauthorized,
            body: 'You lack privileges to access User');
      }
      return await ModelController(context, request, model: User())
          .routeRequest();
    });

    router.all('/<path|.*>', (Request request, String path) async {
      return await ModelController(context, request).routeRequest();
    });

    return router.handler;
  }
}
