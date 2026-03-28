ARG TARGETPLATFORM=linux/amd64
FROM --platform=$TARGETPLATFORM fedora:40


RUN dnf update -y && \
    dnf install --setopt=install_weak_deps=False -y \
    stress-ng gettext-envsubst which && \
    useradd --system --uid 10001 --create-home --home-dir /home/stress stress && \
    dnf clean all

WORKDIR /stress-ng
COPY . .
RUN chmod +x ./run.sh && chown -R 10001:10001 /stress-ng

USER 10001

ENTRYPOINT ["/bin/bash", "run.sh"]
