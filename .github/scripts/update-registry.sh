#!/bin/bash
set -euo pipefail

# Registry Auto-Update Script
# Discovers packages, checks for new releases with complete binaries, and updates registry

# Configuration
DRY_RUN="${DRY_RUN:-false}"
AUTO_MERGE="${AUTO_MERGE:-false}"
FILTER_PACKAGES="${FILTER_PACKAGES:-}"
REQUIRED_PLATFORMS=("Windows-x64" "Linux-gcc-14" "macOS-universal")

# Tracking
UPDATES_MADE=false
UPDATE_SUMMARY=""

# Colors for logging
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

# Compare semantic versions
# Returns: 0 if v1 < v2, 1 if v1 >= v2
version_less_than() {
    local v1="$1"
    local v2="$2"

    # Remove 'v' prefix if present
    v1="${v1#v}"
    v2="${v2#v}"

    # Use sort -V for version comparison
    if [[ "$(printf '%s\n' "$v1" "$v2" | sort -V | head -n1)" == "$v1" ]] && [[ "$v1" != "$v2" ]]; then
        return 0
    else
        return 1
    fi
}

# Extract GitHub repo from portfile.cmake
get_repo_from_portfile() {
    local portfile="$1"

    # Look for REPO line in vcpkg_from_github section
    grep -A10 "vcpkg_from_github" "$portfile" | grep "REPO" | awk '{print $2}' | head -n1
}

# Get PascalCase package name for artifact matching
get_package_name_pascal() {
    local package="$1"

    # Simple conversion: entropycore -> EntropyCore
    # Split on underscore/hyphen, capitalize each part
    echo "$package" | awk -F'[-_]' '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2))} 1' OFS=''
}

# Check if all required pre-built binaries exist for a release
verify_binaries_exist() {
    local repo="$1"
    local version="$2"
    local package_name="$3"

    log_info "Verifying pre-built binaries for $package_name v$version..."

    # Get release assets
    local assets_json
    if ! assets_json=$(gh api "repos/$repo/releases/tags/v$version" --jq '.assets[].name' 2>/dev/null); then
        log_error "Failed to fetch release assets for $repo v$version"
        return 1
    fi

    # Check each required platform
    local all_present=true
    for platform in "${REQUIRED_PLATFORMS[@]}"; do
        local artifact_name="${package_name}-${platform}.tar.gz"

        if echo "$assets_json" | grep -q "^${artifact_name}$"; then
            log_success "  ✓ Found $artifact_name"
        else
            log_warning "  ✗ Missing $artifact_name"
            all_present=false
        fi
    done

    if [[ "$all_present" == "true" ]]; then
        log_success "All required binaries present for $package_name v$version"
        return 0
    else
        log_warning "Incomplete binary set for $package_name v$version - skipping"
        return 1
    fi
}

# Calculate SHA512 for source tarball
calculate_source_sha512() {
    local repo="$1"
    local version="$2"
    local tmpdir

    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' RETURN

    local tarball="$tmpdir/source.tar.gz"
    local url="https://github.com/$repo/archive/refs/tags/v${version}.tar.gz"

    log_info "Downloading source tarball from $url"
    if ! wget -q "$url" -O "$tarball"; then
        log_error "Failed to download source tarball"
        return 1
    fi

    local sha512
    sha512=$(sha512sum "$tarball" | awk '{print $1}')
    echo "$sha512"
}

# Update package port files
update_port_files() {
    local package="$1"
    local new_version="$2"
    local sha512="$3"
    local port_dir="ports/$package"

    log_info "Updating port files for $package to $new_version"

    # Update vcpkg.json
    local vcpkg_json="$port_dir/vcpkg.json"
    local tmp_json="${vcpkg_json}.tmp"

    jq --arg ver "$new_version" \
       '.version = $ver | if has("port-version") then ."port-version" = 0 else . end' \
       "$vcpkg_json" > "$tmp_json"
    mv "$tmp_json" "$vcpkg_json"

    log_success "  ✓ Updated $vcpkg_json"

    # Update portfile.cmake SHA512
    local portfile="$port_dir/portfile.cmake"

    # Replace SHA512 line in vcpkg_from_github section
    sed -i "s/SHA512 [a-f0-9]\{128\}/SHA512 $sha512/g" "$portfile"

    log_success "  ✓ Updated $portfile SHA512"
}

# Update version database
update_version_database() {
    local package="$1"
    local new_version="$2"
    local git_tree="$3"

    log_info "Updating version database for $package"

    # Determine version file prefix (first letter of package name)
    local prefix="${package:0:1}"
    local version_file="versions/${prefix}-/${package}.json"

    # Create new version entry
    local new_entry
    new_entry=$(jq -n --arg ver "$new_version" --arg tree "$git_tree" \
                   '{version: $ver, "git-tree": $tree}')

    # Prepend to versions array
    local tmp_file="${version_file}.tmp"
    jq --argjson entry "$new_entry" '.versions = [$entry] + .versions' \
       "$version_file" > "$tmp_file"
    mv "$tmp_file" "$version_file"

    log_success "  ✓ Updated $version_file"

    # Update baseline.json
    local baseline_file="versions/baseline.json"
    tmp_file="${baseline_file}.tmp"

    jq --arg pkg "$package" --arg ver "$new_version" \
       '.default[$pkg].baseline = $ver | .default[$pkg]."port-version" = 0' \
       "$baseline_file" > "$tmp_file"
    mv "$tmp_file" "$baseline_file"

    log_success "  ✓ Updated $baseline_file"
}

# Process a single package
process_package() {
    local package="$1"
    local port_dir="ports/$package"

    log_info "========================================="
    log_info "Processing package: $package"
    log_info "========================================="

    # Read current version
    local current_version
    if ! current_version=$(jq -r '.version' "$port_dir/vcpkg.json"); then
        log_error "Failed to read version from $port_dir/vcpkg.json"
        return 1
    fi

    log_info "Current version: $current_version"

    # Extract GitHub repo
    local repo
    if ! repo=$(get_repo_from_portfile "$port_dir/portfile.cmake"); then
        log_error "Failed to extract GitHub repo from portfile"
        return 1
    fi

    log_info "GitHub repository: $repo"

    # Check latest release
    log_info "Checking for latest release..."
    local latest_tag
    if ! latest_tag=$(gh api "repos/$repo/releases/latest" --jq '.tag_name' 2>/dev/null); then
        log_warning "No releases found for $repo"
        return 0
    fi

    local latest_version="${latest_tag#v}"
    log_info "Latest release: $latest_version"

    # Compare versions
    if version_less_than "$current_version" "$latest_version"; then
        log_info "New version available: $current_version -> $latest_version"

        # Get PascalCase name for binaries
        local package_name_pascal
        package_name_pascal=$(get_package_name_pascal "$package")

        # Verify binaries exist
        if ! verify_binaries_exist "$repo" "$latest_version" "$package_name_pascal"; then
            log_warning "Skipping $package due to missing binaries"
            return 0
        fi

        # Calculate source SHA512
        log_info "Calculating source SHA512..."
        local sha512
        if ! sha512=$(calculate_source_sha512 "$repo" "$latest_version"); then
            log_error "Failed to calculate SHA512 for $package"
            return 1
        fi

        log_success "SHA512: $sha512"

        if [[ "$DRY_RUN" == "true" ]]; then
            log_info "[DRY RUN] Would update $package to $latest_version"
            UPDATE_SUMMARY+="- $package: $current_version → $latest_version (dry run)\n"
            return 0
        fi

        # Update port files
        update_port_files "$package" "$latest_version" "$sha512"

        # Commit port changes
        git add "$port_dir/"
        git commit -m "Update $package port to $latest_version"
        log_success "Committed port changes"

        # Calculate git-tree SHA
        local git_tree
        git_tree=$(git rev-parse "HEAD:$port_dir")
        log_info "Git-tree SHA: $git_tree"

        # Update version database
        update_version_database "$package" "$latest_version" "$git_tree"

        # Commit version database changes
        git add versions/
        git commit -m "Update $package version database to $latest_version"
        log_success "Committed version database changes"

        # Track updates
        UPDATES_MADE=true
        UPDATE_SUMMARY+="- **$package**: $current_version → $latest_version\n"

        log_success "Successfully updated $package to $latest_version"
    else
        log_info "Package is up to date"
    fi
}

# Main execution
main() {
    log_info "Starting registry update process..."
    log_info "DRY_RUN: $DRY_RUN"
    log_info "AUTO_MERGE: $AUTO_MERGE"

    if [[ -n "$FILTER_PACKAGES" ]]; then
        log_info "Filter packages: $FILTER_PACKAGES"
    fi

    # Discover packages
    log_info "Discovering packages..."
    local packages=()

    for port_dir in ports/*/; do
        if [[ ! -d "$port_dir" ]]; then
            continue
        fi

        local package
        package=$(basename "$port_dir")

        # Apply filter if specified
        if [[ -n "$FILTER_PACKAGES" ]]; then
            if [[ ",$FILTER_PACKAGES," != *",$package,"* ]]; then
                log_info "Skipping $package (not in filter list)"
                continue
            fi
        fi

        packages+=("$package")
    done

    log_info "Found ${#packages[@]} package(s) to check"

    # Process each package
    for package in "${packages[@]}"; do
        if ! process_package "$package"; then
            log_error "Failed to process $package - continuing with others"
        fi
    done

    # Export results for GitHub Actions
    if [[ "$UPDATES_MADE" == "true" ]]; then
        echo "UPDATES_MADE=true" >> "$GITHUB_ENV"
        echo "UPDATE_SUMMARY<<EOF" >> "$GITHUB_ENV"
        echo -e "$UPDATE_SUMMARY" >> "$GITHUB_ENV"
        echo "EOF" >> "$GITHUB_ENV"

        log_success "========================================="
        log_success "Updates completed successfully!"
        log_success "========================================="
        echo -e "$UPDATE_SUMMARY"
    else
        echo "UPDATES_MADE=false" >> "$GITHUB_ENV"
        log_info "========================================="
        log_info "No updates needed - all packages up to date"
        log_info "========================================="
    fi
}

# Run main
main
