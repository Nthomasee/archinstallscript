#!/bin/sh
setfont cyr-sun16
while true; do
    echo "Введите путь до диска:"
    read put
    if ls "${put}" >/dev/null 2>&1; then
        echo "Диск найден, продолжаем выполнение..."
        break
    else
        echo "Такого диска не существует, попробуйте еще раз."
    fi
done


parted ${put} -- mklabel gpt || { echo "Ошибка при создании GPT метки"; exit 1; }
parted ${put} -- mkpart root ext4 512MB -4GB || { echo "Ошибка при создании root раздела"; exit 1; }
parted ${put} -- mkpart swap linux-swap -4GB 100% || { echo "Ошибка при создании swap раздела"; exit 1; }
parted ${put} -- mkpart ESP fat32 1MB 512MB || { echo "Ошибка при создании ESP раздела"; exit 1; }
parted ${put} -- set 3 esp on || { echo "Ошибка при установке флага ESP"; exit 1; }


mkfs.ext4 -L root ${put}1 || { echo "Ошибка при форматировании root раздела"; exit 1; }
mkswap -L swap ${put}2 || { echo "Ошибка при mkswap"; exit 1; }
mkfs.fat -F 32 -n boot ${put}3 || { echo "Ошибка при форматировании ESP раздела"; exit 1; }
swapon ${put}2 || { echo "Ошибка при подключении swap"; exit 1; }

mount /dev/disk/by-label/root /mnt || { echo "Ошибка при монтировании root partition"; exit 1; }
echo "$put" > /mnt/put
mkdir -p /mnt/boot/efi 
mount /dev/disk/by-label/boot /mnt/boot/efi || { echo "Ошибка монтирования boot partition"; exit 1; }
pacstrap -K /mnt base linux linux-firmware amd-ucode intel-ucode sof-firmware base-devel grub efibootmgr neovim vim nano networkmanager || { echo "Ошибка при выполнении pacstrap"; exit 1; }
genfstab /mnt > /mnt/etc/fstab || { echo "Ошибка при создании fstab"; exit 1; }

cp /root/archinstallscript/install2.sh /mnt/install2.sh

arch-chroot /mnt /bin/bash -c "/install2.sh" || { echo "Ошибка при chroot"; exit 1; }
