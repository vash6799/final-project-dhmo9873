# linux-raspberrypi_%.bbappend
#
# meta-customlayers/recipes-kernel/linux/linux-raspberrypi_%.bbappend
#
# Applies three kernel patches and installs the ICM-20948 device tree overlay:
#
#   Patch 1 (Issues 5 & 6): vc4 DRM telemetry plane + custom IOCTL
#   Patch 2 (Issue 9):      IMX219 embedded metadata lines
#   Patch 3 (Issue 10):     IMX219 V4L2_CID_USER_CUSTOM_BASE reactive control
#
# Also installs the ICM-20948 IIO device tree overlay (Issue 3).
#
# TARGET:  Raspberry Pi 4B, Yocto Scarthgap, linux-raspberrypi 6.6.x
#
# HOW THIS WORKS:
#   The '%' wildcard matches any linux-raspberrypi version.
#   FILESEXTRAPATHS prepends our files/ directory to the search path.
#   SRC_URI += adds our patches and DTS overlay to the source fetch list.
#   Yocto automatically applies .patch files via do_patch.
#   The DTS overlay is compiled and installed via a custom do_install_append.
#
# VERIFICATION:
#   After bitbake reactive-image:
#   1. Boot the Pi.
#   2. Run: modetest -M vc4        → should list extra overlay plane
#   3. Run: ls /boot/overlays/     → should show icm20948.dtbo
#   4. Add "dtoverlay=icm20948" to /boot/config.txt and reboot
#   5. Run: ls /sys/bus/iio/devices/  → should show iio:device0

FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

SRC_URI:append = " \
    file://0001-vc4-add-telemetry-overlay-ioctl.patch \
    file://0002-imx219-embedded-metadata.patch \
    file://0003-imx219-custom-v4l2-cid.patch \
    file://icm20948-overlay.dts \
"

# Ensure the patch series is applied in order
# (Yocto applies patches in SRC_URI order by default)

# -------------------------------------------------------------------------
# Kernel config fragments: enable IIO and the ICM-20948 driver
# -------------------------------------------------------------------------
# These CONFIG symbols must be set to compile the IIO subsystem and
# the inv_icm20948 driver into the kernel (or as a module).
#
# Create a file "reactive-camera.cfg" and reference it here:
#   SRC_URI:append = " file://reactive-camera.cfg"
#
# Contents of reactive-camera.cfg:
#   CONFIG_IIO=y
#   CONFIG_IIO_BUFFER=y
#   CONFIG_IIO_TRIGGERED_BUFFER=y
#   CONFIG_INV_ICM20648_IIO=y    # covers ICM-20948
#   CONFIG_DRM_VC4=y
#   CONFIG_VIDEO_IMX219=y
#   CONFIG_MEDIA_CONTROLLER=y
#   CONFIG_V4L2_SUBDEV_API=y
#
# For now we assume the RPi kernel already has these set (RPi 6.6 does).

# -------------------------------------------------------------------------
# Compile and install the ICM-20948 device tree overlay
# -------------------------------------------------------------------------
do_configure:append() {
    # Compile the ICM-20948 DT overlay using the kernel's DTC with plugin support
    bbnote "Compiling ICM-20948 device tree overlay..."
    dtc -@ -I dts -O dtb \
        -o "${WORKDIR}/icm20948.dtbo" \
        "${WORKDIR}/icm20948-overlay.dts"
}

do_install:append() {
    # Install the compiled overlay into the boot overlays directory.
    # The RPi bootloader reads *.dtbo files from /boot/overlays/.
    install -d "${D}/boot/overlays"
    install -m 0644 "${WORKDIR}/icm20948.dtbo" "${D}/boot/overlays/"
    bbnote "Installed icm20948.dtbo to /boot/overlays/"
}

# Package the overlay into the kernel package so it lands on the SD card
FILES:${PN} += "/boot/overlays/icm20948.dtbo"
