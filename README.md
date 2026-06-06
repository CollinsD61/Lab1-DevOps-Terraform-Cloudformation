# AWS Modular Infrastructure Deployment (Terraform & CloudFormation)

Dự án này thực hiện thiết kế, triển khai tự động và kiểm thử một hạ tầng mạng VPC hoàn chỉnh trên AWS sử dụng cả hai công cụ Infrastructure as Code (IaC) phổ biến nhất: **Terraform** và **CloudFormation**. Dự án đáp ứng các tiêu chuẩn bảo mật khắt khe với mô hình Bastion Host (Public EC2) để truy cập gián tiếp vào Private EC2.

---

## 1. Kiến trúc Hạ tầng (Architecture)

Kiến trúc bao bao gồm các thành phần sau:
* **VPC**: `10.0.0.0/16`
* **Subnets**:
  * **Public Subnet**: `10.0.1.0/24` (kết nối Internet Gateway, tự động gán IP công cộng).
  * **Private Subnet**: `10.0.2.0/24` (không có IP công cộng, kết nối ra ngoài qua NAT Gateway).
* **Gateways**:
  * **Internet Gateway (IGW)**: Cho phép lưu lượng từ Public Subnet đi ra ngoài internet.
  * **NAT Gateway**: Đặt tại Public Subnet, cho phép các tài nguyên trong Private Subnet truy cập internet (để cập nhật phần mềm, tải thư viện...) nhưng chặn kết nối trực tiếp từ ngoài vào.
* **Security Groups**:
  * **Public EC2 SG**: Chỉ cho phép SSH (Port 22) từ IP cụ thể của quản trị viên (`AdminIpCidr`).
  * **Private EC2 SG**: Chỉ cho phép kết nối SSH (Port 22) từ Public EC2 Instance (Bastion Host).
* **EC2 Instances**:
  * **Public EC2**: Đóng vai trò Bastion Host (Jump Box).
  * **Private EC2**: Nằm an toàn trong Private Subnet, không thể truy cập trực tiếp từ Internet.

---

## 2. Yêu cầu Tiền đề (Prerequisites)

Để chạy dự án này, bạn cần chuẩn bị:
1. Tài khoản AWS hoạt động.
2. [AWS CLI](https://aws.amazon.com/cli/) đã được cài đặt và cấu hình credentials (`aws configure`).
3. [Terraform](https://developer.hashicorp.com/terraform/downloads) (phiên bản `>= 1.2.0`).
4. [Python 3.x](https://www.python.org/downloads/) (để chạy các kịch bản kiểm thử tự động).

---

## 3. Triển khai bằng Terraform

Mã nguồn Terraform được tổ chức theo cấu trúc module:
* `modules/vpc`: Quản lý VPC, Subnet, Route Tables, Internet Gateway, NAT Gateway.
* `modules/security_groups`: Quản lý các nhóm bảo mật.
* `modules/ec2`: Quản lý các máy chủ EC2 public và private.

### Các bước thực hiện:
1. Di chuyển vào thư mục `terraform`:
   ```bash
   cd terraform
   ```
2. Mở file `terraform.tfvars` và cấu hình các thông số của bạn:
   * `key_name`: Tên Key Pair của bạn trên AWS (phải tồn tại trước).
   * `admin_ip_cidr`: IP của máy bạn (ví dụ: `203.0.113.50/32`) để bảo mật cổng SSH.
3. Khởi tạo Terraform:
   ```bash
   terraform init
   ```
4. Kiểm tra tài nguyên sẽ tạo:
   ```bash
   terraform plan
   ```
5. Tiến hành triển khai hạ tầng:
   ```bash
   terraform apply -auto-approve
   ```
6. Ghi lại các giá trị đầu ra (Outputs) hiển thị trên màn hình (như IP công cộng của Public EC2).

---

## 4. Triển khai bằng CloudFormation

Mã nguồn CloudFormation sử dụng tính năng **Nested Stacks** để đảm bảo tính module hóa:
* `master.yaml`: File chạy chính, điều phối và truyền tham số giữa các stack con.
* `templates/vpc.yaml`: Tạo VPC và hạ tầng mạng.
* `templates/security-groups.yaml`: Tạo các Security Group.
* `templates/ec2.yaml`: Tạo các máy ảo EC2.

### Các bước thực hiện:
Do CloudFormation Nested Stacks yêu cầu các file template con phải được upload lên một S3 bucket trước khi chạy, dự án cung cấp một file script PowerShell để tự động hóa toàn bộ quá trình:

1. Di chuyển vào thư mục `cloudformation`:
   ```powershell
   cd cloudformation
   ```
2. Thực hiện chạy script `deploy.ps1` (Thay đổi tên bucket và tên keypair của bạn):
   ```powershell
   .\deploy.ps1 -BucketName "ten-s3-bucket-cua-ban" -KeyName "lab-keypair" -AdminIpCidr "203.0.113.50/32"
   ```
   * *Lưu ý: Script sẽ tự động kiểm tra, tạo S3 bucket nếu chưa có, đồng bộ các template con lên S3 và kích hoạt lệnh deploy CloudFormation thông qua AWS CLI.*

---

## 5. Chạy Kiểm thử Tự động (Test Cases)

Dự án đi kèm bộ test case tự động viết bằng `pytest` và `boto3` để xác minh hạ tầng đã được tạo và cấu hình đúng yêu cầu của Lab.

### Các bước chạy test:
1. Di chuyển vào thư mục `tests`:
   ```powershell
   cd tests
   ```
2. Chạy file script để thiết lập môi trường ảo Python và khởi chạy kiểm thử:
   ```powershell
   .\run_tests.ps1 -EnvironmentTag "lab-devops"
   ```
3. Kết quả kiểm thử sẽ hiển thị dạng màu sắc trực quan, cho biết chính xác dịch vụ nào đã hoạt động thành công hoặc thất bại.

---

## 6. Dọn dẹp tài nguyên (Cleanup)

Để tránh phát sinh chi phí không mong muốn trên AWS, hãy xóa tài nguyên sau khi hoàn thành:

### Xóa Terraform:
```bash
cd terraform
terraform destroy -auto-approve
```

### Xóa CloudFormation:
```bash
aws cloudformation delete-stack --stack-name lab-devops-cf-stack
```
*(Đồng thời xóa thủ công bucket S3 đã tạo để chứa các templates)*
# Lab1-DevOps-Terraform-Cloudformation
