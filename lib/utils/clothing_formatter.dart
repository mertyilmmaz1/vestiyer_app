class ClothingFormatter {
  static const Map<String, String> _translations = {
    // Categories & Groups
    'top': 'Üst Giyim',
    'bottom': 'Alt Giyim',
    'outerwear': 'Dış Giyim',
    'shoes': 'Ayakkabı',
    'bag': 'Çanta',
    'accessory': 'Aksesuar',
    'ust_giyim': 'Üst Giyim',
    'alt_giyim': 'Alt Giyim',
    'dis_giyim': 'Dış Giyim',
    'ayakkabi': 'Ayakkabı',
    'canta': 'Çanta',
    'aksesuar': 'Aksesuar',

    // Colors
    'siyah': 'Siyah',
    'beyaz': 'Beyaz',
    'gri': 'Gri',
    'koyu_gri': 'Koyu Gri',
    'fum': 'Füme',
    'lacivert': 'Lacivert',
    'mavi': 'Mavi',
    'kiremit': 'Kiremit',
    'bordo': 'Bordo',
    'bej': 'Bej',
    'krem': 'Krem',
    'haki': 'Haki',
    'yesil': 'Yeşil',
    'sari': 'Sarı',
    'turuncu': 'Turuncu',
    'pembe': 'Pembe',
    'mor': 'Mor',
    'lila': 'Lila',
    'gumus': 'Gümüş',
    'altin': 'Altın',
    'bakir': 'Bakır',
    'cok_renkli': 'Çok Renkli',
    'desenli': 'Desenli',

    // Materials
    'pamuk': 'Pamuk',
    'keten': 'Keten',
    'yun': 'Yün',
    'ipek': 'İpek',
    'polyester': 'Polyester',
    'viskon': 'Viskon',
    'akrilik': 'Akrilik',
    'deri': 'Deri',
    'suni_deri': 'Suni Deri',
    'kure': 'Kür',
    'denim': 'Denim',
    'kadife': 'Kadife',
    'saten': 'Saten',
    'sifon': 'Şifon',
    'triko': 'Triko',
    'karisim': 'Karışım',
    'sentetik': 'Sentetik',

    // Seasons
    'kis': 'Kış',
    'yaz': 'Yaz',
    'sonbahar': 'Sonbahar',
    'ilkbahar': 'İlkbahar',
    'tum_mevsimler': 'Tüm Mevsimler',
    'mevsimsiz': 'Mevsimsiz',

    // Styles
    'casual': 'Günlük',
    'smart_casual': 'Smart Casual',
    'classic': 'Klasik',
    'sport': 'Spor',
    'formal': 'Resmi',
    'business': 'İş',
    'invite': 'Davet',
    'bohem': 'Bohem',
    'minimal': 'Minimal',
    'sokak_stili': 'Sokak Stili',
    'vintage': 'Vintage',
    'retro': 'Retro',
    'basic': 'Basic',
  };

  /// Main formatting method
  static String format(String? input) {
    if (input == null || input.isEmpty) return 'Belirtilmemiş';

    // Handle comma-separated lists
    if (input.contains(',')) {
      final items = input
          .split(',')
          .map((e) => _formatSingle(e.trim()))
          .toSet() // Deduplicate
          .toList();
      return items.join(', ');
    }

    return _formatSingle(input);
  }

  static String _formatSingle(String term) {
    String normalized = term.toLowerCase().trim();

    // Direct translation check
    if (_translations.containsKey(normalized)) {
      return _translations[normalized]!;
    }

    // If no direct translation, format automatically
    // Replace underscores/hyphens with spaces
    String cleaned = normalized.replaceAll('_', ' ').replaceAll('-', ' ');

    // Title Case
    return cleaned.split(' ').map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');
  }
}
