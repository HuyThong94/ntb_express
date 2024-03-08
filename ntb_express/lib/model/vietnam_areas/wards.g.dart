// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'wards.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Wards _$WardsFromJson(Map<String, dynamic> json) {
  return Wards(
    id: json['id'] as int,
    name: json['name'] as String,
    location: json['location'] as String,
    type: json['type'] as String,
    districtId: json['huyen_id'] as int,
  );
}

Map<String, dynamic> _$WardsToJson(Wards instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'location': instance.location,
      'type': instance.type,
      'huyen_id': instance.districtId,
    };
