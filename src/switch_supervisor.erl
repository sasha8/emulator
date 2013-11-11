-module(switch_supervisor).
-behaviour(supervisor).
-export([start_link/1,init/1]).

start_link({switch, Switch_name, Fwd_table, {ingress,Ingress},{egress,Egress}})->
	supervisor:start_link({global,list_to_atom(atom_to_list(Switch_name)++"_supevisor")},switch_supervisor,[{Switch_name,Fwd_table,Ingress,Egress}]).
	
init([{Switch_name,Fwd_table,Ingress,Egress}])->

	Name=list_to_atom(atom_to_list(Switch_name)++"_supevisor"),
    io:fwrite("switch_supervisor ~s : init\n",[Name]),
	
	Ingress_children=[{element(1,X),{ingress_port, start_link, [{element(1,X),Fwd_table}]},transient,2000,worker,[ingress_port]}|| X<-Ingress],
	Egress_children=[{element(1,X),{egress_port, start_link, [X]},transient,2000,worker,[egress_port]}|| X<-Egress],	
	{ok,{{one_for_one,1,1},Ingress_children++Egress_children}}.
	
	
