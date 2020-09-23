import 'package:shelf/shelf.dart';
import 'package:mongoserver/models/user.dart';
import 'package:mongoserver/controllers/model_controller.dart';

class UserController extends ModelController {
  final Request request;
  UserController(Map<String, dynamic> context, this.request)
      : super(context, request, model: User());

  @override
  Future<Response> routePath(String id) async {
    String method = request.method;
    if (method == 'Get') {
      return await super.get('user', id);
    }
    return await super.routePath(request.url.path);
  }
}
