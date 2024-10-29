# remote_access

# Setting up a new PiKvm

### Make writable
sudo rw

### Update software
sudo pacman -Syu
sudo shutdown -r now


### change to root & Make os writable
sudo su
rw

## install minicom, picocom, & flashrom
pacman -S minicom picocom
pacman -S flashrom
pacman -S ffmpeg motion

### Add user
sudo groupadd plugdev
useradd -m -G users,wheel,tty,plugdev user

### change default groups to 'users'
usermod -g users kvmd-webterm
usermod -g users user
usermod -g users martin

### Find serial numbers
lsusb
lsusb -vvv -s 001:00X

### install dpcmd
git clone https://github.com/DediProgSW/SF100Linux.git
cd SF100Linux
make
sudo cp 60-dediprog.rules /etc/udev/rules.d/
udevadm control --reload-rules && udevadm trigger
sudo mkdir -p /usr/local/share/DediProg/
sudo cp ChipInfoDb.dedicfg /usr/local/share/DediProg/
sudo usermod -aG plugdev martin
sudo usermod -aG plugdev kvmd-webterm

