# Always build from source
message(STATUS "Building EntropyNetworking from source")

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO Geenz/EntropyNetworking
    REF v${VERSION}
    SHA512 ef49eeb0aba5e5c219acf9e9832f012bb1c617319e7472f29db75d874ea1c90a7f67fc8acc71e6276bf05c3f53e63a95812121c02376b31b59aa5218f22696f4
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
