local skynet = require "skynet"
local skynet_manager = require "skynet.manager"
local cluster = require "skynet.cluster"
local runconfig = require "runconfig"

skynet.start(function ()
	--初始化
	local mynode = skynet.getenv("node")
	local nodecfg = runconfig[mynode]
	--集群
	cluster.reload(runconfig.cluster)
	cluster.open(mynode)
	--nodemgr
	local nodemgr = skynet.newservice("nodemgr", "nodemgr", 0)
	skynet.name("nodemgr", nodemgr)
	--gate
	for i,v in pairs(nodecfg.gateway or {}) do
		local srv = skynet.newservice("gateway", "gateway", i)
		skynet.name("gateway"..i, srv)
	end
	--login
	for i,v in pairs(nodecfg.login or {}) do
		local srv = skynet.newservice("login", "login", i)
		skynet.name("login"..i, srv)
	end
	--agentmgr
	local anode = runconfig.agentmgr.node
	if mynode == anode then
		local srv = skynet.newservice("agentmgr", "agentmgr", 0)
		skynet.name("agentmgr", srv)
	else
		local proxy = cluster.proxy(anode, "agentmgr")
		skynet.name("agentmgr", proxy)
	end
	--scene
	for _, sid in pairs(runconfig.scene[mynode] or {}) do --sid->sceneid
		local srv = skynet.newservice("scene", "scene", sid)
		skynet.name("scene"..sid, srv)
	end
	--admin
	local admin = skynet.newservice("admin", "admin", 0)
	skynet.name("admin", admin)
	--退出自身
	skynet.exit()
end)
