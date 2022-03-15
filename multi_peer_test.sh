#!/bin/bash
calc(){ awk "BEGIN { print $*}"; }

tx_buffer=$1
pub_peer_num=$2
sub_peer_num=$3

pub_peer_array=($(seq 1 $pub_peer_num))
sub_peer_array=($(seq 1 $sub_peer_num))

BIN_DIR="./executables/$tx_buffer/target/release/examples/"
CONF_DIR="./configs/"
LOG_DIR="./logs_multiple/"
payload_size=(8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65500 128000 256000 512000 1024000)
#payload_size=(8 16 32)
configs=("64KiB.json" "128KiB.json" "256KiB.json" "512KiB.json" "1024KiB.json")
sample_number=50

thr_log_file=$LOG_DIR"thr_sub"
mem_sub_file=$LOG_DIR"mem_sub"
mem_pub_file=$LOG_DIR"mem_pub"


echo 1 > /sys/devices/system/cpu/intel_pstate/no_turbo

for ps in ${payload_size[@]}
do
	echo "Testing payload size: $ps"
	for config in ${configs[@]}
	do
		echo "Testing throughput wiht payload size $ps and config $config..."	
		# Run publisher
		for pub_peer in ${pub_peer_array[@]}
		do
			sudo taskset -c 1 nice -n -10 $BIN_DIR"z_pub_thr" $ps -c $CONF_DIR$config &
			sleep 0.5
		done

		sleep 10
		
		# Sample number estimation
		test_out=(`$BIN_DIR"z_sub_thr" -n 5000 -s 1 -c $CONF_DIR$config`)
		test_out=`calc $test_out / 100`
		n=$(echo $test_out | awk '{ print int($1); }' )
		echo "Set sample bucket size: $n"
		
	
		#echo "" >> $thr_log_file
		#echo $ps $tx_buffer $config >> $thr_log_file
		for sub_peer in ${sub_peer_array[@]}
		do 
			echo "" >> $thr_log_file$sub_peer.txt
                	echo $ps $tx_buffer $config $pub_peer_num $sub_peer_num >> $thr_log_file$sub_peer.txt
			echo "" >> $mem_sub_file$sub_peer.txt
			echo $ps $tx_buffer $config $pub_peer_num $sub_peer_num >> $mem_sub_file$sub_peer.txt
		done

		for pub_peer in ${pub_peer_array[@]}
		do
			echo "" >> $mem_pub_file$pub_peer.txt
                	echo $ps $tx_buffer $config $pub_peer_num $sub_peer_num >> $mem_pub_file$pub_peer.txt
		done

		for sub_peer in ${sub_peer_array[@]}
		do
			sudo taskset -c 3 nice -n -10 $BIN_DIR"z_sub_thr" -n $n -s $sample_number -c $CONF_DIR$config >> $thr_log_file$sub_peer.txt &
			sleep 0.1
		done

		sleep 2
		while :
		do
			active_sub_peer=($(pidof z_sub_thr))
			if test ${#active_sub_peer[@]} -eq 0
			then
				break
			fi

			sub_counter=1
			for sub_peer in ${active_sub_peer[@]}
			do
				cat /proc/$sub_peer/statm >> $mem_sub_file$sub_counter.txt
				sub_counter=`expr $sub_counter + 1 `
			done
			
			active_pub_peer=($(pidof z_pub_thr))
			pub_counter=1
			for pub_peer in ${active_pub_peer[@]}
			do
				cat /proc/$pub_peer/statm >> $mem_pub_file$pub_counter.txt
				pub_counter=`expr $pub_counter + 1 `
			done
		done


		kill -9 $(pidof z_pub_thr)
		sleep 3
	done
done

