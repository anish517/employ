import 'package:flutter/foundation.dart';

const String _androidEmulatorUrl = 'http://10.0.2.2:5000/api';
const String _webUrl = 'http://localhost:5000/api';

// Automatically select the correct URL based on platform
final String apiBaseUrl = kIsWeb 
  ? _webUrl 
  : (const String.fromEnvironment('API_BASE_URL', defaultValue: _androidEmulatorUrl));

