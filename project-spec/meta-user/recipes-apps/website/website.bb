#
# This file is the website recipe.
#

SUMMARY = "Simple website application"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

SRC_URI = "file://index.html"
SRC_URI += "file://TRIA_Banner.png"
SRC_URI += "file://VE2302_SOM_TOP_500x500.png"
SRC_URI += "file://FY26_1683_Tria_VE2302_SOM_Product_Brief_vp-1.pdf"
SRC_URI += "file://FY26_1683_Tria_Versal_Dev_Kit_Product_Brief_vp-1.pdf"

FILES:${PN} += "/srv/www"

S = "${WORKDIR}"

do_install() {
	     install -d ${D}/srv/www
		 install -m 0644 ${S}/index.html ${D}/srv/www
	     install -m 0644 ${S}/TRIA_Banner.png ${D}/srv/www
	     install -m 0644 ${S}/VE2302_SOM_TOP_500x500.png ${D}/srv/www
		 install -m 0644 ${S}/FY26_1683_Tria_VE2302_SOM_Product_Brief_vp-1.pdf ${D}/srv/www
		 install -m 0644 ${S}/FY26_1683_Tria_Versal_Dev_Kit_Product_Brief_vp-1.pdf ${D}/srv/www
}
