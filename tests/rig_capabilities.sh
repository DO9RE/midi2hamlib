#!/bin/bash
# Get functions, levels and parameter lists from transceiver.
# Parameters:
# type: one of u, l or p.
# var: Array name to store result in.
# model: Rig model. If given, use rigctl with -m parameter.
#   If not, use rigctl with -m2 and host:port variables.
get_func_level_params() {
  local cmd=$1
  local getter_list setter_list
  if [[ -n $3 ]]; then
    getter_list=$(rigctl -m "$3" "${cmd,,}" "?")
    setter_list=$(rigctl -m "$3" "${cmd^^}" "?")
  else
    # Host and port are not define here, but can be used when run from within idi2hamlib.
    # shellcheck disable=SC2154
    getter_list=$(rigctl -m2 -r "$host:$port" "${cmd,,}" "?")
    setter_list=$(rigctl -m2 -r "$host:$port" "${cmd^^}" "?")
  fi
  local -n map=$2
  for getter in ${getter_list}; do
    map["$getter"]="get"
  done
  for setter in ${setter_list}; do
    map["$setter"]+="set"
  done
}

# parameters:
# title: String like "functions", "levels"...
# array: Array from rig_func_level_params
print_func_level_params() {
  local title="$1"
  # Following is correct as long as parameter $2 names an array variable.
  # shellcheck disable=SC2178
  local -n map=$2
  local -a getters setters getset
  for item in "${!map[@]}"; do
    if [[ ${map[$item]} =~ getset ]]; then
      getset+=( "$item" )
    elif [[ ${map[$item]} =~ get ]]; then
      getters+=( "$item" )
    elif [[ ${map[$item]} =~ set ]]; then
      setters+=( "$item" )
    fi    
  done
  if [[ -n ${getset[0]} || -n ${getters[0]} || -n ${setters[0]} ]]; then
    echo "  ${title^}:"
    if [[ -n ${getset[0]} ]]; then
      printf "    get/set: %3s; %s.\n" "${#getset[@]}" "${getset[*]}"
    fi    
    if [[ -n ${getters[0]} ]]; then
      printf "    get    : %3s; %s.\n" "${#getters[@]}" "${getters[*]}"
    fi    
    if [[ -n ${setters[0]} ]]; then
      printf "    set    : %3s; %s.\n" "${#setters[@]}" "${setters[*]}"
    fi    
  else
    echo "  No ${title}."
  fi
}

# Parameters:
# --unhandled: Optional flag that prints all lines from --dump-caps output
#   that have not been handled or ignored on purpose.
# model: Rig model number.
# rigcap_general: Array for overall rig data.
# rigcap_bounds: Array which stores min, max and res values for levels and other values.
# rigcap_features: Array with feature availability information.
get_capabilities() {
  local tmp tmp1 tmp2 tmp3 show_unhandled indentation
  if [[ "$1" == "--unhandled" ]]; then
    show_unhandled=1
    shift 1
  else
    show_unhandled=0
  fi
  # Following is correct as long as parameter $2 names an array variable.
  # shellcheck disable=SC2178
  local -n general=$2 bounds=$3 features=$4
  local -a tmparr tmparr1 tmparr2
  general["rignr"]="$1"
  # Read capabilities line by line, to make sure we also can detect unhandled things.
  # If we wold just grep for specific lines, we wouldn't know what we are missing to evaluate.
  while IFS="" read -r line; do
# Detect indented blocks like extra functions, levels, parameters, memories etc.
# Note that in some hamlib versions, these lines may also contain additional info, not just headings.
    if [[ "$line" =~ ^Extra\ functions: ]]; then
      indentation="functions" 
      # ToDo: process rest of line after colon.
      continue
    elif [[ "$line" =~ ^Extra\ levels: ]]; then
      indentation="levels" 
      # ToDo: process rest of line after colon.
      continue
    elif [[ "$line" =~ ^Extra\ parameters: ]]; then
      indentation="parameters" 
      # ToDo: process rest of line after colon.
      continue
    elif [[ "$line" =~ ^Memories: ]]; then
      indentation="memories" 
      # ToDo: process rest of line after colon.
      continue
    elif [[ "$line" =~ ^TX\ ranges ]]; then
      indentation="txranges" 
      # ToDo: process rest of line after colon.
      continue
    elif [[ "$line" =~ ^RX\ ranges ]]; then
      indentation="rxranges" 
      # ToDo: process rest of line after colon.
      continue
    elif [[ "$line" =~ ^Tuning\ steps ]]; then
      indentation="tuningsteps" 
      # ToDo: process rest of line after colon.
      continue
    elif [[ "$line" =~ ^Filters: ]]; then
      indentation="filters" 
      # ToDo: process rest of line after colon.
      continue
    elif [[ "$line" =~ ^bandwidths: ]]; then
      indentation="bandwidths" 
      # ToDo: process rest of line after colon.
      continue
    elif [[ ! "$line" =~ ^[[:space:]] ]]; then
      indentation=""
    fi
# Ignore indented content for now.
    if [[ -n "$indentation" && "$line" =~ ^[[:space:]] ]]; then
      continue
    fi
# Ignore these lines, at least for now.
    if [[ -z "$line"
      || "$line" =~ ^Overall\ backend\ warnings:
      || "$line" =~ ^Caps\ dump\ for\ model:
      || "$line" =~ ^Hamlib\ version
      || "$line" =~ ^Backend\ version:
      || "$line" =~ ^Backend\ copyright:
      || "$line" =~ ^Backend\ status:
      || "$line" =~ ^Rig\ type:
      || "$line" =~ ^PTT\ type:
      || "$line" =~ ^DCD\ type:
      || "$line" =~ ^Port\ type:
      || "$line" =~ ^Serial\ speed:
      || "$line" =~ ^Write\ delay:
      || "$line" =~ ^Post\ write\ delay:
      || "$line" =~ ^Has\ targetable\ VFO:
      || "$line" =~ ^Has\ transceive:
      || "$line" =~ ^Targetable\ features:
      || "$line" =~ ^Has\ async\ data\ support:
      || "$line" =~ ^Spectrum
      || "$line" =~ ^Has[[:space:]]
    ]]; then
      continue
# Rig model name
    elif [[ "$line" =~ ^Model\ name: ]]; then
      read -r tmp tmp tmp <<<"$line"
      general["model"]="$tmp"
# Vendor name
    elif [[ "$line" =~ ^Mfg\ name: ]]; then
      read -r tmp tmp tmp <<<"$line"
      general["vendor"]="$tmp"
# Anounce
    elif [[ "$line" =~ ^Announce: ]]; then
      read -r tmp tmp <<<"$line"
      general["announce"]="$tmp"
# RIT, XIT, IF-Shift
    elif [[ "$line" =~ ^Max\ (RIT|XIT|IF-SHIFT): ]]; then
      read -r tmp tmp1 tmp <<<"$line"
      tmp1=${tmp1:0:3}
      tmp1=${tmp1/IF-/IFSHIFT} # contains RIT, XIT or IFSHIFT
      read -r tmp2 tmp3 <<<"$(echo "$tmp" | sed -e 's#/+# #g' -e 's/k/*1000/g' -e 's/M/*1000000/g' -e 's/G/*1000000000/g' -e s#Hz#/1#g)"
      bounds[${tmp1}]=minmax
      bounds[${tmp1}:unit]=Hz
      bounds[${tmp1}:min]=$(echo "$tmp2" | bc)
      bounds[${tmp1}:max]=$(echo "$tmp3" | bc)
# Preamp, Attenuator
    elif [[ "$line" =~ ^(Preamp|Attenuator): ]]; then
      read -r tmp1 tmp <<<"${line//dB/}"
      if [[ "$tmp" == "None" ]]; then continue; fi
      tmp1="${tmp1/:/}"
      tmp1="${tmp1^^}"
      bounds[${tmp1}]=values
      bounds[${tmp1}:unit]=dB
      bounds[${tmp1}:values]="$tmp"
# AGC levels
    elif [[ "$line" =~ ^AGC\ levels: ]]; then
      read -r tmp tmp tmp <<<"${line//=/ }"
      tmparr=( $tmp )
      tmp=${#tmparr[@]}
      tmparr1=()
      tmparr2=()
      for ((i=0; i<$tmp; i++)); do
         tmparr1+=( "${tmparr[i]}" )
         ((i++))
         tmparr2+=( "${tmparr[i]}" )
      done
      bounds["AGC"]=mappedvalues
      bounds["AGC:values"]="${tmparr1[*]}"
      bounds["AGC:names"]="${tmparr2[*]}"
# Feature availability
    elif [[ "$line" =~ Can\ (Reset|Scan): ]]; then
      read -r tmp tmp1 tmp2 <<<"${line,,}"
      tmp1="${tmp1/:/}"
      if [[ "$tmp2" == "y" ]]; then
        features[$tmp1]="yes"
      fi
    elif [[ "$line" =~ ^Can\ (get|set|send|recv|stop|wait|decode|ctl)\ [A-Z,a-z]+ ]]; then
      read -r tmp tmp1 tmp <<<"${line,,}"
      tmp="${tmp/ /}"
      tmp="${tmp/:/}"
      read -r tmp2 tmp3 <<<"$tmp"
      if [[ "$tmp2" == "mem/vfo" ]]; then
        tmp2="memvfo"
      fi
      if [[ "$tmp3" == "y" ]]; then
        features[$tmp2]+="$tmp1"
      fi
# Unhandled lines
    elif [[ $show_unhandled -gt 0 ]]; then
      if [[ $show_unhandled -eq 1 ]]; then
        echo "Unhandled capability lines for ${general["vendor"]} ${general["model"]}, ${general["rignr"]}:"
        show_unhandled=2
      fi
      echo "  Unhandled: '$line'"
    fi
  done <<<"$(rigctl -m "$1" --dump-caps)"
  for i in "${!features[@]}"; do
    if [[ "${features[$i]}" =~ setget ]]; then
      features[$i]=getset
    elif [[ "${features[$i]}" =~ recvsend ]]; then
      features[$i]=sendrecv
    fi
  done
}

# Parameters:
# rigcap_general: Array for overall rig data.
# rigcap_bounds: Array which stores min, max and res values for levels and other values.
# rigcap_features: Array with feature availability information.
print_rig_capabilities()
{
  # Following is correct as long as parameter $2 names an array variable.
  # shellcheck disable=SC2178
  local -n general=$1 bounds=$2 features=$3
  echo "${general["vendor"]} ${general["model"]}, ${general["rignr"]}:"
  echo "  Announce: ${general["announce"]}"
  for i in RIT XIT IFSHIFT; do
    echo "  $i: ${bounds[$i:min]} to ${bounds[$i:max]}"
  done
  echo "  AGC: '${bounds["AGC:names"]}' --> '${bounds["AGC:values"]}'"
  local -A ftypes
  for i in "${!features[@]}"; do
    ftypes["${features[$i]}"]+=" $i"
  done
  if [[ "${#features[@]}" -gt "0" ]]; then
    echo "  Features:"
    for i in "${!ftypes[@]}"; do
      echo "    $i:${ftypes["$i"]}"
    done
  fi
}

# Get rig info for dummy transceiver. Used as reference to compare other models against it.
# these variable seem unused, but are passed as variable names to functions.
# shellcheck disable=SC2034
declare -A rigcap_dummy_functions rigcap_dummy_levels rigcap_dummy_parameters rigcap_dummy_general rigcap_dummy_bounds rigcap_dummy_features
get_func_level_params u rigcap_dummy_functions 1
get_func_level_params l rigcap_dummy_levels 1
get_func_level_params p rigcap_dummy_parameters 1
get_capabilities 1 rigcap_dummy_general rigcap_dummy_bounds rigcap_dummy_features
# Output rig info for dummy transceiver.
print_rig_capabilities rigcap_dummy_general rigcap_dummy_bounds rigcap_dummy_features
print_func_level_params "functions" rigcap_dummy_functions
print_func_level_params "Levels" rigcap_dummy_levels
print_func_level_params "parameters" rigcap_dummy_parameters
# Now collect rig info for all other models and compare with dummy.
# Store rig number, manufactorer and model into arrays.
# Complicated, because there is no dedicated field separator.
while IFS="" read -r line; do
  read -r rignr <<<"${line:0:8}"
  read -r vendor <<<"${line:8:23}"
  read -r model <<<"${line:31:24}"
  if [[ -z "$model" ]]; then
    model="Generic"
  fi
  ###echo "$vendor $model, $rignr:"
  # preamp, attenuator
  ###rigctl -m "$rignr" --dump-caps | grep '^\(Preamp\)\|\(Attenuator\)'
  # AGC levels
  ###rigctl -m "$rignr" --dump-caps | grep '^AGC levels'
  ###rigctl -m "$rignr" --dump-caps | awk '{i=index($0,"AGC("); if (i>0) { $0=substr($0,i); i=index($0,")"); print substr($0,1,i) }}'
  ###echo
done <<<"$(rigctl --list | sed -n '1!p' | sed -n /Hamlib/!p)"
