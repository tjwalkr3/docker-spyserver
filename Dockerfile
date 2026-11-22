# syntax=docker/dockerfile:1

# Stage 1: static busybox (used for the entrypoint and healthcheck)
FROM busybox:musl AS busybox

# Stage 2: fetch spyserver (and runtime libs) and assemble a minimal rootfs
FROM debian:trixie-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      wget \
      librtlsdr0 \
      libairspy0 \
      libairspyhf1 \
      libusb-1.0-0 \
      libudev1 \
    && rm -rf /var/lib/apt/lists/*

ARG TARGETARCH
ARG TARGETVARIANT
WORKDIR /tmp/ss
RUN set -eux; \
    case "${TARGETARCH}${TARGETVARIANT}" in \
      amd64)        f=spyserver-linux-x64 ;; \
      arm64)        f=spyserver-arm64 ;; \
      arm|armv6|armv7) f=spyserver-arm32 ;; \
      *) echo "unsupported platform: ${TARGETARCH}${TARGETVARIANT}" >&2; exit 1 ;; \
    esac; \
    wget -q "https://airspy.com/downloads/${f}.tgz"; \
    tar xzf "${f}.tgz"; \
    rm "${f}.tgz"

COPY --from=busybox /bin/busybox /rootfs/usr/bin/busybox

RUN set -eux; \
    LIBDIR="$(dirname "$(find /usr/lib -name 'librtlsdr.so.0*' | head -n1)")"; \
    DEST="/rootfs${LIBDIR}"; \
    mkdir -p /rootfs/usr/bin /rootfs/etc/spyserver "${DEST}"; \
    cp /tmp/ss/spyserver        /rootfs/usr/bin/spyserver; \
    cp /tmp/ss/spyserver.config /rootfs/etc/spyserver/spyserver.config; \
    for so in librtlsdr.so.0 libairspy.so.0 libairspyhf.so.1; do \
        bare="$(echo "$so" | sed 's/\.so.*/.so/')"; \
        cp -L "${LIBDIR}/${so}" "${DEST}/${so}"; \
        ln -sf "${so}" "${DEST}/${bare}"; \
    done; \
    cp -L "${LIBDIR}/libusb-1.0.so.0" "${DEST}/libusb-1.0.so.0"; \
    cp -L "${LIBDIR}/libudev.so.1"    "${DEST}/libudev.so.1"; \
    for applet in sh sed sleep nc; do \
        ln -sf busybox "/rootfs/usr/bin/${applet}"; \
    done

# Stage 3: graft the rootfs onto distroless/cc
FROM gcr.io/distroless/cc-debian13

COPY --from=builder /rootfs/ /
COPY entrypoint.sh /entrypoint.sh

ENV PATH=/usr/bin:/bin

EXPOSE 5555

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD ["/usr/bin/busybox", "sh", "-c", "/usr/bin/busybox nc -z 127.0.0.1 ${BIND_PORT:-5555}"]

ENTRYPOINT ["/usr/bin/busybox", "sh", "/entrypoint.sh"]
