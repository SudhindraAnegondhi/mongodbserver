import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:mongoserver/controllers/auth_controller.dart';
import 'package:mongoserver/controllers/model_controller.dart';
import 'package:mongoserver/controllers/register_controller.dart';
import 'package:mongoserver/models/user.dart';

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

    router.get('/user/<id>', (Request request, String path) async {
      return await ModelController(context, request, model: User()).routeRequest();
    });
    
    router.all('/user', (Request request) async {
      return await ModelController(context, request, model: User())
          .routeRequest();
    });

    router.all('/<path|.*>', (Request request, String path) async {
      return await ModelController(context, request).routeRequest();
    });

    return router.handler;
  }
}
