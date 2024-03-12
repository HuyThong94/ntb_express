import 'package:json_annotation/json_annotation.dart';

part 'device_info.g.dart';

@JsonSerializable()
class DeviceInfo {
  int? id;
  String? username;
  String? deviceId;
  String? fcmToken;
  String? platform;
  String? locale;

  DeviceInfo(
      {this.id,
      this.username,
      this.deviceId,
      this.fcmToken,
      this.platform,
      this.locale});

  factory DeviceInfo.fromJson(Map<String, dynamic> json) =>
      _$DeviceInfoFromJson(json);

  Map<String, dynamic> toJson() => _$DeviceInfoToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceInfo &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          username == other.username &&
          deviceId == other.deviceId &&
          fcmToken == other.fcmToken &&
          platform == other.platform &&
          locale == other.locale;

  @override
  int get hashCode =>
      id.hashCode ^
      username.hashCode ^
      deviceId.hashCode ^
      fcmToken.hashCode ^
      platform.hashCode ^
      locale.hashCode;

  @override
  String toString() {
    return 'DeviceInfo{id: $id, username: $username, deviceId: $deviceId, fcmToken: $fcmToken, platform: $platform, locale: $locale}';
  }
}
