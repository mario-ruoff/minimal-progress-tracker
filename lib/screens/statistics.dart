import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'dart:io';

class Statistics extends StatefulWidget {
  const Statistics(
      {super.key,
      required this.names,
      required this.valueHistories,
      required this.currentDate});

  final List<String> names;
  final List<Map<DateTime, int>> valueHistories;
  final DateTime currentDate;

  @override
  State<Statistics> createState() => _StatisticsState();
}

class _StatisticsState extends State<Statistics> {
  List<Color> gradientColors = [
    const Color(0xff23b6e6),
    const Color(0xff02d39a),
  ];
  final int minDays = 7;
  final int minValueScale = 10;
  final String locale = Platform.localeName;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting(locale);
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
        padding: const EdgeInsets.only(top: 10),
        itemCount: widget.valueHistories.length,
        itemBuilder: (context, index) {
          return Container(
              margin: const EdgeInsets.all(5),
              child: Stack(
                children: <Widget>[
                  AspectRatio(
                    aspectRatio: 2.0,
                    child: DecoratedBox(
                      decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(
                            Radius.circular(12),
                          ),
                          color: Color(0xff232d37)),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          right: 18,
                          left: 12,
                          top: 44,
                          bottom: 12,
                        ),
                        child:
                            LineChart(mainData(widget.valueHistories[index])),
                      ),
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                      child: Text(
                        widget.names[index],
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[400],
                        ),
                      )),
                ],
              ));
        });
  }

  LineChartData mainData(Map<DateTime, int> valueHistory) {
    int maxHistoryValue = getMaxValue(valueHistory);
    DateTime firstDay = valueHistory.keys.first;
    int daySpan = widget.currentDate.difference(firstDay).inDays;

    // If too few days, expand day span
    if (daySpan < minDays) {
      firstDay = widget.currentDate.subtract(Duration(days: minDays));
      daySpan = minDays;
    }
    // Add 1 day to dayspan to display last day
    daySpan += 1;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 1,
        verticalInterval: 1,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: const Color(0xff37434d),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: bottomTitleWidgets,
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            interval: 1,
            getTitlesWidget: leftTitleWidgets,
            reservedSize: 42,
          ),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(color: const Color(0xff37434d)),
      ),
      minX: 0,
      maxX: daySpan.toDouble(),
      minY: 0,
      maxY: maxHistoryValue.toDouble(),
      lineBarsData: [
        LineChartBarData(
          spots:
              getHistorySpots(valueHistory, firstDay, daySpan, maxHistoryValue),
          isCurved: false,
          gradient: LinearGradient(
            colors: gradientColors,
          ),
          barWidth: 5,
          isStrokeCapRound: true,
          isStrokeJoinRound: true,
          isStepLineChart: true,
          lineChartStepData: LineChartStepData(
              stepDirection: LineChartStepData.stepDirectionForward),
          dotData: FlDotData(
            show: false,
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: gradientColors
                  .map((color) => color.withOpacity(0.3))
                  .toList(),
            ),
          ),
        ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) => touchedSpots
              .map((touchedSpot) => LineTooltipItem(
                  touchedSpot.y.round().toString(),
                  const TextStyle(
                    fontWeight: FontWeight.bold,
                  )))
              .toList(),
        ),
      ),
    );
  }

  List<FlSpot> getHistorySpots(Map<DateTime, int> valueHistory,
      DateTime firstDay, int daySpan, int maxHistoryValue) {
    List<FlSpot> spots = [];
    int? previousYValue;

    // Add all values from the history
    valueHistory.forEach((key, value) {
      int daysToFirst = key.difference(firstDay).inDays;
      spots.add(FlSpot(daysToFirst.toDouble(), value.toDouble()));
      // Save previous value
      previousYValue = value;
    });
    // Add last horizontal value line to current date
    if (previousYValue != null) {
      spots.add(FlSpot(daySpan.toDouble(), previousYValue!.toDouble()));
    }
    return spots;
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff68737d),
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
    Widget text;
    int intValue = value.toInt();
    DateTime valueDate = widget.currentDate
        .subtract(Duration(days: meta.max.toInt() - intValue - 1));

    if (intValue == (meta.max / 3 - meta.max / 6).round() ||
        intValue == (meta.max / 3 * 2 - meta.max / 6).round() ||
        intValue == (meta.max - meta.max / 6).round()) {
      if (meta.max < 500) {
        text = Text(DateFormat.Md(locale).format(valueDate), style: style);
      } else {
        text = Text(DateFormat.yM(locale).format(valueDate), style: style);
      }
    } else {
      return Container();
    }

    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: text,
    );
  }

  Widget leftTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff67727d),
      fontWeight: FontWeight.bold,
      fontSize: 15,
    );
    String text;
    int intValue = value.toInt();

    if (intValue == (meta.max / 3 - meta.max / 6).toInt() ||
        intValue == (meta.max / 3 * 2 - meta.max / 6).toInt() ||
        intValue == (meta.max - meta.max / 6).toInt()) {
      text = intValue.toString();
    } else {
      return Container();
    }

    return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: Text(text, style: style, textAlign: TextAlign.right));
  }

  int getMaxValue(Map<DateTime, int> valueHistory) {
    int maxValue = 0;
    valueHistory.forEach((key, value) {
      if (value > maxValue) {
        maxValue = value;
      }
    });
    // If max value too small, expand max value
    if (maxValue < minValueScale) {
      maxValue = minValueScale;
    }
    return maxValue;
  }
}
