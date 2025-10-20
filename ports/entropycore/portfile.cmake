# Determine platform-specific release artifact name and SHA512
if(VCPKG_TARGET_IS_WINDOWS)
    set(RELEASE_NAME "EntropyCore-Windows-x64")
    set(BINARY_SHA512 "eb58cbca64d2d8d82b5badb735e1b779a2e3c76e9d0a25d6825a17a1aaa198a1145439543963085302c329dd96fdf8827fa2f6d6989ff6bb447a424fb7429180")
elseif(VCPKG_TARGET_IS_OSX)
    set(RELEASE_NAME "EntropyCore-macOS-universal")
    set(BINARY_SHA512 "2477e4113bcfe5f231608ad0bac783982b8485d11e2a9c74c05749a0db6f78fd48c890996534f81fd30e5c919862945fdc0d939fa6c8677ad6c4c652dee540bc")
elseif(VCPKG_TARGET_IS_LINUX)
    set(RELEASE_NAME "EntropyCore-Linux-gcc-14")
    set(BINARY_SHA512 "b39392a16eb4c6775a67df2f42425de21670d0e80a70e8a61fdf6e50d0271b5503b69ce0a3787257f5ef10bc299f1e6193e6be8f1242c1737b8a3e8ecc5e11ec")
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
        SHA512 05198ad26223f9271cb0fec4c9fdfd707f76652837e20dc3d245c36aeb62995729214bd05c32c89de37dc9e427530c73f42cfdc773699c30b6e44b71072ad09f
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
