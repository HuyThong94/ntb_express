import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:ntbexpress/bloc/notification_bloc.dart';
import 'package:ntbexpress/model/notification.dart' as own;
import 'package:ntbexpress/model/notification_detail.dart';
import 'package:ntbexpress/model/order.dart';
import 'package:ntbexpress/screens/order_detail_screen.dart';
import 'package:ntbexpress/sqflite/notification_provider.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/http_util.dart';
import 'package:ntbexpress/util/utils.dart';
import 'package:ntbexpress/widgets/app_provider.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _notificationProvider = NotificationProvider();
  final _limit = 20; // items on page
  bool _loaded = false;
  bool _showLoading = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.extentAfter == 0) {
      if (_showLoading)
        return; // incomplete action => do nothing (wait for action completed)

      setState(() {
        _showLoading = true;
      });

      Future.delayed(Duration(milliseconds: 500), () async {
        final bloc = AppProvider.of(context).state.notificationBloc;
        _notificationProvider
            .getOrderList(start: bloc.start, limit: _limit)
            .then((list) {
          print(list);
          if (list == null) {
            setState(() {
              _showLoading = false;
            });
            return;
          }
          List<own.Notification> current =
              bloc.current.map((o) => own.Notification.clone(o)).toList();
          if (current == null) current = [];
          current.addAll(list);
          bloc.setNotifications(current);
          setState(() {
            _showLoading = false;
          });
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final _notificationBloc = AppProvider.of(context).state.notificationBloc;

    return Scaffold(
      appBar: AppBar(
        title: Text(Utils.getLocale(context).notification),
      ),
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: Container(
          constraints: const BoxConstraints.expand(),
          child: StreamBuilder<List<own.Notification>>(
            stream: _notificationBloc.notifications,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(snapshot.error.toString()),
                );
              }

              if (snapshot.hasData) {
                if (snapshot.data == null || snapshot.data!.isEmpty) {
                  if (!_loaded) {
                    Future.delayed(const Duration(milliseconds: 500), () async {
                      _notificationProvider
                          .getOrderList(start: 0, limit: _limit)
                          .then((list) {
                        _notificationBloc.setNotifications(list);
                        setState(() => _loaded = true);
                      });
                    });

                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return Center(
                    child: Text(
                      Utils.getLocale(context).empty,
                      style: TextStyle(color: Theme.of(context).disabledColor),
                    ),
                  );
                }

                return _content(snapshot.data!, _notificationBloc);
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(),
                );
              }

              return SizedBox();
            },
          ),
        ),
      ),
      /*floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _notificationProvider.markedAllAsUnread();
          int unreadCount = await _notificationProvider.getUnreadCount();
          _notificationBloc.setUnreadCount(unreadCount);
          _notificationBloc.markedAs(read: false);
        },
        child: Icon(Icons.refresh),
      ),*/
    );
  }

  Widget _content(List<own.Notification> notifications, NotificationBloc bloc) {
    return Column(
      mainAxisSize: MainAxisSize.max,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          color: Utils.backgroundColor,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 10.0),
          child: Row(
            children: [
              Expanded(
                child: Text(Utils.getLocale(context).updateOrder),
              ),
              StreamBuilder<int>(
                  stream: bloc.unreadCount,
                  builder: (context, snapshot) {
                    final count = snapshot.data ?? 0;

                    return GestureDetector(
                      onTap: count == 0
                          ? null
                          : () async {
                              await _notificationProvider.markedAllAsRead();
                              int unreadCount =
                                  await _notificationProvider.getUnreadCount();
                              bloc.setUnreadCount(unreadCount);
                              bloc.markedAs(read: true);
                            },
                      child: Text(
                        Utils.getLocale(context).readAll,
                        style: TextStyle(
                          color: count == 0
                              ? Theme.of(context).disabledColor
                              : Color(Utils.hexColor('#f37121')),
                        ),
                      ),
                    );
                  })
            ],
          ),
        ),
        Expanded(
          child: Scrollbar(
            child: CustomScrollView(
              controller: _scrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              shrinkWrap: true,
              slivers: [
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final o = notifications[index];
                      return Slidable(
                        actionPane: SlidableScrollActionPane(),
                        child: NotificationItem(
                          o,
                          provider: _notificationProvider,
                          bloc: bloc,
                        ),
                        secondaryActions: [
                          IconSlideAction(
                            caption: Utils.getLocale(context).delete,
                            color: Colors.red,
                            icon: Icons.delete,
                            onTap: () async {
                              int affected =
                                  await _notificationProvider.delete(o.id);
                              if (affected > 0) {
                                bloc.removeNotification(o);
                                int unreadCount = await _notificationProvider
                                    .getUnreadCount();
                                bloc.setUnreadCount(unreadCount);
                              }
                            },
                          ),
                        ],
                      );
                    },
                    childCount: notifications.length,
                    addAutomaticKeepAlives: true,
                    addRepaintBoundaries: false,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Align(
                    alignment: Alignment.center,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 5.0),
                      child: SizedBox(
                        child: _showLoading
                            ? const CircularProgressIndicator(
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.grey),
                                strokeWidth: 2.0,
                              )
                            : const SizedBox(),
                        width: 20.0,
                        height: 20.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onRefresh() async {
    _notificationProvider.getOrderList().then((list) {
      AppProvider.of(context).state.notificationBloc.setNotifications(list);
    });
  }
}

class NotificationItem extends StatefulWidget {
  final own.Notification notification;
  final NotificationProvider provider;
  final NotificationBloc bloc;

  NotificationItem(this.notification,
      {required this.provider, required this.bloc});

  @override
  _NotificationItemState createState() => _NotificationItemState();
}

class _NotificationItemState extends State<NotificationItem>
    with TickerProviderStateMixin {
  bool _tapped = false;
  bool _loading = false;
  final List<NotificationDetail> _details = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color:
              widget.notification.read == 0 ? Utils.unreadColor : Colors.white,
          child: ListTile(
            onTap: () async {
              widget.provider
                  .markedAsReadByOrderId(widget.notification.orderId);
              widget.bloc
                  .markedAsBy(orderId: widget.notification.orderId, read: true);
              int unreadCount = await widget.provider.getUnreadCount();
              widget.bloc.setUnreadCount(unreadCount);

              HttpUtil.get(
                ApiUrls.instance().getOrderUrl(widget.notification.orderId),
                headers: {'Content-Type': 'application/json; charset=utf-8'},
                onResponse: (resp) {
                  if (resp != null && resp.statusCode == 200) {
                    dynamic json = jsonDecode(utf8.decode(resp.bodyBytes));
                    if (json == null) return;
                    Order order = Order.fromJson(json);
                    if (order == null) return;
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => OrderDetailScreen(order)));
                  }
                },
              );
            },
            trailing: GestureDetector(
              onTap: () {
                if (_tapped) {
                  setState(() => _tapped = false);
                  return;
                }

                setState(() => _loading = true);
                final no = widget.notification;
                Future.delayed(const Duration(milliseconds: 500), () async {
                  widget.provider
                      .getOrderDetailList(orderId: no.orderId)
                      .then((list) {
                    if (list == null) {
                      setState(() {
                        _loading = false;
                        _tapped = _details.isNotEmpty ? true : false;
                      });
                      return;
                    }
                    list.removeWhere(
                        (o) => o.title == no.title && o.body == no.body);

                    list.sort((a, b) {
                      if (a.insertTime == null) a.insertTime = '';
                      if (b.insertTime == null) b.insertTime = '';

                      return b.insertTime.compareTo(a.insertTime);
                    });
                    setState(() => _details
                      ..clear()
                      ..addAll(list));

                    setState(() {
                      _loading = false;
                      _tapped = _details.isNotEmpty ? true : false;
                    });
                  });
                });
              },
              child: _loading
                  ? SizedBox(
                      width: 15.0,
                      height: 15.0,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : Icon(_tapped
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down),
            ),
            title: Text(
              '${widget.notification.orderId} - ${widget.notification.title}',
              style: TextStyle(color: Colors.black),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.notification.body),
                const SizedBox(height: 5.0),
                Text(
                  Utils.getDateString2(
                      widget.notification.insertTime, 'dd.MM.yyyy HH:mm'),
                  style: _small(),
                ),
              ],
            ),
          ),
        ),
        AnimatedSize(
          vsync: this,
          duration: const Duration(milliseconds: 200),
          child: Container(
            color: Utils.grey,
            width: double.infinity,
            child: !_tapped || _details.isEmpty
                ? null
                : Column(
                    children: _details
                        .map((o) => ListTile(
                              title: Text('${o.title}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(o.body),
                                  const SizedBox(height: 5.0),
                                  Text(
                                    Utils.getDateString2(
                                            o.insertTime, 'dd.MM.yyyy HH:mm') ??
                                        '',
                                    style: _small(),
                                  )
                                ],
                              ),
                            ))
                        .toList(),
                  ),
          ),
        ),
      ],
    );
  }

  TextStyle _small() {
    return TextStyle(fontSize: 10.0);
  }
}
