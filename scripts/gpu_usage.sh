#!/usr/bin/env bash
# setting the locale, some users have issues with different locales, this forces the correct one
export LC_ALL=en_US.UTF-8

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $current_dir/utils.sh

get_platform()
{
  case $(uname -s) in
    Linux)
      # use this option for when your gpu isn't detected
      gpu_label=$(get_tmux_option "@dracula-force-gpu" false)
      if [[ "$gpu_label" != false ]]; then
        echo $gpu_label
      else
        # attempt to detect the gpu
        gpu=$(lspci -v | grep VGA | head -n 1 | awk '{print $5}')
        if [[ -n $gpu ]]; then
          # if a gpu is detected, return it
          echo $gpu
        elif type -a nvidia-smi >> /dev/null; then
          # if no gpu was detected, and nvidia-smi is installed, we'll still try nvidia
          echo "NVIDIA"
        fi
      fi
      ;;

    Darwin)
      # WARNING: for this to work the powermetrics command needs to be run without password
      #   add this to the sudoers file, replacing the username and omitting the quotes.
      #   be mindful of the tabs: "username		ALL = (root) NOPASSWD: /usr/bin/powermetrics"
      echo "apple"
      ;;

    CYGWIN*|MINGW32*|MSYS*|MINGW*)
      # TODO - windows compatability
      ;;
  esac
}

get_gpu()
{
  gpu=$(get_platform)
  if [[ "$gpu" == NVIDIA ]]; then
    usage=$(nvidia-smi --query-gpu=utilization.gpu --format=csv,noheader,nounits | awk '{ sum += $0 } END { printf("%d%%\n", sum / NR) }')
  elif [[ "$gpu" == apple ]]; then
    usage="$(sudo powermetrics --samplers gpu_power -i500 -n 1 | grep 'active residency' | sed 's/[^0-9.%]//g' | sed 's/[%].*$//g')%"
  elif [[ "$gpu" == Advanced ]]; then
    usage="$(cat /sys/class/drm/card?/device/gpu_busy_percent | sed -z -e 's/\n/%|/g' -e 's/|$//g')"
  else # "Intel" "Matrox", etc
    usage="unknown"
  fi
  normalize_percent_len $usage
}

main()
{
  # storing the refresh rate in the variable RATE, default is 5
  RATE=$(get_tmux_option "@dracula-refresh-rate" 5)
  gpu_label=$(get_tmux_option "@dracula-gpu-usage-label" "GPU")
  gpu_usage=$(get_gpu)
  echo "$gpu_label $gpu_usage"
  sleep $RATE
}

# run the main driver
main
