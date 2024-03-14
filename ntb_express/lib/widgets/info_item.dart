import 'package:flutter/material.dart';
import 'package:ntbexpress/util/utils.dart';

class InfoItem extends StatelessWidget {
  final String? firstText;
  final String? secondText;
  final bool alignTop;
  final bool breakLine;
  final VoidCallback? onTap;
  final bool useWidget;
  final Widget? firstChild;
  final Widget? secondChild;
  final Widget? bottomChild;

  InfoItem(
      {this.firstText,
      this.secondText,
      this.alignTop = false,
      this.breakLine = false,
      this.onTap,
      this.useWidget = false,
      this.firstChild,
      this.secondChild,
      this.bottomChild});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2.0),
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 10.0, horizontal: 5.0),
              child: Row(
                crossAxisAlignment: alignTop!
                    ? CrossAxisAlignment.start
                    : CrossAxisAlignment.center,
                children: [
                  useWidget ? firstChild : Text(firstText ?? ''),
                  breakLine
                      ? const SizedBox()
                      : Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              useWidget ? secondChild : Text(secondText ?? ''),
                            ],
                          ),
                        ),
                  this.onTap == null
                      ? const SizedBox(width: 5.0)
                      : breakLine
                          ? Expanded(
                              child: Align(
                                  alignment: Alignment.topRight,
                                  child: Icon(
                                    Icons.chevron_right,
                                    color: Theme.of(context).disabledColor,
                                  )))
                          : Icon(
                              Icons.chevron_right,
                              color: Theme.of(context).disabledColor,
                            ),
                ],
              ),
            ),
            breakLine! && !Utils.isNullOrEmpty(secondText!)
                ? Padding(
                    padding: const EdgeInsets.only(
                        left: 5.0, right: 5.0, bottom: 5.0),
                    child: Text(secondText ?? ''),
                  )
                : const SizedBox(),
            bottomChild ?? const SizedBox(),
            const SizedBox(height: 2.0),
          ],
        ),
      ),
    );
  }
}
