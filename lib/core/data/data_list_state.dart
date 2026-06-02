class DataListState<T> {
  List<T> all = <T>[];
  List<T> filtered = <T>[];

  void setItems(List<T> items) {
    all = List<T>.from(items);
    filtered = List<T>.from(items);
  }

  void resetFilter() {
    filtered = List<T>.from(all);
  }

  void filter(bool Function(T item) predicate) {
    filtered = all.where(predicate).toList();
  }
}
