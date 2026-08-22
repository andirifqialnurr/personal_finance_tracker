import 'package:flutter/material.dart';

import '../utils/flow_format.dart';

class FlowBudgetProgressValue extends StatelessWidget {
  const FlowBudgetProgressValue({
    super.key,
    required this.spent,
    required this.limit,
    required this.currency,
    this.textAlign = TextAlign.start,
  });

  final int spent;
  final int limit;
  final String currency;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    final percent = limit == 0 ? 0.0 : spent / limit * 100;
    final style = Theme.of(context).textTheme.bodySmall?.copyWith(
      fontSize: 11,
      height: 1.15,
    );
    return RichText(
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: textAlign,
      text: TextSpan(
        style: style,
        children: [
          TextSpan(
            text:
                '${formatCurrency(spent, currency)} of ${formatCurrency(limit, currency)} ',
          ),
          TextSpan(
            text: '(${percent.toStringAsFixed(1)}%)',
            style: style?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
