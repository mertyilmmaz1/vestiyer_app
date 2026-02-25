# Store & Legal Localization Checklist

## App Store / Play Store metadata

- **Per locale:** Add localized title, subtitle, description, keywords, and screenshots in App Store Connect (iOS) and Play Console (Android) for each supported language (e.g. Turkish, English).
- **Keywords:** Use locale-specific keywords for discoverability in each store.
- **fastlane:** Use fastlane or similar to manage metadata per lane/locale if desired.

## In-app legal content

- **Terms of Service** and **Privacy Policy** screens are localized via `lib/l10n/app_tr.arb` and `app_en.arb` (keys: `terms*`, `privacy*`). Content is loaded from ARB; for long legal text, consider markdown assets per locale (e.g. `terms_tr.md`, `terms_en.md`) and load by locale.
- **Links:** The "Open in browser" buttons point to `vestiyerapp.com/terms-of-service` and `.../privacy-policy`; ensure those URLs serve the correct language or a language selector.

## Regional legal requirements

- **GDPR (EU):** Ensure privacy policy and consent flows cover data processing, legal basis, and user rights (access, rectification, erasure, portability, objection). Add EN (and optionally local EU language) legal copy as needed.
- **KVKK (Turkey):** Turkish privacy copy is in ARB; ensure it reflects data controller, purposes, and rights under KVKK.
- **CCPA (California):** If targeting California users, add CCPA-specific disclosures and "Do not sell" option if applicable.

## Date / number / currency

- **In-app:** `api_usage_screen` and `outfit_history_screen` use `DateFormat` and locale from `Localizations.localeOf(context)` for date formatting. Use `intl` `NumberFormat` with locale for numbers/currency where needed.
- **Premium / RevenueCat:** Display prices from RevenueCat so they are shown in the user’s local currency.
