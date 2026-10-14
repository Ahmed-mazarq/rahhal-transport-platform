abstract class AppException implements Exception {
  final String message;
  AppException(this.message);
  @override
  String toString() => message;
}

class RepositoryException extends AppException {
  RepositoryException(super.message);
}

class FirestoreException extends AppException {
  FirestoreException(super.message);
}

class NetworkException extends AppException {
  NetworkException(super.message);
}

class PermissionException extends AppException {
  PermissionException(super.message);
}

class ParsingException extends AppException {
  ParsingException(super.message);
}
