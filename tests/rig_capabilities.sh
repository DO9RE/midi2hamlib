#!/bin/bash
rigctl --version

source "$(dirname "$0")/../functions/helper_functions"
source "$(dirname "$0")/../functions/rigcaps"

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
  if [[ $diff -gt 0 ]]; then
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
  local -A vtypes vtnames
  for i in "${!bounds[@]}" ; do
    if [[ ! $i =~ : ]] ; then
      (( vtypes[${bounds["$i"]}]++ ))
      vtnames[${bounds["$i"]}]+=" $i"
    fi
  done
  echo "  Value Types:"
  for i in "${!vtypes[@]}" ; do
    echo "    ${i} ${vtypes["$i"]}:${vtnames[$i]}"
  done
  echo
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
internal_get_capabilities --unhandled 1 rigcap_dummy_general rigcap_dummy_bounds rigcap_dummy_features rigcap_dummy_ctcss rigcap_dummy_dcs rigcap_dummy_modes rigcap_dummy_vfos rigcap_dummy_vfo_ops rigcap_dummy_scan_ops rigcap_dummy_functions rigcap_dummy_levels rigcap_dummy_parameters rigcap_dummy_warnings
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
  echo "$vendor $model, $rignr:"
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
    internal_get_capabilities --unhandled $rignr rigcap_general rigcap_bounds rigcap_features rigcap_ctcss rigcap_dcs rigcap_modes rigcap_vfos rigcap_vfo_ops rigcap_scan_ops rigcap_functions rigcap_levels rigcap_parameters rigcap_warnings
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
