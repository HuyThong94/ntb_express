import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:devicelocale/devicelocale.dart';
import 'package:file/memory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';
import 'package:ntbexpress/localization/app_localizations.dart';
import 'package:ntbexpress/localization/message.dart';
import 'package:ntbexpress/model/order.dart';
import 'package:ntbexpress/model/user.dart';
import 'package:ntbexpress/model/vietnam_areas/district.dart';
import 'package:ntbexpress/model/vietnam_areas/province.dart';
import 'package:ntbexpress/model/vietnam_areas/wards.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/edit_screen.dart';
import 'package:ntbexpress/util/http_util.dart';
import 'package:ntbexpress/util/select_area_screen.dart';
import 'package:ntbexpress/util/session_util.dart';
import 'package:ntbexpress/widgets/app_provider.dart';
import 'package:ntbexpress/widgets/confirm_order_status.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Utils {
  /// Primary color, use for appbar, background, ...
  //static final Color primaryColor = Color(Utils.hexColor('#d35656'));
  static final Color primaryColor = Color(Utils.hexColor('#F94D30'));

  //static final Color accentColor = Color(Utils.hexColor('#f66767'));
  static final Color accentColor = Color(Utils.hexColor('#F94D30'));
  static final Color unreadColor = Color(Utils.hexColor('#F5F5F5'));
  static final Color grey = Color(Utils.hexColor('#E0E0E0'));
  static final Color? backgroundColor = Colors.grey[50];

  /// Check the input text is null or empty
  static bool isNullOrEmpty(String? str) {
    return str == null || str.trim().isEmpty;
  }

  /// Get current locale message (can get language correctly by locale)
  static Message? getLocale(BuildContext context) {
    return NTBExpressLocalizations.of(context).currentLocalized;
  }

  /// Convert HTML color code to hex value
  static int hexColor(String code) {
    if (code.length == 4 && code.startsWith('#')) {
      code = code.replaceAll('#', '');
      code = '#$code$code';
    }

    String color = '0xff$code';
    return int.parse(color.replaceAll('#', ''));
  }

  static String getDateString(num sourceDate, String pattern) {
    if (sourceDate == null || isNullOrEmpty(pattern)) return '';

    try {
      var date = DateTime.fromMillisecondsSinceEpoch(
          sourceDate.toInt()); // DateTime.parse(sourceDate);
      if (date != null) {
        return DateFormat(pattern).format(date);
      }
    } catch (e) {
      // ignored
    }

    return '';
  }

  static String getDateString2(String sourceDate, String pattern) {
    if (sourceDate == null || isNullOrEmpty(pattern)) return '';

    try {
      var date = DateTime.parse(sourceDate); // DateTime.parse(sourceDate);
      if (date != null) {
        return DateFormat(pattern).format(date);
      }
    } catch (e) {
      // ignored
    }

    return '';
  }
  static void alert(BuildContext context, {String? title, String? message, VoidCallback? onAccept}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return PopScope(
          onPop: () {
            return Future.value(false);
          },
          child: AlertDialog(
            title: Text(title ?? ''),
            content: Text(message!),
            actions: [
              FlatButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onAccept?.call();
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      }
    );
  }

  static void confirm(BuildContext context,
      {String? title,
      String? message,
      VoidCallback? onAccept,
      VoidCallback? onDecline}) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) {
          return WillPopScope(
            onWillPop: () {
              return Future.value(false);
            },
            child: AlertDialog(
              title: Text(title ?? ''),
              content: Text(message!),
              actions: [
                FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onDecline?.call();
                  },
                  child: Text(
                    Utils.getLocale(context)!.cancel,
                    style: TextStyle(
                      color: Colors.red,
                    ),
                  ),
                ),
                FlatButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onAccept?.call();
                  },
                  child: Text('OK'),
                ),
              ],
            ),
          );
        });
  }

  static Future<Null> showLoading(BuildContext context,
      {String textContent = '',
      Color color = Colors.white,
      double loadingIndicatorSize = 15.0,
      double strokeWidth = 2.0}) {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return new Material(
              color: Colors.transparent,
              child: WillPopScope(
                onWillPop: () => new Future.value(false),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        width: loadingIndicatorSize,
                        height: loadingIndicatorSize,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(color),
                          strokeWidth: strokeWidth,
                        ),
                      ),
                      Padding(
                          padding:
                              EdgeInsets.symmetric(horizontal: 5, vertical: 0)),
                      Text(
                        textContent,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: color),
                      )
                    ],
                  ),
                ),
              ));
        });
  }

  static Future<File?> resizeAvatar(File originImage) async {
    if (originImage == null) return null;
    final originBytes = originImage.readAsBytesSync();
    final threshold = 1024 * 1024 / 3; // 0.3MB
    if (originBytes.length / threshold <= 1) {
      return originImage;
    }

    img.Image? image = img.decodeImage(originBytes);
    img.Image resized = img.copyResize(image!, width: 120);
    return MemoryFileSystem()
        .file('${DateTime.now().millisecondsSinceEpoch}.jpg')
      ..writeAsBytesSync(img.encodeJpg(resized));
  }

  static Future<File?> resizeImage(File originImage) async {
    if (originImage == null) return null;
    final originBytes = originImage.readAsBytesSync();
    final threshold = 1024 * 1024 / 2; // 0.5MB
    if (originBytes.length / threshold <= 1) {
      return originImage;
    }

    img.Image? image = img.decodeImage(originBytes);
    img.Image resized = img.copyResize(image!, height: 500);
    final encoded = img.encodeJpg(resized);
    return MemoryFileSystem()
        .file('${DateTime.now().millisecondsSinceEpoch}.jpg')
      ..writeAsBytesSync(encoded);
  }

  static bool isEmailValid(String email) {
    String p =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regExp = new RegExp(p);
    return regExp.hasMatch(email);
  }

  static bool isPhoneNumberValid(String phoneNumber) {
    String p = r'^(?:[+0])?[0-9]{10,12}$';
    RegExp regExp = new RegExp(p);
    return regExp.hasMatch(phoneNumber);
  }

  static Future<String> editScreen(BuildContext context,
      {String? currentValue,
      required String title,
      required String hintText,
      required int length,
      ValidationCallback? onValidate}) async {
    return await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => EditScreen(
            currentValue: currentValue,
            title: title,
            hintText: hintText,
            length: length,
            onValidate: onValidate)));
  }

  static Future<String> selectArea(BuildContext context,
      {required AreaTarget target,
      String? currentProvince,
      String? currentDistrict,
      String? currentWards,
      String? title}) async {
    return await Navigator.of(context).push(MaterialPageRoute(
        builder: (context) => SelectAreaScreen(
            target: target,
            title: title!,
            currentProvince: currentProvince,
            currentDistrict: currentDistrict,
            currentWards: currentWards)));
  }

  /// Get list of province Vietnam
  static Future<List<Province>?> getProvinceList() async {
    var response = await http.get(VietnamAreas.province as Uri);
    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      return jsonResponse.map((json) => Province.fromJson(json)).toList();
    }

    return null;
  }

  /// Get list of district
  static Future<List<District>?> getDistrictList({int? provinceId}) async {
    var response = await http.get(VietnamAreas.district as Uri);
    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      var result = jsonResponse.map((json) => District.fromJson(json)).toList();
      if (provinceId != null && provinceId > 0) {
        result.removeWhere((district) => district.provinceId != provinceId);
      }

      return result;
    }

    return null;
  }

  /// Get list of wards
  static Future<List<Wards>?> getWardsList({int? districtId}) async {
    var response = await http.get(VietnamAreas.wards as Uri);
    if (response.statusCode == 200) {
      List<dynamic> jsonResponse = json.decode(response.body);
      var result = jsonResponse.map((json) => Wards.fromJson(json)).toList();
      if (districtId != null && districtId > 0) {
        result.removeWhere((wards) => wards.districtId != districtId);
      }

      return result;
    }

    return null;
  }

  static String getUserTypeString(BuildContext context, int userType) {
    String result = '';
    switch (userType) {
      case UserType.admin:
        result = Utils.getLocale(context)!.userTypeAdmin;
        break;
      case UserType.saleStaff:
        result = Utils.getLocale(context)!.userTypeSaleStaff;
        break;
      case UserType.chineseWarehouseStaff:
        result = Utils.getLocale(context)!.userTypeChineseSaleStaff;
        break;
      case UserType.uongbiWarehouseStaff:
        result = Utils.getLocale(context)!.userTypeUongBiSaleStaff;
        break;
      case UserType.hanoiWarehouseStaff:
        result = Utils.getLocale(context)!.userTypeHanoiSaleStaff;
        break;
      case UserType.saigonWarehouseStaff:
        result = Utils.getLocale(context)!.userTypeSaigonSaleStaff;
        break;
      case UserType.customer:
        result = Utils.getLocale(context)!.userTypeCustomer;
        break;
    }

    return result;
  }

  static String getOrderStatusString(BuildContext context, int orderStatus) {
    String result = '';
    switch (orderStatus) {
      case OrderStatus.newlyCreated:
        result = Utils.getLocale(context)!.orderStatusNew;
        break;
      case OrderStatus.aborted:
        result = Utils.getLocale(context)!.orderStatusAbort;
        break;
      case OrderStatus.chineseWarehoused:
        result = Utils.getLocale(context)!.orderStatusChineseWarehoused;
        break;
      case OrderStatus.pendingWoodenPacking:
        result = Utils.getLocale(context)!.orderStatusPendingBoxedWood;
        break;
      case OrderStatus.chineseShippedOut:
        result = Utils.getLocale(context)!.orderStatusChineseShippedOut;
        break;
      case OrderStatus.uongbiWarehoused:
        result = Utils.getLocale(context)!.orderStatusUongBiWarehoused;
        break;
      case OrderStatus.hanoiWarehoused:
        result = Utils.getLocale(context)!.orderStatusHanoiWarehoused;
        break;
      case OrderStatus.saigonWarehoused:
        result = Utils.getLocale(context)!.orderStatusSaigonWarehoused;
        break;
      case OrderStatus.outputUongBi:
        result = Utils.getLocale(context)!.orderStatusOutputUongBi;
        break;
      case OrderStatus.outputHaNoi:
        result = Utils.getLocale(context)!.orderStatusOutputHaNoi;
        break;
      case OrderStatus.outputSaiGon:
        result = Utils.getLocale(context)!.orderStatusOutputSaiGon;
        break;
      case OrderStatus.delivery:
        result = Utils.getLocale(context)!.orderStatusDelivery;
        break;
      case OrderStatus.delivered:
        result = Utils.getLocale(context)!.orderStatusDelivered;
        break;
      case OrderStatus.completed:
        result = Utils.getLocale(context)!.orderStatusCompleted;
        break;
    }

    return result;
  }

  static String getTrackingStatusString(
      BuildContext context, int trackingStatus) {
    String result = '';
    switch (trackingStatus) {
      case ActionType.createNewOrder:
        result = Utils.getLocale(context)!.trackingStatusNew;
        break;
      case ActionType.cancelOrder:
        result = Utils.getLocale(context)!.trackingStatusCancel;
        break;
      case ActionType.chineseWarehouse:
        result = Utils.getLocale(context)!.trackingStatusChineseWarehoused;
        break;
      case ActionType.chineseStockOut:
        result = Utils.getLocale(context)!.trackingStatusChineseShippedOut;
        break;
      case ActionType.sendConfirmationWoodenPacking:
        result = Utils.getLocale(context)!.trackingStatusSendBoxedRequest;
        break;
      case ActionType.confirmWoodenPacking:
        result = Utils.getLocale(context)!.trackingStatusConfirmedBoxedRequest;
        break;
      case ActionType.uongbiWarehouse:
        result = Utils.getLocale(context)!.trackingStatusUongBiWarehoused;
        break;
      case ActionType.hanoiWarehouse:
        result = Utils.getLocale(context)!.trackingStatusHaNoiWarehoused;
        break;
      case ActionType.saigonWarehouse:
        result = Utils.getLocale(context)!.trackingStatusSaiGonWarehoused;
        break;
      case ActionType.outputUongBi:
        result = Utils.getLocale(context)!.trackingStatusOutputUongBi;
        break;
      case ActionType.outputHaNoi:
        result = Utils.getLocale(context)!.trackingStatusOutputHaNoi;
        break;
      case ActionType.outputSaiGon:
        result = Utils.getLocale(context)!.trackingStatusOutputSaiGon;
        break;
      case ActionType.delivery:
        result = Utils.getLocale(context)!.trackingStatusDelivery;
        break;
      case ActionType.delivered:
        result = Utils.getLocale(context)!.trackingStatusDelivered;
        break;
      case ActionType.completed:
        result = Utils.getLocale(context)!.trackingStatusCompleted;
        break;
    }

    return result;
  }

  static String getGoodsTypeString(BuildContext context, int goodsType) {
    String result = '';
    switch (goodsType) {
      case GoodsType.fake:
        result = Utils.getLocale(context)!.goodsTypeFake;
        break;
      case GoodsType.cosmetic:
        result = Utils.getLocale(context)!.goodsTypeCosmetic;
        break;
      case GoodsType.food:
        result = Utils.getLocale(context)!.goodsTypeFood;
        break;
      case GoodsType.medicine:
        result = Utils.getLocale(context)!.goodsTypeMedicine;
        break;
      case GoodsType.liquid:
        result = Utils.getLocale(context)!.goodsTypeLiquid;
        break;
      case GoodsType.fragile:
        result = Utils.getLocale(context)!.goodsTypeFragile;
        break;
      case GoodsType.clothes:
        result = Utils.getLocale(context)!.goodsTypeClothes;
        break;
      case GoodsType.electronic:
        result = Utils.getLocale(context)!.goodsTypeElectronic;
        break;
      case GoodsType.prepackagedGroceries:
        result = Utils.getLocale(context)!.goodsTypePrepackedGroceries;
        break;
      case GoodsType.normal:
        result = Utils.getLocale(context)!.goodsTypeNormal;
        break;
      case GoodsType.superHeavy:
        result = Utils.getLocale(context)!.goodsTypeSuperHeavy;
        break;
      case GoodsType.special:
        result = Utils.getLocale(context)!.goodsTypeSpecial;
        break;
    }

    return result;
  }

  static String getMoneyString(double price) {
    if (price == null) price = 0;
    return NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(
            price) /* +
        ' (' +
        NumberFormat.currency(locale: 'zh_CN').format(price / 3400) +
        ')'*/
        ;
  }

  static bool canEditOrders(User user, Order order) {
    if (user == null || order == null) return false;

    if (user.userType == UserType.customer &&
        ![OrderStatus.delivery, OrderStatus.delivered, OrderStatus.completed]
            .contains(order.orderStatus)) {
      return true;
    }

    if ([
      OrderStatus.chineseShippedOut,
      OrderStatus.uongbiWarehoused,
      OrderStatus.hanoiWarehoused,
      OrderStatus.saigonWarehoused,
      OrderStatus.outputUongBi,
      OrderStatus.outputHaNoi,
      OrderStatus.outputSaiGon,
      OrderStatus.delivery,
      OrderStatus.delivered,
      OrderStatus.completed
    ].contains(order.orderStatus)) return false;

    if (user.userType == UserType.customer &&
        ![OrderStatus.newlyCreated, OrderStatus.pendingWoodenPacking]
            .contains(order.orderStatus)) return false;

    if (order.orderStatus == OrderStatus.newlyCreated ||
        order.orderStatus == OrderStatus.pendingWoodenPacking) return true;
    if (order.orderStatus == OrderStatus.aborted) return false;
    // only chinese warehouse staff can be edit
    if (order.orderStatus == OrderStatus.chineseWarehoused &&
        user.userType != UserType.chineseWarehouseStaff) return false;
    // only Uong Bi warehouse staff can be edit
    if (order.orderStatus == OrderStatus.chineseShippedOut &&
        user.userType != UserType.uongbiWarehouseStaff) return false;

    return true;
  }

  static Future<bool> isUrlValid(String url) async {
    final c = Completer<bool>();
    HttpUtil.get(url, onResponse: (resp) {
      c.complete(resp != null &&
          resp.statusCode == 200 &&
          (resp.bodyBytes != null && resp.bodyBytes.isNotEmpty));
    }, onTimeout: () {
      c.complete(false);
    });

    return c.future;
  }

  static List<AllowAction> getAllowActionList(User user, Order order) {
    final List<AllowAction> list = [];
    if (user == null || order == null) return list;

    // prepare...
    bool isCustomer = user.userType == UserType.customer;
    bool isChineseWarehouseStaff =
        user.userType == UserType.chineseWarehouseStaff;
    bool isUongBiWarehouseStaff =
        user.userType == UserType.uongbiWarehouseStaff;
    bool isHaNoiWarehouseStaff = user.userType == UserType.hanoiWarehouseStaff;
    bool isSaiGonWarehouseStaff =
        user.userType == UserType.saigonWarehouseStaff;
    bool isSaleStaff = user.userType == UserType.saleStaff;
    bool isNewOrder = OrderStatus.newlyCreated == order.orderStatus;
    bool isSaleUser = user.username == order.saleId;

    // the last point => do nothing
    /*if (OrderStatus.hanoiWarehoused == order.orderStatus ||
        OrderStatus.saigonWarehoused == order.orderStatus) {
      return list;
    }*/

    // import Chinese
    if (isChineseWarehouseStaff && isNewOrder) {
      list.add(AllowAction.importChineseWarehouse);
    }

    // import Uong Bi
    if (isUongBiWarehouseStaff &&
        (OrderStatus.chineseShippedOut == order.orderStatus ||
            OrderStatus.outputHaNoi == order.orderStatus ||
            OrderStatus.outputSaiGon == order.orderStatus)) {
      list.add(AllowAction.importUongBiWarehouse);
    }

    // import Ha Noi
    if (isHaNoiWarehouseStaff &&
        (OrderStatus.chineseShippedOut == order.orderStatus ||
            OrderStatus.outputUongBi == order.orderStatus ||
            OrderStatus.outputSaiGon == order.orderStatus)) {
      list.add(AllowAction.importHaNoiWarehouse);
    }

    // import Sai Gon
    if (isSaiGonWarehouseStaff &&
        (OrderStatus.chineseShippedOut == order.orderStatus ||
            OrderStatus.outputUongBi == order.orderStatus ||
            OrderStatus.outputHaNoi == order.orderStatus)) {
      list.add(AllowAction.importSaiGonWarehouse);
    }

    // export Chinese
    if (isChineseWarehouseStaff &&
        OrderStatus.chineseWarehoused == order.orderStatus) {
      list.add(AllowAction.exportChineseWarehouse);
    }

    // output & delivery Uong Bi
    if (isUongBiWarehouseStaff &&
        OrderStatus.uongbiWarehoused == order.orderStatus) {
      list.add(AllowAction.outputUongBi);
      list.add(AllowAction.delivery);
    }

    // output & delivery Ha Noi
    if (isHaNoiWarehouseStaff &&
        OrderStatus.hanoiWarehoused == order.orderStatus) {
      list.add(AllowAction.outputHaNoi);
      list.add(AllowAction.delivery);
    }

    // output & delivery Sai Gon
    if (isSaiGonWarehouseStaff &&
        OrderStatus.saigonWarehoused == order.orderStatus) {
      list.add(AllowAction.outputSaiGon);
      list.add(AllowAction.delivery);
    }

    // delivered
    if ((isUongBiWarehouseStaff ||
            isHaNoiWarehouseStaff ||
            isSaiGonWarehouseStaff) &&
        OrderStatus.delivery == order.orderStatus) {
      list.add(AllowAction.delivered);
      list.add(AllowAction.complete);
    }

    // complete
    if ((isUongBiWarehouseStaff ||
            isHaNoiWarehouseStaff ||
            isSaiGonWarehouseStaff) &&
        OrderStatus.delivered == order.orderStatus) {
      list.add(AllowAction.complete);
    }

    // confirm wooden packing
    if ((isCustomer && user.username == order.customerId ||
            (isSaleStaff && isSaleUser)) &&
        OrderStatus.pendingWoodenPacking == order.orderStatus) {
      list.add(AllowAction.confirmWoodenPacking);
    }

    // edit
    if ((isCustomer &&
            ![
              OrderStatus.delivery,
              OrderStatus.delivered,
              OrderStatus.completed
            ].contains(order.orderStatus)) ||
        ((isCustomer ||
                ((isSaleStaff ||
                        isChineseWarehouseStaff ||
                        isUongBiWarehouseStaff ||
                        isHaNoiWarehouseStaff ||
                        isSaiGonWarehouseStaff) &&
                    isSaleUser)) &&
            isNewOrder) ||
        (isChineseWarehouseStaff &&
            [OrderStatus.newlyCreated, OrderStatus.chineseWarehoused]
                    .indexOf(order.orderStatus) >
                -1)) {
      list.add(AllowAction.edit);
    } else if (isChineseWarehouseStaff &&
        OrderStatus.chineseWarehoused == order.orderStatus) {
      list.add(AllowAction.edit);
    }

    // cancel
    if ((isCustomer ||
            ((isSaleStaff ||
                    isChineseWarehouseStaff ||
                    isUongBiWarehouseStaff ||
                    isHaNoiWarehouseStaff ||
                    isSaiGonWarehouseStaff) &&
                isSaleUser)) &&
        (isNewOrder || OrderStatus.pendingWoodenPacking == order.orderStatus)) {
      list.add(AllowAction.cancel);
    }

    return list;
  }

  static void updatePop(int stacks) {
    SessionUtil.instance().canPop = stacks;
  }

  static void popToFirstScreen(BuildContext context) {
    if (SessionUtil.instance().canPop <= 0) return;
    int count = 0;
    Navigator.of(context)
        .popUntil((route) => count++ == SessionUtil.instance().canPop);
  }

  static Future<ConfirmationStatus?> showConfirmStatusDialog(
      BuildContext context,
      {required Order forOrder,
      bool cancelOrder = false,
      bool output = false,
      bool hidePackCount = false}) async {
    return await showDialog<ConfirmationStatus>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ConfirmOrderStatusWidget(
        forOrder: forOrder,
        cancelOrder: cancelOrder,
        output: output,
        hidePackCount: hidePackCount,
      ),
    );
  }

  static String changeAlias(String alias) {
    var str = alias;
    str = str.toLowerCase();
    str = str.replaceAll(RegExp(r'à|á|ạ|ả|ã|â|ầ|ấ|ậ|ẩ|ẫ|ă|ằ|ắ|ặ|ẳ|ẵ'), 'a');
    str = str.replaceAll(RegExp(r'è|é|ẹ|ẻ|ẽ|ê|ề|ế|ệ|ể|ễ'), 'e');
    str = str.replaceAll(RegExp(r'ì|í|ị|ỉ|ĩ'), 'i');
    str = str.replaceAll(RegExp(r'ò|ó|ọ|ỏ|õ|ô|ồ|ố|ộ|ổ|ỗ|ơ|ờ|ớ|ợ|ở|ỡ'), 'o');
    str = str.replaceAll(RegExp(r'ù|ú|ụ|ủ|ũ|ư|ừ|ứ|ự|ử|ữ'), 'u');
    str = str.replaceAll(RegExp(r'ỳ|ý|ỵ|ỷ|ỹ'), 'y');
    str = str.replaceAll(RegExp(r'đ'), 'd');
    str = str.replaceAll(RegExp(r'[^\w\s]+'), "");
    str = str.trim();
    return str;
  }

  static Future<void> removeOrderFromBloc(
      BuildContext context, Order order) async {
    if (context == null || order == null) return;
    User user = SessionUtil.instance().user;
    if (user == null) return;

    bool needRemove = await compute(
        _computeOrderRemove, <String, dynamic>{'user': user, 'order': order});
    if (!needRemove) return;
    AppProvider.of(context)?.state.orderBloc.removeOrder(order);
  }

  static bool _computeOrderRemove(Map<String, dynamic> p) {
    User user = p['user'];
    Order order = p['order'];

    bool isChineseStaff = user.userType == UserType.chineseWarehouseStaff;
    //bool isCustomer = user.userType == UserType.customer;
    //bool isSaleStaff = user.userType == UserType.saleStaff;
    bool isUongBiStaff = user.userType == UserType.uongbiWarehouseStaff;
    bool isHaNoiStaff = user.userType == UserType.hanoiWarehouseStaff;
    bool isSaiGonStaff = user.userType == UserType.saigonWarehouseStaff;

    bool needRemove = false;
    switch (order.orderStatus) {
      case OrderStatus.aborted:
        needRemove =
            isChineseStaff || isUongBiStaff || isHaNoiStaff || isSaiGonStaff;
        break;
      case OrderStatus.chineseWarehoused:
        needRemove = isUongBiStaff || isHaNoiStaff || isSaiGonStaff;
        break;
      case OrderStatus.chineseShippedOut:
        needRemove = isChineseStaff;
        break;
      case OrderStatus.uongbiWarehoused:
        needRemove = isChineseStaff || isHaNoiStaff || isSaiGonStaff;
        break;
      case OrderStatus.outputUongBi:
        needRemove = isChineseStaff || isUongBiStaff;
        break;
      case OrderStatus.hanoiWarehoused:
        needRemove = isChineseStaff || isUongBiStaff || isSaiGonStaff;
        break;
      case OrderStatus.outputHaNoi:
        needRemove = isChineseStaff || isHaNoiStaff;
        break;
      case OrderStatus.saigonWarehoused:
        needRemove = isChineseStaff || isUongBiStaff || isHaNoiStaff;
        break;
      case OrderStatus.outputSaiGon:
        needRemove = isChineseStaff || isSaiGonStaff;
        break;
      case OrderStatus.delivery:
        needRemove = isChineseStaff;
        break;
      case OrderStatus.delivered:
        needRemove = isChineseStaff;
        break;
      case OrderStatus.completed:
        needRemove =
            isChineseStaff || isUongBiStaff || isHaNoiStaff || isSaiGonStaff;
        break;
    }

    return needRemove;
  }

  static Future<String> getCurrentLocale() async {
    String? currentLocale;
    try {
      currentLocale = await Devicelocale.currentLocale;
      if (currentLocale!.contains('-'))
        currentLocale = currentLocale.split('-')[0];
      else if (currentLocale.contains('_'))
        currentLocale = currentLocale.split('_')[0];
    } on PlatformException {
      currentLocale = 'en';
    }

    return currentLocale.split('_')[0];
  }

  static Future<String> getAppCurrentLocale() async {
    var prefs = await SharedPreferences.getInstance();
    return prefs.getString(PrefsKey.languageCode) ??
        await Utils.getCurrentLocale();
  }

  static RegExp _regex = RegExp(r'DL\d{2}');

  static String getDisplayOrderId(String orderId) {
    if (Utils.isNullOrEmpty(orderId)) return '';

    return orderId.replaceFirst(_regex, 'DL');
  }
}

class ConfirmationStatus {
  int? packCount;
  String? note;
  String? nextWarehouse;
  List<File>? files;

  ConfirmationStatus(
      {this.packCount, this.note, this.nextWarehouse, this.files});

  @override
  String toString() {
    return 'ConfirmationStatus{packCount: $packCount, note: $note, nextWarehouse: $nextWarehouse, files: $files}';
  }
}
