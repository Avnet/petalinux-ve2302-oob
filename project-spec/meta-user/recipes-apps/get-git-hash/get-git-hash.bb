SUMMARY = "Custom build information for RootFS"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# Define the target path and filename
GIT_COMMIT_FILE = "build_git_info.txt"
GIT_COMMIT_PATH = "${sysconfdir}"
BDF_DIR = "bdf_local"

# Force the recipe to re-run every build to capture the latest Git state
do_compile[nostamp] = "1"

# Locate the project root (one level up from the 'build' directory)
PROJ_ROOT = "${@os.path.abspath(os.path.join(d.getVar('TOPDIR'), '..'))}"
HW_DIR = "${PROJ_ROOT}/vivado-hw"

do_compile() {
    OUT="${S}/${GIT_COMMIT_FILE}"

    # Fix for Git 'dubious ownership' in BitBake environment
    export GIT_CONFIG_COUNT=1
    export GIT_CONFIG_KEY_0="safe.directory"
    export GIT_CONFIG_VALUE_0="*"

    # 1. PetaLinux Project Info
    echo "--- PetaLinux Info ---" > ${OUT}
    echo "Version: $(git -C ${PROJ_ROOT} describe --always --dirty --tags 2>/dev/null)" >> ${OUT}
    echo "URL: $(git -C ${PROJ_ROOT} remote get-url origin 2>/dev/null)" >> ${OUT}

    # 2. Vivado Hardware Info
    if [ -d "${HW_DIR}" ]; then
        echo "" >> ${OUT}
        echo "--- Vivado HW Info ---" >> ${OUT}
        echo "Version: $(git -C ${HW_DIR} describe --always --dirty --tags 2>/dev/null || echo 'Not a Git repo')" >> ${OUT}
        echo "URL: $(git -C ${HW_DIR} remote get-url origin 2>/dev/null || echo 'N/A')" >> ${OUT}
    fi

    # 3. BDF Repo Info (Optional)
    if [ -d "${HW_DIR}/${BDF_DIR}" ]; then
        echo "" >> ${OUT}
        echo "--- BDF Info ---" >> ${OUT}
        echo "Version: $(git -C ${HW_DIR}/${BDF_DIR} describe --always --dirty --tags 2>/dev/null)" >> ${OUT}
        echo "URL: $(git -C ${HW_DIR}/${BDF_DIR} remote get-url origin 2>/dev/null)" >> ${OUT}
    fi

    # Debug: Output to console log so you can verify without searching folders
    echo "DEBUG: Generated File Content:"
    cat ${OUT}
}

do_install() {
    install -d ${D}${GIT_COMMIT_PATH}
    install -m 0644 ${S}/${GIT_COMMIT_FILE} ${D}${GIT_COMMIT_PATH}/${GIT_COMMIT_FILE}
}

# This ensures the file is actually included in the final package
FILES:${PN} += "${GIT_COMMIT_PATH}/${GIT_COMMIT_FILE}"
