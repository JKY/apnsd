%%
%% apnsd_channel.erl 
%%
-module(apnsd_channel).
-include("apnsd.hrl").
-compile(export_all).

-record(channel_list, 
  { list }
).

-record(channel_state,
{
      name,
      type,
      devices,
      capacity
}).

%%% start link 
start_link() ->
    Pid = spawn_link(fun()->
                        process_flag(trap_exit, true),
                        service(#channel_list{list=dict:new()})
                     end),
    register(?MODULE,Pid),
    {ok,Pid}.

%% main process 
service(S) ->
    receive 
        {opt_reload,Name} ->
            case dict:find(Name,S#channel_list.list) of
                {ok,[Value]} ->
                    apnsd_util:send_msg_to_process(Value,{opt_reload});
                error ->
                    ok
             end,
             service(S);
        {join,Name,{Dev,Pid}} ->
            %% local find 
            case dict:find(Name,S#channel_list.list) of
                {ok,[Value]} ->
                    C = Value,
                    apnsd_util:send_msg_to_process(C, {join,{Dev,Pid}}),
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
                                apnsd_channel:process(#channel_state{
                                                              name = Name,
                                                              type = Type,
                                                              devices = dict:new(),
                                                              capacity = Limit}
                                                     )
                              end),
                    pg2:join(Name,C),
                    apnsd_util:send_msg_to_process(C, {join,{Dev,Pid}}),
                    service(S#channel_list{ list=dict:append(Name, C, S#channel_list.list)})
            end;
          {push, Reporter, {Name,DevId,Data}} ->
                spawn(fun() ->
                            pg2:which_groups(),
                            case pg2:get_members(Name) of 
                                {error,_}->
                                   apnsd_util:send_msg_to_process(Reporter, {0,0,0});
                                Members ->
                                   N = apnsd_channel:all(Members,push,Reporter,{DevId,Data},0),
                                   {ok,N}
                            end
                        end),
                service(S);
          {stat,Name,Reporter} ->
                 spawn(fun() ->
                            pg2:which_groups(),
                            case pg2:get_members(Name) of 
                                {error,_}->
                                   apnsd_util:send_msg_to_process(Reporter, notfound);
                                Members->
                                   N = apnsd_channel:all(Members,stat,Reporter, nil,0),
                                   {ok,N}
                            end
                        end),
                service(S);
         {stat,list,Name,Reporter} ->
                 spawn(fun() ->
                            pg2:which_groups(),
                            case pg2:get_members(Name) of 
                                {error,_}->
                                   apnsd_util:send_msg_to_process(Reporter, notfound);
                                Members->
                                   N = apnsd_channel:all(Members,list,Reporter, nil,0),
                                   {ok,N}
                            end
                        end),
                service(S);
         {'EXIT',_,Reason} ->
              apnsd_trace:trap(err,ch_demean_exit,Reason)
    end.

%% dispatch all message to group processes 
all([H|T],Mess,Sender,Param,N) -> 
    H ! { Mess,Sender,Param }, 
    all(T,Mess,Sender,Param ,N+1);

all([],_,_,_,N) -> N.


process(S) ->
    receive 
        {join,{Name,Pid}} ->
	         {ok,{Num,Limit}} = apnsd_channel:stat(S),
           case S#channel_state.type of
                  'CF' ->
                        apnsd_util:send_msg_to_process(Pid, {ok,self()}),
                        process(S#channel_state{ devices=dict:append(Name,Pid,S#channel_state.devices)});
                    _->
                        if Num < Limit ->
                            apnsd_util:send_msg_to_process(Pid, {ok,self()}),
                            process(S#channel_state{ devices=dict:append(Name,Pid,S#channel_state.devices)});
                        true->
                            apnsd_util:send_msg_to_process(Pid,too_many),
                            process(S)
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
                    apnsd_util:send_msg_to_process(Reporter,sent);
                _ ->
                    case dict:find(Id,S#channel_state.devices) of
                        {ok,L} ->
                            W = spawn(fun()->
					                              N = length(L), 
                                        case wait4cpr(N,0,0) of
                                            {Tx,F} ->
                                                 apnsd_util:send_msg_to_process(Reporter,{Tx,F,N}) %% report to console
                                        end 
                      				        end),
			                      send2devices(L,{push,W,Data});
                        error ->
                            apnsd_util:send_msg_to_process(Reporter,notfound)
                    end
            end,
            process(S);
        {stat,Reporter,_} ->
            apnsd_util:send_msg_to_process(Reporter,apnsd_channel:stat(S)),
            process(S);
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
            apnsd_util:send_msg_to_process(Reporter,{ok,L}),
            process(S);
        {leave, Name,Pid} ->
	           Devs = dict:update(Name,fun(Old)->
					                               lists:delete(Pid,Old)
                          				    end,
                          			 S#channel_state.devices),
            S1 = S#channel_state{ devices = Devs },
            process(S1);
        {opt_reload} ->
            {Type,Limit} = apnsd_option:channel_capacity(S#channel_state.name),
            S1 = S#channel_state{ type=Type, capacity = Limit },
            process(S1);
        {'EXIT',Pid ,Reason} ->
            case whereis(?MODULE) of 
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
                    process(S)
            end
    end.
%%
%%
%%
send2devices([H|L],M) -> apnsd_util:send_msg_to_process(H,M),send2devices(L,M);
send2devices([],_) -> ok.

%% message delever statistc process 
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

