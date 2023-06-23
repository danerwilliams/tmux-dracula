#!/usr/bin/env bash
# setting the locale, some users have issues with different locales, this forces the correct one
export LC_ALL=en_US.UTF-8

current_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source $current_dir/utils.sh

main()
{

# # Main Structure
# - Color Pallette
# - Get Tmux Option Variables
#   - General
#   - For Left Icon
#   - For Window
#   - For Plugins
# - Left Icon Area
# - Window Area
# - Right Plugins Area


# Dracula Color Pallette{
  white='#f8f8f2'
  gray='#44475a'
  dark_gray='#282a36'
  light_purple='#bd93f9'
  dark_purple='#6272a4'
  cyan='#8be9fd'
  green='#50fa7b'
  orange='#ffb86c'
  red='#ff5555'
  pink='#ff79c6'
  yellow='#f1fa8c'
# }


# Get Tmux Option Variables {

  # general
  show_powerline=$(get_tmux_option "@dracula-show-powerline" false)
  show_left_sep=$(get_tmux_option "@dracula-show-left-sep" )
  show_right_sep=$(get_tmux_option "@dracula-show-right-sep" )
  show_border_contrast=$(get_tmux_option "@dracula-border-contrast" false)
  status_bg=$(get_tmux_option "@dracula-status-bg" gray)

  # left icon area
  left_icon=$(get_tmux_option "@dracula-show-left-icon" smiley)
  left_icon_bg=$(get_tmux_option "@dracula-left-icon-bg" green)
  left_icon_fg=$(get_tmux_option "@dracula-left-icon-fg" dark_gray)
  left_icon_prefix_bg=$(get_tmux_option "@dracula-left-icon-prefix-on-bg" red)
  left_icon_prefix_fg=$(get_tmux_option "@dracula-left-icon-prefix-on-fg" white)
  left_icon_padding_left=$(get_tmux_option "@dracula-left-icon-padding-left" 1)
  left_icon_padding_right=$(get_tmux_option "@dracula-left-icon-padding-right" 1)
  left_icon_margin_right=$(get_tmux_option "@dracula-left-icon-margin-right" 1)

  # window area
  show_flags=$(get_tmux_option "@dracula-show-flags" false)
  IFS=' ' read -r -a plugins <<< $(get_tmux_option "@dracula-plugins" "battery network weather")

  # right plugins area
  # plugins general
  show_refresh=$(get_tmux_option "@dracula-refresh-rate" 5)
  show_empty_plugins=$(get_tmux_option "@dracula-show-empty-plugins" true)

  # terraform
  terraform_label=$(get_tmux_option "@dracula-terraform-label" "")

  # weather
  show_fahrenheit=$(get_tmux_option "@dracula-show-fahrenheit" true)
  show_location=$(get_tmux_option "@dracula-show-location" true)
  fixed_location=$(get_tmux_option "@dracula-fixed-location")

  # time
  show_military=$(get_tmux_option "@dracula-military-time" false)
  show_timezone=$(get_tmux_option "@dracula-show-timezone" true)
  show_day_month=$(get_tmux_option "@dracula-day-month" false)
  time_format=$(get_tmux_option "@dracula-time-format" "")

  # kubernetes-context
  show_kubernetes_context_label=$(get_tmux_option "@dracula-kubernetes-context-label" "")
# }


# General Settings {

  # sets refresh interval to every 5 seconds
  tmux set-option -g status-interval $show_refresh

  # Handle powerline option
  if $show_powerline; then
    left_sep="$show_left_sep"
    right_sep="$show_right_sep"
  else  # if disable powerline mark, equal to '', unify the logic of string.
    left_sep=''
    right_sep=''
    window_left_sep=''
    window_right_sep=''
  fi

  # set length
  tmux set-option -g status-left-length 100
  tmux set-option -g status-right-length 100

  # pane border styling
  if $show_border_contrast; then
    tmux set-option -g pane-active-border-style "fg=${light_purple}"
  else
    tmux set-option -g pane-active-border-style "fg=${dark_purple}"
  fi
  tmux set-option -g pane-border-style "fg=${gray}"

  # message styling
  tmux set-option -g message-style "bg=${gray},fg=${white}"

  # status bar
  tmux set-option -g status-style "bg=${!status_bg},fg=${white}"
# }


# Left Icon Area {
  # Handle left icon configuration
  case $left_icon in
    smiley)
      left_icon_content="☺";;
    session)
      left_icon_content="#S";;
    window)
      left_icon_content="#W";;
    *)
      left_icon_content=$left_icon;;
  esac

  # Handle left icon padding
  icon_pd_l=""
  if [ "$left_icon_padding_left" -gt "0" ]; then
    icon_pd_l="$(printf '%*s' $left_icon_padding_left)"
  fi
  icon_pd_r=""
  if [ "$left_icon_padding_right" -gt "0" ]; then
    icon_pd_r="$(printf '%*s' $left_icon_padding_right)"
  fi

  # Handle left icon margin
  icon_mg_r=""
  if [ "$left_icon_margin_right" -gt "0" ]; then
    icon_mg_r="$(printf '%*s' $left_icon_margin_right)"
  fi

  # Left icon, with prefix status
  tmux set-option -g status-left "\
#{?client_prefix,#[fg=${!left_icon_prefix_fg}],#[fg=${!left_icon_fg}]}\
#{?client_prefix,#[bg=${!left_icon_prefix_bg}],#[bg=${!left_icon_bg}]}\
${icon_pd_l}${left_icon_content}${icon_pd_r}\
#{?client_prefix,#[fg=${!left_icon_prefix_bg}],#[fg=${!left_icon_bg}]}\
#[bg=${!status_bg}]\
${left_sep}\
${icon_mg_r}"
  powerbg=${!status_bg}

# }


# Window Area {

  # Handle window flags
  case $show_flags in
    false)
      flags=""
      current_flags="";;
    true)
      flags="#{?window_flags,#[fg=${dark_purple}]#{window_flags},}"
      current_flags="#{?window_flags,#[fg=${light_purple}]#{window_flags},}"
  esac

  # Window option
  if $show_powerline; then
    tmux set-window-option -g window-status-current-format "#[fg=${gray},bg=${dark_purple}]${left_sep}#[fg=${white},bg=${dark_purple}] #I #W${current_flags} #[fg=${dark_purple},bg=${gray}]${left_sep}"
  else
    tmux set-window-option -g window-status-current-format "#[fg=${white},bg=${dark_purple}] #I #W${current_flags} "
  fi

  tmux set-window-option -g window-status-format "#[fg=${white}]#[bg=${gray}] #I #W${flags}"

  tmux set-window-option -g window-status-activity-style "bold"
  tmux set-window-option -g window-status-bell-style "bold"

# }

# Right Plugins Area{
  tmux set-option -g status-right ""

  # Set timezone unless hidden by configuration
  case $show_timezone in
    false)
      timezone="";;
    true)
      timezone="#(date +%Z)";;
  esac

  # set the prefix + t time format
  if $show_military; then
    tmux set-option -g clock-mode-style 24
  else
    tmux set-option -g clock-mode-style 12
  fi


  for plugin in "${plugins[@]}"; do

    if case $plugin in custom:*) true;; *) false;; esac; then
      script=${plugin#"custom:"}
      if [[ -x "${current_dir}/${script}" ]]; then
        IFS=' ' read -r -a colors <<<$(get_tmux_option "@dracula-custom-plugin-colors" "cyan dark_gray")
        script="#($current_dir/${script})"
      else
        colors[0]="red"
        colors[1]="dark_gray"
        script="${script} not found!"
      fi

    elif [ $plugin = "cwd" ]; then
      IFS=' ' read -r -a colors  <<< $(get_tmux_option "@dracula-cwd-colors" "dark_gray white")
      tmux set-option -g status-right-length 250
      script="#($current_dir/cwd.sh)"

    elif [ $plugin = "git" ]; then
      IFS=' ' read -r -a colors  <<< $(get_tmux_option "@dracula-git-colors" "green dark_gray")
      tmux set-option -g status-right-length 250
      script="#($current_dir/git.sh)"

    elif [ $plugin = "battery" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@dracula-battery-colors" "pink dark_gray")
      script="#($current_dir/battery.sh)"

    elif [ $plugin = "gpu-usage" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@dracula-gpu-usage-colors" "pink dark_gray")
      script="#($current_dir/gpu_usage.sh)"

    elif [ $plugin = "gpu-ram-usage" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@dracula-gpu-ram-usage-colors" "cyan dark_gray")
      script="#($current_dir/gpu_ram_info.sh)"

    elif [ $plugin = "gpu-power-draw" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@dracula-gpu-power-draw-colors" "green dark_gray")
      script="#($current_dir/gpu_power.sh)"

    elif [ $plugin = "cpu-usage" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@dracula-cpu-usage-colors" "orange dark_gray")
      script="#($current_dir/cpu_info.sh)"

    elif [ $plugin = "ram-usage" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@dracula-ram-usage-colors" "cyan dark_gray")
      script="#($current_dir/ram_info.sh)"

    elif [ $plugin = "network" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@dracula-network-colors" "cyan dark_gray")
      script="#($current_dir/network.sh)"

    elif [ $plugin = "network-bandwidth" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@dracula-network-bandwidth-colors" "cyan dark_gray")
      tmux set-option -g status-right-length 250
      script="#($current_dir/network_bandwidth.sh)"

    elif [ $plugin = "network-ping" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@dracula-network-ping-colors" "cyan dark_gray")
      script="#($current_dir/network_ping.sh)"

    elif [ $plugin = "network-vpn" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@dracula-network-vpn-colors" "cyan dark_gray")
      script="#($current_dir/network_vpn.sh)"

    elif [ $plugin = "attached-clients" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@dracula-attached-clients-colors" "cyan dark_gray")
      script="#($current_dir/attached_clients.sh)"

    elif [ $plugin = "spotify-tui" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@dracula-spotify-tui-colors" "green dark_gray")
      script="#($current_dir/spotify-tui.sh)"

    elif [ $plugin = "kubernetes-context" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@dracula-kubernetes-context-colors" "cyan dark_gray")
      script="#($current_dir/kubernetes_context.sh $show_kubernetes_context_label)"

    elif [ $plugin = "terraform" ]; then
      IFS=' ' read -r -a colors <<<$(get_tmux_option "@dracula-terraform-colors" "light_purple dark_gray")
      script="#($current_dir/terraform.sh $terraform_label)"

    elif [ $plugin = "weather" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@dracula-weather-colors" "orange dark_gray")
      script="#($current_dir/weather_wrapper.sh $show_fahrenheit $show_location $fixed_location)"

    elif [ $plugin = "time" ]; then
      IFS=' ' read -r -a colors <<< $(get_tmux_option "@dracula-time-colors" "dark_purple white")
      if [ -n "$time_format" ]; then
        script=${time_format}
      else
        if $show_day_month && $show_military ; then # military time and dd/mm
          script="%a %d/%m %R ${timezone} "
        elif $show_military; then # only military time
          script="%a %m/%d %R ${timezone} "
        elif $show_day_month; then # only dd/mm
          script="%a %d/%m %I:%M %p ${timezone} "
        else
          script="%a %m/%d %I:%M %p ${timezone} "
        fi
      fi

    else
      continue
    fi

    if $show_powerline; then
      if $show_empty_plugins; then
        tmux set-option -ga status-right "#[fg=${!colors[0]},bg=${powerbg},nobold,nounderscore,noitalics]${right_sep}#[fg=${!colors[1]},bg=${!colors[0]}] $script "
      else
        tmux set-option -ga status-right "#{?#{==:$script,},,#[fg=${!colors[0]},nobold,nounderscore,noitalics]${right_sep}#[fg=${!colors[1]},bg=${!colors[0]}] $script }"
      fi
      powerbg=${!colors[0]}
    else
      if $show_empty_plugins; then
        tmux set-option -ga status-right "#[fg=${!colors[1]},bg=${!colors[0]}] $script "
      else
        tmux set-option -ga status-right "#{?#{==:$script,},,#[fg=${!colors[1]},bg=${!colors[0]}] $script }"
      fi
    fi
  done
}

# run main function
main
