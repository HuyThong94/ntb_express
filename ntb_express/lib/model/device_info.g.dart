// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'device_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

DeviceInfo _$DeviceInfoFromJson(Map<String, dynamic> json) {
  return DeviceInfo(
    id: json['id'] as int,
    username: json['username'] as String,
    deviceId: json['deviceId'] as String,
    fcmToken: json['fcmToken'] as String,
    platform: json['platform'] as String,
    locale: json['locale'] as String,
  );
}

Map<String, dynamic> _$DeviceInfoToJson(DeviceInfo instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'deviceId': instance.deviceId,
      'fcmToken': instance.fcmToken,
      'platform': instance.platform,
      'locale': instance.locale,
    };
