# Changelog

All notable changes to the MediaTek MT7927 DKMS package are documented here.

Format: `v<pkgver>-<pkgrel>` where pkgver bumps for driver/patch changes
and pkgrel bumps for PKGBUILD packaging changes.

## [2.2-1] - 2026-03-06

### Documentation

- docs: Add CHANGELOG for MediaTek MT7927 DKMS package

### Driver

- mt7927-dkms: Add three new Tested-by tags to all WiFi patches
- mt7927: Add 320MHz BSS RLM patch for mt7925 MCU

### Other

- cliff.toml: Add git-cliff changelog configuration
- ci: Add automated release workflow on PKGBUILD changes

### Packaging

- PKGBUILD: Bump version to 2.2 and reset pkgrel to 1

### Testing

- test-driver: Add EHT/WiFi 7 capability and channel width checks
## [2.1-23] - 2026-03-05

### Documentation

- README: Update supported hardware table and detection commands

### Driver

- mt7927: Clarify authorship attribution in band-idx fix patch
- dkms: Add Tested-by tags from Marcin FM across all patches

### Testing

- test-driver: Add failure tracking and improve error detection
- test-driver.sh: Expand diagnostic coverage for MT7927 hardware
## [2.1-22] - 2026-03-05

### Documentation

- docs: Add Gigabyte X870E Aorus Master X3D to supported hardware
- README: Update upstream tracking and recently fixed sections

### Driver

- mediatek-mt7927-dkms: Refactor patch stack for upstream submission

### Packaging

- pkg: Drop EAPOL patch and renumber WiFi patch series
## [2.1-20] - 2026-03-05

### Packaging

- pkg: Bump release to 2.1-20 with MT6639 BT patch fixes
## [2.1-19] - 2026-03-05

### Documentation

- docs: ASUS ProArt X870E BT USB ID

### Packaging

- pkg: Rename mt6639 to mt7927 in patches, PKGBUILD, and scripts
## [2.1-18] - 2026-03-04

### Driver

- drivers/net: Fix stale pointer comparisons in MLO link teardown

### Packaging

- PKGBUILD: Bump pkgrel to 18 with patch commit headers

### Testing

- test-driver: Improve data path check robustness
## [2.1-17] - 2026-03-04

### Documentation

- README: Update status to reflect fixed WPA, AP mode, and MLO issues
- README: Add Bazzite packaging reference and fix patch sign-off

### Packaging

- PKGBUILD: Bump pkgrel to 17 with MLO and MAC reset patch updates
## [2.1-16] - 2026-03-04

### Documentation

- doc: Add udev rule for Bluetooth rfkill auto-unblock
- README: Remove MT6639 Bluetooth udev auto-unblock instructions
- README: Document project roadmap and known limitations

### Driver

- drivers: Add MediaTek MT7927 WiFi 7/BT 5.4 DKMS package README
- mediatek-mt7927-dkms: Remove EAPOL RX header translation patch

### Internal

- style: Convert indentation from spaces to tabs

### Packaging

- PKGBUILD: Split WiFi patches into numbered series, add MLO and mac_reset
## [2.1-12] - 2026-02-27

### Driver

- mediatek-mt7927-dkms: Replace EAPOL patch with connection state fix
- mediatek-mt7927-dkms: Remove upstream-merged WiFi connection patch
- mediatek-mt7927-dkms: Fix EAPOL frame handling during authentication

### Packaging

- pkgbuild: Add EAPOL frame patch to fix WiFi 6E authentication
- pkg: Switch to kernel tarball for source and remove download logic
## [2.1-8] - 2026-02-26

### Driver

- mt6639-bt: Add USB ID 13d3:3588 for ASUS X870E-E
- drivers/bluetooth: Add MT7927 USB ID for TP-Link TBE550E
- mediatek/bt: Bump pkgrel for MT6639 firmware persistence optimization
- mediatek-mt7927-dkms: Add WiFi 7 320MHz bandwidth support
## [2.1-5] - 2026-02-25

### Driver

- mediatek-mt7927-dkms: Bump pkgrel to 2
- mediatek-mt7927-dkms: Update device support list and patch checksums
- mediatek-mt7927-dkms: Bump package release and update checksums
- mediatek-mt7927-dkms: Bump package release to 5
## [2.0-8] - 2026-02-24

### Driver

- wifi/mt6639: Refine DMA initialization and power state handling
- drivers/net/wireless/mediatek/mt76: Add MT6639 combo chip support

### Other

- fix is_mt6639_hw probe bug, enable PM, add 320MHz wiphy caps

### Packaging

- pkgbuild: Bump pkgrel to 2 for SRCDEST support
## [2.0-6] - 2026-02-24

### Driver

- dkms: Reformat patchmodule script indentation
- wifi: Add MT6639/MT7927 WiFi support via mt7925e driver patches

### Packaging

- pkg: Generalize MT7927/MT6639 support to multiple OEM devices
## [2.0-3] - 2026-02-20

### Driver

- mediatek-mt7927-dkms: Add WiFi modules and auto-download support

### Other

- btusb-mt7927-dkms: Improve driver ZIP detection and toolchain handling
## [2.0-1] - 2026-02-16

### Other

- Initial release: DKMS bluetooth module for MediaTek MT7927 (MT6639)

