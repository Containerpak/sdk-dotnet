FROM ghcr.io/containerpak/base-sdk:main AS fetch

ARG TARGETARCH
ARG DOTNET_VERSION=9.0.318
ARG DOTNET_SHA512_AMD64=e8685293a3512178e0de1bb3c1663e31fdf9d761af705094bf833cc1ff6b9a18c543aa4141f0216503c98039c719585a6d32905b0bbb3279e93b7e7616e047c3
ARG DOTNET_SHA512_ARM64=f9c957867bddea8f82ec0459432ce7ddff8fafc846537b8003eb9f239d9c2e38586031a15954e74691c5a8cf5b3ab125d99bca85c74ca45dc8745071ca81e7ff

RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates curl && \
    case "$TARGETARCH" in \
        amd64) dotnet_arch=x64; checksum="$DOTNET_SHA512_AMD64" ;; \
        arm64) dotnet_arch=arm64; checksum="$DOTNET_SHA512_ARM64" ;; \
        *) echo "unsupported architecture: $TARGETARCH" >&2; exit 1 ;; \
    esac && \
    curl -fsSLo /tmp/dotnet.tar.gz "https://builds.dotnet.microsoft.com/dotnet/Sdk/${DOTNET_VERSION}/dotnet-sdk-${DOTNET_VERSION}-linux-${dotnet_arch}.tar.gz" && \
    echo "${checksum}  /tmp/dotnet.tar.gz" | sha512sum -c - && \
    mkdir -p /opt/dotnet && \
    tar -C /opt/dotnet -xzf /tmp/dotnet.tar.gz && \
    cpak-clean-junk

FROM ghcr.io/containerpak/base-sdk:main

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        libgssapi-krb5-2 \
        libicu-dev \
        libssl-dev \
        libstdc++6 \
        zlib1g && \
    cpak-clean-junk

COPY --from=fetch /opt/dotnet /opt/dotnet

RUN ln -s /opt/dotnet/dotnet /usr/local/bin/dotnet && \
    ln -s /opt/dotnet/dotnet /usr/bin/dotnet

ENV DOTNET_ROOT=/opt/dotnet
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1
ENV DOTNET_NOLOGO=1
ENV PATH=/usr/local/bin:/opt/dotnet:${PATH}
