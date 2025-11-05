# Always build from source
message(STATUS "Building EntropyCore from source")

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO Geenz/EntropyCore
    REF v${VERSION}
    SHA512 4191190942e23748c25fea90f8399924c3901f099660e5860cd935da8cfb14ec942544fed554f27e8dac63d287b278a47d52fe9c7d8658be6913c6bb86f444db
    HEAD_REF main
)

# Configure and build (both debug and release)
vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DENTROPY_WITH_TRACY=OFF
        -DENTROPY_ENABLE_TESTS=OFF
        -DENTROPY_BUILD_EXAMPLES=OFF
        -DBUILD_SHARED_LIBS=OFF
)

vcpkg_cmake_install()

# Fix up CMake config files
vcpkg_cmake_config_fixup(
    PACKAGE_NAME EntropyCore
    CONFIG_PATH lib/cmake/EntropyCore
)

# Remove duplicate files from debug build
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

# Install license from source
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.md")

# Verify installation succeeded
if(NOT EXISTS "${CURRENT_PACKAGES_DIR}/include/EntropyCore.h")
    message(FATAL_ERROR "Installation failed: EntropyCore.h not found in include/")
endif()
