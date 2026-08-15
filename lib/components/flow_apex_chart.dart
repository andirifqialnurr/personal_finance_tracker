import 'package:apexcharts_flutter/apexcharts_flutter.dart';
import 'package:flutter/material.dart';

class FlowApexChart extends StatelessWidget {
  const FlowApexChart({
    super.key,
    required this.options,
    this.height = 220,
    this.enableTooltip = true,
  });

  final Map<String, dynamic> options;
  final double height;
  final bool enableTooltip;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      width: double.infinity,
      child: ClipRect(
        child: RepaintBoundary(
          child: ApexChart.fromJson(
            options,
            enableTooltip: enableTooltip,
          ),
        ),
      ),
    );
  }
}

String flowChartColorHex(Color color) {
  final value = color.toARGB32() & 0xFFFFFF;
  return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
}
