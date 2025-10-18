# Determine platform-specific release artifact name
if(VCPKG_TARGET_IS_WINDOWS)
    set(RELEASE_NAME "EntropyNetworking-Windows-x64")
elseif(VCPKG_TARGET_IS_OSX)
    set(RELEASE_NAME "EntropyNetworking-macOS-universal")
elseif(VCPKG_TARGET_IS_LINUX)
    set(RELEASE_NAME "EntropyNetworking-Linux-gcc-14")
endif()

# Try to download pre-built binaries from GitHub releases
set(PREBUILT_AVAILABLE FALSE)
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

    # Pre-built binaries must have both debug and release configurations
    if(EXISTS "${PREBUILT_PATH}/lib" AND EXISTS "${PREBUILT_PATH}/debug/lib" AND EXISTS "${PREBUILT_PATH}/include")
        set(PREBUILT_AVAILABLE TRUE)
        message(STATUS "Using pre-built EntropyNetworking binaries from GitHub releases")
    else()
        message(STATUS "Pre-built binaries incomplete (missing debug or release), will build from source")
    endif()
endif()

if(PREBUILT_AVAILABLE)
    # Pre-built binaries already have correct vcpkg structure: lib/, include/, lib/cmake/
    file(COPY "${PREBUILT_PATH}/" DESTINATION "${CURRENT_PACKAGES_DIR}")

    # Fix up CMake config files
    vcpkg_cmake_config_fixup(
        PACKAGE_NAME EntropyNetworking
        CONFIG_PATH lib/cmake/EntropyNetworking
    )

    # Download and install license
    vcpkg_download_distfile(LICENSE
        URLS "https://raw.githubusercontent.com/Geenz/EntropyNetworking/v${VERSION}/LICENSE"
        FILENAME "entropynetworking-${VERSION}-LICENSE"
        SKIP_SHA512
    )
    file(INSTALL "${LICENSE}" DESTINATION "${CURRENT_PACKAGES_DIR}/share/${PORT}" RENAME copyright)
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
endif()
