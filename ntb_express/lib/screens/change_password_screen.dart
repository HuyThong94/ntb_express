import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:ntbexpress/model/user.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/http_util.dart';
import 'package:ntbexpress/util/utils.dart';

class ChangePasswordScreen extends StatefulWidget {
  final User forUser;

  ChangePasswordScreen(this.forUser);

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmNewPasswordController = TextEditingController();

  final _passwordFocusNode = FocusNode();
  final _newNasswordFocusNode = FocusNode();
  final _confirmNewPasswordFocusNode = FocusNode();

  bool _showPassword = false;
  bool _showNewPassword = false;
  bool _showConfirmNewPassword = false;

  User get user => widget.forUser;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Scaffold(
        appBar: AppBar(
          title: Text('${Utils.getLocale(context)?.changePassword}'),
        ),
        body: Container(
          color: Utils.backgroundColor,
          padding: const EdgeInsets.all(8.0),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /*RichText(
                    text: TextSpan(
                      text: 'Your username ',
                      style: TextStyle(
                        color: Theme.of(context).disabledColor,
                      ),
                      children: [
                        TextSpan(
                          text: '${user.username}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                          ),
                        ),
                      ]
                    ),
                  ),*/
                  TextFormField(
                    focusNode: _passwordFocusNode,
                    controller: _passwordController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: Utils.getLocale(context)?.password,
                      hintText:
                          '${Utils.getLocale(context)?.enter} ${Utils.getLocale(context)?.password.toLowerCase()}...',
                      counterText: '',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _showPassword = !_showPassword);
                        },
                        icon: Icon(_showPassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                      ),
                    ),
                    validator: (value) {
                      if (Utils.isNullOrEmpty(value!))
                        return Utils.getLocale(context)?.required;
                      if (value.length < 8)
                        return '${Utils.getLocale(context)?.passwordLengthRequired}';

                      return null;
                    },
                    obscureText: !_showPassword,
                    maxLength: 250,
                  ),
                  TextFormField(
                    focusNode: _newNasswordFocusNode,
                    controller: _newPasswordController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: '${Utils.getLocale(context)?.newPassword}',
                      hintText:
                          '${Utils.getLocale(context)?.enter} ${Utils.getLocale(context)?.password.toLowerCase()}...',
                      counterText: '',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _showNewPassword = !_showNewPassword);
                        },
                        icon: Icon(_showNewPassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                      ),
                    ),
                    validator: (value) {
                      if (Utils.isNullOrEmpty(value!))
                        return Utils.getLocale(context)?.required;
                      if (value.length < 8)
                        return '${Utils.getLocale(context)?.passwordLengthRequired}';
                      if (_passwordController.text.trim() == value)
                        return '${Utils.getLocale(context)?.newPasswordNotMatchMessage}';

                      return null;
                    },
                    obscureText: !_showNewPassword,
                    maxLength: 250,
                  ),
                  TextFormField(
                    focusNode: _confirmNewPasswordFocusNode,
                    controller: _confirmNewPasswordController,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText:
                          '${Utils.getLocale(context)?.confirmNewPassword}',
                      hintText:
                          '${Utils.getLocale(context)?.enter} ${Utils.getLocale(context)?.password.toLowerCase()}...',
                      counterText: '',
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() => _showConfirmNewPassword =
                              !_showConfirmNewPassword);
                        },
                        icon: Icon(_showConfirmNewPassword
                            ? Icons.visibility_off
                            : Icons.visibility),
                      ),
                    ),
                    validator: (value) {
                      if (Utils.isNullOrEmpty(value!))
                        return Utils.getLocale(context)?.required;
                      if (value.length < 8)
                        return '${Utils.getLocale(context)?.passwordLengthRequired}';
                      if (_newPasswordController.text.trim() != value)
                        return '${Utils.getLocale(context)?.confirmPasswordNotMatchMessage}';

                      return null;
                    },
                    obscureText: !_showConfirmNewPassword,
                    maxLength: 250,
                  ),
                  const SizedBox(height: 20.0),
                  SizedBox(
                    width: double.infinity,
                    height: 50.0,
                    // child: RaisedButton(
                    //   onPressed: _btnChangeClicked,
                    //   color: Utils.accentColor,
                    //   textColor: Colors.white,
                    //   child: Text(
                    //     '${Utils.getLocale(context).changePassword}',
                    //     style: TextStyle(fontSize: 18.0),
                    //   ),
                    // ),
                    child: ElevatedButton(
                      onPressed: _btnChangeClicked,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            Utils.accentColor, // Set the button's text color
                      ),
                      child: Text(
                        '${Utils.getLocale(context)?.changePassword}',
                        style: TextStyle(fontSize: 18.0),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _btnChangeClicked() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    _showWaiting();
    Future.delayed(Duration(milliseconds: 500), () async {
      HttpUtil.put(
        ApiUrls.instance().getChangePasswordUrl(),
        headers: {'Content-Type': 'application/json; charset=utf-8'},
        body: {
          'username': user.username,
          'password': _passwordController.text?.trim(),
          'newPassword': _newPasswordController.text?.trim()
        },
        onResponse: (resp) {
          print(resp?.body);
          if (resp == null || resp.statusCode != 200) {
            _popLoading();
            dynamic json = resp != null && !Utils.isNullOrEmpty(resp.body)
                ? jsonDecode(utf8.decode(resp.bodyBytes))
                : null;
            String message = json == null ? '' : json['message'];

            Utils.alert(context,
                title: Utils.getLocale(context)?.failed,
                message:
                    '${Utils.getLocale(context)?.errorOccurred} ${resp?.statusCode}\n$message');
            return;
          }

          _popLoading();
          Utils.alert(context,
              title: Utils.getLocale(context)?.success,
              message:
                  '${Utils.getLocale(context)?.changePasswordSuccessMessage}',
              onAccept: _reset);
        },
        onTimeout: () {
          _popLoading();
          Utils.alert(context,
              title: Utils.getLocale(context)?.failed,
              message: '${Utils.getLocale(context)?.requestTimeout}');
        },
      );
    });
  }

  void _reset() {
    _passwordController.clear();
    _newPasswordController.clear();
    _confirmNewPasswordController.clear();
  }

  void _showWaiting() {
    Utils.showLoading(context,
        textContent: Utils.getLocale(context)!.waitForLogin);
  }

  void _popLoading() {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
