import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shopsy/models/cart_item_model.dart';
import 'package:shopsy/models/product_model.dart';

class CartProvider with ChangeNotifier {
  List<CartItem> _items = [];
  static const String _cartKey = 'shopping_cart';

  List<CartItem> get items => _items;

  int get itemCount => _items.length;

  double get totalAmount {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  int get totalItems {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  // Load cart from local storage
  Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = prefs.getString(_cartKey);

      if (cartData != null) {
        final List<dynamic> decodedData = json.decode(cartData);
        _items = decodedData.map((item) => CartItem.fromJson(item)).toList();
        notifyListeners();
      }
    } catch (e) {
      print('Error loading cart: $e');
    }
  }

  // Save cart to local storage
  Future<void> _saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartData = json.encode(
        _items.map((item) => item.toJson()).toList(),
      );
      await prefs.setString(_cartKey, cartData);
    } catch (e) {
      print('Error saving cart: $e');
    }
  }

  // Add product to cart
  void addToCart(Product product) {
    final existingIndex = _items.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (existingIndex >= 0) {
      _items[existingIndex].quantity++;
    } else {
      _items.add(CartItem(product: product));
    }

    _saveCart();
    notifyListeners();
  }

  // Remove item from cart
  void removeFromCart(int productId) {
    _items.removeWhere((item) => item.product.id == productId);
    _saveCart();
    notifyListeners();
  }

  // Update quantity
  void updateQuantity(int productId, int quantity) {
    final index = _items.indexWhere((item) => item.product.id == productId);

    if (index >= 0) {
      if (quantity > 0) {
        _items[index].quantity = quantity;
      } else {
        _items.removeAt(index);
      }
      _saveCart();
      notifyListeners();
    }
  }

  // Increment quantity
  void incrementQuantity(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);

    if (index >= 0) {
      _items[index].quantity++;
      _saveCart();
      notifyListeners();
    }
  }

  // Decrement quantity
  void decrementQuantity(int productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);

    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        // Remove item if quantity becomes 0
        _items.removeAt(index);
      }
      _saveCart();
      notifyListeners();
    }
  }

  void clearCart() {
    _items.clear();
    _saveCart();
    notifyListeners();
  }

  bool isInCart(int productId) {
    return _items.any((item) => item.product.id == productId);
  }

  int getQuantity(int productId) {
    final item = _items.firstWhere(
      (item) => item.product.id == productId,
      orElse: () => CartItem(
        product: Product(
          id: 0,
          name: '',
          description: '',
          price: 0,
          image: '',
          category: '',
          rating: 0,
        ),
        quantity: 0,
      ),
    );
    return item.quantity;
  }
}
