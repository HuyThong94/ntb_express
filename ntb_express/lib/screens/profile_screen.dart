import 'dart:convert';
import 'dart:io';

import 'package:file/memory.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:ntbexpress/model/file_holder.dart';
import 'package:ntbexpress/model/user.dart';
import 'package:ntbexpress/screens/address_management_screen.dart';
import 'package:ntbexpress/screens/change_password_screen.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/http_util.dart';
import 'package:ntbexpress/util/session_util.dart';
import 'package:ntbexpress/util/utils.dart';
import 'package:ntbexpress/widgets/app_provider.dart';
import 'package:ntbexpress/widgets/info_item.dart';

class ProfileScreen extends StatefulWidget {
  final User currentUser;

  ProfileScreen({required this.currentUser});

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late File _image;
  final picker = ImagePicker();
  final _dividerHeight = 0.5;
  late User _user;
  late User _immutableUser;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _user = widget.currentUser == null
        ? User()
        : User.clone(widget.currentUser) ?? User();
    _immutableUser = User.clone(_user);
  }

  Future<void> _getImage() async {
    showModalBottomSheet(
        context: context,
        builder: (_) => Container(
              child: Wrap(
                children: [
                  ListTile(
                    leading: Icon(Icons.image),
                    title: Text('${Utils.getLocale(context)?.cameraRoll}'),
                    onTap: _cameraRoll,
                  ),
                  ListTile(
                    leading: Icon(Icons.camera),
                    title: Text('${Utils.getLocale(context)?.takeAPhoto}'),
                    onTap: _takePhoto,
                  ),
                ],
              ),
            ));

    return;
  }

  Future<void> _cameraRoll() async {
    Navigator.of(context).pop(); // hide bottom sheet
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    // final pickedFile = await picker.getImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      _hasChanges = true;
      final file = await compute(_computeFile, File(pickedFile.path));
      setState(() => _image = file!);
    }
  }

  Future<void> _takePhoto() async {
    Navigator.of(context).pop(); // hide bottom sheet
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null && mounted) {
      _hasChanges = true;
      final file = await compute(_computeFile, File(pickedFile.path));
      setState(() => _image = file!);
    }
  }

  static Future<File?> _computeFile(File file) async {
    if (file == null) return null;

    return await Utils.resizeImage(MemoryFileSystem()
        .file(file.path.substring(file.path.lastIndexOf('/') + 1))
      ..writeAsBytesSync(file.readAsBytesSync()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${Utils.getLocale(context)?.yourProfile}'),
        actions: [
          IconButton(
            onPressed: !_hasChanges
                ? null
                : () {
                    // TODO: validate
                    _saveChanges();
                    //Navigator.of(context).pop();
                  },
            icon: Icon(Icons.done),
          ),
        ],
      ),
      body: Container(
        constraints: BoxConstraints.expand(),
        padding: const EdgeInsets.symmetric(vertical: 0.0, horizontal: 0.0),
        color: Utils.backgroundColor,
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 40.0, horizontal: 0.0),
                color: Colors.white,
                child: Center(
                  child: GestureDetector(
                    onTap: _getImage,
                    child: CircleAvatar(
                      radius: 43.0,
                      backgroundColor: Theme.of(context).disabledColor,
                      child: CircleAvatar(
                        radius: 40.0,
                        // backgroundImage: _image != null
                        //     ? FileImage(_image)
                        //     : (_user != null &&
                        //             _user.avatarImgDTO != null &&
                        //             !Utils.isNullOrEmpty(
                        //                 _user.avatarImgDTO.flePath))
                        //         ? NetworkImage(
                        //             '${ApiUrls.instance().baseUrl}/${_user.avatarImgDTO.flePath}?t=${DateTime.now().millisecondsSinceEpoch}')
                        //         : AssetImage(
                        //             'assets/images/default-avatar.png'),
                      ),
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: _getImage,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  width: double.infinity,
                  color: Colors.white70,
                  child: Text(
                    '${Utils.getLocale(context)?.touchToChange}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.0),
                  ),
                ),
              ),
              SizedBox(height: 10.0),
              InfoItem(
                firstText: '${Utils.getLocale(context)?.username} ',
                secondText: _user.username,
              ),
              Divider(height: _dividerHeight),
              InfoItem(
                firstText: '${Utils.getLocale(context)?.fullName} ',
                secondText: _user.fullName ?? '',
              ),
              Divider(height: _dividerHeight),
              InfoItem(
                firstText: '${Utils.getLocale(context)?.dateOfBirth} ',
                secondText: _user.dob == null
                    ? ''
                    : Utils.getDateString(_user.dob!, 'dd/MM/yyy') ?? '',
                onTap: _updateDob,
              ),
              Divider(height: _dividerHeight),
              InfoItem(
                firstText: '${Utils.getLocale(context)?.email} ',
                secondText: _user.email,
                onTap: _updateEmail,
              ),
              Divider(height: _dividerHeight),
              InfoItem(
                firstText: '${Utils.getLocale(context)?.phoneNumber} ',
                secondText: _user.phoneNumber,
                //onTap: _updatePhoneNumber,
              ),
              Divider(height: _dividerHeight),
              InfoItem(
                firstText: '${Utils.getLocale(context)?.type} ',
                secondText:
                    '${Utils.getUserTypeString(context, _user.userType!)}',
              ),
              Divider(height: _dividerHeight),
              InfoItem(
                firstText: '${Utils.getLocale(context)?.customerCode} ',
                secondText: '',
              ),
              /*Divider(height: _dividerHeight),
              InfoItem(
                firstText: '${Utils.getLocale(context).address} ',
                secondText: _user.address,
                alignTop: true,
                breakLine: true,
                onTap: _updateAddress,
              ),*/
              Divider(height: _dividerHeight),
              InfoItem(
                firstText: Utils.getLocale(context)?.addressManagement,
                secondText: '',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => AddressManagementScreen())),
              ),
              InfoItem(
                firstText: Utils.getLocale(context)?.changePassword,
                secondText: '',
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => ChangePasswordScreen(_user))),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /*String _getDoB(String date) {
    if (Utils.isNullOrEmpty(date)) return null;
    try {
      var time = DateTime.parse(date);
      if (time == null) return null;

      return DateFormat('dd/MM/yyyy').format(time);
    } catch (e) {
      return null;
    }
  }*/

  /*Future _getImage() async {
    final pickedFile = await picker.getImage(source: ImageSource.gallery);
    if (pickedFile != null && mounted) {
      _hasChanges = true;
      setState(() => _image = File(pickedFile.path));
    }
  }*/

  void _stateChanged() {
    _hasChanges = _user != _immutableUser;
  }

  Future<void> _updateEmail() async {
    String email = Utils.getLocale(context)!.email.toLowerCase();
    String errorOccurred = Utils.getLocale(context)!.errorOccurred;

    String updatedText = await Utils.editScreen(context,
        currentValue: _user.email,
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

    if (updatedText != _user.email && mounted) {
      setState(() {
        _user.email = updatedText;
        _stateChanged();
      });
    }
  }

  Future<void> _updatePhoneNumber() async {
    String phoneNumber = Utils.getLocale(context)!.phoneNumber.toLowerCase();
    String errorOccurred = Utils.getLocale(context)!.errorOccurred;

    String updatedText = await Utils.editScreen(context,
        currentValue: _user.phoneNumber,
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

    if (updatedText != _user.phoneNumber && mounted) {
      setState(() {
        _user.phoneNumber = updatedText;
        _stateChanged();
      });
    }
  }

  Future<void> _updateDob() async {
    String dob = Utils.getLocale(context)!.dateOfBirth.toLowerCase();
    String errorOccurred = Utils.getLocale(context)!.errorOccurred;

    String updatedText = await Utils.editScreen(context,
        currentValue: Utils.getDateString(_user.dob!, 'dd/MM/yyyy'),
        title: '${Utils.getLocale(context)?.edit} $dob',
        hintText: '${Utils.getLocale(context)?.enter} $dob...',
        length: 10, onValidate: (value) {
      if (Utils.isNullOrEmpty(value)) {
        Utils.alert(context,
            title: '$errorOccurred!',
            message: '${Utils.getLocale(context)?.mustEnter} $dob!');
        return false;
      }

      final regex = RegExp(r'\d{2}/\d{2}/\d{4}');
      if (!regex.hasMatch(value)) {
        Utils.alert(context,
            title: '$errorOccurred!',
            message:
                '${Utils.getLocale(context)?.dateOfBirth} ${Utils.getLocale(context)?.wrongFormat}!');
        return false;
      }

      return true;
    });

    String formattedDate = updatedText.split('/').reversed.join('-');
    DateTime date = DateTime.parse(formattedDate);
    if (date != null) {
      if (date.millisecondsSinceEpoch != _user.dob && mounted) {
        setState(() {
          _user.dob = date.millisecondsSinceEpoch;
          _stateChanged();
        });
      }
    }
  }

  /*Future<void> _updateAddress() async {
    String address = Utils.getLocale(context).address.toLowerCase();

    String updatedText = await Utils.editScreen(
      context,
      currentValue: _user.address,
      title: '${Utils.getLocale(context).edit} $address',
      hintText: '${Utils.getLocale(context).enter} $address...',
      length: 250,
    );

    if (updatedText != _user.address && mounted) {
      setState(() {
        _user.address = updatedText;
        _stateChanged();
      });
    }
  }*/

  Future<void> _saveChanges() async {
    // prepare to save
    _user.isCreate = 0; // update
    if (_image != null) {
      _user.avatarImgDTO = null; // request to delete avatar
    }

    // Save user
    _showWaiting();
    if (_image != null) {
      // resize if image is so big
      _image = (await Utils.resizeAvatar(_image))!;
    }
    Future.delayed(Duration(milliseconds: 500), () async {
      HttpUtil.postUser(
        ApiUrls.instance().getUsersUrl(),
        user: _user,
        avatar: _image == null ? null : FileHolder(file: _image),
        onDone: (resp) async {
          _popLoading();
          if (resp == null || resp.statusCode != 200) {
            dynamic json = resp == null || Utils.isNullOrEmpty(resp.body)
                ? null
                : jsonDecode(utf8.decode(resp.bodyBytes));
            String error = json == null ? '' : json['message'];
            Utils.alert(
              context,
              title: Utils.getLocale(context)?.failed,
              message:
                  '${Utils.getLocale(context)?.errorOccurred} ${resp?.statusCode}\n$error',
            );
            return;
          }

          dynamic json = jsonDecode(utf8.decode(resp.bodyBytes));
          User? updatedUser = json == null ? null : User.fromJson(json);
          if (updatedUser != null) {
            SessionUtil.instance().user = updatedUser;
            HttpUtil.get(
              ApiUrls.instance().getUserInfoUrl(),
              headers: {'Content-Type': 'application/json'},
              onResponse: (resp) {
                if (resp != null && resp.statusCode == 200) {
                  dynamic json = jsonDecode(utf8.decode(resp.bodyBytes));
                  User? user = json == null ? null : User.fromJson(json);
                  if (user == null) return;
                  if (user.avatarImgDTO != null &&
                      !Utils.isNullOrEmpty(user.avatarImgDTO!.flePath!)) {
                    user.avatarImgDTO!.flePath +=
                        '?t=${DateTime.now().millisecondsSinceEpoch}';
                  }
                  SessionUtil.instance().user = user;
                  AppProvider.of(context)
                      ?.state
                      ?.userBloc
                      ?.setCurrentUser(SessionUtil.instance().user);
                }
              },
            );
          }

          Utils.alert(
            context,
            title: Utils.getLocale(context)?.success,
            message: '${Utils.getLocale(context)?.updateProfileSuccessMessage}',
          );
        },
        onTimeout: () {
          _popLoading();
        },
      );
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
