# gentoo-local

Source-only Gentoo overlay for ClashTUI, sing-box and Mihomo, with OpenRC integration.
Repository name: `gentoo-local`. Master repository: `gentoo`.

## Install the overlay

Create `/etc/portage/repos.conf/gentoo-local.conf`:

```ini
[gentoo-local]
location = /var/db/repos/gentoo-local
sync-type = git
sync-uri = https://github.com/kyceblake/gentoo-overlay.git
auto-sync = yes
```

Then run as root:

```sh
emerge --sync gentoo-local
emerge --ask net-proxy/clashtui net-proxy/sing-box
```

Packages are keyworded `~amd64`; stable systems need targeted keyword
acceptance. To bootstrap Go entirely from source, mask
`dev-lang/go-bootstrap::gentoo` before installation. This overlay supplies
the source-built replacement; normal Gentoo Go bootstrap packages are binary.

## Packages

- `net-proxy/clashtui`: upstream 0.3.2 snapshot, pinned to
  `5f644c857c2f39b62a4287ce43cd13e469cd4c14`. Cargo.lock dependencies fetched
  as source archives. Builds terminal UI without optional custom themes.
  Gentoo patch supplies OpenRC paths and disables binary self-updates.
- `net-proxy/sing-box`: 1.14.2, source build with Clash API, gVisor, QUIC,
  DHCP, WireGuard, uTLS, ACME, Tailscale, Cloudflare Tunnel, USB/IP,
  OpenVPN, OpenConnect, gRPC and V2Ray API. Standard built-in protocols
  include VLESS/Reality, VMess, Shadowsocks, Trojan, SOCKS and HTTP.
  Tor support uses a source-built system Tor executable, not bundled Tor.
  AI multiplexer services are not protocol features and are omitted.
- `acct-user/sing-box`, `acct-group/sing-box`: dedicated daemon identity.
- `dev-lang/go-bootstrap`: builds Go 1.4 from C, then Go 1.17.13,
  1.20.14, 1.22.12 and 1.24.6 from source. C89 compatibility wrapper applies
  only to the historical C bootstrap. No downloaded Go binary is used.

## USE flags

`net-proxy/sing-box`:

- `tun` (default): check kernel TUN and policy routing support.
- `nftables`: additionally check kernel support for TUN `auto_redirect`.
- `tor` (default): install system Tor for Tor outbound support.
- `naive` (off): compile NaiveProxy outbound using dynamic Cronet loading.
  Requires a separately source-built `libcronet.so` in `/usr/lib64` or
  `/usr/lib`. Installation fails early when absent. Cronet itself is not
  packaged yet; this flag is not currently a turnkey Cronet installation.
  Prebuilt Cronet archive modules are excluded from package downloads.

Kernel options are checked by `linux-info.eclass`. The ebuild installs
`/usr/share/sing-box/kernel.config` for custom kernel rebuilds; it does not
silently edit, rebuild, replace or reboot the running kernel. Basic TUN
needs `CONFIG_TUN`, `CONFIG_IP_ADVANCED_ROUTER`, `CONFIG_IP_MULTIPLE_TABLES`
and `CONFIG_IPV6_MULTIPLE_TABLES`. No kernel command-line parameter is
needed for that mode. nftables checks and the fragment cover the baseline;
advanced routing modes may require further options for their configuration.

## Build / update

After editing an ebuild or patch in a writable checkout, regenerate its
Manifest and rebuild. For a checkout at `/var/db/repos/gentoo-local`:

```sh
ebuild /var/db/repos/gentoo-local/net-proxy/clashtui/clashtui-*.ebuild manifest
ebuild /var/db/repos/gentoo-local/net-proxy/sing-box/sing-box-*.ebuild manifest
emerge --usepkg=n --getbinpkg=n net-proxy/clashtui net-proxy/sing-box
```

For upstream updates, pin the new source revision/release and regenerate
Cargo `CRATES` or Go `EGO_SUM` from the matching lock files. Review module
changes for binary library payloads. The Go package currently uses Gentoo's
deprecated but supported `EGO_SUM` mechanism for individual source archives.

After source Go is installed, ordinary future Go upgrades can bootstrap
from it. The initial bootstrap chain is needed only on systems without Go.

## Runtime

`clashtui` runs as the desktop user. Core config is
`/etc/sing-box/config.json`; OpenRC service is `sing-box`.
The daemon runs under its own account with network administration, raw
socket and privileged bind capabilities. No service is enabled at boot
by package installation. A provider profile/subscription must be configured
before using the service as an actual upstream proxy.

Keep public SSH return traffic excluded from any future TUN routing policy.
Do not enable global TUN routing remotely until that policy is validated.

## Mihomo alternative

Install `net-proxy/mihomo` for Clash-format subscriptions. The source build
includes gVisor and disables EasyTier because upstream embeds prebuilt WASM.
The OpenRC service runs as `mihomo`, reads `/etc/mihomo/config.yaml`, and stores
state in `/var/lib/mihomo`. Add trusted administrators to the `mihomo` group.
The package grants that group service start/stop/restart/status access.

Set ClashTUI's Mihomo binary to `/usr/bin/mihomo`, configuration directory to
`/etc/mihomo`, configuration file to `/etc/mihomo/config.yaml`, service name
to `mihomo`, and service controller to `openrc`. Switch its core to Mihomo.
Keep the API bound to loopback with a secret. TUN routing must be configured
separately; do not run two proxy services on the same ports.

For this ClashTUI snapshot, set `tun.stack: system` in the Mihomo override;
its API parser does not recognize Mihomo's newer default `Mips` stack name.

For Linux process rules while running as the dedicated service user, set
`capabilities` in `/etc/conf.d/mihomo` to include `cap_sys_ptrace` and
`cap_dac_read_search` in addition to the default network capabilities. These
permit reading other users' process/socket links; grant them only when process
routing is required. The init script respects this local override.
