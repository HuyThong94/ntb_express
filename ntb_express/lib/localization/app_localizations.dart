import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ntbexpress/localization/message.dart';
import 'package:ntbexpress/localization/message_en.dart';
import 'package:ntbexpress/localization/message_vi.dart';
import 'package:ntbexpress/localization/message_zh.dart';

class NTBExpressLocalizations {
  final Locale locale;

  NTBExpressLocalizations(this.locale);

  static Map<String, Message> _localizedValues = {
    'vi': MessageVi(),
    'en': MessageEn(),
    'zh': MessageZh(),
  };

  Message get currentLocalized => _localizedValues[locale.languageCode];

  static NTBExpressLocalizations of(BuildContext context) {
    return Localizations.of(context, NTBExpressLocalizations);
  }

  static const LocalizationsDelegate<NTBExpressLocalizations> delegate =
      _NTBExpressLocalizationsDelegate();
}

class _NTBExpressLocalizationsDelegate
    extends LocalizationsDelegate<NTBExpressLocalizations> {
  const _NTBExpressLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['vi', 'en', 'zh'].contains(locale.languageCode);
  }

  @override
  Future<NTBExpressLocalizations> load(Locale locale) {
    return SynchronousFuture<NTBExpressLocalizations>(
        NTBExpressLocalizations(locale));
  }

  @override
  bool shouldReload(LocalizationsDelegate<NTBExpressLocalizations> old) {
    return false;
  }
}
