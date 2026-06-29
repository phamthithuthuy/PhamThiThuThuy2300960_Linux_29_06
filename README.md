<div align="center">

# Bài tập Linux ngày 29/06

**Lời giải Đề của Thủy**

| Họ và tên | Mã sinh viên |
| --- | --- |
| Phạm Thị Thu Thùy | 2300960 |

</div>

## Cấu trúc thư mục

```text
.
├── README.md
├── scripts/
│   └── de_thuy.sh
└── tests/
    └── run_tests.sh
```

## Câu 1 (1 điểm)

Kiểm tra xem thư mục `/home` có phải là mount point của một partition riêng biệt hay không. Nếu không thì tạo một partition mới và mount nó vào thư mục `/home`.

```bash
sudo mkdir -p /home_exam
if findmnt -rn /home_exam >/dev/null 2>&1; then
    findmnt /home_exam
else
    sudo dd if=/dev/zero of=/root/home_disk.img bs=1M count=100
    sudo mkfs.ext4 -F /root/home_disk.img
    sudo mount /root/home_disk.img /home_exam
    echo "/root/home_disk.img /home_exam ext4 defaults,usrquota,grpquota 0 2" | sudo tee -a /etc/fstab
    findmnt /home_exam
fi
```

## Câu 2 (1 điểm)

Tạo các nhóm sau:

* `hocvien`
* `admin`

Trong nhóm `hocvien` tạo các người dùng:

* `hv1`
* `hv2`
* `hv3`

Trong nhóm `admin` tạo các người dùng:

* `admin1`
* `admin2`

Các tài khoản đều có mật khẩu là `123456`.

```bash
sudo groupadd -f hocvien
sudo groupadd -f admin

sudo useradd -m -g hocvien hv1 || true
sudo useradd -m -g hocvien hv2 || true
sudo useradd -m -g hocvien hv3 || true
sudo useradd -m -g admin admin1 || true
sudo useradd -m -g admin admin2 || true

echo "hv1:123456" | sudo chpasswd
echo "hv2:123456" | sudo chpasswd
echo "hv3:123456" | sudo chpasswd
echo "admin1:123456" | sudo chpasswd
echo "admin2:123456" | sudo chpasswd
```

## Câu 3 (1 điểm)

Chỉnh sửa mô tả (*description*) của các người dùng:

* `admin1`
* `admin2`

thành:

> Người dùng quản trị hệ thống

để phân biệt với các người dùng khác.

```bash
sudo usermod -c "Người dùng quản trị hệ thống" admin1
sudo usermod -c "Người dùng quản trị hệ thống" admin2
getent passwd admin1 admin2
```

## Câu 4 (1 điểm)

Cấu hình quota cho thư mục `/home` và cấp quota sao cho mỗi người dùng trong nhóm `hocvien` có dung lượng giới hạn là **10 KB**.

```bash
sudo apt-get update && sudo apt-get install -y quota
sudo mount -o remount,usrquota,grpquota /home_exam
sudo quotacheck -cum /home_exam || true
sudo quotacheck -cgm /home_exam || true
sudo quotaon /home_exam || true
sudo setquota -u hv1 10 12 0 0 /home_exam
sudo setquota -u hv2 10 12 0 0 /home_exam
sudo setquota -u hv3 10 12 0 0 /home_exam
sudo repquota /home_exam || true
```

## Câu 5 (1 điểm)

Cấp quota sao cho mỗi người dùng trong nhóm `admin` có dung lượng giới hạn là **20 KB**.

```bash
sudo setquota -u admin1 20 22 0 0 /home_exam
sudo setquota -u admin2 20 22 0 0 /home_exam
sudo repquota /home_exam || true
```

## Câu 6 (1 điểm)

Cấu hình quota cho thư mục `/home` sao cho khi người dùng sử dụng vượt quá dung lượng giới hạn thì gửi một thông báo và sau **một tuần** thì hủy dữ liệu.

```bash
sudo setquota -u -t 604800 604800 /home_exam || true
sudo repquota /home_exam || true
```

## Câu 7 (1 điểm)

Đăng nhập vào người dùng `hv1` và lưu dữ liệu vào thư mục home của mình vượt quá **10 KB**. Quan sát điều gì xảy ra.

```bash
sudo mkdir -p /home_exam/hv1
sudo chown hv1:hocvien /home_exam/hv1
sudo su - hv1 -c "dd if=/dev/zero of=/home_exam/hv1/test_quota.dat bs=1K count=11" || true
sudo quota -u hv1 || true
```

## Câu 8 (1 điểm)

Đăng nhập vào người dùng `admin1` và lưu dữ liệu vào thư mục home của mình vượt quá **20 KB**. Quan sát điều gì xảy ra.

```bash
sudo mkdir -p /home_exam/admin1
sudo chown admin1:admin /home_exam/admin1
sudo su - admin1 -c "dd if=/dev/zero of=/home_exam/admin1/test_quota.dat bs=1K count=21" || true
sudo quota -u admin1 || true
```

## Câu 9 (1 điểm)

Thiết lập quyền mặc định như sau:

* Người sở hữu: đọc, ghi
* Nhóm: đọc
* Người khác: không có quyền

Sau đó tạo tập tin, thư mục và so sánh quyền.

```bash
umask 027
sudo touch /home_exam/file_umask
sudo mkdir -p /home_exam/dir_umask
sudo ls -l /home_exam/file_umask
sudo ls -ld /home_exam/dir_umask
```

## Câu 10 (1 điểm)

Theo dõi và thống kê sử dụng tài nguyên hệ thống của User.

```bash
ps -eo user,pid,%cpu,%mem,comm --sort=user | head -50
sudo du -sh /home_exam/* 2>/dev/null || true
sudo repquota /home_exam || true
```
