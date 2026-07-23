# Define the builder image
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:8.0 AS builder

ARG OPENRA_RELEASE_VERSION
ENV OPENRA_RELEASE_VERSION=${OPENRA_RELEASE_VERSION}
ARG OPENRA_RELEASE_TYPE=${OPENRA_RELEASE_TYPE:-"release"}
ARG OPENRA_RELEASE=https://github.com/OpenRA/OpenRA/releases/download/${OPENRA_RELEASE_TYPE}-${OPENRA_RELEASE_VERSION}/OpenRA-${OPENRA_RELEASE_TYPE}-${OPENRA_RELEASE_VERSION}-source.tar.bz2

RUN apt-get update && \
    apt-get -y upgrade && \
    apt-get install -y --no-install-recommends \
            ca-certificates \
            curl \
            unzip \
            libfreetype6 \
            git \
            bzip2 \
            make \
            patch \
            liblua5.1-0 \
            libsdl2-2.0-0 \
            libopenal1 \
            wget
RUN useradd -d /home/openra -m -s /sbin/nologin openra && \
    mkdir -p /home/openra/source /home/openra/lib/openra && \
    curl -L $OPENRA_RELEASE | tar xj -C /home/openra/source && \
    cd /home/openra/source && make all TARGETPLATFORM=unix-generic && \
    mv /home/openra/source/* /home/openra/lib/openra

# Define the final image
FROM --platform=$BUILDPLATFORM mcr.microsoft.com/dotnet/sdk:8.0

COPY --from=builder /home/openra/lib/openra /home/openra/lib/openra
RUN useradd -d /home/openra -m -s /sbin/nologin openra && \
    mkdir -p /home/openra/.openra && \
    chown -R openra:openra /home/openra

WORKDIR /home/openra/lib/openra

USER openra

EXPOSE 1234
VOLUME ["/home/openra/.openra"]

CMD ["/home/openra/lib/openra/launch-dedicated.sh"]

LABEL org.opencontainers.image.title="OpenRA dedicated server" \
      org.opencontainers.image.description="Image to run a server instance for OpenRA" \
      org.opencontainers.image.url="https://github.com/traxo-xx/openra-docker" \
      org.opencontainers.image.documentation="https://github.com/traxo-xx/openra-docker#readme" \
      org.opencontainers.image.version="$OPENRA_RELEASE_VERSION" \
      org.opencontainers.image.licenses="GPL-3.0" \
      org.opencontainers.image.authors="Dennis Kruyt, Hannes Stöven"
