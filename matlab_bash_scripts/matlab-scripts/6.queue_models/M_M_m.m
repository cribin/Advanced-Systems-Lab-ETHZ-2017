clear();
%Perform M/M/m analysis according to the formulas in the book
%%%%%%%%input to the model:

%average arrival rates(based on thrp_writes exp.), as measured by the clients
lambda = [10112, 13070, 14446, 15901];

%number of workers
m = [16,32,64,128];

%average service time per worker(=m)
ServiceTime = [0.0015, 0.0023, 0.0041, 0.006];

%%%%%%%%%%%%%output to the model:

%average service rates per worker, as measured by the mw(config. which gives max. thrp.)
mu = ceil(1./ServiceTime);

%average utilization
Util = lambda ./ (m.*mu);

%prob of zero jobs in the system
tmp = zeros(1,4);
counter = 1;
for t = m
    test = t-1;
    for n = 1:test
        tmp(counter) = tmp(counter) + ((t*Util(counter))^n)/factorial(n);
    end
    counter = counter + 1;
end
p0 = 1./(1 + ((m.*Util).^m)./(factorial(m).*(1-Util)) + tmp);

%prob. of queuing 
eta = ((m.*Util).^m./(factorial(m).*(1-Util))).* p0;

%average number of requests in queue
AvgQueueLen = (Util.* eta) ./ (1-Util);

%average queue waiting time(use little's law)
AvgQueueWait = AvgQueueLen ./ lambda;

%average waiting time
AvgWaitTime = AvgQueueWait + ServiceTime;

AvgResponseTime = 1./mu .*(1 + eta./(m.*(1 - Util)));

%average number of requests in the system
AvgNumRequests = m.*Util + (Util.*eta)./(1-Util);