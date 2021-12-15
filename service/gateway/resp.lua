local skynet = require "skynet"
local socket = require "skynet.socket"
local s = require "service"

local str_pack = function (cmd, msg)
	return table.concat(msg, ",") .. "\r\n"
end

--用于login服务的消息转发，功能是将消息发送到指定fd的客户端
s.resp.send_by_fd = function (source, fd, msg)
	if not conns[fd] then
		return
	end

	local buff = str_pack(msg[1], msg)
	skynet.error("Send " .. fd .. " [" .. msg[1] .. "] {" .. table.concat(msg, ",") .. "}")
	socket.write(fd, buff)
end

--用于agent的消息转发，功能是将消息发送给指定玩家id的客户端
s.resp.send = function (source, playerid, msg)
	local gplayer = players[playerid]
	if gplayer == nil then
		return
	end
	local c = gplayer.conn
	if c == nil then
		table.insert(gplayer.msgcache, msg)
		local len = #gplayer.msgcache
		--为避免占用过多内存，在缓存了大于500条消息后，触发下线逻辑，不允许重连
		if len > 500 then
			skynet.call("agentmgr", "lua", "reqkick", playerid, "gate消息缓存过多")
		end
		return
	end	

	s.resp.send_by_fd(nil, c.fd, msg)
end

--完成登录后，login通知agent，让它把客户端连接和新agent关联起来
s.resp.sure_agent = function (source, fd, playerid, agent)
	local conn = conns[fd]
	if not conn then --登录过程中已下线
		skynet.call("agentmgr", "lua", "reqkick", playerid, "未完成登录即下线")	
		return false
	end

	conn.playerid = playerid
	local gplayer = gateplayer()
	gplayer.playerid = playerid
	gplayer.agent = agent
	gplayer.conn = conn
	players[playerid] = gplayer

	return true, gplayer.key
end

--agentmgr把玩家踢下线，删掉玩家对应conn和gateplayer对象
s.resp.kick = function (source, playerid)
	local gplayer = players[playerid]
	if not gplayer then
		return
	end
	players[playerid] = nil
	
	local c = gplayer.conn
	if not c then
		return
	end
	conns[c.fd] = nil
	
	disconnect(c.fd)
	socket.close(c.fd)
end

--不再接收新连接
s.resp.shutdown = function ()
	closing = true
end

