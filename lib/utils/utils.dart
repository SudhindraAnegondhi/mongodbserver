import 'dart:convert';
import 'package:mongoserver/mongoserver.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:crypto/crypto.dart';
import 'package:password_hash/password_hash.dart';
import 'package:shelf/shelf.dart';

Response returnError(String error, {int statusCode = HttpStatus.badRequest}) =>
    Response(statusCode, body: json.encode({'error': error}));

/// A utility method to generate a password hash using the PBKDF2 scheme.
///
///
String generatePasswordHash(String password, String salt,
    {int hashRounds = 1000, int hashLength = 32, Hash hashFunction}) {
  final generator = PBKDF2(hashAlgorithm: hashFunction ?? sha256);
  return generator.generateBase64Key(password, salt, hashRounds, hashLength);
}

/// A utility method to generate a random base64 salt.
///
///
String generateRandomSalt({int hashLength = 32}) {
  return Salt.generateAsBase64String(hashLength);
}

/// Hashes a [password] with [salt] using PBKDF2 algorithm.
///
/// See [hashRounds], [hashLength] and [hashFunction] for more details. This method
/// invoke [generatePasswordHash] with the above inputs.
String hashPassword(String password, String salt) {
  return generatePasswordHash(password, salt);
}

/// generates & returns JWT token
const _hmacKey = 'FewPeopleFindUseForWithoutTheProperLock';
const _issuer = 'inspironsudhindra';
const _audienceDomain = 'clients.spincent.com';

String jwtToken() {
  final claimSet = JwtClaim(
    subject: 'drtmgdbsrvr',
    issuer: '$_issuer',
    audience: <String>[_audienceDomain],
    expiry: DateTime.now().add(Duration(hours: 24)),
    issuedAt: DateTime.now(),
  );

  return issueJwtHS256(claimSet, _hmacKey);
}

bool validateJwtToken(String token) {
  try {
    final JwtClaim declaimSet = verifyJwtHS256Signature(token, _hmacKey);
    declaimSet.validate(
        issuer: _issuer, audience: _audienceDomain);
    return true;
  } on JwtException {
    return false;
  }
}

bool bearerAuthenticate(Request request,) {
  final headers = request.headers;
  if (headers['Authorization'] == null) {
    return false;
  }
  final tokens = headers['Authorization'].split(' ');
  if (tokens == null || tokens.length != 2 || tokens[0] != 'Bearer') {
    return false;
  }
  return validateJwtToken(tokens[1]);
}

///
/// returns integer value of argument passed.
/// returns double if value is double
/// Can be coerced to a double by passing double as type
///
dynamic intTryParse(dynamic value, [String type]) {
  if (value == null) return 0;
  if (type != null && type == 'double') return doubleTryParse(value);
  return value.runtimeType.toString() == 'String'
      ? int.tryParse(value.replaceAll(',', ''))
      : value;
}

///
/// returns double value of argument passed.
/// returns integer if value is integer
/// Can be coerced to a integer by passing int as type
///
dynamic doubleTryParse(dynamic value, [String type]) {
  if (value == null) return 0.0;
  if (type != null && type == 'int') return intTryParse(value);
  var val = value.runtimeType.toString() == 'String' && !value.contains('.')
      ? value + '.0'
      : value;
  return val.runtimeType.toString() == 'String'
      ? double.tryParse(val.replaceAll(',', ''))
      : val;
}

///
/// converts doubles, ints, date  string values
/// to correct dart types

dynamic stringToValue(String type, String val) {
  switch (type) {
    case 'double':
      return doubleTryParse(val);
    case 'int':
      return intTryParse(val);
    case 'date':
      return DateTime.parse(val);
  }
  return val;
}
