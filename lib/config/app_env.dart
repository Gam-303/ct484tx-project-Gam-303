import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppEnv {
  const AppEnv._();

  static String get pocketBaseUrl {
    final raw = dotenv.env['POCKETBASE_URL']?.trim();
    if (raw == null || raw.isEmpty) {
      return 'http://192.168.1.10:8090';
    }
    return raw;
  }
}
