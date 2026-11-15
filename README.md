# Droidspaces RootFS — Fedora 45 + GNOME

为 Android 上的 [Droidspaces](https://github.com/ravindu644/Droidspaces-OSS/) 构建 **Fedora 45 + GNOME（Anland Wayland）** 的 ARM64 根文件系统，产物为 `.tar.xz`，导入 Droidspaces 即可使用。

本仓库只保留这一条流水线：其他发行版与桌面环境（KDE、Niri、Hyprland、Mango、Denial、Anland Next）已移除。

## 产物内容

| 组成 | 版本 / 说明 |
| --- | --- |
| 基础系统 | Fedora 45（arm64，`fedora:45`） |
| 桌面 | GNOME 51（Fedora 45 自带版本），开机自启动 |
| 合成器 | Anland 补丁版 Mutter + 配套补丁版 Xwayland（来自预编译包仓库） |
| GPU | Mesa for Android Container 的 `fedora_45` 资产（kgsl / turnip）+ 视频解码驱动 `msm_drm_drv_video.so` |
| 其他 | Google Chrome（arm64）、Fcitx5 中文输入法、中文本地化与上海时区、开发/压缩工具（可选）、Docker（可选） |
| 运行时工具 | `dstui`（Droidspaces TUI）、GPU 切换器、视频解码管理、USB 管理器 |

GNOME 49 起已移除 X11 会话，因此本流程的 GNOME **只能**通过 Anland Wayland 运行；`desktop=none` 时使用 X11/纯命令行。

## 前置条件：Anland 预编译包

GNOME 需要打过 Anland 补丁的 Mutter，它不是发行版自带的包。上游 [`droidspaces-package`](https://github.com/Goldzxcbug/droidspaces-package) 目前**没有** `fedora45` 资产，因此要么等上游发布，要么自建：

- Anland Mutter：`anland-gnome-fedora45-mutter-*.tar.xz`（配方见 [`wzk0/anland`](https://github.com/wzk0/anland) 的 `producers/gnome/Fedora45_v5`）
- Mesa：`mesa-for-android-container_*_fedora_45_arm64.tar.gz`（上游 [`lfdevs/mesa-for-android-container`](https://github.com/lfdevs/mesa-for-android-container) 已提供，需要在自己的 `droidspaces-package` 里跑 `distribute-mesa.yml` 分发）

构建时把 `wayland_package_repository` 指向持有这些 Release 的仓库（例如 `wzk0/droidspaces-package`）。上游发布 `fedora45` 资产后可改回默认值。

## 构建

仓库 → `Actions` → **编译并发布 Droidspaces RootFS** → `Run workflow`。

常用参数：

| 输入 | 默认值 | 说明 |
| --- | --- | --- |
| `desktop` | `GNOME` | `GNOME` 或 `none`（纯命令行） |
| `display_backend` | `anland-wayland` | GNOME 强制 Wayland |
| `PulseAudio` | `none` | Anland 使用应用内置音频，Wayland 下自动关闭 |
| `custom_username` | `Gold` | 普通用户，初始密码 `1234` |
| `enable_zh_tz` | `true` | 中文 locale + 上海时区 |
| `enable_mesa` | `true` | 骁龙 GPU 支持（Wayland 必需） |
| `enable_8gen2_wayland` | `false` | 骁龙 8 Gen 2 花屏修复 |
| `enable_srf` | `true` | Fcitx5 输入法 |
| `enable_binfmt` | `false` | 跨架构（qemu-user-static）支持 |
| `enable_yj` | `true` | NAT 与 Android 硬件识别 |
| `enable_kfgj` / `enable_zip` / `enable_docker` | `false` / `true` / `false` | 开发工具、压缩工具、Docker |
| `wayland_package_repository` | `Goldzxcbug/droidspaces-package` | Anland/Mesa 预编译包来源 |

产物发布到本仓库的 Releases（`Fedora-45-gnome-Wayland-Droidspaces-rootfs-aarch64-<版本>.tar.xz`，约 890 MB）。归档第一个文件是 `container.config`，包含推荐配置（`enable_anland=1`、`enable_gpu_mode=1`、内网 DNS 等），Droidspaces 导入向导会自动加载。

## 导入与首次启动

1. 下载 `.tar.xz`，在 Droidspaces 中导入为 RootFS；
2. 创建容器时按向导建议启用 Anland / GPU 模式（也可以用归档里的 `container.config`）；
3. 首次进入后确认：

```bash
mutter --version            # 应包含 anland
gnome-shell --version       # 51.x
glxinfo -B | grep -i renderer
gnome-anland --check        # GNOME 会话预检
```

## 仓库结构

```
Fedora-45.Dockerfile                 # 唯一的镜像定义（两阶段：customizer → export）
build_rootfs-native.sh               # 原生 ARM64 构建 + 打包 xz（Actions 使用）
scripts/lib/desktop-config.sh        # 目标/桌面/后端白名单（只有 Fedora-45 + GNOME|none）
scripts/lib/anland-build.sh          # Anland Release revision 解析
scripts/lib/rootfs-config.sh         # 生成 container.config 并写入归档头部
scripts/desktops/gnome.sh            # Fedora 上的 GNOME 包集合与环境变量
scripts/tui/install-anland-gnome.sh  # Anland Mutter/Xwayland 包安装器
scripts/tui/install-mesa.sh          # Mesa + 视频解码驱动安装器
scripts/tui/droidspaces-tui.sh       # 容器内 TUI（dstui）
scripts/configure-*.sh               # 桌面 / Chrome 配置
.github/workflows/                   # build-rootfs-releases.yml（入口）+ core（实现）+ clear（清理旧运行）
```

## 已知限制

- 只有 GNOME 在 Fedora 45 上可用；其他桌面需要各自 `fedora45` 的 Anland 配方。
- `systemd 257 旧内核兼容` 没有 Fedora 45 的预编译包，已从流程中移除。
- 构建机为 `ubuntu-24.04-arm`（原生 ARM64）；本地构建需要 docker buildx。

## 致谢

- [Droidspaces-OSS](https://github.com/ravindu644/Droidspaces-OSS/)：运行环境
- [Anland](https://github.com/superturtlee/anland)：Wayland 显示后端
- [mesa-for-android-container](https://github.com/lfdevs/mesa-for-android-container)：骁龙 GPU 驱动
- [droidspaces-media-decode](https://github.com/Re-s/droidspaces-media-decode)：硬件视频解码
- [droidspaces-package](https://github.com/Goldzxcbug/droidspaces-package)：Anland 预编译包与分发
- [Droidspaces USB Manager](https://github.com/Yizhou147/Droidspaces-USB-Manager)：USB/ADB 管理

许可证见 [LICENSE](LICENSE)（本项目基于 [Goldzxcbug/Droidspaces-rootfs-Desktop-builder](https://github.com/Goldzxcbug/Droidspaces-rootfs-Desktop-builder)）。