# NOOR 1.5 — Content pipeline repair and learning expansion

## Content pipeline
- Normalize legacy JSON records from lessons, hadiths, games, surahs, ayat, verses and challenges.
- Render both string-based steps and structured step maps.
- Read Qur'anic `verses` collections as well as `ayat`.
- Preserve source/curriculum order and week sequence; remove the silent 120-item truncation.
- Route records by their declared category where available, rather than treating every record in a file as belonging to every section.
- Deduplicate repeated records by stable ID and normalized title/age band.
- Expose parsing failures in debug builds rather than silently swallowing every exception.
- Display lesson steps and reflection questions in the NOOR library.

## Content quality
- Add category, difficulty, `content_verified`, and `review_status` metadata to all 54 curated lessons.
- All newly authored lessons remain explicitly pending human review; CI does not certify religious correctness.
- Expand validation to every JSON file, while applying strict schema checks to curated NOOR packs and reporting legacy-shape gaps as warnings.
- Reject vague placeholder references and duplicate curated lesson titles within the same age band.

## Identity and documentation
- Standardize the library name to NOOR.
- Correct README statements about merge state and audio capabilities.
- Keep the legacy source repository read-only and preserve learner database compatibility.

## Verification boundary
The CI validator checks machine-readable structure, not religious authenticity. Qur'anic and hadith content must receive qualified human review before being marked approved. Audio playback, automatic game rewards, and a fully integrated achievement engine are not claimed by this release.
