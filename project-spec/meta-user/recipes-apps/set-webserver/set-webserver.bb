#
# This file is the set-webserver recipe.
#

SUMMARY = "Simple set-webserver application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://set-webserver.sh \
           file://set-webserver.service \
	"

S = "${WORKDIR}"
FILESEXTRAPATHS:prepend := "${THISDIR}/files:"

inherit systemd

SYSTEMD_PACKAGES = "${PN}"
SYSTEMD_SERVICE:${PN} = "set-webserver.service"

do_install() {
    install -d ${D}${bindir}
    install -m 0755 ${WORKDIR}/set-webserver.sh ${D}${bindir}/
    install -d ${D}${systemd_system_unitdir}
    install -m 0644 ${WORKDIR}/set-webserver.service ${D}${systemd_system_unitdir}
}

FILES:${PN} += "${bindir}/set-webserver.sh"

