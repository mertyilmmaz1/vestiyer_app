import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Beklenen dolap boyutu - %100 tamamlanma için gerekli parça sayısı.
const int kExpectedWardrobeSize = 20;

/// Dolap tamamlanma yüzdesi hesapla (0-100).
int computeWardrobeCompletionPercent(int itemCount) {
  if (kExpectedWardrobeSize <= 0) return 100;
  final p = (itemCount / kExpectedWardrobeSize) * 100;
  return p >= 100 ? 100 : p.round();
}

/// Sabitler: Stil DNA onboarding seçenekleri.
/// [value] normalized English key (backend/combinationEngine uyumlu).
/// Görüntüleme için [getLabel] ile l10n kullanın.

/// Stil DNA seçenekleri (max 3 seçim). Value: normalize key.
const List<StyleDnaOption> kStyleDnaOptions = [
  StyleDnaOption('minimal'),
  StyleDnaOption('casual'),
  StyleDnaOption('street'),
  StyleDnaOption('classic'),
  StyleDnaOption('smart_casual'),
  StyleDnaOption('sport'),
  StyleDnaOption('bohem'),
  StyleDnaOption('vintage'),
];

/// Renk tercihi seçenekleri (çoklu seçim).
const List<ColorBiasOption> kColorBiasOptions = [
  ColorBiasOption('black'),
  ColorBiasOption('white'),
  ColorBiasOption('beige'),
  ColorBiasOption('blue'),
  ColorBiasOption('earth_tones'),
  ColorBiasOption('colorful'),
];

/// Fit tercihi (tek seçim).
const List<FitOption> kFitOptions = [
  FitOption('oversize'),
  FitOption('slim'),
  FitOption('regular'),
  FitOption('relaxed'),
];

/// Yaşam tarzı (tek seçim).
const List<LifestyleOption> kLifestyleOptions = [
  LifestyleOption('office'),
  LifestyleOption('university'),
  LifestyleOption('freelancer'),
  LifestyleOption('sports'),
  LifestyleOption('social'),
];

class StyleDnaOption {
  const StyleDnaOption(this.value);
  final String value;

  /// Localized label for UI. Use [value] for storage/API.
  String getLabel(AppLocalizations l10n) {
    switch (value) {
      case 'minimal':
        return l10n.styleDnaMinimal;
      case 'casual':
        return l10n.styleDnaCasual;
      case 'street':
        return l10n.styleDnaStreet;
      case 'classic':
        return l10n.styleDnaClassic;
      case 'smart_casual':
        return l10n.styleDnaSmartCasual;
      case 'sport':
        return l10n.styleDnaSport;
      case 'bohem':
        return l10n.styleDnaBohemian;
      case 'vintage':
        return l10n.styleDnaVintage;
      default:
        return value;
    }
  }
}

class ColorBiasOption {
  const ColorBiasOption(this.value);
  final String value;

  String getLabel(AppLocalizations l10n) {
    switch (value) {
      case 'black':
        return l10n.colorBiasBlack;
      case 'white':
        return l10n.colorBiasWhite;
      case 'beige':
        return l10n.colorBiasBeige;
      case 'blue':
        return l10n.colorBiasBlue;
      case 'earth_tones':
        return l10n.colorBiasEarthTones;
      case 'colorful':
        return l10n.colorBiasColorful;
      default:
        return value;
    }
  }
}

class FitOption {
  const FitOption(this.value);
  final String value;

  String getLabel(AppLocalizations l10n) {
    switch (value) {
      case 'oversize':
        return l10n.fitOversize;
      case 'slim':
        return l10n.fitSlim;
      case 'regular':
        return l10n.fitRegular;
      case 'relaxed':
        return l10n.fitRelaxed;
      default:
        return value;
    }
  }
}

class LifestyleOption {
  const LifestyleOption(this.value);
  final String value;

  String getLabel(AppLocalizations l10n) {
    switch (value) {
      case 'office':
        return l10n.lifestyleOffice;
      case 'university':
        return l10n.lifestyleUniversity;
      case 'freelancer':
        return l10n.lifestyleFreelancer;
      case 'sports':
        return l10n.lifestyleSports;
      case 'social':
        return l10n.lifestyleSocial;
      default:
        return value;
    }
  }
}
