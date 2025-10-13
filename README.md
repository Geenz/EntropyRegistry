# Entropy vcpkg Registry

Custom vcpkg registry for Entropy Engine packages.

## Packages

- **entropycore** - Core utilities and concurrency primitives

## Usage

### Add this registry to your project

Create or edit `vcpkg-configuration.json` in your project root:

```json
{
  "default-registry": {
    "kind": "git",
    "repository": "https://github.com/microsoft/vcpkg",
    "baseline": "c8696863d371ab7f46e213d8f5ca923c4aef2a00"
  },
  "registries": [
    {
      "kind": "git",
      "repository": "https://github.com/YOUR_USERNAME/EntropyRegistry",
      "baseline": "LATEST_COMMIT_SHA",
      "packages": ["entropycore"]
    }
  ]
}
```

### Install packages

```bash
# Basic installation
vcpkg install entropycore

# With optional features
vcpkg install entropycore[tracy]
vcpkg install entropycore[tests]
vcpkg install entropycore[tracy,tests]
```

### Use in CMakeLists.txt

```cmake
find_package(EntropyCore CONFIG REQUIRED)
target_link_libraries(YourTarget PRIVATE EntropyCore::Core)
```

## Adding New Packages

1. Create port directory: `ports/package-name/`
2. Add `vcpkg.json` and `portfile.cmake`
3. Create version entry: `versions/p-/package-name.json`
4. Update `versions/baseline.json`
5. Commit and get git-tree SHA
6. Update version file with correct git-tree SHA

## Updating Package Versions

See [vcpkg documentation](https://learn.microsoft.com/en-us/vcpkg/maintainers/registries) for details on maintaining registries.
