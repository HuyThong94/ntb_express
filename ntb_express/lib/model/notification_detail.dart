import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';

part 'notification_detail.g.dart';

@JsonSerializable()
class NotificationDetail {
  int? id;
  @JsonKey(name: 'order_id')
  String? orderId;
  String? title;
  String? body;
  @JsonKey(name: 'insert_time')
  String? insertTime;


  NotificationDetail({this.id, this.orderId, this.title,
      this.body, this.insertTime});

  factory NotificationDetail.fromJson(Map<String, dynamic> json) =>
      _$NotificationDetailFromJson(json);

  Map<String, dynamic> toJson() => _$NotificationDetailToJson(this);

  static NotificationDetail clone(NotificationDetail other) {
    final String jsonString = json.encode(other);
    final jsonResponse = json.decode(jsonString);

    return NotificationDetail.fromJson(jsonResponse as Map<String, dynamic>);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NotificationDetail &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          orderId == other.orderId &&
          title == other.title &&
          body == other.body &&
          insertTime == other.insertTime;

  @override
  int get hashCode =>
      id.hashCode ^
      orderId.hashCode ^
      title.hashCode ^
      body.hashCode ^
      insertTime.hashCode;

  @override
  String toString() {
    return 'NotificationDetail{id: $id, orderId: $orderId, title: $title, body: $body, insertTime: $insertTime}';
  }
}
