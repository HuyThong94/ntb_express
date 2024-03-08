// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'district.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

District _$DistrictFromJson(Map<String, dynamic> json) {
  return District(
    id: json['id'] as int,
    name: json['name'] as String,
    location: json['location'] as String,
    type: json['type'] as String,
    provinceId: json['tinh_id'] as int,
  );
}

Map<String, dynamic> _$DistrictToJson(District instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'location': instance.location,
      'type': instance.type,
      'tinh_id': instance.provinceId,
    };
