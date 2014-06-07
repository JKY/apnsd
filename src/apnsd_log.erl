%
% ansd_log.erl 
%%
%% 
-module(apnsd_log).
-include("apnsd.hrl").
-export([start_link/0,log/1,loop/1]).

-record(context, {
				  mgn_conn_pool,
				  db_name
               }).


start_link()->
    {ok,DB_HOST} =  application:get_env(db_host),
    {ok,DB_PORT} =  application:get_env(db_port),
    {ok,DB_NAME} =  application:get_env(db_name),
    Pid = spawn_link(fun() ->
    					Ctx = #context{
    							   mgn_conn_pool = resource_pool:new (mongo:connect_factory({DB_HOST,DB_PORT}), 15),
    							   db_name = DB_NAME 
    						},
    					loop(Ctx),
    					resource_pool:close(Ctx#context.mgn_conn_pool)
    				  end),
    register( apnsd_logs, Pid),
    apnsd_trace:add(?MODULE,log),
    {ok,Pid}.
%%
%%
%%
loop(Ctx) ->
	receive 
		{ write, message, D } ->
			w(Ctx,log_m,D);
		{ write, err, D} ->
			w(Ctx,err,D);
		_->
			ok
	end,
	loop(Ctx).


%%
%%
%%
w(Ctx,DB,Data)->
  case resource_pool:get(Ctx#context.mgn_conn_pool) of 
	{ok,Conn} ->
		mongo:do(unsafe, master, Conn, Ctx#context.db_name, 
		      fun () ->
			 mongo:insert(DB,Data)
		      end
		);
	_->
		ok
  end.


%% send
log({tx,Data}) ->
	T = apnsd_util:tsnow(),%calendar:now_to_local_time(erlang:now()),
	apnsd_util:send_pm_byname(apnsd_logs,{write,message,{e,send,p,Data,t,T}}),
    done;
%% send fail
log({tx_fail,Data}) ->
	%T = calendar:now_to_local_time(erlang:now())
	T = apnsd_util:tsnow(),
	apnsd_util:send_pm_byname(apnsd_logs,{write,message,{e,fail,p,Data,t,T}}),
    done;
%% err
log({err,Type,Reason}) ->
	%T = calendar:now_to_local_time(erlang:now()),
	T = apnsd_util:tsnow(),
	apnsd_util:send_pm_byname(apnsd_logs,{write,err,{type,Type,reason,Reason,t,T}}),
    done;

log(_) -> next.

