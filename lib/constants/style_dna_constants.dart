/// Beklenen dolap boyutu - %100 tamamlanma için gerekli parça sayısı.
const int kExpectedWardrobeSize = 20;

/// Dolap tamamlanma yüzdesi hesapla (0-100).
int computeWardrobeCompletionPercent(int itemCount) {
  if (kExpectedWardrobeSize <= 0) return 100;
  final p = (itemCount / kExpectedWardrobeSize) * 100;
  return p >= 100 ? 100 : p.round();
}

/// Sabitler: Stil DNA onboarding seçenekleri.
/// combinationEngine ve aiService ile uyumlu değerler kullanılır.

/// Stil DNA seçenekleri (max 3 seçim).
const List<StyleDnaOption> kStyleDnaOptions = [
  StyleDnaOption('minimal', 'Minimal'),
  StyleDnaOption('casual', 'Casual'),
  StyleDnaOption('street', 'Street'),
  StyleDnaOption('klasik', 'Klasik'),
  StyleDnaOption('smart_casual', 'Smart Casual'),
  StyleDnaOption('spor', 'Spor'),
  StyleDnaOption('bohem', 'Bohem'),
  StyleDnaOption('vintage', 'Vintage'),
];

/// Renk tercihi seçenekleri (çoklu seçim).
const List<ColorBiasOption> kColorBiasOptions = [
  ColorBiasOption('siyah', 'Siyah'),
  ColorBiasOption('beyaz', 'Beyaz'),
  ColorBiasOption('bej', 'Bej'),
  ColorBiasOption('mavi', 'Mavi'),
  ColorBiasOption('toprak_tonlari', 'Toprak tonları'),
  ColorBiasOption('renkli', 'Renkli / Canlı'),
];

/// Fit tercihi (tek seçim).
const List<FitOption> kFitOptions = [
  FitOption('oversize', 'Oversize'),
  FitOption('slim', 'Slim'),
  FitOption('regular', 'Regular'),
  FitOption('rahat', 'Rahat'),
];

/// Yaşam tarzı (tek seçim).
const List<LifestyleOption> kLifestyleOptions = [
  LifestyleOption('office', 'Ofis çalışanı'),
  LifestyleOption('university', 'Üniversite'),
  LifestyleOption('freelancer', 'Freelancer'),
  LifestyleOption('sports', 'Spor ağırlıklı'),
  LifestyleOption('social', 'Sosyal / Etkinlik yoğun'),
];

class StyleDnaOption {
  const StyleDnaOption(this.value, this.label);
  final String value;
  final String label;
}

class ColorBiasOption {
  const ColorBiasOption(this.value, this.label);
  final String value;
  final String label;
}

class FitOption {
  const FitOption(this.value, this.label);
  final String value;
  final String label;
}

class LifestyleOption {
  const LifestyleOption(this.value, this.label);
  final String value;
  final String label;
}
