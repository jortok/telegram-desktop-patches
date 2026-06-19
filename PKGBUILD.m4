dnl procedures
dnl remove_last_newline(STRING)
define(`remove_last_newline', `substr(`$1', 0, decr(len(`$1')))')dnl
dnl format_lines(LINES,LINE_START,LINE_END,LINE_PREFIX)
define(`format_lines', `$2patsubst(remove_last_newline(`$1'), `
', `$3
$4$2')$3')dnl
dnl defines
dnl NOTE: glob 0*.patch only matches our numbered patches (0001..000N),
dnl not tdesktop-fix-minizip-includes.patch (handled separately, distinct -d).
define(`sum_cmd_output', `esyscmd(`sha512sum 0*.patch')')dnl
define(`patches',`patsubst(sum_cmd_output, `.*  ', `')')dnl
define(`hashes', `patsubst(sum_cmd_output, `  .*', `')')dnl
define(`PATCH_FILENAMES',format_lines(patches,`"',`"',`        '))dnl
define(`PATCH_HASHES',format_lines(hashes,`"',`"',`            '))dnl
define(`PATCH_COMMANDS',format_lines(patches,`patch --forward --strip=1 --input "${srcdir}/',`"',`    '))dnl
dnl undefines
undefine(`remove_last_newline')dnl
undefine(`format_lines')dnl
undefine(`sum_cmd_output')dnl
undefine(`patches')dnl
undefine(`hashes')dnl
dnl template
pkgname=telegram-desktop-patched
pkgdesc='Telegram Desktop client with some anti-features (sponsored messages, saving restrictions and other) disabled.'
url="https://github.com/Layerex/telegram-desktop-patches"
conflicts=("telegram-desktop")
provides=("telegram-desktop")
pkgrel=1

prepare() {
    cd tdesktop-$pkgver-full
    PATCH_COMMANDS
    cd "$srcdir"
}
# To bump Telegram version, selectively paste upstream PKGBUILD below, retaining PATCH_FILENAMES and PATCH_HASHES
# https://gitlab.archlinux.org/archlinux/packaging/packages/telegram-desktop/-/blob/main/PKGBUILD
# Make sure you are modifying PKGBUILD.m4, not PKGBUILD, or your changes will be overwritten by make
pkgver=6.9.3
_td_commit=51743dfd01dff6179e2d8f7095729caa4e2222e9
arch=('x86_64')
license=('GPL-3.0-or-later WITH OpenSSL-exception')
depends=('abseil-cpp' 'ada' 'ffmpeg' 'glib2' 'glibc' 'hicolor-icon-theme' 'hunspell'
         'kcoreaddons' 'libavif' 'libgcc' 'libheif' 'libjpeg-turbo' 'libjxl'
         'libpipewire' 'libstdc++' 'libxcb' 'libxcomposite' 'libxdamage' 'libxext' 'libxfixes'
         'libxkbcommon' 'libxrandr' 'libxtst' 'lz4' 'minizip' 'openal' 'openh264' 'openssl'
         'pipewire' 'protobuf' 'qt6-base' 'qt6-imageformats' 'qt6-svg' 'qt6-wayland' 'rnnoise'
         'xxhash' 'zlib')
makedepends=('boost' 'boost-libs' 'cmake' 'git' 'glib2-devel' 'gobject-introspection' 'qt6-shadertools' 'gperf'
             'libtg_owt' 'microsoft-gsl' 'ninja' 'python' 'range-v3' 'tl-expected')
optdepends=('geoclue: geoinformation support'
            'crow-translate: translation provider'
            'webkit2gtk-4.1: embedded browser features provided by webkit2gtk-4.1'
            'webkitgtk-6.0: embedded browser features provided by webkitgtk-6.0 (Wayland only)'
            'xdg-desktop-portal: desktop integration')
source=("https://github.com/telegramdesktop/tdesktop/releases/download/v${pkgver}/tdesktop-${pkgver}-full.tar.gz"
        "git+https://github.com/tdlib/td.git#tag=${_td_commit}"
        PATCH_FILENAMES)
sha512sums=('b3a570cc997c479cd746188f79749f1a163109b5bfe9eac372e295c837619bc2baba2b371581892830b8f60f901b0ed9d2473c5014697b332c12562dc6e1ea0c'
            'SKIP'
            PATCH_HASHES)

build() {
    cmake -S td -B td/build \
        -DCMAKE_BUILD_TYPE=None \
        -DCMAKE_INSTALL_PREFIX="$PWD/td/install" \
        -Wno-dev \
        -DTD_E2E_ONLY=ON
    cmake --build td/build
    cmake --install td/build

    cmake -B build -S tdesktop-$pkgver-full -G Ninja \
        -DCMAKE_VERBOSE_MAKEFILE=ON \
        -DCMAKE_INSTALL_PREFIX="/usr" \
        -Dtde2e_DIR="$PWD/td/install/lib/cmake/tde2e" \
        -DCMAKE_BUILD_TYPE=Release \
        -DCRL_FORCE_QT=ON \
        -DCMAKE_CXX_FLAGS_INIT="-DCRL_FORCE_QT" \
        -DTDESKTOP_API_ID=611335 \
        -DTDESKTOP_API_HASH=d524b414d21f4d37f08684c1df41ac9c
    cmake --build build
}

package() {
    DESTDIR="$pkgdir" cmake --install build
}
