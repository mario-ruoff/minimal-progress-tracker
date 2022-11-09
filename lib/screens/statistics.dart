import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

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
  final double maxX = 11;
  final double maxY = 6;
  final int minDays = 7;
  final int minValueScale = 5;

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
                        color: Color(0xff232d37),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          right: 18,
                          left: 12,
                          top: 38,
                          bottom: 12,
                        ),
                        child:
                            LineChart(mainData(widget.valueHistories[index])),
                      ),
                    ),
                  ),
                  Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Text(
                        widget.names[index],
                        style: const TextStyle(
                          fontSize: 18,
                        ),
                      )),
                ],
              ));
        });
  }

  LineChartData mainData(Map<DateTime, int> valueHistory) {
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
      maxX: maxX,
      minY: 0,
      maxY: maxY,
      lineBarsData: [
        LineChartBarData(
          spots: getHistorySpots(valueHistory),
          isCurved: false,
          gradient: LinearGradient(
            colors: gradientColors,
          ),
          barWidth: 5,
          isStrokeCapRound: true,
          isStrokeJoinRound: true,
          isStepLineChart: true,
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
    );
  }

  List<FlSpot> getHistorySpots(Map<DateTime, int> valueHistory) {
    List<FlSpot> spots = [];
    DateTime firstDay = valueHistory.keys.first;
    int daySpan = widget.currentDate.difference(firstDay).inDays;
    // If too few days, expand day span
    if (daySpan < minDays) {
      firstDay = widget.currentDate.subtract(Duration(days: minDays));
      daySpan = minDays;
    }
    int maxHistoryValue = getMaxValue(valueHistory);
    // If max value too small, expand max value
    if (maxHistoryValue < minValueScale) {
      maxHistoryValue = minValueScale;
    }
    // Add all values from the history
    valueHistory.forEach((key, value) {
      int daysToFirst = key.difference(firstDay).inDays;
      double xValue = daysToFirst / daySpan * maxX;
      double yValue = value / maxHistoryValue * maxY;
      spots.add(FlSpot(xValue, yValue));
      // Save previous value
      // previousYValue = yValue;
    });
    return spots;
  }

  int getMaxValue(Map<DateTime, int> valueHistory) {
    int maxValue = 0;
    valueHistory.forEach((key, value) {
      if (value > maxValue) {
        maxValue = value;
      }
    });
    return maxValue;
  }

  Widget bottomTitleWidgets(double value, TitleMeta meta) {
    const style = TextStyle(
      color: Color(0xff68737d),
      fontWeight: FontWeight.bold,
      fontSize: 16,
    );
    Widget text;
    switch (value.toInt()) {
      case 2:
        text = const Text('MAR', style: style);
        break;
      case 5:
        text = const Text('JUN', style: style);
        break;
      case 8:
        text = const Text('SEP', style: style);
        break;
      default:
        text = const Text('', style: style);
        break;
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
    switch (value.toInt()) {
      case 1:
        text = '10';
        break;
      case 3:
        text = '30';
        break;
      case 5:
        text = '50';
        break;
      default:
        return Container();
    }

    return Text(text, style: style, textAlign: TextAlign.left);
  }
}
