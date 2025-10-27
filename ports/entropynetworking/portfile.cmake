# Always build from source
message(STATUS "Building EntropyNetworking from source")

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO Geenz/EntropyNetworking
    REF v${VERSION}
    SHA512 b93d142811e28df1a40d604376e35a33e078a38263f6cffc4e82c0c721f7adce4e3613e18da10588c75cb0e053fc3cbf89cd5b652edd412116773e8f3d0002f8
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
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
