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

SpyServer needs the USB SDR dongle. The whole USB bus is passed through so the device
survives re-plug and re-enumeration:

```yaml
devices:
  - "/dev/bus/usb:/dev/bus/usb"
```

If the device still isn't detected, replace that block with `privileged: true`.

## Healthcheck

The image ships a `HEALTHCHECK` that runs `nc -z 127.0.0.1 $BIND_PORT` every 30s
(after a 30s start period), so the container goes `unhealthy` if the port stops
accepting connections. It honours `BIND_PORT`.

## Configuration

Each variable maps to a setting in `spyserver.config`. A variable is applied only when you
set it; leave it unset and spyserver keeps its default value. 

| Environment variable | `spyserver.config` key | Description |
| --- | --- | --- |
| `BIND_HOST` | `bind_host` | TCP Listener. |
| `BIND_PORT` | `bind_port` | TCP Listener. |
| `LIST_IN_DIRECTORY` | `list_in_directory` | List Server in Airspy Directory. |
| `OWNER_NAME` | `owner_name` | Owner Name. For example: John Doe L8ZEE. |
| `OWNER_EMAIL` | `owner_email` | Owner email. For example: john@doe.com. |
| `ANTENNA_TYPE` | `antenna_type` | Antenna. For example: Random Wire/Magnetic Loop/Mini-Whip/Inverted V/etc. |
| `ANTENNA_LOCATION` | `antenna_location` | Antenna Location. For example: 48.858332, 2.294560. |
| `GENERAL_DESCRIPTION` | `general_description` | General Description. |
| `MAXIMUM_CLIENTS` | `maximum_clients` | User sessions. |
| `MAXIMUM_SESSION_DURATION` | `maximum_session_duration` | Maximum session duration. In minutes. 0 for no limit. |
| `ALLOW_CONTROL` | `allow_control` | Allow clients to retune and change of gain of the device. |
| `DEVICE_TYPE` | `device_type` | Device Type. Possible Values: AirspyOne (R0, R2, Mini), AirspyHF+, AOR, RTL-SDR, Auto (Scans for the first available device). |
| `DEVICE_SERIAL` | `device_serial` | Device Serial Number as 64bit Hex. A value of 0 will acquire the first available device. |
| `DEVICE_SAMPLE_RATE` | `device_sample_rate` | Device Sample Rate. Comment to use the device's default. |
| `FORCE_8BIT` | `force_8bit` | Force 8bit Compression Mode. |
| `MAXIMUM_BANDWIDTH` | `maximum_bandwidth` | Maximum Bandwidth. Limits the maximum IQ bandwidth the clients can set. |
| `FFT_FPS` | `fft_fps` | FFT Frames Per Second. |
| `FFT_BIN_BITS` | `fft_bin_bits` | FFT Bins. Bins = 2^fft_bin_bits. |
| `INITIAL_FREQUENCY` | `initial_frequency` | Initial Center Frequency. |
| `MINIMUM_FREQUENCY` | `minimum_frequency` | Minimum Tunable Frequency. Comment if using the device default. |
| `MAXIMUM_FREQUENCY` | `maximum_frequency` | Maximum Tunable Frequency. Comment if using the device default. |
| `FREQUENCY_CORRECTION_PPB` | `frequency_correction_ppb` | Frequency Correction in PPB. |
| `INITIAL_GAIN` | `initial_gain` | Initial Gain. |
| `AOR_ANTENNA` | `aor_antenna` | AOR IQ Settings. |
| `AOR_AUTO_GAIN` | `aor_auto_gain` | AOR IQ Settings. |
| `RTL_SAMPLING_MODE` | `rtl_sampling_mode` | RTL-SDR Sampling mode. Quadrature = 0, Direct Sampling I Branch = 1, Direct Sampling Q Branch = 2. |
| `CONVERTER_OFFSET` | `converter_offset` | Converter Offset. Set to -120000000 to enable the SpyVerter offset. |
| `ENABLE_BIAS_TEE` | `enable_bias_tee` | Bias-Tee. For AirspyOne only - Useful for LNA's and SpyVerter. |
| `INPUT_BUFFER_SIZE_MS` | `input_buffer_size_ms` | Input IQ Buffering. |
| `INPUT_BUFFER_COUNT` | `input_buffer_count` | Input IQ Buffering. |
| `OUTPUT_BUFFER_SIZE_MS` | `output_buffer_size_ms` | Output Network Buffer Size (in milliseconds). |
| `HFP_PREAMP` | `hfp_preamp` | AirspyHF+ preamp. Undocumented; not in the stock config. |

*Keys and descriptions are taken from the `spyserver.config` file that ships with SpyServer,
except for `hfp_preamp`.*

## Credits

The `entrypoint.sh` configuration script was inspired by
[f4fhh/spyserver_container](https://github.com/f4fhh/spyserver_container).
