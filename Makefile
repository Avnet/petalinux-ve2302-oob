# MIT License
# Copyright (c) 2025 Avnet / Tria
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to
# deal in the Software without restriction, including without limitation the
# rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
# sell copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in
# all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
# THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
# THE SOFTWARE.

PL_BLD ?= petalinux-build
PL_PKG ?= petalinux-package-fix
PL_CFG ?= petalinux-config

SYSTEM_XSA_LOC ?= project-spec/hw-description/system.xsa
LOCAL_SSTATE ?= $(HOME)/local_2024p2_aarch64
LOCAL_DL ?= $(HOME)/local_2024p2_downloads
IMAGES_DIR ?= images/linux
FIRMWARE_DIR ?= final-firmwares

# If you change VIVADO_DIR be sure to update get-git-hash.bb
VIVADO_DIR ?= vivado-hw
VIVADO_GIT_REPO ?= git@github.com:Avnet/ve2302_oob_hw
VIVADO_GIT_BRANCH_TAG ?= 2024.2
VIVADO_XSA_LOC ?= $(VIVADO_DIR)/ve2302_oob.xsa
PL_PACKAGE_LOC := $(shell which petalinux-package)
WIC_LOC ?= $(FIRMWARE_DIR)/ve2302-oob-sdimage.wic
BOOT_BIN_LOC ?= $(FIRMWARE_DIR)/BOOT.BIN
VIVADO_TOOLS := $(shell which vivado)
PL_TOOLS := $(shell which petalinux-build)
HELP_COLOR ?= 10

.PHONY: all clean realclean update_vivado_repo build_vivado realrealclean \
	vivado_clean create_firmware check_tools

# Targets
all: check_tools $(PL_PACKAGE_LOC)-fix .petalinux/metadata build_vivado \
		$(SYSTEM_XSA_LOC) build_bsp create_firmware
		@echo
		@tput setaf 2 ; echo "Built $(WIC_LOC) successfully!"; tput sgr0;
		@echo

# Only bother to check when user enters single 'make'
check_tools:
	@$(call check_tools)

create_firmware: $(BOOT_BIN_LOC) $(WIC_LOC)
	@echo "Final firmwares completed"

update_vivado_repo: | $(VIVADO_DIR)
	@cd $(VIVADO_DIR) ;\
	git pull

build_vivado: | $(VIVADO_DIR)
	@cd $(VIVADO_DIR) ; make -f Makefile ;\

# Always execute PetaLinux and let it decide dependancies and what to do
build_bsp: | $(LOCAL_SSTATE) $(LOCAL_DL)
	$(PL_BLD)

# This allows every user to modify per build
.petalinux/metadata: | .petalinux/metadata.original
	cp .petalinux/metadata.original .petalinux/metadata

$(PL_PACKAGE_LOC)-fix : | $(PL_PACKAGE_LOC)
	@echo "STATUS: AMD PetaLinux 2024.2 $(PL_PACKAGE_LOC) has wic bug, creating fix: $(PL_PACKAGE_LOC)-fix";\
	echo "NOTE: if the patch fails, it likely means you already modified your petalinux-package script.";\
	echo "If that is the case, you can just copy your fixed version to create a new file: $(PL_PACKAGE_LOC)-fix";\
	echo "Or you can restore your petalinux-package file to its original content and let this Makefile fix it.";\
	echo "The original petalinux-package MD5SUM: 82e80e6e80059b2abdbe9784d970e199";\
	patch -p0 $(PL_PACKAGE_LOC) -i patches/v2024.2-petalinux-package.patch -o "$(PL_PACKAGE_LOC)-fix";\
	chmod +x $(PL_PACKAGE_LOC)-fix ;\

$(VIVADO_DIR):
	git clone $(VIVADO_GIT_REPO) -b $(VIVADO_GIT_BRANCH_TAG) $(VIVADO_DIR)

$(VIVADO_XSA_LOC): | build_vivado
	@if [ -f $(VIVADO_XSA_LOC) ]; then\
		echo "XSA generated";\
	else\
		echo "XSA does not exist, check on the build under $(VIVADO_DIR)";\
	fi

$(SYSTEM_XSA_LOC): $(VIVADO_XSA_LOC) | $(VIVADO_DIR)
	$(PL_CFG) --silentconfig --get-hw-description $(VIVADO_DIR)

$(BOOT_BIN_LOC): $(IMAGES_DIR)/boot.scr $(IMAGES_DIR)/psmfw.elf $(IMAGES_DIR)/plm.elf \
		$(IMAGES_DIR)/u-boot.elf $(IMAGES_DIR)/u-boot-dtb.elf $(IMAGES_DIR)/bl31.elf | $(FIRMWARE_DIR)
	$(PL_PKG) boot --format BIN --plm --psmfw --u-boot --dtb --force
	@if [ -f $(IMAGES_DIR)/BOOT.BIN ]; then\
		cp $(IMAGES_DIR)/BOOT.BIN $(BOOT_BIN_LOC) ;\
		cp -f $(IMAGES_DIR)/boot.scr $(FIRMWARE_DIR)/boot.scr ;\
		cp -f $(IMAGES_DIR)/image.ub $(FIRMWARE_DIR)/image.ub ;\
	else\
		@echo "ERROR: creating $(BOOT_BIN_LOC)";\
	fi

$(WIC_LOC): $(BOOT_BIN_LOC) $(IMAGES_DIR)/image.ub $(IMAGES_DIR)/system.dtb | $(FIRMWARE_DIR)
	$(PL_PKG) wic --extra-bootfiles "image.ub" --size 1G,1G --outdir $(FIRMWARE_DIR)
	mv $(FIRMWARE_DIR)/petalinux-sdimage.wic $(WIC_LOC)

$(FIRMWARE_DIR):
	mkdir $(FIRMWARE_DIR)

$(LOCAL_SSTATE):
	@echo
	@echo "HINT:"
	@echo "To speed up the build, use local aarch64 ..."
	@echo "First download and install the aarch64 SSTATE tarball and"
	@echo "then: ln -s <full path, including ./aarch64> ~/local_2024p2_aarch64"
	@echo

$(LOCAL_DL):
	@echo
	@echo "HINT:"
	@echo "To speed up the build, use local downloads ..."
	@echo "First download and install the Downloads tarball and"
	@echo "then: ln -s <full path, including ./downloads> ~/local_2024p2_downloads"
	@echo

clean:
	rm -f $(IMAGES_DIR)/BOOT.BIN
	rm -rf $(FIRMWARE_DIR)

realclean:
	$(MAKE) clean
	$(MAKE) vivado_clean
	$(PL_BLD) -x distclean
	$(PL_BLD) -x mrproper

vivado_clean:
	@if [ -d $(VIVADO_DIR) ]; then\
		cd $(VIVADO_DIR) ; make clean;\
	fi

realrealclean:
	$(MAKE) clean
	rm -f .petalinux/metadata
	rm -rf $(VIVADO_DIR) build components .Xil

define check_tools
	@if [[ -z "$(VIVADO_TOOLS)" ]]; then\
		echo "ERROR: cannot find Vivado!";\
		echo "       Please source the Vitis/Vivado settings64.sh";\
	fi;\
	if [[ -z "$(PL_TOOLS)" ]]; then\
		echo "ERROR: cannot find PetaLinux!";\
		echo "       Please source the PetaLinux settings.sh";\
	fi;\
	if [[ -z "$(PL_TOOLS)" ]] || [[ -z "$(VIVADO_TOOLS)" ]]; then\
		exit -1;\
	fi
endef

help:
	@echo
	@tput setaf $(HELP_COLOR);
	@echo "To build the VE2302 Kit firmware just type and enter: make"
	@tput sgr0;
	@echo
