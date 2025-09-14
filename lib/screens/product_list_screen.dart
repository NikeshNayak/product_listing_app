import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:product_listing_app/providers/auth_provider.dart';

import '../models/product.dart';
import '../providers/product_provider.dart';
import '../widgets/product_tile.dart';

class ProductListScreen extends ConsumerWidget {
  const ProductListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final future = ref.watch(productsProvider.future);
    final user = ref.watch(authStateProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Products')),
      body: FutureBuilder<List<Product>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData) {
            final items = snapshot.data!;
            return RefreshIndicator(
              onRefresh: () async => ref.refresh(productsProvider),
              child: Padding(
                padding: EdgeInsets.all(8.0),
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // Number of columns
                    crossAxisSpacing: 8.0,
                    mainAxisSpacing: 8.0,
                    childAspectRatio: 0.7,
                  ),
                  itemCount: items.length,
                  itemBuilder: (context, i) => ProductTile(product: items[i]),
                ),
              ),
            );
          } else {
            return const Center(child: Text('No data available'));
          }
        },
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Product Listing App',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            if (user == null) ...[
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Login/Signup'),
                onTap: () {
                  Navigator.of(context).pushNamed('/login');
                },
              ),
            ] else ...[
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Profile'),
                onTap: () {
                  Navigator.of(context).pushNamed('/profile');
                },
              ),
              Divider(),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () async {
                  await ref.read(authStateProvider.notifier).logout();
                  Navigator.of(context).pop(); // Close drawer
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
