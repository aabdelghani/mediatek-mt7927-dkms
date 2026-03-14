#!/usr/bin/env bash
# Install MediaTek MT7927 DKMS driver on Ubuntu (kernel < 6.19)
#
# Handles:
#   - Prerequisites (dkms, linux-headers)
#   - Stub airoha_offload.h for kernel < 6.19
#   - Source download, patch, DKMS build/install
#   - Module reload
#
# Usage: sudo ./install-ubuntu.sh

set -euo pipefail

DKMS_VERSION="2.4"
DKMS_NAME="mediatek-mt7927"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KVER="$(uname -r)"
KBUILD="/lib/modules/${KVER}/build"

# ── helpers ─────────────────────────────────────────────────────────
info()  { echo -e "\e[1;32m==>\e[0m \e[1m$*\e[0m"; }
warn()  { echo -e "\e[1;33m==> WARNING:\e[0m $*"; }
error() { echo -e "\e[1;31m==> ERROR:\e[0m $*" >&2; exit 1; }

require_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (sudo ./install-ubuntu.sh)"
    fi
}

# ── kernel version check ───────────────────────────────────────────
kernel_needs_stub() {
    local major minor
    major="$(uname -r | cut -d. -f1)"
    minor="$(uname -r | cut -d. -f2)"
    # airoha_offload.h was added in kernel 6.19
    [[ "$major" -lt 6 ]] || { [[ "$major" -eq 6 ]] && [[ "$minor" -lt 19 ]]; }
}

# ── install prerequisites ──────────────────────────────────────────
install_prerequisites() {
    info "Checking prerequisites..."
    local pkgs=()
    dpkg -s dkms &>/dev/null || pkgs+=(dkms)
    dpkg -s "linux-headers-${KVER}" &>/dev/null || pkgs+=("linux-headers-${KVER}")
    dpkg -s python3 &>/dev/null || pkgs+=(python3)
    dpkg -s curl &>/dev/null || pkgs+=(curl)
    dpkg -s unzip &>/dev/null || pkgs+=(unzip)

    if [[ ${#pkgs[@]} -gt 0 ]]; then
        info "Installing: ${pkgs[*]}"
        apt-get update -qq
        apt-get install -y "${pkgs[@]}"
    else
        info "All prerequisites installed"
    fi

    # Ensure DKMS tree exists
    mkdir -p /var/lib/dkms
}

# ── create airoha stub header ──────────────────────────────────────
create_airoha_stub() {
    local header_dir="${KBUILD}/include/linux/soc/airoha"
    local header_file="${header_dir}/airoha_offload.h"

    if [[ -f "$header_file" ]]; then
        info "airoha_offload.h already exists, skipping stub"
        return
    fi

    info "Creating stub airoha_offload.h (kernel ${KVER} < 6.19)"
    mkdir -p "$header_dir"
    cat > "$header_file" << 'STUB'
/* Stub for kernel < 6.19 — airoha hardware offload not available */
#ifndef _AIROHA_OFFLOAD_H
#define _AIROHA_OFFLOAD_H

#include <linux/types.h>
#include <linux/gfp.h>
#include <linux/skbuff.h>

struct airoha_ppe_dev;
struct airoha_npu;

enum airoha_npu_wlan_set_cmd { __AIROHA_NPU_WLAN_SET_DUMMY };
enum airoha_npu_wlan_get_cmd { __AIROHA_NPU_WLAN_GET_DUMMY };

struct airoha_npu_tx_dma_desc { __le32 d[8]; };
struct airoha_npu_rx_dma_desc { __le32 d[8]; };

static inline int airoha_npu_wlan_send_msg(struct airoha_npu *npu, int ifindex,
    enum airoha_npu_wlan_set_cmd cmd, void *val, int len, gfp_t gfp)
{ return -EOPNOTSUPP; }

static inline int airoha_npu_wlan_get_msg(struct airoha_npu *npu, int ifindex,
    enum airoha_npu_wlan_get_cmd cmd, void *val, int len, gfp_t gfp)
{ return -EOPNOTSUPP; }

static inline int airoha_npu_wlan_get_irq_status(struct airoha_npu *npu, int index)
{ return 0; }

static inline void airoha_npu_wlan_set_irq_status(struct airoha_npu *npu, int status) {}
static inline void airoha_npu_wlan_disable_irq(struct airoha_npu *npu, int index) {}

static inline bool airoha_ppe_dev_check_skb(struct airoha_ppe_dev *dev,
    struct sk_buff *skb, u32 hash, bool flag)
{ return false; }

#endif /* _AIROHA_OFFLOAD_H */
STUB
}

# ── download and build sources ──────────────────────────────────────
build_sources() {
    info "Downloading kernel tarball and firmware..."
    make -C "$SCRIPT_DIR" download

    info "Extracting and patching sources..."
    make -C "$SCRIPT_DIR" sources
}

# ── DKMS install ────────────────────────────────────────────────────
dkms_install() {
    # Remove previous DKMS registration if exists
    if dkms status "${DKMS_NAME}/${DKMS_VERSION}" 2>/dev/null | grep -q "${DKMS_NAME}"; then
        info "Removing previous DKMS registration..."
        dkms remove "${DKMS_NAME}/${DKMS_VERSION}" --all 2>/dev/null || true
    fi

    info "Installing source tree and firmware..."
    make -C "$SCRIPT_DIR" install

    info "Registering with DKMS..."
    dkms add "${DKMS_NAME}/${DKMS_VERSION}"

    info "Building modules for kernel ${KVER}..."
    dkms build "${DKMS_NAME}/${DKMS_VERSION}"

    info "Installing modules..."
    dkms install "${DKMS_NAME}/${DKMS_VERSION}"
}

# ── reload modules ──────────────────────────────────────────────────
reload_modules() {
    info "Unloading old mt76 modules..."
    modprobe -r mt7921u mt792x_usb mt7921e mt7921_common \
        mt7925e mt7925_common mt792x_lib mt76_connac_lib \
        mt76_usb mt76 btusb btmtk 2>/dev/null || true

    info "Loading new modules..."
    if modprobe mt7925e && modprobe btusb; then
        info "Modules loaded successfully"
    else
        warn "modprobe failed — a reboot may be required"
    fi
}

# ── verify ──────────────────────────────────────────────────────────
verify() {
    echo ""
    if lsmod | grep -q mt7925e; then
        info "mt7925e is loaded"
        local iface
        iface="$(ip -o link show | grep -oP 'wlp\S+' | head -1)"
        if [[ -n "$iface" ]]; then
            info "WiFi interface: ${iface}"
        fi
    else
        warn "mt7925e not loaded — try rebooting"
    fi

    if lsmod | grep -q btusb; then
        info "btusb is loaded"
    fi
    echo ""
    info "Done! If WiFi doesn't appear, reboot and run: ./test-driver.sh"
}

# ── main ────────────────────────────────────────────────────────────
main() {
    require_root
    install_prerequisites
    if kernel_needs_stub; then
        create_airoha_stub
    fi
    build_sources
    dkms_install
    reload_modules
    verify
}

main "$@"
