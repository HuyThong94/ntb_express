// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'promotion.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Promotion _$PromotionFromJson(Map<String, dynamic> json) {
  return Promotion(
    promotionId: json['promotionId'] as int,
    promotionName: json['promotionName'] as String,
    startDate: json['startDate'] as num,
    endDate: json['endDate'] as num,
    goodsType: json['goodsType'] as int,
    promotionType: json['promotionType'] as int,
    discountValue: (json['discountValue'] as num)?.toDouble(),
    maxDiscountValue: (json['maxDiscountValue'] as num)?.toDouble(),
    countOrder: json['countOrder'] as int,
    minSize: (json['minSize'] as num)?.toDouble(),
    maxSize: (json['maxSize'] as num)?.toDouble(),
    minWeight: (json['minWeight'] as num)?.toDouble(),
    maxWeight: (json['maxWeight'] as num)?.toDouble(),
    minFee: (json['minFee'] as num)?.toDouble(),
    maxFee: (json['maxFee'] as num)?.toDouble(),
    compareValue: json['compareValue'] as String,
    compareType: json['compareType'] as int,
    maxUse: json['maxUse'] as int,
    feeBySizeZ1: (json['feeBySizeZ1'] as num)?.toDouble(),
    feeByWeightZ1: (json['feeByWeightZ1'] as num)?.toDouble(),
    feeBySizeZ2: (json['feeBySizeZ2'] as num)?.toDouble(),
    feeByWeightZ2: (json['feeByWeightZ2'] as num)?.toDouble(),
    feeBySizeZ3: (json['feeBySizeZ3'] as num)?.toDouble(),
    feeByWeightZ3: (json['feeByWeightZ3'] as num)?.toDouble(),
    description: json['description'] as String,
    valid: json['valid'] as bool,
  );
}

Map<String, dynamic> _$PromotionToJson(Promotion instance) => <String, dynamic>{
      'promotionId': instance.promotionId,
      'promotionName': instance.promotionName,
      'startDate': instance.startDate,
      'endDate': instance.endDate,
      'goodsType': instance.goodsType,
      'promotionType': instance.promotionType,
      'discountValue': instance.discountValue,
      'maxDiscountValue': instance.maxDiscountValue,
      'countOrder': instance.countOrder,
      'minSize': instance.minSize,
      'maxSize': instance.maxSize,
      'minWeight': instance.minWeight,
      'maxWeight': instance.maxWeight,
      'minFee': instance.minFee,
      'maxFee': instance.maxFee,
      'compareValue': instance.compareValue,
      'compareType': instance.compareType,
      'maxUse': instance.maxUse,
      'feeBySizeZ1': instance.feeBySizeZ1,
      'feeByWeightZ1': instance.feeByWeightZ1,
      'feeBySizeZ2': instance.feeBySizeZ2,
      'feeByWeightZ2': instance.feeByWeightZ2,
      'feeBySizeZ3': instance.feeBySizeZ3,
      'feeByWeightZ3': instance.feeByWeightZ3,
      'description': instance.description,
      'valid': instance.valid,
    };
