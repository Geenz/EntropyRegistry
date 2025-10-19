# Determine platform-specific release artifact name and SHA512
if(VCPKG_TARGET_IS_WINDOWS)
    set(RELEASE_NAME "EntropyCore-Windows-x64")
    set(BINARY_SHA512 "77daed3bb8aa9f2bb4db3edbe2dddc16145905062ed2d096d5bbd4be48ffa4f35adaea8df12d711c93684ae3dd8d17fafa9d19c8084dfd4c5c3561507a3de2df")
elseif(VCPKG_TARGET_IS_OSX)
    set(RELEASE_NAME "EntropyCore-macOS-universal")
    set(BINARY_SHA512 "bf755d216bb28e43d1438919da5a618c3b6bd25ab57bc71d3e620b868367d900490501cd9c0f1caba83bb27592b060e63663475d0864f4694db56698ee1b38eb")
elseif(VCPKG_TARGET_IS_LINUX)
    set(RELEASE_NAME "EntropyCore-Linux-gcc-14")
    set(BINARY_SHA512 "e4d9c7cbae43bd6a198a9bbb36f71b327cc3c8b3392b633669f40336240adf4fb138a1af136176b08a805e7e9f878ff020abb190bbf7625c9fc21d4c526c804c")
endif()

# Try to download pre-built binaries from GitHub releases
set(PREBUILT_AVAILABLE FALSE)
if(DEFINED RELEASE_NAME)
    vcpkg_download_distfile(ARCHIVE
        URLS "https://github.com/Geenz/EntropyCore/releases/download/v${VERSION}/${RELEASE_NAME}.tar.gz"
        FILENAME "entropycore-${VERSION}-${RELEASE_NAME}.tar.gz"
        SHA512 "${BINARY_SHA512}"
    )

    vcpkg_extract_source_archive(PREBUILT_PATH
        ARCHIVE "${ARCHIVE}"
        NO_REMOVE_ONE_LEVEL
    )

    # Pre-built binaries must have both debug and release configurations
    if(EXISTS "${PREBUILT_PATH}/lib" AND EXISTS "${PREBUILT_PATH}/debug/lib" AND EXISTS "${PREBUILT_PATH}/include")
        set(PREBUILT_AVAILABLE TRUE)
        message(STATUS "Using pre-built EntropyCore binaries from GitHub releases")
    else()
        message(STATUS "Pre-built binaries incomplete (missing debug or release), will build from source")
    endif()
endif()

if(PREBUILT_AVAILABLE)
    # Pre-built binaries already have correct vcpkg structure: lib/, include/, lib/cmake/
    file(COPY "${PREBUILT_PATH}/" DESTINATION "${CURRENT_PACKAGES_DIR}")

    # Fix up CMake config files
    vcpkg_cmake_config_fixup(
        PACKAGE_NAME EntropyCore
        CONFIG_PATH lib/cmake/EntropyCore
    )

    # Download and install license
    vcpkg_download_distfile(LICENSE
        URLS "https://raw.githubusercontent.com/Geenz/EntropyCore/v${VERSION}/LICENSE.md"
        FILENAME "entropycore-${VERSION}-LICENSE.md"
        SKIP_SHA512
    )
    file(INSTALL "${LICENSE}" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
else()
    # Fall back to building from source
    message(STATUS "Pre-built binaries not available, building EntropyCore from source")

    vcpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO Geenz/EntropyCore
        REF v${VERSION}
        SHA512 b8c975d3c6342880cf475069e65c6a4191690f05163b5c7faade3133137d7957becf010c8720c939eb8cfeccf8593930361b260830e5e745d281cc55cdc8faa7
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
endif()

# Verify installation succeeded
if(NOT EXISTS "${CURRENT_PACKAGES_DIR}/include/EntropyCore.h")
    message(FATAL_ERROR "Installation failed: EntropyCore.h not found in include/")
endif()
