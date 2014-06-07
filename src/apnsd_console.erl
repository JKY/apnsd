%%
%% apnsd_console.erl 
%%
%% 

-module(apnsd_console).
-include("apnsd.hrl").
-export([start_link/0,loop/0]).


start_link() ->
    Pid = spawn_link( apnsd_console,loop,[]),
    register( apnsd_daemon, Pid),
    {ok,Pid}.


loop() ->
	receive
      {Sender,push,{Ch,Dev,Data}} ->
            spawn(fun()->
                     apnsd_util:send_pm_byname(cproc,{push, nil, {Ch,Dev,Data}}),
                     apnsd_util:send_pm(Sender,ok)
                  end),
            loop();
    	{Sender,sync_push,{Ch,Dev,Data}} ->
            spawn(fun()->
                    N = apnsd_channel:host_num(Ch),
                    case N of 
                        0 ->
                           apnsd_trace:trap({mq,Ch,Dev,Data}),
                           apnsd_util:send_pm(Sender,{0,0,0});
                        _ ->
                           W = spawn(fun()->
                                         {T,M} = coll_pr(0,0,N),
                                         if T==0,M==0;T<M,M==1 ->
                                              apnsd_trace:trap({mq,Ch,Dev,Data});
                                            true ->
                                              ok
                                         end,
                                         apnsd_util:send_pm(Sender, {T,M,N})
                                     end),
                           apnsd_util:send_pm_byname(cproc,{push, W, {Ch,Dev,Data}})
                    end
                  end),
            loop();
       %% channel status: connect num, limit%%
       {Sender,stat,Name}->
            spawn(fun()->
                     N = apnsd_channel:host_num(Name),
                     apnsd_util:send_pm_byname(cproc,{stat, Name, self()}),
                     case N of 
                        0 ->
                           {_,L} = apnsd_option:channel_capacity(Name),
                           apnsd_util:send_pm(Sender,{0,L});
			                  _ ->
                           apnsd_util:send_pm_byname(cproc,{stat, Name, self()}),
                           coll_cinfo(Sender,N,{0,0}) 
                    end
                  end),
            loop();
        %% list channel device names %%
        {Sender,stat,list,Name}->
            spawn(fun()->
                     N = apnsd_channel:host_num(Name),
                     apnsd_util:send_pm_byname(cproc,{stat,list,Name,self()}),
                     case N of 
                        0 ->
                           apnsd_util:send_pm(Sender,[]);
                        _ ->
                           apnsd_util:send_pm_byname(cproc,{stat,list,Name,self()}),
                           coll_dev_names(Sender,N,[]) 
                    end
                  end),
            loop();
        {Sender,reload_option,Name}->
            apnsd_util:send_pm_byname(cproc,{opt_reload, Name}),
            apnsd_util:send_pm(Sender,ok),
            loop();
        _ ->
            loop()
    end.


%%
%%
%%
coll_cinfo(Reporter,N,Stat) when N > 0 ->
    receive
        {ok,{Conn,Limit}} ->
            {C,_} = Stat,
            coll_cinfo(Reporter,N-1,{Conn+C,Limit});
        _->
            coll_cinfo(Reporter,N-1,Stat)
    after 30000 ->
        Reporter ! timeout
    end;
coll_cinfo(Reporter,N,Stat) when N=:=0 ->
    Reporter ! Stat.

%%
%%
%%
coll_dev_names(Reporter,N,NL) when N > 0 ->
    receive
        {ok,L} ->
            coll_dev_names(Reporter,N-1,L++NL);
        _->
            coll_dev_names(Reporter,N-1,NL)
    after 30000 ->
        Reporter ! NL
    end;
coll_dev_names(Reporter,N,NL) when N=:=0 ->
    Reporter ! NL.


%%
%% push result
%%
coll_pr(Tx,M,N) when N > 0 ->
    receive
        {T,F,S} ->
	         coll_pr(Tx+T,M+S,N-1)
    after ?CHANNEL_REPORT_TIMEOUT ->
        coll_pr(Tx,M,N-1)
    end;

coll_pr(Tx,M,N) when N =:= 0 -> {Tx,M}.
