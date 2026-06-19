pkgname=telegram-desktop-patched
pkgdesc='Telegram Desktop client with some anti-features (sponsored messages, saving restrictions and other) disabled.'
url="https://github.com/Layerex/telegram-desktop-patches"
conflicts=("telegram-desktop")
provides=("telegram-desktop")
pkgrel=1

prepare() {
    cd tdesktop-$pkgver-full
    patch --forward --strip=1 --input "${srcdir}/0001-Disable-sponsored-messages.patch"
    patch --forward --strip=1 --input "${srcdir}/0002-Disable-saving-restrictions.patch"
    patch --forward --strip=1 --input "${srcdir}/0003-Disable-invite-peeking-restrictions.patch"
    patch --forward --strip=1 --input "${srcdir}/0004-Disable-accounts-limit.patch"
    patch --forward --strip=1 --input "${srcdir}/0005-Option-to-disable-stories.patch"
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
        "0001-Disable-sponsored-messages.patch"
        "0002-Disable-saving-restrictions.patch"
        "0003-Disable-invite-peeking-restrictions.patch"
        "0004-Disable-accounts-limit.patch"
        "0005-Option-to-disable-stories.patch")
sha512sums=('b3a570cc997c479cd746188f79749f1a163109b5bfe9eac372e295c837619bc2baba2b371581892830b8f60f901b0ed9d2473c5014697b332c12562dc6e1ea0c'
            'SKIP'
            "0de55ce0ed5c608e3e2a6175a31b29b94c7ee4f19b10b9ad5f2aa29e98f908d0e9c57e92f8b536a4a047326b4b64731d867aa8a908ef551f591a6d54940303ee"
            "460fe0208cacf34302fe7337d64786caa416c1c26ea919a8d2135bc2d1af547bf87f093f173197c1b13dd6333a521128173944bc1969146712db6baa8489949c"
            "2c19b303ce77aa5b92dcbc46e61c0f45a5eb5fdb8810bd5f86a5d51acc4a79d6c41742d5197a0d72a6224e5f26855ab74ed35b5d085e8ba713cc9c87d8f54897"
            "cba09b95960960f5657b5482389deb75abad8f4200f4809943e1ca873c19cf4caa99ef79f0ff32ecb17337e1b375523e310bc5e8843d13c8b3a5dff705ca9218"
            "6ebcb82d389779fa9e606c5ac21bdcaa1c1c3d1e5e793c28aaa269cc715a425a26348f6a245aeba4b24ca57ac9cb2e26e5a5b5a0ab2ca38eb596a1746dd24103")

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
