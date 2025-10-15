# Download the source
vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO Geenz/EntropyNetworking
    REF v${VERSION}
    SHA512 993bf4b540ce31a8fb4024518794643a7d45b63bcbd84913380cf2d4e72ab9a90b5ba7aaed2ab82b65077e5eaca756946749c07a887a68452599cce7820b720f
    HEAD_REF main
)

# Configure the build
vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DBUILD_TESTS=OFF
        -DBUILD_EXAMPLES=OFF
        -DBUILD_SHARED_LIBS=OFF
)

# Build and install
# This will install:
# - Static library: lib/libEntropyNetworking.a (or EntropyNetworking.lib on Windows)
# - Headers: include/Networking/*.h
# - CMake configs: lib/cmake/EntropyNetworking/
vcpkg_cmake_install()

# Fix up CMake configs
vcpkg_cmake_config_fixup(
    PACKAGE_NAME EntropyNetworking
    CONFIG_PATH lib/cmake/EntropyNetworking
)

# Remove duplicate files from debug build
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

# Install license
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
