# Incidents

Real failures, what they looked like, and what actually caused them.

---

## USB SSD drops under sustained write load

**Symptom.** Extracting a ~20 GB VM image onto an external SSD. Partway through, the
kernel log fills with UAS resets, then the device disappears entirely:

```
uas_eh_device_reset_handler ... FAILED err -19
usb 2-1: USB disconnect
can't restore configuration #1 (error=-71)
EXT4-fs error: Remounting filesystem read-only / journal aborted
```

The ext4 journal aborted mid-write, corrupting the file being extracted. The device
re-enumerated afterward under a different node (`sdd1` instead of the expected one), so
scripts referencing the old path failed in confusing ways.

**First wrong answer.** I assumed USB autosuspend was putting the drive to sleep and added
a udev rule to disable it. It changed nothing — autosuspend was never involved. Worth
noting because it's the first result you'll find for "USB drive disconnects".

**Root cause.** A UAS (USB Attached SCSI) incompatibility between this drive's bridge chip
and the kernel's `uas` driver. It only manifests under sustained write pressure, which is
why casual file copies had worked fine for days and I'd concluded the drive was healthy.

**Fix.** Force the drive to fall back to the older `usb-storage` driver via a kernel
parameter identifying the specific bridge by vendor:product ID:

```
usb-storage.quirks=<vendor>:<product>:u
```

Requires a reboot. A powered hub also resolves it in some cases.

**Decision.** Even with the quirk applied, this drive is not where a live VM disk belongs.
The workload moved to the internal SSD, which had ample free space. The external drive is
fine for backups — sequential, restartable, not holding anything live.

**Recovery.** `umount` then `e2fsck` to clear the aborted journal before remounting.

**Lesson.** "It's been stable for days" is not evidence a drive is healthy. It's evidence
you haven't hit the failure mode yet. Test storage with the workload you intend to run on
it, not with the workload that's convenient.

---

## Immich fails with ENOTFOUND database

**Symptom.** Immich starts, then immediately errors with `ENOTFOUND database` and restarts
in a loop.

**Root cause.** Immich resolves its Postgres and Redis dependencies by hardcoded service
name. The compose services must be named exactly `database` and `redis`. Renaming them to
something more descriptive — `immich-db`, `immich-redis` — breaks DNS resolution inside the
compose network, because the application is not reading those names from config.

**Fix.** Keep the service names Immich expects and disambiguate with a separate compose
project name instead.

**Lesson.** Container DNS is only as flexible as the application's configuration surface.
Check whether a dependency name is configurable before making it tidier.

---

## Disk space vanishing with no obvious cause

**Symptom.** Free space dropping steadily while the media library stayed roughly the same
size — the library is only ~130 GB, so the numbers didn't add up.

**Root cause.** Nextcloud's trash bin. Deleted files — including a large game archive and a
batch of moved audiobooks — were retained rather than freed. Deletion in the UI is not
deletion on disk.

**Fix.** Empty the trash and set a retention policy. A disk-audit script now reports the
top consumers on demand, so the next unexplained drop takes seconds rather than an
evening to locate.

**Lesson.** Before hunting a phantom, account for the layers that deliberately keep data
you told them to delete.

---

## Radarr removes torrents immediately after import

**Symptom.** Movie torrents disappear from the download client right after import, while
manually added books and audiobooks stay put.

**Root cause.** Working as configured — Radarr's completed-download handling removes what
it manages. The asymmetry was the confusing part: items not managed by an *arr service are
untouched, so the behavior looks intermittent until you notice the pattern.

**Lesson.** Not every surprise is a bug. Figure out which component owns a file before
concluding something is broken.
