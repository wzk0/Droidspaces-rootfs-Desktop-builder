#!/usr/bin/env bash

# 本仓库只维护一条流水线：Fedora 45 + GNOME（Anland Wayland）。
# GNOME 49 起已移除 X11 会话，因此 GNOME 只能通过 Anland Wayland 运行。

desktop_normalize() {
    case "${1:-}" in
        none) printf '%s\n' none ;;
        GNOME|gnome) printf '%s\n' gnome ;;
        *) return 1 ;;
    esac
}

desktop_label() {
    case "${1:-}" in
        none) printf '%s\n' none ;;
        gnome) printf '%s\n' GNOME ;;
        *) return 1 ;;
    esac
}

display_backend_normalize() {
    case "${1:-}" in
        'Anland Wayland'|anland-wayland|'') printf '%s\n' anland-wayland ;;
        X11|x11) printf '%s\n' x11 ;;
        *) return 1 ;;
    esac
}

display_backend_label() {
    case "${1:-}" in
        anland-wayland) printf '%s\n' Wayland ;;
        x11) printf '%s\n' X11 ;;
        *) return 1 ;;
    esac
}

target_is_known() {
    case "${1:-}" in
        Fedora-45) return 0 ;;
        *) return 1 ;;
    esac
}

desktop_target_supported() {
    local target="${1:-}"
    local desktop="${2:-}"

    target_is_known "$target" || return 1
    case "$desktop" in
        none|gnome) return 0 ;;
        *) return 1 ;;
    esac
}

desktop_backend_supported() {
    local target="${1:-}"
    local desktop="${2:-}"
    local backend="${3:-}"

    desktop_target_supported "$target" "$desktop" || return 1
    case "$desktop:$backend" in
        none:x11) return 0 ;;
        gnome:anland-wayland) return 0 ;;
        *) return 1 ;;
    esac
}