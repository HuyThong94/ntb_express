// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'order.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Order _$OrderFromJson(Map<String, dynamic> json) {
  return Order(
    orderId: json['orderId'] as String,
    addressId: json['addressId'] as int,
    commission: (json['commission'] as num)!.toDouble(),
    createdDate: json['createdDate'] as num,
    createdId: json['createdId'] as String,
    customerId: json['customerId'] as String,
    extTrackNo: json['extTrackNo'] as String,
    goodsDescr: json['goodsDescr'] as String,
    goodsType: json['goodsType'] as int,
    extFee: (json['extFee'] as num)!.toDouble(),
    intFee: (json['intFee'] as num)!.toDouble(),
    intTrackNo: json['intTrackNo'] as String,
    payOnBehalf: (json['payOnBehalf'] as num)!.toDouble(),
    needRepack: json['needRepack'] as int,
    repackFee: (json['repackFee'] as num)!.toDouble(),
    orderStatus: json['orderStatus'] as int,
    packCount: json['packCount'] as int,
    saleId: json['saleId'] as String,
    size: (json['size'] as num)!.toDouble(),
    feeBySize: (json['feeBySize'] as num)!.toDouble(),
    feeByWeight: (json['feeByWeight'] as num)!.toDouble(),
    totalFee: (json['totalFee'] as num)!.toDouble(),
    weight: (json['weight'] as num)!.toDouble(),
    note: json['note'] as String,
    nextWarehouse: json['nextWarehouse'] as String,
    promotionId: json['promotionId'] as int,
    tccoFileDTOS: (json['tccoFileDTOS'] as List)
        ?.map((e) =>
            e == null ? null : TCCOFile.fromJson(e as Map<String, dynamic>))
        !.toList(),
    addressDTO: json['addressDTO'] == null
        ? null
        : Address.fromJson(json['addressDTO'] as Map<String, dynamic>),
    customerDTO: json['customerDTO'] == null
        ? null
        : User.fromJson(json['customerDTO'] as Map<String, dynamic>),
    orderTrackDTOS: (json['orderTrackDTOS'] as List)
        ?.map((e) =>
            e == null ? null : OrderTrack.fromJson(e as Map<String, dynamic>))
        !.toList(),
    promotionDTO: json['promotionDTO'] == null
        ? null
        : Promotion.fromJson(json['promotionDTO'] as Map<String, dynamic>),
    totalFeeOriginal: json['totalFeeOriginal'] as double,
    feeBySizeDealer: json['feeBySizeDealer'] as double,
    feeByWeightDealer: json['feeByWeightDealer'] as double,
    totalFeeDaiLong: json['totalFeeDaiLong'] as double,
    licensePlates: json['licensePlates'] as String,
  );
}

Map<String, dynamic> _$OrderToJson(Order instance) => <String, dynamic>{
      'orderId': instance.orderId,
      'addressId': instance.addressId,
      'commission': instance.commission,
      'createdDate': instance.createdDate,
      'createdId': instance.createdId,
      'customerId': instance.customerId,
      'extFee': instance.extFee,
      'extTrackNo': instance.extTrackNo,
      'goodsDescr': instance.goodsDescr,
      'goodsType': instance.goodsType,
      'intFee': instance.intFee,
      'intTrackNo': instance.intTrackNo,
      'payOnBehalf': instance.payOnBehalf,
      'needRepack': instance.needRepack,
      'repackFee': instance.repackFee,
      'orderStatus': instance.orderStatus,
      'packCount': instance.packCount,
      'saleId': instance.saleId,
      'size': instance.size,
      'feeBySize': instance.feeBySize,
      'feeByWeight': instance.feeByWeight,
      'totalFee': instance.totalFee,
      'weight': instance.weight,
      'note': instance.note,
      'nextWarehouse': instance.nextWarehouse,
      'promotionId': instance.promotionId,
      'tccoFileDTOS': instance.tccoFileDTOS,
      'addressDTO': instance.addressDTO,
      'customerDTO': instance.customerDTO,
      'orderTrackDTOS': instance.orderTrackDTOS,
      'promotionDTO': instance.promotionDTO,
      'totalFeeOriginal': instance.totalFeeOriginal,
      'feeBySizeDealer': instance.feeBySizeDealer,
      'feeByWeightDealer': instance.feeByWeightDealer,
      'totalFeeDaiLong': instance.totalFeeDaiLong,
      'licensePlates': instance.licensePlates
    };
