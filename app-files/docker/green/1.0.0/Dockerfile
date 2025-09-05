FROM alpine:latest

WORKDIR /app

COPY green /app/green

RUN apk add --no-cache ca-certificates tzdata && \
    chmod +x /app/green

EXPOSE 8080

ENTRYPOINT ["/app/green"]
