-module(host_ingress_port).
-behaviour(gen_server).

-export([start_link/2]).
-export([init/1, handle_call/3, handle_cast/2,handle_info/2,terminate/2,code_change/3]).

%todo:

%update all state

start_link({Name,Egress_port,Host_name},Hosts)->
	gen_server:start_link({global,Name},host_ingress_port,[{Name,Egress_port,Host_name,Hosts}],[]).

% state: {busy/empty,Name of ingress port,Remote_host,Name of Egress Port,Ref}.
% remote host is a Pid (not registered name!!).
% TODO - handle cast doesn't  check if the remote host is the one that registered (security).  
	
init([{Name,Egress_port,Host_name,Hosts}])->
            	process_flag(trap_exit, true),
		io:fwrite("host_ingress_port ~s: init\n",[Name]),


		Tap_name=list_to_atom("tap"++ (atom_to_list(Host_name) -- "host")),
		Tap=global:whereis_name(Tap_name),
		io:format("Tap is ~p\n",[Tap]),
		%io:format("tap name = ~p\n",[Tap_name]),	
		%{ok, Tap} = tuncer:create(Tap_name, [tap, no_pi, {active, true]),

		global:whereis_name(tap_owner) ! {self(),Tap},				
		
		{ok,{Name,Egress_port,Host_name,Hosts,Tap}}.


handle_call(Request,From,State)->my_handle_call(Request,From,State).

handle_cast(Msg,State)->my_handle_cast(Msg,State).

handle_info(Info,State)->my_handle_info(Info,State).

terminate(_Reason,{_Name,_Egress_port,_Host_name,_Hosts,Tap})->
tuncer:controlling_process(Tap,global:whereis_name(tap_owner)),
io:format("========================\nTerminating\n========================\n"),
ok.

code_change(_Oldvsn, _State, _Extra)->{ok, state}.



		
% default	
my_handle_call(_Request,_From,{Name,Egress_port,Host_name,Hosts,Tap})->

		% io:format("warning: ~p : default handle call ",[Name]),  %performance ??
		{reply, ok, {Name,Egress_port,Host_name,Hosts,Tap}}.
		

my_handle_info({tuntap, Tap, Data},{Name,Egress_port,Host_name,Hosts,Tap})->	

		{Dst_mac,Size}=parser(Data,Data),
		
		case Dst_mac of 
		
			[255,255,255,255,255,255] -> sendto({Hosts -- [Host_name],Egress_port,Size,Data});
			[_,_,_,_,_,X]-> Dst=list_to_atom("host"++integer_to_list(X)), sendto({[Dst],Egress_port,Size,Data})
		end,
		
		% io:format("warning: ~p: ~p died! \n:  ",[Name,From]),  %performance ??
		{noreply, {Name,Egress_port,Host_name,Hosts,Tap}};

% default		
my_handle_info(_,State)-> {noreply,State}.


% Name= Name: message to tap:
my_handle_cast({Host_name,_Size,_Maxhops,_Mode,Payload},{Name,Egress_port,Host_name,Hosts,Tap})->	
	
	% io:format("~p: packet for the remote host\n",[Name]),
	tuncer:send(Tap, Payload),
	{noreply, {Name,Egress_port,Host_name,Hosts,Tap}};


my_handle_cast(_Msg, {Name,Egress_port,Host_name,Hosts,Tap})->
	
	% io:format("warning: ~p : default handle cast ",[Name]),
	{noreply, {Name,Egress_port,Host_name,Hosts,Tap}}.


sendto({Dsts,Egress_port,Size,Data})-> 
		 [gen_server:cast(global:whereis_name(Egress_port),{Dst,Size,1000,regular,Data}) || Dst<-Dsts].






%% TODO: delete these: 
ints_to_atom(List)->
    list_to_atom(ints_to_list(List,"host")).

ints_to_list([],Acc)->Acc;

ints_to_list([H|T],Acc) ->
    ints_to_list(T,Acc++"_"++integer_to_list2(H)).

parser(<<Dmac:6/binary,_Payload/binary>>,Data)->
	Dst_mac=binary_to_list(Dmac),
	Size=byte_size(Data),
	{Dst_mac,Size}.



integer_to_list2(I) when I<10-> "00"++integer_to_list(I);
integer_to_list2(I) when I<100-> "0"++integer_to_list(I);
integer_to_list2(I) -> integer_to_list(I).
       
		
		
