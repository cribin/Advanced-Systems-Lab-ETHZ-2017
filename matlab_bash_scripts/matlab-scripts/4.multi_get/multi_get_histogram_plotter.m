%Plot histogram for multi-get experiments
% figure(1);
% edges = 5 : 0.1 : 11;
% h = histogram(completeRespData_6_keys,edges);
% 
% title('Client Resp. Histogram (Sharded)');
% xlabel('ResponseTime (ms)');
% ax = gca;
% grid on
% ax.YMinorGrid = 'on';
% ax.YAxis.Exponent = 0;
% saveas(gcf,'Histogram_Multi_Get_ClientResp_sharded.jpeg');
% 
% 
% figure(2);
% h = histogram(completeRespData_6_keys_non_shard,edges);
% 
% title('Client Resp. Histogram (NonSharded)');
% xlabel('ResponseTime (ms)');
% ax = gca;
% grid on
% ax.YMinorGrid = 'on';
% ax.YAxis.Exponent = 0;
% saveas(gcf,'Histogram_Multi_Get_ClientResp_nonsharded.jpeg');

figure(1);
%mwedgesSharded = 2 : 0.025 : 3;
mwedgesNonSharded = 1.25 : 0.025 : 2.25;
h = histogram(completeRespDataMW_6_keys,mwedgesNonSharded);

title('MW Resp. Histogram (NonSharded)');
xlabel('ResponseTime (ms)');
ax = gca;
grid on
ax.YMinorGrid = 'on';
ax.YAxis.Exponent = 0;
%saveas(gcf,'Histogram_Multi_Get_MWResp_nonsharded.jpeg');