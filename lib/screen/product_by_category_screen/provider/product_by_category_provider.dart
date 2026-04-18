import '../../../models/brand.dart';
import '../../../models/category.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/data/data_provider.dart';
import '../../../models/product.dart';
import '../../../models/sub_category.dart';

class ProductByCategoryProvider extends ChangeNotifier {
  final DataProvider _dataProvider;
  static const SubCategory _allSubCategory = SubCategory(name: 'All');
  Category? mySelectedCategory;
  SubCategory? mySelectedSubCategory;
  List<SubCategory> subCategories = [];
  List<Brand> brands = [];
  List<Brand> selectedBrands = [];
  List<Product> filteredProduct = [];

  ProductByCategoryProvider(this._dataProvider);

  filterInitialProductAndSubCategory(Category selectedCategory) {
    mySelectedSubCategory = _allSubCategory;
    mySelectedCategory = selectedCategory;
    selectedBrands = [];
    subCategories = _dataProvider.subCategories
        .where((element) => element.categoryId?.sId == selectedCategory.sId)
        .toList();
    subCategories.insert(0, _allSubCategory);
    brands = _brandsForCurrentSelection();
    _applyFilters();
    notifyListeners();
  }

  filterProductBySubCategory(SubCategory subCategory) {
    mySelectedSubCategory = subCategory;
    selectedBrands = [];
    brands = _brandsForCurrentSelection();
    _applyFilters();
    notifyListeners();
  }

  void filterProductByBrand([List<Brand>? brands]) {
    if (brands != null) {
      selectedBrands = List<Brand>.from(brands);
    }
    _applyFilters();
    notifyListeners();
  }

  void sortProducts({required bool ascending}) {
    filteredProduct.sort((a, b) {
      if (ascending) {
        return a.price!.compareTo(b.price ?? 0); // Sort in ascending order
      } else {
        return b.price!.compareTo(a.price ?? 0); // Sort in descending order
      }
    });
    notifyListeners();
  }


  void updateUI() {
    notifyListeners();
  }

  bool get _isAllSubCategory =>
      mySelectedSubCategory?.name?.toLowerCase() == 'all';

  List<Product> _productsForCurrentSelection() {
    final selectedCategoryId = mySelectedCategory?.sId;
    if (selectedCategoryId == null) return [];

    final productsInCategory = _dataProvider.products
        .where((product) => product.proCategoryId?.sId == selectedCategoryId)
        .toList();

    if (_isAllSubCategory) {
      return productsInCategory;
    }

    final selectedSubCategoryId = mySelectedSubCategory?.sId;
    if (selectedSubCategoryId == null) {
      return productsInCategory;
    }

    return productsInCategory
        .where((product) => product.proSubCategoryId?.sId == selectedSubCategoryId)
        .toList();
  }

  List<Brand> _brandsForCurrentSelection() {
    final selectedCategoryId = mySelectedCategory?.sId;
    if (selectedCategoryId == null) return [];

    if (_isAllSubCategory) {
      return _dataProvider.brands
          .where((brand) => brand.subCategoryId?.categoryId == selectedCategoryId)
          .toList();
    }

    final selectedSubCategoryId = mySelectedSubCategory?.sId;
    if (selectedSubCategoryId == null) return [];

    return _dataProvider.brands
        .where((brand) => brand.subCategoryId?.sId == selectedSubCategoryId)
        .toList();
  }

  void _applyFilters() {
    final scopeProducts = _productsForCurrentSelection();
    if (selectedBrands.isEmpty) {
      filteredProduct = scopeProducts;
      return;
    }

    final selectedBrandIds = selectedBrands
        .map((brand) => brand.sId)
        .whereType<String>()
        .toSet();

    filteredProduct = scopeProducts
        .where((product) => selectedBrandIds.contains(product.proBrandId?.sId))
        .toList();
  }
}
