#!/bin/bash

################################################################################
# HansonLattice Framework - Low-Latency Isolation Setup Script
# Purpose: Automates configuration of CPU isolation and latency optimization
#          parameters in GRUB bootloader for real-time performance
################################################################################

set -euo pipefail

# Color output for readability
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration parameters
GRUB_CONFIG="/etc/default/grub"
GRUB_BACKUP="${GRUB_CONFIG}.backup.$(date +%s)"
ISOLATION_PARAMS="isolcpus=2-15 nohz_full=2-15 rcu_nocbs=2-15 mitigations=off transparent_hugepage=never"

################################################################################
# Utility Functions
################################################################################

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root"
        exit 1
    fi
}

backup_grub() {
    if [[ ! -f "$GRUB_BACKUP" ]]; then
        cp "$GRUB_CONFIG" "$GRUB_BACKUP"
        log_info "Created backup: $GRUB_BACKUP"
    else
        log_warn "Backup already exists: $GRUB_BACKUP"
    fi
}

check_grub_config_exists() {
    if [[ ! -f "$GRUB_CONFIG" ]]; then
        log_error "GRUB configuration file not found: $GRUB_CONFIG"
        exit 1
    fi
}

append_isolation_params() {
    local grub_cmdline="GRUB_CMDLINE_LINUX_DEFAULT"
    
    log_info "Checking current GRUB configuration..."
    
    # Extract existing GRUB_CMDLINE_LINUX_DEFAULT
    if grep -q "^${grub_cmdline}=" "$GRUB_CONFIG"; then
        local current_value=$(grep "^${grub_cmdline}=" "$GRUB_CONFIG" | cut -d'"' -f2)
        log_info "Current parameters: $current_value"
        
        # Check if isolation parameters already exist
        if echo "$current_value" | grep -q "isolcpus"; then
            log_warn "Isolation parameters already present in GRUB config"
            log_info "Skipping parameter append"
            return 0
        fi
        
        # Append new parameters
        local new_value="${current_value} ${ISOLATION_PARAMS}"
        sed -i "s|^${grub_cmdline}=\".*\"|${grub_cmdline}=\"${new_value}\"|" "$GRUB_CONFIG"
        log_info "Appended isolation parameters to GRUB_CMDLINE_LINUX_DEFAULT"
    else
        log_error "GRUB_CMDLINE_LINUX_DEFAULT not found in $GRUB_CONFIG"
        exit 1
    fi
}

update_grub_bootloader() {
    log_info "Updating GRUB bootloader configuration..."
    
    if command -v update-grub &> /dev/null; then
        update-grub
        log_info "GRUB bootloader updated successfully"
    elif command -v grub2-mkconfig &> /dev/null; then
        grub2-mkconfig -o /boot/grub2/grub.cfg
        log_info "GRUB2 bootloader updated successfully"
    else
        log_error "Neither update-grub nor grub2-mkconfig found"
        log_error "Manual GRUB update required"
        exit 1
    fi
}

verify_configuration() {
    log_info "Verifying GRUB configuration..."
    
    if grep -q "isolcpus=2-15" "$GRUB_CONFIG" && \
       grep -q "nohz_full=2-15" "$GRUB_CONFIG" && \
       grep -q "rcu_nocbs=2-15" "$GRUB_CONFIG" && \
       grep -q "mitigations=off" "$GRUB_CONFIG" && \
       grep -q "transparent_hugepage=never" "$GRUB_CONFIG"; then
        log_info "All isolation parameters successfully configured"
        return 0
    else
        log_error "Configuration verification failed"
        return 1
    fi
}

display_summary() {
    echo ""
    echo "================================================================================"
    echo "HansonLattice Framework Setup Summary"
    echo "================================================================================"
    echo "Configuration File: $GRUB_CONFIG"
    echo "Backup Location: $GRUB_BACKUP"
    echo "Isolation Parameters Added:"
    echo "  - isolcpus=2-15 (Reserve CPU cores 2-15 for isolation)"
    echo "  - nohz_full=2-15 (Disable scheduler tick on isolated CPUs)"
    echo "  - rcu_nocbs=2-15 (Disable RCU callbacks on isolated CPUs)"
    echo "  - mitigations=off (Disable Spectre/Meltdown mitigations)"
    echo "  - transparent_hugepage=never (Disable transparent huge pages)"
    echo ""
    echo "IMPORTANT: System reboot required for changes to take effect"
    echo "================================================================================"
    echo ""
}

main() {
    log_info "Starting HansonLattice low-latency isolation configuration..."
    echo ""
    
    check_root
    check_grub_config_exists
    backup_grub
    append_isolation_params
    update_grub_bootloader
    
    if verify_configuration; then
        display_summary
        log_info "Setup completed successfully!"
        log_warn "REBOOT YOUR SYSTEM FOR CHANGES TO TAKE EFFECT"
        return 0
    else
        log_error "Setup verification failed"
        log_info "Restoring from backup: $GRUB_BACKUP"
        cp "$GRUB_BACKUP" "$GRUB_CONFIG"
        update_grub_bootloader
        exit 1
    fi
}

# Execute main function
main "$@"
