import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../data/local/tables.dart';

class AmountText extends StatelessWidget {
  final double amount;
  final String type;
  final TextStyle? style;
  final bool withSign;

  const AmountText({
    super.key,
    required this.amount,
    required this.type,
    this.style,
    this.withSign = true,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = type == TxType.income;
    final color = isIncome ? AppColors.income : AppColors.expense;
    final sign = withSign ? (isIncome ? '+ ' : '- ') : '';
    return Text(
      '$sign${Formatters.money(amount)}',
      style: (style ?? const TextStyle(fontSize: 16, fontWeight: FontWeight.w600))
          .copyWith(color: color),
    );
  }
}
