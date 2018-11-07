#!/bin/bash
USER_MACHINES="cribin17"
CLIENT_MACHINES="cribin17foraslvms1.westeurope.cloudapp.azure.com cribin17foraslvms2.westeurope.cloudapp.azure.com cribin17foraslvms3.westeurope.cloudapp.azure.com"
SERVER_MACHINES="cribin17foraslvms6.westeurope.cloudapp.azure.com cribin17foraslvms7.westeurope.cloudapp.azure.com cribin17foraslvms8.westeurope.cloudapp.azure.com"
SERVER_PORT=11560
SERVER_MAC="10.0.0.8:$SERVER_PORT 10.0.0.5:$SERVER_PORT 10.0.0.6:$SERVER_PORT"
OBJECT_SIZE=1024
RUN_TIME_SEC=60
VC=32

MW_MACHINE_1="cribin17foraslvms4.westeurope.cloudapp.azure.com" 
MW_MACHINE_IP_1="10.0.0.4"
MW_PORT_1=11212
MW_MACHINE_2="cribin17foraslvms5.westeurope.cloudapp.azure.com" 
MW_MACHINE_IP_2="10.0.0.7"
MW_PORT_2=11213
READ_SHARDED=false

CLIENT_OUT_DIR_WRITE=/home/cribin/Documents/ASLLogData/2k/client_log/write
CLIENT_OUT_DIR_READ=/home/cribin/Documents/ASLLogData/2k/client_log/read
CLIENT_OUT_DIR_READ_WRITE=/home/cribin/Documents/ASLLogData/2k/client_log/read-write

MW_OUT_DIR_WRITE=/home/cribin/Documents/ASLLogData/2k/mw_log/write
MW_OUT_DIR_READ=/home/cribin/Documents/ASLLogData/2k/mw_log/read
MW_OUT_DIR_READ_WRITE=/home/cribin/Documents/ASLLogData/2k/mw_log/read-write

DSTAT_OUT_DIR_WRITE=/home/cribin/Documents/ASLLogData/2k/dstat_log/write
DSTAT_OUT_DIR_READ=/home/cribin/Documents/ASLLogData/2k/dstat_log/read
DSTAT_OUT_DIR_READ_WRITE=/home/cribin/Documents/ASLLogData/2k/dstat_log/read-write

#scp ./ASL17MainProject.jar $USER_MACHINES@$MW_MACHINE_1:
#scp ./ASL17MainProject.jar $USER_MACHINES@$MW_MACHINE_2:

#echo "kill middleware"
#ssh $USER_MACHINES@$MW_MACHINE_1 "pkill -f 'java -jar'"
#echo "kill middleware"
#ssh $USER_MACHINES@$MW_MACHINE_2 "pkill -f 'java -jar'"

#start all servers
#for serverMachines in $SERVER_MACHINES
#do
#	echo "memcached -p $SERVER_PORT -t 1"
#	ssh $USER_MACHINES@$serverMachines "memcached -p $SERVER_PORT -t 1" &
#	pidserver+=($!)
#done


#{8,16,32,64}

SET_GET_RATIO=0:1
for NUM_SERVERS in {3,}
do

	TEMP_SERVER_MAC=""
	ITER=0
	for cur in $SERVER_MAC
	do
		if [ "$ITER" -eq "$NUM_SERVERS" ]
		then
			break
		fi
		TEMP_SERVER_MAC="$TEMP_SERVER_MAC $cur"
		ITER=$((ITER+1))
	done
	
	for NUM_MW in {2,}
	do
		for NUM_WORKER in {32,}
		do
			for ROUND in {1,2,3}
			do	
				echo "Start Experiment with Servers: $NUM_SERVERS, MWs: $NUM_MW, Worker: $NUM_WORKER, Round: $ROUND"
				if [ "$NUM_MW" -eq "1" ]
				then
					CT=2
				
					echo "Run middleware"
					MW_COMMAND_1="java -jar ./ASL17MainProject.jar -l $MW_MACHINE_IP_1 -p $MW_PORT_1 -t $NUM_WORKER -m $TEMP_SERVER_MAC -s $READ_SHARDED"
					ssh $USER_MACHINES@$MW_MACHINE_1 $MW_COMMAND_1 &
					pid_mw=($!)
					
					sleep 5
					
					dstat_cmd_1="dstat -c -dnm --noheader --nocolor --tcp --output dstat_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-1.csv 1 $RUN_TIME_SEC &> /dev/null"
					ssh $USER_MACHINES@$MW_MACHINE_1 $dstat_cmd_1 &
					
					waiting=()	
					COUNTER=0
					for client_machine in $CLIENT_MACHINES
					do
						memtier_cmd="./memtier_benchmark-master/memtier_benchmark --server=$MW_MACHINE_IP_1 --port=$MW_PORT_1 --protocol=memcache_text --clients=$VC --threads=$CT --test-time=$RUN_TIME_SEC --ratio=$SET_GET_RATIO --data-size=$OBJECT_SIZE --expiry-range=9999-10000 --key-maximum=10000 --hide-histogram &> client_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-$COUNTER-1.txt"
						ssh $USER_MACHINES@$client_machine $memtier_cmd &
						waiting+=($!)
						COUNTER=$((COUNTER+1))
					done


					for pid in "${waiting[@]}"
					do
						echo "waiting"
						wait $pid
					done
					
					echo "kill middleware"
					ssh $USER_MACHINES@$MW_MACHINE_1 "pkill -f 'java -jar'"
					
					sleep 5

					#MW1: Get mw and dstat data
					scp $USER_MACHINES@$MW_MACHINE_1:./dstat_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-1.csv $DSTAT_OUT_DIR_READ_WRITE
					ssh $USER_MACHINES@$MW_MACHINE_1 "rm ./dstat_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-1.csv"

					ssh $USER_MACHINES@$MW_MACHINE_1 "mv ./mw_log.log ./mw_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-1.log"
					scp $USER_MACHINES@$MW_MACHINE_1:./mw_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-1.log $MW_OUT_DIR_READ_WRITE
					ssh $USER_MACHINES@$MW_MACHINE_1 "rm ./mw_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-1.log"

					#Get client data
					COUNTER=0
					for client_machine in $CLIENT_MACHINES
					do
						scp $USER_MACHINES@$client_machine:./client_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-$COUNTER-1.txt $CLIENT_OUT_DIR_READ_WRITE
						ssh $USER_MACHINES@$client_machine "rm ./client_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-$COUNTER-1.txt"
						COUNTER=$((COUNTER+1))
					done
				else
					CT=1
				
					echo "Run middleware 1"
					MW_COMMAND_1="java -jar ./ASL17MainProject.jar -l $MW_MACHINE_IP_1 -p $MW_PORT_1 -t $NUM_WORKER -m $TEMP_SERVER_MAC -s $READ_SHARDED"
					ssh $USER_MACHINES@$MW_MACHINE_1 $MW_COMMAND_1 &
					pid_mw=($!)
					
					echo "Run middleware 2"
					MW_COMMAND_2="java -jar ./ASL17MainProject.jar -l $MW_MACHINE_IP_2 -p $MW_PORT_2 -t $NUM_WORKER -m $TEMP_SERVER_MAC -s $READ_SHARDED"
					ssh $USER_MACHINES@$MW_MACHINE_2 $MW_COMMAND_2 &
					pid_mw=($!)
					
					sleep 5
					
					dstat_cmd_1="dstat -c -dnm --noheader --nocolor --tcp --output dstat_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-1.csv 1 $RUN_TIME_SEC &> /dev/null" 
					dstat_cmd_2="dstat -c -dnm --noheader --nocolor --tcp --output dstat_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-2.csv 1 $RUN_TIME_SEC &> /dev/null" 
					#run dstat on mw machine
					ssh $USER_MACHINES@$MW_MACHINE_1 $dstat_cmd_1 &
					ssh $USER_MACHINES@$MW_MACHINE_2 $dstat_cmd_2 &
					
					waiting=()	
					COUNTER=0
					for client_machine in $CLIENT_MACHINES
					do
						memtier_cmd="./memtier_benchmark-master/memtier_benchmark --server=$MW_MACHINE_IP_1 --port=$MW_PORT_1 --protocol=memcache_text --clients=$VC --threads=$CT --test-time=$RUN_TIME_SEC --ratio=$SET_GET_RATIO --data-size=$OBJECT_SIZE --expiry-range=9999-10000 --key-maximum=10000 --hide-histogram &> client_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-$COUNTER-1.txt & ./memtier_benchmark-master/memtier_benchmark --server=$MW_MACHINE_IP_2 --port=$MW_PORT_2 --protocol=memcache_text --clients=$VC --threads=$CT --test-time=$RUN_TIME_SEC --ratio=$SET_GET_RATIO --data-size=$OBJECT_SIZE --expiry-range=9999-10000 --key-maximum=10000 --hide-histogram &> client_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-$COUNTER-2.txt"
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

					#MW1: Get mw and dstat data
					scp $USER_MACHINES@$MW_MACHINE_1:./dstat_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-1.csv $DSTAT_OUT_DIR_READ_WRITE
					ssh $USER_MACHINES@$MW_MACHINE_1 "rm ./dstat_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-1.csv"

					ssh $USER_MACHINES@$MW_MACHINE_1 "mv ./mw_log.log ./mw_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-1.log"
					scp $USER_MACHINES@$MW_MACHINE_1:./mw_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-1.log $MW_OUT_DIR_READ_WRITE
					ssh $USER_MACHINES@$MW_MACHINE_1 "rm ./mw_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-1.log"

					#MW2: Get mw and dstat data
					scp $USER_MACHINES@$MW_MACHINE_2:./dstat_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-2.csv $DSTAT_OUT_DIR_READ_WRITE
					ssh $USER_MACHINES@$MW_MACHINE_2 "rm ./dstat_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-2.csv"

					ssh $USER_MACHINES@$MW_MACHINE_2 "mv ./mw_log.log ./mw_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-2.log"
					scp $USER_MACHINES@$MW_MACHINE_2:./mw_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-2.log $MW_OUT_DIR_READ_WRITE
					ssh $USER_MACHINES@$MW_MACHINE_2 "rm ./mw_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-2.log"

					#Get client data
					COUNTER=0
					for client_machine in $CLIENT_MACHINES
					do
						scp $USER_MACHINES@$client_machine:./client_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-$COUNTER-1.txt $CLIENT_OUT_DIR_READ_WRITE
						scp $USER_MACHINES@$client_machine:./client_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-$COUNTER-2.txt $CLIENT_OUT_DIR_READ_WRITE
						ssh $USER_MACHINES@$client_machine "rm ./client_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-$COUNTER-1.txt && rm ./client_2k_$NUM_SERVERS-$NUM_MW-$NUM_WORKER-$ROUND-$COUNTER-2.txt"
						COUNTER=$((COUNTER+1))
					done
				fi
			done
		done
	done
done


#echo "kill server"
#pid=$(ssh $USER_MACHINES@$SERVER_MACHINE "pidof memcached 2>&1")
#ssh $USER_MACHINES@$SERVER_MACHINE "sudo kill $pid"
