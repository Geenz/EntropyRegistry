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
# Note: EntropyCore requires CMake 3.28+ for FILE_SET HEADERS support
vcpkg_cmake_configure(
    SOURCE_PATH "${SOURCE_PATH}"
    OPTIONS
        -DENTROPY_WITH_TRACY=OFF
        -DENTROPY_BUILD_TESTS=OFF
        -DBUILD_SHARED_LIBS=OFF
)

# Build and install
# This will install:
# - Static library: lib/libEntropyCore.a (or EntropyCore.lib on Windows)
# - Headers: include/ (via FILE_SET HEADERS)
#   - include/EntropyCore.h
#   - include/Core/*.h
#   - include/Logging/*.h
#   - include/Concurrency/*.h
#   - include/VirtualFileSystem/*.h
#   - include/entropy/*.h (C API)
# - CMake configs: lib/cmake/EntropyCore/
vcpkg_cmake_install()

# Fix up CMake configs
vcpkg_cmake_config_fixup(
    PACKAGE_NAME EntropyCore
    CONFIG_PATH lib/cmake/EntropyCore
)

# Verify headers were installed
if(NOT EXISTS "${CURRENT_PACKAGES_DIR}/include/EntropyCore.h")
    message(FATAL_ERROR "Headers were not installed correctly. EntropyCore.h not found in include/")
endif()

# Remove duplicate files from debug build
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")

# Install license
vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.md")
