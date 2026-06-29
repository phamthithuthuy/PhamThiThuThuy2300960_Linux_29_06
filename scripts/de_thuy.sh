#!/usr/bin/env bash
set -euo pipefail

PASSWORD="123456"
HOME_MOUNT="/home"
HOCVIEN_SOFT_KB=10
HOCVIEN_HARD_KB=12
ADMIN_SOFT_KB=20
ADMIN_HARD_KB=22
GRACE_SECONDS=604800

require_root() {
    if [ "${EUID}" -ne 0 ]; then
        echo "Vui long chay script bang quyen root."
        exit 1
    fi
}

require_command() {
    local command_name="$1"

    if ! command -v "${command_name}" >/dev/null 2>&1; then
        echo "Thieu lenh ${command_name}. Hay cai goi phu hop truoc khi chay."
        exit 1
    fi
}

install_quota_tools() {
    if command -v quotacheck >/dev/null 2>&1 &&
        command -v quotaon >/dev/null 2>&1 &&
        command -v setquota >/dev/null 2>&1 &&
        command -v repquota >/dev/null 2>&1; then
        echo "Cong cu quota da duoc cai dat."
        return
    fi

    if command -v apt-get >/dev/null 2>&1; then
        apt-get update
        DEBIAN_FRONTEND=noninteractive apt-get install -y quota
    elif command -v dnf >/dev/null 2>&1; then
        dnf install -y quota
    elif command -v yum >/dev/null 2>&1; then
        yum install -y quota
    else
        echo "Thieu cong cu quota va khong tim thay trinh quan ly goi phu hop."
        exit 1
    fi
}

print_title() {
    printf '\n========== %s ==========\n' "$1"
}

ensure_group() {
    local group_name="$1"

    if getent group "${group_name}" >/dev/null; then
        echo "Nhom ${group_name} da ton tai."
    else
        groupadd "${group_name}"
        echo "Da tao nhom ${group_name}."
    fi
}

ensure_user() {
    local user_name="$1"
    local primary_group="$2"

    if id "${user_name}" >/dev/null 2>&1; then
        usermod -g "${primary_group}" "${user_name}"
        echo "Nguoi dung ${user_name} da ton tai, cap nhat nhom chinh la ${primary_group}."
    else
        useradd -m -g "${primary_group}" "${user_name}"
        echo "Da tao nguoi dung ${user_name} trong nhom ${primary_group}."
    fi

    echo "${user_name}:${PASSWORD}" | chpasswd
}

cau_1() {
    print_title "Cau 1: Kiem tra mount point /home"
    if findmnt -rn "${HOME_MOUNT}" >/dev/null 2>&1; then
        echo "${HOME_MOUNT} dang la mount point rieng."
        findmnt "${HOME_MOUNT}"
        return
    fi

    echo "${HOME_MOUNT} chua la mount point rieng."
    if [ -z "${HOME_DEVICE:-}" ]; then
        echo "Dat HOME_DEVICE=/dev/<phan-vung> va chay lai de dinh dang, mount vao /home."
        exit 1
    fi

    if [ "${CONFIRM_FORMAT_HOME_DEVICE:-no}" != "yes" ]; then
        echo "Lenh se dinh dang ${HOME_DEVICE}. Dat CONFIRM_FORMAT_HOME_DEVICE=yes neu chac chan."
        exit 1
    fi

    mkdir -p "${HOME_MOUNT}"
    mkfs.ext4 -F "${HOME_DEVICE}"

    local uuid
    uuid="$(blkid -s UUID -o value "${HOME_DEVICE}")"
    cp -a /etc/fstab "/etc/fstab.bak.$(date +%Y%m%d%H%M%S)"
    printf 'UUID=%s %s ext4 defaults,usrquota,grpquota 0 2\n' "${uuid}" "${HOME_MOUNT}" >> /etc/fstab
    mount "${HOME_MOUNT}"
    findmnt "${HOME_MOUNT}"
}

cau_2() {
    print_title "Cau 2: Tao nhom va nguoi dung"
    ensure_group "hocvien"
    ensure_group "admin"

    ensure_user "hv1" "hocvien"
    ensure_user "hv2" "hocvien"
    ensure_user "hv3" "hocvien"
    ensure_user "admin1" "admin"
    ensure_user "admin2" "admin"
}

cau_3() {
    print_title "Cau 3: Chinh sua mo ta admin1 va admin2"
    usermod -c "Nguoi dung quan tri he thong" "admin1"
    usermod -c "Nguoi dung quan tri he thong" "admin2"
    getent passwd "admin1" "admin2"
}

enable_quota_on_home() {
    print_title "Bat quota tren /home"
    install_quota_tools
    require_command "quotacheck"
    require_command "quotaon"
    require_command "setquota"
    require_command "repquota"

    mount -o remount,usrquota,grpquota "${HOME_MOUNT}"
    quotacheck -cum "${HOME_MOUNT}"
    quotacheck -cgm "${HOME_MOUNT}"
    quotaon "${HOME_MOUNT}"
}

set_user_quota_for_group() {
    local group_name="$1"
    local soft_kb="$2"
    local hard_kb="$3"

    while IFS=: read -r user_name _ uid gid _ _ _; do
        if [ "${uid}" -ge 1000 ] && [ "$(id -gn "${user_name}")" = "${group_name}" ]; then
            setquota -u "${user_name}" "${soft_kb}" "${hard_kb}" 0 0 "${HOME_MOUNT}"
            echo "Da dat quota cho ${user_name}: soft=${soft_kb}KB, hard=${hard_kb}KB."
        fi
    done < /etc/passwd
}

cau_4() {
    print_title "Cau 4: Dat quota 10 KB cho nhom hocvien"
    enable_quota_on_home
    set_user_quota_for_group "hocvien" "${HOCVIEN_SOFT_KB}" "${HOCVIEN_HARD_KB}"
    repquota "${HOME_MOUNT}"
}

cau_5() {
    print_title "Cau 5: Dat quota 20 KB cho nhom admin"
    set_user_quota_for_group "admin" "${ADMIN_SOFT_KB}" "${ADMIN_HARD_KB}"
    repquota "${HOME_MOUNT}"
}

cau_6() {
    print_title "Cau 6: Dat thoi gian canh bao quota mot tuan"
    setquota -u -t "${GRACE_SECONDS}" "${GRACE_SECONDS}" "${HOME_MOUNT}"
    if command -v warnquota >/dev/null 2>&1; then
        warnquota -u || true
    fi
    repquota "${HOME_MOUNT}"
}

cau_7() {
    print_title "Cau 7: Thu vuot quota voi hv1"
    su - "hv1" -c "dd if=/dev/zero of=/home/hv1/vuot_quota_hv1.dat bs=1K count=11 status=none" || true
    quota -u "hv1" || true
}

cau_8() {
    print_title "Cau 8: Thu vuot quota voi admin1"
    su - "admin1" -c "dd if=/dev/zero of=/home/admin1/vuot_quota_admin1.dat bs=1K count=21 status=none" || true
    quota -u "admin1" || true
}

cau_9() {
    print_title "Cau 9: Thiet lap quyen mac dinh bang umask 027"
    umask 027

    local sample_file="/home/hv1/taptin_umask"
    local sample_dir="/home/hv1/thumuc_umask"

    rm -f "${sample_file}"
    rm -rf "${sample_dir}"
    touch "${sample_file}"
    mkdir "${sample_dir}"
    chown hv1:hocvien "${sample_file}" "${sample_dir}"

    ls -l "${sample_file}"
    ls -ld "${sample_dir}"
}

cau_10() {
    print_title "Cau 10: Theo doi tai nguyen he thong theo user"
    ps -eo user,pid,ppid,%cpu,%mem,comm --sort=user | head -50
    du -sh /home/* 2>/dev/null || true
    repquota "${HOME_MOUNT}" || true
}

main() {
    require_root
    cau_1
    cau_2
    cau_3
    cau_4
    cau_5
    cau_6
    cau_7
    cau_8
    cau_9
    cau_10
}

main "$@"
