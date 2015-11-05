%%
%% apnsd_util.erl 
%%
%% 
-module(apnsd_util).
-export([gwait/2,send_pm/2,send_pm_byname/2,tsnow/0]).

%% wait groups 
gwait(G,Tries) when Tries > 0 ->
    pg2:which_groups(),
    case pg2:which_groups() of
        L when is_list(L) ->
            case lists:member(G, L) of
                true ->
                    ok;
                _ ->
                    timer:sleep(499),
                    gwait(G,Tries - 1)
            end;
        _ ->
            timer:sleep(499),
      gwait(G,Tries - 1)
    end;
gwait(_,Tries) when Tries == 0 ->
	timeout.



%%% send message to process by Pid
send_msg_to_process(P,M) ->
    case is_pid(P) of
        true ->
            P ! M;
        _ ->
            ok
    end.



%%% send message to process by process name
send_msg_to_process_byname(Npro,M) ->
    try
        Npro ! M
    catch
        % registered process To is unavailable,
        X:Reason -> %exit: {badarg, _}
            ok % dbg only
    end.



%%% time
tsnow()-> {Mega, Secs, _} = now(), Mega*1000000 + Secs.
	