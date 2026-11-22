#!/bin/sh
set -e

CONFIG=/etc/spyserver/spyserver.config

# Apply a config option only when its variable is set
set_config() {
  if [ -n "$2" ]; then
    sed -i "s/^#*$1 .*/$1 = $2/" "$CONFIG"
  fi
}

set_config bind_host                "$BIND_HOST"
set_config bind_port                "$BIND_PORT"
set_config list_in_directory        "$LIST_IN_DIRECTORY"
set_config owner_name               "$OWNER_NAME"
set_config owner_email              "$OWNER_EMAIL"
set_config antenna_type             "$ANTENNA_TYPE"
set_config antenna_location         "$ANTENNA_LOCATION"
set_config general_description      "$GENERAL_DESCRIPTION"
set_config maximum_clients          "$MAXIMUM_CLIENTS"
set_config maximum_session_duration "$MAXIMUM_SESSION_DURATION"
set_config allow_control            "$ALLOW_CONTROL"
set_config device_type              "$DEVICE_TYPE"
set_config device_serial            "$DEVICE_SERIAL"
set_config device_sample_rate       "$DEVICE_SAMPLE_RATE"
set_config force_8bit               "$FORCE_8BIT"
set_config maximum_bandwidth        "$MAXIMUM_BANDWIDTH"
set_config fft_fps                  "$FFT_FPS"
set_config fft_bin_bits             "$FFT_BIN_BITS"
set_config initial_frequency        "$INITIAL_FREQUENCY"
set_config minimum_frequency        "$MINIMUM_FREQUENCY"
set_config maximum_frequency        "$MAXIMUM_FREQUENCY"
set_config frequency_correction_ppb "$FREQUENCY_CORRECTION_PPB"
set_config initial_gain             "$INITIAL_GAIN"
set_config aor_antenna              "$AOR_ANTENNA"
set_config aor_auto_gain            "$AOR_AUTO_GAIN"
set_config rtl_sampling_mode        "$RTL_SAMPLING_MODE"
set_config converter_offset         "$CONVERTER_OFFSET"
set_config enable_bias_tee          "$ENABLE_BIAS_TEE"
set_config input_buffer_size_ms     "$INPUT_BUFFER_SIZE_MS"
set_config input_buffer_count       "$INPUT_BUFFER_COUNT"
set_config output_buffer_size_ms    "$OUTPUT_BUFFER_SIZE_MS"

# AirspyHF+ only: undocumented; not in the stock config
if [ -n "$HFP_PREAMP" ]; then
  echo "hfp_preamp = $HFP_PREAMP" >> "$CONFIG"
fi

sleep 10

# Line-buffer stdout so logs show up without a TTY
export LD_PRELOAD=/usr/libexec/coreutils/libstdbuf.so
export _STDBUF_O=L
exec /usr/bin/spyserver "$CONFIG"
