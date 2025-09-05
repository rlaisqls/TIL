
> <https://github.com/noahbliss/mortar>

- Mortar는 Linux의 물리적 보안 구성 요소들을 연결하는 프레임워크다.
- Mortar 모델을 통해 디스크에서 사용되는 모든 것이 암호화되거나, 서명되거나, 해시된다.
  - 평문 시크릿이 저장되는 유일한 위치는 TPM 모듈이다.
- TPM은 특정 부팅 상태를 효과적으로 화이트리스트하는 데 사용되며, Mortar는 변조되지 않은 시스템이 감지될 때만 키를 해제하도록 구성한다.
  - 이 검증 및 잠금 해제 프로세스가 완전히 자동화되어 있어서, 정상적인 시스템은 사용자 개입 없이 완전히 재시작된다.
  - 덕분에 전체 디스크 암호화가 최종 사용자에게 훨씬 편리해지고, 서버에서도 실용적으로 사용할 수 있게 된다.

## 동작 방식

<img width="621" alt="image" src="https://github.com/rlaisqls/TIL/assets/81006587/a3aada48-dc81-4d32-a794-34b722df8cda">

기본 디스크에서는 2개의 파티션만 사용된다: UEFI ESP와 암호화된 LUKS 파티션이다. (암호화되지 않은 부팅 파티션을 그대로 둬도 되지만, 커널과 initram 파일시스템이 LUKS 파티션에 암호화되어 저장될 수 있도록 자동 마운트를 제거하거나 비활성화할 것을 강력히 권장한다.)

자체 Secureboot 키를 생성한다. 서명한 efi 파일만이 BIOS 수정 없이도 성공적으로 부팅되며 (PCR1 검증도 깨뜨리지 않는다).

## 세부 절차

### 1. 초기 설정

Mortar에는 env 파일(`/etc/mortar/mortar.env`)과 cmdline 파일(`/etc/mortar/cmdline.conf`)이 있다. 그리고 `/etc/mortar`에서 작업한다. env 파일의 기본값은 [여기](https://github.com/noahbliss/mortar/blob/master/mortar.env)에서 확인할 수 있다.

mortar를 설치할 때, 운영체제 식별 데이터를 포함하는 [os-release](https://www.freedesktop.org/software/systemd/man/latest/os-release.html)가 먼저 실행된다.

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

그 다음 필수 패키지들을 설치하는 전제 조건 스크립트를 실행한다.

```bash
apt-get update
apt-get install \
        binutils \
        efitools \
        uuid-runtime
```

랜덤 UUID 값을 가진 `KEY_UUID` 키가 env 파일에 추가된다.

```bash
# Install the env file with a random key_uuid if it doesn't exist.
if ! (command -v uuidgen >/dev/null); then echo "Cannot find uuidgen tool."; exit 1; fi
if ! [ -f "$ENVFILE" ]; then echo "Generating new KEY_UUID and installing mortar.env to $WORKING_DIR"; KEY_UUID=$(uuidgen --random); sed -e "/^KEY_UUID=.*/{s//KEY_UUID=$KEY_UUID/;:a" -e '$!N;$!ba' -e '}' mortar.env > "$ENVFILE"; else echo "mortar.env already installed in $WORKING_DIR"; fi
```

`cmdline.conf` 설치

```bash
if ! [ -f "$CMDLINEFILE" ]; then echo "No CMDLINE options file found. Using currently running cmdline options from /proc/cmdline"; cat /proc/cmdline > "$CMDLINEFILE"; else echo "cmdline.conf already installed in $WORKING_DIR"; fi
echo "Make sure to update the installed mortar.env with your TPM version and ensure all the paths are correct."
if grep " splash" "$CMDLINEFILE" >/dev/null; then echo "WARNING - \"splash\" detected in "$CMDLINEFILE" this this may hide boot-time mortar output!"; fi
if grep " quiet" "$CMDLINEFILE" >/dev/null; then echo "WARNING - \"quiet\" detected in "$CMDLINEFILE" this this may hide boot-time mortar output!"; fi
if grep " rhgb" "$CMDLINEFILE" >/dev/null; then echo "WARNING - \"rhgb\" detected in "$CMDLINEFILE" this this may hide boot-time mortar output!"; fi
```

efi 서명 스크립트를 설치한다.

```bash
cp bin/mortar-compilesigninstall /usr/local/sbin/mortar-compilesigninstall
if ! command -v mortar-compilesigninstall >/dev/null; then
 echo "Installed mortar-compilesigninstall to /usr/local/sbin but couldn't find it in PATH. Please update your PATH to include /usr/local/sbin"
fi
```

### 2. Secureboot 키 생성 및 설치

openssl x509으로 Secureboot 키를 생성한다.

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

그리고 [cert-to-efi-sig-list](https://github.com/mjg59/efitools/blob/master/cert-to-efi-sig-list.c) 명령어로 해당 키들을 efi sig로 만든다.

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

[efi-updatevar](https://github.com/mjg59/efitools/blob/master/efi-updatevar.c) 명령어로 설치한다.

```bash
chattr -i /sys/firmware/efi/efivars/{PK,KEK,db,dbx}-* 2>/dev/null
if (efi-updatevar -f "$SECUREBOOT_DB_AUTH" db); then thing="db"; installed $thing; else failed $thing; exit 1; fi
if (efi-updatevar -f "$SECUREBOOT_KEK_AUTH" KEK); then thing="KEK"; installed $thing; else failed $thing; exit 1; fi
if (efi-updatevar -f "$SECUREBOOT_PK_AUTH" PK); then thing="PK"; installed $thing; else failed $thing; exit 1; fi
```

### 3. LUKS 준비 및 훅 설치

시큐어 부트가 켜져 있고 작동하는지 테스트한다.

```bash
MORTAR_FILE="/etc/mortar/mortar.env"
OLD_DIR="$PWD"
source "$MORTAR_FILE"

od --address-radix=n --format=u1 /sys/firmware/efi/efivars/SecureBoot-*
read -p  "ENTER to continue only if the last number is a \"1\" and you are sure the TPM registers are as you want them." asdf
```

실패한 실행에서 남은 tmpramfs가 있다면 제거한다.

```bash
if [ -d tmpramfs ]; then
 echo "Removing existing tmpfs..."
 umount tmpramfs
 rm -rf tmpramfs
fi
```

생성된 mortar 키를 위한 tmpramfs를 생성하고 사용자 luks 비밀번호를 파일로 읽어들인다.

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

키슬롯에 있는 기존 luks 키를 삭제한다.

```bash
cryptsetup luksKillSlot --key-file tmpramfs/user.key "$CRYPTDEV" "$SLOT"
read -p "If this is the first time running, do you want to attempt taking ownership of the tpm? (y/N): " takeowner 
case "$takeowner" in
 [yY]*) tpm_takeownership -z ;;
esac
```

키를 생성한다.

```bash
dd bs=1 count=512 if=/dev/urandom of=tmpramfs/mortar.key
chmod 700 tmpramfs/mortar.key
cryptsetup luksAddKey "$CRYPTDEV" --key-slot "$SLOT" tmpramfs/mortar.key --key-file tmpramfs/user.key
```

TPM에 키를 봉인한다. NVRAM 영역에 데이터를 쓰는 `tpm_nvwrite`를 사용한다.

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

ramdisk에 있는 키를 제거한다.

```bash
echo "Cleaning up luks keys and tmpfs..."
rm tmpramfs/mortar.key
rm tmpramfs/user.key
umount -l tmpramfs
rm -rf tmpramfs
```

luks 헤더의 새로운 sha256 값을 mortar env 파일에 추가한다.

```bash
if [ -f "$HEADERFILE" ]; then rm "$HEADERFILE"; fi
cryptsetup luksHeaderBackup "$CRYPTDEV" --header-backup-file "$HEADERFILE"

HEADERSHA256=`sha256sum "$HEADERFILE" | cut -f1 -d' '`
sed -i -e "/^HEADERSHA256=.*/{s//HEADERSHA256=$HEADERSHA256/;:a" -e '$!N;$!b' -e '}' "$MORTAR_FILE"
if [ -f "$HEADERFILE" ]; then rm "$HEADERFILE"; fi
```

tpm 버전과 배포판별 설치 스크립트로 위임한다.

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
추천

- <https://github.com/noahbliss/mortar>
- <https://www.unix.com/man-page/centos/8/tpm_nvwrite/>
