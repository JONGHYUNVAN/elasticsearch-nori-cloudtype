# =============================================================================
# Elasticsearch with Nori Plugin for Korean Language Processing
# CloudType.io 배포용 Elasticsearch Dockerfile
# =============================================================================

FROM docker.elastic.co/elasticsearch/elasticsearch:8.15.0

# Nori 플러그인 설치 (한국어 형태소 분석기)
RUN elasticsearch-plugin install analysis-nori

# 권한 설정 및 디렉토리 생성
USER root
RUN mkdir -p /usr/share/elasticsearch/data && \
    chown -R elasticsearch:elasticsearch /usr/share/elasticsearch/data && \
    chmod 755 /usr/share/elasticsearch/data
USER elasticsearch

# 환경 변수 설정
ENV discovery.type=single-node
ENV xpack.security.enabled=true
ENV ES_JAVA_OPTS="-Xms512m -Xmx512m"
ENV cluster.name="elasticsearch-nori-cluster"
ENV node.name="elasticsearch-nori-node"

# CloudType 최적화 설정
ENV bootstrap.memory_lock=false
ENV http.host=0.0.0.0
ENV transport.host=localhost
ENV http.port=9200
ENV action.destructive_requires_name=false

# 포트 노출
EXPOSE 9200 9300

# 데이터 볼륨
VOLUME ["/usr/share/elasticsearch/data"]

# 헬스체크 (CloudType 환경에 맞게 조정)
HEALTHCHECK --interval=60s --timeout=30s --start-period=120s --retries=10 \
  CMD curl -f http://localhost:9200/_cluster/health || exit 1
