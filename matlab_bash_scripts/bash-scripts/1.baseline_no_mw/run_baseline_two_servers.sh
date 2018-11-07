#!/bin/bash
USER_MACHINES="cribin17"
CLIENT_MACHINES="cribin17foraslvms1.westeurope.cloudapp.azure.com"
SERVER_MACHINES="cribin17foraslvms6.westeurope.cloudapp.azure.com cribin17foraslvms7.westeurope.cloudapp.azure.com"
SERVER_MACHINE_IP_1="10.0.0.8"
SERVER_MACHINE_IP_2="10.0.0.5"
SERVER_PORT=11560
OBJECT_SIZE=1024
RUN_TIME_SEC=70
CT=1


pidserver=()
for server_machine in $SERVER_MACHINES
do
	echo "memcached -p $SERVER_PORT -t 1"
	ssh $USER_MACHINES@$server_machine "memcached -p $SERVER_PORT -t 1" &
	pidserver+=($!)
done

sleep 10

SET_GET_RATIO=1:0
for ROUND in {1,2,3}
do
	# number of virtual clients{1,4,16,24,28,32}
	for VC in {1,8,16,20,24,32}
	do
		waiting=()
		COUNTER=0
		for client_machine in $CLIENT_MACHINES
		do
			echo "Start Experiment with $VC per machine"
			memtier_cmd="./memtier_benchmark-master/memtier_benchmark --server=$SERVER_MACHINE_IP_1 --port=$SERVER_PORT --protocol=memcache_text --clients=$VC --threads=$CT --test-time=$RUN_TIME_SEC --ratio=$SET_GET_RATIO  --data-size=$OBJECT_SIZE --expiry-range=9999-10000 --key-maximum=10000 --hide-histogram &> baseline_write_$VC-$COUNTER-$ROUND-1.txt & ./memtier_benchmark-master/memtier_benchmark --server=$SERVER_MACHINE_IP_2 --port=$SERVER_PORT --protocol=memcache_text --clients=$VC --threads=$CT --test-time=$RUN_TIME_SEC --ratio=$SET_GET_RATIO  --data-size=$OBJECT_SIZE --expiry-range=9999-10000 --key-maximum=10000 --hide-histogram &> baseline_write_$VC-$COUNTER-$ROUND-2.txt"
			echo $memtier_cmd
			ssh $USER_MACHINES@$client_machine $memtier_cmd &
			waiting+=($!)
			COUNTER=$((COUNTER+1))
		done 

		for pid in "${waiting[@]}"
		do
			echo "waiting"
			wait $pid
		done

		COUNTER=0
		for client_machine in $CLIENT_MACHINES
		do
			scp $USER_MACHINES@$client_machine:./baseline_write_$VC-$COUNTER-$ROUND-1.txt /home/cribin/Documents/ASLLogData/baseline/two_servers
			ssh $USER_MACHINES@$client_machine "rm ./baseline_write_$VC-$COUNTER-$ROUND-1.txt"
			scp $USER_MACHINES@$client_machine:./baseline_write_$VC-$COUNTER-$ROUND-2.txt /home/cribin/Documents/ASLLogData/baseline/two_servers
			ssh $USER_MACHINES@$client_machine "rm ./baseline_write_$VC-$COUNTER-$ROUND-2.txt"
			COUNTER=$((COUNTER+1))
		done 
	done
done

SET_GET_RATIO=0:1
for ROUND in {1,2,3}
do
	# number of virtual clients{1,8,16,20,24,32}
	for VC in {1,8,16,20,24,32}
	do
		waiting=()
		COUNTER=0
		for client_machine in $CLIENT_MACHINES
		do
			echo "Start Experiment with $VC per machine"
			memtier_cmd="./memtier_benchmark-master/memtier_benchmark --server=$SERVER_MACHINE_IP_1 --port=$SERVER_PORT --protocol=memcache_text --clients=$VC --threads=$CT --test-time=$RUN_TIME_SEC --ratio=$SET_GET_RATIO  --data-size=$OBJECT_SIZE --expiry-range=9999-10000 --key-maximum=10000 --hide-histogram &> baseline_read_$VC-$COUNTER-$ROUND-1.txt & ./memtier_benchmark-master/memtier_benchmark --server=$SERVER_MACHINE_IP_2 --port=$SERVER_PORT --protocol=memcache_text --clients=$VC --threads=$CT --test-time=$RUN_TIME_SEC --ratio=$SET_GET_RATIO  --data-size=$OBJECT_SIZE --expiry-range=9999-10000 --key-maximum=10000 --hide-histogram &> baseline_read_$VC-$COUNTER-$ROUND-2.txt"
			ssh $USER_MACHINES@$client_machine $memtier_cmd &
			waiting+=($!)
			COUNTER=$((COUNTER+1))
		done 

		for pid in "${waiting[@]}"
		do
			echo "waiting"
			wait $pid
		done

		COUNTER=0
		for client_machine in $CLIENT_MACHINES
		do
			scp $USER_MACHINES@$client_machine:./baseline_read_$VC-$COUNTER-$ROUND-1.txt /home/cribin/Documents/ASLLogData/baseline/two_servers
			ssh $USER_MACHINES@$client_machine "rm ./baseline_read_$VC-$COUNTER-$ROUND-1.txt"
			scp $USER_MACHINES@$client_machine:./baseline_read_$VC-$COUNTER-$ROUND-2.txt /home/cribin/Documents/ASLLogData/baseline/two_servers
			ssh $USER_MACHINES@$client_machine "rm ./baseline_read_$VC-$COUNTER-$ROUND-2.txt"
			COUNTER=$((COUNTER+1))
		done 
	done
done

for server_machine in $SERVER_MACHINES
do
	pid=$(ssh $USER_MACHINES@$server_machine "pidof memcached 2>&1")
	ssh $USER_MACHINES@$server_machine "sudo kill $pid"
done
