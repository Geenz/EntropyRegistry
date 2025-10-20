# Determine platform-specific release artifact name and SHA512
if(VCPKG_TARGET_IS_WINDOWS)
    set(RELEASE_NAME "EntropyCore-Windows-x64")
    set(BINARY_SHA512 "fd8bc1a1cf895d074f68b1b9043239b9f592f443380be8d61458acc20ba27a3c8d402a860069484891369b3b73293785edb7b54895d0d603ac8fbcf05c4386d9")
elseif(VCPKG_TARGET_IS_OSX)
    set(RELEASE_NAME "EntropyCore-macOS-universal")
    set(BINARY_SHA512 "0a1b4ecf978142fe94530a7390ef4e3964a17c8095697306c25e79d6a243bcac2e033fd01c05986f416cee64c58ab6f74d6bf6090efed22856089a779cc3c47e")
elseif(VCPKG_TARGET_IS_LINUX)
    set(RELEASE_NAME "EntropyCore-Linux-gcc-14")
    set(BINARY_SHA512 "8ce69e8525958d77d558464318b0218b75c2294ee57199736f5d49de7f087eb8a84040e99dff22dd95ed3d7e598c7f98e9d5950bab4a511a7bdf3dbdd12bb257")
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
        SHA512 8f2258ae0c0986ac4e9abafe4377a9a45198c1dbaea45d537ecda8278b6dd6a5fe18de27a8c98112fe49c8681652fc871620b1559ba87983a443969bbd4f703b
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
