import 'package:json_annotation/json_annotation.dart';

part 'order_track.g.dart';

@JsonSerializable()
class OrderTrack {
  int? trackId;
  int? actionDate;
  String? actionId;
  int? actionType;
  String? orderId;
  String? note;

  OrderTrack(
      {this.trackId,
      this.actionDate,
      this.actionId,
      this.actionType,
      this.orderId, this.note});

  factory OrderTrack.fromJson(Map<String, dynamic> json) =>
      _$OrderTrackFromJson(json);

  Map<String, dynamic> toJson() => _$OrderTrackToJson(this);

  @override
  String toString() {
    return 'OrderTrack{trackId: $trackId, actionDate: $actionDate, actionId: $actionId, actionType: $actionType, orderId: $orderId}';
  }
}
