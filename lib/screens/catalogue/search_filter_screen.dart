import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../controllers/catalogue_controller.dart';
import '../../controllers/currency_controller.dart';
import '../../core/widgets/product_card.dart';
import '../../core/widgets/state_views.dart';
import '../../models/enums.dart';

/// Écran 5b — Recherche + filtre + tri (maquette : champ « Un produit,
/// une envie… » + icône de réglages). BONUS : tri (prix, nouveautés, nom).
class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  @override
  void dispose() {
    // Réinitialise la recherche en quittant (UX : retour catalogue propre).
    context.read<CatalogueController>().setQuery('');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogue = context.watch<CatalogueController>();
    final currency = context.watch<CurrencyController>().selected;
    final products = catalogue.visible(displayCurrency: currency);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: 16),
          child: TextField(
            autofocus: true,
            onChanged: catalogue.setQuery,
            decoration: InputDecoration(
              hintText: 'Un produit, une envie…',
              prefixIcon: const Icon(Icons.search, size: 22),
              filled: true,
              fillColor: context.cardColor,
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.rMd),
                borderSide: BorderSide(color: context.lineColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppTheme.rMd),
                borderSide: BorderSide(color: context.lineColor),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // — Tri (bonus) —
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _SortChip(
                    label: 'Nouveautés',
                    selected: catalogue.sort == ProductSort.newest,
                    onTap: () => catalogue.setSort(ProductSort.newest),
                  ),
                  _SortChip(
                    label: 'Prix croissant',
                    selected: catalogue.sort == ProductSort.priceAsc,
                    onTap: () => catalogue.setSort(ProductSort.priceAsc),
                  ),
                  _SortChip(
                    label: 'Prix décroissant',
                    selected: catalogue.sort == ProductSort.priceDesc,
                    onTap: () => catalogue.setSort(ProductSort.priceDesc),
                  ),
                  _SortChip(
                    label: 'Nom A–Z',
                    selected: catalogue.sort == ProductSort.nameAsc,
                    onTap: () => catalogue.setSort(ProductSort.nameAsc),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Text(
                '${products.length} résultat(s)',
                style: TextStyle(color: context.mutedColor, fontSize: 12.5),
              ),
            ),
            Expanded(
              child: products.isEmpty
                  ? EmptyView(
                      icon: Icons.search_off,
                      title: catalogue.query.isEmpty
                          ? 'Aucun produit'
                          : 'Aucun résultat',
                      message: catalogue.query.isEmpty
                          ? 'Tapez un nom de produit pour rechercher.'
                          : 'Aucun produit ne correspond à « ${catalogue.query} ».',
                    )
                  : GridView.builder(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      itemCount: products.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 18,
                        crossAxisSpacing: 14,
                        childAspectRatio: 0.63,
                      ),
                      itemBuilder: (_, i) =>
                          ProductCard(product: products[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SortChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: selected
                ? (context.isDark
                    ? AppTheme.brand.withValues(alpha: 0.12)
                    : AppTheme.peach)
                : context.cardColor,
            border: Border.all(
              color: selected ? AppTheme.brand : context.lineColor,
              width: selected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              color: selected ? AppTheme.brand : context.mutedColor,
            ),
          ),
        ),
      ),
    );
  }
}
