import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../services/api_service.dart';

final apiServiceProvider = Provider((ref) => ApiService());

final productsProvider = FutureProvider<List<Product>>((ref) async {
  final s = ref.read(apiServiceProvider);
  return s.fetchProducts();
});

final productDetailProvider = FutureProvider.family<Product, int>((
  ref,
  id,
) async {
  final s = ref.read(apiServiceProvider);
  return s.fetchProductDetail(id);
});
