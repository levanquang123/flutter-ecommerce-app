import 'package:flutter/cupertino.dart';

import '../../../models/product.dart';
import '../../../utility/extensions.dart';
import '../../../utility/snack_bar_helper.dart';

class VariantOption {
  final String optionId;
  final String optionName;

  const VariantOption({
    required this.optionId,
    required this.optionName,
  });
}

class VariantTypeGroup {
  final String typeId;
  final String typeName;
  final List<VariantOption> options;

  const VariantTypeGroup({
    required this.typeId,
    required this.typeName,
    required this.options,
  });
}

class ProductDetailProvider extends ChangeNotifier {
  final Map<String, String> _selectedOptionByType = {};

  ProductDetailProvider();

  List<ProductVariant> getActiveVariants(Product product) {
    final variants = product.variants ?? const <ProductVariant>[];
    return variants.where((variant) => variant.isActive).toList();
  }

  List<VariantTypeGroup> getVariantGroups(Product product) {
    final variants = getActiveVariants(product);
    final Map<String, Map<String, String>> typeOptions = {};
    final Map<String, String> typeNames = {};

    for (final variant in variants) {
      for (final attribute in variant.attributes) {
        final typeId = (attribute.variantTypeId ?? '').trim();
        final typeName = (attribute.variantTypeName ?? 'Option').trim();
        final optionId = (attribute.variantId ?? '').trim();
        final rawOptionName = (attribute.variantName ?? '').trim();
        final optionName = rawOptionName.isNotEmpty ? rawOptionName : optionId;

        if (typeId.isEmpty || optionId.isEmpty || optionName.isEmpty) continue;

        typeNames[typeId] = typeName.isEmpty ? 'Option' : typeName;
        typeOptions[typeId] ??= {};
        typeOptions[typeId]![optionId] = optionName;
      }
    }

    final List<VariantTypeGroup> groups = [];
    for (final entry in typeOptions.entries) {
      final options = entry.value.entries
          .map((option) => VariantOption(
                optionId: option.key,
                optionName: option.value,
              ))
          .toList();
      groups.add(
        VariantTypeGroup(
          typeId: entry.key,
          typeName: typeNames[entry.key] ?? 'Option',
          options: options,
        ),
      );
    }
    return groups;
  }

  Map<String, String> get selectedOptionByType =>
      Map<String, String>.from(_selectedOptionByType);

  bool isOptionSelected(String typeId, String optionId) {
    return _selectedOptionByType[typeId] == optionId;
  }

  void selectOption({
    required String typeId,
    required String optionId,
  }) {
    _selectedOptionByType[typeId] = optionId;

    notifyListeners();
  }

  List<ProductVariant> getMatchingVariants(
    Product product, {
    Map<String, String>? overrideSelected,
  }) {
    final selected = overrideSelected ?? _selectedOptionByType;
    final variants = getActiveVariants(product);

    return variants.where((variant) {
      for (final entry in selected.entries) {
        final typeId = entry.key;
        final optionId = entry.value;

        final attribute = variant.attributes.firstWhere(
          (item) => (item.variantTypeId ?? '') == typeId,
          orElse: () => const ProductVariantAttribute(),
        );

        if ((attribute.variantId ?? '') != optionId) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  bool _isFullySelected(Product product) {
    final groups = getVariantGroups(product);
    if (groups.isEmpty) return false;
    return groups.every((group) => (_selectedOptionByType[group.typeId] ?? '').isNotEmpty);
  }

  ProductVariant? _getExactSelectedVariant(Product product) {
    if (!_isFullySelected(product)) return null;
    final matched = getMatchingVariants(product);
    if (matched.isEmpty) return null;
    // Backend should keep attributes unique per SKU; pick exact first match.
    return matched.first;
  }

  bool isOptionAvailable({
    required Product product,
    required String typeId,
    required String optionId,
  }) {
    final selected = Map<String, String>.from(_selectedOptionByType);
    selected[typeId] = optionId;

    final matched = getMatchingVariants(product, overrideSelected: selected);
    return matched.any((variant) => (variant.quantity ?? 0) > 0);
  }

  ProductVariant? getResolvedVariant(Product product) {
    final exactSelected = _getExactSelectedVariant(product);
    if (exactSelected == null) return null;

    final matched = [exactSelected]
        .where((variant) => (variant.quantity ?? 0) > 0)
        .toList();
    if (matched.isEmpty) return null;
    matched.sort((a, b) {
      final aHasImages = _hasUsableImages(a);
      final bHasImages = _hasUsableImages(b);
      if (aHasImages == bHasImages) return 0;
      return aHasImages ? -1 : 1;
    });
    return matched.first;
  }

  List<Images> getDisplayImages(Product product) {
    // Rule: once user selected full combination, use that exact variant's images only.
    final exactSelected = _getExactSelectedVariant(product);
    if (exactSelected != null) {
      final exactImages = _validImages(exactSelected.images);
      if (exactImages.isNotEmpty) return exactImages;
      // Exact variant has no images in DB -> fallback to product images.
      return _validImages(product.images ?? const <Images>[]);
    }

    // Partial selection: still allow preview from the most relevant matched variant.
    final matched = getMatchingVariants(product);
    if (matched.isNotEmpty) {
      matched.sort((a, b) {
        final aHasImages = _hasUsableImages(a);
        final bHasImages = _hasUsableImages(b);
        if (aHasImages == bHasImages) return 0;
        return aHasImages ? -1 : 1;
      });
      final images = _validImages(matched.first.images);
      if (images.isNotEmpty) return images;
    }

    return _validImages(product.images ?? const <Images>[]);
  }

  bool _hasUsableImages(ProductVariant variant) {
    return _validImages(variant.images).isNotEmpty;
  }

  List<Images> _validImages(List<Images> images) {
    return images
        .where((item) => (item.url ?? '').trim().isNotEmpty)
        .toList();
  }

  Future<void> addToCart(Product product, BuildContext context) async {
    final variants = product.variants ?? const <ProductVariant>[];
    String variantId = '';

    if (variants.isNotEmpty) {
      final groups = getVariantGroups(product);
      if (groups.isEmpty) {
        final usableVariants = variants
            .where((variant) => variant.isActive && (variant.quantity ?? 0) > 0)
            .toList();
        if (usableVariants.length == 1 && (usableVariants.first.sId ?? '').isNotEmpty) {
          variantId = usableVariants.first.sId!;
        } else {
          SnackBarHelper.showErrorSnackBar(
            'Variant data is incomplete. Please reopen product from Home.',
          );
          return;
        }
      }

      final missingTypes = groups
          .where((group) => (_selectedOptionByType[group.typeId] ?? '').isEmpty)
          .map((group) => group.typeName)
          .toList();

      if (missingTypes.isNotEmpty) {
        SnackBarHelper.showErrorSnackBar(
          'Please select: ${missingTypes.join(', ')}',
        );
        return;
      }

      final selectedVariant = variantId.isNotEmpty
          ? variants.firstWhere(
              (item) => item.sId == variantId,
              orElse: () => const ProductVariant(),
            )
          : getResolvedVariant(product);
      if (selectedVariant == null || (selectedVariant.sId ?? '').isEmpty) {
        SnackBarHelper.showErrorSnackBar(
          'Selected combination is unavailable. Please choose another option.',
        );
        return;
      }

      if (!selectedVariant.isActive) {
        SnackBarHelper.showErrorSnackBar('Selected variant is inactive');
        return;
      }
      if ((selectedVariant.quantity ?? 0) < 1) {
        SnackBarHelper.showErrorSnackBar('Selected variant is out of stock');
        return;
      }
      variantId = selectedVariant.sId!;
    } else if ((product.quantity ?? 0) < 1) {
      SnackBarHelper.showErrorSnackBar('Product is out of stock');
      return;
    }

    final isAdded = await context.cartProvider.addItemFromProduct(
      product: product,
      variantId: variantId,
      quantity: 1,
    );

    if (isAdded) {
      _selectedOptionByType.clear();
      notifyListeners();
    }
  }

  void clearSelection() {
    _selectedOptionByType.clear();
    notifyListeners();
  }
}
