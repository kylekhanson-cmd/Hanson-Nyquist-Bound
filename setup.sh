#!/bin/bash

# Low-Latency Isolation Setup Script
# Production-ready bash script for CPU isolation configuration
# Isolates CPUs 2-15 for low-latency workloads

set -e

# Color output for readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
GRUB_CONFIG="/etc/default/grub"
GRUB_BACKUP="${GRUB_CONFIG}.backup.$(date +%s)"
ISOLATION_PARAMS="isolcpus=2-15 nohz_full=2-15 rcu_nocbs=2-15 mitigations=off transparent_hugepage=never"

echo -e "${YELLOW}Low-Latency CPU Isolation Setup${NC}"
echo "=================================="

# Check for root privileges
if [[ $EUID -ne 0 ]]; then
   echo -e "${RED}Error: This script must be run as root${NC}"
   exit 1
fi

echo -e "${GREEN}✓${NC} Running as root"

# Verify GRUB config exists
if [[ ! -f "$GRUB_CONFIG" ]]; then
    echo -e "${RED}Error: GRUB config not found at $GRUB_CONFIG${NC}"
    exit 1
fi

echo -e "${GREEN}✓${NC} GRUB config found"

# Backup GRUB configuration
cp "$GRUB_CONFIG" "$GRUB_BACKUP"
echo -e "${GREEN}✓${NC} Backed up GRUB config to $GRUB_BACKUP"

# Check if isolation parameters already exist
if grep -q "isolcpus=" "$GRUB_CONFIG"; then
    echo -e "${YELLOW}⚠${NC} Isolation parameters already present in GRUB config"
    echo "  Current GRUB_CMDLINE_LINUX:"
    grep "GRUB_CMDLINE_LINUX=" "$GRUB_CONFIG"
    read -p "Continue with update? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Aborted. Restoring backup..."
        cp "$GRUB_BACKUP" "$GRUB_CONFIG"
        exit 0
    fi
    # Remove existing isolation parameters
    sed -i 's/isolcpus=[^ ]*//' "$GRUB_CONFIG"
    sed -i 's/nohz_full=[^ ]*//' "$GRUB_CONFIG"
    sed -i 's/rcu_nocbs=[^ ]*//' "$GRUB_CONFIG"
fi

# Append isolation parameters to GRUB_CMDLINE_LINUX
if grep -q "^GRUB_CMDLINE_LINUX=\"" "$GRUB_CONFIG"; then
    sed -i "s/^GRUB_CMDLINE_LINUX=\"/GRUB_CMDLINE_LINUX=\"${ISOLATION_PARAMS} /" "$GRUB_CONFIG"
elif grep -q "^GRUB_CMDLINE_LINUX='" "$GRUB_CONFIG"; then
    sed -i "s/^GRUB_CMDLINE_LINUX='/GRUB_CMDLINE_LINUX='${ISOLATION_PARAMS} /" "$GRUB_CONFIG"
else
    echo "GRUB_CMDLINE_LINUX=\"${ISOLATION_PARAMS}\"" >> "$GRUB_CONFIG"
fi

echo -e "${GREEN}✓${NC} Added isolation parameters to GRUB config"
echo "  Parameters: $ISOLATION_PARAMS"

# Update GRUB bootloader
echo "Updating GRUB bootloader..."
if command -v update-grub &> /dev/null; then
    update-grub
    echo -e "${GREEN}✓${NC} GRUB updated with update-grub"
elif command -v grub2-mkconfig &> /dev/null; then
    grub2-mkconfig -o /boot/grub2/grub.cfg
    echo -e "${GREEN}✓${NC} GRUB updated with grub2-mkconfig"
else
    echo -e "${RED}Error: Neither update-grub nor grub2-mkconfig found${NC}"
    echo "Restoring backup and exiting..."
    cp "$GRUB_BACKUP" "$GRUB_CONFIG"
    exit 1
fi

# Verify configuration
echo "Verifying configuration..."
if grep -q "isolcpus=2-15" "$GRUB_CONFIG" && \
   grep -q "nohz_full=2-15" "$GRUB_CONFIG" && \
   grep -q "rcu_nocbs=2-15" "$GRUB_CONFIG" && \
   grep -q "mitigations=off" "$GRUB_CONFIG" && \
   grep -q "transparent_hugepage=never" "$GRUB_CONFIG"; then
    echo -e "${GREEN}✓${NC} Configuration verified successfully"
    echo ""
    echo -e "${GREEN}Setup completed successfully!${NC}"
    echo ""
    echo "Next steps:"
    echo "1. Reboot your system: sudo reboot"
    echo "2. After reboot, verify isolation with: cat /proc/cmdline"
    echo "3. Monitor CPU isolation with: cat /sys/devices/system/cpu/isolated"
    echo ""
    echo "To rollback if needed:"
    echo "  sudo cp $GRUB_BACKUP $GRUB_CONFIG"
    echo "  sudo update-grub"
    echo "  sudo reboot"
else
    echo -e "${RED}Error: Configuration verification failed${NC}"
    echo "Restoring backup and exiting..."
    cp "$GRUB_BACKUP" "$GRUB_CONFIG"
    if command -v update-grub &> /dev/null; then
        update-grub
    elif command -v grub2-mkconfig &> /dev/null; then
        grub2-mkconfig -o /boot/grub2/grub.cfg
    fi
    exit 1
fi

exit 0
