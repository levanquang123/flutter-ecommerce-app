import '../../../models/brand.dart';
import '../../../models/category.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/data/data_provider.dart';
import '../../../models/product.dart';
import '../../../models/sub_category.dart';

class ProductByCategoryProvider extends ChangeNotifier {
  final DataProvider _dataProvider;
  Category? mySelectedCategory;
  SubCategory? mySelectedSubCategory;
  List<SubCategory> subCategories = [];
  List<Brand> brands = [];
  List<Brand> selectedBrands = [];
  List<Product> filteredProduct = [];

  ProductByCategoryProvider(this._dataProvider);

  filterInitialProductAndSubCategory(Category selectedCategory) {
    mySelectedSubCategory = const SubCategory(name: 'All');
    mySelectedCategory = selectedCategory;
    subCategories =
        _dataProvider.subCategories.where((element) => element.categoryId?.sId == selectedCategory.sId).toList();
    subCategories.insert(0, const SubCategory(name: 'All'));
    filteredProduct =
        _dataProvider.products.where((element) => element.proCategoryId?.name == selectedCategory.name).toList();
    notifyListeners();
  }

  filterProductBySubCategory(SubCategory subCategory) {
    mySelectedSubCategory = subCategory;
    if (subCategory.name?.toLowerCase() == 'all') {
      filteredProduct =
          _dataProvider.products.where((element) => element.proCategoryId?.name == mySelectedCategory?.name).toList();
      brands = [];
    } else {
      filteredProduct =
          _dataProvider.products.where((element) => element.proSubCategoryId?.name == subCategory.name).toList();
      brands = _dataProvider.brands.where((element) => element.subCategoryId?.sId == subCategory.sId).toList();
    }
    notifyListeners();
  }

  void filterProductByBrand() {
    if (selectedBrands.isEmpty) {
      filteredProduct = _dataProvider.products
          .where((product) => product.proSubCategoryId?.name == mySelectedSubCategory?.name)
          .toList();
    } else {
      filteredProduct = _dataProvider.products
          .where((product) =>
      product.proSubCategoryId?.name == mySelectedSubCategory?.name &&
          selectedBrands.any((brand) => product.proBrandId?.sId == brand.sId))
          .toList();
    }
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
}
