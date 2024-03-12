import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:ntbexpress/model/order.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/http_util.dart';
import 'package:ntbexpress/util/session_util.dart';
import 'package:ntbexpress/util/utils.dart';
import 'package:rxdart/rxdart.dart';

class OrderBloc {
  final int _pageSize = 10;
  final List<Order> _orders = <Order>[];
  OrderFilter _filter = OrderFilter(statusList: [], customerId: '', internalTrackNo: '', externalTrackNo: '', fromDate: '', toDate: '', packCount: 0, goodsDescr: '', licensePlates: '');
  int _currentPage = 0;

  late BehaviorSubject<List<Order>> _ordersSubject;
  late BehaviorSubject<OrderFilter> _filterSubject;

  OrderBloc() {
    _ordersSubject = BehaviorSubject<List<Order>>.seeded(_orders);
    _filterSubject = BehaviorSubject<OrderFilter>.seeded(_filter);
  }

  void _handleOrders(List<Order> orders) {
    _orders.clear();
    if (orders != null) {
      orders.forEach((ord) => _orders.add(ord));
    }
    _ordersSubject.sink.add(_orders);
  }

  /// Set customers
  void setOrders(List<Order> orders) {
    _handleOrders(orders);
  }

  /// Add customer if does not exist, otherwise update customer from list
  void updateOrder(Order order) {
    if (order == null) return;

    final index = _orders.indexWhere((ord) => ord.orderId == order.orderId);
    if (index == -1) {
      // not found
      _orders.add(order);
      _sort();
    } else {
      _orders[index] = order;
    }
    _ordersSubject.sink.add(_orders);
  }

  // Remove customer from list
  void removeOrder(Order order) {
    if (order == null) return;

    _orders.removeWhere((ord) => ord.orderId == order.orderId);
    _ordersSubject.sink.add(_orders);
  }

  // Update filter
  void updateFilter(OrderFilter filter, {VoidCallback? done}) {
    if (filter == null) return;
    _filter.statusList = filter.statusList;
    _filter.customerId = filter.customerId;
    _filter.internalTrackNo = filter.internalTrackNo;
    _filter.externalTrackNo = filter.externalTrackNo;
    _filter.fromDate = filter.fromDate;
    _filter.toDate = filter.toDate;
    _filter.packCount = filter.packCount;
    _filter.goodsDescr = filter.goodsDescr;
    _filter.licensePlates = filter.licensePlates;

    fetch(reset: true, done: done);
  }

  void fetch({int page = 0, bool reset = false, VoidCallback? done}) {
    if (reset) page = 0;
    _currentPage = page;

    if (SessionUtil.instance().isLoggedIn()) {
      final url =
          '${ApiUrls.instance().getOrdersUrl()}?page=$page&size=$_pageSize&' +
              _filter.toQueryString();
      HttpUtil.get(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        onResponse: (resp) {
          if (resp == null || (resp.statusCode != 200 || Utils.isNullOrEmpty(resp.body))) {
            _updateCurrentPage();
            done?.call();
            return;
          }
          List<dynamic> jsonList = jsonDecode(utf8.decode(resp.bodyBytes));
          List<Order> orderList =
              jsonList.map((json) => Order.fromJson(json)).toList();
          if (orderList == null) {
            if (reset) {
              _orders.clear();
              _ordersSubject.sink.add(_orders);
              _currentPage = 0;
            } else {
              _updateCurrentPage();
            }
            done?.call();
            return;
          }
          if (reset) _orders.clear();
          _addAll(orderList);
          _sort();
          _ordersSubject.sink.add(_orders);
          _updateCurrentPage();
          done?.call();
        },
        onTimeout: () {
          debugPrint('Request timed out when trying to get order list!');
          _updateCurrentPage();
          done?.call();
        },
      );
    } else {
      print('User does not logged in!');
      done?.call();
    }
  }

  void _sort() {
    _orders.sort((a, b) => b.createdDate.toInt() - a.createdDate.toInt());
  }

  void _addAll(List<Order> orderList) {
    if (orderList == null || orderList.isEmpty) return;
    if (_orders == null || _orders.isEmpty) {
      _orders.addAll(orderList);
      return;
    }

    orderList.forEach((o) {
      _orders.removeWhere((e) => e.orderId == o.orderId);
      _orders.add(o);
    });
  }

  void _updateCurrentPage() {
    _currentPage = _orders == null || _orders.isEmpty
        ? 0
        : (_orders.length / _pageSize).ceil() - 1; // start page = 0
  }

  void loadMore({required VoidCallback done}) {
    fetch(page: _currentPage + 1, done: done);
  }

  Stream<List<Order>> get orders => _ordersSubject.stream;

  Stream<OrderFilter> get filter => _filterSubject.stream;

  void reset() {
    _currentPage = 0;
    _filter = OrderFilter(statusList: [], customerId: '', internalTrackNo: '', externalTrackNo: '', fromDate: '', toDate: '', packCount: 0, goodsDescr: '', licensePlates: '');
    _orders.clear();
    _ordersSubject.sink.add(_orders);
    _filterSubject.sink.add(_filter);
  }

  void dispose() {
    _ordersSubject?.close();
    _filterSubject?.close();
  }
}

class OrderFilter {
  List<int> statusList = []..addAll(OrderStatus.values);
  String customerId;
  String internalTrackNo;
  String externalTrackNo;
  String fromDate;
  String toDate;
  int packCount;
  String goodsDescr;
  String licensePlates;

  OrderFilter(
      {required this.statusList,
      required this.customerId,
      required this.internalTrackNo,
      required this.externalTrackNo,
      required this.fromDate,
      required this.toDate,
      required this.packCount,
      required this.goodsDescr,
      required this.licensePlates}) {
    if (statusList == null) {
      statusList = []..addAll(OrderStatus.values);
    }
  }

  Map<String, dynamic> toBodyRequest() {
    Map<String, dynamic> rs = {};
    if (statusList != null && statusList.length != OrderStatus.values.length)
      rs['orderStatus'] = statusList;
    if (!Utils.isNullOrEmpty(customerId)) rs['customerId'] = customerId;
    if (!Utils.isNullOrEmpty(internalTrackNo))
      rs['intTrackNo'] = internalTrackNo;
    if (!Utils.isNullOrEmpty(externalTrackNo))
      rs['extTrackNo'] = externalTrackNo;
    if (!Utils.isNullOrEmpty(fromDate)) rs['fromCreatedDate'] = fromDate;
    if (!Utils.isNullOrEmpty(toDate)) rs['toCreatedDate'] = toDate;
    if (packCount != null && packCount > 0) rs['packCount'] = packCount;
    if (!Utils.isNullOrEmpty(goodsDescr)) rs['goodsDescr'] = goodsDescr;
    if (!Utils.isNullOrEmpty(licensePlates)) rs['licensePlates'] = licensePlates;

    return rs;
  }

  String toQueryString() {
    List<String> params = [];
    if (statusList.length != OrderStatus.values.length) {
      statusList.forEach((o) {
        params.add('orderStatus=$o');
      });
    }
    if (!Utils.isNullOrEmpty(customerId)) params.add('customerId=$customerId');
    if (!Utils.isNullOrEmpty(internalTrackNo))
      params.add('intTrackNo=$internalTrackNo');
    if (!Utils.isNullOrEmpty(externalTrackNo))
      params.add('extTrackNo=$externalTrackNo');
    if (!Utils.isNullOrEmpty(fromDate)) params.add('fromCreatedTime=$fromDate');
    if (!Utils.isNullOrEmpty(toDate)) params.add('toCreatedTime=$toDate');
    if (packCount != null && packCount > 0) params.add('packCount=$packCount');
    if (!Utils.isNullOrEmpty(goodsDescr)) params.add('goodsDescr=$goodsDescr');
    if (!Utils.isNullOrEmpty(licensePlates)) params.add('licensePlates=$licensePlates');

    return params.join('&') ?? '';
  }
}
