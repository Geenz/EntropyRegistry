# Determine platform-specific release artifact name and SHA512
if(VCPKG_TARGET_IS_WINDOWS)
    set(RELEASE_NAME "EntropyNetworking-Windows-x64")
    set(BINARY_SHA512 "90dfce64dfc64212b0c01a825a0ce24e6ed46ecf97c7d39087a29ec4e1c6e1bc93a724122a9e99b5db95b487ce8b7e27334429dde4874b3cd6118ad87ba1c3fb")
elseif(VCPKG_TARGET_IS_OSX)
    set(RELEASE_NAME "EntropyNetworking-macOS-universal")
    set(BINARY_SHA512 "7d04fc018336d8e33a9cb94622bc9382c2a297297aa56e8fe690f64d75322e6ab53d9a112bc1f96ab9f16e14ef46a4aa90fa3546430f173b6056df554b1e16fe")
elseif(VCPKG_TARGET_IS_LINUX)
    set(RELEASE_NAME "EntropyNetworking-Linux-gcc-14")
    set(BINARY_SHA512 "c9dff24075007b6654a1f80f1064f30290f98557e119725e2d2385cc647b386115121f0582868c25fe7ef770046796e3743bc4174efbdcc1d84850fbf4b8ef6d")
endif()

# Try to download pre-built binaries from GitHub releases
set(PREBUILT_AVAILABLE FALSE)
if(DEFINED RELEASE_NAME)
    vcpkg_download_distfile(ARCHIVE
        URLS "https://github.com/Geenz/EntropyNetworking/releases/download/v${VERSION}/${RELEASE_NAME}.tar.gz"
        FILENAME "entropynetworking-${VERSION}-${RELEASE_NAME}.tar.gz"
        SHA512 "${BINARY_SHA512}"
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
        SHA512 a32d1664e919a4bb44d8055ddc5f965c5ce2b35d9b24382ceb1fdbb27f59a182b17cfc81f00cb54fdbc48e19b2ffee94fa6f4a81590f95f6075e900df815fe97
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
