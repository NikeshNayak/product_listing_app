import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/product.dart';

class ApiService {
  final String base;

  ApiService({this.base = 'https://dummyjson.com'});

  Future<List<Product>> fetchProducts() async {
    final res = await http.get(Uri.parse('$base/products'));
    if (res.statusCode != 200) throw Exception('Failed');
    final data = json.decode(res.body) as Map<String, dynamic>;
    final products = data['products'] as List<dynamic>;
    return products
        .map((e) => Product.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Product> fetchProductDetail(int id) async {
    final res = await http.get(Uri.parse('$base/products/$id'));
    if (res.statusCode != 200) throw Exception('Failed');
    final data = json.decode(res.body) as Map<String, dynamic>;
    return Product.fromJson(data);
  }
}
