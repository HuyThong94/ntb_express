import 'dart:convert';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ntbexpress/model/device_info.dart';
import 'package:ntbexpress/model/user.dart';
import 'package:ntbexpress/screens/forgot_password_screen.dart';
import 'package:ntbexpress/screens/price_calculation_screen.dart';
import 'package:ntbexpress/screens/register_screen.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/http_util.dart';
import 'package:ntbexpress/util/session_util.dart';
import 'package:ntbexpress/util/utils.dart';
import 'package:ntbexpress/widgets/app_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ReceivedNotification {
  final int? id;
  final String? title;
  final String? body;
  final String? payload;

  ReceivedNotification({
    this.id,
    this.title,
    this.body,
    this.payload,
  });
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginFormKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _spacing = 10.0;
  bool _rememberMe = false;
  bool _loading = false;
  bool _initialized = false;
  String _locale = 'vi';
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  bool _appLocaleIsChanged = false;

  @override
  void initState() {
    super.initState();
    _getDeviceId()
        .then((deviceId) => SessionUtil.instance().deviceId = deviceId!);
  }

  Future<void> _getPreferencesData() async {
    var prefs = await SharedPreferences.getInstance();
    await prefs.setBool(PrefsKey.logged, false);
    _rememberMe = prefs.getBool(PrefsKey.remember) ?? false;
    _usernameController.text =
        _rememberMe ? prefs.getString(PrefsKey.username)! : '';
    _passwordController.text =
        _rememberMe ? prefs.getString(PrefsKey.password)! : '';
    _locale = prefs.getString(PrefsKey.languageCode) ??
        await Utils.getCurrentLocale();

    if (_locale.contains('-'))
      _locale = _locale.split('-')[0];
    else if (_locale.contains('_')) _locale = _locale.split('_')[0];
    AppProvider.of(context)?.state.localeBloc.setLocale(Locale(_locale));
    setState(() {});
  }

  @override
  void dispose() {
    _usernameController?.dispose();
    _passwordController?.dispose();
    _usernameFocusNode?.dispose();
    _passwordFocusNode?.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_appLocaleIsChanged) {
      AppProvider.of(context)?.state.localeBloc.setLocale(Locale(_locale));
      _appLocaleIsChanged = true;
    }

    Locale? locale = AppProvider.of(context)?.state?.localeBloc?.currentLocale;
    if (locale != null && locale.languageCode != _locale) {
      if (mounted) {
        setState(() => _locale = locale.languageCode);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _getPreferencesData();
      _initialized = true;
    }

    return Scaffold(
      resizeToAvoidBottomInset: false,
      key: _scaffoldKey,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 40.0),
          //color: Utils.primaryColor,
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Expanded(
                flex: 1,
                child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Image.asset(
                      'assets/images/app-logo.png',
                      width: 200,
                    ) /*Text(
                    'Đại Long Express',
                    style: TextStyle(
                      fontSize: 36.0,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),*/
                    ),
              ),
              /*const SizedBox(
                height: 20,
              ),*/
              Expanded(
                flex: 2,
                child: Form(
                  key: _loginFormKey,
                  child: Column(
                    children: [
                      TextFormField(
                        cursorWidth: 1,
                        controller: _usernameController,
                        focusNode: _usernameFocusNode,
                        decoration: _decoration(
                          hintText: Utils.getLocale(context)!.username,
                          prefixIcon: Icons.account_circle,
                        ),
                        style: _white(),
                        maxLength: 30,
                        maxLines: 1,
                        cursorColor: Utils.accentColor,
                        textInputAction: TextInputAction.next,
                        onFieldSubmitted: (term) {
                          _usernameFocusNode.unfocus();
                          FocusScope.of(context)
                              .requestFocus(_passwordFocusNode);
                        },
                        validator: (value) {
                          if (Utils.isNullOrEmpty(value!))
                            return Utils.getLocale(context)?.required;

                          return null;
                        },
                      ),
                      SizedBox(height: _spacing),
                      TextFormField(
                        cursorWidth: 1,
                        controller: _passwordController,
                        focusNode: _passwordFocusNode,
                        decoration: _decoration(
                          hintText: Utils.getLocale(context)!.password,
                          prefixIcon: Icons.lock_outline,
                        ),
                        style: _white(),
                        obscureText: true,
                        maxLength: 30,
                        maxLines: 1,
                        cursorColor: Utils.accentColor,
                        textInputAction: TextInputAction.done,
                        validator: (value) {
                          if (Utils.isNullOrEmpty(value!))
                            return Utils.getLocale(context)?.required;

                          return null;
                        },
                      ),
                      SizedBox(height: _spacing * 2),
                      Row(
                        children: [
                          SizedBox(
                            width: 24.0,
                            height: 24.0,
                            child: Theme(
                              data: ThemeData(
                                unselectedWidgetColor:
                                    Theme.of(context).disabledColor,
                              ),
                              child: Checkbox(
                                onChanged: (checked) {
                                  setState(() => _rememberMe = checked!);
                                },
                                value: _rememberMe,
                                activeColor: Utils.accentColor,
                              ),
                            ),
                          ),
                          SizedBox(width: _spacing),
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                setState(() => _rememberMe = !_rememberMe);
                              },
                              child: Text(
                                Utils.getLocale(context)!.rememberMe,
                                style: _white(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: _spacing * 2),
                      SizedBox(
                        width: double.infinity,
                        height: 50.0,
                        child:
                            // RaisedButton(
                            //   onPressed: _loading ? null : _btnLoginClicked,
                            //   disabledColor: Colors.black12,
                            //   disabledTextColor: Colors.white70,
                            //   color: Utils.accentColor,
                            //   textColor: Colors.white,
                            //   child: Text(
                            //     _loading
                            //         ? '${Utils.getLocale(context)?.waitForLogin}'
                            //         : Utils.getLocale(context)?.login,
                            //     style: TextStyle(
                            //       fontSize: 20.0,
                            //     ),
                            //   ),
                            // ),
                            ElevatedButton(
                          onPressed: _loading ? null : _btnLoginClicked,
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: _loading
                                ? Colors.black12
                                : Utils.accentColor, // Set text color
                          ),
                          child: Text(
                            _loading
                                ? '${Utils.getLocale(context)!.waitForLogin}'
                                : Utils.getLocale(context)!.login,
                            style: TextStyle(
                              fontSize: 20.0,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: _spacing * 2),
                      Row(
                        children: [
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(MaterialPageRoute(
                                    builder: (context) => RegisterScreen(
                                          currentUser: User(),
                                        )));
                              },
                              child: Text(
                                Utils.getLocale(context)!.register,
                                style: _blue(),
                              ),
                            ),
                          ),
                          Expanded(
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _forgotPasswordClicked,
                                  child: Text(
                                    '${Utils.getLocale(context)?.forgotPassword}?',
                                    style: _blue(),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      Expanded(
                        child: Center(
                          child: Material(
                            color: Colors.transparent,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.language,
                                      color: Colors.black45),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: Row(
                                          children: [
                                            Icon(Icons.language),
                                            SizedBox(width: 10.0),
                                            Text(
                                                '${Utils.getLocale(context)?.language}'),
                                          ],
                                        ),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ListTile(
                                                onTap: () {
                                                  _localeChanged('vi');
                                                  Navigator.of(context).pop();
                                                },
                                                title: Text(
                                                    '${Utils.getLocale(context)?.vietnamese}'),
                                                trailing: _locale != 'vi'
                                                    ? null
                                                    : Icon(Icons.done,
                                                        color:
                                                            Utils.accentColor),
                                              ),
                                              ListTile(
                                                onTap: () {
                                                  _localeChanged('en');
                                                  Navigator.of(context).pop();
                                                },
                                                title: Text(
                                                    '${Utils.getLocale(context)?.english}'),
                                                trailing: _locale != 'en'
                                                    ? null
                                                    : Icon(Icons.done,
                                                        color:
                                                            Utils.accentColor),
                                              ),
                                              ListTile(
                                                onTap: () {
                                                  _localeChanged('zh');
                                                  Navigator.of(context).pop();
                                                },
                                                title: Text(
                                                    '${Utils.getLocale(context)?.chinese}'),
                                                trailing: _locale != 'zh'
                                                    ? null
                                                    : Icon(Icons.done,
                                                        color:
                                                            Utils.accentColor),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                  /*child: Text(
                                  '${Utils.getLocale(context).changeLanguage}',
                                  style: TextStyle(color: Colors.white),
                                ),*/
                                ),
                                Text(
                                  _locale == 'vi'
                                      ? Utils.getLocale(context)!.vietnamese
                                      : _locale == 'en'
                                          ? Utils.getLocale(context)!.english
                                          : Utils.getLocale(context)!.chinese,
                                  style: TextStyle(
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Container(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => PriceCalculationScreen(
                                        currentUser: User(),
                                      )));
                            },
                            child: Text(
                              Utils.getLocale(context)!
                                  .tryToCalculatePrice
                                  .toUpperCase(),
                              style: TextStyle(
                                color: Colors.blue,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              /*Expanded(
                flex: 1,
                child: Column(
                  children: [],
                ),
              ),*/
            ],
          ),
        ),
      ),
    );
  }

  void _localeChanged(String code) {
    setState(() {
      _locale = code;
      AppProvider.of(context)?.state.localeBloc.setLocale(Locale(code));
      SharedPreferences.getInstance()
          .then((prefs) => prefs.setString(PrefsKey.languageCode, _locale));
    });
    HttpUtil.updateLocale(SessionUtil.instance().deviceId, code);
  }

  InputDecoration _decoration({String? hintText, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hintText ?? '',
      hintStyle: TextStyle(
        color: Colors.black45,
      ),
      counterText: '',
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.black12),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.black12),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.black12),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.orangeAccent),
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.orangeAccent),
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: Colors.black12,
      ),
      errorStyle: TextStyle(
        color: Colors.orangeAccent,
      ),
    );
  }

  Future<void> _btnLoginClicked() async {
    if (_loginFormKey.currentState!.validate()) {
      _setLoading(true);
      Future.delayed(Duration(milliseconds: 500), () async {
        late http.Response resp;
        try {
          // send HTTP request to login
          resp = await http
              .post(ApiUrls.instance().getLoginUrl() as Uri,
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    'username': _usernameController.text?.trim(),
                    'password': _passwordController.text?.trim()
                  }))
              .timeout(const Duration(seconds: timeout), onTimeout: () async {
            _onRequestTimeout();
            throw Exception('Request timed out');
            // return null;
          });
        } catch (e) {
          _setLoading(false);
        }
        if (resp == null) return;
        if (resp.statusCode == 200) {
          var body = jsonDecode(resp.body);
          final jwtToken = body['jwttoken'];
          if (!Utils.isNullOrEmpty(jwtToken)) {
            // save authorization token
            SessionUtil.instance().authToken = jwtToken;

            // set FCM token
            FirebaseMessaging firebaseMessaging = FirebaseMessaging.instance;
            SessionUtil.instance().fcmToken =
                (await firebaseMessaging.getToken())!;

            // Get user information
            HttpUtil.get(ApiUrls.instance().getUserInfoUrl(),
                headers: {'Content-Type': 'application/json'},
                onResponse: (resp) {
              if (resp == null || resp.statusCode != 200) {
                _setLoading(false);
                Utils.alert(context,
                    title: Utils.getLocale(context)?.errorOccurred,
                    message:
                        '${Utils.getLocale(context)?.cannotGetUserInfoMessage}');
                return;
              }
              var json = jsonDecode(utf8.decode(resp.bodyBytes));
              if (json == null) {
                Utils.alert(context,
                    title: Utils.getLocale(context)?.errorOccurred,
                    message:
                        '${Utils.getLocale(context)?.usernameOrPasswordNotMatchMessage}');
                return;
              }
              // save user info
              SessionUtil.instance().user = User.fromJson(json);
              // parse avatar
              var imageData = json['avatarImgDTO'];
              if (imageData != null) {
                String filePath = imageData['flePath']?.toString() ?? '';
                filePath = filePath.replaceAll('\\', '/');
                SessionUtil.instance().user.avatarImg =
                    '${ApiUrls.instance().baseUrl}/$filePath';
              }
              _saveDataToPreferences();
              _deviceRegister();
              //_setLoading(false); => now do not needed
              // Navigate to home screen
              /*Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => HomeScreen()));*/
              Navigator.of(context).pushReplacementNamed(AppRouter.homeScreen);
              if (SessionUtil.instance().user?.avatarImgDTO != null &&
                  !Utils.isNullOrEmpty(
                      SessionUtil.instance().user.avatarImgDTO!.flePath)) {
                SessionUtil.instance().user.avatarImgDTO?.flePath +=
                '?t=${DateTime.now().millisecondsSinceEpoch}';
              }
              AppProvider.of(context)!
                  .state
                  .userBloc
                  .setCurrentUser(SessionUtil.instance().user);
            }, onTimeout: _onRequestTimeout);
          } else {
            _setLoading(false);
            Utils.alert(context,
                title: Utils.getLocale(context)?.errorOccurred,
                message: '${body['message']}');
          }
        } else {
          _setLoading(false);
          Utils.alert(context,
              title: Utils.getLocale(context)?.errorOccurred,
              message: '${Utils.getLocale(context)?.wrongCredentialsMessage}');
        }
      });
    } else {
      // TODO: do something with errors
    }
  }

  void _onRequestTimeout() {
    _setLoading(false);
    Utils.alert(context,
        title: Utils.getLocale(context)?.errorOccurred,
        message: '${Utils.getLocale(context)?.requestTimeout}!');
  }

  void _forgotPasswordClicked() {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (context) => ForgotPasswordScreen()));
  }

  TextStyle _white() {
    return TextStyle(color: Colors.black54, fontSize: 20.0);
  }

  TextStyle _blue() {
    return TextStyle(color: Colors.black54, fontSize: 18.0);
  }

  void _setLoading(bool isLoading) {
    setState(() => _loading = isLoading);
  }

  Future<void> _saveDataToPreferences() async {
    var prefs = await SharedPreferences.getInstance();
    prefs.setString(
        PrefsKey.username, _rememberMe ? _usernameController.text.trim() : '');
    prefs.setString(
        PrefsKey.password, _rememberMe ? _passwordController.text.trim() : '');
    prefs.setBool(PrefsKey.remember, _rememberMe);
    prefs.setString(PrefsKey.languageCode, _locale);
    prefs.setBool(PrefsKey.logged, SessionUtil.instance().isLoggedIn());
  }

  Future<void> _deviceRegister() async {
    final String platform = Platform.isAndroid ? 'android' : 'ios';
    final session = SessionUtil.instance();
    if (Utils.isNullOrEmpty(session.deviceId)) {
      session.deviceId = (await _getDeviceId())!;
    }
    DeviceInfo deviceInfo = DeviceInfo(
      username: session.user.username,
      deviceId: session.deviceId,
      fcmToken: session.fcmToken,
      platform: platform,
      locale: _locale == 'vi'
          ? 'vi_VN'
          : _locale == 'en'
              ? 'en_US'
              : 'zh_CN',
    );
    HttpUtil.post(
      ApiUrls.instance().getDeviceRegisterUrl(),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: deviceInfo.toJson(),
      onResponse: (resp) {
        if (resp != null && resp.statusCode == 200) {
          print('Register device success for ${session.deviceId}');
          return;
        }

        print('Register device failed for ${session.deviceId}');
      },
      onTimeout: () {},
    );
  }

  Future<String?> _getDeviceId() async {
    DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    if (Platform.isIOS) {
      IosDeviceInfo iosDeviceInfo = await deviceInfo.iosInfo;
      return iosDeviceInfo.identifierForVendor; // unique ID on iOS
    } else {
      AndroidDeviceInfo androidDeviceInfo = await deviceInfo.androidInfo;
      return androidDeviceInfo.id; // unique ID on Android
    }
  }
}
