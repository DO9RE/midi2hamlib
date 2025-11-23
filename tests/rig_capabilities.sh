#!/bin/bash
rigctl --version

# Get functions, levels and parameter lists from transceiver, using U, L or P with '?'.
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
    map["$getter"]+="get"
  done
  for setter in ${setter_list}; do
    map["$setter"]+="set"
  done
}

# parameters:
# title: String like "functions", "levels"...
# array: Array from rig_func_level_params
print_func_level_params() {
  local check
  check=""
  if [[ "$1" == "--check" ]]; then
    check=1
    shift 1
  fi
  local title="$1"
  # Following is correct as long as parameter $2 names an array variable.
  # shellcheck disable=SC2178
  local -n map=$2
  local -a getters setters getset
  local inconsistent
  for item in "${!map[@]}"; do
    if [[ ! ${map[$item]} =~ ^(getget|setset|getsetgetset)$ ]]; then
      inconsistent+=" $item"
    fi
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
  if [[ "$check" == "1" && -n "$inconsistent" ]]; then
    echo "  Inconsistency for:$inconsistent."
  fi  
}

# Get or check VFO list from transceiver, using the V command with '?'.
# Parameters:
# --check: If specified, this function doesn't update the VFO list but only checks
#   consistency against result from V command.
# var: Array name to store result in.
# model: Rig model. If given, use rigctl with -m parameter.
#   If not, use rigctl with -m2 and host:port variables.
get_vfo_list() {
  local checkonly tmp
  checkonly=""
  if [[ "$1" == "--check" ]]; then
    checkonly=1
    shift 1
  fi
  local -n result=$1
  if [[ -n $2 ]]; then
    tmp=$(rigctl -m "$2" V "?")
  else
    # Host and port are not define here, but can be used when run from within idi2hamlib.
    # shellcheck disable=SC2154
    tmp=$(rigctl -m2 -r "$host:$port" V "?")
  fi
  read -r tmp <<<"$tmp" # strip spaces at beginning and end
  if [[ "$checkonly" == "1" ]]; then
    if [[ "$tmp" != "${result[*]}" ]]; then
      echo "  VFO inconsistency: V command reports $tmp."
#   else
#     echo "VFO consistency check OK."
    fi
  else
    result=( $tmp )
  fi
}

# Parameters:
# --unhandled: Optional flag that prints all lines from --dump-caps output
#   that have not been handled or ignored on purpose.
# model: Rig model number.
# rigcap_general: Array for overall rig data.
# rigcap_bounds: Array which stores min, max and res values for levels and other values.
# rigcap_features: Array with feature availability information.
# rigcap_ctcss_range: Array that holds valid CTCSS values.
# rigcap_dcs_range: Array that holds valid DCS values.
# rigcap_modes: Array with valid modes.
# rigcap_vfos: Array containing all available VFOs.
# rigcap_dummy_fvo_ops, rigcap_dummy_scan_ops:
#   Arrays that hold VFO and scan operations.
# rigcap_functions, rigcap_levels, rigcap_parameters:
#   Arrays that store get, set or getset functions, levels and parameters.
# rigcap_warnings: Array holding backend warnings.
get_capabilities() {
  local i tmp tmp1 tmp2 tmp3 tmp4 tmp5 tmp6
  local show_unhandled indentation
  if [[ "$1" == "--unhandled" ]]; then
    show_unhandled=1
    shift 1
  else
    show_unhandled=0
  fi
  # Following is correct as long as parameter $2 names an array variable.
  # shellcheck disable=SC2178
  local -n general=$2 bounds=$3 features=$4 ctcss=$5 dcs=$6 modeslist=$7 vfos=$8 vfo_ops=$9 scan_ops=${10} functions=${11} levels=${12} params=${13} warnings=${14}
  local -a tmparr tmparr1 tmparr2
  local -A rangeconsistency
  general["rignr"]="$1"
  # Read capabilities line by line, to make sure we also can detect unhandled things.
  # If we wold just grep for specific lines, we wouldn't know what we are missing to evaluate.
  while IFS="" read -r line; do
# Detect indented blocks like extra functions, levels, parameters, memories etc.
# Note that in some hamlib versions, these lines may also contain additional info, not just headings.
    if [[ "$line" =~ ^Extra\ functions: ]]; then
      indentation="functions" 
      continue
    elif [[ "$line" =~ ^Extra\ levels: ]]; then
      indentation="levels" 
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
    elif [[ "$line" =~ ^Bandwidths: ]]; then
      indentation="bandwidths" 
      # ToDo: process rest of line after colon.
      continue
    elif [[ ! "$line" =~ ^[[:space:]] ]]; then
      indentation=""
    fi
# Extra functions
    if [[ "$indentation" == "functions" && "$line" =~ ^[[:space:]] ]]; then
      if [[ ! "$line" =~ : ]]; then
        read -r tmp <<<"$line"
        general["functions_get"]+=" $tmp"
        general["functions_set"]+=" $tmp"
        functions[$tmp]+="getset"
      fi
      continue
# Extra levels and parameters
    elif [[ "$indentation" =~ levels|parameters && "$line" =~ ^[[:space:]] ]]; then
      if [[ ! "$line" =~ : ]]; then
        read -r tmp1 <<<"$line" # name
      elif [[ "$line" =~ Type:\ STRING ]]; then
        # We just can get string parameters, not set them.
        # Restriction due to input devices. No keyboard, just numpd or MIDI.
        general["${indentation}_get"]+=" $tmp1"
        if [[ $indentation =~ levels ]] ; then
          levels[$tmp1]+="get"
        else
          params[$tmp1]+="get"
        fi
        bounds[$tmp1]="string"
      elif [[ "$line" =~ Type:\ (CHECKBUTTON|BUTTON) ]]; then
        if [[ -n "${rangeconsistency[$tmp1]}" && "${rangeconsistency[$tmp1]}" != "0:1:1" ]]; then
          echo "${general["vendor"]} ${general["model"]}, ${general["rignr"]}:"
          echo "Range inconsistency for extra ${indentation::-1} CHECKBUTTON $tmp1. Was already stored with '${rangeconsistency[$tmp1]}'." 
          exit 1
        fi
        rangeconsistency[$tmp1]="0:1:1"
        general["${indentation}_get"]+=" $tmp1"
        general["${indentation}_set"]+=" $tmp1"
        if [[ $indentation =~ levels ]] ; then
          levels[$tmp1]+="getset"
        else
          params[$tmp1]+="getset"
        fi
        bounds[$tmp1]="mappedvalues"
        bounds[$tmp1:names]="off on"
        bounds[$tmp1:values]="0 1"
      elif [[ "$line" =~ Range: ]]; then
        tmparr=( $(echo "$line" | sed 's#\(\.\.\|/\)# \1 #g') )
        if [[ "${tmparr[2]}" == ".."
          && "${tmparr[4]}" == "/"
        ]]; then
          tmp2="${tmparr[1]}" # min
          tmp3="${tmparr[3]}" # max
          tmp4="${tmparr[5]}" # resolution
          # Check if another level or parameter with the same name is already registered with a different value range.
          # We expect that value ranges for set and get are the same and that parameters and levels do not have the same name.
          if [[ -n "${rangeconsistency[$tmp1]}" && "${rangeconsistency[$tmp1]}" != "$tmp2:$tmp3:$tmp4" ]]; then
            echo "${general["vendor"]} ${general["model"]}, ${general["rignr"]}:"
            echo "Range inconsistency for extra ${indentation::-1} $tmp1. Is '$tmp2:$tmp3:$tmp4' but was already stored with '${rangeconsistency[$tmp1]}'."
            exit 1
          fi
          rangeconsistency[$tmp1]="$tmp2:$tmp3:$tmp4"
          # Check if min/max is set or if both contain 0.
          if [[ ( ! "${tmp2//./}" =~ ^0+$ ) 
            && ( ! "${tmp3//./}" =~ ^0+$ )
          ]]; then
            bounds[$tmp1]+="minmax"
            bounds[$tmp1:min]="$tmp2"
            bounds[$tmp1:max]="$tmp3"
          fi
          # Check if resolution is not 0.
          if [[ ! "${tmp4//./}" =~ ^0+$ ]]; then
            bounds[$tmp1]+="res"
            bounds[$tmp1:res]="$tmp4"
          fi
          if [[ $indentation =~ levels ]] ; then
            levels[$tmp1]+="getset"
          else
            params[$tmp1]+="getset"
          fi
          general["${indentation}_get"]+=" $tmp1"
          general["${indentation}_set"]+=" $tmp1"
        else
          echo "${general["vendor"]} ${general["model"]}, ${general["rignr"]}:"
          echo "Unexpected 'Range' for extra ${indentation::-1} $tmp1 in '$line'."
          exit 1
        fi
      elif [[ "$line" =~ Values: ]]; then
        tmparr=( )
        tmp=$(echo "$line" | sed -e 's/\([^:"]\) /\1_/g' -e 's/^.*Values: //g' -e 's/\([0-9]\+\)=/tmparr[\1]=/g' -e 's/ /; /g')
        eval "$tmp"
        general["${indentation}_get"]+=" $tmp1"
        general["${indentation}_set"]+=" $tmp1"
        if [[ $indentation =~ levels ]] ; then
          levels[$tmp1]+="getset"
        else
          params[$tmp1]+="getset"
        fi
        bounds[$tmp1]="mappedvalues"
        bounds[$tmp1:names]="${tmparr[*]}"
        bounds[$tmp1:values]="${!tmparr[*]}"
      fi
      continue
# Ignore other indented content for now.
    elif [[ -n "$indentation" && "$line" =~ ^[[:space:]] ]]; then
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
      || "$line" =~ ^Post\ (W|w)rite\ delay:
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
      if [[ -z $tmp ]] ; then
        tmp="Generic"
      fi
      general["model"]="$tmp"
# Vendor name
    elif [[ "$line" =~ ^Mfg\ name: ]]; then
      read -r tmp tmp tmp <<<"$line"
      general["vendor"]="$tmp"
# Warnings
  elif [[ "$line" =~ Warning-- ]]; then
    warnings+=( "${line:10}" )
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
      read -r tmp1 tmp2 <<<"$line"
      if [[ "$tmp" == "None" ]]; then continue; fi
      tmp1="${tmp1//:/}"
      tmp1="${tmp1^^}"
      tmp3="${tmp2//dB/}"
      bounds[${tmp1}]=mappedvalues
      bounds[${tmp1}:names]="$tmp2"
      bounds[${tmp1}:values]="$tmp3"
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
    elif [[ "$line" =~ ^Can\ (Reset|Scan): ]]; then
      read -r tmp tmp1 tmp2 <<<"${line,,}"
      tmp1="${tmp1//:/}"
      if [[ "$tmp2" == "y" ]]; then
        features[$tmp1]="yes"
      fi
    elif [[ "$line" =~ ^Can\ (get|set|send|recv|stop|wait|decode|ctl)\ [A-Z,a-z]+ ]]; then
      read -r tmp tmp1 tmp <<<"${line,,}"
      tmp="${tmp// /}"
      tmp="${tmp//:/}"
      read -r tmp2 tmp3 <<<"$tmp"
      if [[ "$tmp2" == "mem/vfo" ]]; then
        tmp2="memvfo"
      fi
      if [[ "$tmp3" == "y" ]]; then
        features[$tmp2]+="$tmp1"
      fi
# Modes
    elif [[ "$line" =~ ^Mode\ list: ]]; then
      read -r tmp tmp tmp <<<"$line" # tmp now contains the modes.
      modeslist=( $tmp )
# CTCSS
    elif [[ "$line" =~ ^CTCSS: ]]; then
      tmp=$(echo "$line" | sed 's/\(CTCSS: *\)\|\( Hz.*$\)\|\.//g')
      if [[ -n "$tmp" && ! "$tmp" =~ None ]]; then
        ctcss=( $tmp )
      fi
# DCS
    elif [[ "$line" =~ ^DCS: ]]; then
      tmp=$(echo "$line" | sed 's/\(DCS: *\)\|\(,.*$\)\|\.//g')
      if [[ -n "$tmp" && ! "$tmp" =~ None ]]; then
        dcs=( $tmp )
      fi
# VFO list
    elif [[ "$line" =~ ^VFO\ list: ]]; then
      read -r tmp tmp tmp <<<"$line"
      vfos=( $tmp )
# Banks
    elif [[ "$line" =~ Number\ of\ banks: ]]; then
      read -r tmp tmp tmp tmp <<<"$line"
      general["banks"]="$tmp"
# Memory name size
    elif [[ "$line" =~ Memory\ name\ desc\ size: ]]; then
      read -r tmp tmp tmp tmp tmp <<<"$line"
      general["memnamedescsize"]="$tmp"
# Functions
    elif [[ "$line" =~ ^(Get|Set)\ functions: ]]; then
      read -r tmp1 tmp tmp2 <<<"$line"
      tmp1="${tmp1,,}"
      general["functions_$tmp1"]="$tmp2"
      for i in $tmp2 ; do
        functions["$i"]+="$tmp1"
      done
# VFO Ops
    elif [[ "$line" =~ ^VFO\ Ops: ]]; then
      read -r tmp tmp tmp <<<"$line"
      vfo_ops=( $tmp )
# Scan Ops
    elif [[ "$line" =~ ^Scan\ Ops: ]]; then
      read -r tmp tmp tmp <<<"$line"
      scan_ops=( $tmp )
# Levels and Parameters
    elif [[ "$line" =~ ^(Get|Set)\ (level|parameters): ]]; then
      # Read get/set into tmp1, level/parameters into tmp2 and rest into tmp.
      read -r tmp1 tmp2 tmp <<<"$line"  
      tmp1="${tmp1,,}" # lowercase
      tmp2="${tmp2//s:/}"
      tmp2="${tmp2//:/}"
      tmparr=( $(echo "$tmp" | sed 's#\((\|\.\.\|/\|)\)# \1 #g') )
      (( i=0 ))
      while (( i<${#tmparr[@]} )); do
        if [[ "${tmparr[i+1]}" == "("
          && "${tmparr[i+3]}" == ".."
          && "${tmparr[i+5]}" == "/"
          && "${tmparr[i+7]}" == ")"
        ]]; then
          tmp3="${tmparr[i]}" # name
          tmp4="${tmparr[i+2]}" # min
          tmp5="${tmparr[i+4]}" # max
          tmp6="${tmparr[i+6]}" # resolution
          # Check if another level or parameter with the same name is already registered with a different value range.
          # We expect that value ranges for set and get are the same and that parameters and levels do not have the same name.
          if [[ -n "${rangeconsistency[$tmp3]}" && "${rangeconsistency[$tmp3]}" != "$tmp4:$tmp5:$tmp6" ]]; then
            echo "${general["vendor"]} ${general["model"]}, ${general["rignr"]}:"
            echo "Range inconsistency for $tmp1 $tmp2 $tmp3. Is '$tmp4:$tmp5:$tmp6' but was already stored with '${rangeconsistency[$tmp3]}'."
            exit 1
          fi
          rangeconsistency[$tmp3]="$tmp4:$tmp5:$tmp6"
          if [[ ( ! "${tmp4//./}" =~ ^0+$ )
          	&& ( ! "${tmp5//./}" =~ ^0+$ )
          ]]; then
            bounds[$tmp3]+="minmax"
            bounds[$tmp3:min]="$tmp4"
            bounds[$tmp3:max]="$tmp5"
          fi
          # Check if resolution is not 0.
          if [[ ! "${tmp6//./}" =~ ^0+$ ]]; then
            bounds[$tmp3]+="res"
            bounds[$tmp3:res]="$tmp6"
          fi
          case $tmp2 in
            level)
              levels[$tmp3]+="$tmp1"
              ;;
            parameter)
              params[$tmp3]+="$tmp1"
              ;;
            *)
              echo "${general["vendor"]} ${general["model"]}, ${general["rignr"]}:"
              echo "Unexpected keyword '$tmp2' for $tmp1 $tmp2 $tmp3."
              exit 1
              ;;
          esac
          general["${tmp2}s_${tmp1}"]+="$tmp3 "
          (( i+=8 ))
        elif [[ "${tmparr[i+1]}" == "("
          && "${tmparr[i+3]}" == ")"
        ]]; then
          tmp3="${tmparr[i]}" # name
          tmp4="${tmparr[i+2]}" # content
          if [[ -n "${rangeconsistency[$tmp3]}" && "${rangeconsistency[$tmp3]}" != "$tmp4" ]]; then
            echo "${general["vendor"]} ${general["model"]}, ${general["rignr"]}:"
            echo "Range inconsistency for $tmp1 $tmp2 $tmp3. Is '$tmp4' but was already stored with '${rangeconsistency[$tmp3]}'."
            exit 1
          fi
          rangeconsistency[$tmp3]="$tmp4"
          bounds[$tmp3]+="string"
          bounds[$tmp3:strings]="$tmp4"
          case $tmp2 in
            level)
              levels[$tmp3]+="$tmp1"
              ;;
            parameter)
              params[$tmp3]+="$tmp1"
              ;;
            *)
              echo "${general["vendor"]} ${general["model"]}, ${general["rignr"]}:"
              echo "Unexpected keyword '$tmp2' for $tmp1 $tmp2 $tmp3."
              exit 1
              ;;
          esac
          general["${tmp2}s_${tmp1}"]+="$tmp3 "
          (( i+=4 ))
        else
          echo "${general["vendor"]} ${general["model"]}, ${general["rignr"]}:"
          echo "Unexpected $tmp1 $tmp2 capability at entry $(( i/8 + 1 )) in '$tmp'."
          exit 1
        fi
      done
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
  general["functions"]=general["functions_get"]
  for i in ${general["functions_get"]}; do
    if [[ "${functions[$i]}" == "get" ]]; then
      general["functions_getonly"]+="$i "
    fi
  done
  for i in ${general["functions_set"]}; do
    if [[ "${functions[$i]}" == "set" ]]; then
      general["functions"]+=" $i"
      general["functions_setonly"]+="$i "
    fi
  done
  general["levels"]=general["levels_get"]
  for i in ${general["levels_get"]}; do
    if [[ "${levels[$i]}" == "get" ]]; then
      general["levels_getonly"]+="$i "
    fi
  done
  for i in ${general["levels_set"]}; do
    if [[ "${levels[$i]}" == "set" ]]; then
      general["levels"]+=" $i"
      general["levels_setonly"]+="$i "
    fi
  done
  general["parameters"]=general["parameters_get"]
  for i in ${general["parameters_get"]}; do
    if [[ "${params[$i]}" == "get" ]]; then
      general["parameters_getonly"]+="$i "
    fi
  done
  for i in ${general["parameters_set"]}; do
    if [[ "${params[$i]}" == "set" ]]; then
      general["parameters"]+=" $i"
      general["parameters_setonly"]+="$i "
    fi
  done
}

# Parameters:
# --diff: Print noteworthy differences compared to dummy rig.
# rigcap_general: Array for overall rig data.
# rigcap_bounds: Array which stores min, max and res values for levels and other values.
# rigcap_features: Array with feature availability information.
# rigcap_ctcss_range: Array that holds valid CTCSS values.
# rigcap_dcs_range: Array that holds valid DCS values.
# rigcap_modes: Array with valid modes.
# rigcap_vfos: Array containing all available VFOs.
# rigcap_dummy_fvo_ops, rigcap_dummy_scan_ops:
#   Arrays that hold VFO and scan operations.
# rigcap_warnings: Array holding backend warnings.
print_capabilities()
{
  local diff=""
  if [[ $1 == "--diff" ]]; then
  	diff=1
  	shift 1
  fi
  # Following is correct as long as parameter $2 names an array variable.
  # shellcheck disable=SC2178
  local -n general=$1 bounds=$2 features=$3 ctcss=$4 dcs=$5 modeslist=$6 vfos=$7 vfo_ops=$8 scan_ops=$9 warnings=${10}
  if [[ $diff -ge 0 ]]; then
    if [[ ${general["announce"]} != ${rigcap_dummy_general["announce"]} ]]; then
  	  echo "${general["rignr"]} ${general["vendor"]} ${general["model"]}: Announce: ${general["announce"]}"
    fi
    if [[ -n ${general["functions_setonly"]} && -z ${rigcap_dummy_general["functions_setonly"]} ]]; then
  	  echo "${general["rignr"]} ${general["vendor"]} ${general["model"]}: setonly functions ${general["functions_setonly"]}"
    fi
    if [[ -n ${general["functions_getonly"]} && -z ${rigcap_dummy_general["functions_setonly"]} ]]; then
  	  echo "${general["rignr"]} ${general["vendor"]} ${general["model"]}: getonly functions ${general["functions_getonly"]}"
    fi
  	return 0
  fi
  echo "${general["vendor"]} ${general["model"]}, ${general["rignr"]}:"
  echo "  Announce: ${general["announce"]}"
  echo "  Banks: ${general["banks"]}"
  echo "  Mem Name Desc Size: ${general["memnamedescsize"]}"
  for i in RIT XIT IFSHIFT; do
    echo "  $i: ${bounds[$i:min]} to ${bounds[$i:max]}"
  done
  echo "  AGC: '${bounds["AGC:names"]}' --> '${bounds["AGC:values"]}'"
  echo "  PREAMP: '${bounds["PREAMP:names"]}' --> '${bounds["PREAMP:values"]}'"
  echo "  ATTENUATOR: '${bounds["ATTENUATOR:names"]}' --> '${bounds["ATTENUATOR:values"]}'"
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
  if [[ -n "${modeslist[0]}" ]]; then
    echo "  Modes: ${modeslist[*]}"
  fi
  if [[ -n "${ctcss[0]}" ]]; then
    echo "  CTCSS: ${ctcss[*]}"
  fi
  if [[ -n "${dcs[0]}" ]]; then
    echo "  DCS: ${dcs[*]}"
  fi
  if [[ -n "${vfos[0]}" ]]; then
    echo "  VFOs: ${vfos[*]}"
  fi
  if [[ -n "${vfo_ops[0]}" ]]; then
    echo "  VFO Ops: ${vfo_ops[*]}"
  fi
  if [[ -n "${scan_ops[0]}" ]]; then
    echo "  Scan Ops: ${scan_ops[*]}"
  fi
  if [[ ${#warnings[@]} -ne "0" ]]; then
    echo "  Warnings:"
    for i in "${warnings[@]}"; do
      echo "    - $i"
    done
  fi 
}

# Get rig info for dummy transceiver.
# Used as reference to compare other models against it.
# These variable seem unused, but are passed as variable names to functions.
# shellcheck disable=SC2034
declare -a rigcap_dummy_ctcss rigcap_dummy_dcs rigcap_dummy_modes rigcap_dummy_vfos rigcap_dummy_vfo_ops rigcap_dummy_scan_ops rigcap_dummy_warnings
declare -A rigcap_dummy_functions rigcap_dummy_levels rigcap_dummy_parameters rigcap_dummy_general rigcap_dummy_bounds rigcap_dummy_features
# Get functions, levels and parameters from transceiver command help.
# This is for consistency checking against output of --dump-caps
get_func_level_params u rigcap_dummy_functions 1
get_func_level_params l rigcap_dummy_levels 1
get_func_level_params p rigcap_dummy_parameters 1
# Evaluate rig capabilities from --dump-caps
get_capabilities --unhandled 1 rigcap_dummy_general rigcap_dummy_bounds rigcap_dummy_features rigcap_dummy_ctcss rigcap_dummy_dcs rigcap_dummy_modes rigcap_dummy_vfos rigcap_dummy_vfo_ops rigcap_dummy_scan_ops rigcap_dummy_functions rigcap_dummy_levels rigcap_dummy_parameters rigcap_dummy_warnings
# Output rig info for dummy transceiver.
print_capabilities rigcap_dummy_general rigcap_dummy_bounds rigcap_dummy_features rigcap_dummy_ctcss rigcap_dummy_dcs rigcap_dummy_modes rigcap_dummy_vfos rigcap_dummy_vfo_ops rigcap_dummy_scan_ops rigcap_dummy_warnings
print_func_level_params --check "functions" rigcap_dummy_functions
print_func_level_params --check "levels" rigcap_dummy_levels
print_func_level_params --check "parameters" rigcap_dummy_parameters
get_vfo_list --check rigcap_dummy_vfos 1

# Now collect rig info for all other models or if given, 
# just the given model, and compare with dummy.
rigmodel=$1
shift
if [[ "$rigmodel" == "1" ]]; then
  # Was already examined above.
  exit 0
fi
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
  # shellcheck disable=SC2034
  declare -a rigcap_ctcss rigcap_dcs rigcap_modes rigcap_vfos rigcap_vfo_ops rigcap_scan_ops rigcap_warnings
  declare -A rigcap_functions rigcap_levels rigcap_parameters rigcap_general rigcap_bounds rigcap_features
  if [[ -z "$rigmodel" ]]; then
    # We didn't give a rigmodel at startup. So loop over all models nd report progress.
    echo -n "."
  fi
  if [[ -z "$rigmodel" || "$rigmodel" -eq "$rignr" ]]; then
    # Either we didn't specify a ig model at startup or we specified exactly one.
    # In any case, we evaluate rig capabilities to detect undhandled lines.
    get_capabilities --unhandled $rignr rigcap_general rigcap_bounds rigcap_features rigcap_ctcss rigcap_dcs rigcap_modes rigcap_vfos rigcap_vfo_ops rigcap_scan_ops rigcap_functions rigcap_levels rigcap_parameters rigcap_warnings
    if [[ -n "$rigmodel" ]]; then
      # print detailed report for given rig model. 
      # Check for consistency for levels, functions and parameters is not
      # possible. Can only be done if transceiver is in fact available
      # and of course for dummy. 
      print_capabilities rigcap_general rigcap_bounds rigcap_features rigcap_ctcss rigcap_dcs rigcap_modes rigcap_vfos rigcap_vfo_ops rigcap_scan_ops rigcap_warnings
      print_func_level_params "functions" rigcap_functions
      print_func_level_params "levels" rigcap_levels
      print_func_level_params "parameters" rigcap_parameters
    else
      # only print noteworthy differences compared to dummy rig.
      print_capabilities --diff rigcap_general rigcap_bounds rigcap_features rigcap_ctcss rigcap_dcs rigcap_modes rigcap_vfos rigcap_vfo_ops rigcap_scan_ops rigcap_warnings
    fi
  fi
  unset rigcap_ctcss rigcap_dcs rigcap_modes rigcap_vfos rigcap_vfo_ops rigcap_scan_ops rigcap_warnings
  unset rigcap_functions rigcap_levels rigcap_parameters rigcap_general rigcap_bounds rigcap_features
done <<<"$(rigctl --list | sed -n '1!p' | sed -n /Hamlib/!p)"
if [[ -z "$rigmodel" ]]; then
  echo "done."
fi
