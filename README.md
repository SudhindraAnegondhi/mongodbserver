# Mungsi*

## MongoDb Object Retrieval for Dart & Flutter

***Mungsi*** Kannada - The etymological ancestor to Mongoose, allows Dart and Flutter applications to use MongoDB databases to read, write and validate data easily.

**Mungsi** allows operations only on *registered* models. A registered model can either be just the name of the collection - in which case, Mungsi does not enforce any structure on the data inserted or the model can be added to mongoserver by the dbAdmin allowing Mungsi to enforce the type and names of the data elements inserted or updated.

**Mungsi** has two componnents:

- mongoserver, is as the name implies the database server, and
- mongoclient, a Dart client library that can be called by client applications.

```dart
import 'package:mongocloent/mongoclient.dart';

MongoClient db = MongoClient(configuration: {  "serverAddress": "localhost:8888",
    "authSecret": "mySecret",
    "useTSL": true,
});

final final Map<String, dynamic> response = await authenticate(
  'johndoe@deers.com',
   'antler',
   AuthAction.signUpWithPassword,
);

String collectionName = "widgets";
String key= "productId";
int productId = 4537865690;
final ClientResponse response =await db.findOne(collectionName,
key,
productId
);
Widget widget = Widget.fromMap(response.body);
widget.qtySold -= 1;

final ClientResponse response = await db.save(collectionName, widget.toMap());


```

Mungsi supports the following database operations:

I. Database Retrieval and Storage

1. Multiple databases.
2. CRUD operations.
3. Query multiple conditions including logical AND and OR operations.
4. Joining collections - outer joins.
5. Aggregate operations.

II. Database Administration

1. Register models.
2. Temporary registration of models by a privileged client request.
3. Create Indexes 


