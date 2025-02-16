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
  gpu_power_percent=$(get_tmux_option "@dracula-gpu-power-percent" false)
  if [[ "$gpu" == NVIDIA ]]; then
    if $gpu_power_percent; then
      usage=$(nvidia-smi --query-gpu=power.draw,power.limit --format=csv,noheader,nounits | awk '{ draw += $0; max +=$2 } END { printf("%d%%\n", draw / max * 100) }')
  else
      usage=$(nvidia-smi --query-gpu=power.draw,power.limit --format=csv,noheader,nounits | awk '{ draw += $0; max +=$2 } END { printf("%dW/%dW\n", draw, max) }')
    fi

  elif [[ "$gpu" == apple ]]; then
    usage="$(sudo powermetrics --samplers gpu_power -i500 -n 1 | grep 'GPU Power' | sed 's/GPU Power: \(.*\) \(.*\)/\1\2/g')"
  elif [[ "$gpu" == Advanced ]]; then
    usage=$(
      for card in /sys/class/drm/card?
      do
        echo "$(($(cat "$card"/device/hwmon/hwmon?/power1_average) / 1000 / 1000))/$(($(cat "$card"/device/hwmon/hwmon?/power1_cap_max) / 1000 / 1000))W"
      done | \
      sed -z -e 's/\n/|/g' -e 's/|$//g'
    )
  else # "Intel" "Matrox", etc
    usage="unknown"
  fi
  echo $usage
}

main()
{
  # storing the refresh rate in the variable RATE, default is 5
  RATE=$(get_tmux_option "@dracula-refresh-rate" 5)
  gpu_label=$(get_tmux_option "@dracula-gpu-power-label" "GPU")
  gpu_usage=$(get_gpu)
  echo "$gpu_label $gpu_usage"
  sleep $RATE
}

# run the main driver
main
