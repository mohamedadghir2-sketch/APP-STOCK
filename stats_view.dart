import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/stock_summary.dart';
import '../providers/shoe_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/shoe_card.dart';
import '../widgets/shoe_photo.dart';
import '../widgets/summary_card.dart';
import 'shoe_detail_screen.dart';

/// Onglet « Statistiques » : synthèse financière et alertes de stock.
class StatsView extends StatelessWidget {
  const StatsView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShoeProvider>();
    final theme = Theme.of(context);
    final summary = provider.summary;

    if (provider.loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.isEmptyStock) {
      return const SafeArea(
        child: Center(
          child: EmptyState(
            icon: Icons.insights_outlined,
            title: 'Pas encore de statistiques',
            message: 'Ajoutez des chaussures pour suivre la valeur de votre '
                'stock et votre bénéfice potentiel.',
          ),
        ),
      );
    }

    final maxBrandValue = provider.brandStats.isEmpty
        ? 0.0
        : provider.brandStats
            .map((b) => b.purchaseValue)
            .reduce((a, b) => a > b ? a : b);

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: CustomScrollView(
        slivers: [
          const SliverAppBar(pinned: true, titleSpacing: 20, title: Text('Statistiques')),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
            sliver: SliverList.list(
              children: [
                SummaryCard(
                  label: 'Valeur totale du stock',
                  references: summary.references,
                  items: summary.items,
                  purchaseValue: summary.purchaseValue,
                  saleValue: summary.saleValue,
                ),
                const SizedBox(height: 16),

                // Indicateurs clés
                Row(
                  children: [
                    Expanded(
                      child: _KpiTile(
                        value: Fmt.number(summary.references),
                        label: 'Références',
                        icon: Icons.style_outlined,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KpiTile(
                        value: Fmt.number(summary.items),
                        label: 'Paires en stock',
                        icon: Icons.inventory_2_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _KpiTile(
                        value: Fmt.number(summary.lowStockCount),
                        label: 'Stock faible',
                        icon: Icons.warning_amber_rounded,
                        color: StockColors.low,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _KpiTile(
                        value: Fmt.number(summary.outOfStockCount),
                        label: 'En rupture',
                        icon: Icons.remove_shopping_cart_outlined,
                        color: StockColors.out,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 26),
                _SectionHeader(
                  title: 'Répartition par marque',
                  subtitle: 'Valeur d\'achat immobilisée',
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: AppTheme.cardDecoration(context),
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 6),
                  child: Column(
                    children: [
                      for (final stat in provider.brandStats)
                        _BrandRow(stat: stat, maxValue: maxBrandValue),
                    ],
                  ),
                ),

                if (provider.lowStock.isNotEmpty) ...[
                  const SizedBox(height: 26),
                  _SectionHeader(
                    title: 'À réapprovisionner',
                    subtitle:
                        '$kLowStockThreshold paires restantes ou moins',
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: AppTheme.cardDecoration(context),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        for (var i = 0; i < provider.lowStock.length; i++) ...[
                          if (i > 0) const Divider(height: 1, indent: 76),
                          ListTile(
                            contentPadding:
                                const EdgeInsets.fromLTRB(14, 8, 14, 8),
                            leading: ShoePhoto(
                              fileName: provider.lowStock[i].photo,
                              width: 48,
                              height: 48,
                              radius: 12,
                              iconSize: 18,
                            ),
                            title: Text(
                              provider.lowStock[i].title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodyLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(
                              '${provider.lowStock[i].color} · '
                              'pointure ${Fmt.size(provider.lowStock[i].size)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: QuantityPill(
                                quantity: provider.lowStock[i].quantity),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ShoeDetailScreen(
                                    shoe: provider.lowStock[i]),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _KpiTile extends StatelessWidget {
  const _KpiTile({
    required this.value,
    required this.label,
    required this.icon,
    this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = color ?? theme.colorScheme.onSurfaceVariant;
    return Container(
      decoration: AppTheme.cardDecoration(context),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: tint),
          const SizedBox(height: 10),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: -0.8,
              color: color,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _BrandRow extends StatelessWidget {
  const _BrandRow({required this.stat, required this.maxValue});

  final BrandStat stat;
  final double maxValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final ratio = maxValue <= 0 ? 0.0 : (stat.purchaseValue / maxValue);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  stat.brand,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                Fmt.money(stat.purchaseValue),
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: scheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(scheme.primary),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${stat.items} paires · ${stat.references} réf. · '
            'bénéfice ${Fmt.money(stat.potentialProfit)}',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
