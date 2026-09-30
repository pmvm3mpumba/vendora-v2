import 'dart:typed_data';

import 'package:flutter/material.dart' hide Category;
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/catalogue_controller.dart';
import '../../controllers/seller_controller.dart';
import '../../core/constants/currencies.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_image.dart';
import '../../core/widgets/inputs.dart';
import '../../models/category.dart';
import '../../models/product.dart';
import '../../services/image_storage_service.dart';
import '../../services/product_service.dart';
import 'categories_manage_screen.dart';

/// Écrans 16+17 — Créer / Modifier un produit (§5) :
/// validation complète (prix, stock), image (upload Storage OU base64 Spark),
/// catégorie Firestore, devise. Le produit devient visible publiquement.
class ProductFormScreen extends StatefulWidget {
  final String? productId; // null = création
  const ProductFormScreen({super.key, this.productId});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _stock = TextEditingController();

  String _currency = 'BIF';
  String? _categoryId;
  String _existingImageUrl = '';
  Uint8List? _newImageBytes;
  Product? _editing;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (widget.productId == null) return;
    // Cherche d'abord dans la liste déjà chargée, sinon requête Firestore.
    final seller = context.read<SellerController>();
    Product? p;
    for (final prod in seller.myProducts) {
      if (prod.id == widget.productId) p = prod;
    }
    p ??= await ProductService().getProduct(widget.productId!);
    if (p == null || !mounted) return;
    setState(() {
      _editing = p;
      _name.text = p!.name;
      _description.text = p.description;
      _price.text = p.price.toStringAsFixed(0);
      _stock.text = '${p.stock}';
      _currency = p.currency;
      _categoryId = p.categoryId;
      _existingImageUrl = p.imageUrl;
    });
  }

  @override
  void dispose() {
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // compression — reste < ~350 Ko (plan B base64)
        maxWidth: 1024,
      );
      if (picked == null) return;
      final bytes = await picked.readAsBytes();
      setState(() => _newImageBytes = bytes);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Impossible de lire cette image')));
      }
    }
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Choisissez une catégorie')));
      return;
    }
    if (_editing == null && _newImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Ajoutez une image pour votre produit')));
      return;
    }
    final user = context.read<AuthController>().appUser;
    if (user == null) return;

    setState(() => _saving = true);
    try {
      // 1. Image : upload (Storage) ou base64 selon la stratégie active.
      String imageUrl = _existingImageUrl;
      if (_newImageBytes != null) {
        imageUrl = await createImageStorageService().uploadProductImage(
          _newImageBytes!,
          '${user.uid}_${DateTime.now().millisecondsSinceEpoch}',
        );
      }
      // 2. Catégorie (nom dénormalisé pour le catalogue).
      final categories = context.read<CatalogueController>().categories;
      final category = categories.firstWhere(
        (c) => c.id == _categoryId,
        orElse: () =>
            Category(id: _categoryId!, name: _categoryId!),
      );
      // 3. Firestore (création → visible publiquement ; modification en place).
      final product = Product(
        id: _editing?.id ?? '',
        name: _name.text.trim(),
        description: _description.text.trim(),
        price: double.parse(
            _price.text.replaceAll(' ', '').replaceAll(',', '.')),
        currency: _currency,
        categoryId: category.id,
        categoryName: category.name,
        stock: int.parse(_stock.text),
        imageUrl: imageUrl,
        sellerId: _editing?.sellerId ?? user.uid,
        sellerName: _editing?.sellerName ?? user.name,
        sellerWhatsapp: _editing?.sellerWhatsapp ?? user.whatsappNumber,
        isActive: _editing?.isActive ?? true,
        createdAt: _editing?.createdAt,
      );
      final ok =
          await context.read<SellerController>().saveProduct(product);
      if (!mounted) return;
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(_editing == null
                ? 'Produit publié dans le catalogue ✓'
                : 'Produit mis à jour ✓')));
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.read<SellerController>().error ??
                'Erreur lors de l\'enregistrement')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = context.watch<CatalogueController>().categories;
    final isEdit = _editing != null;

    return Scaffold(
      appBar:
          AppBar(title: Text(isEdit ? 'Modifier le produit' : 'Nouveau produit')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            children: [
              // ── Image ──
              InkWell(
                onTap: _pickImage,
                borderRadius: BorderRadius.circular(AppTheme.rLg),
                child: AspectRatio(
                  aspectRatio: 16 / 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: context.cardColor,
                      border: Border.all(color: context.lineColor),
                      borderRadius: BorderRadius.circular(AppTheme.rLg),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _newImageBytes != null
                        ? Image.memory(_newImageBytes!, fit: BoxFit.cover)
                        : _existingImageUrl.isNotEmpty
                            ? AppImage(_existingImageUrl)
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate_outlined,
                                      size: 40, color: context.mutedColor),
                                  const SizedBox(height: 8),
                                  Text('Touchez pour ajouter une image',
                                      style: TextStyle(
                                          color: context.mutedColor,
                                          fontSize: 13)),
                                ],
                              ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  kUseFirebaseStorage
                      ? 'Image envoyée sur Firebase Storage'
                      : 'Image compressée et stockée dans Firestore (plan gratuit)',
                  style: TextStyle(color: context.mutedColor, fontSize: 11),
                ),
              ),
              const SizedBox(height: 18),

              FieldLabel(
                'Nom du produit',
                child: TextFormField(
                  controller: _name,
                  validator: (v) => Validators.required(v, 'Le nom'),
                  decoration:
                      const InputDecoration(hintText: 'Ex. Casque sans fil Studio'),
                ),
              ),
              const SizedBox(height: 16),
              FieldLabel(
                'Description',
                child: TextFormField(
                  controller: _description,
                  maxLines: 3,
                  validator: (v) => Validators.required(v, 'La description'),
                  decoration: const InputDecoration(
                      hintText: 'Caractéristiques, état, garantie…'),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: FieldLabel(
                      'Prix',
                      child: TextFormField(
                        controller: _price,
                        keyboardType: TextInputType.number,
                        validator: Validators.price,
                        decoration: const InputDecoration(hintText: '135 000'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FieldLabel(
                      'Devise',
                      child: DropdownButtonFormField<String>(
                        value: _currency,
                        items: [
                          for (final c in Currencies.supported)
                            DropdownMenuItem(value: c, child: Text(c)),
                        ],
                        onChanged: (v) =>
                            setState(() => _currency = v ?? 'BIF'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              FieldLabel(
                'Catégorie',
                child: DropdownButtonFormField<String>(
                  value: categories
                          .any((c) => c.id == _categoryId)
                      ? _categoryId
                      : null,
                  decoration:
                      const InputDecoration(hintText: 'Choisir une catégorie'),
                  items: [
                    for (final c in categories)
                      DropdownMenuItem(
                          value: c.id, child: Text('${c.icon} ${c.name}')),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                ),
              ),
              if (categories.isEmpty) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => const CategoriesManageScreen())),
                  borderRadius: BorderRadius.circular(AppTheme.rSm),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.isDark
                          ? AppTheme.brand.withValues(alpha: 0.08)
                          : AppTheme.peach,
                      borderRadius: BorderRadius.circular(AppTheme.rSm),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.category_outlined,
                            color: AppTheme.brand, size: 20),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Aucune catégorie — ouvrez « Gérer les catégories » pour créer les vôtres ou charger les 12 par défaut.',
                            style: TextStyle(
                                color: AppTheme.brand, fontSize: 12.5),
                          ),
                        ),
                        Icon(Icons.chevron_right,
                            color: AppTheme.brand, size: 18),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              FieldLabel(
                'Stock disponible',
                child: TextFormField(
                  controller: _stock,
                  keyboardType: TextInputType.number,
                  validator: Validators.stock,
                  decoration: const InputDecoration(hintText: 'Ex. 12'),
                ),
              ),
              const SizedBox(height: 26),
              ElevatedButton.icon(
                onPressed: _saving ? null : _save,
                icon: Icon(isEdit ? Icons.save_outlined : Icons.publish,
                    size: 19),
                label: Text(isEdit
                    ? 'Enregistrer les modifications'
                    : 'Publier dans le catalogue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
