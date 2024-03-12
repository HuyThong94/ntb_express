import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ntbexpress/model/address.dart';
import 'package:ntbexpress/model/fee_item.dart';
import 'package:ntbexpress/model/user.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/http_util.dart';
import 'package:ntbexpress/util/price_calculation_util.dart';
import 'package:ntbexpress/util/select_area_screen.dart';
import 'package:ntbexpress/util/utils.dart';
import 'package:ntbexpress/widgets/info_item.dart';
import 'package:ntbexpress/util/extensions.dart';

class PriceCalculationScreen extends StatefulWidget {
  final User currentUser;

  PriceCalculationScreen({required this.currentUser});

  @override
  _PriceCalculationScreenState createState() => _PriceCalculationScreenState();
}

class _PriceCalculationScreenState extends State<PriceCalculationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _weightController = TextEditingController();
  final _sizeController = TextEditingController();
  final _weightFocusNode = FocusNode();
  final _sizeFocusNode = FocusNode();
  int _goodsType = GoodsType.normal;
  late String _totalFee;

  late Address _address;

  @override
  void initState() {
    super.initState();
    _address = Address();
    _getFeeTable();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            icon: Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
          title: Text(Utils.getLocale(context).priceCalculation),
        ),
        body: SafeArea(
          child: Container(
            padding: const EdgeInsets.only(left: 10.0, top: 10.0, right: 10.0),
            constraints: const BoxConstraints.expand(),
            color: Colors.white,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        Utils.getLocale(context).priceCalculationNoteMessage,
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ),
                    Divider(),
                    InfoItem(
                      firstText: '${Utils.getLocale(context).province} ',
                      secondText: _address.province ?? '',
                      onTap: () async {
                        String selectedCity = await Utils.selectArea(
                          context,
                          target: AreaTarget.province,
                          currentProvince: _address.province,
                          title:
                              '${Utils.getLocale(context).select} ${Utils.getLocale(context).province}',
                        );

                        if (_address.province != selectedCity) {
                          setState(() {
                            _address.province = selectedCity;
                            // reset district & wards
                            _address.district = '';
                            _address.wards = '';
                          });
                        }
                      },
                    ),
                    Divider(),
                    Row(
                      children: [
                        Text('${Utils.getLocale(context).goodsType}'),
                        SizedBox(
                          width: 10.0,
                        ),
                        DropdownButton<int>(
                          disabledHint: Text(
                              '${Utils.getGoodsTypeString(context, _goodsType)}'),
                          value: _goodsType,
                          items: _dropDownGoodsTypeItems(),
                          onChanged: _onGoodsTypeChanged,
                        ),
                      ],
                    ),
                    Divider(),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _weightController,
                            focusNode: _weightFocusNode,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            onChanged: (value) {
                              //_updateExtFee();
                            },
                            onFieldSubmitted: (val) {
                              _weightFocusNode.unfocus();
                              FocusScope.of(context)
                                  .requestFocus(_sizeFocusNode);
                            },
                            decoration: InputDecoration(
                                labelText:
                                    '${Utils.getLocale(context).weight} (kg)',
                                hintText:
                                    '${Utils.getLocale(context).enter} ${Utils.getLocale(context).weight.toLowerCase()} (kg)...',
                                counterText: ''),
                            maxLines: 1,
                            validator: (value) {
                              String tmp = _sizeController.text;

                              if ((Utils.isNullOrEmpty(value!) ||
                                      value == '0' ||
                                      value == '0.0') &&
                                  (Utils.isNullOrEmpty(tmp) ||
                                      tmp == '0' ||
                                      tmp == '0.0'))
                                return Utils.getLocale(context).required;

                              return null;
                            },
                          ),
                        ),
                        SizedBox(width: 5.0),
                        Expanded(
                          child: TextFormField(
                            controller: _sizeController,
                            focusNode: _sizeFocusNode,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            onChanged: (value) {
                              //_updateExtFee();
                            },
                            onFieldSubmitted: (val) {
                              _sizeFocusNode.unfocus();
                              //FocusScope.of(context).requestFocus(
                              //    _payOnBehalfFocusNode);
                            },
                            decoration: InputDecoration(
                                labelText:
                                    '${Utils.getLocale(context).size} (m³)',
                                hintText:
                                    '${Utils.getLocale(context).enter} ${Utils.getLocale(context).size.toLowerCase()} (m³)...',
                                counterText: ''),
                            maxLines: 1,
                            validator: (value) {
                              String tmp = _weightController.text;

                              if ((Utils.isNullOrEmpty(value!) ||
                                      value == '0' ||
                                      value == '0.0') &&
                                  (Utils.isNullOrEmpty(tmp) ||
                                      tmp == '0' ||
                                      tmp == '0.0'))
                                return Utils.getLocale(context).required;

                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 40.0,
                    ),
                    SizedBox(
                      width: double.infinity,
                      height: 50.0,
                      child: RaisedButton(
                        onPressed: _saveData,
                        disabledColor: Colors.black12,
                        disabledTextColor: Colors.white70,
                        color: Utils.accentColor,
                        textColor: Colors.white,
                        child: Text(
                          Utils.getLocale(context).calculate,
                          style: TextStyle(
                            fontSize: 20.0,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 40.0,
                    ),
                    Visibility(
                      visible: !Utils.isNullOrEmpty(_totalFee),
                      child: Row(
                        children: [
                          Text('${Utils.getLocale(context).result}: ', style: TextStyle(fontSize: 20.0),),
                          Text(_totalFee ?? '', style: TextStyle(fontSize: 20.0, color: Utils.accentColor)),
                        ],
                      ),
                    ),
                    Visibility(
                      visible: !Utils.isNullOrEmpty(_totalFee),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          Utils.getLocale(context).priceCalculationNote,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _getFeeTable() {
    if (feeTable.isNotEmpty) return;
    HttpUtil.getNotAuth(
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

  void _saveData() {
    setState(() {
      // _totalFee = null; // reset result
      FocusScope.of(context).requestFocus(FocusNode());
    });

    if (Utils.isNullOrEmpty(_address.province)) {
      Utils.alert(
        context,
        title: Utils.getLocale(context).required,
        message: Utils.getLocale(context).addressIsRequired,
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _totalFee = Utils.getMoneyString(PriceCalculationUtil.calculateExtFee(
          address: _address,
          goodsType: _goodsType,
          weight: _weightController.text.trim().parseDouble(),
          size: _sizeController.text.trim().parseDouble()));
    });
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

  void _onGoodsTypeChanged(int value) {
    setState(() => _goodsType = value);
    //_updateExtFee();
  }
}
