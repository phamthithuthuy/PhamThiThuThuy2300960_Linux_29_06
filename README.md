<div align="center">

# Bài cuối kỳ Linux ngày 29/06

**Lời giải đề cuối kỳ của Thùy**

| Họ và tên | Mã sinh viên |
| --- | --- |
| Phạm Thị Thu Thùy | 2300960 |

</div>

## Cấu trúc thư mục

```text
.
├── README.md
├── assets/
│   ├── code-de-thuy.png
│   └── diagram-de-thuy.png
├── diagrams/
│   └── de_thuy_flow.puml
├── scripts/
│   └── de_thuy.sh
└── tests/
    └── run_tests.sh
```

## Sơ đồ xử lý

![Sơ đồ xử lý Đề của Thùy](assets/diagram-de-thuy.png)

## Nội dung bài cuối kỳ

Script `scripts/de_thuy.sh` thực hiện lần lượt 10 câu của đề:

| Câu | Chức năng |
| --- | --- |
| 1 | Kiểm tra `/home` có phải mount point riêng hay không; nếu chưa có thì dùng biến `HOME_DEVICE` để định dạng và mount phân vùng vào `/home`. |
| 2 | Tạo nhóm `hocvien`, `admin`; tạo người dùng `hv1`, `hv2`, `hv3`, `admin1`, `admin2` với mật khẩu `123456`. |
| 3 | Đặt mô tả cho `admin1`, `admin2` là `Người dùng quản trị hệ thống`. |
| 4 | Bật quota trên `/home`, đặt quota cho mỗi người dùng nhóm `hocvien` với mức mềm 10 KB và mức cứng 12 KB. |
| 5 | Đặt quota cho mỗi người dùng nhóm `admin` với mức mềm 20 KB và mức cứng 22 KB. |
| 6 | Đặt thời gian cảnh báo quota là một tuần. |
| 7 | Đăng nhập `hv1`, tạo dữ liệu vượt 10 KB và xem trạng thái quota. |
| 8 | Đăng nhập `admin1`, tạo dữ liệu vượt 20 KB và xem trạng thái quota. |
| 9 | Đặt `umask 027`, tạo tập tin và thư mục để so sánh quyền mặc định. |
| 10 | Theo dõi tiến trình, dung lượng thư mục home và thống kê quota theo người dùng. |

## Ảnh chụp mã nguồn

![Ảnh chụp mã nguồn Đề của Thùy](assets/code-de-thuy.png)

## Cách chạy

Nếu `/home` đã là mount point riêng:

```bash
chmod +x scripts/de_thuy.sh
sudo bash scripts/de_thuy.sh
```

Nếu cần tạo phân vùng mới cho `/home`, thay `/dev/sdb1` bằng phân vùng thực tế của máy cuối kỳ:

```bash
sudo HOME_DEVICE=/dev/sdb1 CONFIRM_FORMAT_HOME_DEVICE=yes bash scripts/de_thuy.sh
```

Nếu máy chưa có công cụ quota, script sẽ tự kiểm tra và cài gói cần thiết bằng trình quản lý gói hiện có.

## Kiểm thử

```bash
bash tests/run_tests.sh
```

Kiểm thử kiểm tra cú pháp Bash và sự tồn tại của các tệp chính trong bài.
