#!/bin/bash
calc(){ awk "BEGIN { print $*}"; }

tx_buffer=2

BIN_DIR="./executables/$tx_buffer/target/release/examples/"
CONF_DIR="./configs/"
LOG_DIR="./logs_general/"
payload_size=(8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65500 128000 256000 512000 1024000)
# payload_size=(65500 128000 256000 512000 1024000)
configs=("64KiB.json" "128KiB.json" "256KiB.json" "512KiB.json" "1024KiB.json")
sample_number=5

thr_log_file=$LOG_DIR"thr_sub_msg.txt"
mem_sub_file=$LOG_DIR"mem_sub_msg.txt"
mem_pub_file=$LOG_DIR"mem_pub_msg.txt"


echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo

for ps in ${payload_size[@]}
do
	echo "Testing payload size: $ps"
	for config in ${configs[@]}
	do
		echo "Testing throughput wiht payload size $ps and config $config..."	
		# Run publisher
		sudo taskset -c 1 nice -n -20 $BIN_DIR"z_pub_thr" $ps -c $CONF_DIR$config &

		sleep 1
		
		# Sample number estimation
		test_out=(`$BIN_DIR"z_sub_thr" -n 1000 -s 1 -c $CONF_DIR$config`)
		# test_out=`calc $test_out / 10`
		n=$(echo $test_out | awk '{ print int($1); }' )
		echo "Set sample bucket size: $n"
		
	
		echo "" >> $thr_log_file
		echo $ps $tx_buffer $config >> $thr_log_file
		echo "" >> $mem_sub_file
		echo $ps $tx_buffer $config >> $mem_sub_file
		echo "" >> $mem_pub_file
                echo $ps $tx_buffer $config >> $mem_pub_file
		sudo taskset -c 3 nice -n -20 $BIN_DIR"z_sub_thr" -n $n -s $sample_number -c $CONF_DIR$config >> $thr_log_file &
		
		sleep 0.5
		while (( $(pidof z_sub_thr) -ne ""))
		do
			cat /proc/$(pidof z_sub_thr)/statm >> $mem_sub_file
			cat /proc/$(pidof z_pub_thr)/statm >> $mem_pub_file
			sleep 0.1
		done


		kill $(pidof z_pub_thr)
	done
done

