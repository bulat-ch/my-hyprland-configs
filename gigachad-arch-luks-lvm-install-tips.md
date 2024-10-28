arch with luks and lvm

Запускаемся с образа. Проверяем наличие Интернета (оно нам понадобиться в процессе установки) и доступность диска, над которым планируем поработать.


Первый раздел — EFI sytem Partition, я выделяю под него 256Mb

Второй раздел — boot, 512 Mb
Третий раздел будет зашифрован (нет, boot мы шифровать не будем, ибо запускаться и получать возможность ввода пароля на расшифровку нам как-то надо).

Для первого раздела выбираем тип EFI system, для остальных оставляем по умолчанию Linux filesystem.

Весь оставшийся размер диска размечаем под третью часть (на разделы мы его разобьём чуть позже).

Переходим к шифрованию. Для начала подгрузим необходимые модули ядра (не пугайтесь, это не больно). В этом нам поможет утилита modprobe.
```
modprobe dm-crypt
```
```
modprobe dm-mod
```
Устанавливаем шифрование на наш раздел
```
cryptsetup luksFormat -v -s 512 -h sha512 /dev/sda3
``` 
Нас попросят подтвердить наше намерение заглавными буквами (то есть YES, а не yes или y), а далее ввести и подтвердить пароль. Во избежание проблем крайне не рекомендую этот пароль забывать.


Открываем его (запросит установленный пароль):
```
cryptsetup open /dev/sda3 luks_lvm
```

И теперь разбиваем.
Создаём раздел:
```
pvcreate /dev/mapper/luks_lvm
```
Создаём группу:
```
vgcreate arch /dev/mapper/luks_lvm
```
Создаём логические тома в меру своей испорченности
```
lvcreate -n swap -L 16G -C y arch
```
```
lvcreate -n root -L 100G arch
```
```
lvcreate -n home -l +100%FREE arch
```
Разумеется, количество и размеры разделов зависят от ваших пожеланий и возможностей используемого “железа”.

Если ошиблись и создали неверный раздел или объём, то его можно удалить, как пример "home"
```
lvremove /dev/mapper/arch-home
```

Форматируем разделы.
Я использую файловую систему ext4, но ничего не мешает вам использовать то, что больше по вкусу.
Обратите внимание, что раздел EFI должен быть отформатирован в fat32.
```
mkfs.fat -F32 /dev/sda1
```
```
mkfs.ext4 /dev/sda2
```
```
mkfs.ext4 -L root /dev/mapper/arch-root
```
```
mkfs.ext4 -L home /dev/mapper/arch-home
```
```
mkswap /dev/mapper/arch-swap
```

Монтируем то, что получилось:
```
mount /dev/mapper/arch-root /mnt
```
```
mkdir -p /mnt/{boot,home}
```
```
mount /dev/sda2 /mnt/boot
```
```
mkdir /mnt/boot/efi
```
```
mount /dev/sda1 /mnt/boot/efi
```
```
mount /dev/mapper/arch-home /mnt/home
```
```
swapon /dev/mapper/arch-swap
```
```
swapon -a; swapon -s
```

Если на данном этапе выполнить lsblk, мы увидим список наших созданных разделов.

Приступаем к установке Arch на наш свежеразделанный диск*:
```
pacstrap /mnt base base-devel efibootmgr nano grub mkinitcpio linux-zen linux-firmware lvm2 vi nano
```
* - я использую ядро linux-zen.
 
Если всё прошло хорошо с установкой, генерируем fstab
```
genfstab -U -p /mnt > /mnt/etc/fstab
```
И заходим внутрь нашей новенькой системы
```
arch-chroot /mnt /bin/bash
```
Для удобства ставим сразу тип раскладки клавиатуры
```
localectl set-keymap --no-convert jp106
```
Или же тоже самое можно сделать в файле
```
nano /etc/vconsole.conf
```
Конфигурируем mkinitcpio (что это такое и с чем это едят можно подглядеть на ArchWiki https://wiki.archlinux.org/index.php/Mkinitcpio_(Русский) )
```
vim /etc/mkinitcpio.conf
```
Находим строчку HOOKS и дописываем encrypt, lvm2 и другие необходимые параметры. Мой HOOKS выглядит, обычно, так:
```
HOOKS=(base udev autodetect keyboard keymap modconf block encrypt lvm2 filesystems fsck)
```
Обратите внимание — порядок имеет значение!


В приведённой мной конфигурации в MODULES я добавляю ext4 и модули для nvidia для дальнейшей установки wayland.
Получается такое для nvidia:
```
MODULES=(ext4 usbhid xhci_hcd  nvidia  nvidia_modeset nvidia_uvm nvidia_drm)
```
Для Intel (в данном случае uhd620):
```
MODULES=(ext4 usbhid xhci_hcd i915)
```
Устанавливаем grub
```
grub-install — efi-directory=/boot/efi
```
Конфигурируем
```
vim /etc/default/grub
```
```
GRUB_CMDLINE_LINUX_DEFAULT=”loglevel=3 quiet nvidia_drm.modeset=1”
GRUB_CMDLINE_LINUX=”resume=/dev/mapper/arch-swap cryptdevice=/dev/sda3:luks_lvm root=/dev/mapper/arch-root”
```
Не забываем добавить пользователя и добавить его группы и домашнюю папку. Дополнительно поставить пароли для пользователя и root.
```
useradd -m -G adm,ftp,games,http,log,rfkill,,sys,systemd-journal,uucp,wheel,audio,disk,floppy,input,kvm,optical,scanner,storage,video <username>
```
Устанавливаем пароль для root'a
```
passwd
```
И созданному пользователю
```
passwd <username>
```
Чтобы пользоваться командой "sudo" нужно раскомментировать строку в sudoers (/etc/sudoers):
```
%wheel ALL=(ALL:ALL) ALL
```
Гененрируем образ
```
mkinitcpio -v -p linux
```
Если установлено несколько ОС параллельно и чтобы можно было выбирать из grub куда вам грузиться, то необходимо установить os-prober 
```
sudo pacman -Suy
```
```
sudo pacman -S os-prober
```
и необходимо включить его, раскомментировав строку (/etc/default/grub)
```
GRUB_DISABLE_OS_PROBER=false
```
Генерируем конфигурацию загрузчика
```
grub-mkconfig -o /boot/grub/grub.cfg
```
```
grub-mkconfig -o /boot/efi/EFI/arch/grub.cfg
```
Меняем хостнейм с дефолтного на свой в файле:
```
/etc/hostname
```

Устанавливаем необходимые драйверы и, при необходимости, нужные оконные менеджеры/композиторы.
У меня было следующее:
```
pacman -S networkmanager nvidia-dkms
```
В случае, если у вас установочный образ пакет старый и проблемы вида "pacman-key", "keyring" и т.д.
Тогда следует их обновить:
```
pacman-key --init
```
```
pacman-key --populate 
```
```
pacman-key --refresh-keys
```
Включаем службы NetworkManager'a и иных менеджеров:
```
systemctl enable NetworkManager
```
Выходим обратно в загрузочную флешку
```
exit
```
Размонтируемся
```
umount -R /mnt
```
Перезагружаемся
```
reboot
```
Если у вас возникли вопросы по установке которые вы не можете решить с помощью вики арча
