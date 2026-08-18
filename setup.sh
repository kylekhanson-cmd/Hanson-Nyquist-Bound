#!/usr/bin/env bash

# Check if script is running with root administrative privileges
if [ "$EUID" -ne 0 ]; then
  echo "Error: Please run this script using sudo or as the root user."
  exit 1
fi

GRUB_CONFIG="/etc/default/grub"
NEW_FLAGS="isolcpus=2-15 nohz_full=2-15 rcu_nocbs=2-15 mitigations=off transparent_hugepage=never"

echo "Initializing #HansonLattice Bare-Metal Node Configuration..."

# Backup current configurations to prevent system lockout
cp "$GRUB_CONFIG" "${GRUB_CONFIG}.bak"
echo "Backup created at ${GRUB_CONFIG}.bak"

# Inject core isolation parameters into the active GRUB boot line
if grep -q "GRUB_CMDLINE_LINUX_DEFAULT" "$GRUB_CONFIG"; then
  # Append flags inside existing default command line
  sed -i "/GRUB_CMDLINE_LINUX_DEFAULT=/s/\"$/ ${NEW_FLAGS}\"/" "$GRUB_CONFIG"
else
  # Append flags inside standard default command line fallback
  sed -i "/GRUB_CMDLINE_LINUX=/s/\"$/ ${NEW_FLAGS}\"/" "$GRUB_CONFIG"
fi

echo "Kernel parameters successfully injected."

# Update system bootloader to commit changes to the hardware layer
if command -v update-grub &> /dev/null; then
  update-grub
elif command -v grub2-mkconfig &> /dev/null; then
  grub2-mkconfig -o /boot/grub2/grub.cfg
else
  echo "Warning: Bootloader update tool not found. Manually regenerate your GRUB configuration."
  exit 1
fi

echo "Configuration finalized. Restart your physical node to isolate cores 2-15."
