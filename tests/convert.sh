echo '144.5 * 1000000 /1' | sed 's/,/./g' | bc
echo -e "144,50\n144.30\n7125000\n435,0" | sed 's/,/./g; s/\(\.[1-9]\+\)0*$/\1/g; s/\.0*$//g'
source ../functions/helper_functions
for i in 145,4 13 3.5 ; do echo "re_format_frequency $i is $(re_format_frequency $i)" ; done
for i in 2450000000 135000 50 145400000 13000000 3500000 ; do echo "format_frequency $i is $(format_frequency $i)" ; done
for i in 3.543210 4.2 10 ; do echo "multiply_and_format $i 1000 is $(multiply_and_format $i 1000)" ; done