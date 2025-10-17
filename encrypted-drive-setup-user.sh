#!/bin/bash

# Ensure you have root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root"
  exit
fi

# Check for active network connection
echo "Checking network connection..."
if ! ping -c 1 archlinux.org &> /dev/null; then
  echo "No network connection detected. Please set up your network connection."
  wifi-menu
  if ! ping -c 1 archlinux.org &> /dev/null; then
    echo "Network setup failed. Exiting."
    exit 1
  fi
fi

# Update system clock
timedatectl set-ntp true

# Prompt for username and password
read -p "Enter your username: " username

while true; do
  read -s -p "Enter your password: " password
  echo
  read -s -p "Confirm your password: " password_confirm
  echo
  [ "$password" = "$password_confirm" ] && break
  echo "Passwords do not match. Please try again."
done

# Encrypt the password
encrypted_password=$(openssl passwd -6 "$password")

# Set timezone
ln -sf /usr/share/zoneinfo/Pacific/Auckland /etc/localtime
hwclock --systohc

# Localization
echo "en_NZ.UTF-8 UTF-8" > /etc/locale.gen
locale-gen
echo "LANG=en_NZ.UTF-8" > /etc/locale.conf

read -p "Enter your hostname: " hostname

# Network configuration
echo "$hostname" > /etc/hostname

# Set root password
echo "root:${encrypted_password}" | chpasswd -e

# Create user
useradd -m -G wheel -s /bin/bash $username
echo "${username}:${encrypted_password}" | chpasswd -e
sed -i 's/^# %wheel ALL=(ALL:ALL) ALL/%wheel ALL=(ALL:ALL) ALL/' /etc/sudoers
