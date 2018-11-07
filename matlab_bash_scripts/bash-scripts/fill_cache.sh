#!/bin/bash
USER_MACHINES="cribin17"
CLIENT_MACHINES="cribin17foraslvms1.westeurope.cloudapp.azure.com cribin17foraslvms2.westeurope.cloudapp.azure.com cribin17foraslvms3.westeurope.cloudapp.azure.com"
SERVER_MACHINES="cribin17foraslvms6.westeurope.cloudapp.azure.com cribin17foraslvms7.westeurope.cloudapp.azure.com cribin17foraslvms8.westeurope.cloudapp.azure.com"
SERVER_MACHINE_2="cribin17foraslvms7.westeurope.cloudapp.azure.com"
SERVER_MACHINE_3="cribin17foraslvms8.westeurope.cloudapp.azure.com"
SERVER_PORT=11560
SERVER_MAC="10.0.0.8:$SERVER_PORT 10.0.0.5:$SERVER_PORT 10.0.0.6:$SERVER_PORT"
SERVER_MACHINE_IP_1="10.0.0.8" 
SERVER_MACHINE_IP_1="10.0.0.5" 
SERVER_MACHINE_IP_1="10.0.0.6" 
OBJECT_SIZE=1024
RUN_TIME_SEC=400
CT=4

MW_MACHINE_1="cribin17foraslvms4.westeurope.cloudapp.azure.com" 
MW_MACHINE_IP_1="10.0.0.4"
MW_PORT_1=11212
MW_MACHINE_2="cribin17foraslvms5.westeurope.cloudapp.azure.com" 
MW_MACHINE_IP_2="10.0.0.7"
MW_PORT_2=11213
READ_SHARDED=true
NUM_WORKER=64

CLIENT_OUT_DIR_WRITE=/home/cribin/Documents/ASLLogData/tmp_test

pidserver=()
#for serverMachines in $SERVER_MACHINES
#do
#	echo "memcached -p $SERVER_PORT -t 1"
#	ssh $USER_MACHINES@$serverMachines "memcached -p $SERVER_PORT -t 1" &
#	pidserver+=($!)
#done

#sleep 5

#scp ./middleware-cribin.jar $USER_MACHINES@$MW_MACHINE_1:
#scp ./middleware-cribin.jar $USER_MACHINES@$MW_MACHINE_2:

#echo "kill middlewares"
#ssh $USER_MACHINES@$MW_MACHINE_1 "pkill -f 'java -jar'"
#ssh $USER_MACHINES@$MW_MACHINE_2 "pkill -f 'java -jar'"

#sleep 5

SET_GET_RATIO=1:0
for ROUND in {1,}
do
	# number of virtual clients{1,4,16,24,28,32}
	for VC in {32,}
	do
		echo "Run middleware 1"
		MW_COMMAND_1="java -jar ./middleware-cribin.jar -l $MW_MACHINE_IP_1 -p $MW_PORT_1 -t $NUM_WORKER -m $SERVER_MAC -s $READ_SHARDED"
		echo $MW_COMMAND_1
		ssh $USER_MACHINES@$MW_MACHINE_1 $MW_COMMAND_1 &
		pid_mw=($!)
		
		echo "Run middleware 2"
		MW_COMMAND_2="java -jar ./middleware-cribin.jar -l $MW_MACHINE_IP_2 -p $MW_PORT_2 -t $NUM_WORKER -m $SERVER_MAC -s $READ_SHARDED"
		echo $MW_COMMAND_2
		ssh $USER_MACHINES@$MW_MACHINE_2 $MW_COMMAND_2 &
		pid_mw=($!)
		
		sleep 5
				
		waiting=()	
		COUNTER=0
		for client_machine in $CLIENT_MACHINES
		do
			echo "Start Experiment with $VC per machine"
			memtier_cmd="./memtier_benchmark-master/memtier_benchmark --server=$MW_MACHINE_IP_1 --port=$MW_PORT_1 --protocol=memcache_text --clients=$VC --threads=$CT --test-time=$RUN_TIME_SEC --ratio=$SET_GET_RATIO --data-size=$OBJECT_SIZE --expiry-range=9999-10000 --key-maximum=10000 --hide-histogram &> client-$COUNTER_fill_cache_test-1.txt  & ./memtier_benchmark-master/memtier_benchmark --server=$MW_MACHINE_IP_2 --port=$MW_PORT_2 --protocol=memcache_text --clients=$VC --threads=$CT --test-time=$RUN_TIME_SEC --ratio=$SET_GET_RATIO --data-size=$OBJECT_SIZE --expiry-range=9999-10000 --key-maximum=10000 --hide-histogram &> client-$COUNTER_fill_cache_test-2.txt"
			ssh $USER_MACHINES@$client_machine $memtier_cmd &
			waiting+=($!)
			COUNTER=$((COUNTER+1))
		done
				 

		for pid in "${waiting[@]}"
		do
			echo "waiting"
			wait $pid
		done
		
		
		echo "kill middlewares"
		ssh $USER_MACHINES@$MW_MACHINE_1 "pkill -f 'java -jar'"
		ssh $USER_MACHINES@$MW_MACHINE_2 "pkill -f 'java -jar'"
		
		sleep 5
		
		#Get client data
		#COUNTER=0
		#for client_machine in $CLIENT_MACHINES
		#do
		#	scp $USER_MACHINES@$client_machine:./client-$COUNTER_fill_cache_test-1.txt $CLIENT_OUT_DIR_WRITE
		#	scp $USER_MACHINES@$client_machine:./client-$COUNTER_fill_cache_test-2.txt $CLIENT_OUT_DIR_WRITE
		#	ssh $USER_MACHINES@$client_machine "rm ./client-$COUNTER_fill_cache_test-1.txt && rm ./client-$COUNTER_fill_cache_test-2.txt"
		#	COUNTER=$((COUNTER+1))
		#done		

	done
done