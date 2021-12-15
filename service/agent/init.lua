local skynet = require "skynet"
local s = require "service"

local db = nil

s.client = {}
s.gate = nil

require "scene"
require "activity"
require "data"
require ".logic.init"

s.client.work = function (msg)
	s.data.coin = s.data.coin + 1
	return {"work", s.data.coin}
end

s.resp.client = function (source, cmd, msg)
	s.gate = source
	if s.client[cmd] then
		local ret_msg = s.client[cmd](msg, source)
		if ret_msg then
			skynet.send(source, "lua", "send", s.id, ret_msg)
		end
	else
		skynet.error("s.resp.client fail", cmd)
	end
end

s.resp.kick = function ()
	s.leave_scene()
	--在此处保存角色数据
	save_all_data()
end

s.resp.exit = function ()
	skynet.exit()
end

--scene调用agent的send给客户端发消息
s.resp.send = function (source, msg)
	skynet.send(s.gate, "lua", "send", s.id, msg)
end

s.init = function ()
	--db
	connectdb()
	--在此处加载角色数据
	load_all_data()
	--是否当天第一次登录
	is_first_login_day()
	--agent update
	update()
end

s.start(...)