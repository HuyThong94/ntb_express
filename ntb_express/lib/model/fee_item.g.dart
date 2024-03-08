// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fee_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FeeItem _$FeeItemFromJson(Map<String, dynamic> json) {
  return FeeItem(
    feeId: json['feeId'] as int,
    feeGroup: json['feeGroup'] as int,
    goodsType: json['goodsType'] as int,
    locationGroup: json['locationGroup'] as int,
    feeByWeight: (json['feeByWeight'] as num)?.toDouble(),
    minWeight: (json['minWeight'] as num)?.toDouble(),
    maxWeight: (json['maxWeight'] as num)?.toDouble(),
    feeBySize: (json['feeBySize'] as num)?.toDouble(),
    minSize: (json['minSize'] as num)?.toDouble(),
    maxSize: (json['maxSize'] as num)?.toDouble(),
  );
}

Map<String, dynamic> _$FeeItemToJson(FeeItem instance) => <String, dynamic>{
      'feeId': instance.feeId,
      'feeGroup': instance.feeGroup,
      'goodsType': instance.goodsType,
      'locationGroup': instance.locationGroup,
      'feeByWeight': instance.feeByWeight,
      'minWeight': instance.minWeight,
      'maxWeight': instance.maxWeight,
      'feeBySize': instance.feeBySize,
      'minSize': instance.minSize,
      'maxSize': instance.maxSize,
    };
