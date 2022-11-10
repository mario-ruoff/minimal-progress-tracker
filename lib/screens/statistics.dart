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
          lineChartStepData: LineChartStepData(
              stepDirection: LineChartStepData.stepDirectionForward),
          dotData: FlDotData(
            show: true,
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
                  getRealValueFromGraph(touchedSpot.y, valueHistory).toString(),
                  const TextStyle(
                    fontWeight: FontWeight.bold,
                  )))
              .toList(),
        ),
      ),
    );
  }

  List<FlSpot> getHistorySpots(Map<DateTime, int> valueHistory) {
    List<FlSpot> spots = [];
    DateTime firstDay = valueHistory.keys.first;
    int daySpan = widget.currentDate.difference(firstDay).inDays;
    double? previousYValue;

    // If too few days, expand day span
    if (daySpan < minDays) {
      firstDay = widget.currentDate.subtract(Duration(days: minDays));
      daySpan = minDays;
    }
    int maxHistoryValue = getMaxValue(valueHistory);

    // Add all values from the history
    valueHistory.forEach((key, value) {
      int daysToFirst = key.difference(firstDay).inDays;
      // Add 1 to dayspan to fit last value in diagram
      double xValue = daysToFirst / (daySpan + 1) * maxX;
      double yValue = value / maxHistoryValue * maxY;
      spots.add(FlSpot(xValue, yValue));
      // Save previous value
      previousYValue = yValue;
    });
    // Add last horizontal value line to current date
    if (previousYValue != null) spots.add(FlSpot(maxX, previousYValue!));
    return spots;
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
        text = value.round().toString();
        break;
      case 3:
        text = value.round().toString();
        break;
      case 5:
        text = value.round().toString();
        break;
      default:
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

  int getRealValueFromGraph(
      double graphValue, Map<DateTime, int> valueHistory) {
    int maxHistoryValue = getMaxValue(valueHistory);
    return (graphValue / maxY * maxHistoryValue).round();
  }
}
