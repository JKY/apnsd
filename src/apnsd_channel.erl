%%
%% apnsd_channel.erl 
%%
%% 
-module(apnsd_channel).
-include("apnsd.hrl").
-compile(export_all).

-record(channel_list, {
                    list
               }).

-record(channel_state,{
                  name,
                  type,
                  devices,
                  capacity
               }).


start_link() ->
    Pid = spawn_link(fun()->
                        process_flag(trap_exit, true),
                        service(#channel_list{list=dict:new()})
                     end),
    register(cproc,Pid),
    {ok,Pid}.


service(S) ->
    receive 
        {opt_reload,Name} ->
            case dict:find(Name,S#channel_list.list) of
                {ok,[Value]} ->
                    apnsd_util:send_pm(Value,{opt_reload});
                error ->
                    ok
             end,
             service(S);
        {join,Name,{Dev,Pid}} ->
            %% local find 
            case dict:find(Name,S#channel_list.list) of
                {ok,[Value]} ->
                    C = Value,
                    apnsd_util:send_pm(C, {join,{Dev,Pid}}),
                    service(S);
                error ->
                    %% not found 
                    R = apnsd_util:gwait(Name,1),
                    if R == timeout ->
                        pg2:create(Name);
                    true->
                        ok
                    end,
                    C = spawn_link(fun()->
                                process_flag(trap_exit, true),
                                {Type,Limit} = apnsd_option:channel_capacity(Name),
                                apnsd_channel:loop(#channel_state{name = Name,
                                                                  type = Type,
                                                                  devices = dict:new(),
                                                                  capacity = Limit})
                              end),
                    pg2:join(Name,C),
                    apnsd_util:send_pm(C, {join,{Dev,Pid}}),
                    service(S#channel_list{ list=dict:append(Name,C,S#channel_list.list)})
            end;
          {push,Reporter, {Name,DevId,Data}} ->
                spawn(fun() ->
                            pg2:which_groups(),
                            case pg2:get_members(Name) of 
                                {error,_}->
                                   apnsd_util:send_pm(Reporter, {0,0,0});
                                List ->
                                   N = apnsd_channel:q(List,push,Reporter,{DevId,Data},0),
                                   {ok,N}
                            end
                            %case apnsd_util:gwait(Name,1) of 
                            %   ok ->
                            %List = pg2:get_members(Name),
                            %N = apnsd_channel:q(List,push,Reporter,{DevId,Data},0),
                            %{ok,N};
                            %    timeout ->
                            %        apnsd_util:send_pm(Reporter, timeout)
                            % end
                        end),
                service(S);
          {stat,Name,Reporter} ->
                 spawn(fun() ->
                            %case apnsd_util:gwait(Name,1) of 
                            %    ok ->
                            %        List = pg2:get_members(Name),
                            %        N = apnsd_channel:q(List,stat,Reporter, nil,0),
                            %        {ok,N};
                            %    timeout ->
                            %        apnsd_util:send_pm(Reporter, notfound)
                            %end
                            pg2:which_groups(),
                            case pg2:get_members(Name) of 
                                {error,_}->
                                   apnsd_util:send_pm(Reporter, notfound);
                                List->
                                   N = apnsd_channel:q(List,stat,Reporter, nil,0),
                                   {ok,N}
                            end
                        end),
                service(S);
         {stat,list,Name,Reporter} ->
                 spawn(fun() ->
                            %case apnsd_util:gwait(Name,1) of 
                            %    ok ->
                            %        List = pg2:get_members(Name),
                            %        N = apnsd_channel:q(List,list,Reporter, nil,0),
                            %        {ok,N};
                            %    timeout ->
                            %        apnsd_util:send_pm(Reporter, notfound)
                            %end
                            pg2:which_groups(),
                            case pg2:get_members(Name) of 
                                {error,_}->
                                   apnsd_util:send_pm(Reporter, notfound);
                                List->
                                   N = apnsd_channel:q(List,list,Reporter, nil,0),
                                   {ok,N}
                            end
                        end),
                service(S);
         {'EXIT',_,Reason} ->
              apnsd_trace:trap(err,ch_demean_exit,Reason)
    end.

%%
%%
%%  
q([H|T],Mess,Sender,Param ,N) -> H ! { Mess,Sender, Param }, q(T,Mess,Sender,Param ,N+1);
q([],_,_,_,N) -> N.


loop( S ) ->
    receive 
        {join,{Name,Pid}} ->
            %% local find 
            %case dict:find(Name,S#channel_state.devices) of
            %    {ok,E} ->
            %        apnsd_util:send_pm(E, dupd),
            %        loop(S);
            %    error ->
            %        {ok,{Num,Limit}} = apnsd_channel:stat(S),
            %        case S#channel_state.type of
            %            'CF' ->
            %                apnsd_util:send_pm(Pid, {ok,self()}),
            %                loop(S#channel_state{ devices=dict:append(Name,Pid,S#channel_state.devices)});
            %             _->
            %                if Num < Limit ->
            %                    apnsd_util:send_pm(Pid, {ok,self()}),
            %                    loop(S#channel_state{ devices=dict:append(Name,Pid,S#channel_state.devices)});
            %                true->
            %                    apnsd_util:send_pm(Pid,too_many),
            %                    loop(S)
            %                end
            %        end 
            %end;
	         {ok,{Num,Limit}} = apnsd_channel:stat(S),
           case S#channel_state.type of
                  'CF' ->
                        apnsd_util:send_pm(Pid, {ok,self()}),
                        loop(S#channel_state{ devices=dict:append(Name,Pid,S#channel_state.devices)});
                    _->
                        if Num < Limit ->
                            apnsd_util:send_pm(Pid, {ok,self()}),
                            loop(S#channel_state{ devices=dict:append(Name,Pid,S#channel_state.devices)});
                        true->
                            apnsd_util:send_pm(Pid,too_many),
                            loop(S)
                        end
              end;
        {push,Reporter,{Id,Data}} ->
            case Id of 
                all ->
                    dict:fold(
                              fun(_, L, D) -> 
				                          send2devices(L, {push,nil,D}),
                                  D
                              end,
                              Data,
                              S#channel_state.devices),
                    apnsd_util:send_pm(Reporter,sent);
                _ ->
                    case dict:find(Id,S#channel_state.devices) of
                        {ok,L} ->
                            W = spawn(fun()->
					                              N = length(L), 
                                        case wait4cpr(N,0,0) of
                                            {Tx,F} ->
                                                 apnsd_util:send_pm(Reporter,{Tx,F,N}) %% report to console
                                        end 
                      				        end),
			                      send2devices(L,{push,W,Data});
                        error ->
                            apnsd_util:send_pm(Reporter,notfound)
                    end
            end,
            loop(S);
        {stat,Reporter,_} ->
            apnsd_util:send_pm(Reporter,apnsd_channel:stat(S)),
            loop(S);
        {list,Reporter,_} ->
             L = dict:fold(
                              fun(K, V, D) ->
                                  Dnum = length(V),
                                  case Dnum of 
                                    0->
                                      D;
                                    _-> 
                                      [{K,Dnum}|D]
                                  end
                              end,
                              [],
                              S#channel_state.devices),
            apnsd_util:send_pm(Reporter,{ok,L}),
            loop(S);
        {leave, Name,Pid} ->
	           Devs = dict:update(Name,fun(Old)->
					                               lists:delete(Pid,Old)
                          				    end,
                          			 S#channel_state.devices),
            S1 = S#channel_state{ devices = Devs },
            loop(S1);
        {opt_reload} ->
            {Type,Limit} = apnsd_option:channel_capacity(S#channel_state.name),
            S1 = S#channel_state{ type=Type, capacity = Limit },
            loop(S1);
        {'EXIT',Pid ,Reason} ->
            case whereis(cproc) of 
                Pid ->
                    dict:fold(
                              fun(_, L, D) -> 
                                  send2devices(L,{kill,D}),
                                  D
                              end,
                              Reason,
                              S#channel_state.devices
                          );
                _->
                    loop(S)
            end
    end.
%%
%%
%%
send2devices([H|L],M) -> apnsd_util:send_pm(H,M),send2devices(L,M);
send2devices([],_) -> ok.

%%
%%
%%
wait4cpr(N,Tx,F) when N > 0 -> 
	receive 
		sent ->
		   wait4cpr(N-1,Tx+1,F);
		failed ->
		   wait4cpr(N-1,Tx,F+1)
	after ?DEV_REPORT_TIMEOUT ->
	     wait4cpr(N-1,Tx,F)
	end;
wait4cpr(N,Tx,F) when N =:=0  -> {Tx,F}.



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%  
stat(S) -> 
    N = dict:fold(fun(_,L,D)->
		                  D + length(L)
	                 end,
                   0,
                   S#channel_state.devices), 
    {ok, {N,S#channel_state.capacity}}.

host_num(Name)->
    Group = pg2:which_groups(),
    if is_list(Group) ->
        case lists:member(Name, Group) of
            true ->
                M = pg2:get_members(Name),
                N = length(M);
            _ ->
                N = 0
        end;
    true->
         N = 0
    end,
    N.

