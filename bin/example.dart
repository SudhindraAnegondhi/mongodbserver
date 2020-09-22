import 'package:mongo_dart/mongo_dart.dart';

void main() async {
  
  var db =
      // Db("mongodb://reader:vHm459fU@ds037468.mongolab.com:37468/samlple");
      Db("mongodb://spinserver:0880@localhost/spincent?authSource=admin");
  var test = db.collection('test');
  await db.open();

  await test
      .find(where.eq('item',
              'test') /*
        .inRange('pop', 14000, 16000).sortBy(
            'pop',
            descending: true,
          ),*/
          )
      .forEach((Map r) {
    print(r['item']);
  });
  print('closing db');
  await db.close();
}
