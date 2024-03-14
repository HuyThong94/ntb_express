import 'package:flutter/material.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/utils.dart';

class SelectOrderStatusScreen extends StatefulWidget {
  late final List<int> statusList;

  SelectOrderStatusScreen(this.statusList);

  @override
  _SelectOrderStatusScreenState createState() =>
      _SelectOrderStatusScreenState();
}

class _SelectOrderStatusScreenState extends State<SelectOrderStatusScreen> {
  bool _all = true;
  final int _maxLength = OrderStatus.values.length;
  late final List<int> _statusList = []..addAll(OrderStatus.values);

  @override
  void initState() {
    super.initState();
    if (widget.statusList != null) {
      _statusList
        ..clear()
        ..addAll(widget.statusList);

      _all = _statusList.length == _maxLength;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (_statusList!.length != widget.statusList!.length ?? 0) {
              Utils.confirm(context,
                  title: Utils.getLocale(context)?.confirmation,
                  message:
                      '${Utils.getLocale(context)?.confirmChangeSelectOrderStatusMessage}',
                  onAccept: () {
                _statusList.sort();
                Navigator.of(context).pop(_statusList);
              }, onDecline: () {
                Navigator.of(context).pop();
              });
              return;
            }

            _statusList.sort();
            Navigator.of(context).pop(_statusList);
          },
          icon: Icon(Icons.arrow_back),
        ),
        title: Text('${Utils.getLocale(context)?.select}'),
        actions: [
          IconButton(
            onPressed: () {
              if (_statusList.isEmpty) {
                _statusList.addAll(OrderStatus.values);
              }

              _statusList.sort();
              Navigator.of(context).pop(_statusList);
            },
            icon: Icon(Icons.done),
          ),
        ],
      ),
      body: Container(
        child: Scrollbar(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Checkbox(
                      onChanged: _handleAll,
                      value: _all,
                      activeColor: Utils.accentColor,
                    ),
                    Text('${Utils.getLocale(context)?.all}'),
                  ],
                ),
                Divider(),
                Column(
                  children: OrderStatus.values
                      .map((e) => Row(
                            children: [
                              Checkbox(
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked!) {
                                      if (!_statusList.contains(e))
                                        _statusList.add(e);
                                    } else {
                                      _statusList.removeWhere(
                                          (element) => element == e);
                                    }
                                    _updateAll();
                                  });
                                },
                                value: _statusList.contains(e),
                                activeColor: Utils.accentColor,
                              ),
                              Text('${Utils.getOrderStatusString(context, e)}'),
                            ],
                          ))
                      .toList(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handleAll(bool? checked) {
    setState(() {
      _all = checked!;
      if (checked) {
        _statusList
          ..clear()
          ..addAll(OrderStatus.values);
      } else {
        _statusList.clear();
      }
    });
  }

  void _updateAll() {
    if (_statusList.length == _maxLength) {
      _handleAll(true);
    } else {
      if (_all) {
        setState(() => _all = false);
      }
    }
  }
}
