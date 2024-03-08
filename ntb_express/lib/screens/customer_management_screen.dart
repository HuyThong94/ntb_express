import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:ntbexpress/model/user.dart';
import 'package:ntbexpress/screens/customer_form_screen.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/http_util.dart';
import 'package:ntbexpress/util/utils.dart';
import 'package:ntbexpress/widgets/app_provider.dart';

class CustomerManagementScreen extends StatefulWidget {
  @override
  _CustomerManagementScreenState createState() =>
      _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _scrollController = ScrollController();
  bool _loaded = false;
  bool _showLoading = false;

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

  @override
  void didChangeDependencies() {
    setState(() {
      _loaded = false;
    });
    super.didChangeDependencies();
  }

  void _scrollListener() {
    if (_scrollController.position.extentAfter == 0) {
      if (_showLoading)
        return; // incomplete action => do nothing (wait for action completed)

      setState(() {
        _showLoading = true;
      });
      Future.delayed(Duration(seconds: 1), () async {
        AppProvider.of(context).state.userBloc?.loadMore(done: () {
          setState(() {
            _showLoading = false;
          });
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userBloc = AppProvider.of(context).state.userBloc;

    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title: Text(Utils.getLocale(context).customer),
      ),
      body: Container(
        constraints: const BoxConstraints.expand(),
        color: Utils.backgroundColor,
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: StreamBuilder<List<User>>(
            stream: userBloc.customers,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return Center(
                  child: Text(snapshot.error.toString()),
                );
              }

              if (snapshot.hasData) {
                if (snapshot.data == null || snapshot.data.isEmpty) {
                  if (!_loaded) {
                    Future.delayed(const Duration(milliseconds: 500), () async {
                      userBloc.fetch(
                          reset: true,
                          done: () {
                            if (mounted) {
                              setState(() => _loaded = true);
                            } else {
                              _loaded = true;
                            }
                          }); // fetch data
                    });

                    return Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  return Center(
                    child: Text(
                      '${Utils.getLocale(context).empty}',
                      style: TextStyle(
                        color: Theme.of(context).disabledColor,
                      ),
                    ),
                  );
                }

                return _content(snapshot.data);
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
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          User customer = await Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => CustomerFormScreen()));
          if (customer != null) {
            userBloc.updateCustomer(customer);
          }
        },
        child: Icon(Icons.add, size: 35.0),
      ),
    );
  }

  Future<void> _onRefresh() async {
    AppProvider.of(context).state.userBloc.fetch(reset: true);
  }

  Widget _content(List<User> customers) {
    return Scrollbar(
      child: CustomScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        shrinkWrap: false,
        slivers: [
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final cus = customers[index];
                return Slidable(
                  actionPane: SlidableScrollActionPane(),
                  child: ListTile(
                    onTap: () async {
                      User updatedUser = await Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => CustomerFormScreen(
                                  isUpdate: true, currentUser: cus)));

                      if (updatedUser != null) {
                        if (updatedUser.avatarImgDTO != null) {
                          updatedUser.avatarImgDTO.flePath =
                              updatedUser.avatarImgDTO.flePath +
                                  '?t=${DateTime.now().millisecondsSinceEpoch}';
                        }
                        AppProvider.of(context)
                            .state
                            .userBloc
                            .updateCustomer(updatedUser);
                      }
                    },
                    leading: CircleAvatar(
                      radius: 21.0,
                      backgroundColor: Colors.grey[100],
                      child: CircleAvatar(
                        radius: 20.0,
                        backgroundImage: cus.avatarImgDTO != null
                            ? NetworkImage(
                                '${ApiUrls.instance().baseUrl}/${cus.avatarImgDTO.flePath}')
                            : AssetImage('assets/images/default-avatar.png'),
                      ),
                    ),
                    title: Text(
                      '${cus.fullName}',
                      style: TextStyle(color: Colors.black),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${cus.phoneNumber}'),
                      ],
                    ),
                  ),
                  secondaryActions: [
                    IconSlideAction(
                      onTap: () {
                        Utils.confirm(
                          context,
                          title: Utils.getLocale(context).confirmation,
                          message: Utils.getLocale(context)
                              .confirmDeleteCustomerMessage,
                          onAccept: () => _deleteUser(cus),
                        );
                      },
                      icon: Icons.delete,
                      color: Colors.red,
                      foregroundColor: Colors.white,
                      caption: Utils.getLocale(context).delete,
                    ),
                  ],
                );
              },
              childCount: customers.length,
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
  }

  Future<void> _deleteUser(User user) async {
    if (user == null || Utils.isNullOrEmpty(user.username)) return;
    Utils.showLoading(context, textContent: Utils.getLocale(context).waitForLogin);
    Future.delayed(Duration(milliseconds: 500), () {
      HttpUtil.delete(
        ApiUrls.instance().getDeleteUserUrl(user.username),
        onResponse: (resp) {
          Navigator.of(context, rootNavigator: true).pop(); // pop waiting
          if (resp == null || resp.statusCode != 200) {
            dynamic json = resp == null || Utils.isNullOrEmpty(resp.body)
                ? null
                : jsonDecode(utf8.decode(resp.bodyBytes));

            Utils.alert(
              context,
              title: Utils.getLocale(context).failed,
              message:
              '${Utils.getLocale(context).errorOccurred} ${resp.statusCode}\n${json == null ? '' : json['message']}',
            );
            return;
          }

          Utils.alert(
            context,
            title: Utils.getLocale(context).success,
            message: Utils.getLocale(context).deleteCustomerSuccessMessage,
            onAccept: () {
              AppProvider.of(context).state.userBloc.removeCustomer(user);
            },
          );
        },
        onTimeout: () {
          Navigator.of(context, rootNavigator: true).pop(); // pop waiting
          Utils.alert(context,
              title: Utils.getLocale(context).failed,
              message: Utils.getLocale(context).requestTimeout);
        },
      );
    });
  }

/*TextStyle _small() {
    return TextStyle(fontSize: 10.0);
  }*/
}
