import 'package:flutter/material.dart';
import 'package:ntbexpress/util/extensions.dart';
import 'package:ntbexpress/util/session_util.dart';
import 'package:ntbexpress/util/utils.dart';

class CurrencySwapInput extends StatefulWidget {
  final String? title;
  final TextEditingController ?controller;
  final String? firstLabelText;
  final String? secondLabelText;
  final String? firstHintText;
  final String? secondHintText;
  final String? firstSymbol;
  final String? secondSymbol;
  final FormFieldValidator<String>? firstValidator;
  final FormFieldValidator<String>? secondValidator;

  CurrencySwapInput(
      {this.title,
      this.controller,
      this.firstLabelText,
      this.secondLabelText,
      this.firstHintText,
      this.secondHintText,
      this.firstValidator,
      this.secondValidator,
      this.firstSymbol,
      this.secondSymbol});

  @override
  _CurrencySwapInputState createState() => _CurrencySwapInputState();
}

class _CurrencySwapInputState extends State<CurrencySwapInput> {
  final _secondController = TextEditingController();
  final _firstFocusNode = FocusNode();
  final _secondFocusNode = FocusNode();

  double get _exchangeRate => SessionUtil.instance().exchangeRate;

  @override
  void initState() {
    widget.controller?.addListener(_firstListener);
    _secondController.addListener(_secondListener);
    if (!Utils.isNullOrEmpty(widget.controller!.text) &&
        Utils.isNullOrEmpty(_secondController.text)) {
      _firstListener();
    }

    super.initState();
  }

  @override
  void dispose() {
    widget.controller?.removeListener(_firstListener);
    _secondController.removeListener(_secondListener);

    _secondController.dispose();

    _firstFocusNode.dispose();
    _secondFocusNode.dispose();
    super.dispose();
  }

  void _firstListener() {
    if (_firstFocusNode.hasFocus ||
        (!_firstFocusNode.hasFocus && !_secondFocusNode.hasFocus)) {
      if (Utils.isNullOrEmpty(widget.controller!.text)) {
        _secondController.text = '';
        return;
      }

      double vnd = widget.controller!.text?.trim()?.parseDouble() ?? 0;
      if (vnd == 0) {
        _secondController.text = '0';
        return;
      }

      double cny = vnd / _exchangeRate;
      cny = double.parse(cny.toStringAsFixed(2));
      _secondController.text =
          '${cny.isInt ? cny.toString().substring(0, cny.toString().indexOf('.')) : cny.toString()}';
    }
  }

  void _secondListener() {
    if (_secondFocusNode.hasFocus) {
      if (Utils.isNullOrEmpty(_secondController.text)) {
        widget.controller!.text = '';
        return;
      }

      double cny = _secondController.text?.trim()?.parseDouble() ?? 0;
      if (cny == 0) {
        widget.controller!.text = '0';
        return;
      }

      double vnd = cny * _exchangeRate;
      vnd = double.parse(vnd.toStringAsFixed(2));
      widget.controller!.text =
          '${vnd.isInt ? vnd.toString().substring(0, vnd.toString().indexOf('.')) : vnd.toString()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('${widget.title}'),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: widget.controller,
                  focusNode: _firstFocusNode,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                      labelText: '${widget.firstLabelText}',
                      hintText: '${widget.firstHintText}',
                      counterText: ''),
                  maxLines: 1,
                  validator: widget.firstValidator,
                ),
              ),
              const SizedBox(width: 10.0),
              Text(
                widget.firstSymbol ?? '(đ)',
                style: TextStyle(
                  color: Theme.of(context).disabledColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15.0),
                child: Icon(
                  Icons.swap_horiz,
                  color: Theme.of(context).disabledColor,
                ),
              ),
              Text(
                widget.secondSymbol ?? '(¥)',
                style: TextStyle(
                  color: Theme.of(context).disabledColor,
                ),
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: TextFormField(
                  controller: _secondController,
                  focusNode: _secondFocusNode,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                      labelText: '${widget.secondLabelText}',
                      hintText: '${widget.secondHintText}',
                      counterText: ''),
                  maxLines: 1,
                  validator: widget.secondValidator,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ChineseCurrencyInput extends StatefulWidget {
  final TextEditingController? controller;
  final String? labelText;
  final String? hintText;
  final FormFieldValidator<String>? validator;
  final bool? enabled;
  final TextStyle? style;

  ChineseCurrencyInput(
      {this.controller, this.labelText, this.hintText, this.validator, this.enabled = true, this.style});

  @override
  _ChineseCurrencyInputState createState() => _ChineseCurrencyInputState();
}

class _ChineseCurrencyInputState extends State<ChineseCurrencyInput> {
  final _secondController = TextEditingController();
  final _secondFocusNode = FocusNode();

  double get _exchangeRate => SessionUtil.instance().exchangeRate;

  @override
  void initState() {
    _secondController.addListener(_secondListener);
    if (!Utils.isNullOrEmpty(widget.controller!.text) &&
        Utils.isNullOrEmpty(_secondController.text)) {
      _firstListener();
    }

    super.initState();
  }

  @override
  void dispose() {
    _secondController.removeListener(_secondListener);

    _secondController.dispose();

    _secondFocusNode.dispose();
    super.dispose();
  }

  void _firstListener() {
    if (Utils.isNullOrEmpty(widget.controller!.text)) {
      _secondController.text = '';
      return;
    }

    double vnd = widget.controller!.text?.trim()?.parseDouble() ?? 0;
    if (vnd == 0) {
      _secondController.text = '0';
      return;
    }

    double cny = vnd / _exchangeRate;
    cny = double.parse(cny.toStringAsFixed(2));
    _secondController.text =
        '${cny.isInt ? cny.toString().substring(0, cny.toString().indexOf('.')) : cny.toString()}';
  }

  void _secondListener() {
    if (_secondFocusNode.hasFocus) {
      if (Utils.isNullOrEmpty(_secondController.text)) {
        widget.controller!.text = '';
        return;
      }

      double cny = _secondController.text?.trim()?.parseDouble() ?? 0;
      if (cny == 0) {
        widget.controller!.text = '0';
        return;
      }

      double vnd = cny * _exchangeRate;
      vnd = double.parse(vnd.toStringAsFixed(2));
      widget.controller!.text =
          '${vnd.isInt ? vnd.toString().substring(0, vnd.toString().indexOf('.')) : vnd.toString()}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      style: widget.style,
      enabled: widget.enabled,
      controller: _secondController,
      focusNode: _secondFocusNode,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.done,
      decoration: InputDecoration(
          labelText: '${widget.labelText}',
          hintText: '${widget.hintText}',
          counterText: ''),
      maxLines: 1,
      validator: widget.validator,
    );
  }
}
