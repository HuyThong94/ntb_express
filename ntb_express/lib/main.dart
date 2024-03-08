import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_ringtone_player/flutter_ringtone_player.dart';
import 'package:notification_permissions/notification_permissions.dart';
import 'package:ntbexpress/bloc/locale_bloc.dart';
import 'package:ntbexpress/bloc/notification_bloc.dart';
import 'package:ntbexpress/bloc/order_bloc.dart';
import 'package:ntbexpress/bloc/user_bloc.dart';
import 'package:ntbexpress/localization/app_localizations.dart';
import 'package:ntbexpress/model/notification.dart' as own;
import 'package:ntbexpress/model/order.dart';
import 'package:ntbexpress/model/user.dart';
import 'package:ntbexpress/screens/home_screen.dart';
import 'package:ntbexpress/screens/login_screen.dart';
import 'package:ntbexpress/screens/order_detail_screen.dart';
import 'package:ntbexpress/sqflite/notification_provider.dart';
import 'package:ntbexpress/util/app_state.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/http_util.dart';
import 'package:ntbexpress/util/session_util.dart';
import 'package:ntbexpress/util/utils.dart';
import 'package:ntbexpress/widgets/app_provider.dart';
import 'package:rxdart/subjects.dart';
import 'package:vibration/vibration.dart';

final BehaviorSubject<ReceivedNotification> didReceiveLocalNotificationSubject =
    BehaviorSubject<ReceivedNotification>();

final BehaviorSubject<String> selectNotificationSubject =
    BehaviorSubject<String>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // prevent device orientation change
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  AppState appState = AppState(
    localeBloc: LocaleBloc(
      initialLocale: const Locale('en'),
    ),
    userBloc: UserBloc(),
    orderBloc: OrderBloc(),
    notificationBloc: NotificationBloc(),
  );
  runApp(NTBExpress(state: appState));
}

class NTBExpress extends StatelessWidget {
  final AppState state;

  NTBExpress({@required this.state});

  @override
  Widget build(BuildContext context) {
    return AppProvider(
      state: this.state,
      child: StreamBuilder<Locale>(
          stream: this.state.localeBloc.locale$,
          builder: (context, snapshot) {
            return MaterialApp(
              title: 'DL Express',
              debugShowCheckedModeBanner: false,
              localizationsDelegates: [
                GlobalWidgetsLocalizations.delegate,
                GlobalMaterialLocalizations.delegate,
                NTBExpressLocalizations.delegate
              ],
              supportedLocales: [
                const Locale('vi'),
                const Locale('en'),
                const Locale('zh')
              ],
              locale: snapshot.data,
              theme: ThemeData(
                appBarTheme: AppBarTheme(
                  color: Utils.primaryColor,
                ),
                primarySwatch: Colors.blue,
                accentColor: Utils.primaryColor,
                visualDensity: VisualDensity.adaptivePlatformDensity,
                pageTransitionsTheme: PageTransitionsTheme(builders: {
                  TargetPlatform.android: CupertinoPageTransitionsBuilder(),
                }),
              ),
              routes: <String, WidgetBuilder>{
                AppRouter.login: (context) => LoginScreen(),
                AppRouter.homeScreen: (context) => HomeScreen(),
              },
              home: HandleWrapper(child: Container()),
            );
          }),
    );
  }
}

class HandleWrapper extends StatefulWidget {
  final Widget child;

  HandleWrapper({this.child});

  @override
  _HandleWrapperState createState() => _HandleWrapperState();
}

class _HandleWrapperState extends State<HandleWrapper> {
  static final _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final _firebaseMessaging = FirebaseMessaging();
  static final _notificationProvider = NotificationProvider();
  static NotificationBloc _notificationBloc;
  static OrderBloc _orderBloc;
  bool _initialized = false;

  static bool _isDoubleMessage =
      true; // onMessage execute twice, ignore first time
  static bool _isDoubleResume =
      true; // onResume execute twice, ignore first time

  @override
  void initState() {
    super.initState();
    _checkNotificationPermission();
    _initLocalNotifications();
    _initFirebaseMessaging(context: context);
    _configureDidReceiveLocalNotificationSubject();
    _configureSelectNotificationSubject();
  }

  @override
  void dispose() {
    didReceiveLocalNotificationSubject.close();
    selectNotificationSubject.close();
    super.dispose();
  }

  Future<void> _checkNotificationPermission() async {
    PermissionStatus status =
        await NotificationPermissions.getNotificationPermissionStatus();
    switch (status) {
      case PermissionStatus.granted:
        // do nothing
        break;
      case PermissionStatus.unknown:
        // only iOS => send a request to permission
        _requestNotificationPermission();
        break;
      case PermissionStatus.denied:
        // request user for permission
        _requestNotificationPermission();
        break;
      case PermissionStatus.provisional:
        // TODO: Handle this case.
        break;
    }
  }

  Future<void> _requestNotificationPermission() async {
    NotificationPermissions.requestNotificationPermissions(
        iosSettings: const NotificationSettingsIos(
            sound: true, alert: true, badge: true),
        openSettings: true);
  }

  void _configureDidReceiveLocalNotificationSubject() {
    didReceiveLocalNotificationSubject.stream
        .listen((receivedNotification) async {
      if (receivedNotification == null ||
          Utils.isNullOrEmpty(receivedNotification.payload)) return;
      dynamic message = jsonDecode(receivedNotification.payload);
      _navigateToItemDetail(message);
    });
  }

  void _configureSelectNotificationSubject() {
    selectNotificationSubject.stream.listen((String payload) async {
      if (Utils.isNullOrEmpty(payload)) return;
      dynamic message = jsonDecode(payload);
      _navigateToItemDetail(message);
    });
  }

  void _initLocalNotifications() {
    var initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/launcher_icon');
    var initializationSettingsIOS = IOSInitializationSettings(
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        didReceiveLocalNotificationSubject.add(ReceivedNotification(
            id: id, title: title, body: body, payload: payload));
      },
    );
    var initializationSettings = InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    _flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: (payload) async {
      selectNotificationSubject.add(payload);
    });
  }

  void _initFirebaseMessaging({BuildContext context}) {
    _firebaseMessaging.configure(
      onMessage: (Map<String, dynamic> message) async {
        if (Platform.isIOS) {
          if (!_isDoubleMessage) {
            print("onMessage: $message");
            _showNotificationOnForeground(
                jsonDecode(jsonEncode(message)), context);
            _saveNotification(jsonDecode(jsonEncode(message)));
          }
          _isDoubleMessage = !_isDoubleMessage;
        } else {
          print("onMessage: $message");
          _showNotificationOnForeground(
              jsonDecode(jsonEncode(message)), context);
          _saveNotification(jsonDecode(jsonEncode(message)));
        }
      },
      onBackgroundMessage: Platform.isIOS ? null : _myBackgroundMessageHandler,
      onLaunch: (Map<String, dynamic> message) async {
        print("onLaunch: $message");
        if (Platform.isIOS) {
          await _saveNotification(jsonDecode(jsonEncode(message)));
        }
        _navigateToItemDetail(message);
      },
      onResume: (Map<String, dynamic> message) async {
        if (Platform.isIOS) {
          if (!_isDoubleResume) {
            print("onResume: $message");
            await _saveNotification(jsonDecode(jsonEncode(message)));
            _navigateToItemDetail(message);
          }
          _isDoubleResume = !_isDoubleResume;
        } else {
          print("onResume: $message");
          await _saveNotification(jsonDecode(jsonEncode(message)));
          _navigateToItemDetail(message);
        }
      },
    );
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(
            sound: true, badge: true, alert: true, provisional: false));
    _firebaseMessaging.onIosSettingsRegistered
        .listen((IosNotificationSettings settings) {
      print("Settings registered: $settings");
    });
    _firebaseMessaging.onTokenRefresh.listen((token) {
      if (Utils.isNullOrEmpty(token)) return;
      // TODO: check if logged in => update fcmToken for user
      // save token to session
      SessionUtil.instance().fcmToken = token;
      print('FCM TOKEN: $token');
    });
    _firebaseMessaging.subscribeToTopic('all');
  }

  static Future<dynamic> _myBackgroundMessageHandler(
      Map<String, dynamic> message) {
    print('onBackground: ');
    print(jsonEncode(message));
    _showNotification(message);
    return Future<void>.value();
  }

  static Future _showNotification(Map<String, dynamic> message) async {
    var pushTitle;
    var pushText;

    final data = Platform.isAndroid ? message['data'] : message;
    data['insert_time'] = data['time'];
    String orderId = data['order_id'];
    String status = data['body'];
    String locale = data['title'] ?? 'en';
    Map<String, String> msg = await _parsePushMessage(orderId, status, locale);
    if (msg == null) return;

    pushTitle = msg['title'];
    pushText = msg['body'];

    // save notification to sqlite
    _saveNotification(message);

    // @formatter:off
    var platformChannelSpecificsAndroid = new AndroidNotificationDetails(
        'ntb_express', 'DL Express', 'DL Express notification channel',
        channelShowBadge: true,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        importance: Importance.Max,
        priority: Priority.High,
        visibility: NotificationVisibility.Public);
    // @formatter:on
    var platformChannelSpecificsIos =
        IOSNotificationDetails(presentSound: true);
    var platformChannelSpecifics = NotificationDetails(
        platformChannelSpecificsAndroid, platformChannelSpecificsIos);

    Future.delayed(Duration.zero, () {
      Vibration.vibrate();
      FlutterRingtonePlayer.playNotification();
      _flutterLocalNotificationsPlugin.show(
        Random().nextInt(100),
        pushTitle,
        pushText,
        platformChannelSpecifics,
        payload: jsonEncode(message),
      );
    });
  }

  // type: all, order
  static Future<void> _saveNotification(Map<String, dynamic> message) async {
    if (message == null) return;

    final data = Platform.isAndroid ? message['data'] : message;
    data['insert_time'] = data['time'];
    if (data == null) return;
    String orderId = data['order_id'];
    String status = data['body'];
    String locale = data['title'] ?? 'en';
    Map<String, String> msg = await _parsePushMessage(orderId, status, locale);
    if (msg != null) {
      data['title'] = msg['title'];
      data['body'] = msg['body'];
    }

    data['read'] = 0; // unread
    final dataToInsert =
        own.Notification.fromJson(Map<String, dynamic>.from(data)).toJson();
    if (dataToInsert['order_id'] != null) {
      // remove unnecessary fields
      dataToInsert.remove('id');
      dataToInsert.remove('insert_time');

      final result = await _notificationProvider.insert(dataToInsert);
      if (_notificationBloc != null) {
        User currentUser = SessionUtil.instance()?.user;
        Order order = await HttpUtil.getOrder(result.orderId);
        if ((order != null && currentUser != null) &&
            ([UserType.customer, UserType.saleStaff]
                    .contains(currentUser.userType) ||
                (currentUser.username == order.saleId &&
                    order.orderStatus == OrderStatus.pendingWoodenPacking))) {
          // add or update new order to view list
          _orderBloc?.updateOrder(order);

          // add or update notification
          _notificationBloc.updateNotification(result);
          // update unread count
          _notificationProvider
              .getUnreadCount()
              .then((count) => _notificationBloc.setUnreadCount(count));
        }

        if (order != null && order.createdId == currentUser?.username) {
          // update read status
          _notificationProvider.markedAsReadById(result.id);
        }
      }
    }
  }

  static Future<void> _showNotificationOnForeground(
      Map<String, dynamic> message, BuildContext context) async {
    final data = Platform.isAndroid ? message['data'] : message;
    data['insert_time'] = data['time'];
    if (data == null || data['order_id'] == null || context == null) return;

    String orderId = data['order_id'];
    String status = data['body'];
    String locale = data['title'] ?? 'en';
    Map<String, String> msg = await _parsePushMessage(orderId, status, locale);
    if (msg == null) return;

    Future.delayed(Duration(seconds: 2), () async {
      Order order = await HttpUtil.getOrder(orderId);
      if (order != null &&
          order.createdId == SessionUtil.instance()?.user?.username) {
        // if current user create new order => do nothing
        return;
      }
      if (SessionUtil.instance()?.user?.userType == UserType.customer) {
        Vibration.vibrate();
        FlutterRingtonePlayer.playNotification();
        Utils.alert(context,
            title: '${msg['title'] ?? 'Thông báo'}', message: '${msg['body']}');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _notificationBloc = AppProvider.of(context).state.notificationBloc;
    _orderBloc = AppProvider.of(context).state.orderBloc;
    _notificationBloc.setNotifications([]);
    if (!_initialized) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        Navigator.of(context).pushNamed(AppRouter.login);
      });
      _initialized = true;
    }

    return widget.child;
  }

  Future<void> _navigateToItemDetail(Map<String, dynamic> message) async {
    print("_navigateToItemDetail: $message");
    if (message == null || (Platform.isAndroid && message['data'] == null))
      return;
    final orderId =
        Platform.isAndroid ? message['data']['order_id'] : message['order_id'];
    if (Utils.isNullOrEmpty(orderId)) return;

    // update read status for notification
    await _notificationProvider.markedAsReadByOrderId(orderId,
        customerId: Platform.isAndroid
            ? message['data']['customer_id']
            : message['customer_id']);
    // clear bloc if data already available
    AppProvider.of(context)?.state?.notificationBloc?.setNotifications([]);

    // check if logged in => get order detail & navigate to order detail screen
    if (SessionUtil.instance().isLoggedIn()) {
      HttpUtil.get(
        ApiUrls.instance().getOrderUrl(orderId),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        onResponse: (resp) async {
          if (resp != null && resp.statusCode == 200) {
            dynamic json = jsonDecode(utf8.decode(resp.bodyBytes));
            if (json == null) return;
            Order order = Order.fromJson(json);
            if (order == null) return;

            // check if bloc already => reset order bloc
            AppProvider.of(context)?.state?.orderBloc?.fetch(reset: true);

            // reset unread count
            int unreadCount = await _notificationProvider.getUnreadCount();
            AppProvider.of(context)
                ?.state
                ?.notificationBloc
                ?.setUnreadCount(unreadCount);

            // navigate to order detail screen
            if (SessionUtil.instance().canPop == 0) {
              Utils.updatePop(1);
              await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => OrderDetailScreen(order)));
            }
          }
        },
      );
    }
  }

  static Future<Map<String, String>> _parsePushMessage(
      String orderId, String status, String locale) async {
    if (Utils.isNullOrEmpty(status)) return null;
    locale = locale.split('_')[0].toLowerCase();
    Map<String, String> rs = {};
    final bool isVi = locale.contains('vi');
    final bool isZh = locale.contains('zh');
    final String ordId = Utils.isNullOrEmpty(orderId) ? '' : ' $orderId';

    rs['title'] = isVi ? 'Cập nhật đơn hàng' : isZh ? '更新訂單' : 'Update orders';
    if (status == 'import_to_vn') {
      rs['body'] = isVi
          ? 'Đơn hàng$ordId đã nhập tổng kho tại Việt Nam.'
          : isZh
              ? '訂單已進入越南倉庫.'
              : 'The order has entered the warehouse in Vietnam.';
    } else {
      int orderStatus = 0;
      try {
        orderStatus = int.tryParse(status) ?? 0;
      } catch (e) {
        // ignored
      }
      if (orderStatus == 0 && Platform.isAndroid) return null;
      if (orderStatus == 0 && Platform.isIOS) {
        rs['body'] = status;
        return rs;
      }

      switch (orderStatus) {
        case OrderStatus.newlyCreated:
          rs['body'] = isVi
              ? 'Đơn hàng$ordId đã được tạo.'
              : isZh ? '$ordId訂單已創建。' : 'The$ordId order has been created.';
          break;
        case OrderStatus.chineseWarehoused:
          rs['body'] = isVi
              ? 'Đơn hàng$ordId đã nhập kho Trung Quốc.'
              : isZh
                  ? '$ordId訂單已從中國進口。'
                  : 'The$ordId order have been imported from China.';
          break;
        case OrderStatus.chineseShippedOut:
          rs['body'] = isVi
              ? 'Đơn hàng$ordId đã xuất kho Trung Quốc.'
              : isZh
                  ? '$ordId訂單已從中國發貨。'
                  : 'The$ordId order have been shipped from China.';
          break;
        case OrderStatus.pendingWoodenPacking:
          rs['body'] = isVi
              ? 'Đơn hàng$ordId đang chờ xác nhận đóng gỗ.'
              : isZh
                  ? '$ordId訂單正在等待包裝確認。'
                  : 'The$ordId order is awaiting confirmation of packing.';
          break;
        case OrderStatus.delivery:
          rs['body'] = isVi
              ? 'Đơn hàng$ordId đang được giao.'
              : isZh ? '$ordId訂單已交貨。' : 'The$ordId order is on delivery.';
          break;
      }
    }

    return rs;
  }
}
