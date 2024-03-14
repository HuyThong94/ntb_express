/// create/update the order
import 'package:flutter/material.dart';
import 'package:ntbexpress/model/address.dart';
import 'package:ntbexpress/model/user.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/http_util.dart';
import 'package:ntbexpress/util/select_area_screen.dart';
import 'package:ntbexpress/util/session_util.dart';
import 'package:ntbexpress/util/utils.dart';
import 'package:ntbexpress/widgets/info_item.dart';

class AddressFormScreen extends StatefulWidget {
  final bool isUpdate;
  final Address? address;
  final User? forUser;
  final bool doNotSave;

  AddressFormScreen(
      {this.isUpdate = false,
      this.address,
      this.forUser,
      this.doNotSave = false});

  @override
  _AddressFormScreenState createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<AddressFormScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _dividerHeight = 0.5;
  late Address _address;
  late Address _immutableAddress;
  bool _hasChanged = false;

  @override
  void initState() {
    super.initState();
    _address = widget.address == null
        ? Address()
        : Address.clone(widget.address!) ?? Address();
    if (!widget.isUpdate) {
      User user = widget.forUser!;
      if (user == null) {
        user = User.clone(SessionUtil.instance().user);
      }

      _address.userName = user!.username!;
    } else {
      _address.updatedId = SessionUtil.instance().user!.username!;
    }

    if (widget.forUser != null) {
      _address.fullName = widget.forUser!.fullName!;
      _address.phoneNumber = widget.forUser!.phoneNumber!;
      _address.email = widget.forUser!.email!;
    }
    _immutableAddress = Address.clone(_address);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            if (!_hasChanged) {
              Navigator.of(context).pop();
              return;
            }

            Utils.confirm(
              context,
              title: '${Utils.getLocale(context)?.saveChanges}?',
              message: Utils.getLocale(context)?.saveChangesMessage,
              onAccept: () {
                if (!_validateForm()) return;
                _saveChanges(context,
                    done: () => Navigator.of(context).pop(_address));
              },
              onDecline: () => Navigator.of(context).pop(),
            );
          },
          icon: Icon(Icons.close),
        ),
        title: Text(
            '${!widget.isUpdate ? Utils.getLocale(context)?.add : Utils.getLocale(context)?.edit} ${Utils.getLocale(context)?.address}'),
        actions: [
          IconButton(
            onPressed: !_hasChanged
                ? null
                : () {
                    if (!_validateForm()) return;
                    _saveChanges(context,
                        done: () => Navigator.of(context).pop(_address));
                  },
            icon: Icon(Icons.done),
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          constraints: BoxConstraints.expand(),
          padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
          color: Utils.backgroundColor,
          child: SingleChildScrollView(
            child: Column(
              children: [
                InfoItem(
                  firstText: '${Utils.getLocale(context)?.fullName} ',
                  secondText: _address.fullName ?? '',
                  onTap: _updateFullName,
                ),
                Divider(height: _dividerHeight),
                InfoItem(
                  firstText: '${Utils.getLocale(context)?.phoneNumber} ',
                  secondText: _address.phoneNumber ?? '',
                  onTap: _updatePhoneNumber,
                ),
                Divider(height: _dividerHeight),
                InfoItem(
                  firstText:
                      '${Utils.getLocale(context)?.email} (${Utils.getLocale(context)?.optional}) ',
                  secondText: _address.email ?? '',
                  onTap: _updateEmail,
                ),
                Divider(height: _dividerHeight),
                InfoItem(
                  firstText: '${Utils.getLocale(context)?.province} ',
                  secondText: _address.province ?? '',
                  onTap: () async {
                    String selectedCity = await Utils.selectArea(
                      context,
                      target: AreaTarget.province,
                      currentProvince: _address.province,
                      title:
                          '${Utils.getLocale(context)?.select} ${Utils.getLocale(context)?.province}',
                    );

                    if (_address.province != selectedCity) {
                      setState(() {
                        _address.province = selectedCity;
                        // reset district & wards
                        _address.district = '';
                        _address.wards = '';
                        _stateChanged();
                      });
                    }
                  },
                ),
                Divider(height: _dividerHeight),
                InfoItem(
                  firstText: '${Utils.getLocale(context)?.district} ',
                  secondText: _address.district ?? '',
                  onTap: () async {
                    if (Utils.isNullOrEmpty(_address.province)) {
                      Utils.alert(context,
                          title: Utils.getLocale(context)?.required,
                          message:
                              '${Utils.getLocale(context)?.mustSelect} ${Utils.getLocale(context)?.province}!');
                      return;
                    }

                    String selectedDistrict = await Utils.selectArea(
                      context,
                      target: AreaTarget.district,
                      currentProvince: _address.province,
                      currentDistrict: _address.district,
                      title:
                          '${Utils.getLocale(context)?.select} ${Utils.getLocale(context)?.district}',
                    );

                    if (_address.district != selectedDistrict) {
                      setState(() {
                        _address.district = selectedDistrict;
                        // reset wards
                        _address.wards = '';
                        _stateChanged();
                      });
                    }
                  },
                ),
                Divider(height: _dividerHeight),
                InfoItem(
                  firstText: '${Utils.getLocale(context)?.wards} ',
                  secondText: _address.wards ?? '',
                  onTap: () async {
                    if (Utils.isNullOrEmpty(_address.district)) {
                      Utils.alert(context,
                          title: Utils.getLocale(context)?.required,
                          message:
                              '${Utils.getLocale(context)?.mustSelect} ${Utils.getLocale(context)?.district}!');
                      return;
                    }

                    String selectedWards = await Utils.selectArea(
                      context,
                      target: AreaTarget.wards,
                      currentProvince: _address.province,
                      currentDistrict: _address.district,
                      currentWards: _address.wards,
                      title:
                          '${Utils.getLocale(context)?.select} ${Utils.getLocale(context)?.wards}',
                    );
                    setState(() {
                      _address.wards = selectedWards;
                      _stateChanged();
                    });
                  },
                ),
                Divider(height: _dividerHeight),
                InfoItem(
                  firstText:
                      '${Utils.getLocale(context)?.address} (${Utils.getLocale(context)?.apartmentNumberAndStreet}) ',
                  secondText: _address.address ?? '',
                  alignTop: true,
                  breakLine: true,
                  onTap: _updateAddress,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _stateChanged() {
    _hasChanged = _address != _immutableAddress;
  }

  Future<void> _updateFullName() async {
    String updatedText = await Utils.editScreen(context,
        currentValue: _address.fullName,
        title:
            '${Utils.getLocale(context)?.edit} ${Utils.getLocale(context)?.fullName.toLowerCase()}',
        hintText:
            '${Utils.getLocale(context)?.enter} ${Utils.getLocale(context)?.fullName.toLowerCase()}...',
        length: 50, onValidate: (value) {
      if (Utils.isNullOrEmpty(value)) {
        Utils.alert(context,
            title: '${Utils.getLocale(context)?.errorOccurred}!',
            message:
                '${Utils.getLocale(context)?.mustEnter} ${Utils.getLocale(context)?.fullName.toLowerCase()}!');
        return false;
      }

      return true;
    });

    if (updatedText != _address.fullName && mounted) {
      setState(() {
        _address.fullName = updatedText;
        _stateChanged();
      });
    }
  }

  Future<void> _updateEmail() async {
    String email = Utils.getLocale(context)!.email.toLowerCase();
    String errorOccurred = Utils.getLocale(context)!.errorOccurred;

    String updatedText = await Utils.editScreen(context,
        currentValue: _address.email,
        title: '${Utils.getLocale(context)?.edit} $email',
        hintText: '${Utils.getLocale(context)?.enter} $email...',
        length: 50, onValidate: (value) {
      if (Utils.isNullOrEmpty(value)) {
        Utils.alert(context,
            title: '$errorOccurred!',
            message: '${Utils.getLocale(context)?.mustEnter} $email!');
        return false;
      }

      if (!Utils.isEmailValid(value)) {
        Utils.alert(context,
            title: '$errorOccurred!',
            message:
                '${Utils.getLocale(context)?.email} ${Utils.getLocale(context)?.wrongFormat}!');
        return false;
      }

      return true;
    });

    if (updatedText != _address.email && mounted) {
      setState(() {
        _address.email = updatedText;
        _stateChanged();
      });
    }
  }

  Future<void> _updatePhoneNumber() async {
    String phoneNumber = Utils.getLocale(context)!.phoneNumber.toLowerCase();
    String errorOccurred = Utils.getLocale(context)!.errorOccurred;

    String updatedText = await Utils.editScreen(context,
        currentValue: _address.phoneNumber,
        title: '${Utils.getLocale(context)?.edit} $phoneNumber',
        hintText: '${Utils.getLocale(context)?.enter} $phoneNumber...',
        length: 12, onValidate: (value) {
      if (Utils.isNullOrEmpty(value)) {
        Utils.alert(context,
            title: '$errorOccurred!',
            message: '${Utils.getLocale(context)?.mustEnter} $phoneNumber!');
        return false;
      }

      if (!Utils.isPhoneNumberValid(value)) {
        Utils.alert(context,
            title: '$errorOccurred!',
            message:
                '${Utils.getLocale(context)?.phoneNumber} ${Utils.getLocale(context)?.wrongFormat}!');
        return false;
      }

      return true;
    });

    if (updatedText != _address.phoneNumber && mounted) {
      setState(() {
        _address.phoneNumber = updatedText;
        _stateChanged();
      });
    }
  }

  Future<void> _updateAddress() async {
    String address = Utils.getLocale(context)!.address.toLowerCase();

    String updatedText = await Utils.editScreen(
      context,
      currentValue: _address.address,
      title: '${Utils.getLocale(context)?.edit} $address',
      hintText: '${Utils.getLocale(context)?.enter} $address...',
      length: 250,
    );

    if (updatedText != _address.address && mounted) {
      setState(() {
        _address.address = updatedText;
        _stateChanged();
      });
    }
  }

  void _saveChanges(BuildContext context, {VoidCallback? done}) {
    if (widget.doNotSave) {
      done?.call();
      return;
    }

    Utils.showLoading(context,
        textContent: Utils.getLocale(context)!.waitForLogin);
    Future.delayed(Duration(milliseconds: 500), () async {
      HttpUtil.post(
        ApiUrls.instance().getSaveAddressUrl(),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: _address.toJson(),
        onResponse: (resp) async {
          if (resp == null || resp.statusCode != 200) {
            // pop loading
            Navigator.of(context, rootNavigator: true).pop();
            Utils.alert(
              context,
              title: Utils.getLocale(context)?.failed,
              message: '${Utils.getLocale(context)?.cannotSaveAddressMessage}',
              onAccept: () {
                done?.call();
              },
            );
            return;
          }

          // pop loading
          Navigator.of(context, rootNavigator: true).pop();
          Utils.alert(
            context,
            title: Utils.getLocale(context)?.success,
            message: '${Utils.getLocale(context)?.saveAddressSuccessMessge}',
            onAccept: () {
              done?.call();
            },
          );
        },
        onTimeout: () {
          // pop loading
          Navigator.of(context, rootNavigator: true).pop();
          done?.call();
        },
      );
    });
  }

  bool _validateForm() {
    if (_address == null ||
        Utils.isNullOrEmpty(_address.fullName) ||
        Utils.isNullOrEmpty(_address.phoneNumber) ||
        Utils.isNullOrEmpty(_address.province) ||
        Utils.isNullOrEmpty(_address.district) ||
        Utils.isNullOrEmpty(_address.address)) {
      Utils.alert(
        context,
        title: Utils.getLocale(context)?.requireEnter,
        message: Utils.getLocale(context)?.requireEnterMessage,
      );
      return false;
    }

    return true;
  }
}
