@echo off
REM =============================================================================
REM CloudType.io 자동 배포 스크립트 (Windows)
REM Elasticsearch + Nori 플러그인 배포
REM =============================================================================

echo 🚀 Elasticsearch + Nori 플러그인 CloudType 배포 시작...

REM 현재 디렉토리 확인
if not exist "cloudtype.yml" (
    echo ❌ cloudtype.yml 파일을 찾을 수 없습니다.
    echo 올바른 프로젝트 디렉토리에서 실행해주세요.
    pause
    exit /b 1
)

REM Git 저장소 초기화 (없는 경우)
if not exist ".git" (
    echo 📁 Git 저장소 초기화 중...
    git init
    git add .
    git commit -m "Initial commit: Elasticsearch with Nori plugin"
    echo ✅ Git 저장소가 초기화되었습니다.
) else (
    echo 📝 변경사항 커밋 중...
    git add .
    git commit -m "Update Elasticsearch Nori configuration - %date% %time%" 2>nul || echo 커밋할 변경사항이 없습니다.
)

REM 로컬 Docker 테스트 (선택사항)
set /p test_locally="배포 전 로컬에서 테스트하시겠습니까? (y/N): "

if /i "%test_locally%"=="y" (
    echo 🧪 로컬 Docker 테스트 시작...
    
    REM Docker Compose로 테스트
    docker-compose up -d
    
    echo ⏳ Elasticsearch 시작 대기 중...
    timeout /t 30 /nobreak > nul
    
    REM 헬스체크
    curl -s http://localhost:9200/_cluster/health > nul 2>&1
    if %errorlevel% equ 0 (
        echo ✅ Elasticsearch가 정상적으로 실행 중입니다.
        
        REM Nori 플러그인 확인
        echo 🔍 Nori 플러그인 확인 중...
        curl -s http://localhost:9200/_nodes/plugins | findstr "analysis-nori" > nul
        if %errorlevel% equ 0 (
            echo ✅ Nori 플러그인이 정상적으로 설치되었습니다.
        ) else (
            echo ❌ Nori 플러그인을 찾을 수 없습니다.
        )
        
        REM 한국어 분석 테스트
        echo 🇰🇷 한국어 분석 테스트...
        curl -X POST "localhost:9200/_analyze?pretty" -H "Content-Type: application/json" -d "{\"analyzer\": \"nori\", \"text\": \"안녕하세요 한국어 검색 테스트입니다\"}" > nul 2>&1
        
        if %errorlevel% equ 0 (
            echo ✅ 한국어 분석이 정상적으로 작동합니다.
        ) else (
            echo ⚠️  한국어 분석 테스트를 완료할 수 없습니다.
        )
        
        echo 🛑 테스트 컨테이너 정리 중...
        docker-compose down
    ) else (
        echo ❌ Elasticsearch 연결에 실패했습니다.
        docker-compose down
        pause
        exit /b 1
    )
)

echo.
echo 🎉 준비 완료! 이제 CloudType에서 배포하세요.
echo.
echo 📋 CloudType 배포 가이드:
echo 1. CloudType 대시보드에 로그인
echo 2. '새 애플리케이션' 생성
echo 3. Git 리포지토리 연결
echo 4. cloudtype.yml 설정 파일 선택
echo 5. 리소스 설정 확인 (메모리: 1GB, 디스크: 5GB)
echo 6. 배포 시작
echo.
echo 🔗 Git 리포지토리 URL을 CloudType에 설정하는 것을 잊지 마세요!
echo.
echo ✨ 배포 스크립트 완료
pause

