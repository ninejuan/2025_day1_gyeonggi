FROM --platform=linux/amd64 ubuntu:22.04

WORKDIR /app

COPY red /app/red

RUN apt-get update && apt-get install -y ca-certificates tzdata && \
    rm -rf /var/lib/apt/lists/* && \
    chmod +x /app/red

EXPOSE 8080

ENTRYPOINT ["/app/red"]
