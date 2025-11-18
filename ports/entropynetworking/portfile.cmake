# Always build from source
message(STATUS "Building EntropyNetworking from source")

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO Geenz/EntropyNetworking
    REF v${VERSION}
    SHA512 cda26833c7a1a8a89fde34630eff73cdbeefc0fe18bd20eeabbdc4a140680a76e4a2a5793a93720029a0e1ea50c827bbe0fdc5d289856605e32fe5dac55e00ea
    HEAD_REF main
)

# Configure and build (both debug and release)
vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_TESTS=OFF
        -DBUILD_EXAMPLES=OFF
        -DBUILD_SHARED_LIBS=OFF
)

vcpkg_cmake_install()

# Fix up CMake config files
vcpkg_cmake_config_fixup(
    PACKAGE_NAME EntropyNetworking
    CONFIG_PATH lib/cmake/EntropyNetworking
)

# Remove duplicate files from debug build
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

# Install license from source
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.md")
