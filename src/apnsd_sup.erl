%%
%% apnsd_sup.erl 
%%
%% 

-module(apnsd_sup).
-behaviour(supervisor).
-export([start_link/0,init/1]).
 
-define(SUPERVISOR(M), {M, {M, start_link, []}, permanent, infinity, supervisor, [M]}).
-define(WORKER(M), {M, {M, start_link, []}, permanent, infinity, worker, [M]}).

start_link() ->
	supervisor:start_link({local, ?MODULE}, ?MODULE, []).
    

init([]) ->
    {ok, {
    	 	{one_for_one, 60, 3600},[
           		?WORKER(apnsd_trace),
           		?WORKER(apnsd_log),
              ?WORKER(apnsd_mq),
              ?WORKER(apnsd_event),
           		?WORKER(apnsd_channel),
           		?WORKER(apnsd_console),
           		?SUPERVISOR(apnsd_conn)				
          ]
       }}.
         
