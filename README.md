## WorldSkills Korea 2025 National Day1 - Gyeonggi Project
---

### 배포 전 유의사항
- [ ] CloudWatch의 Log Group이 삭제되어 있는가?
- [ ] rtb pcx는 taa 3번정도 하면 알아서 생김

### 배포 후 진행
- [ ] Bastion에 접속하여 RDS Table 생성
- [ ] artifact의 Green / Red 앱 모두 Secrets, Image 등의 빈 값을 제대로 채워넣기
- [ ] Artifact 디렉토리 전체 압축해서 bastion에 업로드하기.
- [ ] Green / Red Artifact(개별 dir) 압축해서 개별 S3에 업로드
- [ ] CodePipeline / ECS 확인하여 정상 배포됐는지 체크