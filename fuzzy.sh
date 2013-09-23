#!/usr/bin/bash
# By http://sgaul.de/2013/07/07/fuzzy-search-filter-fur-die-bash/

file_to_be_filtered="$1"
filter_string="$2"
# use in-memory directory /dev/shm/
result_file=/dev/shm/.fuzzyfilterresults

if [ ! -f $file_to_be_filtered ]; then
	echo "fuzzy_filter: '$file_to_be_filtered': No such file"
	exit 1
fi

# empty result file
> $result_file
# replace abc with .*?a.*?b.*?c.*?
# ? triggers non-greedy search in Perl
fuzzy_filter_string=$(echo "$filter_string" | sed 's/./&.*?/g')
echo -e "Filter string: $fuzzy_filter_string"
while read line; do
	# get matches only (grep -o) with Perl syntax (-P)
	# replace them by their string length (awk)
	# return the smallest number (sort | head -1)
	match_length=$(echo "$line" | grep -oP "$fuzzy_filter_string" | awk '{ print length }' | sort | head -1)
	# check if variable is a number and not 0
	if [ "$match_length" -eq "$match_length" ] 2>/dev/null && [ "$match_length" -gt "0" ]; then
		# write number, space and original content into result file
		line="$match_length $line"
		echo $line >> $result_file
	fi
done < "$file_to_be_filtered"

# sort by facing order number
sort $result_file -o $result_file
# cut order number and first space, output the rest
cut -d " " -f 2- $result_file | grep -P "$fuzzy_filter_string" --color

rm -f $result_file
