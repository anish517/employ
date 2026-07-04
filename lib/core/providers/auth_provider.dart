import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';

final authServiceProvider = Provider((ref) => AuthService());
final authLoadingNotifierProvider = Provider(
  (ref) => ValueNotifier<bool>(false),
);
