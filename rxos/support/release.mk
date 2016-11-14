# Create a release zipball
#
# This file is part of rxOS.
# rxOS is free software licensed under the
# GNU GPL version 3 or any later version.
#
# (c) 2016 Outernet Inc
# Some rights reserved.

GITVER = $(shell cd $(BR2_EXTERNAL);git rev-parse --short HEAD)
DATE = $(shell date +%Y%m%d%H%M)
FULL_VERSION = v$(call qstrip,$(RXOS_VERSION))-$(DATE)+$(GITVER)
PLATFORM = $(call qstrip,$(RXOS_PLATFORM))
SUBPLATFORM = $(call qstrip,$(RXOS_SUBPLATFORM))
SDCARD_BASENAME = $(BINARIES_DIR)/$(PLATFORM)-$(SUBPLATFORM)-image-$(FULL_VERSION)
SDCARD_ZIPNAME = $(SDCARD_BASENAME).zip
SDCARD_MD5NAME = $(SDCARD_BASENAME).md5
FLASH_BASENAME = $(BINARIES_DIR)/$(PLATFORM)-$(SUBPLATFORM)-flash-$(FULL_VERSION)
FLASH_ZIPNAME = $(FLASH_BASENAME).zip
FLASH_MD5NAME = $(FLASH_BASENAME).md5
SAVE_ARCHIVE_BASE = $(BINARIES_DIR)/../../../../rxos_builds
SAVE_ARCHIVE_DIR = $(SAVE_ARCHIVE_BASE)/$(PLATFORM)-$(SUBPLATFORM)-build-$(FULL_VERSION)

.PHONY: release-sdcard release-flash


$(BINARIES_DIR)/INSTALL.txt: $(BR2_EXTERNAL)/misc/INSTALL.txt
	$(INSTALL) -m644 $< $@
	$(SED) 's|%VER%|$(FULL_VERSION)|' $@
	$(HOST_DIR)/usr/bin/unix2dos $@

$(BINARIES_DIR)/README.txt: $(BR2_EXTERNAL)/misc/README.txt
	$(INSTALL) -m644 $< $@
	$(HOST_DIR)/usr/bin/unix2dos $@

$(BINARIES_DIR)/99-chip.rules: $(BR2_EXTERNAL)/misc/99-chip.rules
	$(INSTALL) -m644 $< $@

$(SDCARD_ZIPNAME): $(BINARIES_DIR)/sdcard.img $(BINARIES_DIR)/INSTALL.txt
	zip -j "$@" "$<" $(BINARIES_DIR)/INSTALL.txt COPYING

$(SDCARD_MD5NAME): $(SDCARD_ZIPNAME)
	md5sum "$<" > "$@"
	sed -i 's|$(BINARIES_DIR)/||' "$@"

$(FLASH_ZIPNAME): $(BINARIES_DIR)/board.ubi $(BINARIES_DIR)/README.txt $(BINARIES_DIR)/99-chip.rules
	zip -j "$@" \
		$(BINARIES_DIR)/{board.ubi,sunxi-spl.bin,sunxi-spl-with-ecc.bin,uboot.bin,uboot.scr,README.txt,99-chip.rules} \
		$(TARGET_DIR)/etc/platform-release \
		$(BR2_EXTERNAL)/../tools/chip-flash.sh \
		$(BR2_EXTERNAL)/../COPYING

$(FLASH_MD5NAME): $(FLASH_ZIPNAME)
	md5sum "$<" > "$@"
	sed -i 's|$(BINARIES_DIR)/||' "$@"
	if [ -d $(SAVE_ARCHIVE_BASE) ] ;\
	then \
		cp -a $(BINARIES_DIR) $(SAVE_ARCHIVE_DIR) ;\
	else \
		echo archive base $(SAVE_ARCHIVE_BASE) - does not exist. mkdir it to start saving builds. ;\
	fi

release-sdcard: $(SDCARD_MD5NAME)

release-flash: $(FLASH_MD5NAME)
