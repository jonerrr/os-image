# for some reason this script doesn't work as a mise task
# most of the script info comes from https://wiki.archlinux.org/title/Unified_Extensible_Firmware_Interface/Secure_Boot
set -euo pipefail

# Directory to store keys
KEY_DIR="keys"
# Directory where bootc expects the final keys
BOOTC_INSTALL_DIR="files/usr/lib/bootc/install/secureboot-keys"
# Microsoft's GUID (Required for MS keys)
MS_GUID="77fa9abd-0359-4d32-bd60-28f4e78f784b"
# MY_GUID is provided by env var (from mise.toml)
# echo "Using MY_GUID: $MY_GUID"
# Name of your personal cert provided in the prompt
MY_SIGNING_CERT="certs/akmods-jonah.der"

mkdir -p "$KEY_DIR"
mkdir -p "$BOOTC_INSTALL_DIR"

echo "=== 1. Downloading Certificates ==="
# (Your existing download commands)
mkdir -p certs
# Microsoft Windows Production PCA 2011 (Windows Bootloader)
curl -L -o certs/MicWinProPCA2011_2011-10-19.crt https://www.microsoft.com/pkiops/certs/MicWinProPCA2011_2011-10-19.crt
# Windows UEFI CA 2023
curl -L -o certs/windows_uefi_ca_2023.crt https://www.microsoft.com/pkiops/certs/windows%20uefi%20ca%202023.crt
# Microsoft UEFI CA 2011 (Third Party / Shim / Linux)
curl -L -o certs/MicCorUEFCA2011_2011-06-27.crt https://www.microsoft.com/pkiops/certs/MicCorUEFCA2011_2011-06-27.crt
# Microsoft UEFI CA 2023
curl -L -o certs/microsoft_uefi_ca_2023.crt https://www.microsoft.com/pkiops/certs/microsoft%20uefi%20ca%202023.crt
# Microsoft KEK 2011
curl -L -o certs/MicCorKEKCA2011_2011-06-24.crt https://www.microsoft.com/pkiops/certs/MicCorKEKCA2011_2011-06-24.crt
# Microsoft KEK 2023
curl -L -o certs/microsoft_kek_2k_ca_2023.crt https://www.microsoft.com/pkiops/certs/microsoft%20corporation%20kek%202k%20ca%202023.crt
# Blue Build Custom Key
curl -L -o certs/akmods-blue-build.der https://github.com/blue-build/base-images/raw/refs/heads/main/files/base/etc/pki/akmods/certs/akmods-blue-build.der

echo "=== 2. Generating Your Hardware Owner Keys (PK, KEK, local db) ==="
# We generate new keys to act as the "Platform Key" owner.
# You cannot use akmods-jonah.der as PK easily because you need the private key to sign the .auth vars.

# Generate Platform Key (PK)
openssl req -newkey rsa:4096 -nodes -keyout "$KEY_DIR/PK.key" -new -x509 -sha256 -days 3650 -subj "/CN=Jonah Platform Key/" -out "$KEY_DIR/PK.crt"
openssl x509 -outform DER -in "$KEY_DIR/PK.crt" -out "$KEY_DIR/PK.cer"

# Generate Key Exchange Key (KEK)
openssl req -newkey rsa:4096 -nodes -keyout "$KEY_DIR/KEK.key" -new -x509 -sha256 -days 3650 -subj "/CN=Jonah KEK/" -out "$KEY_DIR/KEK.crt"
openssl x509 -outform DER -in "$KEY_DIR/KEK.crt" -out "$KEY_DIR/KEK.cer"

# Generate a local DB key (optional, but good for future manual signing)
openssl req -newkey rsa:4096 -nodes -keyout "$KEY_DIR/db.key" -new -x509 -sha256 -days 3650 -subj "/CN=Jonah Local DB/" -out "$KEY_DIR/db.crt"
openssl x509 -outform DER -in "$KEY_DIR/db.crt" -out "$KEY_DIR/db.cer"

echo "=== 3. Converting Certificates to EFI Signature Lists (ESL) ==="

# --- Database (db) ---
# The db contains trusted keys for booting (Bootloaders, Kernels, Drivers)
# We must include: Microsoft Keys, Blue Build, YOUR signing key (akmods-jonah), and your local db key.

# Convert Microsoft db keys (Using MS GUID)
sbsiglist --owner "$MS_GUID" --type x509 --output "$KEY_DIR/MS_Win_db_2011.esl" "certs/MicWinProPCA2011_2011-10-19.crt"
sbsiglist --owner "$MS_GUID" --type x509 --output "$KEY_DIR/MS_Win_db_2023.esl" "certs/windows_uefi_ca_2023.crt"
sbsiglist --owner "$MS_GUID" --type x509 --output "$KEY_DIR/MS_UEFI_db_2011.esl" "certs/MicCorUEFCA2011_2011-06-27.crt"
sbsiglist --owner "$MS_GUID" --type x509 --output "$KEY_DIR/MS_UEFI_db_2023.esl" "certs/microsoft_uefi_ca_2023.crt"

# Convert Custom Keys (Using YOUR GUID)
# Blue Build
sbsiglist --owner "$MY_GUID" --type x509 --output "$KEY_DIR/blue-build.esl" "certs/akmods-blue-build.der"
# Your personal signing key (akmods-jonah.der) - CRITICAL for booting your signed systemd-boot
sbsiglist --owner "$MY_GUID" --type x509 --output "$KEY_DIR/jonah-signing.esl" "$MY_SIGNING_CERT"
# Your generated local db key
sbsiglist --owner "$MY_GUID" --type x509 --output "$KEY_DIR/local-db.esl" "$KEY_DIR/db.crt"

# Concatenate all into one db.esl
cat "$KEY_DIR/MS_Win_db_2011.esl" \
    "$KEY_DIR/MS_Win_db_2023.esl" \
    "$KEY_DIR/MS_UEFI_db_2011.esl" \
    "$KEY_DIR/MS_UEFI_db_2023.esl" \
    "$KEY_DIR/blue-build.esl" \
    "$KEY_DIR/jonah-signing.esl" \
    "$KEY_DIR/local-db.esl" > "$KEY_DIR/db.esl"

# --- Key Exchange Key (KEK) ---
# The KEK is used to update the Signature Database (db).
# We include Microsoft's KEK (so Windows updates can update db) and your KEK.

# Convert Microsoft KEKs
sbsiglist --owner "$MS_GUID" --type x509 --output "$KEY_DIR/MS_KEK_2011.esl" "certs/MicCorKEKCA2011_2011-06-24.crt"
sbsiglist --owner "$MS_GUID" --type x509 --output "$KEY_DIR/MS_KEK_2023.esl" "certs/microsoft_kek_2k_ca_2023.crt"

# Convert your local KEK
sbsiglist --owner "$MY_GUID" --type x509 --output "$KEY_DIR/local-KEK.esl" "$KEY_DIR/KEK.crt"

# Concatenate into KEK.esl
cat "$KEY_DIR/MS_KEK_2011.esl" \
    "$KEY_DIR/MS_KEK_2023.esl" \
    "$KEY_DIR/local-KEK.esl" > "$KEY_DIR/KEK.esl"

# --- Platform Key (PK) ---
# The PK controls the whole system. Only YOUR PK is needed here.
sbsiglist --owner "$MY_GUID" --type x509 --output "$KEY_DIR/PK.esl" "$KEY_DIR/PK.crt"

echo "=== 4. Signing Variables (.auth generation) ==="
# We sign the ESL files to create authenticated variables ready for enrollment

# 1. Sign db.esl with your KEK
/usr/bin/sign-efi-sig-list -g "$MY_GUID" -k "$KEY_DIR/KEK.key" -c "$KEY_DIR/KEK.crt" db "$KEY_DIR/db.esl" "$BOOTC_INSTALL_DIR/db.auth"

# 2. Sign KEK.esl with your PK
/usr/bin/sign-efi-sig-list -g "$MY_GUID" -k "$KEY_DIR/PK.key" -c "$KEY_DIR/PK.crt" KEK "$KEY_DIR/KEK.esl" "$BOOTC_INSTALL_DIR/KEK.auth"

# 3. Sign PK.esl with your PK (Self-signed)
/usr/bin/sign-efi-sig-list -g "$MY_GUID" -k "$KEY_DIR/PK.key" -c "$KEY_DIR/PK.crt" PK "$KEY_DIR/PK.esl" "$BOOTC_INSTALL_DIR/PK.auth"

echo "Done! Keys generated in $BOOTC_INSTALL_DIR"
