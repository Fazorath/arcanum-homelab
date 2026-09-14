# Storage architecture: why hardlinks are load-bearing

## The setup

The download client and the media library share one tree:

```
/srv/media/
  movies/  tv/  music/  audiobooks/  books/  podcasts/
  downloads/          <- intentionally nested inside /srv/media
```

The downloads folder lives *inside* the media root on purpose. When the *arr stack imports
a finished download, it creates a hardlink rather than copying the file. The import is
instant regardless of file size, and the bytes are stored once while appearing in both
places.

Ownership is a shared group with setgid so every service writes files the others can read:

```bash
chown -R :media /srv/media
chmod -R 2775 /srv/media
```

## The rule that follows

**The entire `/srv/media` tree must stay on a single filesystem.**

Hardlinks cannot cross filesystem boundaries. The moment you move `movies/` to a new drive
and leave `downloads/` where it is, every future import silently becomes a copy. Nothing
errors. Nothing warns you. Your disk usage just quietly doubles and you find out months
later when you run out of space.

This is the single constraint that governs every storage expansion decision here. Adding a
drive means migrating the whole tree, not splitting it.

## Migrating without destroying the structure

```bash
rsync -aH /srv/media/ /mnt/newdisk/media/
```

`-H` preserves hardlinks. Without it, rsync copies each link as a separate full file — the
migration "succeeds", the data is all there, and you have silently doubled your storage
and severed every link. There is no warning and no easy way back except redoing it.

`-a` alone is not enough. `-aH` is not optional.

## Verifying afterward

```bash
find /mnt/newdisk/media -type f -links +1 | head    # files with >1 link = intact
du -sh /mnt/newdisk/media                           # should match, not double
```
