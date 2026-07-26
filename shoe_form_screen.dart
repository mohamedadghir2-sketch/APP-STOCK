import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/shoe.dart';
import '../providers/shoe_provider.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/formatters.dart';
import '../utils/photo_storage.dart';
import '../widgets/shoe_photo.dart';

/// Formulaire unique pour créer ou modifier une référence.
class ShoeFormScreen extends StatefulWidget {
  const ShoeFormScreen({super.key, this.shoe});

  /// `null` = création.
  final Shoe? shoe;

  @override
  State<ShoeFormScreen> createState() => _ShoeFormScreenState();
}

class _ShoeFormScreenState extends State<ShoeFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _brand;
  late final TextEditingController _model;
  late final TextEditingController _color;
  late final TextEditingController _size;
  late final TextEditingController _quantity;
  late final TextEditingController _purchase;
  late final TextEditingController _sale;
  late final TextEditingController _note;

  String? _photo;
  String? _originalPhoto;
  bool _saved = false;
  bool _saving = false;

  bool get _isEditing => widget.shoe != null;

  @override
  void initState() {
    super.initState();
    final shoe = widget.shoe;
    _brand = TextEditingController(text: shoe?.brand ?? '');
    _model = TextEditingController(text: shoe?.model ?? '');
    _color = TextEditingController(text: shoe?.color ?? '');
    _size = TextEditingController(
        text: shoe == null ? '' : Fmt.size(shoe.size));
    _quantity = TextEditingController(text: '${shoe?.quantity ?? 1}');
    _purchase = TextEditingController(
        text: shoe == null ? '' : shoe.purchasePrice.toStringAsFixed(2));
    _sale = TextEditingController(
        text: shoe == null ? '' : shoe.salePrice.toStringAsFixed(2));
    _note = TextEditingController(text: shoe?.note ?? '');
    _photo = shoe?.photo;
    _originalPhoto = shoe?.photo;

    for (final controller in [_purchase, _sale, _quantity]) {
      controller.addListener(_onMoneyChanged);
    }
  }

  void _onMoneyChanged() => setState(() {});

  @override
  void dispose() {
    // Si l'utilisateur quitte sans enregistrer, on nettoie la photo copiée.
    if (!_saved && _photo != null && _photo != _originalPhoto) {
      PhotoStorage.delete(_photo);
    }
    for (final controller in [
      _brand,
      _model,
      _color,
      _size,
      _quantity,
      _purchase,
      _sale,
      _note,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  // --- Photo --------------------------------------------------------------

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final fileName = await PhotoStorage.pick(source);
      if (fileName == null) return;
      // On supprime le fichier temporaire précédent s'il n'est pas l'original.
      if (_photo != null && _photo != _originalPhoto) {
        await PhotoStorage.delete(_photo);
      }
      if (mounted) setState(() => _photo = fileName);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? "Impossible d'ouvrir l'appareil photo. Vérifiez l'autorisation Caméra dans les réglages."
                : "Impossible d'ouvrir la galerie. Vérifiez les autorisations dans les réglages.",
          ),
        ),
      );
    }
  }

  Future<void> _openPhotoSheet() async {
    FocusScope.of(context).unfocus();
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Prendre une photo'),
              onTap: () {
                Navigator.of(context).pop();
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choisir dans la galerie'),
              onTap: () {
                Navigator.of(context).pop();
                _pickPhoto(ImageSource.gallery);
              },
            ),
            if (_photo != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: StockColors.out),
                title: const Text('Retirer la photo',
                    style: TextStyle(color: StockColors.out)),
                onTap: () {
                  Navigator.of(context).pop();
                  if (_photo != _originalPhoto) PhotoStorage.delete(_photo);
                  setState(() => _photo = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // --- Enregistrement -----------------------------------------------------

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    final now = DateTime.now();
    final base = widget.shoe;
    final shoe = Shoe(
      id: base?.id,
      brand: _brand.text.trim(),
      model: _model.text.trim(),
      color: _color.text.trim(),
      size: Fmt.parseNumber(_size.text) ?? 0,
      quantity: int.tryParse(_quantity.text.trim()) ?? 0,
      purchasePrice: Fmt.parseNumber(_purchase.text) ?? 0,
      salePrice: Fmt.parseNumber(_sale.text) ?? 0,
      photo: _photo,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      createdAt: base?.createdAt ?? now,
      updatedAt: now,
    );

    await context.read<ShoeProvider>().save(shoe);

    // L'ancienne photo remplacée n'est plus utile.
    if (_originalPhoto != null && _originalPhoto != _photo) {
      await PhotoStorage.delete(_originalPhoto);
    }

    _saved = true;
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.of(context).pop(true);
    if (_isEditing) {
      messenger
        ..clearSnackBars()
        ..showSnackBar(const SnackBar(content: Text('Fiche mise à jour')));
    }
  }

  void _bumpQuantity(int delta) {
    final current = int.tryParse(_quantity.text.trim()) ?? 0;
    final next = (current + delta).clamp(0, 99999);
    _quantity.text = '$next';
  }

  // --- Validation ---------------------------------------------------------

  String? _required(String? value, String field) {
    if (value == null || value.trim().isEmpty) return 'Indiquez $field.';
    return null;
  }

  String? _validateSize(String? value) {
    if (value == null || value.trim().isEmpty) return 'Indiquez la pointure.';
    final size = Fmt.parseNumber(value);
    if (size == null) return 'Pointure invalide (ex. 42 ou 42,5).';
    if (size <= 0 || size > 70) return 'Pointure hors plage (1 à 70).';
    return null;
  }

  String? _validateQuantity(String? value) {
    final quantity = int.tryParse((value ?? '').trim());
    if (quantity == null) return 'Indiquez un nombre entier.';
    if (quantity < 0) return 'La quantité ne peut pas être négative.';
    return null;
  }

  String? _validatePrice(String? value, String field) {
    if (value == null || value.trim().isEmpty) return 'Indiquez le $field.';
    final price = Fmt.parseNumber(value);
    if (price == null) return 'Montant invalide (ex. 89,90).';
    if (price < 0) return 'Le montant ne peut pas être négatif.';
    return null;
  }

  // --- UI -----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final provider = context.watch<ShoeProvider>();

    final purchase = Fmt.parseNumber(_purchase.text) ?? 0;
    final sale = Fmt.parseNumber(_sale.text) ?? 0;
    final quantity = int.tryParse(_quantity.text.trim()) ?? 0;
    final margin = sale - purchase;
    final marginRate = purchase <= 0 ? 0.0 : (margin / purchase) * 100;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Modifier la fiche' : 'Nouvelle chaussure'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            // Photo
            Center(
              child: GestureDetector(
                onTap: _openPhotoSheet,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(kRadius),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: ShoePhoto(
                        fileName: _photo,
                        width: 160,
                        height: 160,
                        radius: kRadius - 1,
                        iconSize: 34,
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _photo == null
                              ? Icons.add_a_photo_outlined
                              : Icons.edit_outlined,
                          size: 18,
                          color: scheme.onPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _openPhotoSheet,
                child: Text(_photo == null
                    ? 'Ajouter une photo'
                    : 'Changer la photo'),
              ),
            ),
            const SizedBox(height: 12),

            const _SectionTitle('Identification'),
            _SuggestionField(
              controller: _brand,
              label: 'Marque',
              hint: 'Nike, Adidas, New Balance…',
              suggestions: provider.brands,
              validator: (v) => _required(v, 'la marque'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _model,
              decoration: const InputDecoration(
                labelText: 'Modèle',
                hintText: 'Air Max 90, Stan Smith…',
              ),
              textCapitalization: TextCapitalization.words,
              validator: (v) => _required(v, 'le modèle'),
            ),
            const SizedBox(height: 14),
            _SuggestionField(
              controller: _color,
              label: 'Couleur',
              hint: 'Noir, blanc, rouge…',
              suggestions: provider.colors,
              validator: (v) => _required(v, 'la couleur'),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _size,
                    decoration: const InputDecoration(
                      labelText: 'Pointure',
                      hintText: '42',
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    validator: _validateSize,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextFormField(
                    controller: _quantity,
                    decoration: InputDecoration(
                      labelText: 'Quantité',
                      suffixIcon: SizedBox(
                        width: 76,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 34, minHeight: 34),
                              onPressed: () => _bumpQuantity(-1),
                              icon: const Icon(Icons.remove_rounded, size: 18),
                            ),
                            IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(
                                  minWidth: 34, minHeight: 34),
                              onPressed: () => _bumpQuantity(1),
                              icon: const Icon(Icons.add_rounded, size: 18),
                            ),
                          ],
                        ),
                      ),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    validator: _validateQuantity,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 26),
            const _SectionTitle('Prix'),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _purchase,
                    decoration: const InputDecoration(
                      labelText: 'Prix d\'achat',
                      suffixText: kCurrencySymbol,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    validator: (v) => _validatePrice(v, 'prix d\'achat'),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextFormField(
                    controller: _sale,
                    decoration: const InputDecoration(
                      labelText: 'Prix de vente',
                      suffixText: kCurrencySymbol,
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    validator: (v) => _validatePrice(v, 'prix de vente'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Aperçu du calcul, mis à jour en direct
            Container(
              decoration: AppTheme.cardDecoration(context),
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  _PreviewRow(
                    label: 'Marge unitaire',
                    value: '${Fmt.money(margin)}  (${Fmt.percent(marginRate)})',
                    color: margin >= 0 ? StockColors.profit : StockColors.out,
                  ),
                  const SizedBox(height: 10),
                  _PreviewRow(
                    label: 'Valeur du stock ($quantity ×)',
                    value: Fmt.money(purchase * quantity),
                  ),
                  const SizedBox(height: 10),
                  _PreviewRow(
                    label: 'Bénéfice potentiel',
                    value: Fmt.money(margin * quantity),
                    color: margin >= 0 ? StockColors.profit : StockColors.out,
                    bold: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 26),
            const _SectionTitle('Note (facultatif)'),
            TextFormField(
              controller: _note,
              decoration: const InputDecoration(
                hintText: 'Emplacement, fournisseur, état de la boîte…',
              ),
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton(
            onPressed: _saving ? null : _submit,
            child: _saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.4, color: Colors.white),
                  )
                : Text(_isEditing
                    ? 'Enregistrer les modifications'
                    : 'Ajouter au stock'),
          ),
        ),
      ),
    );
  }
}

/// Champ texte accompagné des valeurs déjà saisies, à tapoter pour aller vite.
class _SuggestionField extends StatelessWidget {
  const _SuggestionField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.suggestions,
    required this.validator,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final List<String> suggestions;
  final String? Function(String?) validator;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    final visible = suggestions.take(12).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(labelText: label, hintText: hint),
          textCapitalization: textCapitalization,
          validator: validator,
        ),
        if (visible.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: visible.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) => ActionChip(
                label: Text(visible[index]),
                visualDensity: VisualDensity.compact,
                onPressed: () {
                  controller.text = visible[index];
                  controller.selection = TextSelection.fromPosition(
                    TextPosition(offset: controller.text.length),
                  );
                },
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.3,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  const _PreviewRow({
    required this.label,
    required this.value,
    this.color,
    this.bold = false,
  });

  final String label;
  final String value;
  final Color? color;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}
