#!/bin/sh

if [ -f /put ]; then
    put=$(cat /put)
else
    echo "Не удалось получить путь к диску (файл /put не найден)"
    exit 1
fi

while true; do
    echo "Введите hostname:"
    read hostname
    if [ -z "$hostname" ]; then
        echo "Вы ничего не ввели."
    else
        break
    fi
done

while true; do
    echo "Введите имя для Wheel пользователя:"
    read admin
    if [ -z "$admin" ]; then
        echo "Вы ничего не ввели."
    else
        break
    fi
done

show_menu() {
    file="$1"
    title="$2"
    total=$(wc -l < "$file")
    half=$(( (total + 1) / 2 ))

    echo "$title"
    awk -v half="$half" '
    {
        # Левый столбец
        if (NR <= half) {
            left[NR] = sprintf("%2d) %s", NR, $0)
        }
        # Правый столбец
        if (NR > half) {
            right[NR-half] = sprintf("%2d) %s", NR, $0)
        }
    }
    END {
        for (i = 1; i <= half; i++) {
            if (right[i] == "") right[i] = ""
            printf "%-30s %s\n", left[i], right[i]
        }
    }' "$file"
    echo
}

# ШАГ 1: Выбор директории
dir_list=$(mktemp -t tzscript.XXXXXX) || { echo "Не удалось создать временный файл"; exit 1; }

find /usr/share/zoneinfo/ -mindepth 1 -maxdepth 1 \( -type d -o -type l \) | \
  sed 's|^/usr/share/zoneinfo/||' | sort > "$dir_list"

dircount=$(wc -l < "$dir_list")
if [ "$dircount" -eq 0 ]; then
    echo "Нет доступных директорий в /usr/share/zoneinfo/"
    rm "$dir_list"
    exit 1
fi

show_menu "$dir_list" "Выбор timezone:"

echo "Введите номер выбранной директории (от 1 до $dircount):"
read dir_choice

case "$dir_choice" in
    ''|*[!0-9]*) 
        echo "Неверный выбор: введите число."
        rm "$dir_list"
        exit 1
        ;;
esac

if [ "$dir_choice" -lt 1 ] || [ "$dir_choice" -gt "$dircount" ]; then
    echo "Неверный выбор: число вне диапазона."
    rm "$dir_list"
    exit 1
fi

chosen_dir=$(sed -n "${dir_choice}p" "$dir_list")
rm "$dir_list"

# ШАГ 2: Выбор временной зоны
tz_list=$(mktemp -t tzscript.XXXXXX) || { echo "Не удалось создать временный файл"; exit 1; }

find "/usr/share/zoneinfo/$chosen_dir" -mindepth 1 -maxdepth 1 -type f | \
  sed "s|^/usr/share/zoneinfo/$chosen_dir/||" | sort > "$tz_list"

tzcount=$(wc -l < "$tz_list")
if [ "$tzcount" -eq 0 ]; then
    echo "Нет доступных файлов в директории /usr/share/zoneinfo/$chosen_dir/"
    rm "$tz_list"
    exit 1
fi

show_menu "$tz_list" "Доступные временные зоны в каталоге $chosen_dir:"

echo "Введите номер выбранной временной зоны (от 1 до $tzcount):"
read tz_choice

case "$tz_choice" in
    ''|*[!0-9]*) 
        echo "Неверный выбор: введите число."
        rm "$tz_list"
        exit 1
        ;;
esac

if [ "$tz_choice" -lt 1 ] || [ "$tz_choice" -gt "$tzcount" ]; then
    echo "Неверный выбор: число вне диапазона."
    rm "$tz_list"
    exit 1
fi

chosen_tz=$(sed -n "${tz_choice}p" "$tz_list")
rm "$tz_list"

timezone="$chosen_dir/$chosen_tz"
echo "Устанавливаю часовой пояс: $timezone"
ln -sf /usr/share/zoneinfo/$timezone /etc/localtime || { echo "Ошибка при установке часового пояса"; exit 1; }
hwclock --systohc || { echo "Ошибка при синхронизации hwclock"; exit 1; }
echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf
echo "$hostname" > /etc/hostname
useradd -m -G wheel ${admin}
echo "Введите пароль для wheel пользователя:"
until passwd "${admin}"; do
    echo "Ошибка смены пароля. Пожалуйста, попробуйте снова."
done
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers
systemctl enable NetworkManager
grub-install ${put}
grub-mkconfig -o /boot/grub/grub.cfg
echo "All done!" 
