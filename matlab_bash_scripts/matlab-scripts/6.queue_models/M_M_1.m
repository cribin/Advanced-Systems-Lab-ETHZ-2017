clear();
%Perform M/M/1 analysis according to the formulas in the book
%We model the entire system as one blackbox;

%input to the model:

%average arrival rates(based on thrp_writes exp.), as measured by the clients
lambda = [10112, 13070, 14446, 15901];
%average service rates, as measured by the mw(config. which gives max. thrp.)
mu = [10316, 13383, 14756, 16316];

%output to the model:

%average utilization
Util = lambda ./ mu;

%average service time per worker(=1)
ServiceTime = 1./mu;

%average number of requests in queue
AvgQueueLen = Util.^2./(1-Util);

%average queue waiting time(use little's law)
AvgQueueWait = AvgQueueLen ./ lambda;

%average waiting time
AvgWaitTime = AvgQueueWait + ServiceTime;

%average number of requests in the system
AvgNumRequests = Util./(1-Util);