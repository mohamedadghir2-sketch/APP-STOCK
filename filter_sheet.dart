import 'package:flutter/material.dart';

import '../models/shoe_filter.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';

/// Ouvre la feuille de filtres et renvoie le filtre choisi (ou null si annulé).
Future<ShoeFilter?> showFilterSheet(
  BuildContext context, {
  required ShoeFilter current,
  required List<String> brands,
  required List<String> colors,
  required List<double> sizes,
}) {
  return showModalBottomSheet<ShoeFilter>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (_) => FilterSheet(
      current: current,
      brands: brands,
      colors: colors,
      sizes: sizes,
    ),
  );
}

class FilterSheet extends StatefulWidget {
  const FilterSheet({
    super.key,
    required this.current,
    required this.brands,
    required this.colors,
    required this.sizes,
  });

  final ShoeFilter current;
  final List<String> brands;
  final List<String> colors;
  final List<double> sizes;

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late ShoeFilter _draft = widget.current;

  void _toggle<T>(Set<T> source, T value, ShoeFilter Function(Set<T>) build) {
    final next = Set<T>.from(source);
    if (next.contains(value)) {
      next.remove(value);
    } else {
      next.add(value);
    }
    setState(() => _draft = build(next));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxHeight = MediaQuery.of(context).size.height * 0.85;

    return SafeArea(
      top: false,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 4),
              child: Row(
                children: [
                  Text('Filtrer le stock',
                      style: theme.textTheme.titleLarge
                          ?.copyWith(fontWeight: FontWeight.w800)),
                  const Spacer(),
                  TextButton(
                    onPressed: _draft.hasFilters
                        ? () => setState(() => _draft = _draft.cleared())
                        : null,
                    child: const Text('Tout effacer'),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Section(
                      title: 'Trier par',
                      child: Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final option in SortOption.values)
                            ChoiceChip(
                              label: Text(option.label),
                              selected: _draft.sort == option,
                              onSelected: (_) =>
                                  setState(() => _draft = _draft.copyWith(sort: option)),
                            ),
                        ],
                      ),
                    ),
                    if (widget.brands.isNotEmpty)
                      _Section(
                        title: 'Marque',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final brand in widget.brands)
                              FilterChip(
                                label: Text(brand),
                                selected: _draft.brands.contains(brand),
                                onSelected: (_) => _toggle<String>(
                                  _draft.brands,
                                  brand,
                                  (next) => _draft.copyWith(brands: next),
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (widget.colors.isNotEmpty)
                      _Section(
                        title: 'Couleur',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final color in widget.colors)
                              FilterChip(
                                avatar: _colorDot(context, color),
                                label: Text(color),
                                selected: _draft.colors.contains(color),
                                onSelected: (_) => _toggle<String>(
                                  _draft.colors,
                                  color,
                                  (next) => _draft.copyWith(colors: next),
                                ),
                              ),
                          ],
                        ),
                      ),
                    if (widget.sizes.isNotEmpty)
                      _Section(
                        title: 'Pointure',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            for (final size in widget.sizes)
                              FilterChip(
                                label: Text(Fmt.size(size)),
                                selected: _draft.sizes.contains(size),
                                onSelected: (_) => _toggle<double>(
                                  _draft.sizes,
                                  size,
                                  (next) => _draft.copyWith(sizes: next),
                                ),
                              ),
                          ],
                        ),
                      ),
                    _Section(
                      title: 'Disponibilité',
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: _draft.onlyLowStock,
                        onChanged: (value) => setState(
                            () => _draft = _draft.copyWith(onlyLowStock: value)),
                        title: const Text('Stock faible ou rupture'),
                        subtitle: Text(
                          '$kLowStockThreshold paires restantes ou moins',
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(_draft),
                  child: Text(
                    _draft.hasFilters
                        ? 'Appliquer ${_draft.activeCount} filtre'
                            '${_draft.activeCount > 1 ? 's' : ''}'
                        : 'Voir le stock',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _colorDot(BuildContext context, String name) {
    final color = colorFromName(name);
    if (color == null) return null;
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.3,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
