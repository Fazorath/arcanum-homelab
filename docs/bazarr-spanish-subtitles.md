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
| Language Equals | `spa:spa-MX` (`general.language_equals`): a Spanish (`.es`) subtitle also counts as Spanish (Latino, `ea`) |
| Post-processing | on, `/config/rename-es-mx.sh "{{subtitles}}"` |

(An earlier Spanish-only profile was tried and removed.)

`config/bazarr/rename-es-mx.sh` is copied to `/srv/appdata/bazarr/` (`/config` in the
container). After Bazarr downloads an `es-MX` file it renames it to `.es` (same folder, never
overwrites an existing `.es`; if one exists the `es-MX` file stays). Bazarr re-indexes the new name on its
next disk scan.

## Why Language Equals (issue #9)

Without it the rename loop broke Bazarr's bookkeeping: Bazarr saved `ea` as `Name.es-MX.srt`,
the script renamed it to `.es` (or deleted it when a `.es` existed), Bazarr then saw no `ea`
subtitle, listed the item as Wanted and downloaded es-419 again on every search (97 items,
11 wasted downloads in one run).

Fix: Bazarr 1.6.2 `general.language_equals`. The value is `from:to` in Bazarr's internal
codes (alpha3 plus optional country; `ea` is `spa-MX`). `spa:spa-MX` means "when an item
has Spanish, treat it as also having Spanish (Latino)". Set in Settings > Languages >
Language Equals, or `POST /api/system/settings` with `settings-general-language_equals=spa:spa-MX`
(a JSON list value gets stored as a nested list; send the plain string). Changing it
re-indexes subtitles right away. Wanted for `ea` went from 97 items to 13 (7 episodes, 6 movies).

The rename script stays; Language Equals only fixes what Bazarr counts as missing, and the script
is still what makes Jellyfin see `.es`. It changed in one way: when a `.es` twin already exists it
now **keeps** the `es-MX` file instead of deleting it. That matters for items whose only Spanish
file is `.es.hi`: Bazarr only expands plain Spanish, so those stay Wanted for `ea`, and deleting
the HI download (what the old script did) would loop forever. With the file kept, Bazarr counts
`ea` as present. Jellyfin ignores the unlabelled `es-MX` copy.

Checked live 2026-10-27: Wanted fell from 97 items to 13 (the rest have no Spanish at all or
no provider match), repeated searches made no new `ea` downloads, Tulsa King S03E10 kept
`.es.hi` plus `.es-MX.hi`. No `.es` file or media file was touched. `en` Wanted is unchanged (1 movie before and after, 0 episodes).
Bazarr's adaptive search also throttles repeat searches for items no provider has, so the 13 left are not hammered every cycle.

(Fallback not needed: keep `es-MX` and add a `.es` hardlink.)

## Jellyfin: Dad's account only

Setting these needs a signed-in session or API key, which agents don't use. Do it once by
hand, as Miami (or as an admin editing the Miami user):

1. Log in as Miami > Settings > Playback (admin: Dashboard > Users > Miami > Playback).
2. Preferred audio language: Spanish.
3. Settings > Subtitles: preferred subtitle language Spanish; subtitle mode **Smart**
   (Spanish subtitles when the audio isn't Spanish).
4. Every other user gets English audio instead: see
   [Playback: which audio track Jellyfin picks](recyclarr-audio-language.md#playback-which-audio-track-jellyfin-picks).

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

- Settings > Languages > Language Equals shows `Spanish -> Spanish (Latino)` (`spa:spa-MX`).
- `Bazarr > Wanted` lists only titles a provider has no subtitle for.
- Jellyfin: play a Tulsa King episode as Miami; Spanish subtitle auto-selects.
- API: `GET /api/system/languages/profiles` shows profile 1 with no cutoff; `GET /api/series`
  and `/api/movies` show `profileId: 1` everywhere.
- Jellyfin: Miami's Playback and Subtitles pages show Spanish / Smart; another user's don't.
