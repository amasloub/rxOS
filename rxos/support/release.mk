# Create a release zipball
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

GITVER = $(shell cd $(BR2_EXTERNAL);git rev-parse --short HEAD)
FULL_VERSION = v$(call qstrip,$(RXOS_VERSION))+$(GITVER)
DATE = $(shell date +%Y%m%d)
BASENAME = $(BINARIES_DIR)/rxos-image-$(FULL_VERSION)-$(DATE)
ZIPNAME = $(BASENAME).zip
MD5NAME = $(BASENAME).md5


.PHONY: release-zip

$(BINARIES_DIR)/INSTALL.txt:
	$(INSTALL) -m644 $(BR2_EXTERNAL)/misc/INSTALL.txt \
		$(BINARIES_DIR)/INSTALL.txt
	sed -i 's|%VER%|$(FULL_VERSION)|' $(BINARIES_DIR)/INSTALL.txt
	$(HOST_DIR)/usr/bin/unix2dos $(BINARIES_DIR)/INSTALL.txt

$(ZIPNAME): $(BINARIES_DIR)/sdcard.img $(BINARIES_DIR)/INSTALL.txt
	zip -j "$@" "$<" $(BINARIES_DIR)/INSTALL.txt COPYING

$(MD5NAME): $(ZIPNAME)
	md5sum "$<" > "$@"
	sed -i 's|$(BINARIES_DIR)/||' "$@"

release-zip: $(MD5NAME)
