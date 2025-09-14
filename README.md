# Flutter Product Listing & Detail App (DDD + Riverpod)

This repository contains a complete Flutter app implementing: product listing, product details, user authentication (register/login), favorites using Riverpod, profile screen with Swift MethodChannel integration (device info), and DDD-style project structure with dependency injection.

---

## Project structure (recommended)

```
/lib
  /app.dart
  /main.dart
  /core
    /di.dart                # Dependency injection setup (GetIt)
    /secure_storage.dart   # wrapper around SharedPreferences or flutter_secure_storage
  /domain
    /entities
      product.dart
      user.dart
    /repositories
      product_repository.dart
      auth_repository.dart
  /data
    /models
      product_model.dart
      user_model.dart
    /datasources
      product_api.dart
      local_auth_storage.dart
    /repositories_impl
      product_repository_impl.dart
      auth_repository_impl.dart
  /presentation
    /pages
      product_list_page.dart
      product_detail_page.dart
      login_page.dart
      register_page.dart
      profile_page.dart
    /widgets
      product_tile.dart
      favorite_button.dart
  /providers
    product_providers.dart   # Riverpod providers for lists, details
    auth_providers.dart
    favorites_provider.dart

ios/Runner/AppDelegate.swift   # Swift method channel implementation

pubspec.yaml
README.md
```

---

## Key dependencies (pubspec.yaml)

```yaml
name: web3_product_app
description: Product listing & auth demo
publish_to: 'none'
version: 1.0.0

environment:
  sdk: '>=2.19.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.2
  http: ^0.13.6
  flutter_riverpod: ^2.3.6
  get_it: ^7.6.0
  shared_preferences: ^2.1.1
  flutter_secure_storage: ^8.0.0
  cached_network_image: ^3.2.3

dev_dependencies:
  flutter_test:
    sdk: flutter
```

---

## Short explanation of DDD + DI choices

- Domain layer (entities + repository interfaces) contains pure business models and contracts.
- Data layer implements repository contracts and contains API clients and local storage.
- Presentation layer contains Riverpod providers and UI widgets/pages.
- GetIt is used for simple dependency injection; providers consume injected implementations.

---

## Important code snippets

### 1) Domain entity: `product.dart`

```dart
class Product {
  final int id;
  final String title;
  final String description;
  final double price;
  final String thumbnail;
  final List<String> images;

  Product({required this.id, required this.title, required this.description, required this.price, required this.thumbnail, required this.images});
}
```

### 2) Repository interface: `product_repository.dart`

```dart
abstract class ProductRepository {
  Future<List<Product>> fetchProducts({int limit, int skip});
  Future<Product> fetchProductById(int id);
}
```

### 3) Data source (API client): `product_api.dart`

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class ProductApi {
  final http.Client client;
  ProductApi(this.client);

  Future<List<dynamic>> getProducts() async {
    final res = await client.get(Uri.parse('https://dummyjson.com/products')); // or fakestoreapi
    if (res.statusCode == 200) {
      final json = jsonDecode(res.body);
      return (json['products'] as List<dynamic>);
    }
    throw Exception('Failed to load products');
  }

  Future<Map<String,dynamic>> getProduct(int id) async {
    final res = await client.get(Uri.parse('https://dummyjson.com/products/$id'));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception('Not found');
  }
}
```

### 4) Repository implementation: `product_repository_impl.dart`

```dart
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';
import '../datasources/api_service.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductApi api;
  ProductRepositoryImpl(this.api);

  @override
  Future<List<Product>> fetchProducts({int limit = 30, int skip = 0}) async {
    final raw = await api.getProducts();
    return raw.map((e) => Product(
      id: e['id'],
      title: e['title'] ?? e['name'] ?? '',
      description: e['description'] ?? '',
      price: (e['price'] is int) ? (e['price'] as int).toDouble() : (e['price'] as double),
      thumbnail: e['thumbnail'] ?? (e['image'] ?? ''),
      images: (e['images'] as List<dynamic>?)?.map((i)=>i.toString()).toList() ?? [],
    )).toList();
  }

  @override
  Future<Product> fetchProductById(int id) async {
    final e = await api.getProduct(id);
    return Product(
      id: e['id'],
      title: e['title'] ?? e['name'] ?? '',
      description: e['description'] ?? '',
      price: (e['price'] is int) ? (e['price'] as int).toDouble() : (e['price'] as double),
      thumbnail: e['thumbnail'] ?? (e['image'] ?? ''),
      images: (e['images'] as List<dynamic>?)?.map((i)=>i.toString()).toList() ?? [],
    );
  }
}
```

### 5) DI setup (`core/di.dart`)

```dart
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import '../data/datasources/api_service.dart';
import '../data/repositories/product_repository_impl.dart';
import '../domain/repositories/product_repository.dart';

final getIt = GetIt.instance;

void setupDI(){
  getIt.registerLazySingleton(() => http.Client());
  getIt.registerLazySingleton(() => ProductApi(getIt<http.Client>()));
  getIt.registerLazySingleton<ProductRepository>(() => ProductRepositoryImpl(getIt<ProductApi>()));
  // register auth repo, local storage, etc.
}
```

### 6) Riverpod providers (`providers/product_providers.dart`)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/entities/product.dart';
import '../domain/repositories/product_repository.dart';
import '../core/di.dart' as di;

final productRepoProvider = Provider<ProductRepository>((ref) => di.getIt<ProductRepository>());

final productListProvider = FutureProvider.autoDispose<List<Product>>((ref) async {
  final repo = ref.watch(productRepoProvider);
  return repo.fetchProducts();
});

final productDetailProvider = FutureProvider.family<Product, int>((ref, id) async {
  final repo = ref.watch(productRepoProvider);
  return repo.fetchProductById(id);
});
```

### 7) Favorites provider (`providers/favorites_provider.dart`)

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

final favoritesProvider = StateNotifierProvider<FavoritesNotifier, Set<int>>((ref) => FavoritesNotifier());

class FavoritesNotifier extends StateNotifier<Set<int>>{
  FavoritesNotifier(): super({});

  void toggleFavorite(int id){
    final s = Set.of(state);
    if (s.contains(id)) s.remove(id); else s.add(id);
    state = s;
  }
}
```

### 8) Authentication (simple local):
- For a demo, use `shared_preferences` to store a registered user record (email + hashed password - for production use secure backend and proper hashing). For improved security use `flutter_secure_storage`.

`data/datasources/local_auth_storage.dart` contains saveUser / getUser / persist session.

### 9) UI: Product list page (snippet)

```dart
// product_list_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/product_providers.dart';
import '../../providers/favorites_provider.dart';
import '../widgets/product_tile.dart';

class ProductListPage extends ConsumerWidget{
  @override
  Widget build(BuildContext context, WidgetRef ref){
    final async = ref.watch(productListProvider);
    return Scaffold(
      appBar: AppBar(title: Text('Products')),
      body: async.when(
        data: (products) => ListView.builder(
          itemCount: products.length,
          itemBuilder: (_, i){
            final p = products[i];
            return ProductTile(product: p);
          }
        ),
        loading: ()=>Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: \$e')),
      ),
    );
  }
}
```

`ProductTile` uses `cached_network_image` and a heart button that calls `ref.read(favoritesProvider.notifier).toggleFavorite(product.id)` and navigates to detail page on tap.

### 10) Product detail page

Use `productDetailProvider` to fetch details and render images carousel, description, specs, and reviews placeholder.

### 11) Profile page + Swift MethodChannel integration

- Add a MethodChannel in Dart:

```dart
import 'package:flutter/services.dart';

class DeviceInfo {
  static const platform = MethodChannel('app.device/info');

  static Future<String> getDeviceInfo() async {
    try{
      final res = await platform.invokeMethod('getDeviceInfo');
      return res.toString();
    } on PlatformException catch(e){
      return 'Failed: \${e.message}';
    }
  }
}
```

- In iOS `ios/Runner/AppDelegate.swift` (or AppDelegate.m for ObjC) add:

```swift
import UIKit
import Flutter

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  private let channelName = "app.device/info"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let deviceChannel = FlutterMethodChannel(name: channelName,
                                              binaryMessenger: controller.binaryMessenger)

    deviceChannel.setMethodCallHandler({ (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "getDeviceInfo" {
        let device = UIDevice.current
        let info = "\(device.model) - \(device.systemName) \(device.systemVersion)"
        result(info)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
```

- On the Profile page call `DeviceInfo.getDeviceInfo()` and display it.

---

## Session persistence & auth flow

- On successful registration/login, save a token-like object (for demo a JSON with email + timestamp + expiration) to `flutter_secure_storage` or `shared_preferences`.
- Provide an `AuthState` Riverpod provider that reads persisted session on app start.
- Protect routes using a simple `AuthGuard` in `app.dart` which redirects to login if not authenticated.

---

## Performance tips

- Use `ListView.builder` + `cached_network_image` for images.
- Paginate API requests when product lists are large (use `FutureProvider.family` or `PagingController` patterns).
- Keep widgets const where possible.
- Use autoDispose for providers that shouldn't live forever.

---

## How to run

1. `flutter pub get`
2. Setup iOS: open `ios/Runner.xcworkspace` and ensure Swift bridging is set.
3. Run on simulator/device: `flutter run`

---

## What to commit to GitHub

- Entire `lib/` folder
- `pubspec.yaml`
- Short `README.md` (build instructions, how to add device info in iOS, mention Android no-op per-method channel implementation if desired)

---

## Closing notes

This document provides a full scaffold and essential code snippets to implement the requested app. I can create the full file contents for every file in the repo (ready-to-run) and generate a ready-to-import iOS AppDelegate.swift change if you'd like — tell me if you prefer a complete zipped project or a GitHub-ready folder structure with all files filled.

