# This variable defines which of the supported boards are built. Supported 
# boards can be listed with `make -s boards`.
BOARD ?= dc
export BOARD

PRODUCT ?= skylark
export PRODUCT

KEY_RELEASE ?= no
export KEY_RELEASE

# reproducible build for kernel
KBUILD_BUILD_TIMESTAMP ?= 2016-01-01
export KBUILD_BUILD_TIMESTAMP

KBUILD_BUILD_VERSION ?= 1
export KBUILD_BUILD_VERSION

# for busybox config
KCONFIG_NOTIMESTAMP ?= 1
export KCONFIG_NOTIMESTAMP

RXOS_TIMESTAMP ?= "$(shell date -u --rfc-3339=seconds)"
export RXOS_TIMESTAMP

# for uboot
# 1451606400 = date -u +"%s" -d "2016-01-01"
SOURCE_DATE_EPOCH ?= 1451606400
export SOURCE_DATE_EPOCH

# Build configuration
BOARDS_DIR = rxos
CONFIGS_DIR = $(BOARDS_DIR)/configs
DEFCONFIG = $(BOARD)_board_defconfig

# Build output files
OUTPUT = out/$(BOARD)
CONFIG = $(OUTPUT)/.config
IMAGES_DIR = $(OUTPUT)/images
KERNEL_IMAGE = $(IMAGES_DIR)/zImage
BUILD_STAMP = $(OUTPUT)/.stamp_built
IMG_FILE = $(IMAGES_DIR)/sdcard.img
PKG_FILE = $(IMAGES_DIR)/rxos.pkg
#
# Buildroot-specific settings
BUILDROOT = ./buildroot
OUTPUT_DIR = ../$(OUTPUT)
EXTERNAL = ../$(BOARDS_DIR)
export BR2_EXTERNAL=$(EXTERNAL)

.PHONY: \
	default \
	version \
	build \
	rebuild \
	rebuild-with-linux \
	rebuild-everything \
	flash \
	update \
	menuconfig \
	linuxconfig \
	busyboxconfig \
	saveconfig \
	clean-rootfs \
	clean-linux \
	clean-deep \
	light-clean \
	light-rebuild \
	clean \
	config \
	boards

default: build

build: $(BUILD_STAMP)

ifeq ($(BOARD),chip)
release: release-flash
else
release: release-sd-image
endif

manual:
	@make -C docs/ clean html

menuconfig: $(CONFIG)
	@make -C $(BUILDROOT) O=$(OUTPUT_DIR) menuconfig

linuxconfig: $(CONFIG)
	@make -C $(BUILDROOT) O=$(OUTPUT_DIR) linux-menuconfig

busyboxconfig: $(CONFIG)
	@make -C $(BUILDROOT) O=$(OUTPUT_DIR) busybox-menuconfig

saveconfig: $(CONFIG)
	@make -C $(BUILDROOT) O=$(OUTPUT_DIR) savedefconfig
	@make -C $(BUILDROOT) O=$(OUTPUT_DIR) linux-update-defconfig
	@make -C $(BUILDROOT) O=$(OUTPUT_DIR) busybox-update-config

config: $(CONFIG)

rebuild: clean-rootfs build

rebuild-with-linux: clean-linux build

rebuild-everything: clean-deep build

clean-rootfs:
	@-rm $(BUILD_STAMP)
	@-rm $(IMAGES_DIR)/rootfs.*
	@-rm $(IMAGES_DIR)/rxos*
	@-rm $(IMAGES_DIR)/*.txt
	@-rm $(IMAGES_DIR)/*.pkg
	@-rm $(IMAGES_DIR)/*.zip
	@-rm $(IMAGES_DIR)/*.md5
	@-rm $(IMAGES_DIR)/*.tar
	@-rm $(IMG_FILE)

clean-linux: clean-rootfs
	@-rm $(KERNEL_IMAGE)
	@make -C $(BUILDROOT) O=$(OUTPUT_DIR) linux-dirclean

clean-deep: config clean-linux
	@-rm -rf $(IMAGES_DIR)
	@-rm -rf `ls $(OUTPUT)/build | grep -v host-`
	@-rm -rf $(OUTPUT)/target
	@-rm $(OUTPUT)/staging
	@make -C $(BUILDROOT) O=$(OUTPUT_DIR) skeleton-rebuild

clean:
	-rm -rf $(OUTPUT)

light-clean:
	@-rm -rf $(OUTPUT)/.br-external $(OUTPUT)/.config $(OUTPUT)/..config.tmp $(OUTPUT)/images/ $(OUTPUT)/Makefile $(OUTPUT)/.stamp_built $(OUTPUT)/target/
	@-rm -rf $(OUTPUT)/build/*/.stamp_target_installed  $(OUTPUT)/build/*/.stamp_images_installed  $(OUTPUT)/build/*/.stamp_initramfs_rebuilt \
		 $(OUTPUT)/build/host-gcc-final-*/.stamp_host_installed

ifeq ($(BOARD),chip)
light-rebuild: light-clean build release-flash
else
light-rebuild: light-clean build release-sd-image
endif

config:
	@make -C $(BUILDROOT) O=$(OUTPUT_DIR) $(DEFCONFIG)

boards:
	-ls $(CONFIGS_DIR)/*_board_defconfig 2>/dev/null \
		| xargs basename \
		| sed 's/_board_defconfig//' 2>/dev/null

$(BUILD_STAMP): $(CONFIG)
	@make -C $(BUILDROOT) O=$(OUTPUT_DIR)
	touch $@

$(CONFIG):
	@make -C $(BUILDROOT) O=$(OUTPUT_DIR) $(DEFCONFIG)


.DEFAULT:
	@make -C $(BUILDROOT) O=$(OUTPUT_DIR) $@

