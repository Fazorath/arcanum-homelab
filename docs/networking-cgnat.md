# Remote access under CGNAT

## The constraint

The server lives in a managed apartment building on a Ruckus-operated network. The
building hands out CGNAT addresses in `100.x`, likely enforces client isolation, and may
apply per-port MAC limiting on the uplink. I control none of it.

That rules out the usual answer — port forward and point DNS at a public IP. There is no
public IP to point at.

## Two paths, deliberately

**Tailscale mesh** for every device that can run an agent: my laptop, my phone, my desktop.
It NAT-traverses without inbound ports and gives stable addressing regardless of what the
building's DHCP does.

**Cloudflare Tunnel** for the one client that can't. Family in another city watch on a
Samsung smart TV, which has no way to join a tailnet. The tunnel exposes exactly one
service on one hostname, with the origin making an outbound connection — still no inbound
ports open.

Splitting on "can this client run an agent" rather than "is this person trusted" keeps the
attack surface to a single service, instead of putting the whole stack on the internet to
accommodate one TV.

## The diagnostic that matters: direct vs DERP

Tailscale will happily work while relaying all your traffic through a datacenter. It looks
connected. It is not local.

```bash
tailscale ping arcanum
```

- `DERP(dfw)` with 65–79 ms → traffic is relaying through Dallas. Your "LAN" transfer is
  crossing Texas.
- `direct` with sub-millisecond latency → true local switching.

The gap is the difference between ~110 MB/s and something closer to your upload speed.
Persistent DERP on the same LAN means UDP is being blocked or clients are isolated — which
is a building-network problem, not a Tailscale problem, and the fix is a router you
control rather than more Tailscale configuration.

## Wiring gotcha

Adding an unmanaged switch between the modem and two machines dropped the server entirely
— tunnel returning 530, Tailscale down. The cause was a cable seating issue, not the
topology: both machines do get their own DHCP lease through the switch. Worth knowing
before you conclude that your ISP is limiting you to one device.

## Identity note

If your tailnet login is a Sign in with Apple private-relay address, that relay address is
the identity ACL rules have to reference — not the email you think of as yours. Use
`autogroup:admin` or the relay address explicitly, or the owner locks themselves out.
