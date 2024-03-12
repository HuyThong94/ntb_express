import 'package:flutter/cupertino.dart';
import 'package:ntbexpress/model/notification.dart' as notification;
import 'package:ntbexpress/sqflite/notification_provider.dart';
import 'package:ntbexpress/util/utils.dart';
import 'package:rxdart/rxdart.dart';

class NotificationBloc {
  int _unreadCount = 0;
  final List<notification.Notification> _notifications =
      <notification.Notification>[];

  late BehaviorSubject<List<notification.Notification>> _notificationsSubject;
  late BehaviorSubject<int> _unreadCountSubject;

  int get start => _notifications.length;
  List<notification.Notification> get current => _notifications;

  NotificationBloc() {
    _notificationsSubject =
        BehaviorSubject<List<notification.Notification>>.seeded(_notifications);
    _unreadCountSubject = BehaviorSubject<int>.seeded(_unreadCount);
  }

  void _handleNotifications(List<notification.Notification> orders) {
    _notifications.clear();
    if (orders != null) {
      orders.forEach((ord) => _notifications.add(ord));
    }
    _notificationsSubject.sink.add(_notifications);
  }

  /// Set notifications
  void setNotifications(List<notification.Notification> list) {
    _sort();
    _handleNotifications(list);
  }

  void markedAs({required bool read}) {
    final status = read ? 1 : 0;
    _notifications.forEach((o) {
      o.read = status;
    });
    _sort();
    _notificationsSubject.sink.add(_notifications);
  }

  void markedAsBy({required String orderId, required bool read}) {
    final status = read ? 1 : 0;
    _notifications.firstWhere((o) => o.orderId == orderId)?.read = status;
    _notificationsSubject.sink.add(_notifications);
  }

  /// Add notification if does not exist, otherwise update notification from list
  Future<void> updateNotification(notification.Notification o) async {
    if (o == null) return;

    if (_notifications.isEmpty) {
      List<notification.Notification> notificationList = await NotificationProvider().getOrderList();
      if (notificationList != null) {
        _notifications.addAll(notificationList);
      }
    }

    final index = _notifications
        .indexWhere((notification) => notification.orderId == o.orderId);
    if (index == -1) {
      // not found
      _notifications.add(o);
    } else {
      _notifications[index] = o;
    }
    _sort();
    _notificationsSubject.sink.add(_notifications);
  }

  // Remove notification from list
  void removeNotification(notification.Notification obj) {
    if (obj == null) return;

    _notifications.removeWhere((o) => o.id == obj.id);
    _sort();
    _notificationsSubject.sink.add(_notifications);
  }

  // update unread count
  void setUnreadCount(int count) {
    _unreadCount = count;
    _unreadCountSubject.sink.add(_unreadCount);
  }

  void _sort() {
    _notifications.sort((a, b) {
      if (Utils.isNullOrEmpty(a.orderId) || Utils.isNullOrEmpty(b.orderId))
        return b.insertTime.compareTo(a.insertTime);
      return b.orderId.compareTo(a.orderId);
    });
  }

  Stream<List<notification.Notification>> get notifications =>
      _notificationsSubject.stream;

  Stream<int> get unreadCount => _unreadCountSubject.stream;

  void reset() {
    setUnreadCount(0);
    _notifications.clear();
    _notificationsSubject.sink.add(_notifications);
  }

  void dispose() {
    _notificationsSubject?.close();
    _unreadCountSubject?.close();
  }
}
