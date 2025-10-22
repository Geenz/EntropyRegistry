# Determine platform-specific release artifact name and SHA512
if(VCPKG_TARGET_IS_WINDOWS)
    set(RELEASE_NAME "EntropyCore-Windows-x64")
    set(BINARY_SHA512 "070f4dd06561052a205e3e6d98ba357a5a27ea03534ab9b7ce1d96235b0aaa3eb99301f2f1ab2a8b956b5e22111fa2af9c17e13aeaf84172ff14fc0ec16c0c36")
elseif(VCPKG_TARGET_IS_OSX)
    set(RELEASE_NAME "EntropyCore-macOS-universal")
    set(BINARY_SHA512 "a5250ecad22ed49dc63a23dab7e2f7d762a0949ab0e6c70df0c6759ae125746dfb5463cdbe49bfa0d78d829927644657a39979be2d89dcb5334449c818e56133")
elseif(VCPKG_TARGET_IS_LINUX)
    set(RELEASE_NAME "EntropyCore-Linux-gcc-14")
    set(BINARY_SHA512 "61fa9cc9b23e29ed4f95404867542c5fec53419ed8dc22b107373d8801424a812743e620c50d2bee979eea13ec47898cb03faec58bcb02512c00058df456e163")
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
        SHA512 5048128d88a0164653e431704dfa2debfde8f5ac40bd564b21adf51d33f721323b8580dbc85adcead84afade85600d24035415e7a0ec014b40119e03532af120
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
