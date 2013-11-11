-module(egress_port).
-behaviour(gen_server).

-export([start_link/1]).
-export([init/1, handle_call/3, handle_cast/2,handle_info/2,terminate/2,code_change/3]).


start_link({Name,Next_hop,Params})->
		gen_server:start_link({global,Name},egress_port,[{Name,Next_hop,Params}],[]).

		
		
init([{Name,Next_hop,Params}])->
			io:fwrite("egress_port ~s: init\n",[Name]),
            random:seed(erlang:now()),
			{ok,{Name,Next_hop,0,Params}}.  % empty=0, busy=1


handle_call(_Request,_From,State)->{noreply, State}.

handle_cast(Msg,State)->my_handle_cast(Msg,State).

handle_info(_Info,State)->my_handle_info(_Info,State).

terminate(_Reason,_State)->ok.

code_change(_Oldvsn, _State, _Extra)->{ok, state}.


%%%%%my functions%%%%%
	
my_handle_info(timeout,{Name,Next_hop,1,Params})-> {noreply,{Name,Next_hop,0,Params},infinity};  
my_handle_info(_Info,State)->{noreply, State}.	
	
my_handle_cast({Dst,Size,Maxhops,regular,Payload},{Name,Next_hop,Flag,{Lat,BW,Drop_rate}})->  % Mode =0 fast mode
	 %io:fwrite("~p: got packet \n",[Name]),
	Wait=case Flag of
			1 -> Size/BW;
			0->  (Size/BW) + Lat
		end,
	
	% io:fwrite("~s: Sleep for ~p seconds\n",[Name,Wait]),
	% timer:sleep(500),  % Wait in seconds (timer:sleep(milliseconds) Time Dilation Goes Here !
    %timer:sleep(round(Wait*1000)),  % Wait in seconds (timer:sleep(milliseconds) Time Dilation Goes Here !
	mix_wait(round(Wait*1000)),
	% io:fwrite("~s: flag1\n",[Name]),
	R=random:uniform(),
    case R<Drop_rate of
		true -> {noreply,{Name,Next_hop,1,{Lat,BW,Drop_rate}},0};
		_ -> gen_server:cast(global:whereis_name(Next_hop),{Dst,Size,Maxhops,regular,Payload}),
             {noreply,{Name,Next_hop,1,{Lat,BW,Drop_rate}},0} 
	end;
	
my_handle_cast({Dst,Size,Maxhops,debug,{Src,Data,Time_list}},{Name,Next_hop,Flag,{Lat,BW,Drop_rate}})-> % Mode =1 debug mode
	% io:fwrite("~s: got ~p from ~p \n",[Name, {Sub_data,Size}, Src]),
	New_time_list=[{Name,erlang:now()}|Time_list],
	Wait=case Flag of
			1 -> Size/BW;
			0 ->  (Size/BW) + Lat
		end,
	
	% io:fwrite("~s: Sleep for ~p seconds\n",[Name,Wait]),
	% timer:sleep(500),  % Wait in seconds (timer:sleep(milliseconds) Time Dilation Goes Here !
	mix_wait(round(Wait*1000)),
    %timer:sleep(round(Wait*10)),  % Wait in seconds (timer:sleep(milliseconds) Time Dilation Goes Here !
	% io:fwrite("~s: flag1\n",[Name]),
	R=random:uniform(),
    case R<Drop_rate of
		true -> {noreply,{Name,Next_hop,1,{Lat,BW,Drop_rate}},0};
		_ -> gen_server:cast(global:whereis_name(Next_hop),{Dst,Size,Maxhops,debug,{Src,Data,New_time_list}}),
             {noreply,{Name,Next_hop,debug,{Lat,BW,Drop_rate}},0} 
	end;
	
my_handle_cast(_Message,State)-> 
		
	{noreply,State,0}. 
	
%%%%%%  wait implementation
busy_wait(Time)->  %% accepts milliseconds
        Start=erlang:now(),
        busy_wait(Time,Start).

busy_wait(Time,Start)->
    Now=erlang:now(),
    Diff=timer:now_diff(Now,Start)/(1000),
    case Diff>=Time of
        true -> ok;
        _ -> busy_wait(Time,Start)
    end.
    
    
mix_wait(Time) when (Time>30) -> %% millisec
    %io:fwrite("~p: waiting\n",[Time]),
    Start=erlang:now(),
    SleepTime=Time- 5,
    timer:sleep(SleepTime),
    Now=erlang:now(),
    Diff=Time - round(timer:now_diff(Now,Start)/(1000)),
    busy_wait(Diff);
    
mix_wait(Time) ->
	%io:fwrite("~p: waiting\n",[Time]),
    busy_wait(Time).

