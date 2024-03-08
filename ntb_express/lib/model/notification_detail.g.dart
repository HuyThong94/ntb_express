// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_detail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NotificationDetail _$NotificationDetailFromJson(Map<String, dynamic> json) {
  return NotificationDetail(
    id: json['id'] as int,
    orderId: json['order_id'] as String,
    title: json['title'] as String,
    body: json['body'] as String,
    insertTime: json['insert_time'] as String,
  );
}

Map<String, dynamic> _$NotificationDetailToJson(NotificationDetail instance) =>
    <String, dynamic>{
      'id': instance.id,
      'order_id': instance.orderId,
      'title': instance.title,
      'body': instance.body,
      'insert_time': instance.insertTime,
    };
