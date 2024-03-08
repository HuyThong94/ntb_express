import 'package:flutter/material.dart';
import 'package:rxdart/rxdart.dart';

class LocaleBloc {
  Locale initialLocale = const Locale('en');
  BehaviorSubject<Locale> _localeSubject;

  LocaleBloc({this.initialLocale}) {
    _localeSubject = BehaviorSubject<Locale>.seeded(this.initialLocale);
  }

  Stream<Locale> get locale$ => _localeSubject.stream;

  void setLocale(Locale locale) {
    initialLocale = locale;
    _localeSubject.sink.add(locale);
  }

  Locale get currentLocale => initialLocale;

  void dispose() {
    _localeSubject?.close();
  }
}