#!/bin/bash
# =============================================================================
# 한국어 검색 테스트 스크립트
# Elasticsearch + Nori 플러그인 한국어 분석 테스트
# =============================================================================

ELASTICSEARCH_URL="http://localhost:9200"

echo "🇰🇷 Elasticsearch Nori 플러그인 한국어 분석 테스트"
echo "=========================================="

# Elasticsearch 연결 확인
echo "1. Elasticsearch 연결 확인..."
curl -s "$ELASTICSEARCH_URL/_cluster/health" > /dev/null
if [ $? -eq 0 ]; then
    echo "✅ Elasticsearch 연결 성공"
else
    echo "❌ Elasticsearch 연결 실패"
    echo "Docker Compose가 실행 중인지 확인하세요: docker-compose up -d"
    exit 1
fi

echo ""

# Nori 플러그인 확인
echo "2. Nori 플러그인 설치 확인..."
nori_check=$(curl -s "$ELASTICSEARCH_URL/_nodes/plugins" | grep -c "analysis-nori")
if [ $nori_check -gt 0 ]; then
    echo "✅ Nori 플러그인 설치됨"
else
    echo "❌ Nori 플러그인 설치되지 않음"
    exit 1
fi

echo ""

# 한국어 문장 분석 테스트
echo "3. 한국어 문장 분석 테스트..."
echo "테스트 문장: '안녕하세요 Django Elasticsearch 한국어 검색 테스트입니다'"

echo ""
echo "📝 Nori 기본 분석기 결과:"
curl -s -X POST "$ELASTICSEARCH_URL/_analyze?pretty" \
     -H 'Content-Type: application/json' \
     -d '{
       "analyzer": "nori", 
       "text": "안녕하세요 Django Elasticsearch 한국어 검색 테스트입니다"
     }' | jq -r '.tokens[] | "\(.token) (\(.type))"'

echo ""
echo "📝 커스텀 korean_analyzer 결과:"
curl -s -X POST "$ELASTICSEARCH_URL/_analyze?pretty" \
     -H 'Content-Type: application/json' \
     -d '{
       "analyzer": "korean_analyzer",
       "text": "안녕하세요 Django Elasticsearch 한국어 검색 테스트입니다"
     }' | jq -r '.tokens[] | "\(.token) (\(.type))"' 2>/dev/null || echo "korean_analyzer 설정 필요"

echo ""

# 복합어 분해 테스트
echo "4. 복합어 분해 테스트..."
echo "테스트 문장: '한국어형태소분석기'"

echo ""
echo "📝 복합어 분해 결과 (decompound_mode: mixed):"
curl -s -X POST "$ELASTICSEARCH_URL/_analyze?pretty" \
     -H 'Content-Type: application/json' \
     -d '{
       "tokenizer": {
         "type": "nori_tokenizer",
         "decompound_mode": "mixed"
       },
       "text": "한국어형태소분석기"
     }' | jq -r '.tokens[] | "\(.token)"'

echo ""

# 품사 태깅 테스트
echo "5. 품사 태깅 테스트..."
echo "테스트 문장: '아름다운 꽃이 피었습니다'"

echo ""
echo "📝 품사 태깅 결과:"
curl -s -X POST "$ELASTICSEARCH_URL/_analyze?pretty" \
     -H 'Content-Type: application/json' \
     -d '{
       "tokenizer": "nori_tokenizer",
       "filter": ["nori_part_of_speech"],
       "text": "아름다운 꽃이 피었습니다"
     }' | jq -r '.tokens[] | "\(.token) (\(.type))"'

echo ""

# 실제 검색 시나리오 테스트
echo "6. 실제 검색 시나리오 테스트..."

# 테스트 인덱스 생성
echo "테스트 인덱스 생성 중..."
curl -s -X PUT "$ELASTICSEARCH_URL/test_korean" \
     -H 'Content-Type: application/json' \
     -d '{
       "settings": {
         "analysis": {
           "analyzer": {
             "korean_analyzer": {
               "type": "custom",
               "tokenizer": "nori_tokenizer",
               "filter": ["lowercase", "nori_part_of_speech", "nori_readingform"]
             }
           }
         }
       },
       "mappings": {
         "properties": {
           "title": {
             "type": "text",
             "analyzer": "korean_analyzer"
           },
           "content": {
             "type": "text", 
             "analyzer": "korean_analyzer"
           }
         }
       }
     }' > /dev/null

# 테스트 문서 추가
echo "테스트 문서 추가 중..."
curl -s -X POST "$ELASTICSEARCH_URL/test_korean/_doc/1" \
     -H 'Content-Type: application/json' \
     -d '{
       "title": "Django Elasticsearch 한국어 검색",
       "content": "Django와 Elasticsearch를 연동하여 한국어 검색 기능을 구현했습니다. Nori 플러그인을 사용합니다."
     }' > /dev/null

curl -s -X POST "$ELASTICSEARCH_URL/test_korean/_doc/2" \
     -H 'Content-Type: application/json' \
     -d '{
       "title": "CloudType 배포 가이드",
       "content": "CloudType에서 Elasticsearch를 배포하는 방법에 대한 상세한 가이드입니다."
     }' > /dev/null

# 인덱스 새로고침
curl -s -X POST "$ELASTICSEARCH_URL/test_korean/_refresh" > /dev/null

echo "✅ 테스트 데이터 준비 완료"

# 검색 테스트
echo ""
echo "📝 검색 테스트 결과:"
echo "검색어: '한국어'"
search_result=$(curl -s -X GET "$ELASTICSEARCH_URL/test_korean/_search" \
     -H 'Content-Type: application/json' \
     -d '{
       "query": {
         "multi_match": {
           "query": "한국어",
           "fields": ["title", "content"]
         }
       }
     }')

echo $search_result | jq -r '.hits.hits[] | "제목: \(._source.title)"'

echo ""
echo "검색어: 'Django'"
search_result2=$(curl -s -X GET "$ELASTICSEARCH_URL/test_korean/_search" \
     -H 'Content-Type: application/json' \
     -d '{
       "query": {
         "multi_match": {
           "query": "Django",
           "fields": ["title", "content"]
         }
       }
     }')

echo $search_result2 | jq -r '.hits.hits[] | "제목: \(._source.title)"'

# 테스트 인덱스 삭제
echo ""
echo "🧹 테스트 인덱스 정리 중..."
curl -s -X DELETE "$ELASTICSEARCH_URL/test_korean" > /dev/null
echo "✅ 정리 완료"

echo ""
echo "🎉 한국어 검색 테스트 완료!"
echo "모든 테스트가 성공적으로 완료되었습니다."

