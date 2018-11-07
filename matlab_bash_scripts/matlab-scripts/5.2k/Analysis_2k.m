%!!!!!! This script has to be called after the parser_2k.m script !!!!!!This script executes the 2k analysis on the parsed client data, according to the procedure described in the book.
%define sign matrix as given in the book
%3 factors: S(num of servers), M(num of MWs) and W(num of Worker-threads per MW)
S = [-1;1;-1;1;-1;1;-1;1];
M = [-1;-1;1;1;-1;-1;1;1];
W = [-1;-1;-1;-1;1;1;1;1];
yTPS = tTPS(1:8);  %log(tResp(1:8));
yResp = tResp(1:8);  %log(tResp(1:8));
signM = [ones(8,1), S, M, W, S.*M, S.*W, M.*W, S.*M.*W];

totalTPS = sum(signM .* yTPS',1);
factorEffectsTPS = totalTPS / 8;

%compute error effects: SSE
ErrorsSqTPS = (tTPS_rep - tTPS).^2;  %(log(tTPS_rep) - log(tTPS)).^2;
SSETPS = sum(sum(sum(sum(ErrorsSqTPS,1))));

SErrTPS = sqrt(SSETPS/16);
SEffTPS = SErrTPS/sqrt(24);
%2³*r= 2³ * 3 = 24
SSTTPS = 24 * sum(factorEffectsTPS(2:end).^2) + SSETPS;
variationsTPS = (24 * factorEffectsTPS(2:end).^2)/SSTTPS;

totalResp = sum(signM .* yResp',1);
factorEffectsResp = totalResp / 8;

ErrorsSqResp = (tResp_rep - tResp).^2;  %(log(tResp_rep) - log(tResp)).^2;
SSEResp = sum(sum(sum(sum(ErrorsSqResp,1))));

SErrResp = sqrt(SSEResp/16);
SEffResp = SErrResp/sqrt(24);

SSTResp = 24 * sum(factorEffectsResp(2:end).^2) + SSEResp;
variationsResp = (24 * factorEffectsResp(2:end).^2)/SSTResp;