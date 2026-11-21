# syntax=docker/dockerfile:1

# Stage 1: static busybox (used for the entrypoint and healthcheck)
FROM busybox:musl AS busybox

# Stage 2: fetch spyserver (and runtime libs) and assemble a minimal rootfs
FROM debian:bookworm-slim AS builder

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates \
      wget \
      librtlsdr0 \
      libairspy0 \
      libairspyhf1 \
      libusb-1.0-0 \
      libudev1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /tmp/ss
RUN wget -q https://airspy.com/downloads/spyserver-linux-x64.tgz \
    && tar xzf spyserver-linux-x64.tgz \
    && rm spyserver-linux-x64.tgz

COPY --from=busybox /bin/busybox /rootfs/bin/busybox

RUN set -eux; \
    LIBDIR=/usr/lib/x86_64-linux-gnu; \
    DEST=/rootfs${LIBDIR}; \
    mkdir -p /rootfs/usr/bin /rootfs/etc/spyserver /rootfs/bin "${DEST}"; \
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
        ln -sf busybox "/rootfs/bin/${applet}"; \
    done

# Stage 3: graft the rootfs onto distroless/cc
FROM gcr.io/distroless/cc-debian12

COPY --from=builder /rootfs/ /
COPY entrypoint.sh /entrypoint.sh

ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:/lib/x86_64-linux-gnu \
    PATH=/usr/bin:/bin

EXPOSE 5555

HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD ["/bin/busybox", "sh", "-c", "/bin/busybox nc -z 127.0.0.1 ${BIND_PORT:-5555}"]

ENTRYPOINT ["/bin/busybox", "sh", "/entrypoint.sh"]
