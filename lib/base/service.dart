import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:mongoserver/controllers/auth_controller.dart';
import 'package:mongoserver/controllers/model_controller.dart';
import 'package:mongoserver/controllers/register_controller.dart';
import 'package:mongoserver/controllers/user_controller.dart';

class Service {
  // The [Router] can be used to create a handler, which can be used with
  // [shelf_io.serve].
  final context;

  Service(this.context);

  Handler get handler {
    final router = Router();

    router.post('/register', (Request request) async {
      return await RegisterController(context, request).createUser();
    });

    router.post('/auth/token', (Request request) async {
      return await AuthController(context, request).login();
    });

    router.post('/user/<id>', (Request request, String id )async {
      return await UserController(context, request).route(id);
    });

    router.all('/<path|.*>', (Request request, String path) async {
      return await ModelController(context, request).route(path);
    });
    // Embedded URL parameters may also be associated with a regular-expression
    // that the pattern must match.
    router.get('/user/<userId|[0-9]+>', (Request request, String userId) {
      return Response.ok('User has the user-number: $userId');
    });

    // Handlers can be asynchronous (returning `FutureOr` is also allowed).
    router.get('/wave', (Request request) async {
      await Future.delayed(Duration(milliseconds: 100));
      return Response.ok('_o/');
    });

    // Other routers can be mounted...
    //router.mount('/api/', Api().router);

    // You can catch all verbs and use a URL-parameter with a regular expression
    // that matches everything to catch app.
    router.all('/<ignored|.*>', (Request request) {
      return Response.notFound('Page not found');
    });

    return router.handler;
  }
}
