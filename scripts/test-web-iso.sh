#!/bin/bash
# ==============================================================================
# AetherOS Cloud ISO Web Runner
# Runs inside GitHub Codespaces (100% in your browser - zero local download)
# ==============================================================================

set -euo pipefail

echo "=========================================================="
echo "    AetherOS Cloud ISO Browser Runner (Zero Local Download)"
echo "=========================================================="

EDITION="${1:-}"

EDITION="standard"
ARTIFACT_NAME="AetherOS-1.0-Standard-amd64-iso"
ISO_PATTERN="*.iso"
echo "==> Selected: AetherOS Unified Edition (128MB RAM - Full Desktop)"

# 1. Install QEMU and noVNC web viewer
sudo apt-get update -qq
sudo apt-get install -y -qq qemu-system-x86 novnc websockify curl gh

sudo ln -sf /usr/share/novnc/vnc.html /usr/share/novnc/index.html 2>/dev/null || true

# 2. Clean old downloaded ISOs to ensure latest build is fetched
rm -rf "/tmp/iso-download/${EDITION}"
mkdir -p "/tmp/iso-download/${EDITION}"

# 3. Fetch latest built ISO from GitHub Actions
echo "==> Downloading latest ${ARTIFACT_NAME} from GitHub Actions..."
gh run download -R S-Herobrine/AetherOS --name "${ARTIFACT_NAME}" --dir "/tmp/iso-download/${EDITION}" 2>/dev/null || {
    echo "==> Downloading by latest run ID..."
    RUN_ID=$(gh run list -R S-Herobrine/AetherOS -L 5 --json databaseId --jq '.[0].databaseId')
    gh run download "${RUN_ID}" -R S-Herobrine/AetherOS --name "${ARTIFACT_NAME}" --dir "/tmp/iso-download/${EDITION}" 2>/dev/null || true
}

if [ -z "$(find "/tmp/iso-download/${EDITION}" -name "*.iso" 2>/dev/null | head -n1)" ]; then
    ALT_NAME="${ARTIFACT_NAME/AetherOS/ApexOS}"
    echo "==> Checking fallback artifact ${ALT_NAME}..."
    gh run download -R S-Herobrine/AetherOS --name "${ALT_NAME}" --dir "/tmp/iso-download/${EDITION}" 2>/dev/null || true
fi

ISO_PATH=$(find "/tmp/iso-download/${EDITION}" -name "*.iso" | head -n1)

if [ -z "${ISO_PATH}" ]; then
    echo "Error: Could not locate downloaded ISO."
    exit 1
fi

echo "==> Successfully downloaded: ${ISO_PATH}"
ls -lh "${ISO_PATH}"

# 4. Clean up any existing instances on ports 6080 and 5900
sudo fuser -k 6080/tcp 5900/tcp 2>/dev/null || true
pkill -9 -f websockify 2>/dev/null || true
pkill -9 -f qemu-system-x86 2>/dev/null || true
sleep 1

# 5. Start noVNC web bridge with explicit IPv4 binding (127.0.0.1:5900)
echo "==> Starting web display bridge on port 6080..."
websockify -D --web=/usr/share/novnc/ 6080 127.0.0.1:5900

# 6. Check CPU virtualization support & high-speed multi-threaded emulation
CPU_FLAGS="-accel tcg,thread=multi -cpu max"
if [ -e /dev/kvm ] && [ -r /dev/kvm ] && [ -w /dev/kvm ]; then
    CPU_FLAGS="-enable-kvm -cpu host"
    echo "==> Hardware KVM acceleration enabled!"
else
    echo "==> Multi-threaded CPU acceleration enabled (4 threads)!"
fi

# 7. Create virtual drive for installer testing
rm -f /tmp/AetherOS-virtual-drive.qcow2
qemu-img create -f qcow2 /tmp/AetherOS-virtual-drive.qcow2 10G

echo "=========================================================="
echo "  AetherOS ${EDITION^^} IS STARTING!"
echo "  Open Port 6080 in your browser to view the screen."
echo "  Boot log will stream in the terminal below."
echo "=========================================================="

# Detect available host CPU cores and memory
HOST_CORES=$(nproc 2>/dev/null || echo 2)
QEMU_SMP=$(( HOST_CORES > 2 ? 4 : HOST_CORES ))

# 8. Launch QEMU with multi-threading and virtio high-speed GPU
exec qemu-system-x86_64 \
    ${CPU_FLAGS} \
    -m 3584 \
    -smp "${QEMU_SMP}" \
    -vga virtio \
    -usb \
    -device usb-tablet \
    -serial mon:stdio \
    -vnc 127.0.0.1:0 \
    -cdrom "${ISO_PATH}" \
    -hda /tmp/AetherOS-virtual-drive.qcow2 \
    -boot d
