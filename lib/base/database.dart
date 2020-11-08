import 'package:mongo_dart/mongo_dart.dart';
import 'package:mongoserver/base/app_configuration.dart';

class Database {
  final AppConfiguration config;
  Db db;
  Database(this.config);

  Future<Db> open() async {
    if (db == null) {
      /* final connectionString =
          'mongodb://${config.database.username}:${config.database.password}@${config.database.host}/${config.database.databaseName}?authSource=admin';*/
      try {
        db =
            Db("mongodb://spinserver:0880@localhost/spincent?authSource=admin");
        await db.open();
      } catch (e) {
        print(e.toString());
        rethrow;
      }
    }
    return db;
  }

  Future<bool> exists(String collection) async {
    final collections = await db.getCollectionNames();
    return collections.contains(collection);
  }

  Future<void> close() async {
    if (db == null) {
      return;
    }
    await db.close();
  }

  Future<bool> authenticate(
    String userName,
    String password,
  ) async =>
      await db.authenticate(userName, password);

  DbCollection collection(String collectionName) =>
      db.collection(collectionName);

  Future<Map<String, dynamic>> createIndex(String collectionName,
          {String key,
          Map<String, dynamic> keys,
          bool unique,
          bool sparse,
          bool background,
          bool dropDups,
          Map<String, dynamic> partialFilterExpression,
          String name}) async =>
      db.createIndex(
        collectionName,
        key: key,
        keys: keys,
        unique: unique,
        sparse: sparse,
        background: background,
        dropDups: dropDups,
        partialFilterExpression: partialFilterExpression,
        name: name,
      );

  Future drop() async => await db.drop();

  Future<bool> dropCollection(String collectionName) async =>
      db.dropCollection(collectionName);

  Future ensureIndex(String collectionName,
          {String key,
          Map<String, dynamic> keys,
          bool unique,
          bool sparse,
          bool background,
          bool dropDups,
          Map<String, dynamic> partialFilterExpression,
          String name}) async =>
      await db.ensureIndex(
        collectionName,
        key: key,
        keys: keys,
        unique: unique,
        sparse: sparse,
        background: background,
        dropDups: dropDups,
        partialFilterExpression: partialFilterExpression,
        name: name,
      );

  Future<Map<String, dynamic>> executeDbCommand(MongoMessage message) async =>
      await db.executeDbCommand(message);

  void executeMessage(
    MongoMessage message,
    WriteConcern writeConcern,
  ) =>
      db.executeMessage(message, writeConcern);
}
