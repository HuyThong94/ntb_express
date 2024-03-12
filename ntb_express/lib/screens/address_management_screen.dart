import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ntbexpress/model/address.dart';
import 'package:ntbexpress/model/user.dart';
import 'package:ntbexpress/screens/address_form_screen.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/http_util.dart';
import 'package:ntbexpress/util/session_util.dart';
import 'package:ntbexpress/util/utils.dart';

class AddressManagementScreen extends StatefulWidget {
  final User forUser;

  AddressManagementScreen({required this.forUser});

  @override
  _AddressManagementScreenState createState() =>
      _AddressManagementScreenState();
}

class _AddressManagementScreenState extends State<AddressManagementScreen> {
  late User currentUser;

  @override
  void initState() {
    super.initState();

    currentUser = widget.forUser == null
        ? User.clone(SessionUtil.instance().user)
        : User.clone(widget.forUser);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(Utils.getLocale(context).myAddresses),
      ),
      body: SafeArea(
        child: Container(
          color: Utils.backgroundColor,
          constraints: const BoxConstraints.expand(),
          child: RefreshIndicator(
            onRefresh: _onRefresh,
            child: FutureBuilder<List<Address>>(
              future: _getAddressList(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                        '${Utils.getLocale(context).errorOccurred}: ${snapshot.error.toString()}'),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(4.0),
                        child: Text(
                          '${Utils.getLocale(context).addressNoteMessage}',
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            '${Utils.getLocale(context).empty}',
                            style:
                                TextStyle(color: Theme.of(context).disabledColor),
                          ),
                        ),
                      ),
                    ],
                  );
                }

                final addressList = snapshot.data;

                return Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(4.0),
                      child: Text(
                        '${Utils.getLocale(context).addressNoteMessage}',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          color: Theme.of(context).disabledColor,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Scrollbar(
                        child: ListView.separated(
                          itemBuilder: (context, index) {
                            final address = addressList![index];
                            var addrs = [
                              address.address,
                              address.wards,
                              address.district,
                              address.province
                            ];
                            return AddressItem(
                                onTap: () async {
                                  Address updatedAddress =
                                      await Navigator.of(context).push(
                                          MaterialPageRoute(
                                              builder: (_) => AddressFormScreen(
                                                  address: address,
                                                  forUser: currentUser,
                                                  isUpdate: true)));
                                  if (updatedAddress != null &&
                                      updatedAddress != address) {
                                    setState(() {}); // reload
                                  }
                                },
                                name: address.fullName,
                                phoneNumber: address.phoneNumber,
                                address: addrs.join(', ')!.replaceAll(' ,', ''));
                          },
                          separatorBuilder: (context, index) => Divider(
                            height: 0.5,
                            thickness: 0.5,
                          ),
                          itemCount: addressList!.length,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          var address = await Navigator.of(context).push(MaterialPageRoute(
              builder: (context) => AddressFormScreen(forUser: currentUser,)));
          if (address != null) {
            setState(() {}); // rebuild to load new address
          }
        },
        child: Icon(
          Icons.add,
          size: 35.0,
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    setState(() {}); // rebuild
  }

  Future<List<Address>> _getAddressList() async {
    final Completer<List<Address>> c = Completer();
    final url =
        ApiUrls.instance().getAddressListByUserUrl(currentUser.username);

    HttpUtil.get(
      url,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      onResponse: (resp) {
        if (resp == null || resp.statusCode != 200) {
          Utils.alert(context,
              title: Utils.getLocale(context).failed,
              message:
                  '${Utils.getLocale(context).errorOccurred}: ${resp?.statusCode}');

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
          c.complete(json.map((o) => Address.fromJson(o)).toList());
        }
      },
      onTimeout: () {
        Utils.alert(context,
            title: Utils.getLocale(context).errorOccurred,
            message: Utils.getLocale(context).requestTimeout);

        if (!c.isCompleted) {
          c.complete([]);
        }
      },
    );

    return c.future;
  }
}

class AddressItem extends StatelessWidget {
  final String name;
  final String phoneNumber;
  final String? email;
  final String address;
  final VoidCallback? onTap;

  AddressItem(
      {required this.name,
      required this.phoneNumber,
      this.email,
      required this.address,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
        color: Colors.white,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name ?? '',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Utils.isNullOrEmpty(email!) ? const SizedBox() : Text(email ?? ''),
            Text(phoneNumber ?? ''),
            Text(address ?? ''),
          ],
        ),
      ),
    );
  }
}
