class FriesOptions {
  FriesOptions._();

  static const sizes = ['Small', 'Medium', 'Large'];

  static const sizePrices = <String, double>{
    'Small': 170,
    'Medium': 180,
    'Large': 190,
  };

  static bool isFries(String? category, String productName) {
    final normalizedCategory = category?.trim().toLowerCase();
    return normalizedCategory == 'fries' ||
        (normalizedCategory == 'sides' &&
            productName.toLowerCase().contains('fries'));
  }

  static double priceForSize(String size) =>
      sizePrices[size] ?? sizePrices['Small']!;
}
