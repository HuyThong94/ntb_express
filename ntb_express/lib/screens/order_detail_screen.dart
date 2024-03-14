import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:ntbexpress/model/file_holder.dart';
import 'package:ntbexpress/model/order.dart';
import 'package:ntbexpress/screens/order_form_screen.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/http_util.dart';
import 'package:ntbexpress/util/session_util.dart';
import 'package:ntbexpress/util/utils.dart';
import 'package:ntbexpress/widgets/app_provider.dart';
import 'package:ntbexpress/widgets/hide_on_condition.dart';
import 'package:ntbexpress/widgets/image_gallery.dart';
import 'package:ntbexpress/widgets/info_item.dart';
import 'package:ntbexpress/widgets/order_tracking_timeline.dart';

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  OrderDetailScreen(this.order);

  @override
  _OrderDetailScreenState createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen>
    with TickerProviderStateMixin {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final List<FileHolder> _files = [];
  bool _initialized = false;
  bool _statusTapped = false;

  late Order _order;

  bool get isConfirmWoodenPacking =>
      _order.orderStatus == OrderStatus.pendingWoodenPacking;

  bool get canEdit =>
      Utils.canEditOrders(SessionUtil.instance().user, _order) &&
      !isConfirmWoodenPacking;

  bool get isChineseStaff =>
      SessionUtil.instance()?.user?.userType == UserType.chineseWarehouseStaff;

  bool get isAllowEditAgentFee =>
      SessionUtil.instance().user.userType == UserType.admin ||
      SessionUtil.instance().user.userType == UserType.customer ||
      SessionUtil.instance().user.userType == UserType.saleStaff;

  @override
  void initState() {
    super.initState();
    _order = (widget.order == null ? null : Order.clone(widget.order))!;
  }

  Future<void> _init() async {
    _sortOrderTracks();

    if (_order.tccoFileDTOS != null) {
      for (var f in _order.tccoFileDTOS!) {
        if (f == null) continue;
        final url = '${ApiUrls.instance().baseUrl}/${f.flePath}';
        if (!(await Utils.isUrlValid(url))) continue;

        setState(() {
          _files.add(FileHolder(
            key: f.atchFleSeq,
            isNetworkImage: true,
            fileUrl: url,
          ));
        });
      }
    }
  }

  void _sortOrderTracks() {
    final orderTrackDTOS = _order.orderTrackDTOS;
    if (orderTrackDTOS != null) {
      orderTrackDTOS.sort((a, b) => b!.actionDate! - a!.actionDate!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    if (!_initialized) {
      _init();
      _initialized = true;
    }

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Platform.isIOS ? Icons.arrow_back_ios : Icons.arrow_back),
          onPressed: () {
            Utils.updatePop(0);
            Navigator.of(context).pop();
          },
        ),
        title: Text('${Utils.getLocale(context)?.orderInformation}'),
        actions: [
          !canEdit
              ? SizedBox()
              : Material(
                  color: Colors.transparent,
                  child: Container(
                    padding: const EdgeInsets.all(10.0),
                    child: InkWell(
                      onTap: () async {
                        Utils.updatePop(2);
                        Order orderEdited = await Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => OrderFormScreen(
                                    order: _order, update: true)));
                        if (orderEdited == null) return;
                        HttpUtil.get(
                          ApiUrls.instance().getOrderUrl(orderEdited.orderId),
                          headers: {
                            'Content-Type': 'application/json; charset=utf-8'
                          },
                          onResponse: (resp) async {
                            if (resp != null && resp.statusCode == 200) {
                              dynamic json =
                                  jsonDecode(utf8.decode(resp.bodyBytes));
                              if (json == null) return;
                              Order order = Order.fromJson(json);
                              if (order == null) return;

                              setState(() {
                                _order = order;
                                _sortOrderTracks();
                              });
                            }
                          },
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Text(
                            '${Utils.getLocale(context)?.edit}',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
        ],
      ),
      body: SafeArea(
        child: Container(
          color: Utils.backgroundColor,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HideOnCondition(
                  hideOn: isChineseStaff,
                  child: InfoItem(
                    firstText: '${Utils.getLocale(context)?.customerName}',
                    secondText: '${_order.customerDTO?.fullName}',
                  ),
                ),
                _divider(),
                HideOnCondition(
                  hideOn:
                      Utils.isNullOrEmpty(_order.customerId) || isChineseStaff,
                  child: InfoItem(
                    firstText: '${Utils.getLocale(context)?.customerCode}',
                    secondText: _order.customerId,
                  ),
                ),
                _divider(),
                HideOnCondition(
                  hideOn: _order.addressDTO == null || isChineseStaff,
                  child: InfoItem(
                    useWidget: true,
                    breakLine: true,
                    firstChild: Text('${Utils.getLocale(context)?.address}'),
                    bottomChild: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${_order.addressDTO?.fullName}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text('${_order.addressDTO?.phoneNumber}'),
                          Text('${[
                            _order.addressDTO?.address,
                            _order.addressDTO?.wards,
                            _order.addressDTO?.district,
                            _order.addressDTO?.province
                          ].join(', ')?.replaceAll(' ,', '')}'),
                        ],
                      ),
                    ),
                  ),
                ),
                _divider(),
                HideOnCondition(
                  hideOn: Utils.isNullOrEmpty(_order.intTrackNo),
                  child: InfoItem(
                    firstText:
                        '${Utils.getLocale(context)?.chineseWaybillCode}',
                    secondText: _order.intTrackNo,
                  ),
                ),
                _divider(),
                HideOnCondition(
                  hideOn: Utils.isNullOrEmpty(_order.orderId),
                  child: InfoItem(
                    useWidget: true,
                    firstChild: Text(
                        '${Utils.getLocale(context)?.internationalWaybillCode}'),
                    secondChild: Text(
                      Utils.getDisplayOrderId(_order.orderId),
                      style: TextStyle(
                          fontWeight: FontWeight.bold, color: Colors.orange),
                    ),
                  ),
                ),
                _divider(),
                HideOnCondition(
                  hideOn: _order.packCount == null || _order.packCount == 0,
                  child: InfoItem(
                    firstText: '${Utils.getLocale(context)?.packageQuantity}',
                    secondText: '${_order.packCount}',
                  ),
                ),
                _divider(),
                HideOnCondition(
                  hideOn: _order.orderStatus == null,
                  child: InfoItem(
                    useWidget: true,
                    firstChild: Text('${Utils.getLocale(context)?.status}'),
                    secondChild: Material(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _statusTapped = !_statusTapped;
                          });
                        },
                        child: Text(
                          '${Utils.getOrderStatusString(context, _order.orderStatus)}',
                          style: TextStyle(
                            color: Colors.blue,
                          ),
                        ),
                      ),
                    ),
                    bottomChild: AnimatedSize(
                      // vsync: this,
                      duration: const Duration(milliseconds: 200),
                      child: !_statusTapped
                          ? null
                          : OrderTrackingTimeline(
                              tracks: _order.orderTrackDTOS,
                            ),
                    ),
                  ),
                ),
                _divider(),
                HideOnCondition(
                  hideOn: _order.createdDate == null,
                  child: InfoItem(
                    firstText: '${Utils.getLocale(context)?.timeCreated}',
                    //secondText: _order.createdDate,
                    secondText: Utils.getDateString(
                        _order.createdDate, commonDateFormat),
                  ),
                ),
                _divider(),
                HideOnCondition(
                  hideOn: _order.goodsType == null || _order.goodsType == 0,
                  child: InfoItem(
                    firstText: '${Utils.getLocale(context)?.type}',
                    secondText:
                        Utils.getGoodsTypeString(context, _order.goodsType),
                  ),
                ),
                _divider(),
                HideOnCondition(
                  hideOn: Utils.isNullOrEmpty(_order.goodsDescr),
                  child: InfoItem(
                    firstText: '${Utils.getLocale(context)?.description}',
                    secondText: _order.goodsDescr,
                  ),
                ),
                _divider(),
                HideOnCondition(
                  hideOn: _order.weight == null || _order.weight == 0.0,
                  child: InfoItem(
                    firstText: '${Utils.getLocale(context)?.weight}',
                    secondText: '${_order.weight} (kg)',
                  ),
                ),
                _divider(),
                HideOnCondition(
                  hideOn: _order.size == null || _order.size == 0.0,
                  child: InfoItem(
                    firstText: '${Utils.getLocale(context)?.size}',
                    secondText: '${_order.size} (m³)',
                  ),
                ),
                _divider(),
                HideOnCondition(
                  hideOn: Utils.isNullOrEmpty(_order.note!),
                  child: InfoItem(
                    firstText: '${Utils.getLocale(context)?.note}',
                    secondText: '${_order.note}',
                  ),
                ),
                _divider(),
                HideOnCondition(
                  hideOn: Utils.isNullOrEmpty(_order.licensePlates),
                  child: InfoItem(
                    firstText: '${Utils.getLocale(context)?.licensePlates}',
                    secondText: '${_order.licensePlates}',
                  ),
                ),
                _divider(),
                HideOnCondition(
                  hideOn: _order.intFee == null || _order.intFee == 0.0,
                  child: InfoItem(
                    firstText:
                        '${Utils.getLocale(context)?.domesticShippingFee}',
                    secondText: '${Utils.getMoneyString(_order.intFee)}',
                  ),
                ),
                _divider(),
                HideOnCondition(
                  hideOn: isChineseStaff ||
                      (_order.extFee == null || _order.extFee == 0.0),
                  child: InfoItem(
                      useWidget: true,
                      firstChild: Text(
                          '${Utils.getLocale(context)?.internationalShippingFee}'),
                      secondChild: RichText(
                        textAlign: TextAlign.right,
                        text: TextSpan(text: '', children: [
                          TextSpan(
                            text: _order.promotionDTO == null
                                ? ''
                                : (_order.totalFeeOriginal == null ||
                                        _order.totalFeeOriginal <= 0 ||
                                        _order.totalFee >=
                                            _order.totalFeeOriginal)
                                    ? ''
                                    : NumberFormat.currency(
                                            locale: 'vi_VN', symbol: 'đ')
                                        .format(_order.totalFeeOriginal),
                            style: TextStyle(
                                color: Theme.of(context).disabledColor,
                                decoration: TextDecoration.lineThrough,
                                fontSize: 11.0),
                          ),
                          TextSpan(
                            text: (_order.promotionDTO != null &&
                                        _order.totalFeeOriginal != null &&
                                        _order.totalFeeOriginal > 0 &&
                                        _order.totalFee <
                                            _order.totalFeeOriginal
                                    ? ' '
                                    : '') +
                                '${Utils.getMoneyString(_order.totalFee ?? 0)}',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextSpan(
                            text: !isAllowEditAgentFee
                                ? ''
                                : (_order == null ||
                                        _order.totalFeeDaiLong == null ||
                                        _order.totalFeeDaiLong == 0
                                    ? ''
                                    : ' (${Utils.getMoneyString(_order.totalFeeDaiLong ?? 0)})'),
                            style: TextStyle(
                              color: Colors.amber,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ]),
                      ) /*Text(
                      '${Utils.getMoneyString(_order.extFee)}',
                      style: TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),*/
                      ),
                ),
                isChineseStaff ? SizedBox() : _divider(),
                HideOnCondition(
                  hideOn: _order.needRepack == null || _order.needRepack == 0,
                  child: InfoItem(
                    firstText: '${Utils.getLocale(context)?.packedByWoodenBox}',
                    secondText:
                        '${_order?.needRepack != null && _order.needRepack > 0 ? '${Utils.getLocale(context)?.yes}${!isChineseStaff ? ' (${Utils.getMoneyString(_order.repackFee)})' : ''}' : '${Utils.getLocale(context)?.no}'}',
                  ),
                ),
                _divider(),
                Container(
                  padding: const EdgeInsets.all(5.0),
                  width: double.infinity,
                  color: Colors.white,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${Utils.getLocale(context)?.photosAttached}'),
                      _files.isEmpty
                          ? Text(
                              '${Utils.getLocale(context)?.empty}',
                              style: TextStyle(
                                  color: Theme.of(context).disabledColor),
                            )
                          : GridView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              gridDelegate:
                                  SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount:
                                    (orientation == Orientation.portrait)
                                        ? 4
                                        : 6,
                              ),
                              itemCount: _files.length,
                              itemBuilder: (context, index) {
                                final fileHolder = _files.elementAt(index);

                                return Card(
                                  child: GestureDetector(
                                    onTap: () {
                                      // Show gallery
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              GalleryPhotoViewWrapper(
                                            galleryItems: _files,
                                            backgroundDecoration:
                                                const BoxDecoration(
                                              color: Colors.black,
                                            ),
                                            initialIndex: index,
                                            scrollDirection: Axis.horizontal,
                                          ),
                                        ),
                                      );
                                    },
                                    child: GridTile(
                                      child: fileHolder == null
                                          ? Text(
                                              '${Utils.getLocale(context)?.empty}')
                                          : Stack(
                                              fit: StackFit.expand,
                                              children: [
                                                fileHolder.isNetworkImage!
                                                    ? Image.network(
                                                        fileHolder.fileUrl!,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : Image.file(
                                                        fileHolder.file!,
                                                        fit: BoxFit.cover,
                                                      ),
                                              ],
                                            ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: Material(
        elevation: 4.0,
        child: Container(
          padding: const EdgeInsets.all(0),
          child: _buildButtons(),
        ),
      ),
    );
  }

  Widget _buildButtons() {
    List<AllowAction> allowActions =
        Utils.getAllowActionList(SessionUtil.instance().user, _order);
    if (allowActions.isEmpty) return SizedBox();
    if (allowActions.length == 1 && allowActions.first == AllowAction.edit)
      return SizedBox();

    List<Widget> children = [];
    allowActions.removeWhere((a) => a == AllowAction.edit);
    allowActions.forEach((a) {
      switch (a) {
        case AllowAction.create:
          break;
        case AllowAction.edit:
          break;
        case AllowAction.cancel:
          children.add(Expanded(
            child: SizedBox(
              width: double.infinity,
              height: 40.0,
              // child: RaisedButton(
              //   onPressed: () {
              //     Utils.confirm(
              //       context,
              //       title: '${Utils.getLocale(context)?.confirmation}',
              //       message:
              //           '${Utils.getLocale(context)?.confirmCancelOrderMessage}',
              //       onAccept: () async {
              //         _showWaiting();
              //         _delay(() async {
              //           bool success = await HttpUtil.updateOrderTrackingStatus(
              //               _order.orderId, ActionType.cancelOrder);
              //           // pop loading
              //           _popLoading();
              //           if (success) {
              //             Order orderUpdated =
              //                 await HttpUtil.getOrder(_order.orderId);
              //             if (orderUpdated != null) {
              //               AppProvider.of(context)
              //                   ?.state
              //                   .orderBloc
              //                   .updateOrder(orderUpdated);
              //               setState(() {
              //                 _order = orderUpdated;
              //                 _sortOrderTracks();
              //               });
              //
              //               // remove order from block if needed
              //               Utils.removeOrderFromBloc(context, orderUpdated);
              //             }
              //
              //             Utils.alert(context,
              //                 title: Utils.getLocale(context)?.success,
              //                 message: Utils.getLocale(context)
              //                     .cancelOrderSuccessMessage,
              //                 onAccept: () => Utils.popToFirstScreen(context));
              //             /*_scaffoldKey.currentState.showSnackBar(SnackBar(
              //               content: Text(
              //                 '${Utils.getLocale(context).cancelOrderSuccessMessage}',
              //               ),
              //             ));*/
              //           } else {
              //             Utils.alert(context,
              //                 title: Utils.getLocale(context).failed,
              //                 message: Utils.getLocale(context)
              //                     .updateOrderStatusFailedMessage);
              //             /*_scaffoldKey.currentState.showSnackBar(SnackBar(
              //               content: Text(
              //                 '${Utils.getLocale(context).updateOrderStatusFailedMessage}!',
              //               ),
              //             ));*/
              //           }
              //         });
              //       },
              //     );
              //   },
              //   child: Text(
              //     '${Utils.getLocale(context).cancelOrder}',
              //     style: TextStyle(color: Colors.white),
              //   ),
              // ),
              child: ElevatedButton(
                onPressed: () {
                  Utils.confirm(
                    context,
                    title: '${Utils.getLocale(context)?.confirmation}',
                    message:
                        '${Utils.getLocale(context)?.confirmCancelOrderMessage}',
                    onAccept: () async {
                      _showWaiting();
                      _delay(() async {
                        bool success = await HttpUtil.updateOrderTrackingStatus(
                            _order.orderId, ActionType.cancelOrder);
                        // pop loading
                        _popLoading();
                        if (success) {
                          Order orderUpdated =
                              await HttpUtil.getOrder(_order.orderId);
                          if (orderUpdated != null) {
                            AppProvider.of(context)
                                ?.state
                                .orderBloc
                                .updateOrder(orderUpdated);
                            setState(() {
                              _order = orderUpdated;
                              _sortOrderTracks();
                            });

                            // remove order from block if needed
                            Utils.removeOrderFromBloc(context, orderUpdated);
                          }

                          Utils.alert(context,
                              title: Utils.getLocale(context)?.success,
                              message: Utils.getLocale(context)
                                  ?.cancelOrderSuccessMessage,
                              onAccept: () => Utils.popToFirstScreen(context));
                          /*_scaffoldKey.currentState.showSnackBar(SnackBar(
              content: Text(
                '${Utils.getLocale(context).cancelOrderSuccessMessage}',
              ),
            ));*/
                        } else {
                          Utils.alert(context,
                              title: Utils.getLocale(context)?.failed,
                              message: Utils.getLocale(context)
                                  ?.updateOrderStatusFailedMessage);
                          /*_scaffoldKey.currentState.showSnackBar(SnackBar(
              content: Text(
                '${Utils.getLocale(context).updateOrderStatusFailedMessage}!',
              ),
            ));*/
                        }
                      });
                    },
                  );
                },
                child: Text(
                  '${Utils.getLocale(context)?.cancelOrder}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ));
          break;
        case AllowAction.confirmWoodenPacking:
          children.add(Expanded(
            child: SizedBox(
              width: double.infinity,
              height: 40.0,
              child:
                  // RaisedButton(
                  //   onPressed: () async {
                  //     _showWaiting();
                  //     _delay(() async {
                  //       bool success = await HttpUtil.updateOrderTrackingStatus(
                  //           _order.orderId, ActionType.confirmWoodenPacking);
                  //       // pop loading
                  //       _popLoading();
                  //       if (success) {
                  //         Order orderUpdated =
                  //             await HttpUtil.getOrder(_order.orderId);
                  //         if (orderUpdated != null) {
                  //           AppProvider.of(context)
                  //               .state
                  //               .orderBloc
                  //               .updateOrder(orderUpdated);
                  //           setState(() {
                  //             _order = orderUpdated;
                  //             _sortOrderTracks();
                  //           });
                  //
                  //           // remove order from block if needed
                  //           Utils.removeOrderFromBloc(context, orderUpdated);
                  //         }
                  //
                  //         Utils.alert(context,
                  //             title: Utils.getLocale(context).success,
                  //             message: Utils.getLocale(context)
                  //                 .agreeToBoxWoodedSuccessMessage,
                  //             onAccept: () => Utils.popToFirstScreen(context));
                  //         /*_scaffoldKey.currentState.showSnackBar(SnackBar(
                  //           content: Text(
                  //             '${Utils.getLocale(context).agreeToBoxWoodedSuccessMessage}',
                  //           ),
                  //         ));*/
                  //       } else {
                  //         Utils.alert(context,
                  //             title: Utils.getLocale(context).failed,
                  //             message: Utils.getLocale(context)
                  //                 .updateOrderStatusFailedMessage);
                  //         /*_scaffoldKey.currentState.showSnackBar(SnackBar(
                  //           content: Text(
                  //             '${Utils.getLocale(context).failed}!',
                  //           ),
                  //         ));*/
                  //       }
                  //     });
                  //   },
                  //   color: Colors.green,
                  //   child: Text(
                  //     '${Utils.getLocale(context).agreeToBoxWooden}',
                  //     style: TextStyle(color: Colors.white),
                  //   ),
                  // ),
                  ElevatedButton(
                onPressed: () async {
                  _showWaiting();
                  _delay(() async {
                    bool success = await HttpUtil.updateOrderTrackingStatus(
                        _order.orderId, ActionType.confirmWoodenPacking);
                    // pop loading
                    _popLoading();
                    if (success) {
                      Order orderUpdated =
                          await HttpUtil.getOrder(_order.orderId);
                      if (orderUpdated != null) {
                        AppProvider.of(context)
                            ?.state
                            .orderBloc
                            .updateOrder(orderUpdated);
                        setState(() {
                          _order = orderUpdated;
                          _sortOrderTracks();
                        });

                        // remove order from block if needed
                        Utils.removeOrderFromBloc(context, orderUpdated);
                      }

                      Utils.alert(context,
                          title: Utils.getLocale(context)?.success,
                          message: Utils.getLocale(context)
                              ?.agreeToBoxWoodedSuccessMessage,
                          onAccept: () => Utils.popToFirstScreen(context));
                      /*_scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text(
            '${Utils.getLocale(context).agreeToBoxWoodedSuccessMessage}',
          ),
        ));*/
                    } else {
                      Utils.alert(context,
                          title: Utils.getLocale(context)?.failed,
                          message: Utils.getLocale(context)
                              ?.updateOrderStatusFailedMessage);
                      /*_scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text(
            '${Utils.getLocale(context).failed}!',
          ),
        ));*/
                    }
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.green, // Set button's background color
                ),
                child: Text(
                  '${Utils.getLocale(context)?.agreeToBoxWooden}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ));
          break;
        case AllowAction.importChineseWarehouse:
          children.add(Expanded(
            child: SizedBox(
              width: double.infinity,
              height: 40.0,
              child:
                  // RaisedButton(
                  //   onPressed: () =>
                  //       _updateOrderStatus(ActionType.chineseWarehouse),
                  //   color: Colors.green,
                  //   child: Text(
                  //     '${Utils.getLocale(context).input}',
                  //     style: TextStyle(color: Colors.white),
                  //   ),
                  // ),
                  ElevatedButton(
                onPressed: () =>
                    _updateOrderStatus(ActionType.chineseWarehouse),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.green, // Set button's background color
                ),
                child: Text(
                  '${Utils.getLocale(context)?.input}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ));
          break;
        case AllowAction.exportChineseWarehouse:
          children.add(Expanded(
            child: SizedBox(
              width: double.infinity,
              height: 40.0,
              child:
                  // RaisedButton(
                  //   onPressed: () => _updateOrderStatus(ActionType.chineseStockOut),
                  //   color: Colors.green,
                  //   child: Text(
                  //     '${Utils.getLocale(context).output}',
                  //     style: TextStyle(color: Colors.white),
                  //   ),
                  // ),
                  ElevatedButton(
                onPressed: () => _updateOrderStatus(ActionType.chineseStockOut),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.green, // Set button's background color
                ),
                child: Text(
                  '${Utils.getLocale(context)?.output}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
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

          children.add(Expanded(
            child: SizedBox(
              width: double.infinity,
              height: 40.0,
              child:
                  // RaisedButton(
                  //   onPressed: () => _updateOrderStatus(actionType),
                  //   color: Colors.green,
                  //   child: Text(
                  //     '${Utils.getLocale(context).input}',
                  //     style: TextStyle(color: Colors.white),
                  //   ),
                  // ),
                  ElevatedButton(
                onPressed: () => _updateOrderStatus(actionType),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.green, // Set button's background color
                ),
                child: Text(
                  '${Utils.getLocale(context)?.input}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ));
          break;
        case AllowAction.outputUongBi:
        case AllowAction.outputHaNoi:
        case AllowAction.outputSaiGon:
          int actionType = ActionType.outputUongBi;
          if (a == AllowAction.outputHaNoi) actionType = ActionType.outputHaNoi;
          if (a == AllowAction.outputSaiGon)
            actionType = ActionType.outputSaiGon;

          children.add(Expanded(
            child: SizedBox(
              width: double.infinity,
              height: 40.0,
              child:
                  // RaisedButton(
                  //   onPressed: () => _updateOrderStatus(actionType),
                  //   color: Colors.green,
                  //   child: Text(
                  //     '${Utils.getLocale(context).output}',
                  //     style: TextStyle(color: Colors.white),
                  //   ),
                  // ),
                  ElevatedButton(
                onPressed: () => _updateOrderStatus(actionType),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.green, // Set button's background color
                ),
                child: Text(
                  '${Utils.getLocale(context)?.output}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ));
          break;
        case AllowAction.delivery:
          children.add(Expanded(
            child: SizedBox(
              width: double.infinity,
              height: 40.0,
              child:
                  // RaisedButton(
                  //   onPressed: () => _updateOrderStatus(ActionType
                  //       .delivery) /*{
                  //     Utils.confirm(
                  //       context,
                  //       title: Utils.getLocale(context).confirmation,
                  //       message: '${Utils.getLocale(context).orderDeliveryMessage}',
                  //       onAccept: () => _updateOrderStatus(ActionType.delivery),
                  //     );
                  //   }*/
                  //   ,
                  //   color: Colors.orange,
                  //   child: Text(
                  //     '${Utils.getLocale(context).delivery}',
                  //     style: TextStyle(color: Colors.white),
                  //   ),
                  // ),
                  ElevatedButton(
                onPressed: () => _updateOrderStatus(ActionType.delivery),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.orange, // Set button's background color
                ),
                child: Text(
                  '${Utils.getLocale(context)?.delivery}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ));
          break;
        case AllowAction.delivered:
          children.add(Expanded(
            child: SizedBox(
              width: double.infinity,
              height: 40.0,
              child:
                  // RaisedButton(
                  //   onPressed: () {
                  //     _updateOrderStatus(ActionType.delivered);
                  //     /*Utils.confirm(
                  //       context,
                  //       title: Utils.getLocale(context).confirmation,
                  //       message:
                  //           '${Utils.getLocale(context).orderDeliveredMessage}',
                  //       onAccept: () => _updateOrderStatus(ActionType.delivered),
                  //     );*/
                  //   },
                  //   color: Colors.green,
                  //   child: Text(
                  //     '${Utils.getLocale(context).delivered}',
                  //     style: TextStyle(color: Colors.white),
                  //   ),
                  // ),
                  ElevatedButton(
                onPressed: () {
                  _updateOrderStatus(ActionType.delivered);
                  /*Utils.confirm(
                    context,
                    title: Utils.getLocale(context).confirmation,
                    message:
                        '${Utils.getLocale(context).orderDeliveredMessage}',
                    onAccept: () => _updateOrderStatus(ActionType.delivered),
                  );*/
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.green, // Set button's background color
                ),
                child: Text(
                  '${Utils.getLocale(context)?.delivered}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ));
          break;
        case AllowAction.complete:
          children.add(Expanded(
            child: SizedBox(
              width: double.infinity,
              height: 40.0,
              child:
                  // RaisedButton(
                  //   onPressed: () => _updateOrderStatus(ActionType.completed),
                  //   color: Colors.indigo,
                  //   child: Text(
                  //     '${Utils.getLocale(context).completed}',
                  //     style: TextStyle(color: Colors.white),
                  //   ),
                  // ),
                  ElevatedButton(
                onPressed: () => _updateOrderStatus(ActionType.completed),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      Colors.indigo, // Set button's background color
                ),
                child: Text(
                  '${Utils.getLocale(context)?.completed}',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ));
          break;
      }
    });

    return Row(
      children: children,
    );
  }

  Future<void> _updateOrderStatus(int actionType) async {
    bool output = false;
    if ([
      ActionType.outputUongBi,
      ActionType.outputSaiGon,
      ActionType.outputHaNoi
    ].contains(actionType)) output = true;

    ConfirmationStatus? status;
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
        forOrder: _order,
        output: output,
        hidePackCount:
            [ActionType.delivered, ActionType.completed].contains(actionType),
      );
    }

    if (isOutput && status == null) return;

    _showWaiting();
    _delay(() async {
      bool success = await HttpUtil.updateOrderTrackingStatus(
          _order.orderId, actionType,
          confirmStatus: status);
      // pop loading
      _popLoading();
      if (success) {
        Order orderUpdated = await HttpUtil.getOrder(_order.orderId);
        if (orderUpdated != null) {
          AppProvider.of(context)?.state.orderBloc.updateOrder(orderUpdated);

          setState(() {
            _order = orderUpdated;
            _sortOrderTracks();
          });

          // remove order from block if needed
          Utils.removeOrderFromBloc(context, orderUpdated);
        }

        Utils.alert(context,
            title: Utils.getLocale(context)?.success,
            message: Utils.getLocale(context)?.orderStatusUpdatedMessage,
            onAccept: () => Utils.popToFirstScreen(context));
        /*_scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text(
            '${Utils.getLocale(context).inputSuccessMessage}',
          ),
        ));*/
      } else {
        Utils.alert(context,
            title: Utils.getLocale(context)?.failed,
            message: Utils.getLocale(context)?.updateOrderStatusFailedMessage);
        /*_scaffoldKey.currentState.showSnackBar(SnackBar(
          content: Text(
            '${Utils.getLocale(context).updateOrderStatusFailedMessage}',
          ),
        ));*/
      }
    });
  }

  Widget _divider() {
    return Divider(
      height: 0.5,
    );
  }

  void _showWaiting() {
    Utils.showLoading(context,
        textContent: Utils.getLocale(context)!.waitForLogin);
  }

  void _popLoading() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _delay(VoidCallback done) {
    Future.delayed(Duration(milliseconds: 500), () async {
      done?.call();
    });
  }
}
