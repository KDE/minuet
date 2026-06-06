#!/usr/bin/env bash

set -euo pipefail

usage()
{
    cat <<EOF
Usage: $(basename "$0") [--skip-clone-checkout] [--qt-host-prefix <qt-macos-prefix>] <qt-ios-prefix>

Build Minuet's iOS dependency stack into <qt-ios-prefix> and generate
device and simulator Xcode projects below ../build relative to this script.

Options:
  --skip-clone-checkout  Use existing dependency source trees in ../build/ios-src
                         and start directly from configure/build/install.
  --qt-host-prefix PATH  Qt for macOS prefix used to build host tools. Defaults
                         to a sibling "macos" prefix next to <qt-ios-prefix>.
  -h, --help             Show this help.

Example:
  $(basename "$0") /Users/sandroandrade/Qt/6.11.1/ios
  $(basename "$0") --skip-clone-checkout /Users/sandroandrade/Qt/6.11.1/ios
  $(basename "$0") --qt-host-prefix /Users/sandroandrade/Qt/6.11.1/macos /Users/sandroandrade/Qt/6.11.1/ios

Environment overrides:
  CONFIG=Release|Debug
  DEVICE_ARCHS=arm64
  SIMULATOR_ARCHS=x86_64
  KDE_REF=master
  KIRIGAMI_ADDONS_REF=master
  PLASMA_REF=master
  LIBINTL_LITE_REF=ba1514607d02ce3711d828e784a7e9e2bb25aa84
  FLUIDSYNTH_REF=v2.5.3
  BUILD_DEPENDENCIES=0|1
  GIT_RETRY_COUNT=3
  GIT_RETRY_DELAY=5
EOF
}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
MINUET_SRC="$(cd "$SCRIPT_DIR/.." && pwd)"
WORK_DIR="$MINUET_SRC/build"
MANIFEST="$SCRIPT_DIR/ios-dependencies.json"

CONFIG="${CONFIG:-Release}"
DEVICE_ARCHS="${DEVICE_ARCHS:-arm64}"
SIMULATOR_ARCHS="${SIMULATOR_ARCHS:-x86_64}"
BUILD_DEPENDENCIES="${BUILD_DEPENDENCIES:-1}"
SKIP_CLONE_CHECKOUT=0
GIT_RETRY_COUNT="${GIT_RETRY_COUNT:-3}"
GIT_RETRY_DELAY="${GIT_RETRY_DELAY:-5}"

QT_IOS_PREFIX_ARG=
QT_HOST_PREFIX_ARG=
while [ "$#" -gt 0 ]; do
    case "$1" in
        -h|--help)
            usage
            exit 0
            ;;
        --skip-clone-checkout|--skip-fetch)
            SKIP_CLONE_CHECKOUT=1
            shift
            ;;
        --qt-host-prefix)
            [ "$#" -ge 2 ] || {
                usage >&2
                printf 'error: --qt-host-prefix requires a path\n' >&2
                exit 2
            }
            QT_HOST_PREFIX_ARG="$2"
            shift 2
            ;;
        --)
            shift
            break
            ;;
        -*)
            usage >&2
            printf 'error: unknown option: %s\n' "$1" >&2
            exit 2
            ;;
        *)
            if [ -n "$QT_IOS_PREFIX_ARG" ]; then
                usage >&2
                printf 'error: unexpected argument: %s\n' "$1" >&2
                exit 2
            fi
            QT_IOS_PREFIX_ARG="$1"
            shift
            ;;
    esac
done

if [ "$#" -gt 0 ]; then
    if [ -n "$QT_IOS_PREFIX_ARG" ]; then
        usage >&2
        printf 'error: unexpected argument: %s\n' "$1" >&2
        exit 2
    fi
    QT_IOS_PREFIX_ARG="$1"
    shift
fi

if [ "$#" -gt 0 ] || [ -z "$QT_IOS_PREFIX_ARG" ]; then
    usage >&2
    exit 2
fi

[ -d "$QT_IOS_PREFIX_ARG" ] || {
    printf 'error: Qt iOS prefix does not exist: %s\n' "$QT_IOS_PREFIX_ARG" >&2
    exit 1
}

QT_IOS_PREFIX="$(cd "$QT_IOS_PREFIX_ARG" && pwd)"
if [ -z "$QT_HOST_PREFIX_ARG" ]; then
    QT_HOST_PREFIX_ARG="$(cd "$QT_IOS_PREFIX/.." && pwd)/macos"
fi

[ -d "$QT_HOST_PREFIX_ARG" ] || {
    printf 'error: Qt host prefix does not exist: %s\n' "$QT_HOST_PREFIX_ARG" >&2
    exit 1
}

QT_HOST_PREFIX="$(cd "$QT_HOST_PREFIX_ARG" && pwd)"

QT_CMAKE="$QT_IOS_PREFIX/bin/qt-cmake"
QT_HOST_CMAKE="$QT_HOST_PREFIX/bin/qt-cmake"
PKG_CONFIG_EXECUTABLE=
SRC_DIR="$WORK_DIR/ios-src"
SIM_PREFIX="$WORK_DIR/prefix-iphonesimulator"
HOST_TOOLS_PREFIX="$WORK_DIR/host-tools"
HOST_TOOLING_PATH="$HOST_TOOLS_PREFIX/bin;$HOST_TOOLS_PREFIX/lib/cmake"
HOST_BUILD_ROOT="$WORK_DIR/deps-host"
DEVICE_BUILD_ROOT="$WORK_DIR/deps-iphoneos"
SIM_BUILD_ROOT="$WORK_DIR/deps-iphonesimulator"
DEVICE_MINUET_BUILD="$WORK_DIR/minuet-iphoneos"
SIM_MINUET_BUILD="$WORK_DIR/minuet-iphonesimulator"

log()
{
    printf '\n==> %s\n' "$*"
}

die()
{
    printf 'error: %s\n' "$*" >&2
    exit 1
}

require_tool()
{
    command -v "$1" >/dev/null 2>&1 || die "Required tool not found in PATH: $1"
}

find_pkg_config()
{
    if command -v pkg-config >/dev/null 2>&1; then
        command -v pkg-config
    elif command -v pkgconf >/dev/null 2>&1; then
        command -v pkgconf
    else
        die "Required tool not found in PATH: pkg-config or pkgconf"
    fi
}

clean_build_env()
{
    env \
        -u CFLAGS \
        -u CPPFLAGS \
        -u CXXFLAGS \
        -u LDFLAGS \
        -u OBJCFLAGS \
        -u OBJCXXFLAGS \
        -u CPATH \
        -u C_INCLUDE_PATH \
        -u CPLUS_INCLUDE_PATH \
        -u LIBRARY_PATH \
        -u MACOSX_DEPLOYMENT_TARGET \
        -u IPHONEOS_DEPLOYMENT_TARGET \
        -u IPHONESIMULATOR_DEPLOYMENT_TARGET \
        -u TVOS_DEPLOYMENT_TARGET \
        -u TVSIMULATOR_DEPLOYMENT_TARGET \
        -u WATCHOS_DEPLOYMENT_TARGET \
        -u WATCHSIMULATOR_DEPLOYMENT_TARGET \
        -u XROS_DEPLOYMENT_TARGET \
        -u XRSIMULATOR_DEPLOYMENT_TARGET \
        -u SDKROOT \
        -u PLATFORM_NAME \
        -u EFFECTIVE_PLATFORM_NAME \
        "$@"
}

check_environment()
{
    [ -x "$QT_CMAKE" ] || die "Qt iOS qt-cmake not found or not executable: $QT_CMAKE"
    [ -x "$QT_HOST_CMAKE" ] || die "Qt host qt-cmake not found or not executable: $QT_HOST_CMAKE"
    [ -d "$MINUET_SRC" ] || die "Minuet source directory does not exist: $MINUET_SRC"
    [ -f "$MANIFEST" ] || die "Dependency manifest does not exist: $MANIFEST"

    require_tool git
    require_tool cmake
    require_tool python3
    require_tool xcrun
    require_tool lipo
    PKG_CONFIG_EXECUTABLE="$(find_pkg_config)"

    python3 -m json.tool "$MANIFEST" >/dev/null
    xcrun --sdk iphoneos --show-sdk-path >/dev/null
    xcrun --sdk iphonesimulator --show-sdk-path >/dev/null

    mkdir -p "$SRC_DIR" "$SIM_PREFIX" "$HOST_TOOLS_PREFIX" "$HOST_BUILD_ROOT" "$DEVICE_BUILD_ROOT" "$SIM_BUILD_ROOT"
}

manifest_query()
{
    local query="$1"
    local dep="${2:-}"

    python3 - "$MANIFEST" "$query" "$dep" <<'PY'
import json
import os
import sys

manifest_path, query, dep_name = sys.argv[1:4]
with open(manifest_path, encoding="utf-8") as manifest_file:
    manifest = json.load(manifest_file)

dependencies = manifest.get("dependencies")
if not isinstance(dependencies, list):
    raise SystemExit("manifest field 'dependencies' must be an array")

def dependency_named(name):
    for dependency in dependencies:
        if dependency.get("name") == name:
            return dependency
    raise SystemExit(f"dependency not found in manifest: {name}")

if query == "names":
    for dependency in dependencies:
        name = dependency.get("name")
        if not name:
            raise SystemExit("all dependencies must have a name")
        print(name)
elif query == "host-tooling-names":
    dependency_names = {dependency.get("name") for dependency in dependencies}
    for name in manifest.get("hostToolingDependencies", []):
        if name not in dependency_names:
            raise SystemExit(f"hostToolingDependencies contains unknown dependency: {name}")
        print(name)
elif query == "url":
    dependency = dependency_named(dep_name)
    value = dependency.get("url")
    if not value:
        raise SystemExit(f"{dep_name}: missing url")
    print(value)
elif query == "ref":
    dependency = dependency_named(dep_name)
    ref_env = dependency.get("refEnv")
    value = os.environ.get(ref_env, "") if ref_env else ""
    if not value:
        value = dependency.get("defaultRef")
    if not value:
        raise SystemExit(f"{dep_name}: missing refEnv/defaultRef")
    print(value)
elif query == "cmake-options":
    dependency = dependency_named(dep_name)
    for option in dependency.get("cmakeOptions", []):
        print(option)
elif query == "patches":
    dependency = dependency_named(dep_name)
    for patch in dependency.get("patches", []):
        print(patch)
elif query == "host-cmake-options":
    dependency = dependency_named(dep_name)
    for option in dependency.get("cmakeOptions", []):
        print(option)
    for option in dependency.get("hostCmakeOptions", []):
        print(option)
elif query == "build-targets":
    dependency = dependency_named(dep_name)
    for target in dependency.get("buildTargets", []):
        print(target)
elif query == "host-build-targets":
    dependency = dependency_named(dep_name)
    for target in dependency.get("hostBuildTargets", []):
        print(target)
elif query == "install-components":
    dependency = dependency_named(dep_name)
    for component in dependency.get("installComponents", []):
        print(component)
elif query == "host-install-components":
    dependency = dependency_named(dep_name)
    for component in dependency.get("hostInstallComponents", []):
        print(component)
elif query == "skip-host-install":
    dependency = dependency_named(dep_name)
    print("1" if dependency.get("skipHostInstall", False) else "0")
elif query == "staged-archives":
    dependency = dependency_named(dep_name)
    for archive in dependency.get("stagedArchives", []):
        source = archive.get("from")
        destination = archive.get("to")
        if not source or not destination:
            raise SystemExit(f"{dep_name}: stagedArchives entries require from and to")
        print(f"{source}\t{destination}")
elif query == "installed-archives":
    dependency = dependency_named(dep_name)
    for archive in dependency.get("installedArchives", []):
        source = archive.get("from")
        destination = archive.get("to")
        if not source or not destination:
            raise SystemExit(f"{dep_name}: installedArchives entries require from and to")
        print(f"{source}\t{destination}")
elif query == "installed-files":
    dependency = dependency_named(dep_name)
    for installed_file in dependency.get("installedFiles", []):
        source = installed_file.get("from")
        destination = installed_file.get("to")
        if not source or not destination:
            raise SystemExit(f"{dep_name}: installedFiles entries require from and to")
        print(f"{source}\t{destination}")
elif query == "host-installed-files":
    dependency = dependency_named(dep_name)
    for installed_file in dependency.get("hostInstalledFiles", []):
        source = installed_file.get("from")
        destination = installed_file.get("to")
        if not source or not destination:
            raise SystemExit(f"{dep_name}: hostInstalledFiles entries require from and to")
        print(f"{source}\t{destination}")
else:
    raise SystemExit(f"unknown manifest query: {query}")
PY
}

retry()
{
    local description="$1"
    shift
    local attempt=1

    while true; do
        if "$@"; then
            return 0
        fi

        if [ "$attempt" -ge "$GIT_RETRY_COUNT" ]; then
            return 1
        fi

        printf 'warning: %s failed; retrying in %s seconds (%s/%s)\n' \
            "$description" "$GIT_RETRY_DELAY" "$attempt" "$GIT_RETRY_COUNT" >&2
        sleep "$GIT_RETRY_DELAY"
        attempt=$((attempt + 1))
    done
}

clone_dependency()
{
    local name="$1"
    local url="$2"
    local dest="$3"
    local attempt=1

    while true; do
        if [ -e "$dest" ] && [ ! -d "$dest/.git" ]; then
            case "$dest" in
                "$SRC_DIR"/*) rm -rf "$dest" ;;
                *) die "Refusing to remove non-generated clone path: $dest" ;;
            esac
        fi

        if git clone "$url" "$dest"; then
            return 0
        fi

        case "$dest" in
            "$SRC_DIR"/*) rm -rf "$dest" ;;
            *) die "Refusing to remove non-generated clone path after failed clone: $dest" ;;
        esac

        if [ "$attempt" -ge "$GIT_RETRY_COUNT" ]; then
            die "Failed to clone $name from $url after $GIT_RETRY_COUNT attempts"
        fi

        printf 'warning: clone failed for %s from %s; retrying in %s seconds (%s/%s)\n' \
            "$name" "$url" "$GIT_RETRY_DELAY" "$attempt" "$GIT_RETRY_COUNT" >&2
        sleep "$GIT_RETRY_DELAY"
        attempt=$((attempt + 1))
    done
}

fetch_ref()
{
    local name="$1"
    local dest="$2"
    local ref="$3"
    local attempt=1

    while true; do
        if git -C "$dest" fetch --depth 1 origin "$ref" \
            || git -C "$dest" fetch --depth 1 origin "refs/tags/$ref:refs/tags/$ref"; then
            return 0
        fi

        if [ "$attempt" -ge "$GIT_RETRY_COUNT" ]; then
            die "Failed to fetch $name ref $ref from $(git -C "$dest" remote get-url origin) after $GIT_RETRY_COUNT attempts"
        fi

        printf 'warning: fetch failed for %s ref %s; retrying in %s seconds (%s/%s)\n' \
            "$name" "$ref" "$GIT_RETRY_DELAY" "$attempt" "$GIT_RETRY_COUNT" >&2
        sleep "$GIT_RETRY_DELAY"
        attempt=$((attempt + 1))
    done
}

fetch_git()
{
    local name="$1"
    local url="$2"
    local ref="$3"
    local dest="$SRC_DIR/$name"

    if [ ! -d "$dest/.git" ]; then
        log "Cloning $name"
        clone_dependency "$name" "$url" "$dest"
    fi

    log "Checking out $name at $ref"
    fetch_ref "$name" "$dest" "$ref"
    retry "checkout $name ref $ref" git -C "$dest" checkout --detach FETCH_HEAD \
        || die "Failed to checkout $name at $ref"
}

fetch_sources()
{
    local dep
    local url
    local ref

    while IFS= read -r dep; do
        url="$(manifest_query url "$dep")"
        ref="$(manifest_query ref "$dep")"
        fetch_git "$dep" "$url" "$ref"
    done < <(manifest_query names)
}

check_existing_sources()
{
    local dep
    local missing=0

    while IFS= read -r dep; do
        if [ ! -d "$SRC_DIR/$dep" ]; then
            printf 'error: missing dependency source directory: %s\n' "$SRC_DIR/$dep" >&2
            missing=1
        fi
    done < <(manifest_query names)

    [ "$missing" -eq 0 ] || die "Cannot skip clone/checkout with missing dependency sources"
}

apply_dependency_patch()
{
    local dep="$1"
    local patch_file="$2"
    local source_dir="$SRC_DIR/$dep"

    [ -f "$patch_file" ] || die "Dependency patch does not exist: $patch_file"
    [ -d "$source_dir" ] || return 0

    if git -C "$source_dir" apply --reverse --check "$patch_file" >/dev/null 2>&1; then
        log "Patch already applied for $dep: $(basename "$patch_file")"
        return 0
    fi

    log "Applying patch for $dep: $(basename "$patch_file")"
    git -C "$source_dir" apply "$patch_file" \
        || die "Failed to apply $(basename "$patch_file") to $dep"
}

patch_dependency_sources()
{
    local dep
    local patch

    while IFS= read -r dep; do
        while IFS= read -r patch; do
            [ -n "$patch" ] || continue
            apply_dependency_patch "$dep" "$SCRIPT_DIR/$patch"
        done < <(manifest_query patches "$dep")
    done < <(manifest_query names)
}

common_cmake_args()
{
    local prefix="$1"
    local sdk="$2"
    local archs="$3"

    printf '%s\n' \
        -G Xcode \
        -DCMAKE_INSTALL_PREFIX="$prefix" \
        -DCMAKE_PREFIX_PATH="$prefix;$QT_IOS_PREFIX" \
        -DCMAKE_OSX_SYSROOT="$sdk" \
        -DCMAKE_OSX_ARCHITECTURES="$archs" \
        -DCMAKE_TRY_COMPILE_TARGET_TYPE=STATIC_LIBRARY \
        -DCMAKE_AUTOMOC_COMPILER_PREDEFINES=OFF \
        -DCMAKE_C_FLAGS= \
        -DCMAKE_CXX_FLAGS= \
        -DCMAKE_EXE_LINKER_FLAGS= \
        -DCMAKE_MODULE_LINKER_FLAGS= \
        -DCMAKE_SHARED_LINKER_FLAGS= \
        -DCMAKE_BUILD_TYPE="$CONFIG" \
        -DBUILD_SHARED_LIBS=OFF \
        -DBUILD_TESTING=OFF \
        -DBUILD_QCH=OFF \
        -DBUILD_WITH_QT6=ON \
        -DKF_IGNORE_PLATFORM_CHECK=ON \
        -DKF6_HOST_TOOLING="$HOST_TOOLING_PATH" \
        -DKDE_SKIP_TEST_SETTINGS=ON \
        -DKDE_INSTALL_USE_QT_SYS_PATHS=OFF
}

host_cmake_args()
{
    printf '%s\n' \
        -DCMAKE_INSTALL_PREFIX="$HOST_TOOLS_PREFIX" \
        -DCMAKE_PREFIX_PATH="$HOST_TOOLS_PREFIX;$QT_HOST_PREFIX" \
        -DCMAKE_BUILD_TYPE="$CONFIG" \
        -DBUILD_SHARED_LIBS=OFF \
        -DBUILD_TESTING=OFF \
        -DBUILD_QCH=OFF \
        -DBUILD_WITH_QT6=ON \
        -DKF_IGNORE_PLATFORM_CHECK=ON \
        -DKDE_SKIP_TEST_SETTINGS=ON \
        -DKDE_INSTALL_USE_QT_SYS_PATHS=OFF
}

dependency_cmake_args()
{
    printf '%s\n' \
        -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_ALLOWED=NO \
        -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGNING_REQUIRED=NO \
        -DCMAKE_XCODE_ATTRIBUTE_CODE_SIGN_IDENTITY=
}

extra_cmake_args()
{
    manifest_query cmake-options "$1"
}

extra_host_cmake_args()
{
    manifest_query host-cmake-options "$1"
}

cmake_build()
{
    local build_dir="$1"
    shift

    clean_build_env cmake --build "$build_dir" "$@"
}

stage_archives()
{
    local name="$1"
    local build_dir="$2"
    local sdk="$3"
    local source_rel
    local destination_rel
    local source_path
    local destination_path

    while IFS=$'\t' read -r source_rel destination_rel; do
        [ -n "$source_rel" ] || continue
        source_rel="${source_rel//\{CONFIG\}/$CONFIG}"
        source_rel="${source_rel//\{SDK\}/$sdk}"
        destination_rel="${destination_rel//\{CONFIG\}/$CONFIG}"
        destination_rel="${destination_rel//\{SDK\}/$sdk}"
        source_path="$build_dir/$source_rel"
        destination_path="$build_dir/$destination_rel"

        [ -f "$source_path" ] || die "Cannot stage $name archive; source does not exist: $source_path"
        mkdir -p "$(dirname "$destination_path")"
        cp "$source_path" "$destination_path"
        xcrun ranlib "$destination_path" >/dev/null 2>&1 || true
    done < <(manifest_query staged-archives "$name")
}

install_archives()
{
    local name="$1"
    local build_dir="$2"
    local sdk="$3"
    local prefix="$4"
    local source_rel
    local destination_rel
    local source_path
    local destination_path

    while IFS=$'\t' read -r source_rel destination_rel; do
        [ -n "$source_rel" ] || continue
        source_rel="${source_rel//\{CONFIG\}/$CONFIG}"
        source_rel="${source_rel//\{SDK\}/$sdk}"
        destination_rel="${destination_rel//\{CONFIG\}/$CONFIG}"
        destination_rel="${destination_rel//\{SDK\}/$sdk}"
        source_path="$build_dir/$source_rel"
        destination_path="$prefix/$destination_rel"

        [ -f "$source_path" ] || die "Cannot install $name archive; source does not exist: $source_path"
        mkdir -p "$(dirname "$destination_path")"
        cp "$source_path" "$destination_path"
        xcrun ranlib "$destination_path" >/dev/null 2>&1 || true
    done < <(manifest_query installed-archives "$name")
}

install_files()
{
    local name="$1"
    local build_dir="$2"
    local sdk="$3"
    local prefix="$4"
    local source_rel
    local destination_rel
    local source_path
    local destination_path

    while IFS=$'\t' read -r source_rel destination_rel; do
        [ -n "$source_rel" ] || continue
        source_rel="${source_rel//\{CONFIG\}/$CONFIG}"
        source_rel="${source_rel//\{SDK\}/$sdk}"
        destination_rel="${destination_rel//\{CONFIG\}/$CONFIG}"
        destination_rel="${destination_rel//\{SDK\}/$sdk}"
        source_path="$build_dir/$source_rel"
        destination_path="$prefix/$destination_rel"

        [ -f "$source_path" ] || die "Cannot install $name file; source does not exist: $source_path"
        mkdir -p "$(dirname "$destination_path")"
        cp "$source_path" "$destination_path"
    done < <(manifest_query installed-files "$name")
}

sanitize_host_executable_rpaths()
{
    local executable="$1"
    local rpath
    local has_qt_host_rpath=0

    [ "$(uname -s)" = "Darwin" ] || return 0
    command -v otool >/dev/null 2>&1 || return 0
    command -v install_name_tool >/dev/null 2>&1 || return 0
    file "$executable" | grep -q "Mach-O" || return 0

    while IFS= read -r rpath; do
        if [ "$rpath" = "$QT_HOST_PREFIX/lib" ]; then
            has_qt_host_rpath=1
            continue
        fi

        install_name_tool -delete_rpath "$rpath" "$executable" >/dev/null 2>&1 || true
    done < <(otool -l "$executable" | awk '
        $1 == "cmd" && $2 == "LC_RPATH" {
            getline
            getline
            sub(/^ *path /, "")
            sub(/ \(offset [0-9]+\)$/, "")
            print
        }
    ')

    if [ "$has_qt_host_rpath" -eq 0 ]; then
        install_name_tool -add_rpath "$QT_HOST_PREFIX/lib" "$executable" >/dev/null 2>&1 || true
    fi
}

install_host_files()
{
    local name="$1"
    local build_dir="$2"
    local prefix="$3"
    local source_rel
    local destination_rel
    local source_path
    local destination_path

    while IFS=$'\t' read -r source_rel destination_rel; do
        [ -n "$source_rel" ] || continue
        source_rel="${source_rel//\{CONFIG\}/$CONFIG}"
        destination_rel="${destination_rel//\{CONFIG\}/$CONFIG}"
        source_path="$build_dir/$source_rel"
        destination_path="$prefix/$destination_rel"

        [ -f "$source_path" ] || die "Cannot install host $name file; source does not exist: $source_path"
        mkdir -p "$(dirname "$destination_path")"
        cp "$source_path" "$destination_path"
        chmod +x "$destination_path"
        sanitize_host_executable_rpaths "$destination_path"
    done < <(manifest_query host-installed-files "$name")
}

stage_xcode_config_dirs()
{
    local build_dir="$1"
    local sdk="$2"
    local platform_dir
    local config_link
    local target_name

    [ -d "$build_dir/build" ] || return 0

    while IFS= read -r platform_dir; do
        config_link="$(dirname "$platform_dir")/$CONFIG"
        target_name="$(basename "$platform_dir")"

        if [ -L "$config_link" ]; then
            ln -sfn "$target_name" "$config_link"
        elif [ ! -e "$config_link" ]; then
            ln -s "$target_name" "$config_link"
        fi
    done < <(find "$build_dir/build" -type d -name "$CONFIG-$sdk")
}

configure_build_install()
{
    local name="$1"
    local sdk="$2"
    local archs="$3"
    local prefix="$4"
    local build_root="$5"
    local source_dir="$SRC_DIR/$name"
    local build_dir="$build_root/$name"
    local build_targets=()
    local install_components=()
    local target
    local component

    log "Configuring $name for $sdk ($archs)"
    clean_build_env "$QT_CMAKE" -S "$source_dir" -B "$build_dir" \
        $(common_cmake_args "$prefix" "$sdk" "$archs") \
        $(dependency_cmake_args) \
        $(extra_cmake_args "$name")

    mapfile -t build_targets < <(manifest_query build-targets "$name")
    mapfile -t install_components < <(manifest_query install-components "$name")

    if [ "${#build_targets[@]}" -gt 0 ]; then
        for target in "${build_targets[@]}"; do
            log "Building $name target $target for $sdk"
            cmake_build "$build_dir" --config "$CONFIG" --target "$target" --parallel
        done
    else
        log "Building $name for $sdk"
        cmake_build "$build_dir" --config "$CONFIG" --target ALL_BUILD --parallel
    fi

    stage_archives "$name" "$build_dir" "$sdk"
    install_archives "$name" "$build_dir" "$sdk" "$prefix"
    install_files "$name" "$build_dir" "$sdk" "$prefix"
    stage_xcode_config_dirs "$build_dir" "$sdk"

    if [ "${#install_components[@]}" -gt 0 ]; then
        for component in "${install_components[@]}"; do
            log "Installing $name component $component for $sdk"
            clean_build_env cmake --install "$build_dir" --config "$CONFIG" --component "$component"
        done
    else
        log "Installing $name for $sdk"
        clean_build_env cmake --install "$build_dir" --config "$CONFIG"
    fi
}

configure_build_install_host_tool()
{
    local name="$1"
    local source_dir="$SRC_DIR/$name"
    local build_dir="$HOST_BUILD_ROOT/$name"
    local build_targets=()
    local install_components=()
    local skip_install
    local target
    local component

    log "Configuring host tooling $name"
    clean_build_env "$QT_HOST_CMAKE" -S "$source_dir" -B "$build_dir" \
        $(host_cmake_args) \
        $(extra_host_cmake_args "$name")

    mapfile -t build_targets < <(manifest_query host-build-targets "$name")
    mapfile -t install_components < <(manifest_query host-install-components "$name")
    skip_install="$(manifest_query skip-host-install "$name")"

    if [ "${#build_targets[@]}" -gt 0 ]; then
        for target in "${build_targets[@]}"; do
            log "Building host tooling $name target $target"
            cmake_build "$build_dir" --config "$CONFIG" --target "$target" --parallel
        done
    fi

    install_host_files "$name" "$build_dir" "$HOST_TOOLS_PREFIX"

    if [ "$skip_install" = "1" ]; then
        return 0
    fi

    if [ "${#install_components[@]}" -gt 0 ]; then
        for component in "${install_components[@]}"; do
            log "Installing host tooling $name component $component"
            clean_build_env cmake --install "$build_dir" --config "$CONFIG" --component "$component"
        done
    else
        log "Installing host tooling $name"
        cmake_build "$build_dir" --config "$CONFIG" --target install --parallel
    fi
}

build_host_tooling()
{
    local dep

    while IFS= read -r dep; do
        configure_build_install_host_tool "$dep"
    done < <(manifest_query host-tooling-names)

    [ -f "$HOST_TOOLS_PREFIX/lib/cmake/KF6Config/KF6ConfigCompilerTargets.cmake" ] \
        || die "KConfig host compiler targets were not installed into $HOST_TOOLS_PREFIX"
}

merge_simulator_binary()
{
    local device_file="$1"
    local simulator_file="$2"
    local base_file="$device_file"
    local stripped_file
    local next_file
    local output_file="$device_file.universal.$$"
    local arch

    stripped_file="$device_file.device-only.$$"
    rm -f "$stripped_file" "$output_file"

    for arch in $SIMULATOR_ARCHS; do
        if lipo -archs "$base_file" 2>/dev/null | grep -qw "$arch"; then
            next_file="$stripped_file.$arch"
            lipo -remove "$arch" "$base_file" -output "$next_file"
            if [ "$base_file" != "$device_file" ]; then
                rm -f "$base_file"
            fi
            base_file="$next_file"
        fi
    done

    lipo -create "$base_file" "$simulator_file" -output "$output_file"
    mv "$output_file" "$device_file"

    if [ "$base_file" != "$device_file" ]; then
        rm -f "$base_file"
    fi
    rm -f "$stripped_file" "$stripped_file".*
}

merge_simulator_binaries()
{
    local simulator_file
    local rel
    local device_file

    log "Merging simulator static archives and resource objects into $QT_IOS_PREFIX"
    while IFS= read -r simulator_file; do
        rel="${simulator_file#$SIM_PREFIX/}"
        device_file="$QT_IOS_PREFIX/$rel"
        [ -f "$device_file" ] || continue

        merge_simulator_binary "$device_file" "$simulator_file"
        if [[ "$device_file" == *.a ]]; then
            xcrun ranlib "$device_file" >/dev/null 2>&1 || true
        fi
    done < <(find "$SIM_PREFIX" -type f \( -name '*.a' -o -name '*.o' \))
}

build_dependency_stack()
{
    local dep

    if [ "$SKIP_CLONE_CHECKOUT" = "1" ]; then
        log "Skipping dependency clone/checkout; using sources in $SRC_DIR"
        check_existing_sources
    else
        fetch_sources
    fi

    patch_dependency_sources
    build_host_tooling

    while IFS= read -r dep; do
        configure_build_install "$dep" iphoneos "$DEVICE_ARCHS" "$QT_IOS_PREFIX" "$DEVICE_BUILD_ROOT"
        configure_build_install "$dep" iphonesimulator "$SIMULATOR_ARCHS" "$SIM_PREFIX" "$SIM_BUILD_ROOT"
    done < <(manifest_query names)

    merge_simulator_binaries
}

configure_minuet()
{
    local sdk="$1"
    local archs="$2"
    local build_dir="$3"
    local pkg_config_dir="$QT_IOS_PREFIX/lib/pkgconfig"

    log "Generating Minuet Xcode project for $sdk ($archs)"
    [ -f "$pkg_config_dir/fluidsynth.pc" ] \
        || die "FluidSynth pkg-config file does not exist: $pkg_config_dir/fluidsynth.pc"

    clean_build_env env \
        -u PKG_CONFIG_PATH \
        -u PKG_CONFIG_LIBDIR \
        -u PKG_CONFIG_SYSROOT_DIR \
        PKG_CONFIG_PATH="$pkg_config_dir" \
        PKG_CONFIG_LIBDIR="$pkg_config_dir" \
        "$QT_CMAKE" -S "$MINUET_SRC" -B "$build_dir" \
        $(common_cmake_args "$QT_IOS_PREFIX" "$sdk" "$archs") \
        -DPKG_CONFIG_EXECUTABLE="$PKG_CONFIG_EXECUTABLE" \
        -DCMAKE_XCODE_ATTRIBUTE_PRODUCT_BUNDLE_IDENTIFIER=org.kde.minuet \
        -DCMAKE_XCODE_ATTRIBUTE_ONLY_ACTIVE_ARCH=YES
}

main()
{
    check_environment

    if [ "$BUILD_DEPENDENCIES" = "1" ]; then
        build_dependency_stack
    else
        log "Skipping dependency build because BUILD_DEPENDENCIES=$BUILD_DEPENDENCIES"
    fi

    configure_minuet iphoneos "$DEVICE_ARCHS" "$DEVICE_MINUET_BUILD"
    configure_minuet iphonesimulator "$SIMULATOR_ARCHS" "$SIM_MINUET_BUILD"

    log "Done"
    printf 'Device Xcode project: %s/minuet.xcodeproj\n' "$DEVICE_MINUET_BUILD"
    printf 'Simulator Xcode project: %s/minuet.xcodeproj\n' "$SIM_MINUET_BUILD"
}

main "$@"
