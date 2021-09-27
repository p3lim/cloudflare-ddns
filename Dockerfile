FROM docker.io/curlimages/curl:7.79.1

USER root
RUN apk add --no-cache bash jq
USER curl_user

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]
