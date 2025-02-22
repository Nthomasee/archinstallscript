# Arch Linux Install Script

Этот репозиторий содержит `sh`-скрипт для автоматической установки Arch Linux.

## Установка

Чтобы запустить скрипт, выполните следующие команды:

```sh
pacman -Sy git
git clone https://github.com/Nthomasee/archinstallscript
cd archinstallscript
./install.sh
```

## Описание работы скрипта

1. Запрашивает у пользователя, на какой диск установить Arch Linux.
2. Форматирует указанный диск следующим образом:
   - Создаёт GPT-метку.
   - Создаёт 512MB раздел под `/boot` (EFI).
   - Создаёт 4GB раздел под swap.
   - Оставшееся место выделяет под `root` (`/`).
3. Форматирует разделы:
   - `boot` в `FAT32`.
   - `root` в `EXT4`.
   - Включает swap.
4. Устанавливает следующие пакеты:
   ```
   base linux linux-firmware amd-ucode intel-ucode sof-firmware base-devel grub efibootmgr neovim vim nano networkmanager
   ```
5. Запрашивает у пользователя `hostname`.
6. Запрашивает имя пользователя с правами `wheel` и создаёт его.
7. Позволяет выбрать временную зону через интерактивное меню.
8. Устанавливает локализацию (`en_US.UTF-8`).
9. Устанавливает и настраивает загрузчик `GRUB`.
10. Включает `NetworkManager` для управления сетью.

## Требования
- UEFI-совместимая система
- Доступ в интернет
