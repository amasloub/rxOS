################################################################################
#
# wgrib2
#
################################################################################

WGRIB2_VERSION = 2.0.5
# note version not included below. TODO. currently it breaks the extraction
# as file name doesn't end in tar.gz
WGRIB2_SOURCE = wgrib2.tgz
WGRIB2_SITE = http://www.ftp.cpc.ncep.noaa.gov/wd51we/wgrib2


define WGRIB2_BUILD_CMDS
    $(TARGET_MAKE_ENV) CC=gcc FC=gfortran LIBTOOL=libtool $(MAKE) USE_OPENMP=0 -C $(@D)
endef


define WGRIB2_INSTALL_TARGET_CMDS
	$(INSTALL) -Dm755 $(@D)/wgrib2/wgrib2 $(TARGET_DIR)/usr/bin/wgrib2
endef

$(eval $(generic-package))
