import 'package:flutter/material.dart';
import 'package:ntbexpress/model/order_track.dart';
import 'package:ntbexpress/util/utils.dart';
import 'package:timeline_tile/timeline_tile.dart';

class OrderTrackingTimeline extends StatelessWidget {
  final List<OrderTrack?>? tracks;
  final double indicatorLineWidth;
  final double indicatorPadding;
  final double indicatorWidth;

  OrderTrackingTimeline(
      {this.tracks,
      this.indicatorLineWidth = 1.0,
      this.indicatorPadding = 10.0,
      this.indicatorWidth = 10.0});

  List<Widget> _buildItems(BuildContext context) {
    List<Widget> list = [];
    tracks!.forEach((track) {
      if (track != null) {
        bool isFirst = track.trackId == tracks?.first?.trackId;
        bool isLast = track.trackId == tracks?.last?.trackId;
        list.add(TimelineTile(
          isFirst: isFirst,
          isLast: isLast,
          afterLineStyle: LineStyle(
            // width: indicatorLineWidth,
            color: Colors.black12,
          ),
          indicatorStyle: IndicatorStyle(
            width: indicatorWidth,
            drawGap: true,
            color: isFirst ? Colors.green : Colors.black12,
            padding: EdgeInsets.only(left: indicatorPadding),
          ),
          startChild: Container(
            margin: EdgeInsets.only(left: indicatorPadding),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(
                bottom: isLast
                    ? BorderSide.none
                    : BorderSide(
                        width: 1.0,
                        color: Colors.black12,
                      ),
              ),
            ),
            constraints: BoxConstraints(minHeight: 40.0),
            child: Padding(
              padding: EdgeInsets.only(left: indicatorPadding),
              child: Align(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${Utils.getTrackingStatusString(context, track.actionType!)}',
                      style: TextStyle(
                        fontSize: 12.0,
                        color: isFirst ? Colors.green : Colors.black45,
                      ),
                    ),
                    Visibility(
                      visible: !Utils.isNullOrEmpty(track.note!),
                      child: SizedBox(
                        height: 2.0,
                      ),
                    ),
                    Visibility(
                      visible: !Utils.isNullOrEmpty(track.note!),
                      child: Text(
                        '${Utils.getLocale(context)?.note}: ${track.note}',
                        style: TextStyle(
                          fontSize: 10.0,
                          color: Theme.of(context).disabledColor,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 2.0,
                    ),
                    track.actionDate == null
                        ? SizedBox()
                        : Text(
                            '${Utils.getDateString(track.actionDate!, 'dd-MM-yyyy HH:mm')}',
                            style: TextStyle(
                                fontSize: 10.0, color: Colors.black45),
                          )
                  ],
                ),
                alignment: Alignment.centerLeft,
              ),
            ),
          ),
        ));
      }
    });

    return list;
  }

  @override
  Widget build(BuildContext context) {
    return tracks == null || tracks!.isEmpty
        ? SizedBox()
        : Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _buildItems(context),
            ),
          );
  }
}
