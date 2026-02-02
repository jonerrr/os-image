#!/usr/bin/env bash

set -oue pipefail

# Define key paths based on blue-build standards
# PUBLIC_KEY_DER_PATH is typically set in the recipe environment
# PRIVATE_KEY_PATH is mounted as a secret during build
PUBLIC_KEY_CRT_PATH="/tmp/certs/public_key.crt"
PRIVATE_KEY_PATH="/tmp/certs/private_key.priv"

# Ensure the public key variable is set
if [ -z "$PUBLIC_KEY_DER_PATH" ]; then
    echo "Error: PUBLIC_KEY_DER_PATH is not set."
    exit 1
fi

# Convert DER public key to CRT format for sbsign
openssl x509 -in "$PUBLIC_KEY_DER_PATH" -out "$PUBLIC_KEY_CRT_PATH"

# Directory containing systemd-boot EFI binaries
EFI_BOOT_DIR="/usr/lib/systemd/boot/efi"

echo "Signing systemd-boot binaries in $EFI_BOOT_DIR..."

# Sign all EFI binaries found in the directory (e.g., systemd-bootx64.efi, linuxx64.efi.stub)
for binary in "$EFI_BOOT_DIR"/*.efi; do
    if [ -f "$binary" ]; then
        echo "Signing $binary..."
        sbsign --cert "$PUBLIC_KEY_CRT_PATH" \
               --key "$PRIVATE_KEY_PATH" \
               "$binary" \
               --output "$binary"

        # Verify the signature
        sbverify --list "$binary"
    fi
done

echo "systemd-boot signing complete."