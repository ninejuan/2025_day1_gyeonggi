FROM alpine:latest

WORKDIR /app

COPY red /app/red

RUN apk add --no-cache ca-certificates tzdata && \
    chmod +x /app/red

EXPOSE 8080

ENTRYPOINT ["/app/red"]
