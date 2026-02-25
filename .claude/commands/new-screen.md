# Yeni Ekran Şablonu

Vestiyer projesine yeni ekran eklemek için şablon ve adımlar.

## Dosya Oluştur

`lib/screens/my_new_screen.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/product/theme/app_colors.dart';
import '../core/product/widget/vestiyer_page_header.dart';
// Diğer importlar...

class MyNewScreen extends StatefulWidget {
  const MyNewScreen({super.key});

  @override
  State<MyNewScreen> createState() => _MyNewScreenState();
}

class _MyNewScreenState extends State<MyNewScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Veri yükle...
    } catch (e) {
      setState(() => _errorMessage = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const VestiyerPageHeader(title: 'Başlık'),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
            if (_errorMessage != null)
              Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red))),
            if (!_isLoading && _errorMessage == null)
              Expanded(
                child: _buildContent(),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return const Center(child: Text('İçerik'));
  }
}
```

## Navigasyon Ekle

`main.dart` veya ilgili ekranda:
```dart
Navigator.push(
  context,
  MaterialPageRoute(builder: (_) => const MyNewScreen()),
);
```

## Kontrol Listesi

- [ ] `VestiyerPageHeader` kullanıldı
- [ ] Loading state gösteriliyor
- [ ] Error state gösteriliyor
- [ ] `AppColors` renkleri kullanıldı
- [ ] `FirestoreServiceBase` üzerinden veri erişimi (direkt `FirestoreService` değil)
- [ ] Premium kontrolü varsa `SubscriptionProvider` kullanıldı
