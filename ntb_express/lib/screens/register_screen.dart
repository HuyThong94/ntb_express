import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ntbexpress/model/user.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/http_util.dart';
import 'package:ntbexpress/util/session_util.dart';
import 'package:ntbexpress/util/utils.dart';
import 'package:random_string/random_string.dart';

class RegisterScreen extends StatefulWidget {
  final User currentUser;

  RegisterScreen({required this.currentUser});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _customerCodeController = TextEditingController();
  final _fullNameFocusNode = FocusNode();
  final _phoneNumberFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  bool _hasChanged = false;
  late User _user;
  late User _immutableUser;

  User get currentUser => SessionUtil.instance().user;

  @override
  void initState() {
    super.initState();
    _user = User();
    _user.password = ''; // to make sure password field always blank
    _immutableUser = User.clone(_user);

    // register event listeners
    _registerListeners();
  }

  @override
  void dispose() {
    // remove listeners
    _removeListeners();

    // text editing controllers
    _fullNameController?.dispose();
    _phoneNumberController?.dispose();
    _emailController?.dispose();
    _customerCodeController?.dispose();

    // focus nodes
    _fullNameFocusNode?.dispose();
    _phoneNumberFocusNode?.dispose();
    _emailFocusNode?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Scaffold(
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
                title: '${Utils.getLocale(context).saveChanges}?',
                message: Utils.getLocale(context).saveChangesMessage,
                onAccept: () {
                  _saveData(done: (user) => Navigator.of(context).pop(user));
                },
                onDecline: () => Navigator.of(context).pop(),
              );
            },
            icon: Icon(Icons.close, color: Colors.white,),
          ),
          title: Text('${Utils.getLocale(context).register}'),
          actions: [
            IconButton(
              onPressed: !_hasChanged
                  ? null
                  : () {
                      _saveData(
                          done: (user) => Navigator.of(context).pop(user));
                    },
              icon: Icon(Icons.done, color: _hasChanged ? Colors.white : Theme.of(context).disabledColor,),
            ),
          ],
        ),
        body: SafeArea(
          child: Container(
            padding: const EdgeInsets.only(left: 10.0, top: 10.0, right: 10.0),
            constraints: const BoxConstraints.expand(),
            color: Colors.white,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      focusNode: _fullNameFocusNode,
                      controller: _fullNameController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: Utils.getLocale(context).fullName,
                        hintText:
                            '${Utils.getLocale(context).enter} ${Utils.getLocale(context).fullName.toLowerCase()}...',
                        counterText: '',
                      ),
                      maxLength: 50,
                      onFieldSubmitted: (value) {
                        _fullNameFocusNode.unfocus();
                        FocusScope.of(context)
                            .requestFocus(_phoneNumberFocusNode);
                      },
                      validator: (value) {
                        if (Utils.isNullOrEmpty(value!))
                          return Utils.getLocale(context).required;

                        return null;
                      },
                    ),
                    TextFormField(
                      focusNode: _phoneNumberFocusNode,
                      controller: _phoneNumberController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: Utils.getLocale(context).phoneNumber,
                        hintText:
                        '${Utils.getLocale(context).enter} ${Utils.getLocale(context).phoneNumber.toLowerCase()}...',
                        counterText: '',
                      ),
                      maxLength: 12,
                      onFieldSubmitted: (value) {
                        _phoneNumberFocusNode.unfocus();
                        FocusScope.of(context)
                            .requestFocus(_emailFocusNode);
                      },
                      validator: (value) {
                        if (Utils.isNullOrEmpty(value!))
                          return Utils.getLocale(context).required;
                        if (!Utils.isPhoneNumberValid(value))
                          return '${Utils.getLocale(context).phoneNumber} ${Utils.getLocale(context).wrongFormat}';

                        return null;
                      },
                    ),
                    Visibility(
                      visible: false, // hide for register form
                      child: TextFormField(
                        controller: _customerCodeController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: Utils.getLocale(context).customerCode,
                          hintText:
                              '${Utils.getLocale(context).enter} ${Utils.getLocale(context).customerCode.toLowerCase()}...',
                          counterText: '',
                        ),
                        maxLength: 50,
                        validator: (value) {
                          if (Utils.isNullOrEmpty(value!))
                            return '${Utils.getLocale(context).required}';
                          if (RegExp(r'[^a-zA-Z_0-9]+').hasMatch(value))
                            return '${Utils.getLocale(context).customerCode} ${Utils.getLocale(context).wrongFormat}';

                          return null;
                        },
                      ),
                    ),
                    TextFormField(
                      focusNode: _emailFocusNode,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: Utils.getLocale(context).email,
                        hintText:
                            '${Utils.getLocale(context).enter} ${Utils.getLocale(context).email.toLowerCase()}...',
                        counterText: '',
                      ),
                      maxLength: 50,
                      onFieldSubmitted: (value) {
                        _emailFocusNode.unfocus();
                      },
                      validator: (value) {
                        if (Utils.isNullOrEmpty(value!))
                          return '${Utils.getLocale(context).required}';
                        if (!Utils.isEmailValid(value))
                          return '${Utils.getLocale(context).email} ${Utils.getLocale(context).wrongFormat}';

                        return null;
                      },
                    ),
                    const SizedBox(height: 20.0),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveData({ValueChanged<User>? done}) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // prepare data
    _user.username = _user.phoneNumber;
    _user.password = _generatePassword();
    //_user.managerId = currentUser.username;
    _user.userType = UserType.customer;
    _user.isCreate = 1; // 1: create new, other: update
    if (Utils.isNullOrEmpty(_user.email)) {
      // _user.email = null; // avoid exception from DB for Unique constraint
    }

    // Save user
    _showWaiting();
    Future.delayed(Duration(milliseconds: 500), () async {
      HttpUtil.postRegister(
        ApiUrls.instance().getRegisterUrl(),
        user: _user,
        onDone: (resp) async {
          print(resp);
          if (resp == null || resp.statusCode != 200) {
            _popLoading();
            dynamic json = resp == null || Utils.isNullOrEmpty(resp.body)
                ? null
                : jsonDecode(utf8.decode(resp.bodyBytes));
            String error = json == null ? '' : json['message'];
            Utils.alert(
              context,
              title: Utils.getLocale(context).failed,
              message:
                  '${Utils.getLocale(context).errorOccurred} ${resp?.statusCode}\n$error',
              onAccept: () {
                // ignored
              },
            );
            return;
          }

          dynamic json = jsonDecode(utf8.decode(resp.bodyBytes));
          User? savedUser = json == null ? null : User.fromJson(json);
          if (savedUser != null) {
            _popLoading();
            Utils.alert(
              context,
              title: Utils.getLocale(context).success,
              message: Utils.getLocale(context).registerSuccessMessage,
              onAccept: () {
                if (done != null) {
                  done(savedUser);
                }
              },
            );
          } else {
            _popLoading();
            Utils.alert(
              context,
              title: Utils.getLocale(context).success,
              message: '${Utils.getLocale(context).createUserSuccessMessage}',
              onAccept: () {
                if (done != null) {
                  done(savedUser!);
                }
              },
            );
          }
        },
        onTimeout: () {
          _popLoading();
          if (done != null) {
            done(null);
          }
        },
      );
    });
  }

  void _showWaiting() {
    Utils.showLoading(context,
        textContent: Utils.getLocale(context).waitForLogin);
  }

  void _popLoading() {
    Navigator.of(context, rootNavigator: true).pop();
  }

  void _stateChanged() {
    _hasChanged = _user != _immutableUser;
  }

  String _generatePassword() {
    return randomAlphaNumeric(8);
  }

  void _updateUI() {
    if (mounted && _hasChanged != (_user != _immutableUser)) {
      setState(_stateChanged);
    }
  }

  void _registerListeners() {
    _fullNameController.addListener(_fullNameListener);
    _phoneNumberController.addListener(_phoneNumberListener);
    _emailController.addListener(_emailListener);
    _customerCodeController.addListener(_customerIdListener);
  }

  void _removeListeners() {
    _fullNameController.removeListener(_fullNameListener);
    _phoneNumberController.removeListener(_phoneNumberListener);
    _emailController.removeListener(_emailListener);
    _customerCodeController.removeListener(_customerIdListener);
  }

  void _makeCustomerId() {
    String name = Utils.isNullOrEmpty(_user.fullName)
        ? ''
        : _user.fullName.substring(_user.fullName.lastIndexOf(' ') != -1
            ? _user.fullName.lastIndexOf(' ')
            : 0);
    String phone = Utils.isNullOrEmpty(_user.phoneNumber)
        ? ''
        : _user.phoneNumber.substring(
            _user.phoneNumber.length > 4 ? _user.phoneNumber.length - 4 : 0);
    _customerCodeController.text =
        Utils.changeAlias('${name.toLowerCase()}$phone');
    _user.customerId = _customerCodeController.text!.trim();
  }

  // Listeners
  void _fullNameListener() {
    _user.fullName = _fullNameController.text!.trim();
    _makeCustomerId();

    _updateUI();
  }

  void _phoneNumberListener() {
    _user.phoneNumber = _phoneNumberController.text!.trim();
    _makeCustomerId();

    _updateUI();
  }

  void _emailListener() {
    _user.email = _emailController.text!.trim();
    _updateUI();
  }

  void _customerIdListener() {
    _user.customerId = _customerCodeController.text!.trim();
    _updateUI();
  }

}
