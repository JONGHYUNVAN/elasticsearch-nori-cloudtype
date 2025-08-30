# Elasticsearch with Nori Plugin for CloudType

Django 애플리케이션과 연동할 수 있는 한국어 검색 최적화 Elasticsearch 서버입니다. Nori 플러그인이 포함되어 있어 한국어 형태소 분석이 가능합니다.

## 🌟 주요 특징

- **Nori 플러그인**: 한국어 형태소 분석 자동 설정
- **CloudType 최적화**: CloudType.io 플랫폼에 최적화된 설정
- **Django 연동**: Django-Elasticsearch-DSL과 호환
- **한국어 검색**: 커스텀 분석기로 한국어 검색 품질 향상
- **모니터링**: 헬스체크 및 성능 모니터링 포함

## 📁 파일 구조

```
elasticsearch-nori-cloudtype/
├── Dockerfile                 # Elasticsearch + Nori 플러그인 이미지
├── cloudtype.yml             # CloudType 배포 설정
├── docker-compose.yml        # 로컬 개발/테스트용
├── config/
│   └── elasticsearch.yml     # Elasticsearch 상세 설정
├── deploy.sh                 # 배포 스크립트 (Linux/Mac)
├── deploy.bat                # 배포 스크립트 (Windows)
├── .gitignore               # Git 무시 파일
└── README.md                # 이 파일
```

## 🚀 빠른 시작

### 1. 로컬 테스트

```bash
# 저장소 클론
git clone <your-repository-url>
cd elasticsearch-nori-cloudtype

# Docker Compose로 실행
docker-compose up -d

# 헬스체크
curl http://localhost:9200/_cluster/health

# Nori 플러그인 확인
curl http://localhost:9200/_nodes/plugins | grep analysis-nori

# 한국어 분석 테스트
curl -X POST "localhost:9200/_analyze?pretty" \
     -H 'Content-Type: application/json' \
     -d'{"analyzer": "nori", "text": "안녕하세요 한국어 검색 테스트입니다"}'
```

### 2. CloudType 배포

#### 자동 배포 (권장)
```bash
# Linux/Mac
./deploy.sh

# Windows
deploy.bat
```

#### 수동 배포
1. CloudType 대시보드 접속
2. "새 애플리케이션" 생성
3. Git 리포지토리 연결
4. `cloudtype.yml` 설정 파일 선택
5. 리소스 설정 확인:
   - 메모리: 1GB
   - 디스크: 5GB
   - CPU: 0.5 core
6. 배포 시작

## 🔧 설정 상세

### Elasticsearch 설정

- **버전**: 8.15.0
- **플러그인**: analysis-nori (한국어 형태소 분석)
- **클러스터**: 단일 노드 모드
- **보안**: 비활성화 (개발/테스트용)
- **메모리**: 512MB JVM 힙

### 한국어 분석기

#### korean_analyzer
- **용도**: 인덱싱용
- **토크나이저**: nori_tokenizer
- **분해 모드**: mixed (복합어 분해)
- **필터**: lowercase, nori_part_of_speech, nori_readingform, cjk_width

#### korean_search_analyzer  
- **용도**: 검색용
- **토크나이저**: nori_tokenizer
- **분해 모드**: none (복합어 분해 안함)
- **필터**: lowercase, nori_part_of_speech, nori_readingform, cjk_width

### 사용자 사전

기본적으로 다음 단어들이 사용자 사전에 포함되어 있습니다:
- Django
- ElasticSearch  
- CloudType
- 한국어
- 형태소
- 분석

## 🔌 Django 연동

### 1. 패키지 설치

```bash
pip install django-elasticsearch-dsl elasticsearch==7.17.9
```

### 2. Django 설정

```python
# settings.py
INSTALLED_APPS = [
    # ...
    'django_elasticsearch_dsl',
]

ELASTICSEARCH_DSL = {
    'default': {
        'hosts': 'http://<cloudtype-elasticsearch-url>:9200',
        'timeout': 20,
    },
}
```

### 3. 문서 정의

```python
# documents.py
from django_elasticsearch_dsl import Document, Index, fields
from django_elasticsearch_dsl.registries import registry
from .models import Post

@registry.register_document
class PostDocument(Document):
    title = fields.TextField(
        analyzer='korean_analyzer',
        search_analyzer='korean_search_analyzer'
    )
    content = fields.TextField(
        analyzer='korean_analyzer', 
        search_analyzer='korean_search_analyzer'
    )
    
    class Index:
        name = 'posts'
        settings = {
            'number_of_shards': 1,
            'number_of_replicas': 0,
        }
    
    class Django:
        model = Post
        fields = ['created_at', 'updated_at']
```

### 4. 인덱스 생성

```bash
python manage.py search_index --rebuild
```

### 5. 검색 구현

```python
# views.py
from elasticsearch_dsl import Q
from .documents import PostDocument

def search_posts(request):
    query = request.GET.get('q', '')
    
    if query:
        search = PostDocument.search().query(
            Q("multi_match", 
              query=query,
              fields=['title^2', 'content'],
              analyzer='korean_search_analyzer'
            )
        )
        posts = search.to_queryset()
    else:
        posts = Post.objects.none()
    
    return render(request, 'search_results.html', {'posts': posts})
```

## 📊 모니터링

### 기본 엔드포인트

- **헬스체크**: `GET /_cluster/health`
- **노드 정보**: `GET /_nodes`
- **플러그인 확인**: `GET /_nodes/plugins`
- **인덱스 목록**: `GET /_cat/indices`

### Kibana (옵션)

로컬 개발 시 Kibana가 포함되어 있습니다:
- URL: `http://localhost:5601`
- Elasticsearch 연결: 자동 설정됨

### Elasticsearch Head (옵션)

간단한 웹 GUI가 포함되어 있습니다:
- URL: `http://localhost:9100`
- Elasticsearch 클러스터 관리 가능

## ⚠️ 주의사항

### 리소스 요구사항
- **최소 메모리**: 1GB RAM
- **권장 메모리**: 2GB+ RAM (프로덕션)
- **디스크**: 최소 5GB

### 보안
- 현재 설정은 개발/테스트용으로 보안이 비활성화되어 있습니다
- 프로덕션 환경에서는 `xpack.security.enabled=true` 권장
- HTTPS 및 인증 설정 필요

### CloudType 제한사항
- 무료 플랜의 경우 리소스 제한 확인 필요
- 영구 볼륨 설정으로 데이터 유실 방지
- 네트워크 정책에 따른 연결 제한 가능

## 🛠 문제 해결

### Elasticsearch 연결 실패
1. CloudType 서비스 상태 확인
2. 네트워크 설정 점검
3. 포트 개방 확인 (9200, 9300)

### Nori 플러그인 인식 안됨
1. Dockerfile의 플러그인 설치 확인
2. Elasticsearch 버전 호환성 점검 (6.4.0+)
3. 컨테이너 로그 확인

### 한국어 검색 결과 부정확
1. 분석기 설정 확인
2. `decompound_mode` 조정 (mixed/none)
3. `stoptags` 튜닝
4. 사용자 사전 추가

### 메모리 부족
1. JVM 힙 크기 조정 (`ES_JAVA_OPTS`)
2. CloudType 리소스 할당 증가
3. 불필요한 플러그인 비활성화

## 📞 지원

### 공식 문서
- [Elasticsearch 공식 문서](https://www.elastic.co/guide/en/elasticsearch/reference/current/index.html)
- [Nori 플러그인 가이드](https://www.elastic.co/guide/en/elasticsearch/plugins/current/analysis-nori.html)
- [Django-Elasticsearch-DSL](https://django-elasticsearch-dsl.readthedocs.io/)
- [CloudType 가이드](https://docs.cloudtype.io/)

### 커뮤니티
- Elasticsearch 한국 사용자 그룹
- Django Korea 커뮤니티

## 📝 라이선스

이 프로젝트는 MIT 라이선스 하에 제공됩니다.

## 🤝 기여

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

💡 **Tip**: 한국어 검색 품질을 높이려면 사용자 사전을 도메인에 맞게 추가 설정하세요!

