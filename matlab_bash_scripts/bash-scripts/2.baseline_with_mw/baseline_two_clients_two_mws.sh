#!/bin/bash
USER_MACHINES="cribin17"
CLIENT_MACHINES="cribin17foraslvms1.westeurope.cloudapp.azure.com cribin17foraslvms2.westeurope.cloudapp.azure.com"
SERVER_MACHINE="cribin17foraslvms6.westeurope.cloudapp.azure.com"
SERVER_MACHINE_IP="10.0.0.8"
SERVER_PORT=11560
SERVER_MAC="$SERVER_MACHINE_IP:$SERVER_PORT"
OBJECT_SIZE=1024
RUN_TIME_SEC=60
CT=1

MW_MACHINE_1="cribin17foraslvms4.westeurope.cloudapp.azure.com" 
MW_MACHINE_IP_1="10.0.0.4"
MW_PORT_1=11212
MW_MACHINE_2="cribin17foraslvms5.westeurope.cloudapp.azure.com" 
MW_MACHINE_IP_2="10.0.0.7"
MW_PORT_2=11213
READ_SHARDED=true

#CLIENT_OUT_DIR_WRITE=/home/cribin/Documents/ASLLogData/baseline_mw/two_clients_2_mws/client_log/client_write
CLIENT_OUT_DIR_READ=/home/cribin/Documents/ASLLogData/baseline_mw/two_clients_2_mws/client_log/client_read

#MW_OUT_DIR_WRITE=/home/cribin/Documents/ASLLogData/baseline_mw/two_clients_2_mws/mw_log/mw_write
MW_OUT_DIR_READ=/home/cribin/Documents/ASLLogData/baseline_mw/two_clients_2_mws/mw_log/mw_read

#DSTAT_OUT_DIR_WRITE=/home/cribin/Documents/ASLLogData/baseline_mw/two_clients_2_mws/dstat_log/dstat_write
DSTAT_OUT_DIR_READ=/home/cribin/Documents/ASLLogData/baseline_mw/two_clients_2_mws/dstat_log/dstat_read

#scp ./ASL17MainProject.jar $USER_MACHINES@$MW_MACHINE_1:
#scp ./ASL17MainProject.jar $USER_MACHINES@$MW_MACHINE_2:

#echo "kill middleware"
#ssh $USER_MACHINES@$MW_MACHINE_1 "pkill -f 'java -jar'"
#echo "kill middleware"
#ssh $USER_MACHINES@$MW_MACHINE_2 "pkill -f 'java -jar'"

#echo "memcached -p $SERVER_PORT -t 1"
#ssh $USER_MACHINES@$SERVER_MACHINE "memcached -p $SERVER_PORT -t 1" &
#pidserver+=($!)

#{8,16,32,64}
for NUM_WORKER in {64,}
do
	#write
	SET_GET_RATIO=0:1
	for ROUND in {1,2,3}
	do
		# number of virtual clients{8,16,20,24,32}
		for VC in {16,20,24,32}
		do
			echo "Run middleware 1"
			MW_COMMAND_1="java -jar ./ASL17MainProject.jar -l $MW_MACHINE_IP_1 -p $MW_PORT_1 -t $NUM_WORKER -m $SERVER_MAC -s $READ_SHARDED"
			echo $MW_COMMAND_1
			ssh $USER_MACHINES@$MW_MACHINE_1 $MW_COMMAND_1 &
			pid_mw=($!)
			
			echo "Run middleware 2"
			MW_COMMAND_2="java -jar ./ASL17MainProject.jar -l $MW_MACHINE_IP_2 -p $MW_PORT_2 -t $NUM_WORKER -m $SERVER_MAC -s $READ_SHARDED"
			echo $MW_COMMAND_2
			ssh $USER_MACHINES@$MW_MACHINE_2 $MW_COMMAND_2 &
			pid_mw=($!)

			sleep 5
			
			echo "Start Experiment with $VC per machine"
			
			dstat_cmd_1="dstat -c -dnm --noheader --nocolor --tcp --output dstat_read_$VC-$ROUND-$NUM_WORKER-1.csv 1 $RUN_TIME_SEC &> /dev/null" 
			dstat_cmd_2="dstat -c -dnm --noheader --nocolor --tcp --output dstat_read_$VC-$ROUND-$NUM_WORKER-2.csv 1 $RUN_TIME_SEC &> /dev/null" 
			echo $memtier_cmd
			#run dstat on mw machine
			
			ssh $USER_MACHINES@$MW_MACHINE_1 $dstat_cmd_1 &
			ssh $USER_MACHINES@$MW_MACHINE_2 $dstat_cmd_2 &
			
			waiting=()	
			COUNTER=0
			for client_machine in $CLIENT_MACHINES
			do
				memtier_cmd="./memtier_benchmark-master/memtier_benchmark --server=$MW_MACHINE_IP_1 --port=$MW_PORT_1 --protocol=memcache_text --clients=$VC --threads=$CT --test-time=$RUN_TIME_SEC --ratio=$SET_GET_RATIO  --data-size=$OBJECT_SIZE --expiry-range=9999-10000 --key-maximum=10000 --hide-histogram &> client_two_mw_read_$VC-$COUNTER-$ROUND-$NUM_WORKER-1.txt & ./memtier_benchmark-master/memtier_benchmark --server=$MW_MACHINE_IP_2 --port=$MW_PORT_2 --protocol=memcache_text --clients=$VC --threads=$CT --test-time=$RUN_TIME_SEC --ratio=$SET_GET_RATIO  --data-size=$OBJECT_SIZE --expiry-range=9999-10000 --key-maximum=10000 --hide-histogram &> client_two_mw_read_$VC-$COUNTER-$ROUND-$NUM_WORKER-2.txt"
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

			sleep 10

			#MW1: Get mw and dstat data
			scp $USER_MACHINES@$MW_MACHINE_1:./dstat_read_$VC-$ROUND-$NUM_WORKER-1.csv $DSTAT_OUT_DIR_READ
			ssh $USER_MACHINES@$MW_MACHINE_1 "rm ./dstat_read_$VC-$ROUND-$NUM_WORKER-1.csv"
			
			ssh $USER_MACHINES@$MW_MACHINE_1 "mv ./mw_log.log ./two_mw_read_$VC-$ROUND-$NUM_WORKER-1.log"
			scp $USER_MACHINES@$MW_MACHINE_1:./two_mw_read_$VC-$ROUND-$NUM_WORKER-1.log $MW_OUT_DIR_READ
			ssh $USER_MACHINES@$MW_MACHINE_1 "rm ./two_mw_read_$VC-$ROUND-$NUM_WORKER-1.log"
			
			#MW2: Get mw and dstat data
			scp $USER_MACHINES@$MW_MACHINE_2:./dstat_read_$VC-$ROUND-$NUM_WORKER-2.csv $DSTAT_OUT_DIR_READ
			ssh $USER_MACHINES@$MW_MACHINE_2 "rm ./dstat_read_$VC-$ROUND-$NUM_WORKER-2.csv"
			
			ssh $USER_MACHINES@$MW_MACHINE_2 "mv ./mw_log.log ./two_mw_read_$VC-$ROUND-$NUM_WORKER-2.log"
			scp $USER_MACHINES@$MW_MACHINE_2:./two_mw_read_$VC-$ROUND-$NUM_WORKER-2.log $MW_OUT_DIR_READ
			ssh $USER_MACHINES@$MW_MACHINE_2 "rm ./two_mw_read_$VC-$ROUND-$NUM_WORKER-2.log"
			
			#Get client data
			COUNTER=0
			for client_machine in $CLIENT_MACHINES
			do
				scp $USER_MACHINES@$client_machine:./client_two_mw_read_$VC-$COUNTER-$ROUND-$NUM_WORKER-1.txt $CLIENT_OUT_DIR_READ
				scp $USER_MACHINES@$client_machine:./client_two_mw_read_$VC-$COUNTER-$ROUND-$NUM_WORKER-2.txt $CLIENT_OUT_DIR_READ
				ssh $USER_MACHINES@$client_machine "rm ./client_two_mw_read_$VC-$COUNTER-$ROUND-$NUM_WORKER-1.txt && rm ./client_two_mw_read_$VC-$COUNTER-$ROUND-$NUM_WORKER-2.txt"
				COUNTER=$((COUNTER+1))
			done
				
		done
	done
done


#echo "kill server"
#pid=$(ssh $USER_MACHINES@$SERVER_MACHINE "pidof memcached 2>&1")
#ssh $USER_MACHINES@$SERVER_MACHINE "sudo kill $pid"
