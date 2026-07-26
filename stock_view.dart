import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/shoe.dart';
import '../providers/shoe_provider.dart';
import '../utils/formatters.dart';
import '../widgets/empty_state.dart';
import '../widgets/filter_sheet.dart';
import '../widgets/shoe_card.dart';
import '../widgets/summary_card.dart';
import 'shoe_detail_screen.dart';
import 'shoe_form_screen.dart';

/// Onglet « Stock » : synthèse, recherche, filtres et liste complète.
class StockView extends StatefulWidget {
  const StockView({super.key});

  @override
  State<StockView> createState() => _StockViewState();
}

class _StockViewState extends State<StockView> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openFilters(ShoeProvider provider) async {
    final result = await showFilterSheet(
      context,
      current: provider.filter,
      brands: provider.brands,
      colors: provider.colors,
      sizes: provider.sizes,
    );
    if (result != null) provider.applyFilter(result);
  }

  void _openDetail(Shoe shoe) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ShoeDetailScreen(shoe: shoe)),
    );
  }

  Future<void> _addShoe() async {
    await Navigator.of(context)
        .push<bool>(MaterialPageRoute(builder: (_) => const ShoeFormScreen()));
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ShoeProvider>();
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final filter = provider.filter;

    return RefreshIndicator(
      onRefresh: provider.refresh,
      child: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          SliverAppBar(
            pinned: true,
            titleSpacing: 20,
            title: const Text('Mon stock'),
            actions: [
              IconButton(
                tooltip: 'Filtrer et trier',
                onPressed: () => _openFilters(provider),
                icon: Badge(
                  isLabelVisible: filter.hasFilters,
                  label: Text('${filter.activeCount}'),
                  child: const Icon(Icons.tune_rounded),
                ),
              ),
              const SizedBox(width: 8),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: provider.search,
                  decoration: InputDecoration(
                    hintText: 'Marque, modèle, couleur, pointure…',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: filter.hasSearch
                        ? IconButton(
                            tooltip: 'Effacer la recherche',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              _searchController.clear();
                              provider.clearSearch();
                              FocusScope.of(context).unfocus();
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ),

          // Synthèse financière
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: provider.isFiltered
                  ? SummaryCard(
                      label: 'Sélection affichée',
                      references: provider.shoes.length,
                      items: provider.visibleItems,
                      purchaseValue: provider.visiblePurchaseValue,
                      saleValue: provider.visibleSaleValue,
                    )
                  : SummaryCard(
                      label: 'Valeur totale du stock',
                      references: provider.summary.references,
                      items: provider.summary.items,
                      purchaseValue: provider.summary.purchaseValue,
                      saleValue: provider.summary.saleValue,
                    ),
            ),
          ),

          // Filtres actifs
          if (filter.hasFilters)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    for (final brand in filter.brands)
                      _ActiveChip(
                        label: brand,
                        onRemoved: () => provider.toggleBrand(brand),
                      ),
                    for (final color in filter.colors)
                      _ActiveChip(
                        label: color,
                        onRemoved: () => provider.toggleColor(color),
                      ),
                    for (final size in filter.sizes)
                      _ActiveChip(
                        label: 'P. ${Fmt.size(size)}',
                        onRemoved: () => provider.toggleSize(size),
                      ),
                    if (filter.onlyLowStock)
                      _ActiveChip(
                        label: 'Stock faible',
                        onRemoved: () => provider.applyFilter(
                          filter.copyWith(onlyLowStock: false),
                        ),
                      ),
                    TextButton(
                      onPressed: provider.clearFilters,
                      child: const Text('Tout effacer'),
                    ),
                  ],
                ),
              ),
            ),

          // Ligne d'en-tête de la liste
          if (!provider.loading && provider.shoes.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 10),
                child: Row(
                  children: [
                    Text(
                      '${provider.shoes.length} référence'
                      '${provider.shoes.length > 1 ? 's' : ''}',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: () => _openFilters(provider),
                      icon: const Icon(Icons.swap_vert_rounded, size: 18),
                      label: Text(filter.sort.label),
                      style: TextButton.styleFrom(
                        foregroundColor: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Contenu
          if (provider.loading)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (provider.shoes.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: provider.isFiltered
                  ? EmptyState(
                      icon: Icons.search_off_rounded,
                      title: 'Aucun résultat',
                      message:
                          'Aucune chaussure ne correspond à cette recherche. '
                          'Modifiez les filtres pour élargir la sélection.',
                      actionLabel: 'Réinitialiser',
                      onAction: () {
                        _searchController.clear();
                        provider.applyFilter(provider.filter.cleared()
                            .copyWith(search: ''));
                      },
                    )
                  : EmptyState(
                      icon: Icons.inventory_2_outlined,
                      title: 'Votre stock est vide',
                      message:
                          'Ajoutez votre première paire : photo, pointure, '
                          'prix d\'achat et de vente.',
                      actionLabel: 'Ajouter une chaussure',
                      onAction: _addShoe,
                    ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
              sliver: SliverList.separated(
                itemCount: provider.shoes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final shoe = provider.shoes[index];
                  return ShoeCard(
                    shoe: shoe,
                    onTap: () => _openDetail(shoe),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _ActiveChip extends StatelessWidget {
  const _ActiveChip({required this.label, required this.onRemoved});

  final String label;
  final VoidCallback onRemoved;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Chip(
        label: Text(label),
        onDeleted: onRemoved,
        deleteIcon: const Icon(Icons.close_rounded, size: 16),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}
