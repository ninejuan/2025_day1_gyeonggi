# AWS World Skills 2025 - 경기도 대회 Day1 인프라 구성

## 개요
이 프로젝트는 AWS World Skills 2025 경기도 대회 Day1 과제를 위한 인프라 구성입니다.

## 구성 요소
- **VPC**: Hub VPC와 App VPC (VPC Peering으로 연결)
- **Bastion Host**: SSH 포트 10100, EIP 할당
- **RDS Aurora MySQL**: KMS 암호화, 백업, 모니터링
- **ECS**: Green(EC2), Red(Fargate) 서비스
- **ECR**: 컨테이너 이미지 저장소
- **Load Balancers**: Hub NLB, App NLB, App ALB
- **CI/CD**: CodeDeploy, CodePipeline
- **Monitoring**: CloudWatch Dashboard, Container Insights

## 사전 준비 사항
1. AWS CLI 설정
2. Terraform 설치 (>= 1.0)
3. 제공된 애플리케이션 바이너리 파일
4. day1_table_v1.sql 파일

## 배포 방법

### 1. Terraform 초기화 및 적용
```bash
# terraform.tfvars 파일에서 account_number 수정
vi terraform.tfvars

# Terraform 초기화
terraform init

# 계획 확인
terraform plan

# 인프라 배포
terraform apply
```

### 2. 컨테이너 이미지 빌드 및 푸시
```bash
# ECR 로그인
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin <ACCOUNT_ID>.dkr.ecr.ap-northeast-2.amazonaws.com

# Green 이미지 빌드 및 푸시
cd app-files/docker/1.0.0
docker build -t green:v1.0.0 -f Dockerfile.green .
docker tag green:v1.0.0 <ACCOUNT_ID>.dkr.ecr.ap-northeast-2.amazonaws.com/green:v1.0.0
docker push <ACCOUNT_ID>.dkr.ecr.ap-northeast-2.amazonaws.com/green:v1.0.0

# Red 이미지 빌드 및 푸시
docker build -t red:v1.0.0 -f Dockerfile.red .
docker tag red:v1.0.0 <ACCOUNT_ID>.dkr.ecr.ap-northeast-2.amazonaws.com/red:v1.0.0
docker push <ACCOUNT_ID>.dkr.ecr.ap-northeast-2.amazonaws.com/red:v1.0.0

# v1.0.1도 동일하게 수행
```

### 3. 데이터베이스 초기화
```bash
# Bastion 서버 접속
ssh -i ~/.ssh/ws25-bastion-key.pem -p 10100 ec2-user@<BASTION_IP>

# RDS 접속 및 테이블 생성
mysql -h <RDS_ENDPOINT> -P 10101 -u admin -p
mysql> source day1_table_v1.sql
```

### 4. 파이프라인 아티팩트 준비
Bastion 서버에서:
```bash
# Green 아티팩트
mkdir -p /home/ec2-user/pipeline/artifact/green
# appspec.yaml과 taskdef.json 파일을 디렉토리에 복사

# Red 아티팩트
mkdir -p /home/ec2-user/pipeline/artifact/red
# appspec.yaml과 taskdef.json 파일을 디렉토리에 복사

# 스크립트 복사
cp green.sh red.sh /home/ec2-user/pipeline/
chmod +x /home/ec2-user/pipeline/*.sh
```

### 5. 배포 실행
```bash
# Green 애플리케이션 배포
/home/ec2-user/pipeline/green.sh

# Red 애플리케이션 배포
/home/ec2-user/pipeline/red.sh
```

## 접속 정보
- **Hub NLB**: terraform output hub_nlb_dns_name
- **Bastion SSH**: terraform output bastion_ssh_command
- **Green API**: http://<HUB_NLB_DNS>/green
- **Red API**: http://<HUB_NLB_DNS>/red

## 주의 사항
- Bastion 인스턴스는 종료 보호가 활성화되어 있습니다
- Secrets Manager의 비밀은 즉시 삭제 가능하도록 설정되어 있습니다
- Fargate와 Lambda 사용은 금지되어 있습니다 (Red는 예외)
- 모든 리소스는 ap-northeast-2 리전에 생성됩니다
