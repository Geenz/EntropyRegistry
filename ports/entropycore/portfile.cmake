# Download the source
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO Geenz/EntropyCore
    REF v${VERSION}
    SHA512 0
    HEAD_REF main
)

# Set vcpkg triplet for macOS universal binaries
if(APPLE AND NOT DEFINED VCPKG_TARGET_TRIPLET)
    set(VCPKG_TARGET_TRIPLET "universal-osx" CACHE STRING "")
endif()

# Configure the build
vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DENTROPY_WITH_TRACY=OFF
        -DENTROPY_BUILD_TESTS=OFF
        -DBUILD_SHARED_LIBS=OFF
)

# Build and install
vcpkg_cmake_install()

# Fix up CMake configs
vcpkg_cmake_config_fixup(
    PACKAGE_NAME EntropyCore
    CONFIG_PATH lib/cmake/EntropyCore
)

# Remove duplicate files
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

# Install license
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.md")
