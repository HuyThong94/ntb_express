import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ntbexpress/model/address.dart';
import 'package:ntbexpress/model/user.dart';
import 'package:ntbexpress/screens/address_form_screen.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/http_util.dart';
import 'package:ntbexpress/util/utils.dart';

class SelectAddressScreen extends StatefulWidget {
  final User? customer;
  final Address? current;

  SelectAddressScreen({this.customer, this.current});

  @override
  _SelectAddressScreenState createState() => _SelectAddressScreenState();
}

class _SelectAddressScreenState extends State<SelectAddressScreen> {
  late Address _current;

  @override
  void initState() {
    super.initState();
    _current = widget.current!;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(_current),
          icon: Icon(Icons.close),
        ),
        title: Text('${Utils.getLocale(context).selectAnAddress}'),
      ),
      body: Container(
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
              return Center(
                child: Text('${Utils.getLocale(context).empty}'),
              );
            }

            final addressList = snapshot.data;

            return Scrollbar(
              child: ListView.separated(
                itemBuilder: (context, index) {
                  final address = addressList?[index];
                  return ListTile(
                    onTap: () {
                      if (mounted) {
                        setState(() => _current = address!);
                      }
                      Navigator.of(context).pop(_current);
                    },
                    title: Text('${address!.fullName}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(address!.phoneNumber ?? ''),
                        Text([
                          address.address,
                          address.wards,
                          address.district,
                          address.province
                        ].join(', ')!.replaceAll(' ,', '')),
                      ],
                    ),
                    trailing: _current != null &&
                            _current.addressId == address.addressId
                        ? Icon(
                            Icons.done,
                            color: Utils.accentColor,
                          )
                        : SizedBox(),
                  );
                },
                separatorBuilder: (context, index) => Divider(),
                itemCount: addressList!.length,
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => AddressFormScreen(forUser: widget.customer)));
          setState(() {}); // reset state to load new address if added
        },
        child: Icon(Icons.add, size: 35.0),
      ),
    );
  }

  Future<List<Address>> _getAddressList() async {
    final Completer<List<Address>> c = Completer();
    final url =
        ApiUrls.instance().getAddressListByUserUrl(widget.customer!.username);

    HttpUtil.get(
      url!,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      onResponse: (resp) {
        if (resp == null || resp.statusCode != 200) {
          Utils.alert(context,
              title: Utils.getLocale(context).failed,
              message: '${Utils.getLocale(context).errorOccurred}: ${resp?.statusCode}');

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
