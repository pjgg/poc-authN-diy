FROM golang:1.21.8-alpine3.18 AS builder

ENV GO111MODULE=on
ENV GOPATH /go

RUN apk --no-cache add make

WORKDIR /app
COPY . .

RUN make dependencies build

FROM alpine:3.18 AS runtime

RUN mkdir -p /opt/osin/etc /opt/osin/bin/
USER 1000
COPY --from=builder /app/bin/osin /opt/osin/bin/

VOLUME /opt/osin/etc
EXPOSE 14000/tcp

ENTRYPOINT [ "/opt/osin/bin/osin" ]
CMD [ ]