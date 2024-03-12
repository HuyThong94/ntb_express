import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ntbexpress/model/user.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/http_util.dart';
import 'package:ntbexpress/util/session_util.dart';
import 'package:ntbexpress/util/utils.dart';
import 'package:rxdart/rxdart.dart';

class UserBloc {
  User _currentUser = User();
  final List<User> _customers = <User>[];
  int _currentPage = 0;
  final int _pageSize = 20;

  late BehaviorSubject<User> _currentUserSubject;
  late BehaviorSubject<List<User>> _customersSubject;

  UserBloc() {
    _currentUserSubject = BehaviorSubject<User>.seeded(_currentUser);
    _customersSubject = BehaviorSubject<List<User>>.seeded(_customers);
    //_currentUserSubject.stream.listen(_handleCurrentUser);
    //_customersSubject.stream.listen(_handleCustomers);
  }

  void _handleCurrentUser(User user) {
    _currentUser = user;
    _currentUserSubject.add(_currentUser);
  }

  void _handleCustomers(List<User> customers) {
    _customers.clear();
    if (customers != null) {
      customers.forEach((cus) => _customers.add(cus));
    }
    _customersSubject.sink.add(_customers);
  }

  void fetch({int page = 0, bool reset = false, VoidCallback? done}) {
    if (reset) page = 0;
    _currentPage = page;

    if (SessionUtil.instance().isLoggedIn()) {
      final url =
          '${ApiUrls.instance().getUsersUrl()}?page=$page&size=$_pageSize';
      HttpUtil.get(
        url,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        onResponse: (resp) {
          if (resp == null ||
              (resp.statusCode != 200 || Utils.isNullOrEmpty(resp.body))) {
            _updateCurrentPage();
            done?.call();
            return;
          }
          List<dynamic> jsonList = jsonDecode(utf8.decode(resp.bodyBytes));
          List<User> orderList =
              jsonList.map((json) => User.fromJson(json)).toList();
          if (orderList == null) {
            if (reset) {
              _customers.clear();
              _customersSubject.sink.add(_customers);
              _currentPage = 0;
            } else {
              _updateCurrentPage();
            }
            done?.call();
            return;
          }
          if (reset) _customers.clear();
          _addAll(orderList);
          _sort();
          _customersSubject.sink.add(_customers);
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

  void _updateCurrentPage() {
    _currentPage = _customers == null || _customers.isEmpty
        ? 0
        : (_customers.length / _pageSize).ceil() - 1; // start page = 0
  }

  void loadMore({VoidCallback? done}) {
    fetch(page: _currentPage + 1, done: done);
  }

  void _sort() {
    _customers.sort((a, b) => a == null || b == null
        ? 0
        : b.createdDate.toInt() == null || a.createdDate.toInt() == null
            ? 0
            : b.createdDate.toInt() - a.createdDate.toInt());
  }

  void _addAll(List<User> customerList) {
    if (customerList == null || customerList.isEmpty) return;
    if (_customers == null || _customers.isEmpty) {
      _customers.addAll(customerList);
      return;
    }

    customerList.forEach((o) {
      _customers.removeWhere((e) => e.username == o.username);
      _customers.add(o);
    });
  }

  // Set current user
  void setCurrentUser(User user) {
    _handleCurrentUser(user);
  }

  /// Set customers
  void setCustomers(List<User> customers) {
    _handleCustomers(customers);
  }

  /// Add customer if does not exist, otherwise update customer from list
  void updateCustomer(User customer) {
    if (customer == null) return;

    final index =
        _customers.indexWhere((cus) => cus.username == customer.username);
    if (index == -1) {
      // not found
      _customers.insert(0, customer);
    } else {
      _customers[index] = customer;
    }
    _sort();
    _customersSubject.sink.add(_customers);
  }

  // Remove customer from list
  void removeCustomer(User customer) {
    if (customer == null) return;

    _customers.removeWhere((cus) => cus.username == customer.username);
    _customersSubject.sink.add(_customers);
  }

  /// Current user stream
  Stream<User> get currentUser => _currentUserSubject.stream;

  Stream<List<User>> get customers => _customersSubject.stream;

  void reset() {
    _currentUser = User();
    _customers.clear();
    _currentUserSubject.sink.add(_currentUser);
    _customersSubject.sink.add(_customers);
  }

  void dispose() {
    _currentUserSubject?.close();
    _customersSubject?.close();
  }
}
