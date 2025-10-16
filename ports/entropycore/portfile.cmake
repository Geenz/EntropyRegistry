# Try to download pre-built binaries first, fall back to building from source
set(PREBUILT_AVAILABLE FALSE)

# Determine platform-specific release artifact name
if(VCPKG_TARGET_IS_WINDOWS)
    set(RELEASE_NAME "EntropyCore-Windows-x64")
elseif(VCPKG_TARGET_IS_OSX)
    set(RELEASE_NAME "EntropyCore-macOS-universal")
elseif(VCPKG_TARGET_IS_LINUX)
    # Default to GCC build for Linux
    set(RELEASE_NAME "EntropyCore-Linux-gcc-14")
endif()

# Try to download and extract pre-built binaries from GitHub releases
if(DEFINED RELEASE_NAME)
    vcpkg_download_distfile(ARCHIVE
        URLS "https://github.com/Geenz/EntropyCore/releases/download/v${VERSION}/${RELEASE_NAME}.tar.gz"
        FILENAME "entropycore-${VERSION}-${RELEASE_NAME}.tar.gz"
        SKIP_SHA512
    )

    vcpkg_extract_source_archive(PREBUILT_PATH
        ARCHIVE "${ARCHIVE}"
        NO_REMOVE_ONE_LEVEL
    )

    # Check if extraction was successful
    if(EXISTS "${PREBUILT_PATH}")
        set(PREBUILT_AVAILABLE TRUE)
        message(STATUS "Using pre-built EntropyCore binaries from GitHub releases")
    endif()
endif()

if(PREBUILT_AVAILABLE)
    # Copy pre-built files to package directory
    file(COPY "${PREBUILT_PATH}/" DESTINATION "${CURRENT_PACKAGES_DIR}")

    # Fix up CMake configs
    vcpkg_cmake_config_fixup(
        PACKAGE_NAME EntropyCore
        CONFIG_PATH lib/cmake/EntropyCore
    )
else()
    # Fall back to building from source
    message(STATUS "Pre-built binaries not available, building EntropyCore from source")

    vcpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO Geenz/EntropyCore
        REF v${VERSION}
        SHA512 25323256b84129e991851162c50449fc535d23c6fa6b718fdc31d0a72dc581efabcf282a37e8151aa1f246ba49b5b232520402c53a7107a302bf30acd8731e0b
        HEAD_REF main
    )

    # Force static library linkage
    set(VCPKG_LIBRARY_LINKAGE static)

    # Configure the build
    vcpkg_cmake_configure(
        SOURCE_PATH "${SOURCE_PATH}"
        OPTIONS
            -DENTROPY_WITH_TRACY=OFF
            -DENTROPY_ENABLE_TESTS=OFF
            -DENTROPY_BUILD_EXAMPLES=OFF
            -DBUILD_SHARED_LIBS=OFF
    )

    # Build and install
    vcpkg_cmake_install()

    # Fix up CMake configs
    vcpkg_cmake_config_fixup(
        PACKAGE_NAME EntropyCore
        CONFIG_PATH lib/cmake/EntropyCore
    )

    # Remove duplicate files from debug build
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
endif()

# Verify installation
if(NOT EXISTS "${CURRENT_PACKAGES_DIR}/include/EntropyCore.h")
    message(FATAL_ERROR "Headers were not installed correctly. EntropyCore.h not found in include/")
endif()

# Install license (download if using prebuilt)
if(PREBUILT_AVAILABLE)
    vcpkg_download_distfile(LICENSE
        URLS "https://raw.githubusercontent.com/Geenz/EntropyCore/v${VERSION}/LICENSE.md"
        FILENAME "entropycore-${VERSION}-LICENSE.md"
        SKIP_SHA512
    )
    file(INSTALL "${LICENSE}" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
else()
    vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE.md")
endif()
