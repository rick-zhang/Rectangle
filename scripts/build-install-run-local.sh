#!/usr/bin/env bash

set -euo pipefail

APP_NAME="Rectangle"
BUNDLE_ID="com.knollsoft.Rectangle"
SCHEME="Rectangle"
CONFIGURATION="${CONFIGURATION:-Debug}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_PATH="$REPO_ROOT/Rectangle.xcodeproj"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-$REPO_ROOT/build/LocalInstallDerivedData}"
INSTALL_DIR="${INSTALL_DIR:-/Applications}"
INSTALL_APP_PATH="$INSTALL_DIR/$APP_NAME.app"
BUILT_APP_PATH="$DERIVED_DATA_PATH/Build/Products/$CONFIGURATION/$APP_NAME.app"
PROCESS_NAMES=("$APP_NAME" "${APP_NAME}Launcher")
PLIST_BUDDY="/usr/libexec/PlistBuddy"
USE_SUDO=0

log() {
    printf '[local-install] %s\n' "$*"
}

fail() {
    printf '[local-install] ERROR: %s\n' "$*" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || fail "缺少命令：$1"
}

read_bundle_id() {
    "$PLIST_BUDDY" -c 'Print :CFBundleIdentifier' "$1/Contents/Info.plist" 2>/dev/null || true
}

find_conflicting_pids() {
    local name
    for name in "${PROCESS_NAMES[@]}"; do
        /usr/bin/pgrep -x "$name" 2>/dev/null || true
    done | /usr/bin/sort -u
}

describe_pids() {
    local pids pid_list
    pids="$(find_conflicting_pids)"
    [[ -n "$pids" ]] || return 0

    pid_list="$(printf '%s\n' "$pids" | /usr/bin/paste -sd, -)"
    /bin/ps -o pid= -o command= -p "$pid_list" 2>/dev/null || true
}

wait_for_no_conflicts() {
    local timeout="$1"
    local deadline=$((SECONDS + timeout))

    while (( SECONDS < deadline )); do
        if [[ -z "$(find_conflicting_pids)" ]]; then
            return 0
        fi
        sleep 1
    done

    [[ -z "$(find_conflicting_pids)" ]]
}

quit_conflicting_processes() {
    local pids pid
    pids="$(find_conflicting_pids)"
    [[ -n "$pids" ]] || return 0

    log "检测到正在运行的 Rectangle 相关进程："
    describe_pids | /usr/bin/sed 's/^/  /'

    /usr/bin/osascript -e "tell application id \"$BUNDLE_ID\" to quit" >/dev/null 2>&1 || true
    if wait_for_no_conflicts 15; then
        log "已正常退出旧进程。"
        return 0
    fi

    log "旧进程未在 15 秒内退出，发送 TERM。"
    for pid in $(find_conflicting_pids); do
        /bin/kill -TERM "$pid" 2>/dev/null || true
    done
    if wait_for_no_conflicts 5; then
        log "旧进程已退出。"
        return 0
    fi

    log "旧进程仍未退出，发送 KILL。"
    for pid in $(find_conflicting_pids); do
        /bin/kill -KILL "$pid" 2>/dev/null || true
    done
    if ! wait_for_no_conflicts 5; then
        log "仍然存在冲突进程："
        describe_pids | /usr/bin/sed 's/^/  /'
        fail "无法结束已有 Rectangle 进程，请手动退出后重试。"
    fi
}

run_install_command() {
    if [[ "$USE_SUDO" -eq 1 ]]; then
        /usr/bin/sudo "$@"
    else
        "$@"
    fi
}

prepare_install_permissions() {
    local install_parent
    install_parent="$(dirname "$INSTALL_DIR")"

    if [[ ! -d "$INSTALL_DIR" && ! -w "$install_parent" ]]; then
        USE_SUDO=1
    elif [[ -d "$INSTALL_DIR" && ! -w "$INSTALL_DIR" ]]; then
        USE_SUDO=1
    fi

    if [[ "$USE_SUDO" -eq 1 ]]; then
        log "安装目录需要管理员权限，后续步骤可能要求输入本机密码。"
    fi

    run_install_command /bin/mkdir -p "$INSTALL_DIR"
}

validate_paths() {
    [[ -d "$PROJECT_PATH" ]] || fail "未找到 Xcode 工程：$PROJECT_PATH"

    case "$INSTALL_APP_PATH" in
        */Rectangle.app) ;;
        *) fail "拒绝安装到非 Rectangle.app 路径：$INSTALL_APP_PATH" ;;
    esac

    if [[ "$INSTALL_APP_PATH" == "$BUILT_APP_PATH" ]]; then
        fail "安装路径不能与构建产物路径相同：$INSTALL_APP_PATH"
    fi
}

build_app() {
    log "开始构建 $CONFIGURATION 版本。"
    /usr/bin/xcodebuild \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -configuration "$CONFIGURATION" \
        -derivedDataPath "$DERIVED_DATA_PATH" \
        build \
        CODE_SIGN_IDENTITY="-"

    [[ -d "$BUILT_APP_PATH" ]] || fail "未找到构建产物：$BUILT_APP_PATH"
    [[ -x "$BUILT_APP_PATH/Contents/MacOS/$APP_NAME" ]] || fail "构建产物缺少可执行文件。"

    local built_bundle_id
    built_bundle_id="$(read_bundle_id "$BUILT_APP_PATH")"
    [[ "$built_bundle_id" == "$BUNDLE_ID" ]] || fail "构建产物 bundle id 不正确：$built_bundle_id"
}

install_app() {
    local tmp_app old_app installed_bundle_id
    tmp_app="$INSTALL_DIR/.$APP_NAME.installing.$$"
    old_app="$INSTALL_DIR/.$APP_NAME.previous.$$"

    prepare_install_permissions

    run_install_command /bin/rm -rf "$tmp_app" "$old_app"

    log "复制构建产物到临时安装目录。"
    if ! run_install_command /usr/bin/ditto "$BUILT_APP_PATH" "$tmp_app"; then
        run_install_command /bin/rm -rf "$tmp_app" 2>/dev/null || true
        fail "复制构建产物失败。"
    fi

    if [[ -e "$INSTALL_APP_PATH" || -L "$INSTALL_APP_PATH" ]]; then
        log "发现已安装版本，将替换：$INSTALL_APP_PATH"
        if ! run_install_command /bin/mv "$INSTALL_APP_PATH" "$old_app"; then
            run_install_command /bin/rm -rf "$tmp_app" 2>/dev/null || true
            fail "无法移走已有版本：$INSTALL_APP_PATH"
        fi
    else
        log "未发现已安装版本，将安装到：$INSTALL_APP_PATH"
    fi

    if ! run_install_command /bin/mv "$tmp_app" "$INSTALL_APP_PATH"; then
        if [[ -e "$old_app" || -L "$old_app" ]]; then
            run_install_command /bin/mv "$old_app" "$INSTALL_APP_PATH" 2>/dev/null || true
        fi
        run_install_command /bin/rm -rf "$tmp_app" 2>/dev/null || true
        fail "替换安装失败，已尝试恢复原版本。"
    fi

    run_install_command /bin/rm -rf "$old_app"

    installed_bundle_id="$(read_bundle_id "$INSTALL_APP_PATH")"
    [[ "$installed_bundle_id" == "$BUNDLE_ID" ]] || fail "安装后的 bundle id 不正确：$installed_bundle_id"
    [[ -x "$INSTALL_APP_PATH/Contents/MacOS/$APP_NAME" ]] || fail "安装后的 app 缺少可执行文件。"

    log "安装完成：$INSTALL_APP_PATH"
}

launch_app() {
    local pids pid command expected_exec deadline
    expected_exec="$INSTALL_APP_PATH/Contents/MacOS/$APP_NAME"
    deadline=$((SECONDS + 30))

    log "启动本地安装版本。"
    /usr/bin/open "$INSTALL_APP_PATH"

    while (( SECONDS < deadline )); do
        pids="$(/usr/bin/pgrep -x "$APP_NAME" 2>/dev/null || true)"
        for pid in $pids; do
            command="$(/bin/ps -p "$pid" -o command= 2>/dev/null || true)"
            case "$command" in
                "$expected_exec"*)
                    log "启动成功，进程 PID：$pid"
                    return 0
                    ;;
            esac
        done
        sleep 1
    done

    log "当前 Rectangle 相关进程："
    describe_pids | /usr/bin/sed 's/^/  /'
    fail "未能确认 $INSTALL_APP_PATH 已成功运行。"
}

main() {
    require_command xcodebuild
    require_command ditto
    require_command open
    require_command pgrep
    require_command osascript
    [[ -x "$PLIST_BUDDY" ]] || fail "缺少命令：$PLIST_BUDDY"

    validate_paths
    build_app
    quit_conflicting_processes
    install_app
    launch_app
}

main "$@"
