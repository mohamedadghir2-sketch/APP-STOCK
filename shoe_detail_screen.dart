import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/shoe.dart';
import '../providers/shoe_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../widgets/shoe_card.dart';
import '../widgets/shoe_photo.dart';
import 'shoe_form_screen.dart';

/// Fiche complète d'une référence : photo, caractéristiques, finances,
/// ajustement rapide de la quantité.
class ShoeDetailScreen extends StatefulWidget {
  const ShoeDetailScreen({super.key, required this.shoe});

  final Shoe shoe;

  @override
  State<ShoeDetailScreen> createState() => _ShoeDetailScreenState();
}

class _ShoeDetailScreenState extends State<ShoeDetailScreen> {
  late Shoe _shoe = widget.shoe;
  bool _busy = false;

  Future<void> _reload() async {
    final fresh = await context.read<ShoeProvider>().byId(_shoe.id!);
    if (fresh != null && mounted) setState(() => _shoe = fresh);
  }

  Future<void> _edit() async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ShoeFormScreen(shoe: _shoe)),
    );
    if (saved == true) await _reload();
  }

  Future<void> _adjust(int delta) async {
    if (_busy) return;
    setState(() => _busy = true);
    await context.read<ShoeProvider>().adjustQuantity(_shoe, delta);
    await _reload();
    if (mounted) setState(() => _busy = false);
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cette référence ?'),
        content: Text(
          '${_shoe.title} (pointure ${Fmt.size(_shoe.size)}) sera retirée du '
          'stock. Cette action est définitive.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: StockColors.out),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    await context.read<ShoeProvider>().delete(_shoe);
    if (!mounted) return;
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(content: Text('${_shoe.title} supprimée')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final dotColor = colorFromName(_shoe.color);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300,
            backgroundColor: scheme.surface,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
            actionsIconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  ShoePhoto(
                    fileName: _shoe.photo,
                    width: double.infinity,
                    height: double.infinity,
                    radius: 0,
                    iconSize: 56,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x99000000), Color(0x00000000)],
                        stops: [0, 0.4],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              IconButton(
                tooltip: 'Modifier',
                onPressed: _edit,
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Supprimer',
                onPressed: _confirmDelete,
                icon: const Icon(Icons.delete_outline_rounded),
              ),
              const SizedBox(width: 4),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _shoe.brand.toUpperCase(),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _shoe.model,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      QuantityPill(quantity: _shoe.quantity, large: true),
                      const SizedBox(width: 10),
                      if (dotColor != null)
                        Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                            border: Border.all(color: scheme.outlineVariant),
                          ),
                        ),
                      if (dotColor != null) const SizedBox(width: 6),
                      Text(
                        '${_shoe.color} · pointure ${Fmt.size(_shoe.size)}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Ajustement rapide
                  Container(
                    decoration: AppTheme.cardDecoration(context),
                    padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Quantité restante',
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Une vente ? Retirez une paire.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: _shoe.quantity > 0 && !_busy
                              ? () => _adjust(-1)
                              : null,
                          icon: const Icon(Icons.remove_rounded),
                        ),
                        SizedBox(
                          width: 52,
                          child: Text(
                            '${_shoe.quantity}',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: _busy ? null : () => _adjust(1),
                          icon: const Icon(Icons.add_rounded),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Finances
                  Container(
                    decoration: AppTheme.cardDecoration(context),
                    padding: const EdgeInsets.fromLTRB(18, 6, 18, 10),
                    child: Column(
                      children: [
                        _InfoRow(
                          label: 'Prix d\'achat unitaire',
                          value: Fmt.money(_shoe.purchasePrice),
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          label: 'Prix de vente unitaire',
                          value: Fmt.money(_shoe.salePrice),
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          label: 'Marge unitaire',
                          value: '${Fmt.money(_shoe.unitMargin)}'
                              '  (${Fmt.percent(_shoe.marginRate)})',
                          color: _shoe.unitMargin >= 0
                              ? StockColors.profit
                              : StockColors.out,
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          label: 'Valeur du stock (achat)',
                          value: Fmt.money(_shoe.stockValue),
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          label: 'Vente potentielle',
                          value: Fmt.money(_shoe.potentialRevenue),
                        ),
                        const Divider(height: 1),
                        _InfoRow(
                          label: 'Bénéfice potentiel',
                          value: Fmt.money(_shoe.potentialProfit),
                          emphasis: true,
                          color: _shoe.potentialProfit >= 0
                              ? StockColors.profit
                              : StockColors.out,
                        ),
                      ],
                    ),
                  ),

                  if ((_shoe.note ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      decoration: AppTheme.cardDecoration(context),
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'NOTE',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(_shoe.note!.trim()),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 18),
                  Text(
                    'Ajoutée le ${Fmt.date(_shoe.createdAt)} · '
                    'modifiée le ${Fmt.date(_shoe.updatedAt)}',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _edit,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Modifier la fiche'),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _confirmDelete,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: StockColors.out,
                      ),
                      icon: const Icon(Icons.delete_outline_rounded),
                      label: const Text('Supprimer du stock'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    this.emphasis = false,
    this.color,
  });

  final String label;
  final String value;
  final bool emphasis;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            value,
            style: (emphasis
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.bodyLarge)
                ?.copyWith(
              fontWeight: emphasis ? FontWeight.w800 : FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
