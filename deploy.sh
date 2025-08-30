#!/bin/bash
# =============================================================================
# CloudType.io 자동 배포 스크립트
# Elasticsearch + Nori 플러그인 배포
# =============================================================================

set -e

echo "🚀 Elasticsearch + Nori 플러그인 CloudType 배포 시작..."

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 현재 디렉토리 확인
if [ ! -f "cloudtype.yml" ]; then
    echo -e "${RED}❌ cloudtype.yml 파일을 찾을 수 없습니다.${NC}"
    echo "올바른 프로젝트 디렉토리에서 실행해주세요."
    exit 1
fi

# Git 저장소 초기화 (없는 경우)
if [ ! -d ".git" ]; then
    echo -e "${YELLOW}📁 Git 저장소 초기화 중...${NC}"
    git init
    git add .
    git commit -m "Initial commit: Elasticsearch with Nori plugin"
    echo -e "${GREEN}✅ Git 저장소가 초기화되었습니다.${NC}"
else
    echo -e "${BLUE}📝 변경사항 커밋 중...${NC}"
    git add .
    git commit -m "Update Elasticsearch Nori configuration - $(date '+%Y-%m-%d %H:%M:%S')" || echo "커밋할 변경사항이 없습니다."
fi

# 로컬 Docker 테스트 (선택사항)
read -p "배포 전 로컬에서 테스트하시겠습니까? (y/N): " test_locally

if [[ $test_locally =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}🧪 로컬 Docker 테스트 시작...${NC}"
    
    # Docker Compose로 테스트
    docker-compose up -d
    
    echo -e "${YELLOW}⏳ Elasticsearch 시작 대기 중...${NC}"
    sleep 30
    
    # 헬스체크
    if curl -s http://localhost:9200/_cluster/health > /dev/null; then
        echo -e "${GREEN}✅ Elasticsearch가 정상적으로 실행 중입니다.${NC}"
        
        # Nori 플러그인 확인
        echo -e "${BLUE}🔍 Nori 플러그인 확인 중...${NC}"
        curl -s http://localhost:9200/_nodes/plugins | grep -q "analysis-nori"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ Nori 플러그인이 정상적으로 설치되었습니다.${NC}"
        else
            echo -e "${RED}❌ Nori 플러그인을 찾을 수 없습니다.${NC}"
        fi
        
        # 한국어 분석 테스트
        echo -e "${BLUE}🇰🇷 한국어 분석 테스트...${NC}"
        curl -X POST "localhost:9200/_analyze?pretty" \
             -H 'Content-Type: application/json' \
             -d'{"analyzer": "nori", "text": "안녕하세요 한국어 검색 테스트입니다"}' \
             > /dev/null 2>&1
        
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✅ 한국어 분석이 정상적으로 작동합니다.${NC}"
        else
            echo -e "${YELLOW}⚠️  한국어 분석 테스트를 완료할 수 없습니다.${NC}"
        fi
        
        echo -e "${BLUE}🛑 테스트 컨테이너 정리 중...${NC}"
        docker-compose down
    else
        echo -e "${RED}❌ Elasticsearch 연결에 실패했습니다.${NC}"
        docker-compose down
        exit 1
    fi
fi

echo -e "${GREEN}🎉 준비 완료! 이제 CloudType에서 배포하세요.${NC}"
echo ""
echo -e "${BLUE}📋 CloudType 배포 가이드:${NC}"
echo "1. CloudType 대시보드에 로그인"
echo "2. '새 애플리케이션' 생성"
echo "3. Git 리포지토리 연결"
echo "4. cloudtype.yml 설정 파일 선택"
echo "5. 리소스 설정 확인 (메모리: 1GB, 디스크: 5GB)"
echo "6. 배포 시작"
echo ""
echo -e "${YELLOW}🔗 Git 리포지토리 URL을 CloudType에 설정하는 것을 잊지 마세요!${NC}"

echo -e "${GREEN}✨ 배포 스크립트 완료${NC}"

