# Audio language: English first, Spanish second

Rule: **English audio is always the primary track.** A Spanish (Latin American) track is a bonus
only when the release also carries English. Spanish never replaces English.

All of this is managed by Recyclarr (`config/recyclarr/`). Scores set by hand in the Sonarr/Radarr
UI are overwritten by the nightly sync, so change the repo file and re-sync instead.

## What is configured

| Piece | Where | Effect |
|---|---|---|
| `EN+ES Dual Audio` custom format | `config/recyclarr/custom-formats/{radarr,sonarr}/en-es-dual-audio.json` | Matches releases whose language includes English **and** Spanish / Spanish (Latino), or that carry a `Dual`, `Latino` or `ENG-SPA` tag together with English. No score for Spanish on its own. |
| Score **+4** | `recyclarr.yml`, `custom_formats` | Added to every profile the library uses (Radarr: HD Bluray + WEB, WEB-1080p, HD - 720p/1080p. Sonarr: WEB-1080p, HD-1080p). Too small to beat a better release group or quality, so it only breaks ties inside one tier. |
| `Language: Not Original` **-10000** | Radarr: `recyclarr.yml`. Sonarr: TRaSH language group on WEB-1080p, `recyclarr.yml` on HD-1080p | A release without the title's original language (e.g. a Spanish-only dub of an English movie) is rejected. Non-English originals keep their own language. |
| *Minimum Custom Format Score Increment* **5** | `min_upgrade_format_score` on the profiles that allow upgrades | A +4 dual-audio match alone never triggers an upgrade of a file you already have. Repack/Proper (+5) and release-group tier upgrades still do. Quality-to-quality upgrades are decided by quality rank and are unaffected. |

Minimum Custom Format Score stays at 0, so English-only releases remain grabbable.
Anime profiles are untouched.

## Changing it

1. Edit `config/recyclarr/recyclarr.yml` or the custom-format JSON in this repo.
2. Copy to `/srv/appdata/recyclarr/` (via `~/server/appdata/recyclarr`). `secrets.yml` lives there only and is gitignored (template: `secrets.example.yml`).
3. `docker exec recyclarr recyclarr sync`, then run it again: the second run must say everything is up to date.

Spanish subtitles are covered in [bazarr-spanish-subtitles.md](bazarr-spanish-subtitles.md) (GH #3).

## Playback: which audio track Jellyfin picks

EN+ES files must start in English for the household and in Spanish for Dad (Miami). The file's
own *default* flag is not touched: the Radarr/Sonarr containers have no mkvtoolnix or ffprobe,
so an On Import script can't re-flag tracks, and the owner chose a per-account Jellyfin setting
over a host job or custom arr image (GH #6, option 1). No media file, Recyclarr, arr, Bazarr or
Jellyfin server config changes.

### Per-account settings (by hand, once)

Agents have no Jellyfin credentials. For **every household account except Miami**, sign in
(password or Quick Connect) > Settings > Playback and set:

- *Preferred audio language*: **English**
- *Play default audio track regardless of language*: **off**
- *Remember audio selections*: **off**

Miami stays as it is (Spanish audio; Subtitles Spanish + Smart, see
[the Miami section](bazarr-spanish-subtitles.md#jellyfin-dads-account-only)). Check that Miami's
Playback page still shows Spanish.

Gotcha: *Remember audio selections* stores the track picked last time per series and overrides
the preference. Leave it off, or an old Spanish pick keeps winning.

Out of scope: players outside Jellyfin (VLC, Plex, direct file play) still follow the file's
default flag.

### Verify

Play an EN+ES file from the start as a non-Miami account on the Fire TV/Android TV and the web
client. The audio menu shows **English** selected without touching it. As Miami, the same file
starts on Spanish. Best test file: one whose default flag is on the Spanish track. List audio
streams read-only with:

```
docker exec jellyfin /usr/lib/jellyfin-ffmpeg/ffprobe -v error -select_streams a \
  -show_entries stream=index,codec_name:stream_tags=language:stream_disposition=default \
  -of csv=p=0 "/media/movies/<file>"
```
