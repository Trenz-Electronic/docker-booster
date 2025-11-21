#http.static: TESTDATA=/tmp/docker-booster-http-test
FROM alpine:latest
RUN apk add --no-cache sudo curl
ARG HTTP_TESTDATA
RUN curl -f ${HTTP_TESTDATA}/marker.txt -o /tmp/fetched.txt
RUN cat /tmp/fetched.txt
