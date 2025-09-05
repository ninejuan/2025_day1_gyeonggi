FROM public.ecr.aws/amazonlinux/amazonlinux:2023

ARG VERSION=1.0.0
WORKDIR /app

COPY red_${VERSION} /app/red
RUN chmod +x /app/red

RUN yum update -y && yum install -y curl && yum clean all

EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=60s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

ENTRYPOINT ["./red"]
CMD ["-p", "8080"]