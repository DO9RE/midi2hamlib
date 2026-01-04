echo '144.5 * 1000000 /1' | sed 's/,/./g' | bc
echo -e "144,50\\n144.30\\n7125000\\n435,0" | sed 's/,/./g; s/\(\.[1-9]\+\)0*$/\1/g; s/\.0*$//g'
# shellcheck disable=SC1091
source ../functions/helper_functions
for i in 145,4 13 3.5 ; do echo "re_format_frequency $i is $(re_format_frequency $i)" ; done
for i in 2450000000 135000 50 145400000 13000000 3500000 ; do echo "format_frequency $i is $(format_frequency $i)" ; done
for i in 3.543210 4.2 10 ; do echo "multiply_and_format $i 1000 is $(multiply_and_format $i 1000)" ; done
echo "Testing validate_midi_value with 'abs' mode:"
if ! validate_midi_value -1 abs 10 result; then
  echo "-1 abs 10 is invalid, OK."
else
  echo "-1 abs 10 is valid, ERROR."
fi
if validate_midi_value 0 abs 10 result; then
  echo "0 abs 10 is valid, result $result, OK."
else
  echo "0 abs 10 is invalid, ERROR."
fi
if validate_midi_value 5 abs 10 result; then
  echo "5 abs 10 is valid, result $result, OK."
else
  echo "5 abs 10 is invalid, ERROR."
fi
if ! validate_midi_value 10 abs 10 result; then
  echo "10 abs 10 is invalid, OK."
else
  echo "5 abs 10 is valid, ERROR."
fi
echo "Testing validate_midi_value with 'mod' mode with range 3:"
for i in 0 1 2 3 4 5; do
  if validate_midi_value $i mod 3 result; then
    echo "$i mod 3 is $result."
  else
    echo "ERROR for $i mod 3."
  fi  
done
echo "Testing validate_midi_value with 'zone' mode with range 32:"
unset result # make sure variable is newly created to avoid side-effects from before.
for i in 0 1 2 3 4 5 6 7 8 9 10 118 119 120 121 122 123 124 125 126 127; do
  if validate_midi_value $i zone 32 result; then
    echo "$i mapped to $result."
  fi
done
echo -n "Testing unify_midi: "
for i in 126 127 0 1 2 62 63 64 65 66; do
  echo -n "$(unify_rel_midi $i) "
done
echo
echo "Testing strip_trailing_zeros and strip_trailing_zeros_float:"
for i in 1.0 1.00 +1,123000 -1.0100 100 ; do
  echo "$i --> $(strip_trailing_zeros $i), $(strip_trailing_zeros_float $i)"
done
