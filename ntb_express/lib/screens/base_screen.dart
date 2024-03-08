import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ntbexpress/screens/register_screen.dart';
import 'package:ntbexpress/util/contants.dart';
import 'package:ntbexpress/util/utils.dart';

class BaseScreen extends StatefulWidget {
  @override
  _BaseScreenState createState() => _BaseScreenState();
}

class _BaseScreenState extends State<BaseScreen> {
  final List<String> _imageUrlList = [
    'https://i.pinimg.com/originals/5c/cd/75/5ccd7544f3908ca293f66e9b186015df.jpg',
    'https://i.pinimg.com/originals/10/c0/1b/10c01b0688a3551a61360615d54a7e74.jpg',
    'https://bestwallpapers.net/wp-content/uploads/2020/02/Top-Nature-Wallpapers-For-Phone-Free-Download.jpg'
  ];
  String _backgroundUrl = '';
  Timer _timer;

  @override
  void initState() {
    super.initState();
    _backgroundUrl = _imageUrlList[new Random().nextInt(2)];

    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        setState(() {
          _backgroundUrl = _imageUrlList[new Random().nextInt(2)];
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedContainer(
        constraints: BoxConstraints.expand(),
        duration: Duration(milliseconds: 0),
        curve: Curves.bounceInOut,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(_backgroundUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RaisedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed(AppRouter.login);
                },
                disabledColor: Colors.black12,
                disabledTextColor: Colors.white70,
                color: Utils.accentColor,
                textColor: Colors.white,
                child: Text(
                  Utils.getLocale(context).login,
                  style: TextStyle(
                    fontSize: 20.0,
                  ),
                ),
              ),
              RaisedButton(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => RegisterScreen()));
                },
                disabledColor: Colors.black12,
                disabledTextColor: Colors.white70,
                color: Utils.accentColor,
                textColor: Colors.white,
                child: Text(
                  Utils.getLocale(context).register,
                  style: TextStyle(
                    fontSize: 20.0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
