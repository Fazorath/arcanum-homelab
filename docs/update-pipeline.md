# Update pipeline

## The problem with the obvious answer

Watchtower is the usual recommendation, and it finds nothing here — because every image is
pinned to an exact tag. Pinning is the right call (a floating tag turns an unattended
restart into an unplanned major-version migration), but it means the thing that watches for
updates has to compare against upstream releases, not against a moving tag.

## What runs instead

**Diun** as the detection engine. It watches the registry and reports when a pinned image
has a newer release available, without changing anything.

**A bump script** as the apply step — rewrites the pinned tag in the compose file, pulls,
and recreates only the named service.

**A dashboard tile** as the only notification channel. No email, no push. Updates are not
an interrupt; they're something to look at when I'm already looking at the dashboard.

## The hold list

The core safety property: **stateful services never upgrade unattended.**

A hold list covers the four databases. Everything on it is reported but never auto-applied
— a Postgres major version bump can require a dump-and-restore, and discovering that at
04:30 while asleep is how you lose a photo library.

Everything else splits by blast radius:

- **Low-risk, auto-apply** — media frontends and *arr services. Stateless enough that a
  bad version is a restart away from fixed.
- **Everything else, ask first** — anything holding data, anything in the auth path.

A nightly job at 04:30 UTC applies only the auto-approved set. An interactive command
handles the rest on demand, including host `apt` upgrades.

## Why a tile and not alerts

Every notification channel you add is one you eventually start ignoring. A homelab that
pages you about a Jellyfin point release teaches you to dismiss pages. The dashboard is
already the thing I open; putting update state there means I see it exactly as often as I
should care.
