#
# This file is the get-git-hash recipe.
#

SUMMARY = "Fetch and emit the build's git infos into the rootfs"
SECTION = "PETALINUX/apps"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# Point S (source) to the directory containing the recipe
S = "${WORKDIR}"

# Define the target path and filename in the rootfs
GIT_COMMIT_FILE = "build_git_info.txt"
GIT_COMMIT_PATH = "/etc"
BDF_DIR = "bdf_local"

do_compile() {
    # 1. Temporarily change directory to the PetaLinux project root
    cd ${S}/../..

    # 2. Get the descriptive version string (tag-commits-hash-dirty)
    #    We use un-escaped backticks (`...`) as confirmed working in 2024.2.
    GIT_VERSION=`git describe --always --dirty --tags`

    # 3. Get the remote origin URL
    GIT_URL=`git config --get remote.origin.url`

    # 4. Write the version to the file
    echo "Version: $GIT_VERSION" > ${S}/${GIT_COMMIT_FILE}

    # 5. Append the URL to the file
    echo "URL: $GIT_URL" >> ${S}/${GIT_COMMIT_FILE}

    # 6. cd to the Vivado prj
    PROJECT_ROOT=`dirname ${TOPDIR}`
    TARGET_DIR="${PROJECT_ROOT}/vivado-hw"
    cd $TARGET_DIR

    # 7. Write the version to the file
    echo "Version: $GIT_VERSION" >> ${S}/${GIT_COMMIT_FILE}

    # 8. Append the URL to the file
    echo "URL: $GIT_URL" >> ${S}/${GIT_COMMIT_FILE}

    # 9. Check for optional but usually present bdf repo info
    if [ -d "$TARGET_DIR/$BDF_DIR" ]; then
        cd "$TARGET_DIR/$BDF_DIR"
        echo "Version: $GIT_VERSION" >> ${S}/${GIT_COMMIT_FILE}
        echo "URL: $GIT_URL" >> ${S}/${GIT_COMMIT_FILE}
    fi

    # 10. Return to the starting directory
    cd -
}

# Install the generated file into the rootfs
do_install() {
    install -d ${D}${GIT_COMMIT_PATH}
    install -m 0644 ${S}/${GIT_COMMIT_FILE} ${D}${GIT_COMMIT_PATH}/${GIT_COMMIT_FILE}
}
