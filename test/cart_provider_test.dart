import 'package:burger_bites/models/product_model.dart';
import 'package:burger_bites/providers/cart_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late CartProvider cart;
  final burger = Product(
    id: 'burger-1',
    name: 'Classic Burger',
    description: 'Beef burger',
    price: 100,
    category: 'Burgers',
    createdAt: DateTime(2026),
  );

  setUp(() => cart = CartProvider());

  test('adding the same product merges quantities and calculates totals', () {
    cart.addItem(burger, quantity: 2);
    cart.addItem(burger);

    expect(cart.items, hasLength(1));
    expect(cart.items.single.quantity, 3);
    expect(cart.subtotal, 300);
    expect(cart.tax, closeTo(36, 0.001));
    expect(cart.deliveryFee, 25);
    expect(cart.total, closeTo(361, 0.001));
  });

  test('zero quantity removes an item and empty cart has no delivery fee', () {
    cart.addItem(burger);
    cart.updateQuantity(burger.id, 0);

    expect(cart.isEmpty, isTrue);
    expect(cart.deliveryFee, 0);
    expect(cart.total, 0);
  });

  test('unavailable products are rejected', () {
    final unavailable = Product(
      id: 'unavailable',
      name: 'Unavailable burger',
      description: 'Out of stock',
      price: 50,
      available: false,
      createdAt: DateTime(2026),
    );

    cart.addItem(unavailable);

    expect(cart.isEmpty, isTrue);
    expect(cart.errorMessage, 'This item is currently unavailable.');
  });

  test(
    'customized versions stay separate and merge regardless of topping order',
    () {
      cart.addItem(
        burger,
        customizations: {
          'size': 'Large',
          'toppings': ['Crispy bacon', 'Extra cheese'],
        },
      );
      cart.addItem(
        burger,
        customizations: {
          'toppings': ['Extra cheese', 'Crispy bacon'],
          'size': 'Large',
        },
      );
      cart.addItem(
        burger,
        customizations: {'size': 'Double', 'toppings': <String>[]},
      );

      expect(cart.items, hasLength(2));
      expect(cart.items.first.quantity, 2);
      expect(cart.items.last.customizations['size'], 'Double');
    },
  );

  test('quantity changes target the selected customization', () {
    cart.addItem(
      burger,
      customizations: {'size': 'Regular', 'toppings': <String>[]},
    );
    cart.addItem(
      burger,
      customizations: {'size': 'Large', 'toppings': <String>[]},
    );

    cart.updateCartItemQuantity(cart.items.last, 3);

    expect(cart.items.first.quantity, 1);
    expect(cart.items.last.quantity, 3);
  });
}
