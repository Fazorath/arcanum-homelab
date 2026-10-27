# Bazarr: Spanish (es-419) subtitles

Dad's (Miami) libraries need a Spanish subtitle that Jellyfin recognises. Tracked in
issue #3 (part of #1).

## The problem

- Bazarr's "Spanish (Latino)" language (code `ea`, es-419) saves files as `Name.es-MX.srt`.
  Jellyfin does not parse the `es-MX` tag, so the stream has no language and never
  auto-selects. A plain `Name.es.srt` is recognised.

## Configuration (live in Bazarr, 2026-10-27)

English stays the household default; only Dad's Jellyfin account prefers Spanish. Bazarr
can't tell accounts apart, so it fetches both languages for everything.

| Setting | Value |
|---|---|
| Profile 1 | `English + Spanish`: items `en`, `ea` (Spanish Latino, es-419), `es`. **No cutoff**, so all three are fetched |
| Default for new series / movies | Profile 1 (`serie_default_profile`, `movie_default_profile`) |
| Assigned to existing items | all 15 series and 58 movies |
| Post-processing | on, `/config/rename-es-mx.sh "{{subtitles}}"` |

(An earlier Spanish-only profile was tried and removed.)

`config/bazarr/rename-es-mx.sh` is copied to `/srv/appdata/bazarr/` (`/config` in the
container). After Bazarr downloads an `es-MX` file it renames it to `.es` (same folder, never
overwrites an existing `.es`; a duplicate is dropped). Bazarr re-indexes the new name on its
next disk scan.

## Jellyfin: Dad's account only

Setting these needs a signed-in session or API key, which agents don't use. Do it once by
hand, as Miami (or as an admin editing the Miami user):

1. Log in as Miami > Settings > Playback (admin: Dashboard > Users > Miami > Playback).
2. Preferred audio language: Spanish.
3. Settings > Subtitles: preferred subtitle language Spanish; subtitle mode **Smart**
   (Spanish subtitles when the audio isn't Spanish).
4. Leave every other user untouched; they stay on English.

## One-off fix of existing files

Every `*.es-MX*.srt` with no `.es` twin was renamed to `.es` (`.es.hi` for hearing-impaired).
That covers the 5 Tulsa King episodes (S03E01, S03E06, S03E09, S04E01, S04E02) and 12 more
(Ghost in the Shell, Rick and Morty, Murderbot, several movies). Where an `.es` file already
existed the `es-MX` copy was left alone. Only subtitle files changed; no media was moved or
re-encoded.

## Steps to redo it

1. Bazarr > Settings > Languages: enable English, Spanish and Spanish (Latino); make the
   profile above (no cutoff) and set it as default for series and movies.
2. Bazarr > Series / Movies > Mass Edit: select all, set the profile.
3. Settings > Subtitles > Post-processing: enable, set the command above.
4. Rename old `*.es-MX*.srt` files as described, then scan disk in Bazarr and rescan the
   libraries in Jellyfin.

## Verify

- `Bazarr > Wanted` lists only titles a provider has no subtitle for.
- Jellyfin: play a Tulsa King episode as Miami; Spanish subtitle auto-selects.
- API: `GET /api/system/languages/profiles` shows profile 1 with no cutoff; `GET /api/series`
  and `/api/movies` show `profileId: 1` everywhere.
- Jellyfin: Miami's Playback and Subtitles pages show Spanish / Smart; another user's don't.
