
> https://github.com/noahbliss/mortar

Framework to join Linux's physical security bricks. Mortar is essentially Linux-native TPM-backed Bitlocker. Virtually all linux districutions are critically vulnerable to physical bootloader attacks and potential disk key interception. Mortar fixes that.

Mortar is an attempt to take the headache and fragmented processes out of joining Secureboot, TPM keys, and LUKS.

Through the "Mortar Model" everything on disk that is used is **either encrypted, signed, or hashed**. The only location cleartext secrets are stored is in the TPM module, which is purpose-built to protect these keys against physical and virtual theft.

The TPM is used to effectively whitelist certain boot states and Mortar configures it to only release the key when an untampered system is observed. Since this validation and unlocking process is completely automated, intact systems fully restart without human interaction. This makes full-disk encryption dramatically more convenient for end-users and finally viable on servers.

## How it works

<img width="621" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/a3aada48-dc81-4d32-a794-34b722df8cda">

Only 2 partitions on your primary disk are used: your UEFI ESP, and your encrypted LUKS partition. (You can leave your unencrypted boot partition if you like, but I'd highly recommend removing or disabling its automatic mount so that kernels and initram filesystems can reside encrypted on your LUKS partition.)

You generate your own Secureboot keys. Only efi files you sign will successfully boot without modifying the BIOS (and breaking PCR1 validation).

## Detail Procedure

### 1. Initial setup

Mortar has env file(`/etc/mortar/mortar.env`), cmdline file(`/etc/mortar/cmdline.conf`). And work in `/etc/mortar`. You can see the env file's default value in [here](https://github.com/noahbliss/mortar/blob/master/mortar.env). 

When installing the motor, [os-release](https://www.freedesktop.org/software/systemd/man/latest/os-release.html) including operating system identification data is first executed.

```bash
# Figure out our distribuition. 
source /etc/os-release

# Install prerequisite packages. 
if [ -f "res/$ID/prereqs.sh" ]; then 
	source "res/$ID/prereqs.sh"; 
else
	echo "Could not find a prerequisite installer for $ID. Please only press enter if you want to continue at your own risk."
	read -p "Press enter to continue." asdf
fi
```

And run a prerequisite script to install prequisite packages.

```bash
apt-get update
apt-get install \
        binutils \
        efitools \
        uuid-runtime
```

`KEY_UUID` key that has random UUID value is added to env file.

```bash
# Install the env file with a random key_uuid if it doesn't exist.
if ! (command -v uuidgen >/dev/null); then echo "Cannot find uuidgen tool."; exit 1; fi
if ! [ -f "$ENVFILE" ]; then echo "Generating new KEY_UUID and installing mortar.env to $WORKING_DIR"; KEY_UUID=$(uuidgen --random); sed -e "/^KEY_UUID=.*/{s//KEY_UUID=$KEY_UUID/;:a" -e '$!N;$!ba' -e '}' mortar.env > "$ENVFILE"; else echo "mortar.env already installed in $WORKING_DIR"; fi
```

Istall `cmdline.conf`

```bash
if ! [ -f "$CMDLINEFILE" ]; then echo "No CMDLINE options file found. Using currently running cmdline options from /proc/cmdline"; cat /proc/cmdline > "$CMDLINEFILE"; else echo "cmdline.conf already installed in $WORKING_DIR"; fi
echo "Make sure to update the installed mortar.env with your TPM version and ensure all the paths are correct."
if grep " splash" "$CMDLINEFILE" >/dev/null; then echo "WARNING - \"splash\" detected in "$CMDLINEFILE" this this may hide boot-time mortar output!"; fi
if grep " quiet" "$CMDLINEFILE" >/dev/null; then echo "WARNING - \"quiet\" detected in "$CMDLINEFILE" this this may hide boot-time mortar output!"; fi
if grep " rhgb" "$CMDLINEFILE" >/dev/null; then echo "WARNING - \"rhgb\" detected in "$CMDLINEFILE" this this may hide boot-time mortar output!"; fi
```

Install the efi signing script.

```bash
cp bin/mortar-compilesigninstall /usr/local/sbin/mortar-compilesigninstall
if ! command -v mortar-compilesigninstall >/dev/null; then
	echo "Installed mortar-compilesigninstall to /usr/local/sbin but couldn't find it in PATH. Please update your PATH to include /usr/local/sbin"
fi
```

### 2. Generate And Install Securebootkeys

Generate Securebootkeys by openssl x509.

```bash
set -e
source mortar.env
echo "Generating secureboot keys..."
openssl req -new -x509 -newkey rsa:2048 -subj "/CN=PK$SECUREBOOT_MODIFIER/"  -keyout "$SECUREBOOT_PK_KEY"  -out "$SECUREBOOT_PK_CRT"  -days 7300 -nodes -sha256
openssl req -new -x509 -newkey rsa:2048 -subj "/CN=KEK$SECUREBOOT_MODIFIER/" -keyout "$SECUREBOOT_KEK_KEY" -out "$SECUREBOOT_KEK_CRT" -days 7300 -nodes -sha256
openssl req -new -x509 -newkey rsa:2048 -subj "/CN=db$SECUREBOOT_MODIFIER/"  -keyout "$SECUREBOOT_DB_KEY"  -out "$SECUREBOOT_DB_CRT"  -days 7300 -nodes -sha256
# Adding der versions of keys to private dir.
openssl x509 -in "$SECUREBOOT_PK_CRT" -outform der -out "$SECUREBOOT_PK_CRT".der
openssl x509 -in "$SECUREBOOT_KEK_CRT" -outform der -out "$SECUREBOOT_KEK_CRT".der
openssl x509 -in "$SECUREBOOT_DB_CRT" -outform der -out "$SECUREBOOT_DB_CRT".der
```

And make that keys efi sig using [cert-to-efi-sig-list](https://github.com/mjg59/efitools/blob/master/cert-to-efi-sig-list.c) command.

```bash
# Generate secureboot specific file variants.
cert-to-efi-sig-list -g "$KEY_UUID" "$SECUREBOOT_PK_CRT" "$SECUREBOOT_PK_ESL"
sign-efi-sig-list -g "$KEY_UUID" -k "$SECUREBOOT_PK_KEY" -c "$SECUREBOOT_PK_CRT" PK "$SECUREBOOT_PK_ESL" "$SECUREBOOT_PK_AUTH"
cert-to-efi-sig-list -g "$KEY_UUID" "$SECUREBOOT_KEK_CRT" "$SECUREBOOT_KEK_ESL"
sign-efi-sig-list -g "$KEY_UUID" -k "$SECUREBOOT_PK_KEY" -c "$SECUREBOOT_PK_CRT" KEK "$SECUREBOOT_KEK_ESL" "$SECUREBOOT_KEK_AUTH"
cert-to-efi-sig-list -g "$KEY_UUID" "$SECUREBOOT_DB_CRT" "$SECUREBOOT_DB_ESL"
sign-efi-sig-list -g "$KEY_UUID" -k "$SECUREBOOT_KEK_KEY" -c "$SECUREBOOT_KEK_CRT" db "$SECUREBOOT_DB_ESL" "$SECUREBOOT_DB_AUTH"

echo "You now need to generate/install a signed efi file Before installing the keys and enabling secureboot!"
echo "Run bin/mortar-compilesigninstall FULLPATHTOKERNELIMAGE FULLPATHTOINITRDIMAGE"
```

And install by [efi-updatevar](https://github.com/mjg59/efitools/blob/master/efi-updatevar.c) command.

```bash
chattr -i /sys/firmware/efi/efivars/{PK,KEK,db,dbx}-* 2>/dev/null
if (efi-updatevar -f "$SECUREBOOT_DB_AUTH" db); then thing="db"; installed $thing; else failed $thing; exit 1; fi
if (efi-updatevar -f "$SECUREBOOT_KEK_AUTH" KEK); then thing="KEK"; installed $thing; else failed $thing; exit 1; fi
if (efi-updatevar -f "$SECUREBOOT_PK_AUTH" PK); then thing="PK"; installed $thing; else failed $thing; exit 1; fi
```

### 3. Prepluk sand install hooks

Testing if secure boot is on and working.

```bash
MORTAR_FILE="/etc/mortar/mortar.env"
OLD_DIR="$PWD"
source "$MORTAR_FILE"

od --address-radix=n --format=u1 /sys/firmware/efi/efivars/SecureBoot-*
read -p  "ENTER to continue only if the last number is a \"1\" and you are sure the TPM registers are as you want them." asdf
```

Remove tmpramfs from failed runs if applicable.

```bash
if [ -d tmpramfs ]; then
	echo "Removing existing tmpfs..."
	umount tmpramfs
	rm -rf tmpramfs
fi
```

Create tmpramfs for generated mortar key and read user luks password to file.

```bash
if mkdir tmpramfs && mount tmpfs -t tmpfs -o size=1M,noexec,nosuid tmpramfs; then
	echo "Created tmpramfs for storing the key."
	trap "if [ -f tmpramfs/user.key ]; then rm -f tmpramfs/user.key; fi" EXIT
	echo -n "Enter luks password: "; read -s PASSWORD; echo
	echo -n "$PASSWORD" > tmpramfs/user.key
	unset PASSWORD
else
	echo "Failed to create tmpramfs for storing the key."
	exit 1
fi

if command -v luksmeta >/dev/null; then
	echo "Wiping any existing metadata in the luks keyslot."
	luksmeta wipe -d "$CRYPTDEV" -s "$SLOT"
fi
```

Wiping any old luks key in the keyslot.

```bash
cryptsetup luksKillSlot --key-file tmpramfs/user.key "$CRYPTDEV" "$SLOT"
read -p "If this is the first time running, do you want to attempt taking ownership of the tpm? (y/N): " takeowner	
case "$takeowner" in
	[yY]*) tpm_takeownership -z ;;
esac
```

Generate the key.

```bash
dd bs=1 count=512 if=/dev/urandom of=tmpramfs/mortar.key
chmod 700 tmpramfs/mortar.key
cryptsetup luksAddKey "$CRYPTDEV" --key-slot "$SLOT" tmpramfs/mortar.key --key-file tmpramfs/user.key
```

Sealing key to TPM. Using `tpm_nvwrite` that writes data to an NVRAM area.

> NVRAM (non-volatile random-access memory) refers to computer memory that can hold data even when power to the memory chips has been turned off.

```bash
if [ -z "$TPMINDEX" ]; then echo "TPMINDEX not set."; exit 1; fi
PERMISSIONS="OWNERWRITE|READ_STCLEAR"
read -s -r -p "Owner password: " OWNERPW

# Wipe index if it is populated.
if tpm_nvinfo | grep \($TPMINDEX\) > /dev/null; then tpm_nvrelease -i "$TPMINDEX" -o"$OWNERPW"; fi

# Convert PCR format...
PCRS=`echo "-r""$BINDPCR" | sed 's/,/ -r/g'`

# Create new index sealed to PCRS. 
if tpm_nvdefine -i "$TPMINDEX" -s `wc -c tmpramfs/mortar.key` -p "$PERMISSIONS" -o "$OWNERPW" -z $PCRS; then
	# Write key into the index...
	tpm_nvwrite -i "$TPMINDEX" -f tmpramfs/mortar.key -z --password="$OWNERPW"
fi
```

Get rid of the key in the ramdisk.

```bash
echo "Cleaning up luks keys and tmpfs..."
rm tmpramfs/mortar.key
rm tmpramfs/user.key
umount -l tmpramfs
rm -rf tmpramfs
```

Adding new sha256 of the luks header to the mortar env file.

```bash
if [ -f "$HEADERFILE" ]; then rm "$HEADERFILE"; fi
cryptsetup luksHeaderBackup "$CRYPTDEV" --header-backup-file "$HEADERFILE"

HEADERSHA256=`sha256sum "$HEADERFILE" | cut -f1 -d' '`
sed -i -e "/^HEADERSHA256=.*/{s//HEADERSHA256=$HEADERSHA256/;:a" -e '$!N;$!b' -e '}' "$MORTAR_FILE"
if [ -f "$HEADERFILE" ]; then rm "$HEADERFILE"; fi
```

Defer to tpm and distro-specific install script.

```bash
source /etc/os-release
tpmverdir='tpm1.2'

if [ -d "$OLD_DIR/""res/""$ID/""$tpmverdir/" ]; then
	cd "$OLD_DIR/""res/""$ID/""$tpmverdir/"
	echo "Distribution: $ID"
	echo "Installing kernel update and initramfs build scripts with mortar.env values..."
	bash install.sh # Start in new process so we don't get dropped to another directory. 
else
	echo "Distribution: $ID"
	echo "Could not find scripts for your distribution."
fi
```

---
reference
- https://github.com/noahbliss/mortar
- https://www.unix.com/man-page/centos/8/tpm_nvwrite/