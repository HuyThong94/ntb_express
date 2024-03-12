import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ntbexpress/model/user.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/http_util.dart';
import 'package:ntbexpress/util/utils.dart';

class SelectUserScreen extends StatefulWidget {
  final User manager;
  final User current;

  SelectUserScreen(this.manager, this.current);

  @override
  _SelectUserScreenState createState() => _SelectUserScreenState();
}

class _SelectUserScreenState extends State<SelectUserScreen> {
  late User _current;
  final List<User> _userList = [];
  final List<User> _immutableUserList = [];

  @override
  void initState() {
    super.initState();
    _current = widget.current;
    _getUserList().then((value) {
      if (mounted) {
        setState(() {
          _userList.addAll(value);
          _immutableUserList.addAll(value);
        });
      } else {
        _userList.addAll(value);
        _immutableUserList.addAll(value);
      }
    });
  }

  Future<List<User>> _getUserList() async {
    final c = Completer<List<User>>();

    HttpUtil.get(
      ApiUrls.instance().getUsersUrl(),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      onResponse: (resp) {
        if (resp != null &&
            resp.statusCode == 200 &&
            !Utils.isNullOrEmpty(resp.body)) {
          List<dynamic> json = jsonDecode(utf8.decode(resp.bodyBytes));
          if (json == null || json.isEmpty) return c.complete([]);
          return c.complete(json.map((e) => User.fromJson(e)).toList());
        }

        return c.complete([]);
      },
      onTimeout: () {
        c.complete([]);
      },
    );

    return c.future;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close),
          ),
          title: Text('${Utils.getLocale(context).select}'),
        ),
        body: Container(
          child: Column(
            children: [
              TextField(
                onChanged: (value) {
                  if (Utils.isNullOrEmpty(value)) {
                    if (_userList.length != _immutableUserList.length) {
                      if (mounted) {
                        setState(() {
                          _userList
                            ..clear()
                            ..addAll(_immutableUserList);
                        });
                      } else {
                        _userList
                          ..clear()
                          ..addAll(_immutableUserList);
                      }
                    }
                  } else {
                    List<User> filteredList = _userList
                        .where((element) =>
                            (Utils.changeAlias(element.fullName)
                                .toLowerCase()
                                .contains(value.toLowerCase())) ||
                            (!Utils.isNullOrEmpty(element.phoneNumber) &&
                                element.phoneNumber.contains(value)) ||
                            (!Utils.isNullOrEmpty(element.customerId) &&
                                element.customerId
                                    .toLowerCase()
                                    .contains(value.toLowerCase())))
                        .toList();
                    _userList
                      ..clear()
                      ..addAll(filteredList);
                    setState(() {});
                  }
                },
                decoration: InputDecoration(
                    hintText: '${Utils.getLocale(context).search}...',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 10.0)),
              ),
              const Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10.0)),
              Expanded(
                child: ListView.separated(
                  itemBuilder: (context, index) {
                    final user = _userList[index];
                    return ListTile(
                      onTap: () {
                        if (mounted) {
                          setState(() => _current = user);
                        }
                        Navigator.of(context).pop(_current);
                      },
                      title: Text('${user.fullName}'),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.phoneNumber ?? ''),
                          Text(user.address ?? ''),
                        ],
                      ),
                      trailing:
                          _current != null && _current.username == user.username
                              ? Icon(
                                  Icons.done,
                                  color: Utils.accentColor,
                                )
                              : SizedBox(),
                    );
                  },
                  separatorBuilder: (context, index) => Divider(),
                  itemCount: _userList.length,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
