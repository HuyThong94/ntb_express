import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/http_util.dart';
import 'package:ntbexpress/util/session_util.dart';
import 'package:ntbexpress/util/utils.dart';
import 'package:ntbexpress/widgets/app_provider.dart';
import 'package:settings_ui/settings_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingScreen extends StatefulWidget {
  @override
  _SettingScreenState createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  bool _initialized = false;
  String _locale = 'vi';

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      _getPreferencesData();
      _initialized = true;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${Utils.getLocale(context)?.setting}'),
      ),
      body: Container(
        color: Utils.backgroundColor,
        child: SettingsList(
          sections: [
            SettingsSection(
              title: Text('${Utils.getLocale(context)?.common}'),
              tiles: [
                SettingsTile(
                  onTap: _changeLanguage,
                  title: Text('${Utils.getLocale(context)?.language}'),
                  subtitle: _locale == 'vi'
                      ? Utils.getLocale(context)?.vietnamese
                      : _locale == 'en'
                          ? Utils.getLocale(context)?.english
                          : Utils.getLocale(context)?.chinese,
                  leading: Icon(Icons.language),
                ),
                SettingsTile(
                  onTap: () async {
                    AppSettings.openAppSettings();
                  },
                  title: Text('${Utils.getLocale(context)?.notification}'),
                  leading: Icon(Icons.notifications),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getPreferencesData() async {
    _locale =
        AppProvider.of(context)?.state.localeBloc.currentLocale.languageCode ??
            'vi';
    setState(() {});
  }

  void _localeChanged(String code) {
    setState(() {
      _locale = code;
      AppProvider.of(context)?.state.localeBloc.setLocale(Locale(code));
      SharedPreferences.getInstance()
          .then((prefs) => prefs.setString(PrefsKey.languageCode, _locale));
    });
    HttpUtil.updateLocale(SessionUtil.instance().deviceId, code);
  }

  Future<void> _changeLanguage() async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.language),
            SizedBox(width: 10.0),
            Text('${Utils.getLocale(context)?.language}'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                onTap: () {
                  _localeChanged('vi');
                  Navigator.of(context).pop();
                },
                title: Text('${Utils.getLocale(context)?.vietnamese}'),
                trailing: _locale != 'vi'
                    ? null
                    : Icon(Icons.done, color: Utils.accentColor),
              ),
              ListTile(
                onTap: () {
                  _localeChanged('en');
                  Navigator.of(context).pop();
                },
                title: Text('${Utils.getLocale(context)?.english}'),
                trailing: _locale != 'en'
                    ? null
                    : Icon(Icons.done, color: Utils.accentColor),
              ),
              ListTile(
                onTap: () {
                  _localeChanged('zh');
                  Navigator.of(context).pop();
                },
                title: Text('${Utils.getLocale(context)?.chinese}'),
                trailing: _locale != 'zh'
                    ? null
                    : Icon(Icons.done, color: Utils.accentColor),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
