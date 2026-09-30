import 'package:flutter/material.dart' hide Category;
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../controllers/catalogue_controller.dart';
import '../../core/widgets/state_views.dart';
import '../../models/category.dart';
import '../../seed/seed_data.dart';
import '../../services/category_service.dart';

/// Gestion des catégories (vendeur) : liste, ajout avec ICÔNE, suppression.
/// Bouton « 12 catégories par défaut » pour démarrer en un tap.
class CategoriesManageScreen extends StatefulWidget {
  const CategoriesManageScreen({super.key});

  @override
  State<CategoriesManageScreen> createState() =>
      _CategoriesManageScreenState();
}

class _CategoriesManageScreenState extends State<CategoriesManageScreen> {
  final _service = CategoryService();
  bool _seeding = false;

  /// Palette d'icônes proposées à la création.
  static const _emojis = [
    '🎧', '📱', '🖥️', '📷', '👕', '👖', '👟', '👗',
    '⌚', '💍', '👜', '🕶️', '🧺', '🍎', '🥤', '☕',
    '🏠', '🛋️', '🛏️', '💄', '🧴', '⚽', '🎮', '🚲',
    '📚', '🧸', '👶', '🚗',
  ];

  @override
  Widget build(BuildContext context) {
    final catalogue = context.watch<CatalogueController>();
    final categories = catalogue.categories;

    return Scaffold(
      appBar: AppBar(title: const Text('Catégories')),
      body: SafeArea(
        child: categories.isEmpty
            ? _emptyState(context)
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 96),
                itemCount: categories.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (_, i) =>
                    _CategoryTile(category: categories[i], onDelete: () => _confirmDelete(categories[i])),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppTheme.brand,
        foregroundColor: Colors.white,
        onPressed: () => _showCategoryDialog(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouvelle catégorie'),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const EmptyView(
              icon: Icons.category_outlined,
              title: 'Aucune catégorie',
              message:
                  'Les catégories organisent votre catalogue (elles sont requises pour créer un produit).',
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: 320,
              child: ElevatedButton.icon(
                onPressed: _seeding ? null : _seedDefaults,
                icon: _seeding
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.download_for_offline_outlined),
                label: Text(_seeding
                    ? 'Chargement…'
                    : 'Charger les 12 catégories par défaut'),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: 320,
              child: OutlinedButton.icon(
                onPressed: () => _showCategoryDialog(context),
                icon: const Icon(Icons.add),
                label: const Text('Créer une catégorie'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _seedDefaults() async {
    setState(() => _seeding = true);
    try {
      await SeedData.seedCategoriesOnly();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('12 catégories par défaut ajoutées ✓')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  Future<void> _showCategoryDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    String emoji = _emojis.first;
    String? errorText;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: const Text('Nouvelle catégorie'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: 'Ex. Chaussures',
                    errorText: errorText,
                  ),
                ),
                const SizedBox(height: 18),
                Text('Icône de la catégorie',
                    style: TextStyle(
                        color: context.textColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final e in _emojis)
                      InkWell(
                        onTap: () => setDialog(() => emoji = e),
                        borderRadius: BorderRadius.circular(AppTheme.rSm),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 120),
                          width: 44,
                          height: 44,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: e == emoji
                                ? (context.isDark
                                    ? AppTheme.brand.withValues(alpha: 0.12)
                                    : AppTheme.peach)
                                : context.cardColor,
                            border: Border.all(
                              color: e == emoji
                                  ? AppTheme.brand
                                  : context.lineColor,
                              width: e == emoji ? 1.6 : 1,
                            ),
                            borderRadius:
                                BorderRadius.circular(AppTheme.rSm),
                          ),
                          child: Text(e, style: const TextStyle(fontSize: 21)),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Annuler'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameCtrl.text.trim().isEmpty) {
                  setDialog(() => errorText = 'Le nom est requis');
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Ajouter'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final categories =
        context.read<CatalogueController>().categories;
    final category = Category(
      id: 'cat_${DateTime.now().millisecondsSinceEpoch}',
      name: nameCtrl.text.trim(),
      icon: emoji,
      order: categories.isEmpty
          ? 1
          : categories.map((c) => c.order).reduce((a, b) => a > b ? a : b) + 1,
    );
    try {
      await _service.upsert(category);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Catégorie « ${category.name} » ajoutée ✓')));
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }

  Future<void> _confirmDelete(Category category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer cette catégorie ?'),
        content: Text(
            '« ${category.name} » sera retirée des filtres. Les produits existants conservent leur catégorie enregistrée et restent visibles dans le catalogue.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    try {
      await _service.delete(category.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('« ${category.name} » supprimée')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Erreur : $e')));
    }
  }
}

class _CategoryTile extends StatelessWidget {
  final Category category;
  final VoidCallback onDelete;
  const _CategoryTile({required this.category, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: context.cardColor,
        border: Border.all(color: context.lineColor),
        borderRadius: BorderRadius.circular(AppTheme.rLg),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: context.isDark
                  ? AppTheme.brand.withValues(alpha: 0.12)
                  : AppTheme.peach,
              borderRadius: BorderRadius.circular(AppTheme.rMd),
            ),
            child: Text(category.icon, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name,
                    style: TextStyle(
                        color: context.textColor,
                        fontWeight: FontWeight.w800)),
                Text('Ordre d\'affichage : ${category.order}',
                    style: TextStyle(
                        color: context.mutedColor, fontSize: 12)),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Supprimer',
            icon: const Icon(Icons.delete_outline, color: AppTheme.danger),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
