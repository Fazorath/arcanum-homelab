# Bazarr: Spanish (es-419) subtitles

Dad's (Miami) libraries need a Spanish subtitle that Jellyfin recognises. Tracked in
issue #3 (part of #1).

## The problem

- Bazarr's "Spanish (Latino)" language (code `ea`, es-419) saves files as `Name.es-MX.srt`.
  Jellyfin does not parse the `es-MX` tag, so the stream has no language and never
  auto-selects. A plain `Name.es.srt` is recognised.
- The old default profile (`English + Spanish`: en, ea, es, no cutoff) fetched both.

## Configuration (live in Bazarr, 2026-10-27)

| Setting | Value |
|---|---|
| Profile 2 | `Spanish (es-419, then es)`: items `ea` then `es`, cutoff = `es` (either one satisfies it) |
| Default for new series / movies | Profile 2 (`serie_default_profile`, `movie_default_profile`) |
| Assigned to existing items | all 15 series and 58 movies |
| Post-processing | on, `/config/rename-es-mx.sh "{{subtitles}}"` |

Profile 1 (`English + Spanish`) is kept, unused. English subtitles already on disk stay.
Profile 2 does not fetch new English subtitles; switch an item back to profile 1 for that.

`config/bazarr/rename-es-mx.sh` is copied to `/srv/appdata/bazarr/` (`/config` in the
container). After a download of an `es-MX` file it renames it to `.es` (same folder, never
overwrites an existing `.es`). Bazarr re-indexes the new name on its next disk scan, and the
cutoff stops it re-fetching.

## One-off fix of existing files

Every `*.es-MX*.srt` with no `.es` twin was renamed to `.es` (`.es.hi` for hearing-impaired).
That covers the 5 Tulsa King episodes (S03E01, S03E06, S03E09, S04E01, S04E02) and 12 more
(Ghost in the Shell, Rick and Morty, Murderbot, several movies). Where an `.es` file already
existed the `es-MX` copy was left alone. Only subtitle files changed; no media was moved or
re-encoded.

## Steps to redo it

1. Bazarr > Settings > Languages: enable Spanish and Spanish (Latino); add the profile above;
   set it as default for series and movies.
2. Bazarr > Series / Movies > Mass Edit: select all, set the profile.
3. Settings > Subtitles > Post-processing: enable, set the command above.
4. Rename old `*.es-MX*.srt` files as described, then scan disk in Bazarr and rescan the
   libraries in Jellyfin.

## Verify

- `Bazarr > Wanted` lists only titles with no Spanish subtitle on any provider.
- Jellyfin: play a Tulsa King episode as Miami; Spanish subtitle auto-selects.
- API: `GET /api/system/languages/profiles` shows profile 2; `GET /api/series` and
  `/api/movies` show `profileId: 2` everywhere.
