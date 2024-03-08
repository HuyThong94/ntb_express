// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Notification _$NotificationFromJson(Map<String, dynamic> json) {
  return Notification(
    id: json['id'] as int,
    notificationGroup: json['notification_group'] as String,
    orderId: json['order_id'] as String,
    customerId: json['customer_id'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    read: json['read'] as int,
    insertTime: json['insert_time'] as String,
  );
}

Map<String, dynamic> _$NotificationToJson(Notification instance) =>
    <String, dynamic>{
      'id': instance.id,
      'notification_group': instance.notificationGroup,
      'order_id': instance.orderId,
      'customer_id': instance.customerId,
      'title': instance.title,
      'body': instance.body,
      'read': instance.read,
      'insert_time': instance.insertTime,
    };
