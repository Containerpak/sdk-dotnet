FROM ghcr.io/containerpak/base-sdk:main AS fetch

ARG TARGETARCH
ARG DOTNET_VERSION=9.0.317
ARG DOTNET_SHA512_AMD64=145bf69dcb88c4b905feb531cfdd7894a75fc875d2a030e958a13d1fb1131521c8cebd8a8a6e0fbd1a433ebae9cde86356b6adad07b1ad81efb92b36ff8a3333
ARG DOTNET_SHA512_ARM64=fdf30fe705c91304d890115e955f738055f8c0885ea9891e7df1153321120fa2c38b6ae4dd132f871cb8facc0d1fabbd2b25ddd53d0a5b4293aa85d296e3b98d

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
