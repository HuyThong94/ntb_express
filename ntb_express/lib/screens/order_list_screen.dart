import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_barcode_scanner/flutter_barcode_scanner.dart';
import 'package:ntbexpress/bloc/order_bloc.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/session_util.dart';
import 'package:ntbexpress/util/utils.dart';
import 'package:ntbexpress/widgets/app_provider.dart';
import 'package:ntbexpress/util/extensions.dart';

class OrderColor {
  static final Color newlyCreated = Colors.white;
  static final Color? waitWoodenConfirm = Colors.brown[50];
  static final Color? cancelled = Colors.grey[50];
  static final Color? myUser = Colors.green[100];
}

class OrderFilterWidget extends StatefulWidget {
  final OrderFilter filter;
  final ValueChanged<String> onCustomerCodeChange;

  OrderFilterWidget(this.filter, {required this.onCustomerCodeChange});

  @override
  _OrderFilterWidgetState createState() => _OrderFilterWidgetState();
}

class _OrderFilterWidgetState extends State<OrderFilterWidget> {
  final List<int> _statusList = [];
  final double _rightWidth = 250;
  final _customerIdController = TextEditingController();
  final _internalTrackNoController = TextEditingController();
  final _externalTrackNoController = TextEditingController();
  final _packCountController = TextEditingController();
  final _fromDateController = TextEditingController();
  final _toDateController = TextEditingController();
  final _goodsDescrController = TextEditingController();
  final _licensePlatesController = TextEditingController();
  //Timer _timer;

  //String _statusText;
  //final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  //final _maskFormatter = MaskTextInputFormatter(
  //    mask: '####-##-##', filter: {'#': RegExp(r'[0-9]')});

  @override
  void initState() {
    super.initState();
    _statusList..addAll(widget.filter.statusList ?? []);
    _customerIdController.text = widget.filter.customerId ?? '';
    _internalTrackNoController.text = widget.filter.internalTrackNo ?? '';
    _externalTrackNoController.text = widget.filter.externalTrackNo ?? '';
    _fromDateController.text = widget.filter.fromDate ?? '';
    _toDateController.text = widget.filter.toDate ?? '';
    _goodsDescrController.text = widget.filter.goodsDescr ?? '';
    _licensePlatesController.text = widget.filter.licensePlates ?? '';
    if (widget.filter.packCount != null && widget.filter.packCount > 0) {
      _packCountController.text = '${widget.filter.packCount}';
    }

    /*if (this.widget.onCustomerCodeChange != null) {
      _customerIdController.addListener(() {
        final String text = _customerIdController.text?.trim();
        if (_timer != null) {
          _timer.cancel();
        }

        _timer = new Timer(const Duration(milliseconds: 1000),
                () => this.widget.onCustomerCodeChange(text));
      });
    }*/
  }

  @override
  void dispose() {
    _customerIdController?.dispose();
    _internalTrackNoController?.dispose();
    _externalTrackNoController?.dispose();
    _fromDateController?.dispose();
    _toDateController?.dispose();
    _packCountController?.dispose();
    _goodsDescrController?.dispose();
    _licensePlatesController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    //_statusText = _getStatusText();

    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: 80.0,
        decoration: BoxDecoration(
          color: Colors.transparent,
          /*border: Border(
            bottom: BorderSide(
              width: 0.4,
              color: Theme.of(context).disabledColor,
            ),
          ),*/
        ),
        child: Column(
          children: [
            Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                Expanded(
                  flex: 2,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: SizedBox(
                          width: _rightWidth,
                          child: Row(
                            children: [
                              Expanded(
                                child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: TextField(
                                            cursorWidth: 1,
                                            cursorColor: Colors.white,
                                            controller: _goodsDescrController,
                                            decoration: _decoration(
                                              hintText: Utils.getLocale(context)
                                                  ?.description,
                                            ),
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8.0),
                                        Expanded(
                                          child: TextField(
                                            cursorWidth: 1,
                                            cursorColor: Colors.white,
                                            controller:
                                                _licensePlatesController,
                                            decoration: _decoration(
                                              hintText: Utils.getLocale(context)
                                                  ?.licensePlates,
                                            ),
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    )),
                                // Uncomment to allow input waybill code China - Vietnam displayed
                                /*child: TextField(
                                    cursorWidth: 1,
                                    cursorColor: Colors.white,
                                    controller: _internalTrackNoController,
                                    decoration: _decoration(
                                        hintText: SessionUtil.instance()
                                                    ?.user
                                                    ?.userType ==
                                                UserType.chineseWarehouseStaff
                                            ? Utils.getLocale(context)
                                                .chineseWaybillCode
                                            : Utils.getLocale(context)
                                                .internationalWaybillCode),
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),*/
                              ),
                              //const SizedBox(width: 10.0),
                              // Uncomment to allow scan code button displayed
                              /*GestureDetector(
                                onTap: () {
                                  FlutterBarcodeScanner.scanBarcode(
                                    '#ff6666',
                                    '${Utils.getLocale(context).cancel}',
                                    true,
                                    ScanMode.DEFAULT,
                                  ).then((value) {
                                    if (value == '-1') value = '';
                                    _internalTrackNoController.text = value;
                                  });
                                },
                                child: Image.asset(
                                  'assets/images/scan.png',
                                  width: 32.0,
                                  height: 32.0,
                                  color: Colors.white,
                                ),
                              ),*/
                              SizedBox(width: 5.0),
                              _searchButton,
                              InkWell(
                                onTap: _reset,
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Icon(
                                    Icons.refresh,
                                    color: Colors.white,
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
              ],
            ),
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: TextField(
                      cursorWidth: 1,
                      cursorColor: Colors.white,
                      controller: _customerIdController,
                      decoration: _decoration(
                          hintText: Utils.getLocale(context)?.customerCode),
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: TextField(
                      cursorWidth: 1,
                      cursorColor: Colors.white,
                      controller: _packCountController,
                      keyboardType: TextInputType.number,
                      decoration: _decoration(
                          hintText:
                              '${Utils.getLocale(context)?.packs[0].toUpperCase()}${Utils.getLocale(context)?.packs.substring(1)}'),
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10.0),
              ],
            ),
          ],
        ),
      ),
    );

    /*return Container(
      child: ExpansionTile(
        maintainState: true,
        title: Text('${Utils.getLocale(context).search}'),
        childrenPadding: const EdgeInsets.all(10.0),
        backgroundColor: Colors.white,
        children: [
          InfoItem(
            firstText: '${Utils.getLocale(context).status}',
            secondText: _statusText,
            breakLine: _statusText.contains(',') ? true : false,
            onTap: () async {
              List<int> result = await Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => SelectOrderStatusScreen(_statusList)));
              if (result != null && mounted) {
                setState(() {
                  _statusList
                    ..clear()
                    ..addAll(result);
                  _statusText = _getStatusText();
                });
              }
            },
          ),
          const Divider(),
          const SizedBox(height: 10.0),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${Utils.getLocale(context).customerCode}: '),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: _rightWidth,
                    child: TextField(
                      controller: _customerIdController,
                      decoration: _decoration(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${Utils.getLocale(context).chineseWaybillCode}: '),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: _rightWidth,
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _internalTrackNoController,
                            decoration: _decoration(),
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        GestureDetector(
                          onTap: () {
                            FlutterBarcodeScanner.scanBarcode(
                              '#ff6666',
                              '${Utils.getLocale(context).cancel}',
                              true,
                              ScanMode.DEFAULT,
                            ).then((value) {
                              if (value == '-1') value = '';
                              _internalTrackNoController.text = value;
                            });
                          },
                          child: Image.asset(
                            'assets/images/scan.png',
                            width: 36.0,
                            height: 36.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${Utils.getLocale(context).internationalWaybillCode}: '),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: _rightWidth,
                    child: TextField(
                      controller: _externalTrackNoController,
                      decoration: _decoration(),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15.0),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${Utils.getLocale(context).time}: '),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: _rightWidth,
                    child: Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  keyboardType: TextInputType.datetime,
                                  inputFormatters: [_maskFormatter],
                                  controller: _fromDateController,
                                  decoration:
                                      _decoration(hintText: 'yyyy-MM-dd'),
                                  style: TextStyle(
                                    fontSize: 12.0,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _selectDate(context, onPicked: (date) {
                                    if (date != null) {
                                      _fromDateController.text =
                                          _dateFormat.format(date);
                                    }
                                  });
                                },
                                child: Icon(
                                  Icons.date_range,
                                  color: Theme.of(context).disabledColor,
                                ),
                              )
                            ],
                          ),
                        ),
                        Text(' ~ '),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  keyboardType: TextInputType.datetime,
                                  inputFormatters: [_maskFormatter],
                                  controller: _toDateController,
                                  decoration:
                                      _decoration(hintText: 'yyyy-MM-dd'),
                                  style: TextStyle(
                                    fontSize: 12.0,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _selectDate(context, onPicked: (date) {
                                    if (date != null) {
                                      _toDateController.text =
                                          _dateFormat.format(date);
                                    }
                                  });
                                },
                                child: Icon(
                                  Icons.date_range,
                                  color: Theme.of(context).disabledColor,
                                ),
                              )
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: _searchButton,
                ),
              ),
              IconButton(
                onPressed: _reset,
                icon: Icon(
                  Icons.refresh,
                  color: Theme.of(context).disabledColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
        ],
      ),
    );*/
  }

  InkWell get _searchButton => InkWell(
        onTap: () {
          FocusScope.of(context).requestFocus(FocusNode()); // unfocus
          if (!_validateSearchForm()) return;

          _showWaiting();
          Future.delayed(Duration(milliseconds: 500), () async {
            _getStatistics();
            AppProvider.of(context)?.state.orderBloc.updateFilter(
              OrderFilter(
                  statusList: _statusList,
                  customerId: _customerIdController.text!.trim(),
                  externalTrackNo: SessionUtil.instance().user.userType !=
                          UserType.chineseWarehouseStaff
                      ? _internalTrackNoController.text!.trim()
                      : '',
                  internalTrackNo: SessionUtil.instance().user.userType ==
                          UserType.chineseWarehouseStaff
                      ? _internalTrackNoController.text!.trim()
                      : '',
                  fromDate: _fromDateController.text!.trim(),
                  toDate: _toDateController.text!.trim(),
                  packCount: _packCountController.text!.trim().parseInt(),
                  goodsDescr: _goodsDescrController.text!.trim() ?? '',
                  licensePlates: _licensePlatesController.text!.trim() ?? ''),
              done: () {
                _popLoading();
              },
            );
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            Icons.search,
            color: Colors.white,
          ),
        ),
      );

  void _getStatistics() {
    if (this.widget.onCustomerCodeChange == null) return;
    final String text = _customerIdController.text!.trim();
    this.widget.onCustomerCodeChange(text);
  }

  void _reset() {
    _statusList
      ..clear()
      ..addAll(OrderStatus.values);
    _customerIdController.clear();
    _internalTrackNoController.clear();
    _externalTrackNoController.clear();
    _fromDateController.clear();
    _toDateController.clear();
    _packCountController.clear();
    _goodsDescrController.clear();
    _licensePlatesController.clear();
    _searchButton.onTap!();
  }

  void _showWaiting() {
    Utils.showLoading(context,
        textContent: Utils.getLocale(context)!.waitForLogin);
  }

  void _popLoading() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  bool _validateSearchForm() {
    late DateTime fromDate;
    late DateTime toDate;

    if (!Utils.isNullOrEmpty(_fromDateController.text!.trim())) {
      try {
        fromDate = DateTime.parse(_fromDateController.text.trim());
      } catch (e) {
        // ignored
      }
    }

    if (!Utils.isNullOrEmpty(_toDateController.text!.trim())) {
      try {
        toDate = DateTime.parse(_toDateController.text.trim());
      } catch (e) {
        // ignored
      }
    }

    if (fromDate != null && toDate != null && fromDate.isAfter(toDate)) {
      Utils.alert(context,
          title: Utils.getLocale(context)?.errorOccurred,
          message: '${Utils.getLocale(context)?.wrongDateRangeMessage}');
      return false;
    }

    return true;
  }

  /*Future<void> _selectDate(BuildContext context,
      {ValueChanged<DateTime> onPicked}) async {
    final DateTime picked = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2101));

    if (onPicked != null) {
      onPicked(picked);
    }
  }*/

  /*String _getStatusText() {
    if (_statusList.length == OrderStatus.values.length)
      return '${Utils.getLocale(context).all}';
    List<String> statusStrings =
        _statusList.map((o) => Utils.getOrderStatusString(context, o)).toList();
    return statusStrings.join(', ');
  }*/

  InputDecoration _decoration({String? hintText}) {
    return InputDecoration(
      border: OutlineInputBorder(
        borderSide: BorderSide(width: 0.5, color: Colors.white),
        borderRadius: BorderRadius.circular(2.0),
      ),
      disabledBorder: OutlineInputBorder(
        borderSide: BorderSide(width: 0.5, color: Colors.white),
        borderRadius: BorderRadius.circular(2.0),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(width: 0.5, color: Colors.white),
        borderRadius: BorderRadius.circular(2.0),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(width: 0.8, color: Colors.white),
        borderRadius: BorderRadius.circular(2.0),
      ),
      isDense: true,
      contentPadding: EdgeInsets.all(4.0),
      hintText: hintText ?? '',
      hintStyle: TextStyle(
        fontSize: 12.0,
        color: Colors.white,
      ),
    );
  }
}
