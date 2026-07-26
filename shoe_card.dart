import 'package:flutter/material.dart';

import '../models/shoe.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import 'shoe_photo.dart';

/// Ligne de stock : photo, identité du modèle, prix et quantité restante.
class ShoeCard extends StatelessWidget {
  const ShoeCard({super.key, required this.shoe, required this.onTap});

  final Shoe shoe;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dotColor = colorFromName(shoe.color);

    return Semantics(
      button: true,
      label: '${shoe.title}, pointure ${Fmt.size(shoe.size)}, '
          '${shoe.quantity} en stock',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(kRadius),
          child: Ink(
            decoration: AppTheme.cardDecoration(context),
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(
                  opacity: shoe.isOutOfStock ? 0.45 : 1,
                  child: ShoePhoto(
                    fileName: shoe.photo,
                    width: 88,
                    height: 88,
                    radius: 14,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              shoe.brand.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          QuantityPill(quantity: shoe.quantity),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        shoe.model,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          _MetaChip(
                            label: shoe.color,
                            leading: dotColor == null
                                ? null
                                : Container(
                                    width: 10,
                                    height: 10,
                                    decoration: BoxDecoration(
                                      color: dotColor,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: scheme.outlineVariant,
                                      ),
                                    ),
                                  ),
                          ),
                          _MetaChip(label: 'P. ${Fmt.size(shoe.size)}'),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Text(
                            Fmt.money(shoe.purchasePrice),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Icon(Icons.arrow_right_alt_rounded,
                              size: 16, color: scheme.onSurfaceVariant),
                          Text(
                            Fmt.money(shoe.salePrice),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            Fmt.money(shoe.potentialProfit),
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: shoe.potentialProfit >= 0
                                  ? StockColors.profit
                                  : StockColors.out,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Badge « quantité restante », coloré selon le niveau de stock.
class QuantityPill extends StatelessWidget {
  const QuantityPill({super.key, required this.quantity, this.large = false});

  final int quantity;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    late final Color color;
    late final String label;

    if (quantity <= 0) {
      color = StockColors.out;
      label = 'Rupture';
    } else if (quantity <= kLowStockThreshold) {
      color = StockColors.low;
      label = '$quantity restant${quantity > 1 ? 's' : ''}';
    } else {
      color = StockColors.ok;
      label = '$quantity en stock';
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 8 : 5,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: scheme.brightness == Brightness.dark
                  ? Color.lerp(color, Colors.white, 0.35)
                  : color,
              fontWeight: FontWeight.w700,
              fontSize: large ? 14 : 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.label, this.leading});

  final String label;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 6)],
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
