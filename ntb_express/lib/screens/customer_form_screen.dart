import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:ntbexpress/model/address.dart';
import 'package:ntbexpress/model/file_holder.dart';
import 'package:ntbexpress/model/user.dart';
import 'package:ntbexpress/screens/address_form_screen.dart';
import 'package:ntbexpress/screens/address_management_screen.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/http_util.dart';
import 'package:ntbexpress/util/session_util.dart';
import 'package:ntbexpress/util/utils.dart';
import 'package:ntbexpress/widgets/info_item.dart';
import 'package:random_string/random_string.dart';

class CustomerFormScreen extends StatefulWidget {
  final bool isUpdate;
  final User? currentUser;

  CustomerFormScreen({this.isUpdate = false, this.currentUser});

  @override
  _CustomerFormScreenState createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _fullNameController = TextEditingController();
  final _phoneNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _refUserController = TextEditingController();
  final _customerCodeController = TextEditingController();
  final _fullNameFocusNode = FocusNode();
  final _phoneNumberFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _refUserFocusNode = FocusNode();
  final picker = ImagePicker();
  bool _hasChanged = false;
  late File _image;
  bool _active = true;
  bool _showPassword = true;
  late User _user;
  late User _immutableUser;
  final List<Address> _addressList = [];
  final _maskFormatter = MaskTextInputFormatter(
      mask: '##-##-####', filter: {'#': RegExp(r'[0-9]')});
  static String _datePattern = 'dd-MM-yyyy';
  final DateFormat _dateFormat = DateFormat(_datePattern);
  final dateRegex = RegExp(r'\d{2}-\d{2}-\d{4}');
  final _dobController = TextEditingController();
  final _dobFocusNode = FocusNode();

  User get currentUser => SessionUtil.instance().user;

  Future _getImage() async {
    // final pickedFile = await picker.getImage(source: ImageSource.gallery);
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      _hasChanged = true;
      setState(() => _image = File(pickedFile.path));
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.isUpdate) {
      _user =
          widget.currentUser == null ? User() : User.clone(widget.currentUser!);
      _initValues();
    } else {
      _user = User();
    }
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
    _passwordController?.dispose();
    _dobController?.dispose();
    _refUserController?.dispose();
    _customerCodeController?.dispose();

    // focus nodes
    _fullNameFocusNode?.dispose();
    _phoneNumberFocusNode?.dispose();
    _emailFocusNode?.dispose();
    _passwordFocusNode?.dispose();
    _dobFocusNode?.dispose();
    _refUserFocusNode?.dispose();
    super.dispose();
  }

  void _initValues() {
    _fullNameController.text = _user.fullName;
    _phoneNumberController.text = _user.phoneNumber;
    _dobController.text =
        _user.dob == null ? '' : Utils.getDateString(_user.dob!, _datePattern);
    _emailController.text = _user.email;
    _refUserController.text = _user.refId;
    _customerCodeController.text = _user.customerId;
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
            icon: Icon(Icons.close),
          ),
          title: Text(
              '${!widget.isUpdate ? Utils.getLocale(context).add : Utils.getLocale(context).edit} ${Utils.getLocale(context).customer}'),
          actions: [
            IconButton(
              onPressed: !_hasChanged
                  ? null
                  : () {
                      _saveData(
                          done: (user) => Navigator.of(context).pop(user));
                    },
              icon: Icon(Icons.done),
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 40.0, horizontal: 0.0),
                      color: Colors.white,
                      child: Center(
                        child: GestureDetector(
                          onTap: _getImage,
                          child: CircleAvatar(
                            radius: 43.0,
                            backgroundColor: Theme.of(context).disabledColor,
                            child: CircleAvatar(
                              radius: 40.0,
                              backgroundImage: _image != null
                                  ? FileImage(_image)
                                  : (widget.isUpdate &&
                                          _user.avatarImgDTO != null)
                                      ? NetworkImage(
                                          '${ApiUrls.instance().baseUrl}/${_user.avatarImgDTO.flePath}?t=${DateTime.now().millisecondsSinceEpoch}')
                                      : AssetImage(
                                          'assets/images/default-avatar.png'),
                            ),
                          ),
                        ),
                      ),
                    ),
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
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            readOnly: widget.isUpdate,
                            enabled: !widget.isUpdate,
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
                              /*FocusScope.of(context)
                                  .requestFocus(_dobFocusNode);*/
                            },
                            validator: (value) {
                              if (Utils.isNullOrEmpty(value!))
                                return Utils.getLocale(context).required;
                              if (!Utils.isPhoneNumberValid(value))
                                return '${Utils.getLocale(context).phoneNumber} ${Utils.getLocale(context).wrongFormat}';

                              return null;
                            },
                          ),
                        ),
                        /*SizedBox(width: 5.0),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  keyboardType: TextInputType.datetime,
                                  inputFormatters: [_maskFormatter],
                                  controller: _dobController,
                                  textInputAction: TextInputAction.next,
                                  decoration: InputDecoration(
                                    labelText:
                                        '${Utils.getLocale(context).dateOfBirth}',
                                    hintText: _datePattern,
                                    counterText: '',
                                  ),
                                  onFieldSubmitted: (value) {
                                    _dobFocusNode.unfocus();
                                    FocusScope.of(context)
                                        .requestFocus(_emailFocusNode);
                                  },
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _selectDate(context, onPicked: (date) {
                                    if (date != null) {
                                      _dobController.text =
                                          _dateFormat.format(date);
                                    }
                                  });
                                },
                                child: Icon(
                                  Icons.date_range,
                                  color: Theme.of(context).disabledColor,
                                ),
                              )
                            ],
                          ),
                        ),*/
                      ],
                    ),
                    TextFormField(
                      controller: _customerCodeController,
                      textInputAction: TextInputAction.next,
                      enabled: !widget.isUpdate,
                      decoration: InputDecoration(
                        labelText: Utils.getLocale(context).customerCode,
                        hintText:
                            '${Utils.getLocale(context).enter} ${Utils.getLocale(context).customerCode.toLowerCase()}...',
                        counterText: '',
                      ),
                      maxLength: 50,
                      validator: (value) {
                        if (widget.isUpdate) return null;
                        if (Utils.isNullOrEmpty(value!))
                          return '${Utils.getLocale(context).required}';
                        if (RegExp(r'[^a-zA-Z_0-9]+').hasMatch(value))
                          return '${Utils.getLocale(context).customerCode} ${Utils.getLocale(context).wrongFormat}';

                        return null;
                      },
                    ),
                    /*TextFormField(
                      focusNode: _emailFocusNode,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: Utils.getLocale(context).email,
                        hintText:
                            '${Utils.getLocale(context).enter} ${Utils.getLocale(context).email.toLowerCase()}...',
                        counterText: '',
                      ),
                      maxLength: 50,
                      onFieldSubmitted: (value) {
                        _emailFocusNode.unfocus();
                        FocusScope.of(context).requestFocus(_refUserFocusNode);
                      },
                      validator: (value) {
                        if (Utils.isNullOrEmpty(value))
                          return '${Utils.getLocale(context).required}';
                        if (!Utils.isEmailValid(value))
                          return '${Utils.getLocale(context).email} ${Utils.getLocale(context).wrongFormat}';

                        return null;
                      },
                    ),
                    TextFormField(
                      focusNode: _refUserFocusNode,
                      controller: _refUserController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText:
                            '${Utils.getLocale(context).whoIntroducedYou} (${Utils.getLocale(context).optional})',
                        hintText:
                            '${Utils.getLocale(context).enter} ${Utils.getLocale(context).whoIntroducedYou.toLowerCase()}...',
                        counterText: '',
                      ),
                      maxLength: 50,
                      onFieldSubmitted: (value) {
                        _refUserFocusNode.unfocus();
                        FocusScope.of(context).requestFocus(_passwordFocusNode);
                      },
                      validator: (value) {
                        return null;
                      },
                    ),*/
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            focusNode: _passwordFocusNode,
                            controller: _passwordController,
                            keyboardType: TextInputType.text,
                            textInputAction: TextInputAction.done,
                            decoration: InputDecoration(
                              labelText: Utils.getLocale(context).password,
                              hintText:
                                  '${Utils.getLocale(context).enter} ${Utils.getLocale(context).password.toLowerCase()}...',
                              counterText: '',
                              suffixIcon: IconButton(
                                onPressed: () {
                                  setState(
                                      () => _showPassword = !_showPassword);
                                },
                                icon: Icon(_showPassword
                                    ? Icons.visibility_off
                                    : Icons.visibility),
                              ),
                            ),
                            validator: (value) {
                              if (widget.isUpdate) return null;

                              if (Utils.isNullOrEmpty(value!))
                                return Utils.getLocale(context).required;
                              if (value.length < 8)
                                return '${Utils.getLocale(context).passwordLengthRequired}';

                              return null;
                            },
                            obscureText: !_showPassword,
                            maxLength: 250,
                          ),
                        ),
                        IconButton(
                          onPressed: _generatePassword,
                          icon: Icon(
                            Icons.autorenew,
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                        SizedBox(width: 5.0),
                        IconButton(
                          onPressed: _copyToClipboard,
                          icon: Icon(
                            Icons.content_copy,
                            color: Theme.of(context).disabledColor,
                          ),
                        ),
                      ],
                    ),
                    Visibility(
                      visible: widget.isUpdate,
                      child: InfoItem(
                        firstText: Utils.getLocale(context).addressManagement,
                        secondText: '',
                        onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (context) =>
                                    AddressManagementScreen(forUser: _user))),
                      ),
                    ),
                    Visibility(
                      visible: !widget.isUpdate,
                      child: InfoItem(
                        onTap: () async {
                          Address address = await Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => AddressFormScreen(
                                      forUser: _user, doNotSave: true)));

                          if (address != null) {
                            if (mounted) {
                              setState(() {
                                _addressList.add(address);
                              });
                            } else {
                              _addressList.add(address);
                            }
                          }
                        },
                        useWidget: true,
                        breakLine: true,
                        firstChild: Text('${Utils.getLocale(context).address}'),
                        bottomChild: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5.0),
                          child: _addressList.isEmpty
                              ? Text(
                                  '${Utils.getLocale(context).unavailable}',
                                  style: TextStyle(color: Colors.black45),
                                )
                              : _addressWidgetItems(),
                        ),
                      ),
                    ),
                    Visibility(
                      visible: false, // only show if current use is Admin
                      child: Row(
                        children: [
                          SizedBox(
                            width: 25.0,
                            child: Checkbox(
                              onChanged: (value) {
                                setState(() => _active = value!);
                              },
                              value: _active,
                            ),
                          ),
                          SizedBox(width: 5.0),
                          Text('${Utils.getLocale(context).active}')
                        ],
                      ),
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

  Future<void> _selectDate(BuildContext context,
      {ValueChanged<DateTime>? onPicked}) async {
    final DateTime? picked = await showDatePicker(
        context: context,
        initialDate: DateTime(1970),
        firstDate: DateTime(1930),
        lastDate: DateTime(2020));

    if (onPicked != null) {
      onPicked(picked!);
    }
  }

  void _saveData({ValueChanged<User> done}) {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // prepare data
    /*String dobString = _dobController?.text?.trim();
    _user.dob = Utils.isNullOrEmpty(dobString)
        ? null
        : !dateRegex.hasMatch(dobString)
            ? null
            : DateTime.parse(dobString.split('-').reversed.join())
                .millisecondsSinceEpoch;
    if (_user.dob == null) {
      Utils.alert(context,
          title: Utils.getLocale(context).required,
          message: '${Utils.getLocale(context).dobIsRequired}!');
      return;
    }*/
    _user.username = _user.phoneNumber;
    _user.managerId = currentUser.username;
    _user.userType = UserType.customer;
    _user.isCreate = widget.isUpdate ? 0 : 1; // 1: create new, other: update
    if (Utils.isNullOrEmpty(_user.email)) {
      _user.email = ''; // avoid exception from DB for Unique constraint
    }
    if (widget.isUpdate && _image != null) {
      // update avatar
      _user.avatarImgDTO = null; // request server delete the old avatar
    }

    if (_addressList == null || _addressList.isEmpty) {
      Utils.alert(context,
          title: Utils.getLocale(context).required,
          message: '${Utils.getLocale(context).addressIsRequired}!');
      return;
    }

    // Save user
    _showWaiting();
    Future.delayed(Duration(milliseconds: 500), () async {
      HttpUtil.postUser(
        ApiUrls.instance().getUsersUrl(),
        user: _user,
        avatar: _image == null ? null : FileHolder(file: _image),
        onDone: (resp) async {
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
            // save addresses
            for (var address in _addressList) {
              address.userName = savedUser.username;
              await _saveAddress(address);
            }

            _popLoading();
            Utils.alert(
              context,
              title: Utils.getLocale(context).success,
              message: widget.isUpdate
                  ? '${Utils.getLocale(context).updateUserInfoSuccessMessage}'
                  : '${Utils.getLocale(context).createUserSuccessMessage}',
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
              message: widget.isUpdate
                  ? '${Utils.getLocale(context).updateUserInfoSuccessMessage}'
                  : '${Utils.getLocale(context).createUserSuccessMessage}',
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

  Future<bool> _saveAddress(Address address) async {
    final c = Completer<bool>();
    HttpUtil.post(
      ApiUrls.instance().getSaveAddressUrl(),
      headers: {'Content-Type': 'application/json; charset=utf-8'},
      body: address.toJson(),
      onResponse: (resp) async {
        if (resp == null || resp.statusCode != 200) {
          c.complete(false);
          return;
        }

        c.complete(true);
      },
      onTimeout: () {
        c.complete(false);
      },
    );

    return c.future;
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

  void _generatePassword() {
    _passwordController.text = randomAlphaNumeric(8);
    _copyToClipboard();
  }

  void _copyToClipboard() {
    final currentText = _passwordController.text?.trim() ?? '';
    if (Utils.isNullOrEmpty(currentText)) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('${Utils.getLocale(context).nothingToCopy}'),
      ));
      return;
    }

    Clipboard.setData(ClipboardData(text: currentText)).then((value) {
      _scaffoldKey.currentState.showSnackBar(SnackBar(
        content: Text('${Utils.getLocale(context).passwordCopied}'),
      ));
    });
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
    _passwordController.addListener(_passwordListener);
    _refUserController.addListener(_refUserListener);
    _customerCodeController.addListener(_customerIdListener);
  }

  void _removeListeners() {
    _fullNameController.removeListener(_fullNameListener);
    _phoneNumberController.removeListener(_phoneNumberListener);
    _emailController.removeListener(_emailListener);
    _passwordController.removeListener(_passwordListener);
    _refUserController.removeListener(_refUserListener);
    _customerCodeController.removeListener(_customerIdListener);
  }

  void _makeCustomerId() {
    if (widget.isUpdate) return;

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
    if (widget.isUpdate) return;

    _user.customerId = _customerCodeController.text!.trim();
    _updateUI();
  }

  void _passwordListener() {
    _user.password = _passwordController.text!.trim();
    _updateUI();
  }

  void _refUserListener() {
    _user.refId = _refUserController.text!.trim();
    _updateUI();
  }

  Widget _addressWidgetItems() {
    return Column(
      children: _addressList
          .map((address) => ListTile(
                title: Text('${address.fullName}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(address.phoneNumber ?? ''),
                    Text([
                      address.address,
                      address.wards,
                      address.district,
                      address.province
                    ].join(', ')!.replaceAll(' ,', '')),
                  ],
                ),
                trailing: IconButton(
                  onPressed: () {
                    setState(() {
                      _addressList.remove(address);
                    });
                  },
                  icon: Icon(Icons.clear),
                ),
              ))
          .toList(),
    );
  }
}
