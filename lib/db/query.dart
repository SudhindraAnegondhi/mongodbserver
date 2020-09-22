import 'dart:convert';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:mongo_dart_query/mongo_dart_query.dart';
import 'package:mongoserver/mongoserver.dart';
import 'package:shelf/shelf.dart';
import 'package:mongoserver/utils/utils.dart';

enum OpCode {
  all, // expect fieldname, list values -> sb
  and, // expect selector builder (other) -> sb
  comment, // expect str, returns selectorbuilder (sb)
  eq, // expect fieldname, value -> sb
  excludeFields, // expect List<String> fields -> sb
  exists, // expect fieldname -> sb
  explain, // expect nothing -> sb
  fields, // expect List<String> fields -> sb
  getQueryString, // expect callback function -> string
  gt, // expect fieldname, value -> sb
  gte, // expect fieldname, value -> sb
  hint, // expect fieldname, bool (descending false) -> sb
  hintIndex, // expect indexname -> sb
  id, // objectid value -> sb,
  inRange, // expecct fieldname, min, max, bool mininclude (true), bool maxinclude (false) -> rb
  jsQuery, // expect javescript code -> sb
  limit, // expect int -> sb
  lt, // expect fieldname, value -> sb
  lte, // expect fieldname, value -> sb
  match, // expect fieldName, String pattern, {bool multiLine, bool caseInsensitive, bool dotAll, bool extended} → sb
  metaTextScore, // expect fieldname -> sb
  mod, // expect fieldname, int -> sb
  ne, // expect fieldname, value -> sb
  near, // expect  fieldName, dynamic value, [double maxDistance] -> sb
  nin, // expect fieldname, list values -> sb
  notExists, // expect fieldname -> sb
  oneFrom, // expect fieldname, list values -> sb
  or, // or filters -> sb
  raw, // map<string, dynamic> -> sb
  returnKey, // expect nothing -> sb
  showDiskLoc, // expect nothing -> sb
  skip, // expect int, -> sb
  snapshot, // expect nothing -> sb
  sortBy, // expect fieldname, bool descending false -> sb
  sortByMetaTextScore, // expect fieldname -> sb
  within, // expect fieldname, value -> sb

}

OpCode stringToOpCode(String value) {
  for (int i = 0; i < OpCode.values.length; i++) {
    if (value.toLowerCase() == describeEnum(OpCode.values[i]).toLowerCase()) {
      return OpCode.values[i];
    }
  }
  return null;
}

String describeEnum(Object enumEntry) {
  final String description = enumEntry.toString().replaceAll('_', '.');
  final int indexOfDot = description.indexOf('.');
  assert(indexOfDot != -1 && indexOfDot < description.length - 1);
  return description.substring(indexOfDot + 1);
}

class Query {
  final context;
  final String collectionName;
  String model;
  Map<String, dynamic> modelTypeMap;
  DbCollection dbCollection;
  Db db;
  Query(this.context, this.collectionName)
      : model = context['model'],
        modelTypeMap = context['modelTypeMap'] ?? {} {
    db = context['db'];
    dbCollection = db.collection(collectionName);
  }

  Future<void> open() async {
    await db.open();
  }

  Future<Response> insert(Map<String, dynamic> document, {String id}) async {
    try {
      if (id != null && document[id] != null) {
        // dart driver does not support user supplied ids
        // enforce unique id.
        final sb = selectorBuilder([
          {'opCode': OpCode.eq, 'fieldname': id, 'value': document[id]},
        ]);

        final found = await dbCollection.findOne(sb);
        if (found != null) {
          return Response(HttpStatus.conflict,
              body: '$id: ${document[id]} already exists');
        }
      }

      final response = await dbCollection.insert(document);
      if (response['ok'] == 1.0)
        return Response.ok("inserted");
      else
        return Response(HttpStatus.conflict, body: 'error: insert failed');
    } catch (e) {
      return returnError(e.message);
    }
  }

  Future<Response> findOne(String key, dynamic value) async {
    final sb = selectorBuilder([
      {'opCode': OpCode.eq, 'fieldname': key, 'value': value},
    ]);

    final found = await dbCollection.findOne(sb);
    if (found != null) {
      return Response(HttpStatus.ok, body: json.encode(found));
    }
    return Response.notFound('$key not found');
  }

  Future<Response> find(Map<String, String> queryParameters) async {
    SelectorBuilder sb;
    if (queryParameters != null) {
      sb = _buildQuery(queryParameters);
      if (sb == null) {
        return returnError('Error in parameters, please check server logs');
      }
    }

    final found = await dbCollection.find(sb == null ? null : sb);
    if (found != null) {
      final List<Map<String, dynamic>> records = [];
      await found.forEach((element) {
        records.add(element);
      });
      return Response(HttpStatus.ok, body: json.encode(records));
    }
    return Response.notFound('No records found');
  }

  Future<void> close() async {
    if (db == null) {
      return;
    }
    await db.close();
  }

  /// query parameters:
  ///
  SelectorBuilder _buildQuery(Map<String, String> queryParameters) {
    List<Map<String, String>> groupQueries = [];
    List<String> logicalOperator = [];
    final keys = queryParameters.keys.toList();
    Map<String, String> parameters = {};
    keys.forEach((key) {
      if (key.toLowerCase() == 'or' || key.toLowerCase() == 'and') {
        if (parameters.length > 0) {
          groupQueries.add(parameters);
        }
        parameters = {};
        logicalOperator.add(key.toLowerCase());
      } else {
        parameters[key] = queryParameters[key];
      }
    });
    if (parameters.length > 0) groupQueries.add(parameters);
    //
    List<SelectorBuilder> sbs = [];
    for (int i = 0; i < groupQueries.length; i++) {
      final filters = _buildFilters(groupQueries[i]);
      if (filters is String) {
        print(filters);
        return null;
      }
      sbs.add(selectorBuilder(filters));
    }
    final sb = sbs[0];
    if (sbs.length > 1) {
      for (int i = 1; i < sbs.length; i++) {
        if (logicalOperator[i - 1] == 'or')
          sb.or(sbs[i]);
        else
          sb.and(sbs[i]);
      }
    }
    return sb;
  }

  dynamic _buildFilters(Map<String, String> parameters) {
    List<Map<String, dynamic>> filters = [];
    String error;
    parameters.forEach((String key, value) {
      if (error == null) {
        final List<String> keys = key.split('.');
        String fieldname =
            ['or', 'and'].contains(keys[0].toLowerCase()) ? null : keys[0];
        String indexname;
        String min;
        String max;
        String
            code; // = keys.length == 1 && (code == 'or' || code == 'and') ? key ?
        if (keys.length == 1) {
          if (key == 'or' || key == 'and') {
            code = key;
          }
        } else {
          code = keys[1];
        }

        final opCode = code != null ? stringToOpCode(code) : OpCode.eq;
        if (opCode == null) {
          //return returnError('${key.split('.')[1]} is not a filter opCode');
          error = '$key is not a filter opCode';
        }
        dynamic typedValue;
        switch (opCode) {
          case OpCode.excludeFields:
          case OpCode.fields:
          case OpCode.nin:
          case OpCode.oneFrom:
            // list is implemented as comma separated values
            typedValue = value.split(',');
            break;
          case OpCode.or:
            fieldname = null;
            break;
          case OpCode.raw:
            error = 'OpCode.Or not yet implemented from ModelController';
            break;
          case OpCode.exists:
          case OpCode.hint:
          case OpCode.metaTextScore:
          case OpCode.notExists:
          case OpCode.sortBy:
          case OpCode.sortByMetaTextScore:
            // no value
            break;
          case OpCode.explain:
          case OpCode.getQueryString:
          case OpCode.returnKey:
          case OpCode.showDiskLoc:
          case OpCode.snapshot:
            fieldname = null;
            // no field name,value
            break;
          case OpCode.jsQuery:
          case OpCode.limit:
          case OpCode.skip:
            fieldname = null;
            typedValue = value;
            break;
          case OpCode.hintIndex:
            fieldname = null;
            indexname = value;
            break;
          case OpCode.id:
            fieldname = '_id';
            typedValue = ObjectId.fromHexString(value);
            break;
          case OpCode.inRange:
            final values = value.split(',');
            if (values.length != 2) {
              error += '$key should have min,max values';
              break;
            }
            min = modelTypeMap == null
                ? _guessType(values[0])
                : _typedValue(fieldname, values[0]);
            max = modelTypeMap == null
                ? _guessType(values[1])
                : _typedValue(fieldname, values[1]);
            break;
          default:
            if (value != null) {
              if (modelTypeMap[fieldname] != null) {
                typedValue = _typedValue(fieldname, value);
              } else {
                typedValue = _guessType(value);
              }
            }
        }
        filters.add({
          'fieldname': fieldname,
          'opCode': opCode,
          'value': typedValue,
          'indexname': indexname,
          'min': min,
          'max': max,
        });
      }
    });
    return error == null ? filters : error;
  }

  dynamic _guessType(dynamic value) {
    if (['true', 'false'].contains(value)) {
      return value == 'true';
    } else if (RegExp(r'\d').hasMatch(value)) {
      return intTryParse(value);
    } else if (RegExp(r'\d+\.\d+').hasMatch(value)) {
      return doubleTryParse(value);
    } else if (RegExp(r'\d[4]\-\dd\-\dd').hasMatch(value)) {
      return DateTime.parse(value);
    }
    return value; // most probably String
  }

  dynamic _typedValue(String fieldname, dynamic value) {
    if (modelTypeMap.containsKey(fieldname)) {
      switch (modelTypeMap[fieldname]) {
        case 'bool':
          return value == 'true';
        case 'int':
          return intTryParse(value);
        case 'double':
          return doubleTryParse(value);
        case 'date':
          return DateTime.parse(value);
      }
    }
    return value;
  }

  SelectorBuilder selectorBuilder(List<Map<String, dynamic>> filters) {
    if (filters == null || !(filters is List)) {
      return null;
    }
    SelectorBuilder sb = SelectorBuilder();
    for (final filter in filters) {
      final opCode = filter['opCode'] as OpCode;
      final fieldName = filter['fieldname'] as String;
      final value = filter['value'] as dynamic;
      switch (opCode) {
        case OpCode.all:
          sb = sb.all(fieldName, value as List);
          break;
        case OpCode.and:
          sb = sb.and(value as SelectorBuilder);
          break;
        case OpCode.comment:
          sb = sb.comment(value as String);
          break;
        case OpCode.eq:
          sb = sb.eq(fieldName, value);
          break;
        case OpCode.excludeFields:
          sb = sb.excludeFields(value as List<String>);
          break;
        case OpCode.exists:
          sb = sb.exists(fieldName);
          break;
        case OpCode.explain:
          sb = sb.explain();
          break;
        case OpCode.fields:
          sb = sb.fields(value as List<String>);
          break;
        case OpCode.getQueryString:
          value(sb.getQueryString());
          break;
        case OpCode.gt:
          sb = sb.gt(fieldName, value);
          break;
        case OpCode.gte:
          sb = sb.gte(fieldName, value);
          break;
        case OpCode.hint:
          sb = sb.hint(fieldName);
          break;
        case OpCode.hintIndex:
          sb = sb.hintIndex(filter['indexname']);
          break;
        case OpCode.id:
          sb = sb.id(value);
          break;
        case OpCode.inRange:
          sb = sb.inRange(fieldName, filter['min'], filter['max']);
          break;
        case OpCode.jsQuery:
          sb = sb.jsQuery(value);
          break;
        case OpCode.limit:
          sb = sb.limit(value);
          break;
        case OpCode.lt:
          sb = sb.lt(fieldName, value);
          break;
        case OpCode.lte:
          sb = sb.lte(fieldName, value);
          break;
        case OpCode.match:
          sb = sb.match(fieldName, value as String);
          break;
        case OpCode.metaTextScore:
          sb = sb.metaTextScore(fieldName);
          break;
        case OpCode.mod:
          sb = sb.mod(fieldName, value);
          break;
        case OpCode.ne:
          sb = sb.ne(fieldName, value);
          break;
        case OpCode.near:
          sb = sb.ne(fieldName, value);
          break;
        case OpCode.nin:
          sb = sb.nin(fieldName, value as List);
          break;
        case OpCode.notExists:
          sb = sb.notExists(fieldName);
          break;
        case OpCode.oneFrom:
          sb = sb.oneFrom(fieldName, value as List);
          break;
        case OpCode.or:
          sb = sb.or(selectorBuilder(value as List<Map<String, dynamic>>));
          break;
        case OpCode.raw:
          sb = sb.raw(value as Map<String, dynamic>);
          break;
        case OpCode.returnKey:
          sb = sb.returnKey();
          break;
        case OpCode.showDiskLoc:
          sb = sb.showDiskLoc();
          break;
        case OpCode.skip:
          sb = sb.skip(value as int);
          break;
        case OpCode.snapshot:
          sb = sb.snapshot();
          break;
        case OpCode.sortBy:
          sb.sortBy(fieldName);
          break;
        case OpCode.sortByMetaTextScore:
          sb.sortByMetaTextScore(fieldName);
          break;
        case OpCode.within:
          sb = sb.within(fieldName, value);
          break;
      }
    }
    return sb;
  }
}
