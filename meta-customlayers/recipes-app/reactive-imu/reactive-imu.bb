SUMMARY = "Reactive IMU — unified 5-thread integration binary"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "git://github.com/cu-ecen-aeld/final-project-vash6799.git;protocol=https;branch=main"
SRCREV = "${AUTOREV}"

S = "${WORKDIR}/git"

DEPENDS = "libdrm"

do_compile() {
    ${CC} ${CFLAGS} \
        -I${STAGING_INCDIR}/libdrm \
        -o reactive_imu ${S}/orchestrator/src/reactive_imu.c \
        ${LDFLAGS} -ldrm -lpthread -lm
}

do_install() {
    install -d ${D}${bindir}
    install -m 0755 reactive_imu ${D}${bindir}/
}
