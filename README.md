# docker-spyserver

[![Build](https://github.com/tjwalkr3/docker-spyserver/actions/workflows/docker.yml/badge.svg)](https://github.com/tjwalkr3/docker-spyserver/actions/workflows/docker.yml)
[![Docker Hub version](https://img.shields.io/docker/v/tjwalkr3/spyserver?label=docker%20hub)](https://hub.docker.com/r/tjwalkr3/spyserver)
[![Image size](https://img.shields.io/docker/image-size/tjwalkr3/spyserver/latest)](https://hub.docker.com/r/tjwalkr3/spyserver/tags)
[![Docker pulls](https://img.shields.io/docker/pulls/tjwalkr3/spyserver)](https://hub.docker.com/r/tjwalkr3/spyserver)

A minimal, distroless Docker image for [SpyServer](https://airspy.com/directory/), the
Airspy / RTL-SDR network streaming server. The image is built on
`gcr.io/distroless/cc-debian13` with no shell or package manager. It builds for amd64,
arm64, and arm/v7, and supports RTL-SDR, Airspy, and Airspy HF+ devices.

It has a built-in TCP healthcheck and is configured through environment variables.

## Quick start

With Docker Compose:

```bash
docker compose up -d --build
```

With `docker run`:

```bash
docker build -t spyserver:distroless .
docker run -d --name spyserver \
  --restart unless-stopped \
  -p 5555:5555 \
  --device /dev/bus/usb:/dev/bus/usb \
  -e DEVICE_TYPE=Auto \
  spyserver:distroless
```

Point your SDR client (e.g. SDR#, SDR++, CubicSDR) at `sdr://<host>:5555`.

A plain `docker build` targets the host architecture. Use `buildx` to build others:

```bash
docker buildx build --platform linux/amd64,linux/arm64,linux/arm/v7 -t spyserver:distroless .
```

## Device access

SpyServer needs the USB SDR dongle. The whole USB bus is passed through:

```yaml
devices:
  - "/dev/bus/usb:/dev/bus/usb"
```

Plug the SDR in before starting the container. Docker only passes through the USB devices
that are present when the container starts, so if you plug it in later, or unplug and
re-plug it, restart the container (`docker restart spyserver`).

If the device still isn't detected, replace that block with `privileged: true`.

## Healthcheck

The image ships a `HEALTHCHECK` that runs `nc -z 127.0.0.1 $BIND_PORT` every 30s
(after a 30s start period), so the container goes `unhealthy` if the port stops
accepting connections. It honours `BIND_PORT`.

## Configuration

The entrypoint writes `spyserver.config` from scratch on every container start, using
only environment variables. Each variable maps to one setting:

- A key with a **Default** is always written. Leave the variable unset to get the default,
  which matches the `spyserver.config` that ships with SpyServer.
- A key marked **—** is commented out in the stock config. It's written only when you set
  the variable. Otherwise, SpyServer or the device uses its own default (for example, the
  HF+ picks its 768000 sample rate).

| Environment variable | `spyserver.config` key | Default | Description |
| --- | --- | --- | --- |
| `BIND_HOST` | `bind_host` | `0.0.0.0` | TCP Listener. |
| `BIND_PORT` | `bind_port` | `5555-6666` | TCP Listener. |
| `LIST_IN_DIRECTORY` | `list_in_directory` | `1` | List Server in Airspy Directory. |
| `OWNER_NAME` | `owner_name` | *(empty)* | Owner Name. For example: John Doe L8ZEE. |
| `OWNER_EMAIL` | `owner_email` | *(empty)* | Owner email. For example: john@doe.com. |
| `ANTENNA_TYPE` | `antenna_type` | *(empty)* | Antenna. For example: Random Wire/Magnetic Loop/Mini-Whip/Inverted V/etc. |
| `ANTENNA_LOCATION` | `antenna_location` | *(empty)* | Antenna Location. For example: 48.858332, 2.294560. |
| `GENERAL_DESCRIPTION` | `general_description` | *(empty)* | General Description. |
| `MAXIMUM_CLIENTS` | `maximum_clients` | `1` | User sessions. |
| `MAXIMUM_SESSION_DURATION` | `maximum_session_duration` | — | Maximum session duration. In minutes. 0 for no limit. |
| `ALLOW_CONTROL` | `allow_control` | `1` | Allow clients to retune and change of gain of the device. |
| `DEVICE_TYPE` | `device_type` | `Auto` | Device Type. Possible Values: AirspyOne (R0, R2, Mini), AirspyHF+, AOR, RTL-SDR, Auto (Scans for the first available device). |
| `DEVICE_SERIAL` | `device_serial` | `0` | Device Serial Number as 64bit Hex. A value of 0 will acquire the first available device. |
| `DEVICE_SAMPLE_RATE` | `device_sample_rate` | — | Device Sample Rate. Airspy R0, R2: 10000000 or 2500000. Airspy Mini: 6000000 or 3000000. Airspy HF+: 768000. RTL-SDR: 500000 to 3200000. |
| `FORCE_8BIT` | `force_8bit` | — | Force 8bit Compression Mode. |
| `MAXIMUM_BANDWIDTH` | `maximum_bandwidth` | — | Maximum Bandwidth. Limits the maximum IQ bandwidth the clients can set. Recommended: 200000 for WFM, 15000 for narrow band modes. |
| `FFT_FPS` | `fft_fps` | `15` | FFT Frames Per Second. |
| `FFT_BIN_BITS` | `fft_bin_bits` | `15` | FFT Bins. Bins = 2^fft_bin_bits. |
| `INITIAL_FREQUENCY` | `initial_frequency` | — | Initial Center Frequency. |
| `MINIMUM_FREQUENCY` | `minimum_frequency` | — | Minimum Tunable Frequency. |
| `MAXIMUM_FREQUENCY` | `maximum_frequency` | — | Maximum Tunable Frequency. |
| `FREQUENCY_CORRECTION_PPB` | `frequency_correction_ppb` | — | Frequency Correction in PPB. |
| `INITIAL_GAIN` | `initial_gain` | — | Initial Gain. |
| `AOR_ANTENNA` | `aor_antenna` | — | AOR IQ Settings. |
| `AOR_AUTO_GAIN` | `aor_auto_gain` | — | AOR IQ Settings. |
| `RTL_SAMPLING_MODE` | `rtl_sampling_mode` | — | RTL-SDR Sampling mode. Quadrature = 0, Direct Sampling I Branch = 1, Direct Sampling Q Branch = 2. |
| `CONVERTER_OFFSET` | `converter_offset` | — | Converter Offset. Set to -120000000 to enable the SpyVerter offset. |
| `ENABLE_BIAS_TEE` | `enable_bias_tee` | — | Bias-Tee. For AirspyOne only - Useful for LNA's and SpyVerter. |
| `INPUT_BUFFER_SIZE_MS` | `input_buffer_size_ms` | `10` | Input IQ Buffering. |
| `INPUT_BUFFER_COUNT` | `input_buffer_count` | `4` | Input IQ Buffering. |
| `OUTPUT_BUFFER_SIZE_MS` | `output_buffer_size_ms` | `50` | Output Network Buffer Size (in milliseconds). |
| `HFP_PREAMP` | `hfp_preamp` | — | AirspyHF+ preamp. Undocumented; not in the stock config. |

*Keys and descriptions are taken from the `spyserver.config` file that ships with SpyServer,
except for `hfp_preamp`.*

### Other settings

To set a key that isn't in the table, put one or more `key = value` lines in
`EXTRA_CONFIG`. They're appended to the end of the generated config as-is:

```yaml
environment:
  EXTRA_CONFIG: |
    some_key = 1
    another_key = foo
```

Don't use `EXTRA_CONFIG` for a key that has its own variable. The key would appear twice,
and it isn't documented which line SpyServer uses.

## Credits

The `entrypoint.sh` configuration script was inspired by
[f4fhh/spyserver_container](https://github.com/f4fhh/spyserver_container).
