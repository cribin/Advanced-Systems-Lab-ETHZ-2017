clear();
%Network of queues analysis
%we perform mean value anlysis for all devices present in the system
%Devices in the system: - ClientNet: 2 delay centers to and from middleware.
%                       - MemcacheNet: 2 delay centers to and from middleware
%                       - MemcacheServer: 1 M/M/1 device, represent the queue of the memcache server
%                       - MW: 1 M/M/m deivce, as each worker shares one queue(we combine both MW instances to one model)
% We look at the case with 64 total clients and take data from the baseline for server related data 
%We take data from section 3 for the other devices

%Init params
maxClients = 64;%we iterate from 0 to 64 clients
numWorkers = 4;
numDevices = 4;
numMWs = 2;
serviceTimeWrite = zeros(numDevices, numMWs, numWorkers);
serviceTimeRead = zeros(numDevices, numMWs, numWorkers);
visitCount = serviceTimeWrite;
workers = [8, 16, 32, 64];
%Compute parameter for memcached server

toSec = 1000;

%perform M/M/1 analysis to get server service time:
lambda = 24955;%baseline with 96 clients
MeanResp = 3.8472/toSec;%baseline with 96 clients
MeanReq = lambda * MeanResp;
utilization = MeanReq/(MeanReq + 1);
mu = lambda / utilization;
serviceTimeWrite(3,:,:) = 1/mu;

lambda = 11184;%baseline with 96 clients
MeanResp = 4.3097/toSec;%baseline with 96 clients
MeanReq = lambda * MeanResp;
utilization = MeanReq/(MeanReq + 1);
mu = lambda / utilization;
serviceTimeRead(3,:,:) = 1/mu;

%compute memcacheNet service time=memcache total timemeasured on client) - memcache service time(see above):
serverTime_1MW_64VC_write =  [0.9557, 1.0611, 1.2004, 1.2811]/toSec;
serverTime_1MW_64VC_read = [0.9936, 1.0293, 1.2044, 1.2701]/toSec;
serverTime_2MW_64VC_write =([0.8951, 0.9702, 1.0764, 1.1034]/toSec);
serverTime_2MW_64VC_read = ([0.9226, 1.5821, 2.1781, 1.7951]/toSec);


serviceTimeWrite(2,2,:) = (serverTime_2MW_64VC_write - serviceTimeWrite(3,1,1)) * 0.5;%serviceTimeWrite(2,1,:);
serviceTimeRead(2,2,:) = (serverTime_2MW_64VC_read - serviceTimeRead(3,1,1)) * 0.5;%serviceTimeRead(2,1,:);
serviceTimeWrite(2,1,:) = serviceTimeWrite(2,2,:) ;%(serverTime_1MW_64VC_write - serviceTimeWrite(3,1,1)) * 0.5;
serviceTimeRead(2,1,:) = serviceTimeRead(2,2,:);%(serverTime_1MW_64VC_read - serviceTimeRead(3,1,1)) * 0.5;

%Compute service time for client network=(ClientResp- MWResp)/2
clientResp_1MW_64VC_write = [0.8621, 1.0692,1.3314,1.3124]/toSec;
clientResp_1MW_64VC_read = [0.8216, 1.1882, 1.3269, 1.2772]/toSec;
clientResp_2MW_64VC_write = [1.6590, 1.7364, 1.7302, 1.8090]/toSec;
clientResp_2MW_64VC_read =  [1.6566, 1.5632, 1.6220, 1.6567]/toSec;

serviceTimeWrite(1,1,:) = clientResp_2MW_64VC_write;
serviceTimeRead(1,1,:) = clientResp_2MW_64VC_read;%1.6567/toSec;%clientResp_2MW_64VC_read;
serviceTimeWrite(1,2,:) = clientResp_2MW_64VC_write;%clientResp_2MW_64VC_write;
serviceTimeRead(1,2,:) = clientResp_2MW_64VC_read;%1.6567/toSec;%clientResp_2MW_64VC_read;%clientResp_2MW_64VC_read;

%Compute service time for the M/M/m Middleware model
serviceTimeWrite(4,1,:) = ([0.0381, 0.0423, 0.0506, 0.0570]/toSec)./workers;% 0.0570/toSec;
serviceTimeRead(4,1,:) = ([0.0430, 0.0476, 0.0587, 0.0678]/toSec)./workers;%0.0678/toSec;
serviceTimeWrite(4,2,:) = ([0.0288, 0.0298, 0.0356, 0.0352]/toSec)./(2*workers);% 0.0570/toSec;
serviceTimeRead(4,2,:) = ([0.0312, 0.0339, 0.0391, 0.0390]/toSec)./(2*workers);%0.0390/toSec;

VCs = 4:4:192;
X = zeros(4,2,size(VCs,2));
RS = zeros(4,2,size(VCs,2));
Q = zeros(4,2,size(VCs,2));
P = zeros(4,2);
wCounter = 1;
for workers = [8, 16, 32, 64]
    for mw = [1,2]
        VisitCount = [2,2,1,1];
        vcCounter = 1;
        for VC =VCs  
            [X(wCounter,mw, vcCounter), Q(wCounter,mw, vcCounter), R, RS(wCounter,mw, vcCounter), U, P] = extendedMVA(serviceTimeRead(:,mw,wCounter), VisitCount, VC, serviceTimeRead(4,mw,wCounter), workers*mw, [1,1,2,3]);
            vcCounter = vcCounter + 1;
        end
    end
    wCounter = wCounter + 1;
end

function [XSys, QDev, RDev, RSys, UDev, PDev] = extendedMVA(S, V, N, muDev, m, type)
    %Computes extended MVA as explained in book
    %Input:: S:service time per device, V:visit count per device, M:number of devices(delay,delay,fixed,load dep.), N:number of users, muDev:servicerate per Worker
    %Output:: XSys:system throughput, QDev:queue length per device, RDev: response time per device, RSys:system response time, UDev:utilization of device, PDev:probability of j jobs
    M = size(type,2);
    %Initialization
    QDev = zeros(M,1);
    RDev = zeros(M,1);
    UDev = zeros(M,1);
    PDev = zeros(N+1,1);%PDev(1)=prob of 0 jobs in system
    PDev(1) = 1;

    muPerUser = @(k) (k>=m).*(m/muDev) + (k<m).*(k/muDev);

    %iterate N times
    for n = 1:N
        
        for i = 1:M
            switch type(i)
                case 3
                    %Handle load dependant (M/M/m)
                    test1 = muPerUser(1:n);
                    test2 = ([1:n]./muPerUser(1:n));
                    RDev(i) = sum(PDev(1:n) .* ([1:n]./muPerUser(1:n))' );
                case 2
                    %Handle fixed capacity(M/M/1)
                    RDev(i) = S(i)*(1 + QDev(i));
                otherwise
                    %Handle delay center(M/M/inf)
                    RDev(i) = S(i);
            end
        end
        
        RSys = sum(RDev.*V');
        %assume Z = 0
        XSys = n/(RSys);
        
        for i = 1:M
            switch type(i)
                case 3
                    %Handle load dependant (M/M/m)
                    for j = n+1:-1:2
                        test = muPerUser(j-1);
                        PDev(j) = (XSys/test)*PDev(j-1);
                    end
                    test2 = sum(PDev(2:end));
                    PDev(1) = 1 - min(sum(PDev(2:end)),1);
                otherwise
                    %Handle fixed or delay center(M/M/inf) or (M/M/1)
                    QDev(i) = XSys * V(i) * RDev(i);
            end
        end
    end
    
    XDev = XSys * V;
     for i = 1:M
        switch type(i)
            case 3
                %Handle load dependant (M/M/m)
                UDev(i) = 1 - PDev(1);
            otherwise
                %Handle fixed or delay center(M/M/inf) or (M/M/1)
                UDev(i) = XSys*(S(i).*V(i));
        end
     end
     
     QDev = QDev(4);
end
