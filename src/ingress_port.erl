-module(ingress_port).
-behaviour(gen_server).

-export([start_link/1]).
-export([init/1, handle_call/3, handle_cast/2,handle_info/2,terminate/2,code_change/3]).

start_link({Name,Fwd_table})->
	gen_server:start_link({global,Name},ingress_port,[{Name,Fwd_table}],[]).
	
init([{Name,Fwd_table}])->
            
				io:fwrite("ingress_port ~s: init\n",[Name]),
				{ok,{Name,Fwd_table}}.


handle_call(_Request,_From,State)->{noreply, State}.

handle_cast(Msg,State)->my_handle_cast(Msg,State).

handle_info(_Info,State)->{noreply, State}.

terminate(_Reason,_State)->ok.

code_change(_Oldvsn, _State, _Extra)->{ok, state}.
	
%{Dst,Src,{Sub_data,Size}  old version
%{Dst,Size,Maxhops,Mode,{Src,Data,Time_list}}
%{Dst,Size,Maxhops,Mode,Payload}

my_handle_cast({Dst,Size,Maxhops,regular,Payload}, {Name,Fwd_table}) when Maxhops > 0->  %Mode=0
	
	% io:format("~p get packet\n",[Name]),
	try  dict:fetch(Dst,Fwd_table) of
		Next_hop->  % io:fwrite("Next Hop is ~p\n",[Next_hop]),
                gen_server:cast(global:whereis_name(Next_hop),{Dst,Size,Maxhops-1,regular,Payload})  % maybe we need a try catch here.. 
	catch
		_:_ ->  io:fwrite("debug: error, not a legel value in Fwd_table in ~s  payload = ~p Dst= ~p \n",[Name,Payload,Dst]) %% debug mode: print
	end,
	{noreply, {Name,Fwd_table}};
	
	
my_handle_cast({Dst,Size,Maxhops,debug,{Src,Data,Time_list}}, {Name,Fwd_table}) when Maxhops > 0->	 %Mode=1

	New_time_list=[{Name,erlang:now()}|Time_list],
	try  dict:fetch(Dst,Fwd_table) of
		Next_hop->  % io:fwrite("Next Hop is ~p\n",[Next_hop]),
                gen_server:cast(global:whereis_name(Next_hop),{Dst,Size,Maxhops-1,debug,{Src,Data,New_time_list}})  % maybe we need a try catch here.. 
	catch
		_:_ ->  io:fwrite("debug: error, not a legel value in Fwd_table in ~s \n",[Name]) %% debug mode: print
	end,
	{noreply, {Name,Fwd_table}};
	
my_handle_cast({_Dst,_Size,0,Mode,{_Src,_Data,_Time_list}}, {Name,Fwd_table})->	
	case Mode of
		regular -> {noreply, {Name,Fwd_table}};
		debug->   io:fwrite("~p : Time to live =0, message drop \n",[Name]), {noreply, {Name,Fwd_table}} 
	end;

my_handle_cast(_Message, {Name,Fwd_table})->
	
	{noreply, {Name,Fwd_table}}.
	
	
	


		
