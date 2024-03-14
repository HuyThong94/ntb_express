import 'dart:convert';

import 'package:json_annotation/json_annotation.dart';
import 'package:ntbexpress/model/address.dart';
import 'package:ntbexpress/model/order_track.dart';
import 'package:ntbexpress/model/promotion.dart';
import 'package:ntbexpress/model/tcco_file.dart';
import 'package:ntbexpress/model/user.dart';
import 'package:ntbexpress/util/utils.dart';

part 'order.g.dart';

@JsonSerializable()
class Order {
  String orderId;
  int addressId;
  double commission;
  num createdDate;
  String createdId;
  String customerId;
  double extFee;
  String extTrackNo;
  String goodsDescr;
  int goodsType;
  double intFee;
  String intTrackNo;
  double payOnBehalf;
  int needRepack;
  double repackFee;
  int orderStatus;
  int packCount;
  String saleId;
  double size;
  double feeBySize;
  double feeByWeight;
  double totalFee;
  double weight;
  String? note;
  String? nextWarehouse;
  int? promotionId;
  List<TCCOFile?>? tccoFileDTOS;
  Address? addressDTO;
  User? customerDTO;
  List<OrderTrack?>? orderTrackDTOS;
  Promotion? promotionDTO;
  double totalFeeOriginal;
  double feeBySizeDealer;
  double feeByWeightDealer;
  double totalFeeDaiLong;
  String licensePlates;

  Order(
      {this.orderId = '',
      this.addressId = 0,
      this.commission = 0.0,
      this.createdDate = 0,
      this.createdId = '',
      this.customerId = '',
      this.extFee = 0.0,
      this.extTrackNo = '',
      this.goodsDescr = '',
      this.goodsType = 0,
      this.intFee = 0.0,
      this.intTrackNo = '',
      this.payOnBehalf = 0.0,
      this.needRepack = 0,
      this.repackFee = 0.0,
      this.orderStatus = 0,
      this.packCount = 0,
      this.saleId = '',
      this.size = 0.0,
      this.feeBySize = 0.0,
      this.feeByWeight = 0.0,
      this.totalFee = 0.0,
      this.weight = 0.0,
      this.note,
      this.nextWarehouse,
      this.promotionId,
      required this.tccoFileDTOS,
      this.addressDTO,
      this.customerDTO,
      this.orderTrackDTOS,
      this.promotionDTO,
      this.totalFeeOriginal = 0,
      this.feeBySizeDealer = 0,
      this.feeByWeightDealer = 0,
      this.totalFeeDaiLong = 0,
      this.licensePlates = ""});

  factory Order.fromJson(Map<String, dynamic> json) => _$OrderFromJson(json);

  Map<String, dynamic> toJson() => _$OrderToJson(this);

  factory Order.clone(Order other) =>
      Order.fromJson(jsonDecode(jsonEncode(other)));

  Map<String, String> toJsonString(String prefix) {
    var json = this
        .toJson()
        .map((key, value) => MapEntry(key, value?.toString() ?? ''));
    return json.map((key, value) => MapEntry(
        '${Utils.isNullOrEmpty(prefix) ? key : '$prefix[$key]'}', value));
  }

  String toPromotionQueryString() {
    return 'customerId=${this.customerId}&goodsType=${this.goodsType}&size=${this.size}&weight=${this.weight}';
  }

  @override
  String toString() {
    return 'Order{orderId: $orderId, addressId: $addressId, commission: $commission, createdDate: $createdDate, createdId: $createdId, customerId: $customerId, extFee: $extFee, extTrackNo: $extTrackNo, goodsDescr: $goodsDescr, goodsType: $goodsType, intFee: $intFee, intTrackNo: $intTrackNo, payOnBehalf: $payOnBehalf, needRepack: $needRepack, repackFee: $repackFee, orderStatus: $orderStatus, packCount: $packCount, saleId: $saleId, size: $size, totalFee: $totalFee, weight: $weight, note: $note, tccoFileDTOS: $tccoFileDTOS, addressDTO: $addressDTO, customerDTO: $customerDTO, orderTrackDTOS: $orderTrackDTOS}';
  }
}
