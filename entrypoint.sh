#!/bin/sh
set -e

CONFIG=/etc/spyserver/spyserver.config

cfg() { printf '%s =%s\n' "$1" "${2:+ $2}"; } # Always written (defaults given in sample config)
opt() { [ -z "$2" ] || cfg "$1" "$2"; } # Written only when set (commented out in sample config)

{
  cfg bind_host                "${BIND_HOST:-0.0.0.0}"
  cfg bind_port                "${BIND_PORT:-5555-6666}"
  cfg list_in_directory        "${LIST_IN_DIRECTORY:-1}"
  cfg owner_name               "$OWNER_NAME"
  cfg owner_email              "$OWNER_EMAIL"
  cfg antenna_type             "$ANTENNA_TYPE"
  cfg antenna_location         "$ANTENNA_LOCATION"
  cfg general_description      "$GENERAL_DESCRIPTION"
  cfg maximum_clients          "${MAXIMUM_CLIENTS:-1}"
  opt maximum_session_duration "$MAXIMUM_SESSION_DURATION"
  cfg allow_control            "${ALLOW_CONTROL:-1}"
  cfg device_type              "${DEVICE_TYPE:-Auto}"
  cfg device_serial            "${DEVICE_SERIAL:-0}"
  opt device_sample_rate       "$DEVICE_SAMPLE_RATE"
  opt force_8bit               "$FORCE_8BIT"
  opt maximum_bandwidth        "$MAXIMUM_BANDWIDTH"
  cfg fft_fps                  "${FFT_FPS:-15}"
  cfg fft_bin_bits             "${FFT_BIN_BITS:-15}"
  opt initial_frequency        "$INITIAL_FREQUENCY"
  opt minimum_frequency        "$MINIMUM_FREQUENCY"
  opt maximum_frequency        "$MAXIMUM_FREQUENCY"
  opt frequency_correction_ppb "$FREQUENCY_CORRECTION_PPB"
  opt initial_gain             "$INITIAL_GAIN"
  opt aor_antenna              "$AOR_ANTENNA"
  opt aor_auto_gain            "$AOR_AUTO_GAIN"
  opt rtl_sampling_mode        "$RTL_SAMPLING_MODE"
  opt converter_offset         "$CONVERTER_OFFSET"
  opt enable_bias_tee          "$ENABLE_BIAS_TEE"
  cfg input_buffer_size_ms     "${INPUT_BUFFER_SIZE_MS:-10}"
  cfg input_buffer_count       "${INPUT_BUFFER_COUNT:-4}"
  cfg output_buffer_size_ms    "${OUTPUT_BUFFER_SIZE_MS:-50}"
  opt hfp_preamp               "$HFP_PREAMP" # AirspyHF+ only; not in the stock config

  # Extra "key = value" lines, written as-is
  if [ -n "$EXTRA_CONFIG" ]; then
    printf '%s\n' "$EXTRA_CONFIG"
  fi
} > "$CONFIG"

sleep 10

# Line-buffer stdout so logs show up without a TTY
export LD_PRELOAD=/usr/libexec/coreutils/libstdbuf.so
export _STDBUF_O=L
exec /usr/bin/spyserver "$CONFIG"
