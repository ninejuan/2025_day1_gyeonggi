FROM --platform=linux/amd64 ubuntu:22.04

WORKDIR /app

COPY green /app/green

RUN apt-get update && apt-get install -y ca-certificates tzdata && \
    rm -rf /var/lib/apt/lists/* && \
    chmod +x /app/green

EXPOSE 8080

ENTRYPOINT ["/app/green"]
