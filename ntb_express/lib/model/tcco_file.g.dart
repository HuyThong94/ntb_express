// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tcco_file.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TCCOFile _$TCCOFileFromJson(Map<String, dynamic> json) {
  return TCCOFile(
    atchFleSeq: json['atchFleSeq'] as String,
    fleTP: json['fleTP'] as String,
    flePath: json['flePath'] as String,
    fleNm: json['fleNm'] as String,
    newFleNm: json['newFleNm'] as String,
    fleSz: json['fleSz'] as String,
    descrpt: json['descrpt'] as String,
    insId: json['insId'] as String,
    insDt: json['insDt'] as num,
    uptDt: json['uptDt'] as num,
    fleUri: json['fleUri'] as String,
  );
}

Map<String, dynamic> _$TCCOFileToJson(TCCOFile instance) => <String, dynamic>{
      'atchFleSeq': instance.atchFleSeq,
      'fleTP': instance.fleTP,
      'flePath': instance.flePath,
      'fleNm': instance.fleNm,
      'newFleNm': instance.newFleNm,
      'fleSz': instance.fleSz,
      'descrpt': instance.descrpt,
      'insId': instance.insId,
      'insDt': instance.insDt,
      'uptDt': instance.uptDt,
      'fleUri': instance.fleUri,
    };
