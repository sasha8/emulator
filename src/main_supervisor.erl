-module(main_supervisor).
-behaviour(supervisor).
-export([start_link/0, start_link/1, init/1]).


start_link()->
	io:fwrite("hello world\n"),
    start_link("tree.cfg.txt").
    
start_link(Cfg_file)->
	supervisor:start_link({global,main_supervisor},main_supervisor,[Cfg_file]).

init([Cfg_file])->
    % io:fwrite("main_supervisor : init, Cfg file - ~p\n",[Cfg_file]),
	% Switches=parser(),
	{ok, [Switches]}=file:consult(Cfg_file),
	Hosts=[element(2,Y) || Y<-Switches, element(1,Y)==host],
	Switch_supervisors=[{element(2,X),{switch_supervisor, start_link, [X]},transient,2000,supervisor,[switch_supervisor]}|| X<-Switches, element(1,X)==switch],
	Host_supervisors=[{element(2,Y),{host_supervisor,start_link, [Y,Hosts]},transient, 2000,supervisor, [host_supervisor]}   || Y<-Switches, element(1,Y)==host],
	{ok,{{one_for_one,1,1},Switch_supervisors ++ Host_supervisors}}.
	
	
% parser()->	
% 			[{switch,switch1,
%          {dict,2,16,16,8,80,48,
%                {[],[],[],[],[],[],[],[],[],[],[],[],[],[],[],[]},
%                {{[],
%                  [[host1|switch1_to_host1]],
%                  [[host2|switch1_to_host2]],
%                  [],[],[],[],[],[],[],[],[],[],[],[],[]}}},
%          {ingress,[{switch1_ingress}]},
%          {egress,[{switch1_to_host1,host1_ingress,{1,1,0}},
%                   {switch1_to_host2,host2_ingress,{1,1,0}}]}},
%  {host,host1,host1_ingress,
%        {egress,[{host1_to_switch1,switch1_ingress,{1,1,0}}]}},
%  {host,host2,host2_ingress,
%        {egress,[{host2_to_switch1,switch1_ingress,{1,1,0}}]}}].
% 			
% 			%Temp=dict:new(),
% 			%Temp1=dict:append(host1,switch1_egress1,Temp),
% 			%Fwd_table_switch1=dict:append(host2,switch1_egress2,Temp1),
% 			%Switch1={switch, switch1, Fwd_table_switch1,{ingress,[{switch1_ingress1},{switch1_ingress2}]},{egress,[{switch1_egress1,host1,{0,1000000,0}},{switch1_egress2,host2,{0,1000000,0}}]}}, % {Lat,BW,Drop_rate}
% 			%[Switch1].
% to compile run:
% c(main_supervisor),c(switch_supervisor),c(host_supervisor),c(ingress_port),c(egress_port),c(host_ingress_port).
		
 
			 
% message format:
% {Dst,Size,Maxhops,Mode,Payload}
% Dst - final destination 
% Size - message size
% Maxhopst - message time to live
% Mode: 
%		0 - regular
%		1 - debug(print message), and measure(collect time stemp on the way).
% Payload:
% 			{Src,Data,Time_list} - Src destination and the data in the message
%			Time_list - list of time stemp tuples: {<port_name>,erlang:now} (when Mode is 1, else empty list)    
