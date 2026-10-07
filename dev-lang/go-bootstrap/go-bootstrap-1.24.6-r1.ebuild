# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2
EAPI=8
inherit toolchain-funcs
DESCRIPTION="Go bootstrap built entirely from source via the C-based Go 1.4 compiler"
HOMEPAGE="https://go.dev/"
SRC_URI="https://dl.google.com/go/go1.4-bootstrap-20171003.tar.gz
 https://dl.google.com/go/go1.17.13.src.tar.gz
 https://dl.google.com/go/go1.20.14.src.tar.gz
 https://dl.google.com/go/go1.22.12.src.tar.gz
 https://dl.google.com/go/go1.24.6.src.tar.gz"
S="${WORKDIR}/go1.24.6"
LICENSE="BSD"
SLOT="0"
KEYWORDS="~amd64"
RESTRICT="test strip"
src_unpack() {
 local archive version
 for version in 1.4 1.17.13 1.20.14 1.22.12 1.24.6; do
  if [[ ${version} == 1.4 ]]; then
   archive=go1.4-bootstrap-20171003.tar.gz
  else
   archive=go${version}.src.tar.gz
  fi
  unpack "${archive}"
  mv go "go${version}" || die
 done
}
src_compile() {
 export CC="$(tc-getCC)" CGO_ENABLED=0 GOTOOLCHAIN=local GO111MODULE=off
 export GOMAXPROCS=8 GOFLAGS="-p=8"
 export CGO_CFLAGS="${CFLAGS} -std=gnu89 -fcommon -Wno-error=implicit-function-declaration -Wno-error=incompatible-pointer-types"
 local compiler=$(tc-getCC)
 cat > "${T}/bootstrap-cc" <<EOF_CC
#!/bin/sh
exec "${compiler}" "\$@" -std=gnu89 -fcommon -Wno-error
EOF_CC
 chmod +x "${T}/bootstrap-cc" || die
 local version previous=""
 for version in 1.4 1.17.13 1.20.14 1.22.12 1.24.6; do
  cd "${WORKDIR}/go${version}/src" || die
  if [[ -n ${previous} ]]; then
   export GOROOT_BOOTSTRAP="${WORKDIR}/go${previous}"
   export CC="${compiler}"
  else
   unset GOROOT_BOOTSTRAP
   export CC="${T}/bootstrap-cc"
  fi
  einfo "Building source bootstrap stage Go ${version}"
  bash ./make.bash || die "Go ${version} bootstrap failed"
  previous=${version}
 done
}
src_install() {
 dodir /usr/lib
 cp -a "${S}" "${ED}/usr/lib/go-bootstrap" || die
}
