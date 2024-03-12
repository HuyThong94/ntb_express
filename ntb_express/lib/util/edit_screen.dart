import 'package:flutter/material.dart';
import 'package:ntbexpress/util/utils.dart';

typedef bool ValidationCallback(String value);

class EditScreen extends StatefulWidget {
  final String? currentValue;
  final String title;
  final String hintText;
  final int length;
  final ValidationCallback? onValidate;

  EditScreen(
      {this.currentValue,
      required this.title,
      required this.hintText,
      required this.length,
      this.onValidate});

  @override
  _EditScreenState createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  final _txtController = TextEditingController();
  String _currentValue = '';
  bool _isDataChanged = false;

  @override
  void initState() {
    super.initState();
    _currentValue = widget.currentValue ?? '';
    _txtController.text = widget.currentValue ?? '';
    _txtController.addListener(() {
      if (_txtController.text != _currentValue) {
        if (!_isDataChanged && mounted) {
          setState(() => _isDataChanged = true);
        }
      } else {
        if (_isDataChanged && mounted) {
          setState(() => _isDataChanged = false);
        }
      }
    });
  }

  @override
  void dispose() {
    _txtController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).requestFocus(FocusNode()),
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            onPressed: () {
              if (_txtController.text == _currentValue) {
                Navigator.of(context).pop(_currentValue);
                return;
              }

              Utils.confirm(
                context,
                title: '${Utils.getLocale(context).saveChanges}',
                message: Utils.getLocale(context).saveChangesMessage,
                onAccept: () {
                  if (widget.onValidate != null) {
                    if (widget.onValidate!(_txtController.text)) {
                      Navigator.of(context).pop(_txtController.text);
                    }
                  } else {
                    Navigator.of(context).pop(_txtController.text);
                  }
                },
                onDecline: () {
                  Navigator.of(context).pop(null);
                },
              );
            },
            icon: Icon(Icons.arrow_back),
          ),
          actions: [
            IconButton(
              onPressed: !_isDataChanged ? null : () {
                if (widget.onValidate != null) {
                  if (widget.onValidate!(_txtController.text)) {
                    Navigator.of(context).pop(_txtController.text);
                  }
                } else {
                  Navigator.of(context).pop(_txtController.text);
                }
              },
              icon: Icon(Icons.done),
            )
          ],
          title: Text(widget.title ?? ''),
        ),
        body: Container(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _txtController,
                maxLength: widget.length ?? 100,
                maxLines: 1,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 5.0,
                    horizontal: 10.0,
                  ),
                  hintText: widget.hintText ?? '...',
                  counterText: '',
                ),
              ),
              SizedBox(
                height: 10.0,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 8.0),
                child: Text('${widget.length ?? 100} ${Utils.getLocale(context).charactersOnly}'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
