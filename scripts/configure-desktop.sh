#!/usr/bin/env bash
# 固化启动参数（本镜像只保留 root 用户，桌面会话以 root 运行）
set -euo pipefail

desktop="${1:-}"
backend="${2:-}"
autostart="${3:-}"
rootfs="${ROOTFS_DIR:-}"
templates="${START_TEMPLATES_DIR:-/tmp/droidspaces-start}"
profile_dir="${DROIDSPACES_DESKTOP_PROFILE_DIR:-/usr/local/lib/droidspaces/desktops}"
config="$rootfs/etc/droidspaces-desktop.conf"

if [[ -r "$rootfs/etc/os-release" ]]; then
    source "$rootfs/etc/os-release"
fi

case "$desktop" in none|gnome) ;; *) echo "无效的桌面：$desktop" >&2; exit 1 ;; esac
case "$backend" in x11|anland-wayland) ;; *) echo "无效的显示后端：$backend" >&2; exit 1 ;; esac
case "$autostart" in true|false) ;; *) echo "无效的桌面自启动值：$autostart" >&2; exit 1 ;; esac

if [[ "$desktop" == none && "$backend" != x11 ]]; then
    echo "不支持的桌面与显示后端组合：$desktop/$backend" >&2
    exit 1
fi
if [[ "$desktop" == gnome && "$backend" != anland-wayland ]]; then
    echo "GNOME 只支持 Anland Wayland。" >&2
    exit 1
fi

cat > "$config" <<EOF
DESKTOP=$desktop
DISPLAY_BACKEND=$backend
EOF
chmod 0644 "$config"

# 桌面专属环境必须在 Dockerfile 完成 /etc/environment 后配置。
if [[ "$desktop" != none ]]; then
    profile="$profile_dir/$desktop.sh"
    [[ -x "$profile" ]] || { echo "桌面配置脚本不存在或不可执行：$profile" >&2; exit 1; }
    ROOTFS_DIR="$rootfs" DROIDSPACES_DESKTOP="$desktop" "$profile" configure-environment "$backend"
fi

if [[ "$desktop" == none ]]; then
    [[ "$autostart" == false ]] || { echo "桌面为 none 时不能启用自动启动" >&2; exit 1; }
    exit 0
fi

if [[ "$autostart" == true ]]; then
    install -Dm0644 "$templates/desktop-session.service" \
        "$rootfs/etc/systemd/system/desktop-session.service"
    install -d -m 0755 "$rootfs/etc/systemd/system/multi-user.target.wants"
    ln -sfn /etc/systemd/system/desktop-session.service \
        "$rootfs/etc/systemd/system/multi-user.target.wants/desktop-session.service"
fi