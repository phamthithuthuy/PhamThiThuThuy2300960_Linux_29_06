#!/usr/bin/env bash
set -euo pipefail

if [ "${EUID}" -ne 0 ]; then
    echo "Vui long chay script bang quyen root."
    exit 1
fi

PASSWORD="123456"
HOME_MOUNT="/home"
HOME_DEVICE="${HOME_DEVICE:-}"

title() {
    printf '\n========== %s ==========\n' "$1"
}

add_user() {
    local user_name="$1"
    local group_name="$2"

    if id "${user_name}" >/dev/null 2>&1; then
        usermod -g "${group_name}" "${user_name}"
    else
        useradd -m -g "${group_name}" "${user_name}"
    fi

    echo "${user_name}:${PASSWORD}" | chpasswd
}

title "Cau 1: Kiem tra /home"
if findmnt -rn "${HOME_MOUNT}" >/dev/null 2>&1; then
    findmnt "${HOME_MOUNT}"
else
    dd if=/dev/zero of=/root/home_disk.img bs=1M count=0 seek=5120
    mkfs.ext4 -F /root/home_disk.img
    mkdir -p /mnt/new_home
    mount /root/home_disk.img /mnt/new_home
    cp -a /home/. /mnt/new_home/ 2>/dev/null || true
    umount /mnt/new_home
    mount /root/home_disk.img "${HOME_MOUNT}"
    echo "/root/home_disk.img ${HOME_MOUNT} ext4 defaults,usrquota,grpquota 0 2" >> /etc/fstab
    findmnt "${HOME_MOUNT}"
fi

title "Cau 2: Tao nhom va user"
groupadd -f hocvien
groupadd -f admin
add_user hv1 hocvien
add_user hv2 hocvien
add_user hv3 hocvien
add_user admin1 admin
add_user admin2 admin

title "Cau 3: Sua description admin"
usermod -c "Người dùng quản trị hệ thống" admin1
usermod -c "Người dùng quản trị hệ thống" admin2
getent passwd admin1 admin2

title "Cau 4: Quota 10 KB cho hocvien"
if ! command -v quotacheck >/dev/null 2>&1; then
    apt-get install -y quota
fi
mount -o remount,usrquota,grpquota "${HOME_MOUNT}"
quotacheck -cum "${HOME_MOUNT}" || true
quotacheck -cgm "${HOME_MOUNT}" || true
quotaon "${HOME_MOUNT}" || true
setquota -u hv1 10 12 0 0 "${HOME_MOUNT}"
setquota -u hv2 10 12 0 0 "${HOME_MOUNT}"
setquota -u hv3 10 12 0 0 "${HOME_MOUNT}"
repquota "${HOME_MOUNT}" || true

title "Cau 5: Quota 20 KB cho admin"
setquota -u admin1 20 22 0 0 "${HOME_MOUNT}"
setquota -u admin2 20 22 0 0 "${HOME_MOUNT}"
repquota "${HOME_MOUNT}" || true

title "Cau 6: Dat thoi gian canh bao mot tuan"
setquota -u -t 604800 604800 "${HOME_MOUNT}" || true
repquota "${HOME_MOUNT}" || true

title "Cau 7: Thu vuot 10 KB voi hv1"
su - hv1 -c "dd if=/dev/zero of=/home/hv1/test_quota.dat bs=1K count=11" || true
quota -u hv1 || true

title "Cau 8: Thu vuot 20 KB voi admin1"
su - admin1 -c "dd if=/dev/zero of=/home/admin1/test_quota.dat bs=1K count=21" || true
quota -u admin1 || true

title "Cau 9: Dat umask 027 va tao mau"
umask 027
touch /home/hv1/file_umask
mkdir -p /home/hv1/dir_umask
chown hv1:hocvien /home/hv1/file_umask /home/hv1/dir_umask
ls -l /home/hv1/file_umask
ls -ld /home/hv1/dir_umask

title "Cau 10: Thong ke tai nguyen theo user"
ps -eo user,pid,%cpu,%mem,comm --sort=user | head -50
du -sh /home/* 2>/dev/null || true
repquota "${HOME_MOUNT}" || true
