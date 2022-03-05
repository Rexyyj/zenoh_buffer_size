#!/bin/bash
calc(){ awk "BEGIN { print $*}"; }

BIN_DIR="../zenoh/target/release/examples/"
CONF_DIR="./configs/"
LOG_DIR="./logs/"
payload_size=(8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65500 128000 256000 512000 1024000)
configs=("conf64KiB.json" "conf128KiB.json" "conf256KiB.json" "conf512KiB.json" "conf1MiB.json")
estimation_bias=710000 # Make estimated communication time to [4000,6000] us level
sample_number=100

for ps in ${payload_size[@]}
do
	packet_size=$(($ps + 36))
	echo "Testing payload size: $ps"
	for config in ${configs[@]}
	do
		thr_log_file=$LOG_DIR"thr_sub_msg_"$ps".txt"
		mem_log_file=$LOG_DIR"mem_sub_msg_"$ps".txt"
		echo "Testing throughput wiht payload size $ps and config $config..."	
		# Run publisher
		$BIN_DIR"z_pub_thr" $ps &
		
		# Sample number estimation
		T=$(date +%s%N)
		$BIN_DIR"z_sub_thr" -n 1000 -s 1 -c $CONF_DIR$config
		T=$(($(date +%s%N)-$T))
		T_us=$(($((T/1000))-$estimation_bias))
		n=$(($((1000000/$T_us))*1000))
		if [ $n -le 1000 ]
		then
			kill $(pidof z_pub_thr)
			echo "Bucket number estimation error..."
			exit
		fi
		echo "Estimation communication time: $T_us us"
		echo "Set sample bucket size: $n"
	
	
		echo "" >> $thr_log_file
		echo $ps $config >> $thr_log_file
		echo "" >> $mem_log_file
		echo $ps $config >> $mem_log_file
		$BIN_DIR"z_sub_thr" -n $n -s $sample_number -c $CONF_DIR$config >> $thr_log_file &
		
		sleep 0.5
		while (( $(pidof z_sub_thr) -ne ""))
		do
			cat /proc/$(pidof z_sub_thr)/statm >> $mem_log_file
			sleep 0.1
		done


		kill $(pidof z_pub_thr)
	done
done

#$BIN_DIR"z_pub_thr" 8 &
#echo "passed pub"
#$BIN_DIR"z_sub_thr" -n 1000 -s 1000
#kill $(pidof z_pub_thr)

