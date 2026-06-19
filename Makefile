package: PKGBUILD
	makepkg -si

PKGBUILD: PKGBUILD.m4 $(wildcard *.patch) .
	m4 PKGBUILD.m4 > PKGBUILD

# Deploy the built package into the local [patched] pacman repo
# (/var/cache/pacman/patched). Requires sudo for write access.
# Usage: make deploy BUILDDIR=/path/to/build/dir
REPO ?= /var/cache/pacman/patched
deploy:
	@test -n "$(BUILDDIR)" || (echo "BUILDDIR required, e.g. make deploy BUILDDIR=/home/toku/builds2"; exit 1)
	@test -d "$(BUILDDIR)/telegram-desktop-patched/pkg/telegram-desktop-patched" || \
		(echo "No pkg/ tree at $(BUILDDIR)/telegram-desktop-patched/pkg/ — run make first"; exit 1)
	@NAME=$$(awk -F= '/^pkgname=/{gsub(/[\047"]/,"",$$2); print $$2; exit}' PKGBUILD); \
	VER=$$(awk -F= '/^pkgver=/{gsub(/[\047"]/,"",$$2); print $$2; exit}' PKGBUILD); \
	REL=$$(awk -F= '/^pkgrel=/{gsub(/[\047"]/,"",$$2); gsub(/[^0-9]/,"",$$2); print $$2; exit}' PKGBUILD); \
	OUT="$(BUILDDIR)/telegram-desktop-patched/$$NAME-$$VER-$$REL-x86_64.pkg.tar.zst"; \
	echo "Building $$OUT from pkg/ tree..."; \
	cd $(BUILDDIR)/telegram-desktop-patched/pkg/telegram-desktop-patched && \
	tar -c --owner=0 --group=0 --xattrs-include='*' --transform='s|^\./||' . | zstd -19 -T2 -fo $$OUT; \
	echo "Deploying $$OUT to $(REPO)..."; \
	sudo cp $$OUT $(REPO)/ && \
	sudo repo-add $(REPO)/patched.db.tar.gz $(REPO)/$$(basename $$OUT) && \
	echo "Run: sudo pacman -S telegram-desktop-patched (DB already synced)"