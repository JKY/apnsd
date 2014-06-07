{application, 
	apnsd, 
	[
		{description, "Android Push Notification Service"},
		{vsn, "1.0.0"},
		{modules, [apnsd, apnsd_sup, apnsd_option, apnsd_channel, apnsd_dev, apnsd_pkt, apnsd_conn,apnsd_console, apnsd_trace, apnsd_util]},
		{registered, [apnsd]},
		{mod, {apnsd,[]}},
		{env, [ 
				{port, 1885},
	                   	{mc, 128},
				{db_host, localhost},
				{db_port, 27017},
				{db_usr, "root"},
				{db_pwd, "root"},
				{db_name, apnsd},
				{eth,"eth1"}
			  ]
		}
	]
}.
