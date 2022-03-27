#!/bin/bash

#test_round=($(seq 1 5))
test_round=(2 5 10)
for num in ${test_round[@]}
do
	./multi_peer_test.sh 4 $num 1
done

