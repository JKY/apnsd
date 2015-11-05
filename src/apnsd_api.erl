%%
%% apnsd_api.erl
%% 
-module(apnsd_api).
-include("apnsd.hrl").
-export([start_link/0,loop/0]).

-define(CHANNEL_MODULE,apnsd_channel).

%% start link
start_link() ->
    Pid = spawn_link(?MODULE,loop,[]),
    register(?MODULE, Pid),
    {ok,Pid}.

%% main 
loop() ->
	receive
      {Sender,push,{Ch,Dev,Data}} ->
            spawn(fun()->
                     apnsd_util:send_msg_to_process_byname(?CHANNEL_MODULE,{push, nil, {Ch,Dev,Data}}),
                     apnsd_util:send_msg_to_process(Sender,ok)
                  end),
            loop();
    	{Sender,sync_push,{Ch,Dev,Data}} ->
            spawn(fun()->
                    N = apnsd_channel:host_num(Ch),
                    case N of 
                        0 ->
                           apnsd_trace:trap({enqueue,Ch,Dev,Data}),
                           apnsd_util:send_msg_to_process(Sender,{0,0,0});
                        _ ->
                           W = spawn(fun()->
                                         {T,M} = wait4push_stat(0,0,N),
                                         if T==0,M==0;T<M,M==1 ->
                                              apnsd_trace:trap({enqueue,Ch,Dev,Data});
                                            true ->
                                              ok
                                         end,
                                         apnsd_util:send_msg_to_process(Sender, {T,M,N})
                                     end),
                           apnsd_util:send_msg_to_process_byname(?CHANNEL_MODULE,{push, W, {Ch,Dev,Data}})
                    end
                  end),
            loop();
       %% channel status: connect num, limit%%
       {Sender,stat,Name}->
            spawn(fun()->
                     N = apnsd_channel:host_num(Name),
                     apnsd_util:send_msg_to_process_byname(?CHANNEL_MODULE,{stat, Name, self()}),
                     case N of 
                        0 ->
                           {_,L} = apnsd_option:channel_capacity(Name),
                           apnsd_util:send_msg_to_process(Sender,{0,L});
			                  _ ->
                           apnsd_util:send_msg_to_process_byname(?CHANNEL_MODULE,{stat, Name, self()}),
                           cl_channel_info(Sender,N,{0,0}) 
                    end
                  end),
            loop();
        %% list channel device names %%
        {Sender,stat,list,Name}->
            spawn(fun()->
                     N = apnsd_channel:host_num(Name),
                     apnsd_util:send_msg_to_process_byname(?CHANNEL_MODULE,{stat,list,Name,self()}),
                     case N of 
                        0 ->
                           apnsd_util:send_msg_to_process(Sender,[]);
                        _ ->
                           apnsd_util:send_msg_to_process_byname(?CHANNEL_MODULE,{stat,list,Name,self()}),
                           cl_dev_names(Sender,N,[]) 
                    end
                  end),
            loop();
        {Sender,reload_option,Name}->
            apnsd_util:send_msg_to_process_byname(?CHANNEL_MODULE,{opt_reload, Name}),
            apnsd_util:send_msg_to_process(Sender,ok),
            loop();
        _ ->
            loop()
    end.


%% waiting for all channel response to report the status
cl_channel_info(Sender,N,Stat) when N > 0 ->
    receive
        {ok,{ConnNum,Max}} ->
            {C,_} = Stat,
            cl_channel_info(Sender,N-1,{ConnNum+C,Max});
        _->
            cl_channel_info(Sender,N-1,Stat)
    after 30000 ->
        Sender ! timeout
    end;
cl_channel_info(Sender,N,Stat) when N=:=0 ->
    Sender ! Stat.




%% waiting for all channel response to report the device names 
cl_dev_names(Sender,N,NL) when N > 0 ->
    receive
        {ok,L} ->
            cl_dev_names(Sender,N-1,L++NL);
        _->
            cl_dev_names(Sender,N-1,NL)
    after 30000 ->
        Sender ! NL
    end;
cl_dev_names(Sender,N,NL) when N=:=0 ->
    Sender ! NL.



%% push result collection process 
wait4push_stat(Tx,M,N) when N > 0 ->
    receive
        {T,F,S} ->
	         wait4push_stat(Tx+T,M+S,N-1)
    after ?CHANNEL_REPORT_TIMEOUT ->
        wait4push_stat(Tx,M,N-1)
    end;

wait4push_stat(Tx,M,N) when N =:= 0 -> {Tx,M}.
