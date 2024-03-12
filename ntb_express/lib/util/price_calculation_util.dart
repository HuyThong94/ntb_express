import 'package:ntbexpress/model/address.dart';
import 'package:ntbexpress/model/fee_item.dart';
import 'package:ntbexpress/model/promotion.dart';
import 'package:ntbexpress/util/contants.dart';

class PriceCalculationUtil {
  static double calculatePrice(
      {double repackFee = 0,
      double payOnBehalf = 0,
      double intFee = 0,
      double extFee = 0}) {
    //print('calculatePrice: repackFee=$repackFee, payOnBehalf=$payOnBehalf, intFee=$intFee, extFee=$extFee, promotion=$promotion');
    double price = 0;
    price = repackFee + payOnBehalf + intFee + extFee;
        //_getDiscountPrice(repackFee + payOnBehalf + intFee + extFee, promotion);
    return price;
  }

  /// Calculate international shipping fee
  static double calculateExtFee(
      {Address? address,
      int? goodsType,
      double weight = 0,
      double size = 0,
      double feeByWeight = 0,
      double feeBySize = 0}) {
    //print('calculateExtFee: address=$address, goodsType=$goodsType, weight=$weight, size=$size');
    if (address == null) return 0;
    if (weight == 0 && size == 0) return 0;

    // check fixed fee
    if (feeBySize > 0 || feeByWeight > 0) {
      return weight * feeByWeight + size * feeBySize;
    }

    final locationGroup = getLocationGroupByProvince(address.province);
    if (locationGroup == 0) return 0;

    if (goodsType != GoodsType.normal) {
      FeeItem fee = _getFeeItem(goodsType!, locationGroup);
      if (fee == null) return 0;

      double price = weight * fee.feeByWeight! + size * fee.feeBySize!;

      return price;
    }

    double price = 0;
    List<FeeItem> fees = _getFeeItems(locationGroup);
    if (fees != null) {
      fees.forEach((e) {
        if (weight > 0 &&
            (weight >= e.minWeight! &&
                (weight < e.maxWeight! || e.maxWeight == -1))) {
          price += weight * e.feeByWeight!;
        }

        if (size > 0 &&
            (size >= e.minSize! && (size < e.maxSize! || e.maxSize == -1))) {
          price += size * e.feeBySize!;
        }
      });
    }

    return price;
  }

  static Map<String, double> getAgentFee(
      {Address? address,
        int? goodsType,
        double weight = 0,
        double size = 0,
        double feeByWeight = 0,
        double feeBySize = 0}) {
    Map<String, double> result = {
      "weight": 0,
      "size": 0
    };

    if (address == null) return result;
    if (weight == 0 && size == 0) return result;

    // check fixed fee
    if (feeBySize > 0 || feeByWeight > 0) {
      result["weight"] = feeByWeight;
      result["size"] = feeBySize;
      return result;
    }

    final locationGroup = getLocationGroupByProvince(address.province);
    if (locationGroup == 0) return result;

    if (goodsType != GoodsType.normal) {
      FeeItem fee = _getFeeItem(goodsType!, locationGroup);
      if (fee == null) return result;
      result["weight"] = fee.feeByWeight!;
      result["size"] = fee.feeBySize!;
      return result;
    }

    List<FeeItem> fees = _getFeeItems(locationGroup);
    if (fees != null) {
      fees.forEach((e) {
        if (weight > 0 &&
            (weight >= e.minWeight! &&
                (weight < e.maxWeight! || e.maxWeight == -1))) {
          result["weight"] = e.feeByWeight!;
        }

        if (size > 0 &&
            (size >= e.minSize! && (size < e.maxSize! || e.maxSize == -1))) {
          result["size"] = e.feeBySize!;
        }
      });
    }

    return result;
  }

  static double _getDiscountPrice(double price, Promotion promotion) {
    if (promotion != null &&
        promotion.valid! &&
        (promotion.countOrder == -1 || promotion.countOrder! > 0)) {
      double discountPrice = 0;
      if (promotion.promotionType == PromotionType.percent) {
        discountPrice = (price * promotion.discountValue!) / 100; // 100%
        if (discountPrice > promotion.maxDiscountValue!) {
          discountPrice = promotion.maxDiscountValue!;
        }
      } else if (promotion.promotionType == PromotionType.specificValue ||
          promotion.promotionType == PromotionType.samePrice) {
        discountPrice = promotion.discountValue!;
      }

      price = price - discountPrice;
      if (price < 0) price = 0;
    }

    return price;
  }

  static FeeItem _getFeeItem(int goodsType, int locationGroup) {
    return feeTable.firstWhere(
        (e) => e.locationGroup == locationGroup && e.goodsType == goodsType,
        orElse: () => null);
  }

  static List<FeeItem> _getFeeItems(int locationGroup) {
    return feeTable
        .where((e) =>
            e.locationGroup == locationGroup && e.goodsType == GoodsType.normal)
        .toList();
  }

  static int getLocationGroupByProvince(String provinceName) {
    return provinces
            .firstWhere(
                (p) => p.name.toLowerCase() == provinceName.toLowerCase(),
                orElse: () => null)
            ?.group ??
        0;
  }
}
