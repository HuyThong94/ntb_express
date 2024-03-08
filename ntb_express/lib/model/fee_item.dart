import 'package:json_annotation/json_annotation.dart';

part 'fee_item.g.dart';

@JsonSerializable()
class FeeItem {
  int feeId;
  int feeGroup;
  int goodsType;
  int locationGroup;
  double feeByWeight;
  double minWeight;
  double maxWeight;
  double feeBySize;
  double minSize;
  double maxSize;

  FeeItem(
      {this.feeId,
      this.feeGroup,
      this.goodsType,
      this.locationGroup,
      this.feeByWeight,
      this.minWeight,
      this.maxWeight,
      this.feeBySize,
      this.minSize,
      this.maxSize});

  factory FeeItem.fromJson(Map<String, dynamic> json) =>
      _$FeeItemFromJson(json);

  Map<String, dynamic> toJson() => _$FeeItemToJson(this);
}
