import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import '../exceptions/app_exceptions.dart';

class ExceptionHandler {
  static AppException handle(dynamic error) {
    if (error is FirebaseException) {
      if (error.code == 'permission-denied') {
        return PermissionException('ليس لديك صلاحية للوصول إلى هذه البيانات.');
      }
      if (error.code == 'unavailable') {
        return NetworkException('لا يوجد اتصال بالإنترنت.');
      }
      return FirestoreException(
        error.message ?? 'حدث خطأ غير معروف في قاعدة البيانات.',
      );
    }

    if (error is FirebaseAuthException) {
      return PermissionException(error.message ?? 'حدث خطأ في المصادقة.');
    }

    if (error.toString().contains('SocketException')) {
      return NetworkException('لا يوجد اتصال بالشبكة.');
    }

    if (error is TimeoutException) {
      return NetworkException('انتهى وقت الاتصال.');
    }

    if (error is PlatformException) {
      return RepositoryException(error.message ?? 'حدث خطأ في النظام.');
    }

    if (error is AppException) {
      return error;
    }

    return RepositoryException('حدث خطأ غير متوقع: $error');
  }
}
