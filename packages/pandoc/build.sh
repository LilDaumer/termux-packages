TERMUX_PKG_HOMEPAGE=https://pandoc.org/
TERMUX_PKG_DESCRIPTION="Universal markup converter"
TERMUX_PKG_LICENSE="GPL-2.0"
TERMUX_PKG_MAINTAINER="Aditya Alok <alok@termux.dev>"
TERMUX_PKG_VERSION=3.6.4
TERMUX_PKG_SRCURL="https://hackage.haskell.org/package/pandoc-cli-$TERMUX_PKG_VERSION/pandoc-cli-$TERMUX_PKG_VERSION.tar.gz"
TERMUX_PKG_SHA256=ca6faf434e1d65875089a88da11e140d76c6fe1fc1e46b13baea693f1e6ed210
TERMUX_PKG_DEPENDS="libffi, libiconv, libgmp, zlib"
TERMUX_PKG_BUILD_DEPENDS="aosp-libs"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="-f-lua"
TERMUX_PKG_BUILD_IN_SRC=true
# Upstream doesn't support 32bit.
TERMUX_PKG_EXCLUDED_ARCHES="arm, i686"

termux_step_post_configure() {
	cabal get xml-conduit-1.10.0.0 # NOTE: Confirm version before updating
	mv xml-conduit{-1.10.0.0,}
	sed -i -E 's|(build-type:\s*)Custom|\1Simple|' ./xml-conduit/xml-conduit.cabal

	if [[ "$TERMUX_ON_DEVICE_BUILD" == false ]]; then # We do not need iserv for on device builds.
		termux_setup_ghc_iserv
		cat <<-EOF >>cabal.project.local
			packages: ./xml-conduit
			          ./
			package *
			    ghc-options: -fexternal-interpreter -pgmi=$(command -v termux-ghc-iserv)
		EOF
	fi

}

termux_step_post_make_install() {
	# Will be compressed in massage step.
	install -Dm600 ./man/pandoc.1 "$TERMUX_PREFIX"/share/man/man1/pandoc.1
	# Create empty completions file so that it is removed on uninstalling the package.
	install -Dm644 /dev/null "$TERMUX_PREFIX"/share/bash-completion/completions/pandoc
}

termux_step_create_debscripts() {
	cat <<-EOF >./postinst
		#!$TERMUX_PREFIX/bin/sh
		pandoc --bash-completion > $TERMUX_PREFIX/share/bash-completion/completions/pandoc
	EOF
}
