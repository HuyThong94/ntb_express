import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/utils.dart';

class ForgotPasswordScreen extends StatefulWidget {
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _usernameController = TextEditingController();
  final _usernameFocusNode = FocusNode();
  final _passwordRetrievalFormKey = GlobalKey<FormState>();
  bool _hasError = false;
  late String _message;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.close, color: Colors.white),
          ),
          title: Text('${Utils.getLocale(context)?.forgotPassword}'),
        ),
        body: Container(
          //color: Utils.primaryColor,
          color: Colors.white,
          padding: const EdgeInsets.all(40.0),
          child: Center(
            child: Form(
              key: _passwordRetrievalFormKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Visibility(
                    visible: !Utils.isNullOrEmpty(_message),
                    child: Text(
                      '$_message',
                      style: TextStyle(
                        color: _hasError ? Colors.red[200] : Colors.green[100],
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  SizedBox(height: _hasError ? 15.0 : 0),
                  TextFormField(
                    cursorWidth: 1,
                    controller: _usernameController,
                    focusNode: _usernameFocusNode,
                    decoration: _decoration(
                      hintText: Utils.getLocale(context)?.username,
                      prefixIcon: Icons.account_circle,
                    ),
                    style: _white(),
                    maxLength: 30,
                    maxLines: 1,
                    cursorColor: Utils.accentColor,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (Utils.isNullOrEmpty(value!))
                        return Utils.getLocale(context)?.required;

                      return null;
                    },
                  ),
                  SizedBox(
                    height: 30.0,
                  ),
                  SizedBox(
                    width: double.infinity,
                    height: 50.0,
                    // child: RaisedButton(
                    //   onPressed: _btnPasswordRetrievalClicked,
                    //   color: Utils.accentColor,
                    //   textColor: Colors.white,
                    //   child: Text(
                    //     '${Utils.getLocale(context).passwordRetrieval}',
                    //     style: TextStyle(
                    //       fontSize: 18.0,
                    //     ),
                    //   ),
                    // ),
                    child: ElevatedButton(
                      onPressed: _btnPasswordRetrievalClicked,
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor:
                            Utils.accentColor, // Set button's text color
                      ),
                      child: Text(
                        '${Utils.getLocale(context)?.passwordRetrieval}',
                        style: TextStyle(
                          fontSize: 18.0,
                        ),
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

  InputDecoration _decoration({String? hintText, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hintText ?? '',
      hintStyle: TextStyle(
        color: Colors.black45,
      ),
      counterText: '',
      border: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.black45),
      ),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.black45),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.black45),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.orangeAccent),
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: Colors.orangeAccent),
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: Colors.black45,
      ),
      errorStyle: TextStyle(
        color: Colors.orangeAccent,
      ),
    );
  }

  TextStyle _white() {
    return TextStyle(color: Colors.black45, fontSize: 20.0);
  }

  void _btnPasswordRetrievalClicked() {
    if (!_passwordRetrievalFormKey.currentState!.validate()) {
      return;
    }

    _showWaiting();
    Future.delayed(Duration(milliseconds: 500), () async {
      final username = _usernameController.text?.trim();

      late http.Response resp;
      try {
        resp = await http.get(
            ApiUrls.instance().getForgotPasswordUrl(username!) as Uri,
            headers: {
              'Content-Type': 'application/json; charset=utf-8'
            }).timeout(const Duration(seconds: timeout), onTimeout: () async {
          _popLoading();
          setState(() {
            _hasError = false;
            _message = Utils.getLocale(context)!.requestTimeout;
          });
          throw Exception('Request timed out');
          // return null;
        });

        dynamic json = resp == null
            ? null
            : ['true', 'false'].contains(resp.body)
                ? null
                : jsonDecode(utf8.decode(resp.bodyBytes));
        String message = json == null ? '' : json['message'];

        if (resp == null || resp.statusCode != 200) {
          _popLoading();
          setState(() {
            _hasError = true;
            _message =
                '${Utils.getLocale(context)?.errorOccurred} ${resp?.statusCode}\n$message';
          });
          return;
        }

        _popLoading();
        setState(() {
          _hasError = false;
          _message = Utils.getLocale(context)!
              .sendForgotPasswordSuccessMessage
              .replaceAll('%username%', username);
        });
      } catch (e) {
        // ignored
        _popLoading();
        setState(() {
          _hasError = true;
          _message =
              '${Utils.getLocale(context)?.errorOccurred} ${resp.statusCode}\n$e';
        });
      }
    });
  }

  void _showWaiting() {
    Utils.showLoading(context,
        textContent: Utils.getLocale(context)!.waitForLogin);
  }

  void _popLoading() {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
