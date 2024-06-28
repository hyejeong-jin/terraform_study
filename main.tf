## 소스코드 출처 : https://okms1017.tistory.com/62


provider "aws" {
region = var.region
(* variables.tf 파일에서 선언한 리전 값(ap-northeast-2) *)
}

data "aws_ami" "ubuntu" {
most_recent = true

filter {
name = "name"
values = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]

filter {
name = "virtualization-type"
values = ["hvm"]
}
(* name과 가상화 타입으로 필터링하여 가장 최신의 우분투 ami를 가져옴 *)

owners = ["205983949585"]
(* 최상단 계정 정보 정의 *)
}

data "aws_vpc" "default-vpc"{
filter {
name = "tag:Name"
values = ["default-vpc"]
}
}
(* vpc 태그 값으로 필터링 후 설정. 여기선 따로 생성된 vpc가 아닌 디폴트 vpc 정보를 가져옴 *)

data "aws_subnet" "default-subnet" {
filter {
naem = "tag:Name"
values = ["default-subnet01"]
}
}
(* subnet 태그 값으로 필터링 후 설정. 기본 디폴트 subnet 정보를 가져옴 *)

(* 보안그룹 inbound/ountbound 지정하기 *)
resource "aws_security_group" "web_sg"{
name = "web-sg"
vpc_id = data.aws_vpc.default-vpc.id
(* 디폴트 vpc 정보 가져옴 *)
}

resource "aws_security_group_rule" "sg_22" {
type = "ingress"
(* 인바운드 룰 *)
from_port = 22
to_port = 22
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
(* 22번 포트(ssh) 전체 허용 *)
security_group_id = aws_security_group.web_sg.id
}

(* 인바운드 sg 설정은 위와 같은 블록으로 해주면 됨. 규칙은 추가,삭제,변경을 고려하여 별도 리소스 블록으로 분리 선언하는 것을 추*)

resource "aws_security_group_rule" "sg_80" {
type = "ingress"
from_port = 80
to_port = 80
protocol = "tcp"
cidr_blocks = ["0.0.0.0/0"]
(* 80 포트(http) 웹 서비스 전체 허용 *)
security_group_id = aws_security_group.web_sg.id
}

resource "aws_security_group_rule" "sg_80" {
type = "egress"
(* 아웃바운드 룰 *)
from_port = 0
to_port = 0
protocol = "-1"
(* 웹 서버에 대한 모든 out 허용 *)
cidr_blocks = ["0.0.0.0/0"]
security_group_id = aws_security_group.web_sg.id
}

resource "aws_instance" "web" {
ami = data.aws_ami.ubuntu.id
(* 앞전에 정의한 우분투 ami 이미지를 가져옴*)
instance_type = "t2.micro"
subnet_id = data.aws_subnet.default-subnet.id
vpc_security_group_ids = [aws_security_group_rule.sg_22.id, aws_security_group_rule.sg_80.id]
associate_public_ip_address = true
user_data = file(".....")
(* 유저 데이터와 함께 생성되는 인스턴스 리소스 *)

tags = {
Name = "Apache-WEB"
}
}
