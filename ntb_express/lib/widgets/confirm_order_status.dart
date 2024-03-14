import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:ntbexpress/model/fee_item.dart';
import 'package:ntbexpress/model/order.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/extensions.dart';
import 'package:ntbexpress/util/http_util.dart';
import 'package:ntbexpress/util/price_calculation_util.dart';
import 'package:ntbexpress/util/session_util.dart';
import 'package:ntbexpress/util/utils.dart';
import 'package:ntbexpress/widgets/app_provider.dart';
import 'package:ntbexpress/widgets/currency_swap_input.dart';
import 'package:ntbexpress/widgets/image_picker_widget.dart';

class ConfirmOrderStatusWidget extends StatefulWidget {
  final Order? forOrder;
  final bool cancelOrder;
  final bool output;
  final bool hidePackCount;

  ConfirmOrderStatusWidget(
      {this.forOrder,
      this.cancelOrder = false,
      this.output = false,
      this.hidePackCount = false});

  @override
  _ConfirmOrderStatusWidgetState createState() =>
      _ConfirmOrderStatusWidgetState();
}

class _ConfirmOrderStatusWidgetState extends State<ConfirmOrderStatusWidget> {
  final _formKey = GlobalKey<FormState>();
  final _filesController = ImagePickerController();
  final _weightController = TextEditingController();
  final _sizeController = TextEditingController();
  final _payOnBehalfController = TextEditingController();
  final _intFeeController = TextEditingController();
  int _packCount = 0;
  late String _note;
  String _nextWarehouse = '';
  late Order _order;

  bool get isChineseStaff =>
      SessionUtil.instance()?.user?.userType == UserType.chineseWarehouseStaff;

  @override
  void initState() {
    super.initState();
    if (widget.forOrder != null) {
      _order = Order.clone(widget.forOrder!);
    }

    if (feeTable.isEmpty) {
      _getFeeTable();
    }

    if (_order != null) {
      _weightController.text = '${_order.weight}';
      _sizeController.text = '${_order.size}';
      _payOnBehalfController.text = '${_order.payOnBehalf}';
      _intFeeController.text = '${_order.intFee}';
    }
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
    _order.weight = _weightController.text.trim().parseDouble();
    _order.size = _sizeController.text.trim().parseDouble();
    _order.payOnBehalf = _payOnBehalfController.text.trim().parseDouble();
    _order.intFee = _intFeeController.text.trim().parseDouble();
  }

  double _getTotalFee() {
    return PriceCalculationUtil.calculatePrice(
        repackFee: _order.repackFee ?? 0,
        payOnBehalf: _order.payOnBehalf ?? 0,
        intFee: _order.intFee ?? 0,
        extFee: _order.extFee ?? 0);
  }

  double _getTotalFeeOriginal() {
    return PriceCalculationUtil.calculatePrice(
        repackFee: _order.repackFee ?? 0,
        payOnBehalf: _order.payOnBehalf ?? 0,
        intFee: _order.intFee,
        extFee: PriceCalculationUtil.calculateExtFee(
            address: _order.addressDTO,
            goodsType: _order.goodsType,
            size: _order.size,
            weight: _order.weight));
  }

  double _getExtFee() {
    return PriceCalculationUtil.calculateExtFee(
        address: _order.addressDTO,
        goodsType: _order.goodsType,
        size: _order.size,
        weight: _order.weight,
        feeBySize: _order.feeBySize,
        feeByWeight: _order.feeByWeight);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: AlertDialog(
        title: Text('${Utils.getLocale(context)?.confirmation}'),
        content: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          child: Scrollbar(
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Visibility(
                      visible: isChineseStaff &&
                          widget.forOrder?.orderStatus ==
                              OrderStatus.newlyCreated,
                      child: Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _weightController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                  labelText:
                                      '${Utils.getLocale(context)?.weight} (kg)',
                                  hintText:
                                      '${Utils.getLocale(context)?.enter} ${Utils.getLocale(context)?.weight.toLowerCase()} (kg)...',
                                  counterText: ''),
                              maxLines: 1,
                              validator: (value) {
                                if (!isChineseStaff ||
                                    widget.forOrder?.orderStatus !=
                                        OrderStatus.newlyCreated) return null;

                                String tmp = _sizeController.text;

                                if ((Utils.isNullOrEmpty(value!) ||
                                        value.trim() == '0' ||
                                        value.trim() == '0.0') &&
                                    (Utils.isNullOrEmpty(tmp) ||
                                        tmp.trim() == '0' ||
                                        tmp.trim() == '0.0'))
                                  return Utils.getLocale(context)?.required;

                                return null;
                              },
                            ),
                          ),
                          SizedBox(width: 5.0),
                          Expanded(
                            child: TextFormField(
                              controller: _sizeController,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                  labelText:
                                      '${Utils.getLocale(context)?.size} (m³)',
                                  hintText:
                                      '${Utils.getLocale(context)?.enter} ${Utils.getLocale(context)?.size.toLowerCase()} (m³)...',
                                  counterText: ''),
                              maxLines: 1,
                              validator: (value) {
                                if (!isChineseStaff ||
                                    widget.forOrder?.orderStatus !=
                                        OrderStatus.newlyCreated) return null;

                                String tmp = _weightController.text;

                                if ((Utils.isNullOrEmpty(value!) ||
                                        value.trim() == '0' ||
                                        value.trim() == '0.0') &&
                                    (Utils.isNullOrEmpty(tmp) ||
                                        tmp.trim() == '0' ||
                                        tmp.trim() == '0.0'))
                                  return Utils.getLocale(context)?.required;

                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: isChineseStaff &&
                          widget.forOrder?.orderStatus ==
                              OrderStatus.newlyCreated,
                      child: ChineseCurrencyInput(
                        controller: _payOnBehalfController,
                        labelText:
                            '${Utils.getLocale(context)?.payOnBehalf} (CNY)',
                        hintText: '${Utils.getLocale(context)?.enter} CNY...',
                      ),
                    ),
                    Visibility(
                      visible: isChineseStaff &&
                          widget.forOrder?.orderStatus ==
                              OrderStatus.newlyCreated,
                      child: ChineseCurrencyInput(
                        controller: _intFeeController,
                        labelText:
                            '${Utils.getLocale(context)?.domesticShippingFee} (CNY)',
                        hintText: '${Utils.getLocale(context)?.enter} CNY...',
                      ),
                    ),
                    Visibility(
                      visible: !widget.cancelOrder && !widget.hidePackCount,
                      child: TextFormField(
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText:
                              '${Utils.getLocale(context)?.packageQuantity}',
                        ),
                        onChanged: (value) => _packCount = value.parseInt(),
                        validator: (value) {
                          if (widget.cancelOrder || widget.hidePackCount)
                            return null;

                          if (Utils.isNullOrEmpty(value!))
                            return Utils.getLocale(context)?.required;
                          final int numValue = value.parseInt();
                          if (numValue <= 0)
                            return '${Utils.getLocale(context)?.mustBeGreaterThanZero}!';
                          int count = widget?.forOrder?.packCount ?? 0;
                          if (numValue > count &&
                              widget.forOrder?.orderStatus !=
                                  OrderStatus.newlyCreated)
                            return '${Utils.getLocale(context)?.greaterThanCurrentParcels}!';

                          return null;
                        },
                      ),
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: '${Utils.getLocale(context)?.note}...',
                      ),
                      onChanged: (value) => _note = value,
                      validator: (value) {
                        bool needToValidate = false;
                        if (widget.forOrder?.orderStatus ==
                            OrderStatus.chineseWarehoused)
                          needToValidate = true;
                        else if (widget.output) needToValidate = true;
                        if (!needToValidate) return null;
                        if (Utils.isNullOrEmpty(value!))
                          return Utils.getLocale(context)?.required;

                        return null;
                      },
                    ),
                    Visibility(
                        visible: !widget.cancelOrder,
                        child: SizedBox(height: 10.0)),
                    Visibility(
                      visible: !widget.cancelOrder,
                      child: ImagePickerWidget(
                        controller: _filesController,
                        child: Text('${Utils.getLocale(context)?.imageAttach}'),
                        maxImages: 2,
                      ),
                    ),
                    Visibility(
                      visible: !widget.cancelOrder &&
                          SessionUtil.instance().user.userType !=
                              UserType.chineseWarehouseStaff &&
                          widget.output,
                      child: Builder(
                        builder: (_) {
                          bool isChineseStaff =
                              SessionUtil.instance().user.userType ==
                                  UserType.chineseWarehouseStaff;
                          if (isChineseStaff) return SizedBox();

                          final List<String> values = [];
                          bool isHanoiStaff =
                              SessionUtil.instance().user.userType ==
                                  UserType.hanoiWarehouseStaff;
                          bool isUongBiStaff =
                              SessionUtil.instance().user.userType ==
                                  UserType.uongbiWarehouseStaff;
                          bool isSaiGonStaff =
                              SessionUtil.instance().user.userType ==
                                  UserType.saigonWarehouseStaff;

                          if (isHanoiStaff)
                            values
                              ..clear()
                              ..addAll(
                                  [NextWarehouse.uongbi, NextWarehouse.saigon]);
                          else if (isUongBiStaff)
                            values
                              ..clear()
                              ..addAll(
                                  [NextWarehouse.hanoi, NextWarehouse.saigon]);
                          else if (isSaiGonStaff)
                            values
                              ..clear()
                              ..addAll(
                                  [NextWarehouse.uongbi, NextWarehouse.hanoi]);

                          if (values.isEmpty) return SizedBox();

                          values.insert(0, '');
                          return Row(
                            children: [
                              Text(
                                  '${Utils.getLocale(context)?.warehouseArrived}'),
                              SizedBox(width: 5.0),
                              DropdownButton<String>(
                                value: _nextWarehouse,
                                onChanged: (value) {
                                  setState(() {
                                    _nextWarehouse = value!;
                                  });
                                },
                                items: values
                                    .map((e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(e == NextWarehouse.hanoi
                                              ? 'Hà Nội'
                                              : e == NextWarehouse.uongbi
                                                  ? 'Uông Bí'
                                                  : e == NextWarehouse.saigon
                                                      ? 'Sài Gòn'
                                                      : '${Utils.getLocale(context)?.select}...'),
                                        ))
                                    .toList(),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        actions: [
          FlatButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              Utils.getLocale(context)!.cancel,
              style: TextStyle(
                color: Colors.red,
              ),
            ),
          ),
          FlatButton(
            onPressed: () async {
              if (!_formKey.currentState!.validate()) {
                return;
              }

              if (widget.output && Utils.isNullOrEmpty(_nextWarehouse)) {
                Utils.alert(context,
                    title: Utils.getLocale(context)?.required,
                    message:
                        '${Utils.getLocale(context)?.mustSelectAWarehouseArrived}!');
                return;
              }

              List<File>? files =
                  _filesController.files.map((fh) => fh.file).cast<File>().toList();
              if (files != null) files.removeWhere((f) => f == null);
              // check if does not attach files & is chinese staff
              if (isChineseStaff &&
                  widget.forOrder?.orderStatus == OrderStatus.newlyCreated &&
                  (widget.forOrder?.tccoFileDTOS == null ||
                      widget.forOrder!.tccoFileDTOS!.isEmpty) &&
                  (files == null || files.isEmpty)) {
                Utils.alert(context,
                    title: Utils.getLocale(context)?.required,
                    message: Utils.getLocale(context)?.imagesRequired);
                return;
              }

              bool passed = await updateOrder();
              Navigator.of(context).pop(!passed
                  ? null
                  : ConfirmationStatus(
                      packCount: _packCount,
                      note: _note,
                      nextWarehouse: _nextWarehouse,
                      files: files));
            },
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> updateOrder() async {
    var c = Completer<bool>();
    _getFormData();
    if (_order.weight != widget.forOrder?.weight ||
        _order.size != widget.forOrder?.size ||
        _order.payOnBehalf != widget.forOrder?.payOnBehalf ||
        _order.intFee != widget.forOrder?.intFee) {
      // get new price
      _order.extFee = _getExtFee();
      _order.totalFee = _getTotalFee();
      _order.totalFeeOriginal = _getTotalFeeOriginal();

      widget.forOrder?.weight = _order.weight;
      widget.forOrder?.size = _order.size;
      widget.forOrder?.payOnBehalf = _order.payOnBehalf;
      widget.forOrder?.intFee = _order.intFee;
      widget.forOrder?.extFee = _order.extFee;
      widget.forOrder?.totalFee = _order.totalFee;
      widget.forOrder?.totalFeeOriginal = _order.totalFeeOriginal;

      HttpUtil.postOrder(
        ApiUrls.instance().getOrdersUrl(),
        order: widget.forOrder,
        onDone: (resp) {
          var json =
              resp == null ? null : jsonDecode(utf8.decode(resp.bodyBytes));
          if (resp == null || resp.statusCode != 200) {
            c.complete(false);
            return;
          }

          if (json != null) {
            Order savedOrder = Order.fromJson(json);
            AppProvider.of(context)?.state.orderBloc.updateOrder(savedOrder);
          }
          c.complete(true);
        },
        onTimeout: () => c.complete(false),
      );
    } else {
      c.complete(true);
    }

    return c.future;
  }
}
