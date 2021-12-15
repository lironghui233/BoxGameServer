local skynet = require "skynet"
local s = require "service"

s.client = {}

s.client.login_req = function (fd, msg, source)
	local playerid = tonumber(msg.id)
	local pw = tonumber(msg.pw)
	local gate  = source
	node = skynet.getenv("node")
	--检验用户名和密码
	if pw ~= 123 then
		return {"login", 1, "密码错误"}
	end
	--发给agentmgr
	local isok, agent = skynet.call("agentmgr", "lua", "reqlogin", playerid, node, gate)
	if not isok then
		return {"login", 1, "请求mgr失败"}
	end
	--回应gate
	local isok, key = skynet.call(gate, "lua", "sure_agent", fd, playerid, agent)
	if not isok then
		return {"login", 1, "gate注册失败"}
	end
	skynet.error("login succ" .. playerid)
	return {"login", 0, key, "登陆成功"}
end


s.resp.client = function (source, fd, cmd, msg)
	if s.client[cmd] then
		local ret_msg = s.client[cmd](fd, msg, source)
		skynet.send(source, "lua", "send_by_fd", fd, ret_msg)
	else
		skynet.error("s.resp.client fail", cmd)
	end
end

s.start(...)