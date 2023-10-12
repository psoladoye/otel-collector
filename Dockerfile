FROM --platform=$BUILDPLATFORM golang:1.20-alpine as build
ARG  OTEL_VERSION=0.87.0
WORKDIR /build

COPY build-config.yaml .
RUN go install go.opentelemetry.io/collector/cmd/builder@v${OTEL_VERSION}
RUN builder --config=build-config.yaml

FROM --platform=$BUILDPLATFORM alpine:3.16 as certs
RUN apk --update add ca-certificates

FROM scratch

ARG USER_UID=10001
USER ${USER_UID}

COPY --from=certs /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=build /build/bin/otelcol-custom /
COPY otel-config.yaml /etc/otelcol-custom/config.yaml

EXPOSE 4317/tcp 55678/tcp  55679/tcp

ENTRYPOINT ["/otelcol-custom"]

CMD ["--config", "/etc/otelcol-custom/config.yaml"]
