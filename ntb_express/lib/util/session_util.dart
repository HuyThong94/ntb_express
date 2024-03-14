import 'package:ntbexpress/model/user.dart';
import 'package:ntbexpress/util/utils.dart';

class SessionUtil {
  SessionUtil._();

  static late SessionUtil _instance;

  static SessionUtil instance() {
    if (_instance != null) return _instance;

    _instance = SessionUtil._();
    return _instance;
  }

  late User user;
  late String fcmToken;
  late String authToken;
  late String deviceId;
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
