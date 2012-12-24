-module(device).
-export([start/3, init_device/3]).

init_device(I, J, MonitorPid) -> 
	receive
		{start} -> io:format("Device ~p: Started at ~p, ~p.\n", [self(), I, J]), start(I, J, MonitorPid);
		{restart} -> io:format("Device ~p: Restated at ~p, ~p.\n", [self(), I, J]), start(I, J, MonitorPid)
	end.

start(I, J, MonitorPid) -> 
	Ran = crypto:rand_uniform(0, 3),
	if Ran == 0 -> io:format("Device ~p: monitor ~p!{fail, ~p, ~p}.\n", [self(), MonitorPid, I, J]), 
				   MonitorPid ! {fail, I, J}, 
				   exit(self(), kill);
	   Ran == 1 -> io:format("Device ~p: monitor ~p!{finish, ~p, ~p, Pid}.\n", [self(), MonitorPid, I, J]), 
				   MonitorPid ! {finish, I, J, self()},
				   init_device(I, J, MonitorPid);
	   Ran == 2 -> io:format("Device ~p: monitor ~p!{statistics}.\n", [self(), MonitorPid]), 
				   MonitorPid ! {statistics},
				   start(I, J, MonitorPid)
	end.