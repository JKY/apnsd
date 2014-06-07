%%
%% apnsd.hrl
%%
-define( DEBUG, 1).
-define( READ_TIMEOUT, 30000). 		   
-define( DEV_REPORT_TIMEOUT, 15000). 
-define( CHANNEL_REPORT_TIMEOUT, 30000).	   
-define( KEEP_ALIVE_INTERVAL, 300000).   %5 min 
-define( ECHO_TIMEOUT, 300000).        
-define( MAX_QUEQUE, 100).

-define( DEBUG_INFO(X),apnsd_util:log(X)).
-define( DEBUG_ERR(X),apnsd_util:log(X)).
