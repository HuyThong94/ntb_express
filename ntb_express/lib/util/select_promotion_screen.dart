import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ntbexpress/model/order.dart';
import 'package:ntbexpress/model/promotion.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/http_util.dart';
import 'package:ntbexpress/util/utils.dart';
import 'package:ntbexpress/util/extensions.dart';

class SelectPromotionScreen extends StatefulWidget {
  final Order order;
  final Promotion current;

  SelectPromotionScreen({this.order, this.current});

  @override
  _SelectPromotionScreenState createState() => _SelectPromotionScreenState();
}

class _SelectPromotionScreenState extends State<SelectPromotionScreen> {
  Promotion _current;
  final List<Promotion> _promotionList = [];
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _current = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      _init();
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: Icon(Icons.close),
        ),
        title: Text(
            '${Utils.getLocale(context).select} ${Utils.getLocale(context).promotion}'),
      ),
          body: Container(
      child: !_loaded
      ? Center(child: CircularProgressIndicator())
        : _promotionList.isEmpty
                ? Center(
                    child: Text('${Utils.getLocale(context).empty}'),
                  )
                : ListView.separated(
                    itemBuilder: (context, index) {
                      final promotion = _promotionList[index];
                      return Container(
                        color:
                            promotion.valid ? Colors.white : Utils.unreadColor,
                        child: ListTile(
                          onTap: !promotion.valid
                              ? null
                              : () {
                                  if (mounted) {
                                    setState(() => _current = promotion);
                                  }
                                },
                          title: Wrap(
                            children: [
                              //_getTag(promotion),
                              //const SizedBox(width: 4.0),
                              Text('${promotion.promotionName}'),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4.0,),
                              RichText(
                                text: TextSpan(
                                  style: Theme.of(context).textTheme.bodyText2,
                                  text: '${Utils.getLocale(context).applyFor} ',
                                  children: [
                                    TextSpan(
                                      text: Utils.getGoodsTypeString(
                                          context, promotion.goodsType),
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                  ],
                                ),
                              ),
                              Text(promotion.description),
                              //Text(promotion.description ?? ''),
                              Text(
                                  '${Utils.getLocale(context).expiryDate}: ${Utils.getDateString(promotion.startDate, 'dd.MM.yyyy')} - ${Utils.getDateString(promotion.endDate, 'dd.MM.yyyy')}'),
                            ],
                          ),
                          trailing: _current != null &&
                                  _current.promotionId == promotion.promotionId
                              ? Icon(
                                  Icons.check_circle,
                                  color: Utils.accentColor,
                                )
                              : Icon(Icons.radio_button_unchecked),
                        ),
                      );
                    },
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 4.0),
                    itemCount: _promotionList.length,
                  ),
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(_current == null
                  ? '${Utils.getLocale(context).noPromotionSelected}'
                  : '${Utils.getLocale(context).onePromotionSelected}. ${_current.promotionName}'),
            ),
            SizedBox(
              width: double.infinity,
              height: 40.0,
              child: RaisedButton(
                color: Utils.accentColor,
                onPressed: () {
                  Navigator.of(context).pop(_current);
                },
                child: Text(
                  'OK',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getTag(Promotion promotion) {
    var nf = NumberFormat.currency(locale: 'vi_VN');
    String tagText = '';
    final String discount = promotion?.discountValue?.toString() ?? '';
    if (promotion.promotionType == PromotionType.percent) {
      tagText =
          '${Utils.getLocale(context).discount.replaceFirst('%value%', '${promotion?.discountValue?.isInt ?? false ? discount.substring(0, discount.indexOf('.')) : discount}')}% (${Utils.getLocale(context).max} ${nf.format(promotion?.maxDiscountValue ?? 0)})';
    } else if (promotion.promotionType == PromotionType.specificValue) {
      tagText = Utils.getLocale(context)
          .discount
          .replaceFirst('%value%', '${nf.format(promotion.discountValue ?? 0)}');
    } else if (promotion.promotionType == PromotionType.samePrice) {
      tagText = Utils.getLocale(context)
          .discount
          .replaceFirst('%value%', '${nf.format(promotion.discountValue ?? 0)}');
    }

    return Container(
      padding: const EdgeInsets.all(2.0),
      color: Colors.orange,
      child: Text(
        tagText,
        style: TextStyle(color: Colors.white, fontSize: 12.0),
      ),
    );
  }

  Future<List<Promotion>> _getPromotionList() async {
    final Completer<List<Promotion>> c = Completer();
    if (widget.order == null) {
      c.complete([]);
      return c.future;
    }

    final url = ApiUrls.instance().getPromotionListByOrderUrl(widget.order);

    HttpUtil.get(
      url,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      onResponse: (resp) {
        if (resp == null || resp.statusCode != 200) {
          Utils.alert(context,
              title: Utils.getLocale(context).failed,
              message:
                  '${Utils.getLocale(context).errorOccurred} ${resp?.statusCode}');

          if (!c.isCompleted) {
            c.complete([]);
          }
          return;
        }

        List<dynamic> json = jsonDecode(utf8.decode(resp.bodyBytes));
        if (json == null || json.isEmpty) {
          if (!c.isCompleted) {
            c.complete([]);
          }
          return;
        }

        if (!c.isCompleted) {
          c.complete(json.map((o) => Promotion.fromJson(o)).toList());
        }
      },
      onTimeout: () {
        Utils.alert(context,
            title: Utils.getLocale(context).errorOccurred,
            message: Utils.getLocale(context).requestTimeout);

        _loaded = true;
        if (!c.isCompleted) {
          c.complete([]);
        }
      },
    );

    return c.future;
  }

  Future<void> _init() async {
    var rs = await _getPromotionList();
    _promotionList.addAll(rs);
    if (mounted) {
      setState(() => _loaded = true);
    }
  }
}
