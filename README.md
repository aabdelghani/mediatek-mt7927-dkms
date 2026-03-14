# mediatek-mt7927-dkms

DKMS driver for MediaTek MT7927 (Filogic 380) - WiFi 7 + Bluetooth 5.4 on Linux.

Builds out-of-tree btusb/btmtk (Bluetooth) and mt76 (WiFi) kernel modules with
device ID and firmware patches not yet in mainline.

## Status

| Component | Status | Details |
|-----------|--------|---------|
| Bluetooth (MT6639 via USB) | **WORKING** | Patched btusb with device ID + firmware |
| WiFi (MT7925e via PCIe) | **WORKING** | 2.4/5/6 GHz, 320MHz, PM, suspend/resume |

**Known issues:**
- TX retransmissions elevated vs baseline (firmware-side, not driver-fixable) ([#26](https://github.com/jetm/mediatek-mt7927-dkms/issues/26))
- Bluetooth USB device may disappear after module reload or DKMS upgrade.
  Workaround: full power cycle — shut down, unplug PSU, wait 10s, power on.
  ([#23](https://github.com/jetm/mediatek-mt7927-dkms/issues/23))

**Recently fixed:**
- 5/6 GHz WPA 4WAY_HANDSHAKE_TIMEOUT — fixed by explicit band_idx assignment ([#24](https://github.com/jetm/mediatek-mt7927-dkms/issues/24))

## Supported Hardware

| Device | BT USB ID | WiFi PCI ID |
|--------|-----------|-------------|
| ASUS ROG Crosshair X870E Hero | 0489:e13a | 14c3:7927 |
| ASUS ROG Strix X870-I | 0489:e13a | 14c3:7927 |
| ASUS ProArt X870E-Creator WiFi | 13d3:3588 | 14c3:6639 |
| ASUS X870E-E | 13d3:3588 | 14c3:7927 |
| Gigabyte X870E Aorus Master X3D | 0489:e10f | 14c3:7927 |
| Gigabyte Z790 AORUS MASTER X | 0489:e10f | 14c3:7927 |
| Lenovo Legion Pro 7 16ARX9 | 0489:e0fa | 14c3:7927 |
| Lenovo Legion Pro 7 16AFR10H | 0489:e0fa | 14c3:7927 |
| TP-Link Archer TBE550E PCIe | 0489:e116 | 14c3:7927 |
| EDUP EP-MT7927BE M.2 | - | 14c3:7927 |
| Foxconn/Azurewave M.2 modules | - | 14c3:6639 |
| AMD RZ738 (MediaTek MT7927) | - | 14c3:0738 |

```bash
lspci | grep -i 14c3              # WiFi (PCIe)
lsusb | grep -iE '0489|13d3|0e8d' # Bluetooth (USB)
```

## Naming Guide

```
MT7927 = combo module on the motherboard (WiFi 7 + BT 5.4, Filogic 380)
  ├── BT side:   internally MT6639, connects via USB
  └── WiFi side: architecturally MT7925, connects via PCIe
```

**MT7902** is a separate WiFi 6E chip (uses mt7921 driver). Included at zero cost
because it shares the mt76 dependency chain.

See [MT7927 WiFi: The Missing Piece](https://jetm.github.io/blog/posts/mt7927-wifi-the-missing-piece/) for the full naming story.

## Install

### Arch Linux (AUR)

```bash
yay -S mediatek-mt7927-dkms
# or
paru -S mediatek-mt7927-dkms
```

Manual:
```bash
git clone https://aur.archlinux.org/mediatek-mt7927-dkms.git
cd mediatek-mt7927-dkms
makepkg -si
```

### Ubuntu (automated)

```bash
git clone https://github.com/aabdelghani/mediatek-mt7927-dkms.git
cd mediatek-mt7927-dkms
sudo ./scripts/install-ubuntu.sh
```

The script handles everything automatically:
- Installs prerequisites (`dkms`, `linux-headers`, `python3`, `curl`, `unzip`)
- Creates `/var/lib/dkms` if missing
- Creates `airoha_offload.h` stub for kernel < 6.19
- Downloads kernel tarball + ASUS firmware ZIP
- DKMS build/install
- Module reload

### Ubuntu (manual)

<details>
<summary>Click to expand manual steps</summary>

The mt76 source is extracted from kernel 6.19.6. On Ubuntu 24.04 HWE (kernel 6.17),
the build fails because `linux/soc/airoha/airoha_offload.h` doesn't exist yet.

```bash
# 1. Prerequisites
sudo apt install dkms linux-headers-$(uname -r)
sudo mkdir -p /var/lib/dkms

# 2. Download and patch sources
git clone https://github.com/aabdelghani/mediatek-mt7927-dkms.git
cd mediatek-mt7927-dkms
make download
make sources

# 3. Create airoha stub (kernel < 6.19 only)
sudo mkdir -p /lib/modules/$(uname -r)/build/include/linux/soc/airoha
sudo tee /lib/modules/$(uname -r)/build/include/linux/soc/airoha/airoha_offload.h > /dev/null << 'EOF'
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
    struct sk_buff *skb, u32 hash, bool flag) { return false; }
#endif
EOF

# 4. Build and install
sudo make install
sudo dkms add mediatek-mt7927/2.4
sudo dkms build mediatek-mt7927/2.4
sudo dkms install mediatek-mt7927/2.4

# 5. Load
sudo modprobe -r mt7921u mt792x_usb mt7921e mt7921_common mt7925e mt7925_common \
    mt792x_lib mt76_connac_lib mt76_usb mt76 btusb btmtk 2>/dev/null
sudo modprobe mt7925e btusb
```

If `modprobe mt7925e` fails with "disagrees about version of symbol", old
in-kernel mt76 modules are still loaded. Unload the entire stack or reboot.

</details>

### Other Distributions

- **NixOS:** [cmspam/mt7927-nixos](https://github.com/cmspam/mt7927-nixos), [clemenscodes/linux-mt7927](https://github.com/clemenscodes/linux-mt7927)
- **Ubuntu (alt):** [giosal/mediatek-mt7927-dkms](https://github.com/giosal/mediatek-mt7927-dkms)
- **Bazzite (Fedora Atomic):** [samutoljamo/bazzite-mt7927](https://github.com/samutoljamo/bazzite-mt7927)

## Post-install

Reload modules without rebooting:

```bash
sudo modprobe -r mt7925e mt7921e btusb
sudo modprobe mt7925e btusb
```

Or just reboot.

## Verification

```bash
./scripts/test-driver.sh              # quick validation (<30s)
./scripts/test-driver.sh wlp9s0       # specify interface
./scripts/stability-test.sh           # 8-hour stability test
./scripts/stability-test.sh -d 2h     # 2-hour test
```

## Project Structure

```
mediatek-mt7927-dkms/
├── patches/
│   ├── wifi/                 # 18 MT7927 + 1 MT7902 WiFi patches
│   └── bt/                   # MT6639 Bluetooth patch
├── kbuild/                   # Kbuild files for out-of-tree build
├── scripts/
│   ├── install-ubuntu.sh     # Automated Ubuntu installer
│   ├── download-driver.sh    # ASUS firmware downloader
│   ├── extract_firmware.py   # Firmware extractor
│   ├── test-driver.sh        # Quick driver validation
│   └── stability-test.sh     # Long-running stability test
├── Makefile                  # Download, patch, build, install
├── dkms.conf                 # DKMS module configuration
├── PKGBUILD                  # Arch Linux AUR package
└── CHANGELOG.md
```

## Troubleshooting

**5/6 GHz authentication retries:**
```bash
nmcli connection modify <ssid> connection.auth-retries 3
```

**Bluetooth rfkill soft-block:**
```bash
rfkill unblock bluetooth
```

**Bluetooth USB device disappeared:**
Full power cycle required — shut down, unplug PSU, wait 10s, power on.
See [#23](https://github.com/jetm/mediatek-mt7927-dkms/issues/23).

**DKMS not built for current kernel:**
```bash
sudo dkms install mediatek-mt7927/2.4
```

## Upstream Tracking

| Submission | Status | Tracking |
|-----------|--------|----------|
| WiFi patches (linux-wireless@) | Under review | [#15](https://github.com/jetm/mediatek-mt7927-dkms/issues/15) |
| BT driver patches (linux-bluetooth@) | v2 pending | [#16](https://github.com/jetm/mediatek-mt7927-dkms/issues/16) |
| BT firmware (linux-firmware) | MR open | [#17](https://github.com/jetm/mediatek-mt7927-dkms/issues/17) |

See [mt76#927](https://github.com/openwrt/mt76/issues/927) for the community tracking issue.

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for the full release history.

## License

GPL-2.0-only
