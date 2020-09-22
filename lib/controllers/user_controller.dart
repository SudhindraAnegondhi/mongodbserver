import 'package:shelf/shelf.dart';
import 'package:mongoserver/models/user.dart';
import 'package:mongoserver/controllers/model_controller.dart';

class UserController extends ModelController {
  final Request request;
  UserController(Map<String, dynamic> context, this.request)
      : super(context, request, model: 'user', modelTypeMap: User.typeMap);

  @override
  Future<Response> route(String id) async {
    String method = request.method;
    if (method == 'Get') {
      return await super.get('user', id);
    }
    return await super.route(request.url.path);
  }
}
