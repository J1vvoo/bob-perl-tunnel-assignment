# 1단계: 빌드 환경 (Maven을 사용하여 WAR 파일 생성)
FROM maven:3.8.4-openjdk-8 AS builder

# 소스 코드 복사
WORKDIR /app
COPY src ./src

# SSL/TLS 인증서 문제 최종 해결: 수동으로 인증서 다운로드 및 Java truststore에 추가
RUN apt-get update && apt-get install -y openssl unzip && \
    openssl s_client -showcerts -connect repo.maven.apache.org:443 < /dev/null | sed -n -e '/BEGIN CERTIFICATE/,/END CERTIFICATE/ p' > /tmp/maven-central.crt && \
    keytool -import -alias maven-central -keystore "$JAVA_HOME/jre/lib/security/cacerts" -file /tmp/maven-central.crt -storepass changeit -noprompt && \
    rm /tmp/maven-central.crt

# pom.xml이 없으므로, 최소한의 pom.xml 생성
RUN echo '<project><modelVersion>4.0.0</modelVersion><groupId>com.example</groupId><artifactId>cmdi-tunnel</artifactId><version>1.0</version><packaging>war</packaging></project>' > pom.xml

# WAR 파일 빌드
# Maven이 기본 디렉토리 구조(src/main/webapp)를 인식하여 자동으로 WAR 파일을 생성합니다.
RUN mvn package

# WAR 파일의 내용을 target/ROOT 디렉토리에 압축 해제
RUN unzip target/cmdi-tunnel-1.0.war -d target/ROOT


# 2단계: 실행 환경 (Tomcat)
FROM tomcat:9-jre8-alpine

# su-exec 설치 및 tomcat_user 사용자 생성
RUN apk add --no-cache su-exec

# 1000번 UID/GID로 사용자 생성 (일반적인 non-root 사용자)
RUN addgroup -g 1000 tomcat_user && \
    adduser -u 1000 -G tomcat_user -s /bin/sh -D tomcat_user

# Alpine Linux에서 기본 제공되는 일부 유틸리티 제거
RUN apk update && \
    apk add --no-cache perl iptables && \
    rm -f /bin/wget /bin/nc /bin/base64 /usr/bin/curl /usr/bin/python* /usr/bin/xxd && \
    rm -rf /var/cache/apk/*

# Tomcat의 기본 webapps를 모두 삭제
RUN rm -rf /usr/local/tomcat/webapps/*

# 빌드된 애플리케이션(압축 해제된 상태)을 Tomcat의 webapps/ROOT 디렉토리로 복사
COPY --from=builder /app/target/ROOT /usr/local/tomcat/webapps/ROOT

# Tomcat 디렉토리 소유권을 tomcat_user에게 부여
RUN chown -R tomcat_user:tomcat_user /usr/local/tomcat

# Blind RCE 결과 파일을 저장할 디렉토리 생성
RUN mkdir /usr/local/tomcat/webapps/ROOT/uploads && \
    chown tomcat_user:tomcat_user /usr/local/tomcat/webapps/ROOT/uploads

# entrypoint 스크립트 복사 및 실행 권한 부여
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# entrypoint 설정 및 Tomcat 실행
ENTRYPOINT ["/entrypoint.sh"]
CMD ["catalina.sh", "run"]
