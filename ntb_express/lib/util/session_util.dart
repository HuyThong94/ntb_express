import 'package:ntbexpress/model/user.dart';
import 'package:ntbexpress/util/utils.dart';

class SessionUtil {
  SessionUtil._();

  static SessionUtil _instance;

  static SessionUtil instance() {
    if (_instance != null) return _instance;

    _instance = SessionUtil._();
    return _instance;
  }

  User user;
  String fcmToken;
  String authToken;
  String deviceId;
  double exchangeRate = 3400;
  int canPop = 0;

  void reset() {
    _instance = SessionUtil._();
  }

  bool isLoggedIn() {
    if (user == null ||
        Utils.isNullOrEmpty(fcmToken) ||
        Utils.isNullOrEmpty(authToken)) return false;

    return true;
  }

  @override
  String toString() {
    return 'SessionUtil{user: $user, fcmToken: $fcmToken, authToken: $authToken, deviceId: $deviceId}';
  }
}
