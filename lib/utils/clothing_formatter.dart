import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Formats clothing-related values (category, color, material, season, style)
/// for display using localized strings from ARB.
///
/// Storage uses normalized English keys (e.g. black, cotton, top). Use
/// [format] with [BuildContext] for localized display. Legacy Turkish values
/// are normalized to English keys for lookup.
class ClothingFormatter {
  /// Turkish/legacy value -> normalized English key (for backward compatibility).
  static const Map<String, String> _legacyToNormalized = {
    // Categories
    'ust_giyim': 'top',
    'üst giyim': 'top',
    'alt_giyim': 'bottom',
    'alt giyim': 'bottom',
    'dis_giyim': 'outerwear',
    'dış giyim': 'outerwear',
    'ayakkabi': 'shoes',
    'ayakkabı': 'shoes',
    'canta': 'bag',
    'çanta': 'bag',
    'aksesuar': 'accessory',

    // Colors (Turkish -> English)
    'siyah': 'black',
    'beyaz': 'white',
    'gri': 'gray',
    'koyu_gri': 'dark_gray',
    'fum': 'charcoal',
    'füme': 'charcoal',
    'lacivert': 'navy',
    'mavi': 'blue',
    'kiremit': 'brick',
    'bordo': 'burgundy',
    'bej': 'beige',
    'krem': 'cream',
    'haki': 'khaki',
    'yesil': 'green',
    'yeşil': 'green',
    'sari': 'yellow',
    'sarı': 'yellow',
    'turuncu': 'orange',
    'pembe': 'pink',
    'mor': 'purple',
    'lila': 'lilac',
    'gumus': 'silver',
    'gümüş': 'silver',
    'altin': 'gold',
    'altın': 'gold',
    'bakir': 'copper',
    'bakır': 'copper',
    'cok_renkli': 'multicolor',
    'çok_renkli': 'multicolor',
    'desenli': 'patterned',

    // Materials
    'pamuk': 'cotton',
    'keten': 'linen',
    'yun': 'wool',
    'yün': 'wool',
    'ipek': 'silk',
    'viskon': 'viscose',
    'akrilik': 'acrylic',
    'deri': 'leather',
    'suni_deri': 'faux_leather',
    'kure': 'fur',
    'kür': 'fur',
    'kadife': 'velvet',
    'sifon': 'chiffon',
    'şifon': 'chiffon',
    'triko': 'knit',
    'karisim': 'blend',
    'karışım': 'blend',
    'sentetik': 'synthetic',

    // Seasons
    'kis': 'winter',
    'kış': 'winter',
    'yaz': 'summer',
    'sonbahar': 'autumn',
    'ilkbahar': 'spring',
    'tum_mevsimler': 'all_seasons',
    'tüm mevsimler': 'all_seasons',
    'mevsimsiz': 'seasonless',

    // Styles
    'klasik': 'classic',
    'spor': 'sport',
    'sokak_stili': 'street_style',
  };

  /// Localized format using [context]. Prefer this in UI.
  static String format(BuildContext? context, String? input) {
    if (input == null || input.isEmpty) {
      return _unspecified(context);
    }
    if (input.contains(',')) {
      final items = input
          .split(',')
          .map((e) => _formatSingleWithContext(context, e.trim()))
          .toSet()
          .toList();
      return items.join(', ');
    }
    return _formatSingleWithContext(context, input);
  }

  static String _unspecified(BuildContext? context) {
    if (context != null) {
      final l10n = AppLocalizations.of(context);
      // ignore: unnecessary_null_comparison - l10n can be null if no Localizations ancestor
      if (l10n != null) return l10n.unspecified;
    }
    return 'Belirtilmemiş';
  }

  static String _formatSingleWithContext(BuildContext? context, String term) {
    final normalized = _toNormalizedKey(term);
    if (context == null) {
      return _titleCase(normalized.replaceAll('_', ' '));
    }
    final l10n = AppLocalizations.of(context);
    // ignore: unnecessary_null_comparison - l10n can be null if no Localizations ancestor
    if (l10n == null) return _titleCase(normalized.replaceAll('_', ' '));
    final translated = _lookupL10n(l10n, normalized);
    return translated ?? _titleCase(normalized.replaceAll('_', ' '));
  }

  static String _toNormalizedKey(String term) {
    final t = term.toLowerCase().trim();
    if (_legacyToNormalized.containsKey(t)) {
      return _legacyToNormalized[t]!;
    }
    return t.replaceAll(' ', '_');
  }

  static String? _lookupL10n(AppLocalizations l10n, String key) {
    switch (key) {
      case 'top':
        return l10n.categoryTopWear;
      case 'bottom':
        return l10n.categoryBottomWear;
      case 'outerwear':
        return l10n.categoryOuterwear;
      case 'shoes':
        return l10n.categoryShoes;
      case 'bag':
        return l10n.categoryBags;
      case 'accessory':
        return l10n.categoryAccessories;
      case 'black':
        return l10n.colorBlack;
      case 'white':
        return l10n.colorWhite;
      case 'gray':
      case 'grey':
        return l10n.colorGray;
      case 'dark_gray':
        return l10n.colorDarkGray;
      case 'charcoal':
        return l10n.colorCharcoal;
      case 'navy':
        return l10n.colorNavy;
      case 'blue':
        return l10n.colorBlue;
      case 'brick':
        return l10n.colorBrick;
      case 'burgundy':
        return l10n.colorBurgundy;
      case 'beige':
        return l10n.colorBeige;
      case 'cream':
        return l10n.colorCream;
      case 'khaki':
        return l10n.colorKhaki;
      case 'green':
        return l10n.colorGreen;
      case 'yellow':
        return l10n.colorYellow;
      case 'orange':
        return l10n.colorOrange;
      case 'pink':
        return l10n.colorPink;
      case 'purple':
        return l10n.colorPurple;
      case 'lilac':
        return l10n.colorLilac;
      case 'silver':
        return l10n.colorSilver;
      case 'gold':
        return l10n.colorGold;
      case 'copper':
        return l10n.colorCopper;
      case 'multicolor':
        return l10n.colorMulticolor;
      case 'patterned':
        return l10n.colorPatterned;
      case 'cotton':
        return l10n.materialCotton;
      case 'linen':
        return l10n.materialLinen;
      case 'wool':
        return l10n.materialWool;
      case 'silk':
        return l10n.materialSilk;
      case 'polyester':
        return l10n.materialPolyester;
      case 'viscose':
        return l10n.materialViscose;
      case 'acrylic':
        return l10n.materialAcrylic;
      case 'leather':
        return l10n.materialLeather;
      case 'faux_leather':
        return l10n.materialFauxLeather;
      case 'fur':
        return l10n.materialFur;
      case 'denim':
        return l10n.materialDenim;
      case 'velvet':
        return l10n.materialVelvet;
      case 'satin':
        return l10n.materialSatin;
      case 'chiffon':
        return l10n.materialChiffon;
      case 'knit':
        return l10n.materialKnit;
      case 'blend':
        return l10n.materialBlend;
      case 'synthetic':
        return l10n.materialSynthetic;
      case 'winter':
        return l10n.seasonWinter;
      case 'summer':
        return l10n.seasonSummer;
      case 'autumn':
        return l10n.seasonAutumn;
      case 'spring':
        return l10n.seasonSpring;
      case 'all_seasons':
        return l10n.seasonAllSeasons;
      case 'seasonless':
        return l10n.seasonSeasonless;
      case 'casual':
        return l10n.styleCasual;
      case 'smart_casual':
        return l10n.styleSmartCasual;
      case 'classic':
        return l10n.styleClassic;
      case 'sport':
        return l10n.styleSport;
      case 'formal':
        return l10n.styleFormal;
      case 'business':
        return l10n.styleBusiness;
      case 'party':
      case 'invite':
        return l10n.styleParty;
      case 'bohem':
      case 'bohemian':
        return l10n.styleBohemian;
      case 'minimal':
        return l10n.styleMinimal;
      case 'street_style':
      case 'street':
        return l10n.styleStreetStyle;
      case 'vintage':
        return l10n.styleVintage;
      case 'retro':
        return l10n.styleRetro;
      case 'basic':
        return l10n.styleBasic;
      default:
        return null;
    }
  }

  static String _titleCase(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return '';
      return '${word[0].toUpperCase()}${word.substring(1)}';
    }).join(' ');
  }

  /// Legacy formatter without context. Prefer [format] with [BuildContext].
  @Deprecated('Use format(BuildContext, String?) for localized display')
  static String formatWithoutContext(String? input) {
    if (input == null || input.isEmpty) return 'Belirtilmemiş';
    if (input.contains(',')) {
      final items = input
          .split(',')
          .map((e) => _formatSingleLegacy(e.trim()))
          .toSet()
          .toList();
      return items.join(', ');
    }
    return _formatSingleLegacy(input);
  }

  static String _formatSingleLegacy(String term) {
    final normalized = _toNormalizedKey(term);
    return _titleCase(normalized.replaceAll('_', ' '));
  }
}

