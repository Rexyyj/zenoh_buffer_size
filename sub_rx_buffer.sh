#!/bin/bash

BIN_DIR="../zenoh/target/release/examples/"
CONF_DIR="./configs/"
LOG_DIR="./logs/"
payload_size=(8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65500 128000 256000 512000 1024000)
configs=("conf64KiB.json" "conf128KiB.json" "conf256KiB.json" "conf512KiB.json" "conf1MiB.json")

for ps in ${payload_size[@]}
do
	echo "Testing payload size: $ps"
	for config in ${configs[@]}
	do
		log_file=$LOG_DIR"sub_rx_msg_"$ps".txt"
		$BIN_DIR"z_pub_thr" $ps &
		echo "" >> $log_file
		echo $ps $config >> $log_file
		$BIN_DIR"z_sub_thr" -n 1000 -s 1000 -c $CONF_DIR$config >> $log_file
		kill $(pidof z_pub_thr)
	done
done

#$BIN_DIR"z_pub_thr" 8 &
#echo "passed pub"
#$BIN_DIR"z_sub_thr" -n 1000 -s 1000
#kill $(pidof z_pub_thr)

