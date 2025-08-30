# =============================================================================
# Elasticsearch with Nori Plugin for Korean Language Processing
# CloudType.io 배포용 Elasticsearch Dockerfile
# =============================================================================

FROM docker.elastic.co/elasticsearch/elasticsearch:8.15.0

# Nori 플러그인 설치 (한국어 형태소 분석기)
RUN elasticsearch-plugin install analysis-nori

# 환경 변수 설정
ENV discovery.type=single-node
ENV xpack.security.enabled=false
ENV ES_JAVA_OPTS="-Xms512m -Xmx512m"
ENV cluster.name="elasticsearch-nori-cluster"
ENV node.name="elasticsearch-nori-node"

# 포트 노출
EXPOSE 9200 9300

# 데이터 볼륨
VOLUME ["/usr/share/elasticsearch/data"]

# 헬스체크
HEALTHCHECK --interval=30s --timeout=10s --retries=5 \
  CMD curl -f http://localhost:9200/_cluster/health || exit 1
