import 'package:flutter/material.dart';

import '../utils/constants.dart';
import '../utils/formatters.dart';

/// Bandeau de synthèse : valeur immobilisée, CA potentiel, bénéfice.
class SummaryCard extends StatelessWidget {
  const SummaryCard({
    super.key,
    required this.label,
    required this.references,
    required this.items,
    required this.purchaseValue,
    required this.saleValue,
    this.onTap,
  });

  final String label;
  final int references;
  final int items;
  final double purchaseValue;
  final double saleValue;
  final VoidCallback? onTap;

  double get profit => saleValue - purchaseValue;
  double get marginRate =>
      purchaseValue <= 0 ? 0 : (profit / purchaseValue) * 100;

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF16181D);
    final onInk = Colors.white.withOpacity(0.62);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kRadius),
        child: Ink(
          decoration: BoxDecoration(
            color: ink,
            borderRadius: BorderRadius.circular(kRadius),
          ),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    label.toUpperCase(),
                    style: TextStyle(
                      color: onInk,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '$references réf. · $items paires',
                    style: TextStyle(color: onInk, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                Fmt.money(purchaseValue),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1.2,
                  height: 1.1,
                ),
              ),
              Text(
                'Valeur d\'achat immobilisée',
                style: TextStyle(color: onInk, fontSize: 13),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _Stat(
                      title: 'Vente potentielle',
                      value: Fmt.money(saleValue),
                      color: Colors.white,
                      subColor: onInk,
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 38,
                    color: Colors.white.withOpacity(0.12),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _Stat(
                      title: 'Bénéfice · ${Fmt.percent(marginRate)}',
                      value: Fmt.money(profit),
                      color: profit >= 0
                          ? const Color(0xFF4ADE80)
                          : const Color(0xFFFF6B6B),
                      subColor: onInk,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.title,
    required this.value,
    required this.color,
    required this.subColor,
  });

  final String title;
  final String value;
  final Color color;
  final Color subColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: subColor, fontSize: 12),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
        ),
      ],
    );
  }
}
