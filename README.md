# Kali Linux Scanning Tools Collection

이 레포지토리는 Kali Linux에서 사용되는 다양한 모의해킹 스캐닝 도구들을 쉽게 사용할 수 있도록 만든 쉘 스크립트 모음입니다.

## 디렉토리 구조

```
.
├── attack.sh
├── scripts/
│   ├── nmap.sh
│   ├── dirb.sh
│   ├── nikto.sh
│   └── gobuster.sh
├── logs/
│   ├── nmap/
│   ├── dirb/
│   ├── nikto/
│   ├── gobuster/
│   └── attack/
└── README.md
```

## 주요 스크립트 설명

### attack.sh
- 메인 실행 스크립트
- 사용 가능한 스캐닝 도구들을 메뉴로 제공
- 사용자가 선택한 스크립트를 실행
- 로그 디렉토리 자동 생성 및 관리
- 전체 실행 세션을 logs/attack/ 디렉토리에 저장

### scripts/nmap.sh
- 포트 스캐닝 도구
- 대상 IP의 열린 포트, 서비스, 버전 정보를 스캔
- 결과를 테이블 형식으로 표시
- 상태에 따른 컬러 출력 지원 (열린 포트: 초록색, 닫힌 포트: 빨간색)
- 스캔 결과는 logs/nmap/ 디렉토리에 저장

### scripts/nikto.sh
- 웹 서버 취약점 스캐닝 도구
- 웹 서버의 알려진 취약점을 검사
- 위험도에 따른 결과 분류 (Low, Medium, High)
- 컬러 출력으로 위험도 구분
- 스캔 결과는 logs/nikto/ 디렉토리에 저장

### scripts/dirb.sh
- 디렉토리 브루트포스 스캐닝 도구
- 웹 서버의 숨겨진 디렉토리와 파일을 검색
- 기본 워드리스트: common.txt
- 발견된 항목을 디렉토리와 파일로 구분하여 표시
- HTTP 상태 코드에 따른 컬러 출력 지원
- 스캔 결과는 logs/dirb/ 디렉토리에 저장

### scripts/gobuster.sh
- 디렉토리 및 파일 브루트포스 스캐닝 도구
- 웹 서버의 숨겨진 디렉토리와 파일을 검색
- 기본 워드리스트: common.txt
- 기본 확장자: html, php, txt
- 발견된 항목을 디렉토리와 파일로 구분하여 표시
- 파일 타입별 구분 (HTML, PHP, TXT 등)
- 기본 워드리스트 또는 사용자 정의 워드리스트 선택 가능
- 기본 탐색 파일 확장자 또는 사용자 정의 확장자 선택 가능
- 스캔 결과는 logs/gobuster/ 디렉토리에 저장

## 사용 방법

1. 스크립트 실행:
```bash
./attack.sh
```

2. 메뉴에서 원하는 스캐닝 도구 선택:
   - 1: Nmap Port Scanner
   - 2: Nikto Web Scanner
   - 3: Dirb Directory Scanner
   - 4: Gobuster Directory Scanner
   - 5: Exit

3. 필요한 정보 입력:
   - Nmap: 대상 IP 주소 (ex: 192.168.1.1)
   - Dirb/Nikto/Gobuster: 
     - 대상 URL (ex: http://192.168.1.1 또는 http://domain.com)
     - 워드리스트 선택 (기본 또는 사용자 정의)
     - Gobuster의 경우 파일 확장자 선택 가능 (ex: html, php, txt)

4. 입력 정보 확인:
   - 입력한 정보가 맞는지 확인 (y/n)
   - 틀린 경우 재입력 가능

5. 스캔 결과 확인:
   - 실시간으로 화면에 출력
   - 자동으로 logs 디렉토리에 저장

6. 추가 스캔:
   - 스캔 완료 후 추가 스캔 여부 선택 가능
   - 이전 스캔 결과가 화면에 유지된 상태로 계속 진행

## 로그 파일
- 모든 스캔 결과는 자동으로 logs 디렉토리 아래에 저장
- 모든 로그 파일명에 타임스탬프 포함
- 각 도구별로 별도의 디렉토리에 저장

```
logs/
  ├── nmap/ : 포트 스캔 결과
  ├── dirb/ : 디렉토리/파일 스캔 결과
  ├── nikto/ : 취약점 스캔 결과
  ├── gobuster/ : 디렉토리/파일 스캔 결과
  └── attack/ : 전체 실행 세션 로그
```

## 요구사항
- Kali Linux 운영체제
- nikto 설치
- nmap 설치
- dirb 설치
- gobuster 설치

## 주의사항
이 도구들은 허가된 시스템에서만 사용해야 합니다. 허가되지 않은 시스템에 대한 스캐닝은 법적 문제를 일으킬 수 있습니다.
