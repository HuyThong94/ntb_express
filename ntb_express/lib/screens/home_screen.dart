import 'dart:convert';

import 'package:app_settings/app_settings.dart';
import 'package:badges/badges.dart';

/// home screen => display order list
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'package:ntbexpress/bloc/notification_bloc.dart';
import 'package:ntbexpress/bloc/order_bloc.dart';
import 'package:ntbexpress/model/order.dart';
import 'package:ntbexpress/model/user.dart';
import 'package:ntbexpress/screens/address_management_screen.dart';
import 'package:ntbexpress/screens/change_password_screen.dart';
import 'package:ntbexpress/screens/customer_management_screen.dart';
import 'package:ntbexpress/screens/notification_screen.dart';
import 'package:ntbexpress/screens/order_detail_screen.dart';
import 'package:ntbexpress/screens/order_form_screen.dart';
import 'package:ntbexpress/screens/order_list_screen.dart';
import 'package:ntbexpress/screens/profile_screen.dart';
import 'package:ntbexpress/screens/setting_screen.dart';
import 'package:ntbexpress/sqflite/notification_provider.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/http_util.dart';
import 'package:ntbexpress/util/select_order_status_screen.dart';
import 'package:ntbexpress/util/session_util.dart';
import 'package:ntbexpress/util/utils.dart';
import 'package:ntbexpress/widgets/app_provider.dart';
import 'package:ntbexpress/widgets/hide_on_condition.dart';

//import 'package:ntbexpress/widgets/info_item.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _notificationProvider = NotificationProvider();
  bool _initialized = false;
  bool _loaded = false;
  bool _showLoading = false;
  final _scrollController = ScrollController();
  var _tapPosition;
  final List<dynamic> _statisticList = [];
  final String _statisticUrl = ApiUrls.instance().baseUrl + '/getStatistics/-1';

  bool get isCustomer =>
      SessionUtil.instance()?.user?.userType == UserType.customer;

  bool get isChineseWarehouseStaff =>
      (SessionUtil.instance()?.user?.userType ?? -1) ==
      UserType.chineseWarehouseStaff;

  bool get isAdmin => SessionUtil.instance()?.user?.userType == UserType.admin;

  bool get isSaleStaff =>
      SessionUtil.instance()?.user?.userType == UserType.saleStaff;

  User get _user => SessionUtil.instance()?.user;

  bool get isWarehouseStaff => [
        UserType.chineseWarehouseStaff,
        UserType.uongbiWarehouseStaff,
        UserType.hanoiWarehouseStaff,
        UserType.saigonWarehouseStaff
      ].contains(SessionUtil.instance()?.user?.userType ?? -1);

  @override
  void initState() {
    super.initState();
    //_scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    //_scrollController.removeListener(_scrollListener);
    // clear session
    SessionUtil.instance().reset();
    super.dispose();
  }

  Future<void> _requestPushPermissions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    if (prefs == null) return;
    final hasRequested = !prefs.containsKey(PrefsKey.requestPushPermissions)
        ? false
        : prefs.getBool(PrefsKey.requestPushPermissions);
    if (hasRequested) return;
    Utils.alert(
      context,
      title: Utils.getLocale(context).required,
      message: Utils.getLocale(context).requestPushPermissionsMessage,
      onAccept: () async {
        await AppSettings.openAppSettings();
        prefs.setBool(PrefsKey.requestPushPermissions, true);
      },
    );
  }

  void _scrollListener() {
    if (_scrollController.position.extentAfter == 0) {
      if (_showLoading)
        return; // incomplete action => do nothing (wait for action completed)

      setState(() {
        _showLoading = true;
      });
      Future.delayed(Duration(seconds: 1), () async {
        AppProvider.of(context).state.orderBloc?.loadMore(done: () {
          setState(() {
            _showLoading = false;
          });
        });
      });
    }
  }

  Future<void> _getStatisticList({String url}) async {
    HttpUtil.get(
      Utils.isNullOrEmpty(url) ? _statisticUrl : url,
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      onResponse: (resp) {
        if (resp == null ||
            resp.statusCode != 200 ||
            Utils.isNullOrEmpty(resp.body)) {
          _statisticList.clear();
          if (mounted) {
            setState(() {});
          }
          return;
        }

        dynamic response = jsonDecode(utf8.decode(resp.bodyBytes));
        if (response == null || !(response is List)) {
          _statisticList.clear();
          if (mounted) {
            setState(() {});
          }
          return;
        }

        _statisticList.clear();
        _statisticList.addAll(response);
        if (mounted) {
          setState(() {});
        }
      },
      onTimeout: () {
        _statisticList.clear();
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderBloc = AppProvider.of(context).state.orderBloc;
    final _notificationBloc = AppProvider.of(context).state.notificationBloc;
    if (!_initialized) {
      // get notification count
      _notificationProvider
          .getUnreadCount()
          .then((count) => _notificationBloc.setUnreadCount(count));
      _requestPushPermissions();
      _getStatisticList().then((value) {
        setState(() {}); // reset state for statistic list
      });
      _initialized = true;
    }

    return WillPopScope(
      onWillPop: () async => false,
      // on home screen => disable android back button
      child: GestureDetector(
        onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
        child: Scaffold(
          /*appBar: AppBar(

          ),*/
          key: _scaffoldKey,
          drawer: _buildDrawer(),
          body: StreamBuilder<List<Order>>(
              stream: orderBloc.orders,
              builder: (context, snapshot) {
                Widget result = SizedBox();

                if (snapshot.hasError) {
                  result = Center(
                    child: Text(snapshot.error.toString()),
                  );
                } else if (snapshot.hasData) {
                  if (snapshot.data == null || snapshot.data.isEmpty) {
                    if (!_loaded) {
                      Future.delayed(const Duration(milliseconds: 500),
                          () async {
                        orderBloc.fetch(
                            reset: true,
                            done: () {
                              if (mounted) {
                                setState(() => _loaded = true);
                              } else {
                                _loaded = true;
                              }
                            }); // fetch data
                      });

                      result = Center(
                        child: CircularProgressIndicator(),
                      );
                    } else {
                      result = Center(
                        child: Text(
                          '${Utils.getLocale(context).empty}',
                          style: TextStyle(
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                      );
                    }
                  } else {
                    result = _content(snapshot.data);
                  }
                } else if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  result = Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return NestedScrollView(
                  controller: _scrollController,
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        expandedHeight: 160.0,
                        floating: true,
                        pinned: true,
                        snap: true,
                        flexibleSpace: FlexibleSpaceBar(
                            background: SearchBoxFlexible(
                          orderBloc,
                          onCustomerCodeChange: (customerCode) {
                            final String url = Utils.isNullOrEmpty(customerCode)
                                ? _statisticUrl
                                : _statisticUrl + '/' + customerCode;
                            if (mounted) {
                              _getStatisticList(url: url);
                            }
                          },
                        )),
                        title: Text('${Utils.getLocale(context).order}'),
                        actions: [
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) => ProfileScreen(
                                        currentUser:
                                            SessionUtil.instance().user,
                                      )));
                            },
                            child: Center(
                              child: Row(
                                children: [
                                  StreamBuilder<User>(
                                    stream: AppProvider.of(context)
                                        .state
                                        .userBloc
                                        .currentUser,
                                    builder: (context, snapshot) {
                                      return CircleAvatar(
                                        radius: 18.0,
                                        backgroundImage: (snapshot.hasData &&
                                                snapshot.data != null &&
                                                snapshot.data.avatarImgDTO !=
                                                    null &&
                                                !Utils.isNullOrEmpty(snapshot
                                                    .data.avatarImgDTO.flePath))
                                            ? NetworkImage(
                                                '${ApiUrls.instance().baseUrl}/${snapshot.data.avatarImgDTO.flePath}')
                                            : AssetImage(
                                                'assets/images/default-avatar.png'),
                                      );
                                    },
                                  ),
                                  /*CircleAvatar(
                                    radius: 18.0,
                                    backgroundImage: (_user != null &&
                                            _user.avatarImgDTO != null &&
                                            !Utils.isNullOrEmpty(
                                                _user.avatarImgDTO.flePath))
                                        ? NetworkImage(
                                            '${ApiUrls.instance().baseUrl}/${SessionUtil.instance().user.avatarImgDTO.flePath}')
                                        : AssetImage(
                                            'assets/images/default-avatar.png'),
                                  ),*/
                                  const SizedBox(width: 5.0),
                                  Text(Utils.isNullOrEmpty(
                                          SessionUtil.instance()
                                              .user
                                              .customerId)
                                      ? SessionUtil.instance().user.username
                                      : SessionUtil.instance().user.customerId),
                                ],
                              ),
                            ),
                          ),
                          _notificationsBadge(_notificationBloc),
                        ],
                      ),
                    ];
                  },
                  body: RefreshIndicator(
                    onRefresh: _onRefresh,
                    child: result,
                  ),
                );
              }),
          floatingActionButton: Visibility(
            visible: _user.userType != UserType.customer && !isWarehouseStaff,
            child: FloatingActionButton(
              onPressed: () {
                Utils.updatePop(1);
                Navigator.of(context).push(
                    MaterialPageRoute(builder: (context) => OrderFormScreen()));
              },
              child: Icon(Icons.add, size: 35.0),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _onRefresh() async {
    AppProvider.of(context).state.orderBloc.fetch(reset: true);
  }

  Color _getColor(int orderStatus) {
    if (OrderStatus.pendingWoodenPacking == orderStatus)
      return OrderColor.waitWoodenConfirm;
    if (OrderStatus.aborted == orderStatus) return OrderColor.cancelled;

    return OrderColor.newlyCreated;
  }

  void _storePosition(TapDownDetails details) {
    _tapPosition = details.globalPosition;
  }

  String _getTotalFeeText(double totalFee) =>
      NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(totalFee);

  User get currentUser => SessionUtil.instance()?.user;

  TextStyle _statisticStyle(int orderStatus) {
    return TextStyle(
      fontSize: 9.0,
      color: _getTextColorByStatus(orderStatus),
    );
  }

  bool _isVisibleWeightSize(Order ord) {
    return (ord.weight != null && ord.weight > 0) ||
        (ord.size != null && ord.size > 0);
  }

  Color _getCardColorByStatus(int orderStatus) {
    Color result = Colors.transparent;
    switch (orderStatus) {
      case OrderStatus.newlyCreated:
        result = Color(Utils.hexColor('#CAE5FF'));
        break;
      case OrderStatus.aborted:
        result = Color(Utils.hexColor('#D7D8DA'));
        break;
      case OrderStatus.pendingWoodenPacking:
        result = Color(Utils.hexColor('#ECD180'));
        break;
      case OrderStatus.chineseWarehoused:
        result = Color(Utils.hexColor('#FAC7CC'));
        break;
      case OrderStatus.chineseShippedOut:
        result = Color(Utils.hexColor('#543B7C'));
        break;
      case OrderStatus.uongbiWarehoused:
      case OrderStatus.hanoiWarehoused:
      case OrderStatus.saigonWarehoused:
      case OrderStatus.outputUongBi:
      case OrderStatus.outputHaNoi:
      case OrderStatus.outputSaiGon:
        result = Color(Utils.hexColor('#D8EBD8'));
        break;
      case OrderStatus.delivery:
        result = Colors.orange;
        break;
      case OrderStatus.delivered:
        result = Colors.green;
        break;
      case OrderStatus.completed:
        result = Colors.indigo;
        break;
    }
    return result;
  }

  Color _getTextColorByStatus(int orderStatus) {
    Color result = Colors.transparent;
    switch (orderStatus) {
      case OrderStatus.newlyCreated:
        result = Color(Utils.hexColor('#234A75'));
        break;
      case OrderStatus.aborted:
        result = Color(Utils.hexColor('#161D27'));
        break;
      case OrderStatus.pendingWoodenPacking:
        result = Color(Utils.hexColor('#7F5E11'));
        break;
      case OrderStatus.chineseWarehoused:
        result = Color(Utils.hexColor('#843D45'));
        break;
      case OrderStatus.chineseShippedOut:
        result = Color(Utils.hexColor('#B1A5E3'));
        break;
      case OrderStatus.uongbiWarehoused:
      case OrderStatus.hanoiWarehoused:
      case OrderStatus.saigonWarehoused:
      case OrderStatus.outputUongBi:
      case OrderStatus.outputHaNoi:
      case OrderStatus.outputSaiGon:
        result = Color(Utils.hexColor('#29511F'));
        break;
      case OrderStatus.delivery:
        result = Colors.white;
        break;
      case OrderStatus.delivered:
        result = Colors.white;
        break;
      case OrderStatus.completed:
        result = Colors.white;
        break;
    }
    return result;
  }

  Widget _content(List<Order> orders) {
    return Builder(
      builder: (context) {
        final innerScrollController = PrimaryScrollController.of(context);
        innerScrollController.addListener(_scrollListener);

        return Scrollbar(
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ExpansionTile(
                  title: Text(Utils.getLocale(context).statistics),
                  maintainState: true,
                  children: [
                    _statisticList.isEmpty
                        ? SizedBox()
                        : GridView.builder(
                            physics: const NeverScrollableScrollPhysics(),
                            shrinkWrap: true,
                            itemCount: _statisticList.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount:
                                        MediaQuery.of(context).orientation ==
                                                Orientation.portrait
                                            ? 3
                                            : 3),
                            itemBuilder: (context, index) {
                              dynamic item = _statisticList[index];
                              int orderStatus = int.parse(
                                  item['orderStatus']?.toString() ?? '0');
                              int orderCount = int.parse(
                                  item['orderCount']?.toString() ?? '0');
                              double totalSize = double.parse(
                                  item['totalSize']?.toString() ?? '0');
                              double totalWeight = double.parse(
                                  item['totalWeight']?.toString() ?? '0');
                              double totalFee = double.parse(
                                  item['totalFee']?.toString() ?? '0');

                              return Card(
                                color: _getCardColorByStatus(orderStatus),
                                child: Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: GridTile(
                                    header: Text(
                                      Utils.getOrderStatusString(
                                              context, orderStatus) ??
                                          'Unknown',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 10.0,
                                        color:
                                            _getTextColorByStatus(orderStatus),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.only(top: 20.0),
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                Utils.getLocale(context)
                                                    .totalCount,
                                                style: _statisticStyle(
                                                    orderStatus),
                                              ),
                                              Expanded(
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: Text(
                                                    orderCount.toString() ?? '',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ).merge(_statisticStyle(
                                                        orderStatus)),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8.0),
                                          Row(
                                            children: [
                                              Text(
                                                Utils.getLocale(context)
                                                    .totalSize,
                                                style: _statisticStyle(
                                                    orderStatus),
                                              ),
                                              Expanded(
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: Text(
                                                    '${totalSize.toStringAsFixed(2)} m³' ??
                                                        '',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ).merge(_statisticStyle(
                                                        orderStatus)),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8.0),
                                          Row(
                                            children: [
                                              Text(
                                                Utils.getLocale(context)
                                                    .totalWeight,
                                                style: _statisticStyle(
                                                    orderStatus),
                                              ),
                                              Expanded(
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: Text(
                                                    '${totalWeight.toStringAsFixed(2)} kg' ??
                                                        '',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ).merge(_statisticStyle(
                                                        orderStatus)),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 8.0),
                                          Row(
                                            children: [
                                              Text(
                                                Utils.getLocale(context)
                                                    .totalFee,
                                                style: _statisticStyle(
                                                    orderStatus),
                                              ),
                                              Expanded(
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: Text(
                                                    '${Utils.getMoneyString(totalFee)}',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ).merge(_statisticStyle(
                                                        orderStatus)),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                  ],
                ),
              ),
              SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final ord = orders[index];
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Slidable(
                        actionPane: SlidableScrollActionPane(),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _getColor(ord.orderStatus),
                          ),
                          child: InkWell(
                            onTapDown: _storePosition,
                            onTap: () {
                              Utils.updatePop(1);
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (context) =>
                                      OrderDetailScreen(ord)));
                            },
                            onLongPress: isWarehouseStaff
                                ? null
                                : () => _makeCopyContext(ord),
                            child: Stack(
                              children: [
                                ListTile(
                                  title: Text(
                                    '${isCustomer ? Utils.getDisplayOrderId(ord.orderId) : ord.customerDTO?.fullName}',
                                    style: TextStyle(
                                        color: Colors.black87,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 5.0),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        HideOnCondition(
                                          hideOn: (ord.customerDTO == null ||
                                                  Utils.isNullOrEmpty(ord
                                                      .customerDTO
                                                      .customerId)) ||
                                              isCustomer,
                                          child: Row(
                                            children: [
                                              Text(
                                                '${Utils.getLocale(context).customerCode} ',
                                                style: _small(),
                                              ),
                                              Expanded(
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: Text(
                                                    '${ord?.customerDTO?.customerId}',
                                                    style: _small(),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        HideOnCondition(
                                          hideOn: Utils.isNullOrEmpty(
                                              ord.intTrackNo),
                                          child: Row(
                                            children: [
                                              Text(
                                                '${Utils.getLocale(context).chineseWaybillCode} ',
                                                style: _small(),
                                              ),
                                              Expanded(
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: Text(
                                                    '${ord.intTrackNo}',
                                                    style: _small(),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        /*HideOnCondition(
                                          hideOn: Utils.isNullOrEmpty(
                                                  ord.orderId) ||
                                              isCustomer,
                                          child: Row(
                                            children: [
                                              Text(
                                                '${Utils.getLocale(context).internationalWaybillCode} ',
                                                style: _small(),
                                              ),
                                              Expanded(
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: RichText(
                                                    text: TextSpan(
                                                      text:
                                                          '${Utils.getDisplayOrderId(ord.orderId)}',
                                                      style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.orange)
                                                          .merge(_small()),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),*/
                                        HideOnCondition(
                                          hideOn: Utils.isNullOrEmpty(
                                              ord.goodsDescr),
                                          child: Row(
                                            children: [
                                              Text(
                                                '${Utils.getLocale(context).description} ',
                                                style: _small(),
                                              ),
                                              Expanded(
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: RichText(
                                                    text: TextSpan(
                                                      text:
                                                          '${ord.goodsDescr ?? ""}',
                                                      style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  Colors.orange)
                                                          .merge(_small()),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        HideOnCondition(
                                          hideOn: Utils.isNullOrEmpty(
                                              ord.licensePlates),
                                          child: Row(
                                            children: [
                                              Text(
                                                '${Utils.getLocale(context).licensePlates} ',
                                                style: _small(),
                                              ),
                                              Expanded(
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: RichText(
                                                    text: TextSpan(
                                                      text:
                                                          '${ord.licensePlates ?? ""}',
                                                      style: TextStyle(
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color: Colors
                                                                  .black87)
                                                          .merge(_small()),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        HideOnCondition(
                                          hideOn: ord.orderStatus == null,
                                          child: Wrap(
                                            children: [
                                              _buildStatusTag(ord.orderStatus),
                                              Text(
                                                  '${ord.packCount != null ? ' - ' : ''}${ord.packCount} ${Utils.getLocale(context).packs}',
                                                  style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color: Theme.of(
                                                                  context)
                                                              .disabledColor)
                                                      .merge(_small())),
                                            ],
                                          ),
                                        ),
                                        Visibility(
                                          visible: _isVisibleWeightSize(ord),
                                          child: Column(
                                            children: [
                                              SizedBox(height: 3.0),
                                              Text(
                                                  '${ord.size != null && ord.size > 0 ? '${ord.size}m³' : ''}${(ord.size != null && ord.weight != null && ord.size > 0 && ord.weight > 0) ? ' - ' : ''}${ord.weight != null && ord.weight > 0 ? '${ord.weight}kg' : ''}'),
                                            ],
                                          ),
                                        ),
                                        Visibility(
                                          visible: !isChineseWarehouseStaff,
                                          child: Divider(),
                                        ),
                                        Row(
                                          children: [
                                            HideOnCondition(
                                              hideOn: ord.createdDate == null,
                                              child: Padding(
                                                padding: EdgeInsets.only(
                                                    top: isChineseWarehouseStaff
                                                        ? 2.0
                                                        : 0),
                                                child: Text(
                                                  '${Utils.getDateString(ord.createdDate, commonDateFormat)}',
                                                  style: TextStyle(
                                                    fontSize: 10.0,
                                                    color: Theme.of(context)
                                                        .disabledColor,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Expanded(
                                              child: Visibility(
                                                visible:
                                                    !isChineseWarehouseStaff,
                                                child: Align(
                                                  alignment:
                                                      Alignment.centerRight,
                                                  child: RichText(
                                                    text: TextSpan(
                                                        text:
                                                            '${Utils.getLocale(context).intoMoney}: ',
                                                        style: TextStyle(
                                                          color: Theme.of(
                                                                  context)
                                                              .disabledColor,
                                                        ).merge(_small()),
                                                        children: [
                                                          TextSpan(
                                                            text: ord.promotionDTO ==
                                                                    null
                                                                ? ''
                                                                : (ord.totalFeeOriginal ==
                                                                            null ||
                                                                        ord.totalFeeOriginal <=
                                                                            0 ||
                                                                        ord.totalFee >=
                                                                            ord
                                                                                .totalFeeOriginal)
                                                                    ? ''
                                                                    : NumberFormat.currency(
                                                                            locale:
                                                                                'vi_VN',
                                                                            symbol:
                                                                                'đ')
                                                                        .format(
                                                                            ord.totalFeeOriginal),
                                                            style: TextStyle(
                                                              color: Theme.of(
                                                                      context)
                                                                  .disabledColor,
                                                              decoration:
                                                                  TextDecoration
                                                                      .lineThrough,
                                                            ),
                                                          ),
                                                          TextSpan(
                                                              text: (ord.promotionDTO != null &&
                                                                          ord.totalFeeOriginal !=
                                                                              null &&
                                                                          ord.totalFeeOriginal >
                                                                              0 &&
                                                                          ord.totalFee <
                                                                              ord.totalFeeOriginal
                                                                      ? ' '
                                                                      : '') +
                                                                  '${_getTotalFeeText(ord.totalFee ?? 0)}',
                                                              style: TextStyle(
                                                                color:
                                                                    Colors.red,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                              )),
                                                        ]),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible: ![
                                        UserType.customer,
                                        UserType.saleStaff
                                      ].contains(currentUser?.userType) &&
                                      currentUser?.username == ord.saleId,
                                  child: Positioned(
                                    top: 4.0,
                                    right: 4.0,
                                    child: Icon(
                                      Icons.shopping_cart,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        secondaryActions: _buildActions(ord),
                      ),
                    );
                  },
                  childCount: orders.length,
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
        );
      },
    );
  }

  TextStyle _small() {
    return TextStyle(fontSize: 14.0);
  }

  void _showWaiting() {
    Utils.showLoading(context,
        textContent: Utils.getLocale(context).waitForLogin);
  }

  void _popLoading() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _delay(VoidCallback done) {
    Future.delayed(Duration(milliseconds: 500), () async {
      done?.call();
    });
  }

  void _makeCopyContext(Order ord) {
    final RenderBox overlay = Overlay.of(context).context.findRenderObject();
    showMenu(
        context: context,
        position: RelativeRect.fromRect(
            _tapPosition & Size(40, 40),
            // smaller rect, the touch area
            Offset.zero & overlay.size // Bigger rect, the entire screen
            ),
        items: <PopupMenuEntry>[
          PopupMenuItem(
            value: 'copy',
            child: GestureDetector(
              onTap: () => _copyOrder(ord),
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.content_copy,
                    color: Theme.of(context).disabledColor,
                  ),
                  SizedBox(width: 5.0),
                  Text('${Utils.getLocale(context).copy}'),
                ],
              ),
            ),
          )
        ]);
  }

  Future<void> _copyOrder(Order ord) async {
    Navigator.of(context).pop();
    Utils.updatePop(1);
    Order order = Order.clone(ord);
    // reset some properties
    order.orderId = null;
    order.orderStatus = OrderStatus.newlyCreated;
    order.orderTrackDTOS?.clear();
    order.tccoFileDTOS?.clear();
    order.promotionId = null;
    order.promotionDTO = null;
    order.createdDate = null;
    order.intTrackNo = null;
    order.totalFee = 0;
    order.totalFeeOriginal = 0;
    Navigator.of(context).push(
        MaterialPageRoute(builder: (context) => OrderFormScreen(order: order)));
  }

  Widget _buildStatusTag(int orderStatus) {
    Color background;
    Color textColor;
    switch (orderStatus) {
      case OrderStatus.newlyCreated:
        background = Color(Utils.hexColor('#CAE5FF'));
        textColor = Color(Utils.hexColor('#234A75'));
        break;
      case OrderStatus.aborted:
        background = Color(Utils.hexColor('#D7D8DA'));
        textColor = Color(Utils.hexColor('#161D27'));
        break;
      case OrderStatus.pendingWoodenPacking:
        background = Color(Utils.hexColor('#ECD180'));
        textColor = Color(Utils.hexColor('#7F5E11'));
        break;
      case OrderStatus.chineseWarehoused:
        background = Color(Utils.hexColor('#FAC7CC'));
        textColor = Color(Utils.hexColor('#843D45'));
        break;
      case OrderStatus.chineseShippedOut:
        background = Color(Utils.hexColor('#543B7C'));
        textColor = Color(Utils.hexColor('#B1A5E3'));
        break;
      case OrderStatus.uongbiWarehoused:
      case OrderStatus.hanoiWarehoused:
      case OrderStatus.saigonWarehoused:
      case OrderStatus.outputUongBi:
      case OrderStatus.outputHaNoi:
      case OrderStatus.outputSaiGon:
        background = Color(Utils.hexColor('#D8EBD8'));
        textColor = Color(Utils.hexColor('#29511F'));
        break;
      case OrderStatus.delivery:
        background = Colors.orange;
        textColor = Colors.white;
        break;
      case OrderStatus.delivered:
        background = Colors.green;
        textColor = Colors.white;
        break;
      case OrderStatus.completed:
        background = Colors.indigo;
        textColor = Colors.white;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
      decoration: BoxDecoration(
          color: background, borderRadius: BorderRadius.circular(4.0)),
      child: Text(
        '${Utils.getOrderStatusString(context, orderStatus)}',
        style: TextStyle(
          color: textColor,
          fontSize: 10.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  List<Widget> _buildActions(Order order) {
    List<Widget> list = [];
    List<AllowAction> allowActions =
        Utils.getAllowActionList(SessionUtil.instance().user, order);
    allowActions?.forEach((a) {
      switch (a) {
        case AllowAction.create:
          // ignored
          break;
        case AllowAction.edit:
          list.add(IconSlideAction(
            caption: '${Utils.getLocale(context).edit}',
            foregroundColor: Colors.white,
            color: Colors.orangeAccent,
            icon: Icons.edit,
            onTap: () {
              Utils.updatePop(1);
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => OrderFormScreen(order: order, update: true)));
            },
          ));
          break;
        case AllowAction.cancel:
          list.add(IconSlideAction(
            caption: '${Utils.getLocale(context).cancelOrder}',
            color: Colors.black12,
            icon: Icons.close,
            onTap: () async {
              Utils.confirm(
                context,
                title: '${Utils.getLocale(context).confirmation}',
                message:
                    '${Utils.getLocale(context).confirmCancelOrderMessage}',
                onAccept: () async {
                  _showWaiting();
                  _delay(() async {
                    bool success = await HttpUtil.updateOrderTrackingStatus(
                        order.orderId, ActionType.cancelOrder);
                    // pop loading
                    _popLoading();
                    if (success) {
                      Order orderUpdated =
                          await HttpUtil.getOrder(order.orderId);
                      if (orderUpdated != null) {
                        AppProvider.of(context)
                            .state
                            .orderBloc
                            .updateOrder(orderUpdated);

                        // remove order from block if needed
                        Utils.removeOrderFromBloc(context, orderUpdated);
                      }
                      _scaffoldKey.currentState.showSnackBar(SnackBar(
                        content: Text(
                          '${Utils.getLocale(context).cancelOrderSuccessMessage}',
                        ),
                      ));
                    } else {
                      _scaffoldKey.currentState.showSnackBar(SnackBar(
                        content: Text(
                          '${Utils.getLocale(context).updateOrderStatusFailedMessage}!',
                        ),
                      ));
                    }
                  });
                },
              );
            },
          ));
          break;
        case AllowAction.confirmWoodenPacking:
          list.add(IconSlideAction(
            foregroundColor: Colors.white,
            caption: '${Utils.getLocale(context).agreeToBoxWooden}',
            color: Colors.green,
            icon: Icons.done,
            onTap: () async {
              _showWaiting();
              _delay(() async {
                bool success = await HttpUtil.updateOrderTrackingStatus(
                    order.orderId, ActionType.confirmWoodenPacking);
                // pop loading
                _popLoading();
                if (success) {
                  Order orderUpdated = await HttpUtil.getOrder(order.orderId);
                  if (orderUpdated != null) {
                    AppProvider.of(context)
                        .state
                        .orderBloc
                        .updateOrder(orderUpdated);

                    // remove order from block if needed
                    Utils.removeOrderFromBloc(context, orderUpdated);
                  }
                  _scaffoldKey.currentState.showSnackBar(SnackBar(
                    content: Text(
                      '${Utils.getLocale(context).agreeToBoxWoodedSuccessMessage}',
                    ),
                  ));
                } else {
                  _scaffoldKey.currentState.showSnackBar(SnackBar(
                    content: Text(
                      '${Utils.getLocale(context).updateOrderStatusFailedMessage}!',
                    ),
                  ));
                }
              });
            },
          ));
          break;
        case AllowAction.importChineseWarehouse:
          list.add(IconSlideAction(
            foregroundColor: Colors.white,
            caption: '${Utils.getLocale(context).input}',
            color: Colors.green,
            icon: Icons.system_update_alt,
            onTap: () => _updateOrderStatus(order, ActionType.chineseWarehouse),
          ));
          break;
        case AllowAction.exportChineseWarehouse:
          list.add(IconSlideAction(
            foregroundColor: Colors.white,
            caption: '${Utils.getLocale(context).output}',
            color: Colors.green,
            icon: Icons.exit_to_app,
            onTap: () => _updateOrderStatus(order, ActionType.chineseStockOut),
          ));
          break;
        case AllowAction.importUongBiWarehouse:
        case AllowAction.importHaNoiWarehouse:
        case AllowAction.importSaiGonWarehouse:
          int actionType = ActionType.uongbiWarehouse;
          if (a == AllowAction.importHaNoiWarehouse)
            actionType = ActionType.hanoiWarehouse;
          if (a == AllowAction.importSaiGonWarehouse)
            actionType = ActionType.saigonWarehouse;

          list.add(IconSlideAction(
            foregroundColor: Colors.white,
            caption: '${Utils.getLocale(context).input}',
            color: Colors.green,
            icon: Icons.system_update_alt,
            onTap: () => _updateOrderStatus(order, actionType),
          ));
          break;
        case AllowAction.outputUongBi:
        case AllowAction.outputHaNoi:
        case AllowAction.outputSaiGon:
          int actionType = ActionType.outputUongBi;
          if (a == AllowAction.outputHaNoi) actionType = ActionType.outputHaNoi;
          if (a == AllowAction.outputSaiGon)
            actionType = ActionType.outputSaiGon;

          list.add(IconSlideAction(
            foregroundColor: Colors.white,
            caption: '${Utils.getLocale(context).output}',
            color: Colors.green,
            icon: Icons.exit_to_app,
            onTap: () => _updateOrderStatus(order, actionType),
          ));
          break;
        case AllowAction.delivery:
          list.add(IconSlideAction(
            foregroundColor: Colors.white,
            caption: Utils.getLocale(context).delivery,
            color: Colors.orange,
            icon: Icons.more_horiz,
            onTap: () => _updateOrderStatus(
                order,
                ActionType
                    .delivery) /*{
              Utils.confirm(
                context,
                title: Utils.getLocale(context).confirmation,
                message: '${Utils.getLocale(context).orderDeliveryMessage}',
                onAccept: () => _updateOrderStatus(order, ActionType.delivery),
              );
            }*/
            ,
          ));
          break;
        case AllowAction.delivered:
          list.add(IconSlideAction(
            foregroundColor: Colors.white,
            caption: Utils.getLocale(context).delivered,
            color: Colors.green,
            icon: Icons.done,
            onTap: () {
              _updateOrderStatus(order, ActionType.delivered);
              /*Utils.confirm(
                context,
                title: Utils.getLocale(context).confirmation,
                message: '${Utils.getLocale(context).orderDeliveredMessage}',
                onAccept: () => _updateOrderStatus(order, ActionType.delivered),
              );*/
            },
          ));
          break;
        case AllowAction.complete:
          list.add(IconSlideAction(
            foregroundColor: Colors.white,
            caption: Utils.getLocale(context).completed,
            color: Colors.indigo,
            icon: Icons.done_all,
            onTap: () => _updateOrderStatus(order, ActionType.completed),
          ));
          break;
      }
    });

    return list;
  }

  Future<void> _updateOrderStatus(Order order, int actionType) async {
    bool output = false;
    if ([
      ActionType.outputUongBi,
      ActionType.outputSaiGon,
      ActionType.outputHaNoi
    ].contains(actionType)) output = true;

    ConfirmationStatus status;
    bool isOutput = false;
    if ([
      ActionType.chineseWarehouse,
      ActionType.chineseStockOut,
      ActionType.uongbiWarehouse,
      ActionType.outputUongBi,
      ActionType.hanoiWarehouse,
      ActionType.outputHaNoi,
      ActionType.saigonWarehouse,
      ActionType.outputSaiGon,
      ActionType.delivery,
      ActionType.delivered,
      ActionType.completed
    ].contains(actionType)) {
      isOutput = true;
      status = await Utils.showConfirmStatusDialog(
        context,
        forOrder: order,
        output: output,
        hidePackCount:
            [ActionType.delivered, ActionType.completed].contains(actionType),
      );
    }

    if (isOutput && status == null) return;
    /*if (status == null) {
      Utils.alert(context,
          title: Utils.getLocale(context).failed,
          message: Utils.getLocale(context).updateOrderStatusFailedMessage);
      return;
    }*/

    _showWaiting();
    _delay(() async {
      bool success = await HttpUtil.updateOrderTrackingStatus(
        order.orderId,
        actionType,
        confirmStatus: status,
        error: (e) {
          if (e == null) {
            Utils.alert(context,
                title: "Lỗi", message: "Máy chủ không phản hồi!");
            return;
          }

          print("RESPONSE: " + e);
        },
      );
      // pop loading
      _popLoading();
      if (success) {
        Order orderUpdated = await HttpUtil.getOrder(order.orderId);
        if (orderUpdated != null) {
          AppProvider.of(context).state.orderBloc.updateOrder(orderUpdated);

          // remove order from block if needed
          Utils.removeOrderFromBloc(context, orderUpdated);
        }
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text(
            '${Utils.getLocale(context).inputSuccessMessage}',
          ),
        ));
      } else {
        _scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text(
            '${Utils.getLocale(context).updateOrderStatusFailedMessage}!',
          ),
        ));
      }
    });
  }

  Widget _buildDrawer() {
    return SafeArea(
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        child: Drawer(
          child: ListView(
            children: [
              ListTile(
                onTap: () {
                  Navigator.of(context).pop(); // close the drawer
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => ProfileScreen(
                            currentUser: SessionUtil.instance().user,
                          )));
                },
                leading: Icon(Icons.account_circle),
                title: Text(
                  Utils.getLocale(context).profile,
                  style: _drawerTextStyle(),
                ),
              ),
              Visibility(
                visible: !isAdmin && !isWarehouseStaff,
                child: ListTile(
                  onTap: () {
                    Navigator.of(context).pop(); // close the drawer
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => AddressManagementScreen()));
                  },
                  leading: Icon(Icons.location_on),
                  title: Text(
                    Utils.getLocale(context).address,
                    style: _drawerTextStyle(),
                  ),
                ),
              ),
              Visibility(
                visible: isSaleStaff && !isAdmin,
                child: ListTile(
                  onTap: () {
                    Navigator.of(context).pop(); // close the drawer
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => CustomerManagementScreen()));
                  },
                  leading: Icon(Icons.group),
                  title: Text(
                    Utils.getLocale(context).customer,
                    style: _drawerTextStyle(),
                  ),
                ),
              ),
              const Divider(),
              ListTile(
                onTap: () {
                  Navigator.of(context).pop(); // close the drawer
                  showAboutDialog(
                      context: context,
                      applicationName: 'DL Express',
                      applicationVersion: '1.0',
                      applicationIcon: Image.asset(
                        'assets/icon/icon.png',
                        width: 40.0,
                        height: 40.0,
                      ),
                      children: [
                        Text(
                          'Bạn đang sử dụng phiên bản 1.0 phát hành lúc 17.07.2020 15:30.',
                          style: TextStyle(
                              fontSize: 12.0, color: Colors.grey[500]),
                        ),
                      ]);
                },
                leading: Icon(Icons.help),
                title: Text(
                  '${Utils.getLocale(context).help}',
                  style: _drawerTextStyle(),
                ),
              ),
              ListTile(
                onTap: () {
                  Navigator.of(context).pop(); // close the drawer
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => SettingScreen()));
                },
                leading: Icon(Icons.settings),
                title: Text(
                  '${Utils.getLocale(context).setting}',
                  style: _drawerTextStyle(),
                ),
              ),
              const Divider(),
              ListTile(
                onTap: () {
                  Navigator.of(context).pop(); // close the drawer
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) =>
                          ChangePasswordScreen(SessionUtil.instance().user)));
                },
                leading: Icon(Icons.vpn_key),
                title: Text(
                  '${Utils.getLocale(context).changePassword}',
                  style: _drawerTextStyle(),
                ),
              ),
              ListTile(
                onTap: () async {
                  // reset bloc
                  AppProvider.of(context)?.state?.reset();

                  var prefs = await SharedPreferences.getInstance();
                  prefs.setBool(PrefsKey.logged, false);

                  Navigator.of(context).pop(); // close the drawer
                  /*Navigator.of(context).pushReplacement(
                            MaterialPageRoute(builder: (context) => LoginScreen()));*/
                  Utils.showLoading(context,
                      textContent: Utils.getLocale(context).waitForLogin);
                  Future.delayed(Duration(milliseconds: 1000), () {
                    Navigator.of(context, rootNavigator: true).pop();
                    Navigator.of(context).pushReplacementNamed(AppRouter.login);
                  });
                },
                leading: Icon(Icons.exit_to_app),
                title: Text(
                  Utils.getLocale(context).logout,
                  style: _drawerTextStyle(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _drawerTextStyle() {
    return TextStyle(
      fontSize: 18.0,
      color: Colors.black54,
    );
  }

  Widget _notificationsBadge(NotificationBloc bloc) {
    return StreamBuilder<int>(
        stream: bloc.unreadCount,
        builder: (context, snapshot) {
          final count = snapshot.data ?? 0;

          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(
                  builder: (context) => NotificationScreen()));
            },
            child: Badge(
              position: BadgePosition.topRight(top: 6, right: 6),
              animationDuration: Duration(milliseconds: 300),
              animationType: BadgeAnimationType.slide,
              showBadge: count > 0,
              badgeColor: Colors.blue,
              badgeContent: Text(
                count < 10 ? count.toString() : '9+',
                style: TextStyle(
                    color: Colors.white, fontSize: count < 10 ? 12.0 : 10.0),
              ),
              child: IconButton(
                  icon: Icon(Icons.notifications),
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(
                        builder: (context) => NotificationScreen()));
                  }),
            ),
          );
        });
  }
}

class SearchBoxFlexible extends StatelessWidget {
  final OrderBloc orderBloc;
  final double appBarHeight = 66.0;
  final ValueChanged<String> onCustomerCodeChange;

  const SearchBoxFlexible(this.orderBloc, {this.onCustomerCodeChange});

  @override
  Widget build(BuildContext context) {
    final double statusBarHeight = MediaQuery.of(context).padding.top;

    return new Container(
      color: Colors.transparent,
      padding: new EdgeInsets.only(top: statusBarHeight + 50),
      height: statusBarHeight + appBarHeight,
      child: StreamBuilder<OrderFilter>(
          stream: orderBloc.filter,
          builder: (context, snapshot) {
            if (!snapshot.hasData || snapshot.data == null) return SizedBox();

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                OrderFilterWidget(
                  snapshot.data,
                  onCustomerCodeChange: this.onCustomerCodeChange,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: GestureDetector(
                    onTap: () async {
                      List<int> result = await Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => SelectOrderStatusScreen(
                                  snapshot.data.statusList)));

                      if (result == null || result.isEmpty) {
                        result = []..addAll(OrderStatus.values);
                      }

                      OrderFilter filter = snapshot.data;
                      filter.statusList = result;
                      orderBloc.updateFilter(filter);
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.max,
                      children: [
                        Text(
                          Utils.getLocale(context).status,
                          style: TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Expanded(
                                  child: Align(
                                    alignment: Alignment.centerRight,
                                    child: Text(
                                      _getStatusText(
                                          context, snapshot.data.statusList),
                                      style: TextStyle(color: Colors.white),
                                      overflow: TextOverflow.ellipsis,
                                      maxLines: 1,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right,
                                  color: Colors.white,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }),
    );
  }

  String _getStatusText(BuildContext context, List<int> statusList) {
    if (statusList.length == OrderStatus.values.length)
      return '${Utils.getLocale(context).all}';
    List<String> statusStrings =
        statusList.map((o) => Utils.getOrderStatusString(context, o)).toList();
    return statusStrings.join(', ');
  }
}
