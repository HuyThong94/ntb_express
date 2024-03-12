import 'package:flutter/cupertino.dart';
import 'package:ntbexpress/bloc/locale_bloc.dart';
import 'package:ntbexpress/bloc/notification_bloc.dart';
import 'package:ntbexpress/bloc/order_bloc.dart';
import 'package:ntbexpress/bloc/user_bloc.dart';

class AppState {
  LocaleBloc localeBloc;
  UserBloc userBloc;
  OrderBloc orderBloc;
  NotificationBloc notificationBloc;

  AppState(
      {required this.localeBloc,
      required this.userBloc,
      required this.orderBloc,
      required this.notificationBloc});

  void reset() {
    userBloc = UserBloc();
    orderBloc = OrderBloc();
    notificationBloc = NotificationBloc();
  }
}
