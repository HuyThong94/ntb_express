import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'notification.g.dart';

@JsonSerializable()
class Notification {
  int? id;
  @JsonKey(name: 'notification_group')
  String? notificationGroup;
  @JsonKey(name: 'order_id')
  String orderId;
  @JsonKey(name: 'customer_id')
  String? customerId;
  String? title;
  String?body;
  int? read;
  @JsonKey(name: 'insert_time')
  String insertTime;


  Notification({this.id, this.notificationGroup,  required this.orderId, this.customerId, this.title,
      this.body, this.read = 0, required this.insertTime});

  factory Notification.fromJson(Map<String, dynamic> json) =>
      _$NotificationFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationToJson(this);

  static Notification clone(Notification other) {
    final String jsonString = json.encode(other);
    final jsonResponse = json.decode(jsonString);

    return Notification.fromJson(jsonResponse as Map<String, dynamic>);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Notification &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          notificationGroup == other.notificationGroup &&
          orderId == other.orderId &&
          customerId == other.customerId &&
          title == other.title &&
          body == other.body &&
          read == other.read &&
          insertTime == other.insertTime;

  @override
  int get hashCode =>
      id.hashCode ^
      notificationGroup.hashCode ^
      orderId.hashCode ^
      customerId.hashCode ^
      title.hashCode ^
      body.hashCode ^
      read.hashCode ^
      insertTime.hashCode;

  @override
  String toString() {
    return 'Notification{id: $id, notificationGroup: $notificationGroup, orderId: $orderId, customerId: $customerId, title: $title, body: $body, read: $read, insertTime: $insertTime}';
  }
}
