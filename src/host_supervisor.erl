-module(host_supervisor).
-behaviour(supervisor).
-export([start_link/2,init/1]).

start_link({host, Host_supervisor_name, Ingress_name, {egress,[{Egress_name,Next_hop,Parm}]}},Hosts)->
	supervisor:start_link({global,list_to_atom(atom_to_list(Host_supervisor_name)++"_supevisor")},host_supervisor,[{Host_supervisor_name,Ingress_name,Egress_name,Hosts,[{Egress_name,Next_hop,Parm}]}]).

init([{Host_supervisor_name,Ingress_name,Egress_name,Hosts,Egress}])->
	
	Name=list_to_atom(atom_to_list(Host_supervisor_name)++"_supevisor"),
    io:fwrite("host_supervisor ~s : init\n",[Name]),
	
	Ingress_children=[{ingress,{host_ingress_port, start_link, [{Ingress_name,Egress_name,Host_supervisor_name},Hosts]},transient,2000,worker,[host_ingress_port]}],
	Egress_children=[{element(1,X),{egress_port, start_link, [X]},transient,2000,worker,[egress_port]}|| X<-Egress],	
	{ok,{{one_for_one,1,1},Ingress_children ++ Egress_children}}.
	
	
	%{host, bode,bode_ingress, {egress,{bode_to_switch1}}}	
	%{egress,[{switch1_egress1,host1,{0,1000000,0}},{switch1_egress2,host2,{0,1000000,0}}]}
	%start_link({switch, Switch_name, Fwd_table, {ingress,Ingress},{egress,Egress}})->
