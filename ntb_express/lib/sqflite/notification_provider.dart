import 'package:ntbexpress/model/notification.dart' as own;
import 'package:ntbexpress/model/notification_detail.dart';
import 'package:ntbexpress/sqflite/database_helper.dart';
import 'package:ntbexpress/util/session_util.dart';
import 'package:ntbexpress/util/utils.dart';
import 'package:sqflite/sqflite.dart';

class NotificationProvider {
  final dbHelper = DatabaseHelper.instance;

  final _notificationColumnList = 'id, customer_id, notification_group, order_id, title, body, read, datetime(insert_time, "localtime") as insert_time';
  final _notificationDetailColumnList = 'id, order_id, title, body, datetime(insert_time, "localtime") as insert_time';

  Future<own.Notification?> insert(Map<String, dynamic> row) async {
    final group = row['notification_group']?.toString();
    final orderId = row['order_id']?.toString();
    if (NotificationGroup.order == group && !Utils.isNullOrEmpty(orderId!)) {
      // delete current order_id in notification table
      await dbHelper.delete(TableName.notification, 'order_id', orderId);

      if (row['customer_id'] == null && SessionUtil.instance().user != null) {
        row['customer_id'] = SessionUtil.instance().user.username;
      }

      final String customerId = row['customer_id'];
      if (customerId != null) {
        // insert new row to notification table
        await dbHelper.insert(TableName.notification, row);
        // insert new row to notification_detail table
        row = NotificationDetail.fromJson(row).toJson();
        row.remove('insert_time');
        row.remove('customer_id');
        await dbHelper.insert(TableName.notificationDetail, row);
        return await _getNotificationByOrderId(orderId, customerId: customerId);
      }

      return null;
    } else {
      // insert to notification table
      await dbHelper.insert(TableName.notification, row);
      return await _getNotificationByOrderId(orderId!);
    }
  }

  Future<own.Notification?> _getNotificationByOrderId(String orderId, {String? customerId}) async {
    final db = await dbHelper.database;
    if (Utils.isNullOrEmpty(customerId!) && SessionUtil.instance().isLoggedIn())
      customerId = SessionUtil.instance()!.user!.username;
    List<Map<String, dynamic>> list = await db.rawQuery('SELECT $_notificationColumnList FROM ${TableName.notification} WHERE order_id = "$orderId" ${!Utils.isNullOrEmpty(customerId) ? 'AND customer_id = "$customerId"' : ''}');
    if (list == null || list.isEmpty) return null;

    return own.Notification.fromJson(list.first);
  }

  Future<List<own.Notification>?> getOrderList({int start = 0, int limit = 20, String? customerId}) async {
    final db = await dbHelper.database;
    if (Utils.isNullOrEmpty(customerId!) && SessionUtil.instance().isLoggedIn())
      customerId = SessionUtil.instance()!.user!.username;
    List<Map<String, dynamic>> list = await db.rawQuery('SELECT $_notificationColumnList FROM ${TableName.notification} ${!Utils.isNullOrEmpty(customerId) ? 'WHERE customer_id = "$customerId"' : ''} ORDER BY order_id DESC, insert_time DESC LIMIT $start, $limit');
    if (list == null || list.isEmpty) return null;

    return list.map((e) => own.Notification.fromJson(e)).toList();
  }

  Future<List<NotificationDetail>?> getOrderDetailList({String? orderId}) async {
    final db = await dbHelper.database;
    List<Map<String, dynamic>> list = await db.rawQuery('SELECT $_notificationDetailColumnList FROM ${TableName.notificationDetail} WHERE order_id = "$orderId" ORDER BY insert_time DESC');
    if (list == null || list.isEmpty) return null;

    return list.map((e) => NotificationDetail.fromJson(e)).toList();
  }

  Future<int?> getUnreadCount({String? customerId}) async {
    final db = await dbHelper.database;
    if (Utils.isNullOrEmpty(customerId!) && SessionUtil.instance().isLoggedIn())
      customerId = SessionUtil.instance()?.user?.username;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM ${TableName.notification} WHERE read = 0 ${!Utils.isNullOrEmpty(customerId!) ? 'AND customer_id = "$customerId"' : ''}'));
  }

  Future<void> markedAllAsRead({String? customerId}) async {
    final db = await dbHelper.database;
    if (Utils.isNullOrEmpty(customerId!) && SessionUtil.instance().isLoggedIn())
      customerId = SessionUtil.instance()?.user?.username;
    await db.execute('UPDATE ${TableName.notification} SET read = 1 WHERE customer_id = "$customerId" ${!Utils.isNullOrEmpty(customerId!) ? 'AND customer_id = "$customerId"' : ''}');
  }

  Future<void> markedAllAsUnread({String? customerId}) async {
    final db = await dbHelper.database;
    if (Utils.isNullOrEmpty(customerId!) && SessionUtil.instance().isLoggedIn())
      customerId = SessionUtil.instance()!.user!.username;
    await db.execute('UPDATE ${TableName.notification} SET read = 0 AND customer_id = "$customerId" ${!Utils.isNullOrEmpty(customerId) ? 'AND customer_id = "$customerId"' : ''}');
  }

  Future<void> markedAsReadById(int notificationId, {String? customerId}) async {
    final db = await dbHelper.database;
    if (Utils.isNullOrEmpty(customerId!) && SessionUtil.instance().isLoggedIn())
      customerId = SessionUtil.instance()?.user?.username;
    await db.execute('UPDATE ${TableName.notification} SET read = 1 WHERE id = $notificationId ${!Utils.isNullOrEmpty(customerId!) ? 'AND customer_id = "$customerId"' : ''}');
  }

  Future<void> markedAsReadByOrderId(String orderId, {String? customerId}) async {
    final db = await dbHelper.database;
    if (Utils.isNullOrEmpty(customerId!) && SessionUtil.instance().isLoggedIn())
      customerId = SessionUtil.instance()!.user!.username;
    await db.execute('UPDATE ${TableName.notification} SET read = 1 WHERE order_id = "$orderId" ${!Utils.isNullOrEmpty(customerId) ? 'AND customer_id = "$customerId"' : ''}');
  }

  Future<int> delete(int id) async {
    return await dbHelper.delete(TableName.notification, 'id', id);
  }

  Future<int> deleteByOrderId(String orderId) async {
    return await dbHelper.delete(TableName.notification, 'order_id', orderId);
  }
}