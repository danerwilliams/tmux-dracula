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
      # TODO - Darwin/Mac compatability
      ;;

    CYGWIN*|MINGW32*|MSYS*|MINGW*)
      # TODO - windows compatability
      ;;
  esac
}

get_gpu()
{
  gpu=$(get_platform)
  gpu_vram_percent=$(get_tmux_option "@dracula-gpu-vram-percent" false)
  if [[ "$gpu" == NVIDIA ]]; then
    if $gpu_vram_percent; then
      usage=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits | awk '{ used += $0; total +=$2 } END { printf("%d%%\n", used / total * 100 ) }')
    normalize_percent_len $usage
    exit 0
    else
      # to add finer grained info
      used_accuracy=$(get_tmux_option "@dracula-gpu-vram-used-accuracy" "d")
      total_accuracy=$(get_tmux_option "@dracula-gpu-vram-total-accuracy" "d")
      usage=$(nvidia-smi --query-gpu=memory.used,memory.total --format=csv,noheader,nounits | awk "{ used += \$0; total +=\$2 } END { printf(\"%${used_accuracy}GB/%${total_accuracy}GB\n\", used / 1024, total / 1024) }")
    fi
  elif [[ "$gpu" == Advanced ]]; then
    usage="$(
      for card in /sys/class/drm/card?
      do
        use=$(cat "$card"/device/mem_info_vram_used | numfmt --to=iec --suffix=B)
        max=$(cat "$card"/device/mem_info_vram_total | numfmt --to=iec --suffix=B)
        echo "$use/$max"
      done | sed -z -e 's/\n/|/g' -e 's/|$//g'
    )"
  else # "Intel" "Matrox", etc
    usage="unknown"
  fi
  echo $usage
}

main()
{
  # storing the refresh rate in the variable RATE, default is 5
  RATE=$(get_tmux_option "@dracula-refresh-rate" 5)
  gpu_label=$(get_tmux_option "@dracula-gpu-vram-label" "VRAM")
  gpu_usage=$(get_gpu)
  echo "$gpu_label $gpu_usage"
  sleep $RATE
}

# run the main driver
main
