// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

OrderTrack _$OrderTrackFromJson(Map<String, dynamic> json) {
  return OrderTrack(
    trackId: json['trackId'] as int,
    actionDate: json['actionDate'] as int,
    actionId: json['actionId'] as String,
    actionType: json['actionType'] as int,
    orderId: json['orderId'] as String,
    note: json['note'] as String,
  );
}

Map<String, dynamic> _$OrderTrackToJson(OrderTrack instance) =>
    <String, dynamic>{
      'trackId': instance.trackId,
      'actionDate': instance.actionDate,
      'actionId': instance.actionId,
      'actionType': instance.actionType,
      'orderId': instance.orderId,
      'note': instance.note,
    };
