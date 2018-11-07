#!/bin/bash
USER_MACHINES="cribin17"
CLIENT_MACHINE="cribin17foraslvms1.westeurope.cloudapp.azure.com"
SERVER_MACHINE="cribin17foraslvms6.westeurope.cloudapp.azure.com"
SERVER_MACHINE_IP="10.0.0.8"
SERVER_PORT=11560
SERVER_MAC="$SERVER_MACHINE_IP:$SERVER_PORT"
OBJECT_SIZE=1024
RUN_TIME_SEC=60
CT=2

MW_MACHINE="cribin17foraslvms4.westeurope.cloudapp.azure.com"
MW_MACHINE_IP="10.0.0.4"
MW_PORT=11212
READ_SHARDED=true

CLIENT_OUT_DIR_WRITE=/home/cribin/Documents/ASLLogData/baseline_mw/one_mw/client_log/client_write
CLIENT_OUT_DIR_READ=/home/cribin/Documents/ASLLogData/baseline_mw/one_mw/client_log/client_read

MW_OUT_DIR_WRITE=/home/cribin/Documents/ASLLogData/baseline_mw/one_mw/mw_log/mw_write
MW_OUT_DIR_READ=/home/cribin/Documents/ASLLogData/baseline_mw/one_mw/mw_log/mw_read

DSTAT_OUT_DIR_WRITE=/home/cribin/Documents/ASLLogData/baseline_mw/one_mw/dstat_log/dstat_write
DSTAT_OUT_DIR_READ=/home/cribin/Documents/ASLLogData/baseline_mw/one_mw/dstat_log/dstat_read

scp ./ASL17MainProject.jar $USER_MACHINES@$MW_MACHINE:

echo "memcached -p $SERVER_PORT -t 1"
ssh $USER_MACHINES@$SERVER_MACHINE "memcached -p $SERVER_PORT -t 1" &
pidserver+=($!)

sleep 5

#{8,16,32,64}
for NUM_WORKER in {8,16,32,64}
do
	#write
	SET_GET_RATIO=1:0
	for ROUND in {1,2,3}
	do
		# number of virtual clients{1,8,16,20,24,32}
		for VC in {4,8,16,20,24,32}
		do
			echo "Run middleware"
			MW_COMMAND="java -jar ./ASL17MainProject.jar -l $MW_MACHINE_IP -p $MW_PORT -t $NUM_WORKER -m $SERVER_MAC -s $READ_SHARDED"
			echo $MW_COMMAND
			ssh $USER_MACHINES@$MW_MACHINE $MW_COMMAND &
			pid_mw=($!)

			sleep 5
			
			waiting=()	
			echo "Start Experiment with $VC per machine"
			memtier_cmd="./memtier_benchmark-master/memtier_benchmark --server=$MW_MACHINE_IP --port=$MW_PORT --protocol=memcache_text --clients=$VC --threads=$CT --test-time=$RUN_TIME_SEC --ratio=$SET_GET_RATIO  --data-size=$OBJECT_SIZE --expiry-range=9999-10000 --key-maximum=10000 --hide-histogram &> client_one_mw_write_$VC-$ROUND-$NUM_WORKER.txt"
			dstat_cmd="dstat -c -dnm --noheader --nocolor --tcp --output dstat_write_$VC-$ROUND-$NUM_WORKER.csv 1 $RUN_TIME_SEC" 
			echo $memtier_cmd
			#run dstat on mw machine
			ssh $USER_MACHINES@$MW_MACHINE $dstat_cmd &
			ssh $USER_MACHINES@$CLIENT_MACHINE $memtier_cmd &
			waiting+=($!)


			for pid in "${waiting[@]}"
			do
				echo "waiting"
				wait $pid
			done
			
			echo "kill middleware"
			ssh $USER_MACHINES@$MW_MACHINE "pkill -f 'java -jar'"

			sleep 5

			scp $USER_MACHINES@$MW_MACHINE:./dstat_write_$VC-$ROUND-$NUM_WORKER.csv $DSTAT_OUT_DIR_WRITE
			ssh $USER_MACHINES@$MW_MACHINE "rm ./dstat_write_$VC-$ROUND-$NUM_WORKER.csv"
			
			ssh $USER_MACHINES@$MW_MACHINE "mv ./mw_log.log ./one_mw_write_$VC-$ROUND-$NUM_WORKER.log"
			scp $USER_MACHINES@$MW_MACHINE:./one_mw_write_$VC-$ROUND-$NUM_WORKER.log $MW_OUT_DIR_WRITE
			ssh $USER_MACHINES@$MW_MACHINE "rm ./one_mw_write_$VC-$ROUND-$NUM_WORKER.log"
		
			scp $USER_MACHINES@$CLIENT_MACHINE:./client_one_mw_write_$VC-$ROUND-$NUM_WORKER.txt $CLIENT_OUT_DIR_WRITE
			ssh $USER_MACHINES@$CLIENT_MACHINE "rm ./client_one_mw_write_$VC-$ROUND-$NUM_WORKER.txt"
				
		done
	done
	
	#read
	SET_GET_RATIO=0:1
	for ROUND in {1,2,3}
	do
		# number of virtual clients{1,8,16,20,24,32
		for VC in {4,8,16,20,24,32}
		do
			echo "Run middleware"
			MW_COMMAND="java -jar ./ASL17MainProject.jar -l $MW_MACHINE_IP -p $MW_PORT -t $NUM_WORKER -m $SERVER_MAC -s $READ_SHARDED"
			echo $MW_COMMAND
			ssh $USER_MACHINES@$MW_MACHINE $MW_COMMAND &
			pid_mw=($!)

			sleep 5
			
			waiting=()	
			echo "Start Experiment with $VC per machine"
			memtier_cmd="./memtier_benchmark-master/memtier_benchmark --server=$MW_MACHINE_IP --port=$MW_PORT --protocol=memcache_text --clients=$VC --threads=$CT --test-time=$RUN_TIME_SEC --ratio=$SET_GET_RATIO  --data-size=$OBJECT_SIZE --expiry-range=9999-10000 --key-maximum=10000 --hide-histogram &> client_one_mw_read_$VC-$ROUND-$NUM_WORKER.txt"
			dstat_cmd="dstat -c -dnm --noheader --nocolor --tcp --output dstat_read_$VC-$ROUND-$NUM_WORKER.csv 1 $RUN_TIME_SEC" 
			echo $memtier_cmd
			#run dstat on mw machine
			ssh $USER_MACHINES@$MW_MACHINE $dstat_cmd &
			ssh $USER_MACHINES@$CLIENT_MACHINE $memtier_cmd &
			waiting+=($!)


			for pid in "${waiting[@]}"
			do
				echo "waiting"
				wait $pid
			done
			
			echo "kill middleware"
			ssh $USER_MACHINES@$MW_MACHINE "pkill -f 'java -jar'"

			sleep 5
			
			scp $USER_MACHINES@$MW_MACHINE:./dstat_read_$VC-$ROUND-$NUM_WORKER.csv $DSTAT_OUT_DIR_READ
			ssh $USER_MACHINES@$MW_MACHINE "rm ./dstat_read_$VC-$ROUND-$NUM_WORKER.csv"

			ssh $USER_MACHINES@$MW_MACHINE "mv ./mw_log.log ./one_mw_read_$VC-$ROUND-$NUM_WORKER.log"
			scp $USER_MACHINES@$MW_MACHINE:./one_mw_read_$VC-$ROUND-$NUM_WORKER.log $MW_OUT_DIR_READ
			ssh $USER_MACHINES@$MW_MACHINE "rm ./one_mw_read_$VC-$ROUND-$NUM_WORKER.log"
		
			scp $USER_MACHINES@$CLIENT_MACHINE:./client_one_mw_read_$VC-$ROUND-$NUM_WORKER.txt $CLIENT_OUT_DIR_READ
			ssh $USER_MACHINES@$CLIENT_MACHINE "rm ./client_one_mw_read_$VC-$ROUND-$NUM_WORKER.txt"
				
		done
	done
done

echo "kill server"
pid=$(ssh $USER_MACHINES@$SERVER_MACHINE "pidof memcached 2>&1")
ssh $USER_MACHINES@$SERVER_MACHINE "sudo kill $pid"


