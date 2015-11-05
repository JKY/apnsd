{application, 
	apnsd, 
	[
		{description, "Push Notification Service"},
		{vsn, "1.0.0"},
		{modules, [apnsd, apnsd_sup, apnsd_option, apnsd_channel, apnsd_dev, apnsd_pkt, apnsd_conn,apnsd_api, apnsd_trace, apnsd_util]},
		{registered, [apnsd]},
		{mod, {apnsd,[]}},
		{env, [ 
				{maxq, 128},
				{port, 1885},
				{db_host, localhost},
				{db_port, 27017},
				{db_usr, ""},
				{db_pwd, ""},
				{db_name, apnsd},
				{eth,"eth1"}
			  ]
		}
	]
}.
