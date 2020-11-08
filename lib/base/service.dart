import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:mongoserver/controllers/admin_controller.dart';
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

  Handler get withLog =>
      Pipeline().addMiddleware(logRequests()).addHandler(handler);

  Handler get handler => appRoutes;

  Handler get appRoutes {
    final router = Router();

    router.all('/register', (Request request) async {
      if (request.method != 'POST') {
        return returnError('Register requests must be POSTed');
      }
      return await RegisterController(context, request).createUser();
    });

    router.all('/auth/token', (Request request) async {
      if (request.method != 'POST') {
        return returnError('Auth requests must be POSTed');
      }
      return await AuthController(context, request).login();
    });

    router.all('/allow/<model>', (Request request, String model) {
      if (request.method != 'POST') {
        return returnError('Allow requests must be POSTed');
      }
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
        return Response(HttpStatus.unauthorized, body: 'Not Authorized');
      }
      return await ModelController(
        context,
        request,
        model: User(),
      ).routeRequest();
    });

    router.all('/admin/<action|.*>', (Request request, String action) async {
      if (action == null) {
        return Response.notFound('that request is not found');
      }
      // allow only admins
      if (!bearerAuthenticate(request, isAdmin: true)) {
        return Response(HttpStatus.unauthorized, body: 'Not Authorized');
      }
      return await AdminController(context, request).routeRequest();
    });

    router.all('/<path|.*>', (Request request, String path) async {
      return await ModelController(context, request).routeRequest();
    });

    return router.handler;
  }
}
