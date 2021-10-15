#!/usr/bin/env bash
# setting the locale, some users have issues with different locales, this forces the correct one
export LC_ALL=en_US.UTF-8

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $current_dir/utils.sh

get_bytes()
{
  case $(uname -s) in
    Linux)
      download=$(cat /sys/class/net/$1/statistics/rx_bytes)
      upload=$(cat /sys/class/net/$1/statistics/tx_bytes)
      echo "$download $upload"
      ;;

    Darwin)
      # TODO - Darwin/Mac compatability
      ;;

    CYGWIN*|MINGW32*|MSYS*|MINGW*)
      # TODO - windows compatability
      ;;
  esac
}

get_bandwidth() {
  output_download=""
  output_upload=""
  output_download_unit=""
  output_upload_unit=""

  read initial_download initial_upload < <(get_bytes $2)

  sleep $1

  read final_download final_upload < <(get_bytes $2)

  total_download_bps=$(echo "$final_download $initial_download $1" | awk '{printf "%.0f \n", ($1 - $2) / $3}')
  total_upload_bps=$(echo "$final_upload $initial_upload $1" | awk '{printf "%.0f \n", ($1 - $2) / $3}')

  if [ $total_download_bps -gt 1073741824 ]; then
      output_download=$(echo "$total_download_bps 1024" | awk '{printf "%.2f \n", $1/($2 * $2 * $2)}')
      output_download_unit="gB/s"
  elif [ $total_download_bps -gt 1048576 ]; then
      output_download=$(echo "$total_download_bps 1024" | awk '{printf "%.2f \n", $1/($2 * $2)}')
      output_download_unit="mB/s"
  else
      output_download=$(echo "$total_download_bps 1024" | awk '{printf "%.2f \n", $1/$2}')
      output_download_unit="kB/s"
  fi

  if [ $total_upload_bps -gt 1073741824 ]; then
      output_upload=$(echo "$total_download_bps 1024" | awk '{printf "%.2f \n", $1/($2 * $2 * $2)}')
      output_upload_unit="gB/s"
  elif [ $total_upload_bps -gt 1048576 ]; then
      output_upload=$(echo "$total_upload_bps 1024" | awk '{printf "%.2f \n", $1/($2 * $2)}')
      output_upload_unit="mB/s"
  else
      output_upload=$(echo "$total_upload_bps 1024" | awk '{printf "%.2f \n", $1/$2}')
      output_upload_unit="kB/s"
  fi

  echo "↓ $output_download $output_download_unit • ↑ $output_upload $output_upload_unit"
}

main()
{
  # storing the refresh rate in the variable RATE, default is 5
  RATE=$(get_tmux_option "@dracula-refresh-rate" 5)
  default_network_name=$(ip route | grep default | sed -e "s/^.*dev.//" -e "s/.proto.*//")
  network_name=$(get_tmux_option "@dracula-network-bandwith" "$default_network_name")
  network_bandwidth=$(get_bandwidth "$RATE" "$network_name")
  echo "$network_bandwidth"
}

# run the main driver
main
