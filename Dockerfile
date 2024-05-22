FROM docker.io/curlimages/curl:8.8.0

USER root
RUN apk add --no-cache bash jq
USER curl_user

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
