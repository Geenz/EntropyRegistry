# Always build from source
message(STATUS "Building EntropyCore from source")

vcpkg_from_github(
    OUT_SOURCE_PATH SOURCE_PATH
    REPO Geenz/EntropyCore
    REF v${VERSION}
    SHA512 6198f40de5463e44acaffd2b21584f34d5a6523238010f9e77ad8f1a70f08797f520b73a28276d9911a5231d4c28bd925724b1d6416c564d048d597fc1d94637
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
