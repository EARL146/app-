class DrinkOptions {
  DrinkOptions._();

  static const brands = [
    'Coca-Cola',
    'Sprite',
    'Pepsi',
    'Royal',
    'Mountain Dew',
    '7Up',
  ];

  static const sizes = ['Regular', 'Large', 'XL'];

  static const sizePrices = <String, double>{
    'Regular': 150,
    'Large': 170,
    'XL': 180,
  };

  static String brandForProductName(String name) {
    final normalizedName = name.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '',
    );
    return brands.firstWhere(
      (brand) => normalizedName.contains(
        brand.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), ''),
      ),
      orElse: () => brands.first,
    );
  }

  static double priceForSize(String size) =>
      sizePrices[size] ?? sizePrices['Regular']!;
}
