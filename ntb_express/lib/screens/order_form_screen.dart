import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';

/// create/update the order
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:intl/intl.dart';
import 'package:ntbexpress/model/address.dart';
import 'package:ntbexpress/model/fee_item.dart';
import 'package:ntbexpress/model/file_holder.dart';
import 'package:ntbexpress/model/order.dart';
import 'package:ntbexpress/model/promotion.dart';
import 'package:ntbexpress/model/user.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/extensions.dart';
import 'package:ntbexpress/util/http_util.dart';
import 'package:ntbexpress/util/price_calculation_util.dart';
import 'package:ntbexpress/util/select_address_screen.dart';
import 'package:ntbexpress/util/select_promotion_screen.dart';
import 'package:ntbexpress/util/select_user_screen.dart';
import 'package:ntbexpress/util/session_util.dart';
import 'package:ntbexpress/util/utils.dart';
import 'package:ntbexpress/widgets/app_provider.dart';
import 'package:ntbexpress/widgets/currency_swap_input.dart';
import 'package:ntbexpress/widgets/image_picker_widget.dart';

class OrderFormScreen extends StatefulWidget {
  final Order order;
  final bool update;

  OrderFormScreen({required this.order, this.update = false});

  @override
  _OrderFormScreenState createState() => _OrderFormScreenState();
}

class _OrderFormScreenState extends State<OrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _goodsTypeDescrController = TextEditingController();
  final _intTrackNoController = TextEditingController();
  final _packCountController = TextEditingController();
  final _weightController = TextEditingController();
  final _sizeController = TextEditingController();
  final _intFeeController = TextEditingController();
  final _extFeeController = TextEditingController();
  final _noteController = TextEditingController();
  final _payOnBehalfController = TextEditingController();
  final _repackFeeController = TextEditingController();
  final _feeByWeightController = TextEditingController();
  final _feeBySizeController = TextEditingController();
  final _feeBySizeDealerController = TextEditingController();
  final _feeByWeightDealerController = TextEditingController();

  final _goodsTypeDescrFocusNode = FocusNode();
  final _intTrackNoFocusNode = FocusNode();
  final _packCountFocusNode = FocusNode();
  final _weightFocusNode = FocusNode();
  final _sizeFocusNode = FocusNode();
  final _intFeeFocusNode = FocusNode();
  final _extFeeFocusNode = FocusNode();
  final _noteFocusNode = FocusNode();
  final _payOnBehalfFocusNode = FocusNode();

  final _filesController = ImagePickerController();

  final List<FileHolder> _uploadImages = [];
  final List<FileHolder> _removeImages = [];
  double _totalFee = 0;
  double _totalFeeOrigin = 0;
  late Order _order;
  late User _customer;
  late Address _address;
  late Promotion _promotion;
  int _goodsType = GoodsType.normal;
  int _status = OrderStatus.newlyCreated;
  bool _boxedWood = false;
  PriceType _priceType = PriceType.normal;
  double _minAgentWeightFee = 0;
  double _minAgentSizeFee = 0;
  double _agentTotalFee = 0;

  bool get isChineseWarehouseStaff =>
      SessionUtil.instance().user.userType == UserType.chineseWarehouseStaff;

  bool get isSaleStaff =>
      SessionUtil.instance().user.userType == UserType.saleStaff;

  bool get isNotCustomer =>
      SessionUtil.instance().user.userType != UserType.customer;

  String get _getTotalFeeText =>
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(_totalFee);

  String get _getAgentTotalFeeText =>
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ')
          .format(_agentTotalFee);

  User get currentUser => SessionUtil.instance().user;

  bool get canEditAddress => !widget.update
      ? true
      : currentUser.username == _order?.customerId ||
          (currentUser.username == _order?.saleId);

  bool get canEditCustomer => !widget.update
      ? true
      : currentUser.username == _order?.customerId ||
          (currentUser.username == _order?.saleId);

  TextStyle get textStyle => TextStyle(
      color: !isChineseWarehouseStaff && isNotCustomer
          ? Colors.black
          : Theme.of(context).disabledColor);

  bool get isAgentFeeFieldsEnabled =>
      _customer != null &&
      _address != null &&
      !Utils.isNullOrEmpty(_weightController.text) &&
      !Utils.isNullOrEmpty(_sizeController.text) &&
      (_order != null &&
          ![OrderStatus.delivery, OrderStatus.delivered, OrderStatus.completed]
              .contains(_order.orderStatus) &&
          !isSaleStaff);

  bool get isAllowEditAgentFee =>
      currentUser.userType == UserType.admin ||
      currentUser.userType == UserType.customer ||
      isSaleStaff;

  @override
  void initState() {
    super.initState();
    _getFeeTable();
    if (widget.order != null) {
      _order = Order.clone(widget.order);
      _status = _order.orderStatus;
      _goodsType = _order.goodsType;
      _customer = _order.customerDTO!;
      _address = _order.addressDTO!;
      _goodsTypeDescrController.text = _order.goodsDescr;
      _intTrackNoController.text = _order.intTrackNo;
      _packCountController.text = _order.packCount!.toString();
      _weightController.text = _order.weight!.toString();
      _sizeController.text = _order.size!.toString();
      _boxedWood = _order.needRepack == 1;
      _payOnBehalfController.text = _order.payOnBehalf!.toString();
      _repackFeeController.text = _order.repackFee!.toString();
      _intFeeController.text = _order.intFee!.toString();
      _extFeeController.text = _order.extFee!.toString();
      _noteController.text = _order.note!;
      _parseImages();
      _promotion = (_order.promotionDTO == null
          ? null
          : Promotion.fromJson(_order.promotionDTO!.toJson()))!;
      _totalFee = _order.totalFeeDaiLong ?? 0;
      _feeBySizeController.text =
          _order.feeBySize == null ? '0' : _order.feeBySize.toString();
      _feeByWeightController.text =
          _order.feeByWeight == null ? '0' : _order.feeByWeight.toString();
      if (_order.feeBySize != null && _order.feeBySize > 0 ||
          _order.feeByWeight != null && _order.feeByWeight > 0) {
        _priceType = PriceType.fixed;
      }

      Map<String, double> fees = PriceCalculationUtil.getAgentFee(
          address: _order.addressDTO!,
          goodsType: _order.goodsType,
          weight: _order.weight,
          size: _order.size,
          feeBySize: _order.feeBySize,
          feeByWeight: _order.feeByWeight);

      _minAgentWeightFee = fees["weight"]!;
      _minAgentSizeFee = fees["size"]!;

      _feeByWeightDealerController.text = _order.feeByWeightDealer == null
          ? '0'
          : _order.feeByWeightDealer.toString();
      _feeBySizeDealerController.text = _order.feeBySizeDealer == null
          ? '0'
          : _order.feeBySizeDealer.toString();
      _agentTotalFee = _order.totalFee ?? 0;
      //Future.delayed(const Duration(milliseconds: 500), _updateTotalFee);
    }

    if (currentUser.userType == UserType.customer) {
      _customer = User.clone(currentUser);
    }

    _payOnBehalfController.addListener(_updateTotalFee);
    _repackFeeController.addListener(_updateTotalFee);
    _intFeeController.addListener(_updateTotalFee);
    _extFeeController.addListener(_updateTotalFee);
    _feeByWeightController.addListener(_updateTotalFee);
    _feeBySizeController.addListener(_updateTotalFee);
  }

  @override
  void dispose() {
    _payOnBehalfController.removeListener(_updateTotalFee);
    _repackFeeController.removeListener(_updateTotalFee);
    _intFeeController.removeListener(_updateTotalFee);
    _extFeeController.removeListener(_updateTotalFee);
    _feeByWeightController.removeListener(_updateTotalFee);
    _feeBySizeController.removeListener(_updateTotalFee);

    _goodsTypeDescrFocusNode.dispose();
    _intTrackNoFocusNode.dispose();
    _packCountFocusNode.dispose();
    _weightFocusNode.dispose();
    _sizeFocusNode.dispose();
    _intFeeFocusNode.dispose();
    _extFeeFocusNode.dispose();
    _noteFocusNode.dispose();
    _payOnBehalfFocusNode.dispose();

    _goodsTypeDescrController.dispose();
    _intTrackNoController.dispose();
    _packCountController.dispose();
    _weightController.dispose();
    _sizeController.dispose();
    _intFeeController.dispose();
    _extFeeController.dispose();
    _noteController.dispose();
    _payOnBehalfController.dispose();
    _repackFeeController.dispose();
    _feeByWeightController.dispose();
    _feeBySizeController.dispose();
    _feeByWeightDealerController.dispose();
    _feeBySizeDealerController.dispose();

    super.dispose();
  }

  Future<void> _parseImages() async {
    if (_order.tccoFileDTOS != null) {
      for (var f in _order.tccoFileDTOS!) {
        if (f == null) continue;
        final url = '${ApiUrls.instance().baseUrl}/${f.flePath}';
        if (!(await Utils.isUrlValid(url))) continue;

        if (widget.update) {
          _filesController.add(FileHolder(
              key: f.atchFleSeq, isNetworkImage: true, fileUrl: url));
        } else {
          File file = await HttpUtil.download(url);
          _filesController.add(FileHolder(file: file));
        }
      }
    }
  }

  void _updateTotalFee() {
    _updateExtFee();
    _getFormData();
    setState(() {
      _updateAgentTotalFee();

      _totalFee = PriceCalculationUtil.calculatePrice(
          repackFee: _order.repackFee,
          payOnBehalf: _order.payOnBehalf,
          intFee: _order.intFee,
          extFee: _order.extFee);

      _totalFeeOrigin = PriceCalculationUtil.calculatePrice(
          repackFee: _order.repackFee,
          payOnBehalf: _order.payOnBehalf,
          intFee: _order.intFee,
          extFee: PriceCalculationUtil.calculateExtFee(
              address: _address,
              goodsType: _order.goodsType,
              size: _order.size,
              weight: _order.weight));
    });
  }

  void _updateAgentTotalFee() {
    _agentTotalFee = PriceCalculationUtil.calculatePrice(
        repackFee: _order.repackFee,
        payOnBehalf: _order.payOnBehalf,
        intFee: _order.intFee,
        extFee: _order.weight * _order.feeByWeightDealer +
            _order.size * _order.feeBySizeDealer);
  }

  void _updateAgentFee() {
    _formKey.currentState!.validate();
    _getFormData();
    _updateAgentTotalFee();
    setState(() {});
  }

  void _updateExtFee() {
    //_promotion = null; // reset promotion when the price has changed, user need reselect promotion!!!
    _getFormData();
    double price = PriceCalculationUtil.calculateExtFee(
        address: _order.addressDTO!,
        goodsType: _order.goodsType,
        size: _order.size,
        weight: _order.weight,
        feeBySize: _order.feeBySize,
        feeByWeight: _order.feeByWeight);

    _extFeeController.text = price.toString() ?? '0';

    Map<String, double> fees = PriceCalculationUtil.getAgentFee(
        address: _order.addressDTO!,
        goodsType: _order.goodsType,
        weight: _order.weight,
        size: _order.size,
        feeBySize: _order.feeBySize,
        feeByWeight: _order.feeByWeight);

    _minAgentWeightFee = fees["weight"]!;
    _minAgentSizeFee = fees["size"]!;
    _feeByWeightDealerController.text = _minAgentWeightFee.toString();
    _feeBySizeDealerController.text = _minAgentSizeFee.toString();

    setState(() {});
  }

  void _getFeeTable() {
    HttpUtil.get(
      ApiUrls.instance().getFeeTableUrl(),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      onResponse: (resp) {
        if (resp != null && resp.statusCode == 200) {
          List<dynamic> json = jsonDecode(resp.body);
          if (json != null) {
            feeTable
              ..clear()
              ..addAll(json.map((e) => FeeItem.fromJson(e)).toList());
          }
        }
      },
      onTimeout: () {},
    );
  }

  void _getFormData() {
    if (_order == null) {
      _order = Order(tccoFileDTOS: []);
    }
    _order.addressDTO = _address;
    _order.addressId = _address.addressId!;
    _order.customerId = _customer.username!;
    _order.customerDTO = _customer;
    _order.goodsType = _goodsType;
    _order.orderStatus = _status;
    _order.goodsDescr = _goodsTypeDescrController.text.trim();
    _order.intTrackNo = _intTrackNoController.text.trim();
    _order.packCount = _packCountController.text.trim().parseInt();
    _order.weight = _weightController.text.trim().parseDouble();
    _order.size = _sizeController.text.trim().parseDouble();
    _order.needRepack = _boxedWood ? 1 : 0;
    _order.repackFee = _repackFeeController.text.trim().parseDouble();
    _order.payOnBehalf = _payOnBehalfController.text.trim().parseDouble();
    _order.intFee = _intFeeController.text.trim().parseDouble();
    _order.extFee = _extFeeController.text.trim().parseDouble();
    _order.note = _noteController.text.trim();
    if (_removeImages.isNotEmpty) {
      if (_order.tccoFileDTOS == null) {
        _order.tccoFileDTOS = [];
      }

      _removeImages.forEach((e) {
        _order.tccoFileDTOS?.removeWhere((f) => e.key == f?.atchFleSeq);
      });
    }
    _order.promotionId = _promotion?.promotionId;
    _order.promotionDTO = _promotion;
    _order.feeBySize =
        _feeBySizeController?.text?.toString()?.parseDouble() ?? 0;
    _order.feeByWeight =
        _feeByWeightController?.text?.toString()?.parseDouble() ?? 0;
    _order.totalFee = _agentTotalFee;
    _order.totalFeeOriginal = _totalFeeOrigin;
    _order.feeByWeightDealer =
        _feeByWeightDealerController.text.trim().parseDouble();
    _order.feeBySizeDealer =
        _feeBySizeDealerController.text.trim().parseDouble();
    _order.totalFeeDaiLong = _totalFee;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(_order),
            icon: Icon(Icons.close),
          ),
          title: Text(
              '${widget.update ? Utils.getLocale(context)?.edit : Utils.getLocale(context)?.add} ${Utils.getLocale(context)?.order.toLowerCase()}'),
          actions: [
            IconButton(
              onPressed: _saveOrder,
              icon: Icon(Icons.done),
            )
          ],
        ),
        body: SafeArea(
          child: Container(
            color: Utils.backgroundColor,
            //padding: const EdgeInsets.only(left: 10.0, top: 10.0, right: 10.0),
            constraints: const BoxConstraints.expand(),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Scrollbar(
                      child: SingleChildScrollView(
                        child: Container(
                          padding: const EdgeInsets.only(
                              left: 10.0, top: 10.0, right: 10.0),
                          child: Column(
                            children: [
                              Visibility(
                                visible: SessionUtil.instance().user.userType !=
                                        UserType.customer &&
                                    !isChineseWarehouseStaff,
                                child: ListTile(
                                  enabled: isNotCustomer,
                                  onTap: !canEditCustomer
                                      ? null
                                      : () async {
                                          _customer =
                                              await Navigator.of(context).push(
                                                  MaterialPageRoute(
                                                      builder: (context) =>
                                                          SelectUserScreen(
                                                              currentUser,
                                                              _customer)));

                                          // _address = null;
                                          _totalFee = 0;
                                          _totalFeeOrigin = 0;

                                          // clear promotion
                                          if (_promotion != null) {
                                            // _promotion = null;
                                            _priceType = PriceType.normal;
                                            _feeByWeightController.clear();
                                            _feeBySizeController.clear();
                                            _updateTotalFee();
                                          }

                                          setState(() {});
                                        },
                                  contentPadding:
                                      const EdgeInsets.only(left: 0.0),
                                  title: Text(
                                      '${Utils.getLocale(context)?.customer}'),
                                  subtitle: _customer != null
                                      ? ListTile(
                                          title: Text('${_customer.fullName}'),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(_customer.phoneNumber ?? ''),
                                              Text(_customer.address ?? ''),
                                            ],
                                          ),
                                        )
                                      : Text(
                                          '${Utils.getLocale(context)?.notSelectedYet}'),
                                  trailing: !canEditCustomer
                                      ? null
                                      : Icon(Icons.chevron_right),
                                ),
                              ),
                              Visibility(
                                visible: !isChineseWarehouseStaff,
                                child: ListTile(
                                  enabled: isNotCustomer,
                                  onTap: !canEditAddress
                                      ? null
                                      : () async {
                                          if (_customer == null) {
                                            Utils.alert(context,
                                                title: Utils.getLocale(context)
                                                    ?.required,
                                                message:
                                                    '${Utils.getLocale(context)?.mustChooseCustomer}!');
                                            return;
                                          }

                                          _address = await Navigator.of(context)
                                              .push(MaterialPageRoute(
                                                  builder: (context) =>
                                                      SelectAddressScreen(
                                                        customer: _customer,
                                                        current: _address,
                                                      )));
                                          _updateTotalFee();
                                          setState(() {});
                                        },
                                  contentPadding:
                                      const EdgeInsets.only(left: 0.0),
                                  title: Text(
                                      '${Utils.getLocale(context)?.deliveryAddress}'),
                                  subtitle: _address != null
                                      ? ListTile(
                                          enabled: isNotCustomer,
                                          title: Text('${_address.fullName}'),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(_address.phoneNumber ?? ''),
                                              Text([
                                                _address.address,
                                                _address.wards,
                                                _address.district,
                                                _address.province
                                              ]
                                                  .join(', ')!
                                                  .replaceAll(' ,', '')),
                                            ],
                                          ),
                                        )
                                      : Text(
                                          '${Utils.getLocale(context)?.notSelectedYet}'),
                                  trailing: canEditAddress
                                      ? Icon(Icons.chevron_right)
                                      : null,
                                ),
                              ),
                              Visibility(
                                visible: isSaleStaff,
                                child: Container(
                                  padding: const EdgeInsets.all(8.0),
                                  color: Colors.orange[50],
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Text(Utils.getLocale(context)!
                                              .priceType),
                                          SizedBox(
                                            width: 10.0,
                                          ),
                                          DropdownButton<PriceType>(
                                            disabledHint: Text(
                                                Utils.getLocale(context)!
                                                    .fixed),
                                            value: _priceType,
                                            items: _dropDownPriceType(),
                                            onChanged: _promotion != null
                                                ? null
                                                : _onPriceTypeChanged,
                                          ),
                                        ],
                                      ),
                                      Visibility(
                                        visible: _priceType == PriceType.fixed,
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                              bottom: 10.0),
                                          child: Row(
                                            children: [
                                              Expanded(
                                                child: TextFormField(
                                                  enabled: _promotion == null,
                                                  controller:
                                                      _feeByWeightController,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration: InputDecoration(
                                                      labelText:
                                                          Utils.getLocale(
                                                                  context)
                                                              ?.priceOnKilogram,
                                                      hintText:
                                                          '${Utils.getLocale(context)?.priceOnKilogram}...'),
                                                  onChanged: (value) {
                                                    _updateExtFee();
                                                  },
                                                  validator: (value) {
                                                    if (_priceType !=
                                                        PriceType.fixed)
                                                      return null;
                                                    if (Utils.isNullOrEmpty(
                                                        value!))
                                                      return Utils.getLocale(
                                                              context)
                                                          ?.required;

                                                    return null;
                                                  },
                                                ),
                                              ),
                                              SizedBox(width: 5.0),
                                              Expanded(
                                                child: TextFormField(
                                                  enabled: _promotion == null,
                                                  controller:
                                                      _feeBySizeController,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  decoration: InputDecoration(
                                                      labelText: Utils
                                                              .getLocale(
                                                                  context)
                                                          ?.priceOnCubicMeter,
                                                      hintText:
                                                          '${Utils.getLocale(context)?.priceOnCubicMeter}...'),
                                                  onChanged: (value) {
                                                    _updateExtFee();
                                                  },
                                                  validator: (value) {
                                                    if (_priceType !=
                                                        PriceType.fixed)
                                                      return null;
                                                    if (Utils.isNullOrEmpty(
                                                        value!))
                                                      return Utils.getLocale(
                                                              context)
                                                          ?.required;

                                                    return null;
                                                  },
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              Row(
                                children: [
                                  Text(
                                    '${Utils.getLocale(context)?.type}',
                                    style: TextStyle(
                                      color: isNotCustomer
                                          ? Colors.black
                                          : Theme.of(context).disabledColor,
                                    ),
                                  ),
                                  SizedBox(
                                    width: 10.0,
                                  ),
                                  DropdownButton<int>(
                                    disabledHint: Text(
                                        '${Utils.getGoodsTypeString(context, _goodsType)}'),
                                    value: _goodsType,
                                    items: _dropDownGoodsTypeItems(),
                                    onChanged: isChineseWarehouseStaff ||
                                            !isNotCustomer
                                        ? null
                                        : _onGoodsTypeChanged,
                                  ),
                                ],
                              ),
                              Visibility(
                                visible: false, //widget.update,
                                child: Row(
                                  children: [
                                    Text('${Utils.getLocale(context)?.status}'),
                                    SizedBox(
                                      width: 10.0,
                                    ),
                                    DropdownButton<int>(
                                      value: _status,
                                      items: _dropDownOrderStatusItems(),
                                      onChanged: _onOrderStatusChanged,
                                    ),
                                  ],
                                ),
                              ),
                              TextFormField(
                                style: textStyle,
                                enabled:
                                    !isChineseWarehouseStaff && isNotCustomer,
                                controller: _goodsTypeDescrController,
                                focusNode: _goodsTypeDescrFocusNode,
                                textInputAction: TextInputAction.next,
                                onFieldSubmitted: (val) {
                                  _goodsTypeDescrFocusNode.unfocus();
                                  FocusScope.of(context)
                                      .requestFocus(_intTrackNoFocusNode);
                                },
                                decoration: InputDecoration(
                                    labelText:
                                        '${Utils.getLocale(context)?.description}',
                                    hintText:
                                        '${Utils.getLocale(context)?.enter} ${Utils.getLocale(context)?.description.toLowerCase()}...',
                                    counterText: ''),
                                maxLines: 1,
                                maxLength: 250,
                                validator: (value) {
                                  if (isChineseWarehouseStaff) return null;

                                  if (Utils.isNullOrEmpty(value!))
                                    return Utils.getLocale(context)?.required;

                                  return null;
                                },
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      enabled: isNotCustomer,
                                      controller: _intTrackNoController,
                                      focusNode: _intTrackNoFocusNode,
                                      textInputAction: TextInputAction.next,
                                      onFieldSubmitted: (val) {
                                        _intTrackNoFocusNode.unfocus();
                                        FocusScope.of(context)
                                            .requestFocus(_packCountFocusNode);
                                      },
                                      decoration: InputDecoration(
                                          labelText:
                                              '${Utils.getLocale(context)?.chineseWaybillCode}',
                                          hintText:
                                              '${Utils.getLocale(context)?.enter}/${Utils.getLocale(context)?.scan}...',
                                          counterText: ''),
                                      maxLines: 1,
                                      maxLength: 50,
                                      validator: (value) {
                                        /*if (Utils.isNullOrEmpty(value))
                                          return Utils.getLocale(context)
                                              .required;*/

                                        return null;
                                      },
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: !isNotCustomer
                                        ? null
                                        : () {
                                            FlutterBarcodeScanner.scanBarcode(
                                              '#ff6666',
                                              '${Utils.getLocale(context)?.cancel}',
                                              true,
                                              ScanMode.DEFAULT,
                                            ).then((value) {
                                              if (value == '-1') value = '';
                                              _intTrackNoController.text =
                                                  value;
                                            });
                                          },
                                    child: Image.asset(
                                      'assets/images/scan.png',
                                      width: 36.0,
                                      height: 36.0,
                                      color: isNotCustomer
                                          ? Colors.black
                                          : Theme.of(context).disabledColor,
                                    ),
                                  ),
                                ],
                              ),
                              TextFormField(
                                style: textStyle,
                                controller: _packCountController,
                                focusNode: _packCountFocusNode,
                                keyboardType: TextInputType.number,
                                textInputAction: TextInputAction.next,
                                enabled:
                                    !isChineseWarehouseStaff && isNotCustomer,
                                onFieldSubmitted: (val) {
                                  _packCountFocusNode.unfocus();
                                  FocusScope.of(context)
                                      .requestFocus(_weightFocusNode);
                                },
                                decoration: InputDecoration(
                                    labelText:
                                        '${Utils.getLocale(context)?.packageQuantity}',
                                    hintText:
                                        '${Utils.getLocale(context)?.enter} ${Utils.getLocale(context)?.packageQuantity.toLowerCase()}...',
                                    counterText: ''),
                                maxLines: 1,
                                validator: (value) {
                                  if (Utils.isNullOrEmpty(value!))
                                    return Utils.getLocale(context)?.required;

                                  return null;
                                },
                              ),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      style: textStyle,
                                      enabled: isNotCustomer,
                                      controller: _weightController,
                                      focusNode: _weightFocusNode,
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.next,
                                      onChanged: (value) {
                                        _updateExtFee();
                                      },
                                      onFieldSubmitted: (val) {
                                        _weightFocusNode.unfocus();
                                        FocusScope.of(context)
                                            .requestFocus(_sizeFocusNode);
                                      },
                                      decoration: InputDecoration(
                                          labelText:
                                              '${Utils.getLocale(context)?.weight} (kg)',
                                          hintText:
                                              '${Utils.getLocale(context)?.enter} ${Utils.getLocale(context)?.weight.toLowerCase()} (kg)...',
                                          counterText: ''),
                                      maxLines: 1,
                                      validator: (value) {
                                        if (!isChineseWarehouseStaff)
                                          return null;

                                        String tmp = _sizeController.text;

                                        if ((Utils.isNullOrEmpty(value!) ||
                                                value == '0' ||
                                                value == '0.0') &&
                                            (Utils.isNullOrEmpty(tmp) ||
                                                tmp == '0' ||
                                                tmp == '0.0'))
                                          return Utils.getLocale(context)
                                              ?.required;

                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 5.0),
                                  Expanded(
                                    child: TextFormField(
                                      style: textStyle,
                                      enabled: isNotCustomer,
                                      controller: _sizeController,
                                      focusNode: _sizeFocusNode,
                                      keyboardType: TextInputType.number,
                                      textInputAction: TextInputAction.next,
                                      onChanged: (value) {
                                        _updateExtFee();
                                      },
                                      onFieldSubmitted: (val) {
                                        _sizeFocusNode.unfocus();
                                        FocusScope.of(context).requestFocus(
                                            _payOnBehalfFocusNode);
                                      },
                                      decoration: InputDecoration(
                                          labelText:
                                              '${Utils.getLocale(context)?.size} (m³)',
                                          hintText:
                                              '${Utils.getLocale(context)?.enter} ${Utils.getLocale(context)?.size.toLowerCase()} (m³)...',
                                          counterText: ''),
                                      maxLines: 1,
                                      validator: (value) {
                                        if (!isChineseWarehouseStaff)
                                          return null;

                                        String tmp = _weightController.text;

                                        if ((Utils.isNullOrEmpty(value!) ||
                                                value == '0' ||
                                                value == '0.0') &&
                                            (Utils.isNullOrEmpty(tmp) ||
                                                tmp == '0' ||
                                                tmp == '0.0'))
                                          return Utils.getLocale(context)
                                              ?.required;

                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              Visibility(
                                visible: isAllowEditAgentFee,
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        style: TextStyle(
                                          color: isSaleStaff
                                              ? Theme.of(context).disabledColor
                                              : Colors.black,
                                        ),
                                        controller:
                                            _feeByWeightDealerController,
                                        enabled: isAgentFeeFieldsEnabled,
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.next,
                                        onChanged: (value) {
                                          _updateAgentFee();
                                        },
                                        decoration: InputDecoration(
                                            labelText:
                                                '${Utils.getLocale(context)?.feeByWeightDealer} (VND)',
                                            hintText:
                                                '${Utils.getLocale(context)?.enter} ${Utils.getLocale(context)?.feeByWeightDealer.toLowerCase()}...',
                                            counterText: ''),
                                        maxLines: 1,
                                        validator: (value) {
                                          if (!isAllowEditAgentFee) return null;
                                          if (Utils.isNullOrEmpty(value!)) {
                                            return Utils.getLocale(context)
                                                ?.required;
                                          } else if (double.parse(value) <
                                              _minAgentWeightFee) {
                                            return Utils.getLocale(context)!
                                                    .required +
                                                " >= " +
                                                _minAgentWeightFee.toString();
                                          }

                                          return null;
                                        },
                                      ),
                                    ),
                                    SizedBox(width: 5.0),
                                    Expanded(
                                      child: TextFormField(
                                        style: TextStyle(
                                          color: isSaleStaff
                                              ? Theme.of(context).disabledColor
                                              : Colors.black,
                                        ),
                                        controller: _feeBySizeDealerController,
                                        enabled: isAgentFeeFieldsEnabled,
                                        keyboardType: TextInputType.number,
                                        textInputAction: TextInputAction.next,
                                        onChanged: (value) {
                                          _updateAgentFee();
                                        },
                                        decoration: InputDecoration(
                                            labelText:
                                                '${Utils.getLocale(context)?.feeBySizeDealer} (VND)',
                                            hintText:
                                                '${Utils.getLocale(context)?.enter} ${Utils.getLocale(context)?.feeBySizeDealer.toLowerCase()}...',
                                            counterText: ''),
                                        maxLines: 1,
                                        validator: (value) {
                                          if (!isAllowEditAgentFee) return null;
                                          if (Utils.isNullOrEmpty(value!)) {
                                            return Utils.getLocale(context)
                                                ?.required;
                                          } else if (double.parse(value) <
                                              _minAgentSizeFee) {
                                            return Utils.getLocale(context)!
                                                    .required +
                                                " >= " +
                                                _minAgentSizeFee.toString();
                                          }

                                          return null;
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10.0),
                              Visibility(
                                visible: isChineseWarehouseStaff,
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 25.0,
                                      child: Checkbox(
                                        value: _boxedWood,
                                        onChanged: widget.update &&
                                                OrderStatus.chineseWarehoused ==
                                                    _order.orderStatus
                                            ? null
                                            : (value) => setState(() {
                                                  _boxedWood = value!;
                                                  if (!_boxedWood) {
                                                    _repackFeeController
                                                        .clear();
                                                  }
                                                }),
                                      ),
                                    ),
                                    SizedBox(width: 5.0),
                                    Text(
                                        '${Utils.getLocale(context)?.packedByWoodenBox}'),
                                  ],
                                ),
                              ),
                              SizedBox(height: 10.0),
                              Visibility(
                                visible: _boxedWood && isChineseWarehouseStaff,
                                child: ChineseCurrencyInput(
                                  controller: _repackFeeController,
                                  labelText:
                                      '${Utils.getLocale(context)?.packingFee} (CNY)',
                                  hintText:
                                      '${Utils.getLocale(context)?.enter} CNY...',
                                ),
                                /*CurrencySwapInput(
                                  controller: _repackFeeController,
                                  title:
                                      '${Utils.getLocale(context).packingFee} (VND/CNY)',
                                  firstLabelText: 'VND',
                                  firstHintText:
                                      '${Utils.getLocale(context).enter} VND...',
                                  secondLabelText: 'CNY',
                                  secondHintText:
                                      '${Utils.getLocale(context).enter} CNY...',
                                ),*/
                              ),
                              SizedBox(
                                  height:
                                      _boxedWood && isNotCustomer ? 20.0 : 0),
                              ChineseCurrencyInput(
                                style: textStyle,
                                enabled: isNotCustomer,
                                controller: _payOnBehalfController,
                                labelText:
                                    '${Utils.getLocale(context)?.payOnBehalf} (CNY)',
                                hintText:
                                    '${Utils.getLocale(context)?.enter} CNY...',
                              ),
                              /*CurrencySwapInput(
                                controller: _payOnBehalfController,
                                title:
                                    '${Utils.getLocale(context).payOnBehalf} (VND/CNY)',
                                firstLabelText: 'VND',
                                firstHintText:
                                    '${Utils.getLocale(context).enter} VND...',
                                secondLabelText: 'CNY',
                                secondHintText:
                                    '${Utils.getLocale(context).enter} CNY...',
                              ),*/
                              const SizedBox(height: 20.0),
                              ChineseCurrencyInput(
                                style: textStyle,
                                enabled: isNotCustomer,
                                controller: _intFeeController,
                                labelText:
                                    '${Utils.getLocale(context)?.domesticShippingFee} (CNY)',
                                hintText:
                                    '${Utils.getLocale(context)?.enter} CNY...',
                              ),
                              /*CurrencySwapInput(
                                controller: _intFeeController,
                                title:
                                    '${Utils.getLocale(context).domesticShippingFee} (VND/CNY)',
                                firstLabelText: 'VND',
                                firstHintText:
                                    '${Utils.getLocale(context).enter} VND...',
                                secondLabelText: 'CNY',
                                secondHintText:
                                    '${Utils.getLocale(context).enter} CNY...',
                              ),*/
                              const SizedBox(height: 20.0),
                              Visibility(
                                visible: !isChineseWarehouseStaff,
                                child: TextFormField(
                                  style: textStyle,
                                  readOnly: true,
                                  enabled: false,
                                  controller: _extFeeController,
                                  focusNode: _extFeeFocusNode,
                                  decoration: InputDecoration(
                                      labelText:
                                          '${Utils.getLocale(context)?.internationalShippingFee} (VND)',
                                      hintText:
                                          '${Utils.getLocale(context)?.enter} ${Utils.getLocale(context)?.internationalShippingFee.toLowerCase()}...',
                                      counterText: ''),
                                  maxLines: 1,
                                ),
                              ),
                              /*CurrencySwapInput(
                                controller: _extFeeController,
                                title:
                                    '${Utils.getLocale(context).internationalShippingFee} (VND/CNY)',
                                firstLabelText: 'VND',
                                firstHintText:
                                    '${Utils.getLocale(context).enter} VND...',
                                secondLabelText: 'CNY',
                                secondHintText:
                                    '${Utils.getLocale(context).enter} CNY...',
                              ),*/
                              SizedBox(height: 10.0),
                              TextFormField(
                                enabled: isNotCustomer,
                                controller: _noteController,
                                focusNode: _noteFocusNode,
                                decoration: InputDecoration(
                                    labelText:
                                        '${Utils.getLocale(context)?.note}',
                                    hintText:
                                        '${Utils.getLocale(context)?.enter} ${Utils.getLocale(context)?.note.toLowerCase()}...',
                                    counterText: ''),
                                maxLines: 1,
                              ),
                              SizedBox(height: 20.0),
                              IgnorePointer(
                                ignoring: !isNotCustomer,
                                child: ImagePickerWidget(
                                  controller: _filesController,
                                  child: ListTile(
                                    enabled: isNotCustomer,
                                    contentPadding:
                                        const EdgeInsets.only(left: 0.0),
                                    title: Text(
                                        '${Utils.getLocale(context)?.imageAttach}'),
                                    subtitle: Text(
                                        '${Utils.getLocale(context)?.imageAttachNote}'),
                                  ),
                                  onAdd: (img) {
                                    final index = _uploadImages
                                        .indexWhere((e) => e.id == img.id);
                                    if (index > -1) {
                                      _uploadImages.removeAt(index);
                                    }
                                    _uploadImages.add(img);
                                  },
                                  onRemove: (img) {
                                    _removeImages.add(img);
                                    _uploadImages
                                        .removeWhere((e) => e.id == img.id);
                                  },
                                ),
                              ),
                              SizedBox(height: 20.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Material(
                    elevation: 4.0,
                    child: Container(
                      color: Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Visibility(
                            visible: !isChineseWarehouseStaff,
                            child: Opacity(
                              opacity: isNotCustomer ? 1.0 : 0.5,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                child: GestureDetector(
                                  onTap: !isNotCustomer
                                      ? null
                                      : () async {
                                          _getFormData();
                                          if (_order == null ||
                                              Utils.isNullOrEmpty(
                                                  _order.customerId) ||
                                              _address == null ||
                                              Utils.isNullOrEmpty(
                                                  _address.province)) {
                                            Utils.alert(context,
                                                title: Utils.getLocale(context)
                                                    ?.required,
                                                message:
                                                    '${Utils.getLocale(context)?.cannotChoosePromotionMessage}!');
                                            return;
                                          }

                                          _promotion = await Navigator.of(
                                                      context)
                                                  .push(MaterialPageRoute(
                                                      builder: (context) =>
                                                          SelectPromotionScreen(
                                                            order: _order,
                                                            current: _promotion,
                                                          ))) ??
                                              _promotion;

                                          if (_promotion != null) {
                                            setState(() {
                                              _priceType = PriceType.fixed;
                                              int locationGroup =
                                                  PriceCalculationUtil
                                                      .getLocationGroupByProvince(
                                                          _address.province);
                                              if (locationGroup == 1) {
                                                _feeByWeightController.text =
                                                    '${_promotion.feeByWeightZ1}';
                                                _feeBySizeController.text =
                                                    '${_promotion.feeBySizeZ1}';
                                              } else if (locationGroup == 2) {
                                                _feeByWeightController.text =
                                                    '${_promotion.feeByWeightZ2}';
                                                _feeBySizeController.text =
                                                    '${_promotion.feeBySizeZ2}';
                                              } else if (locationGroup == 3) {
                                                _feeByWeightController.text =
                                                    '${_promotion.feeByWeightZ3}';
                                                _feeBySizeController.text =
                                                    '${_promotion.feeBySizeZ3}';
                                              }
                                            });
                                          }

                                          setState(() {});
                                          _updateTotalFee();
                                        },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${Utils.getLocale(context)?.promotion}',
                                              style: TextStyle(
                                                fontSize: 12.0,
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.chevron_right,
                                            color:
                                                Theme.of(context).disabledColor,
                                          ),
                                        ],
                                      ),
                                      _promotion != null
                                          ? Text(
                                              '${_promotion.promotionName}',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .disabledColor,
                                                fontSize: 10.0,
                                              ),
                                            )
                                          : Text(
                                              '${Utils.getLocale(context)?.notSelectedYet}',
                                              style: TextStyle(
                                                color: Theme.of(context)
                                                    .disabledColor,
                                                fontSize: 10.0,
                                              ),
                                            ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Visibility(
                            visible: !isChineseWarehouseStaff,
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  left: 8.0, bottom: 9.0, right: 8.0),
                              child: RichText(
                                text: TextSpan(
                                  text:
                                      '${Utils.getLocale(context)?.totalAmount}: ',
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .textTheme
                                        .bodyText1
                                        ?.color,
                                    fontSize: 16.0,
                                  ),
                                  children: [
                                    TextSpan(
                                      text: _promotion == null
                                          ? ''
                                          : Utils.isNullOrEmpty(
                                                  _extFeeController.text)
                                              ? ''
                                              : _totalFeeOrigin <= 0
                                                  ? ''
                                                  : NumberFormat.currency(
                                                          locale: 'vi_VN',
                                                          symbol: 'đ')
                                                      .format(_totalFeeOrigin),
                                      style: TextStyle(
                                        color: Theme.of(context).disabledColor,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    TextSpan(
                                      text: (_promotion != null ? ' ' : '') +
                                          (isAllowEditAgentFee
                                              ? _getAgentTotalFeeText
                                              : _getTotalFeeText),
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    TextSpan(
                                      text: !isAllowEditAgentFee
                                          ? ''
                                          : ((_promotion != null ? ' ' : '') +
                                              ' (' +
                                              _getTotalFeeText +
                                              ')'),
                                      style: TextStyle(
                                        fontSize: 16.0,
                                        color: Colors.amber,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          SizedBox(
                            width: double.infinity,
                            height: 40.0,
                            child:
                                // RaisedButton(
                                //   color: Utils.accentColor,
                                //   onPressed: _saveOrder,
                                //   child: Text(
                                //     '${Utils.getLocale(context)?.save}'
                                //     /*isChineseWarehouseStaff &&
                                //             _order?.orderStatus !=
                                //                 OrderStatus.chineseWarehoused
                                //         ? _boxedWood
                                //             ? '${Utils.getLocale(context).saveAndWaitConfirmPacking}'
                                //             : '${Utils.getLocale(context).saveAndWarehoused}'
                                //         : '${Utils.getLocale(context).save}'*/
                                //     ,
                                //     style: TextStyle(color: Colors.white),
                                //   ),
                                // ),
                                ElevatedButton(
                              onPressed: _saveOrder,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Utils
                                    .accentColor, // Set button's background color
                              ),
                              child: Text(
                                '${Utils.getLocale(context)?.save}',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isNumberValid(num number) {
    return number != null && number > 0;
  }

  List<DropdownMenuItem<int>> _dropDownGoodsTypeItems() {
    return [
      DropdownMenuItem(
        value: GoodsType.fake,
        child: Text(Utils.getGoodsTypeString(context, GoodsType.fake)),
      ),
      DropdownMenuItem(
        value: GoodsType.cosmetic,
        child: Text(Utils.getGoodsTypeString(context, GoodsType.cosmetic)),
      ),
      DropdownMenuItem(
        value: GoodsType.food,
        child: Text(Utils.getGoodsTypeString(context, GoodsType.food)),
      ),
      DropdownMenuItem(
        value: GoodsType.medicine,
        child: Text(Utils.getGoodsTypeString(context, GoodsType.medicine)),
      ),
      DropdownMenuItem(
        value: GoodsType.liquid,
        child: Text(Utils.getGoodsTypeString(context, GoodsType.liquid)),
      ),
      DropdownMenuItem(
        value: GoodsType.fragile,
        child: Text(Utils.getGoodsTypeString(context, GoodsType.fragile)),
      ),
      DropdownMenuItem(
        value: GoodsType.clothes,
        child: Text(Utils.getGoodsTypeString(context, GoodsType.clothes)),
      ),
      DropdownMenuItem(
        value: GoodsType.electronic,
        child: Text(Utils.getGoodsTypeString(context, GoodsType.electronic)),
      ),
      DropdownMenuItem(
        value: GoodsType.prepackagedGroceries,
        child: Text(
            Utils.getGoodsTypeString(context, GoodsType.prepackagedGroceries)),
      ),
      DropdownMenuItem(
        value: GoodsType.normal,
        child: Text(Utils.getGoodsTypeString(context, GoodsType.normal)),
      ),
      DropdownMenuItem(
        value: GoodsType.superHeavy,
        child: Text(Utils.getGoodsTypeString(context, GoodsType.superHeavy)),
      ),
      DropdownMenuItem(
        value: GoodsType.special,
        child: Text(Utils.getGoodsTypeString(context, GoodsType.special)),
      ),
    ];
  }

  void _onGoodsTypeChanged(int? value) {
    setState(() => _goodsType = value!);
    _updateExtFee();
  }

  List<DropdownMenuItem<int>> _dropDownOrderStatusItems() {
    return [
      DropdownMenuItem(
        value: OrderStatus.newlyCreated,
        child:
            Text(Utils.getOrderStatusString(context, OrderStatus.newlyCreated)),
      ),
      DropdownMenuItem(
        value: OrderStatus.aborted,
        child: Text(Utils.getOrderStatusString(context, OrderStatus.aborted)),
      ),
      DropdownMenuItem(
        value: OrderStatus.chineseWarehoused,
        child: Text(
            Utils.getOrderStatusString(context, OrderStatus.chineseWarehoused)),
      ),
      DropdownMenuItem(
        value: OrderStatus.pendingWoodenPacking,
        child: Text(Utils.getOrderStatusString(
            context, OrderStatus.pendingWoodenPacking)),
      ),
      DropdownMenuItem(
        value: OrderStatus.chineseShippedOut,
        child: Text(
            Utils.getOrderStatusString(context, OrderStatus.chineseShippedOut)),
      ),
      DropdownMenuItem(
        value: OrderStatus.uongbiWarehoused,
        child: Text(
            Utils.getOrderStatusString(context, OrderStatus.uongbiWarehoused)),
      ),
      DropdownMenuItem(
        value: OrderStatus.hanoiWarehoused,
        child: Text(
            Utils.getOrderStatusString(context, OrderStatus.hanoiWarehoused)),
      ),
      DropdownMenuItem(
        value: OrderStatus.saigonWarehoused,
        child: Text(
            Utils.getOrderStatusString(context, OrderStatus.saigonWarehoused)),
      ),
    ];
  }

  List<DropdownMenuItem<PriceType>> _dropDownPriceType() {
    return [
      DropdownMenuItem(
        value: PriceType.normal,
        child: Text('${Utils.getLocale(context)?.company}'),
      ),
      DropdownMenuItem(
        value: PriceType.fixed,
        child: Text('${Utils.getLocale(context)?.fixed}'),
      ),
    ];
  }

  void _onOrderStatusChanged(int? value) {
    setState(() => _status = value!);
  }

  void _onPriceTypeChanged(PriceType? value) {
    setState(() => _priceType = value!);

    if (value == PriceType.normal) {
      _feeBySizeController.clear();
      _feeByWeightController.clear();
    }
    _updateExtFee();
  }

  Future<void> _saveOrder() async {
    if (_address == null || _address.addressId == null) {
      Utils.alert(context,
          title: Utils.getLocale(context)?.required,
          message: '${Utils.getLocale(context)?.mustChooseAddress}!');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    // check attachment is empty
    if (isChineseWarehouseStaff &&
        ((!widget.update ||
                widget.order?.orderStatus == OrderStatus.newlyCreated) ||
            (widget.update &&
                (widget.order.tccoFileDTOS == null ||
                    widget.order.tccoFileDTOS!.isEmpty)))) {
      if (_uploadImages == null || _uploadImages.isEmpty) {
        Utils.alert(context,
            title: Utils.getLocale(context)?.required,
            message: '${Utils.getLocale(context)?.imagesRequired}!');
        return;
      }
    }

    _getFormData();
    Utils.showLoading(context,
        textContent: Utils.getLocale(context)!.waitForLogin);
    Future.delayed(Duration(milliseconds: 500), () async {
      /*if (_uploadImages.isNotEmpty) {
        // resize images if so big
        await Future.forEach(_uploadImages, (fh) async {
          if (fh.file != null) {
            fh.file = await Utils.resizeImage(fh.file);
          }
        });
      }*/

      HttpUtil.postOrder(
        ApiUrls.instance().getOrdersUrl(),
        order: _order,
        files: _uploadImages,
        onTimeout: () {
          // pop loading
          Navigator.of(context, rootNavigator: true).pop();
          Utils.alert(context,
              title: Utils.getLocale(context)?.errorOccurred,
              message: Utils.getLocale(context)?.requestTimeout);
        },
        onDone: (resp) async {
          var json =
              resp == null ? null : jsonDecode(utf8.decode(resp.bodyBytes));
          if (resp == null || resp.statusCode != 200) {
            // pop loading
            Navigator.of(context, rootNavigator: true).pop();
            Utils.alert(context,
                title: Utils.getLocale(context)?.failed,
                message:
                    '${Utils.getLocale(context)?.errorOccurred}!\n${json['message']}');
            return;
          }

          if (json != null) {
            Order savedOrder = Order.fromJson(json);
            AppProvider.of(context)?.state.orderBloc.updateOrder(savedOrder);
          }

          // now do not needed
          /*if (widget.update &&
              isChineseWarehouseStaff &&
              !_boxedWood &&
              _order.orderStatus == OrderStatus.newlyCreated) {
            bool success = await HttpUtil.updateOrderTrackingStatus(
                _order.orderId, ActionType.chineseWarehouse);
            if (success) {
              Order updatedOrder = await HttpUtil.getOrder(_order.orderId);
              AppProvider.of(context).state.orderBloc.updateOrder(updatedOrder);

              // remove order from block if needed
              Utils.removeOrderFromBloc(context, updatedOrder);
            }
          }*/

          // pop loading
          Navigator.of(context, rootNavigator: true).pop();
          Utils.alert(context,
              title: '${Utils.getLocale(context)?.success}',
              message: widget.update
                  ? '${Utils.getLocale(context)?.updateOrderSuccessMessage}'
                  : '${Utils.getLocale(context)?.createOrderSuccessMessage}',
              onAccept: widget.update
                  ? () => Utils.popToFirstScreen(context)
                  : () {
                      _reset();
                      Future.delayed(Duration(milliseconds: 200), () {
                        Utils.popToFirstScreen(context);
                      });
                    });
        },
      );
    });
  }

  // use only for create mode
  void _reset() {
    // _address = null;
    _goodsType = GoodsType.normal;
    _goodsTypeDescrController.clear();
    _intTrackNoController.clear();
    _packCountController.clear();
    _weightController.clear();
    _sizeController.clear();
    _boxedWood = false;
    _repackFeeController.clear();
    _payOnBehalfController.clear();
    _intFeeController.clear();
    _extFeeController.clear();
    _filesController.clear();
    _uploadImages.clear();
    _removeImages.clear();
    _noteController.clear();
    // _promotion = null;
    _totalFee = 0;
    setState(() {});
  }
}
