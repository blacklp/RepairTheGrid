-module(monitor).

-export([init_monitor/3, global_monitoring/3]).

init_monitor(N, M, NumberOfTasks) -> 
	MonitorPid = spawn(monitor, global_monitoring, [NumberOfTasks, 0, 0]),
	io:format("Monitor ~p: The monitor has been created.\n", [MonitorPid]),
	List = [[Rows, Columns] || Rows <- lists:seq(1,N), Columns <- lists:seq(1,M)],
	lists:foreach(fun(X) -> {I, J} = lists:split(1, X),
							DevicePid = spawn(device, init_device, [I, J, MonitorPid]),
							io:format("Monitor ~p: Device with Pid ~p has been created.\n", [MonitorPid,DevicePid]),
							DevicePid ! {start},
							io:format("Monitor ~p: Device ~p ! {start}.\n", [MonitorPid, DevicePid])
							end, List),
	io:format("Monitor ~p: The devices have been created and started.\n", [MonitorPid]).
	
global_monitoring(NumberOfRemaining, NumberOfFailures, NumberOfFinished) ->
	io:format("Monitor is ready for receiving messages.\n"),
	receive
		{fail, I, J} -> % a new device must be created to subtitute the old one.
			io:format("Monitor ~p: receive {fail, ~p, ~p}\n", [self(), I, J]),
			DevicePid = spawn(device, init_device, [I, J, self()]),
			io:format("Monitor ~p: Device with Pid ~p has been created.\n", [self(), DevicePid]),
			DevicePid ! {start},
			global_monitoring(NumberOfRemaining, NumberOfFailures+1, NumberOfFinished);
		{finish, I, J, Pid} -> 
			% it can be restarted depending on NumberOfRemaining
			if NumberOfRemaining == 1 ->
				io:format("Monitor ~p: receive {finish, ~p, ~p, ~p} & this is the LAST task.\n", [self(), I, J, Pid]),
				exit(Pid, normal),
			    global_monitoring(NumberOfRemaining-1, NumberOfFailures, NumberOfFinished+1);
			   NumberOfRemaining == 0 ->
				io:format("Monitor ~p: receive {finish, ~p, ~p, ~p} and NO more tasks to do.\n", [self(), I, J, Pid]),
				exit(Pid, normal),
			    global_monitoring(NumberOfRemaining, NumberOfFailures, NumberOfFinished);
			   NumberOfRemaining > 1 ->
				io:format("Monitor ~p: receive {finish, ~p, ~p, ~p} and more tasks to do.\n", [self(), I, J, Pid]),
				Pid ! {restart},
				global_monitoring(NumberOfRemaining-1, NumberOfFailures, NumberOfFinished+1)
			end;
		{statistics} -> % print number of failures and number of finished tasks
			io:format("Monitor ~p: receive {statistics}\n", [self()]),
			io:format("Number of failures: ~p.\n", [NumberOfFailures]),
			io:format("Number of finished tasks: ~p\n", [NumberOfFinished]),
			global_monitoring(NumberOfRemaining, NumberOfFailures, NumberOfFinished)
	end.
