# Subscription logos

Logo files bundled in the app for catalog services. `SubscriptionLogo` uses
one before `logo_url`, the site's favicon or the first letter.

- Name each file after the service's `domain` in `subscription_catalog`:
  `netflix.com.png`, `vodafone.com.eg.svg`, `te.eg.png` (WE).
- `.png`, `.jpg`, `.jpeg`, `.webp` or `.svg`, directly in this folder.
- Logos are drawn whole on a white tile with a margin, so any shape works and
  dark text stays readable in dark mode. Square, icon-style logos fill the
  tile best; wide wordmarks come out small.
- Keep bitmaps at most 512px on the longest side.
- New or changed files need a full rebuild (`flutter run`), not a hot restart.
