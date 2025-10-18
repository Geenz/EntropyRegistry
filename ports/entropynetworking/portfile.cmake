# Try to download pre-built binaries first, fall back to building from source
set(PREBUILT_AVAILABLE FALSE)

# Determine platform-specific release artifact name
if(VCPKG_TARGET_IS_WINDOWS)
    set(RELEASE_NAME "EntropyNetworking-Windows-x64")
elseif(VCPKG_TARGET_IS_OSX)
    set(RELEASE_NAME "EntropyNetworking-macOS-universal")
elseif(VCPKG_TARGET_IS_LINUX)
    # Default to GCC build for Linux
    set(RELEASE_NAME "EntropyNetworking-Linux-gcc-14")
endif()

# Try to download and extract pre-built binaries from GitHub releases
if(DEFINED RELEASE_NAME)
    vcpkg_download_distfile(ARCHIVE
        URLS "https://github.com/Geenz/EntropyNetworking/releases/download/v${VERSION}/${RELEASE_NAME}.tar.gz"
        FILENAME "entropynetworking-${VERSION}-${RELEASE_NAME}.tar.gz"
        SKIP_SHA512
    )

    vcpkg_extract_source_archive(PREBUILT_PATH
        ARCHIVE "${ARCHIVE}"
        NO_REMOVE_ONE_LEVEL
    )

    # Check if extraction was successful
    if(EXISTS "${PREBUILT_PATH}")
        set(PREBUILT_AVAILABLE TRUE)
        message(STATUS "Using pre-built EntropyNetworking binaries from GitHub releases")
    endif()
endif()

if(PREBUILT_AVAILABLE)
    # Copy pre-built files to package directory
    file(COPY "${PREBUILT_PATH}/" DESTINATION "${CURRENT_PACKAGES_DIR}")

    # Fix up CMake configs
    vcpkg_cmake_config_fixup(
        PACKAGE_NAME EntropyNetworking
        CONFIG_PATH lib/cmake/EntropyNetworking
    )
else()
    # Fall back to building from source
    message(STATUS "Pre-built binaries not available, building EntropyNetworking from source")

    vcpkg_from_github(
        OUT_SOURCE_PATH SOURCE_PATH
        REPO Geenz/EntropyNetworking
        REF v${VERSION}
        SHA512 993bf4b540ce31a8fb4024518794643a7d45b63bcbd84913380cf2d4e72ab9a90b5ba7aaed2ab82b65077e5eaca756946749c07a887a68452599cce7820b720f
        HEAD_REF main
    )

    # Force static library linkage
    set(VCPKG_LIBRARY_LINKAGE static)

    # Configure the build
    vcpkg_cmake_configure(
        SOURCE_PATH "${SOURCE_PATH}"
        OPTIONS
            -DBUILD_TESTS=OFF
            -DBUILD_EXAMPLES=OFF
            -DBUILD_SHARED_LIBS=OFF
    )

    # Build and install
    vcpkg_cmake_install()

    # Fix up CMake configs
    vcpkg_cmake_config_fixup(
        PACKAGE_NAME EntropyNetworking
        CONFIG_PATH lib/cmake/EntropyNetworking
    )

    # Remove duplicate files from debug build
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/include")
    file(REMOVE_RECURSE "${CURRENT_PACKAGES_DIR}/debug/share")
endif()

# Install license (download if using prebuilt)
if(PREBUILT_AVAILABLE)
    vcpkg_download_distfile(LICENSE
        URLS "https://raw.githubusercontent.com/Geenz/EntropyNetworking/v${VERSION}/LICENSE"
        FILENAME "entropynetworking-${VERSION}-LICENSE"
        SKIP_SHA512
    )
    file(INSTALL "${LICENSE}" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
else()
    vcpkg_install_copyright(FILE_LIST "${SOURCE_PATH}/LICENSE")
endif()
