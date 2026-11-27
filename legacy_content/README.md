# NOOR legacy content integration

This branch imports 89 JSON content datasets from the read-only legacy repository:
- Primary content branch: feature/kids-motivation-v1 at e69d1eb9e841b995220e35c5c7af04c837ef73f4
- Supplemental branch: ccr-fb0217df-4tgxql at 6b7d56763e383add25a342a3f23ea52617da4bf0

The source files are preserved under legacy_content/assets/content. The Android build copies them into the Flutter asset bundle, loads age-appropriate items in the corresponding NOOR sections, and retains the new app catalog, child profiles, progress, and database. The NOOR identity patch replaces the in-app mark with an animated open-book/crescent/star logo and refreshes the Android adaptive launcher vector.

The legacy source repository is not modified.