# Always build from source
message(STATUS "Building EntropyNetworking from source")

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO Geenz/EntropyNetworking
    REF v${VERSION}
    SHA512 e3068aa14f7491e20485a1eb2d12d30e1c7fac6011f0076720cc59b9cfb64e884ac39e31f4f650de474a49c493714330d0850ccb55a4ef666392efba33cbab8a
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
