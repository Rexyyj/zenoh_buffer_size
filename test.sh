#!/bin/bash

test_round=($(seq 1 5))

for num in ${test_round[@]}
do
	./multi_peer_test.sh 4 $num $num
done
