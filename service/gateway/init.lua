local skynet = require "skynet"
local register = require "register"

local runconfig = require "runconfig"

local s = require "service"


local closing = false --是否正在关闭服务器，不再接受新连接
conns = {} --[fd] = conn
players = {} --[playerid] = gateplayer

require "resp"
require ".decode.init"

--连接类
function conn()
	local m = {
		fd = nil, --socketfd
		playerid = nil,
	}
	return m
end

--玩家类
function gateplayer()
	local m = {
		playerid = nil,
		agent = nil,
		conn = nil,
		
		--断线重连相关
		key = math.random(1, 999999999), --key下发给客户端，重连时发给gate，通过验证证明是重连的客户端
		lost_conn_time = nil, --最后一次断开连接的时间
		msgcache = {}, --=断线期间未发送给客户端的消息缓存
	}
	return m
end

function process_reconnect(fd, msg)
	local playerid = tonumber(msg[2])
	local key = tonumber(msg[3])
	--conn
	local conn = conns[fd]
	if not conn then
		skynet.error("reconnect fail, conn not exist")
		return
	end
	--gplayer
	local gplayer = players[playerid]
	if not gplayer then
		skynet.error("reconnect fail, player not exist")
		return
	end
	if gplayer.conn then
		skynet.error("reconnect fail, conn not break")
		return
	end
	if gplayer.key ~= key then
		skynet.error("reconnect fail, key error")
		return
	end
	--绑定
	gplayer.conn = conn
	conn.playerid = playerid
	--回应
	s.resp.send_by_fd(nil, fd, {"reconnect, 0"})
	--发送缓存消息
	for i, cmsg in ipairs(gplayer.msgcache) do
		s.resp.send_by_fd(nil, fd, cmsg)
	end
end

 function disconnect(fd)
	local c = conns[fd]
	if not c then
		return 
	end

	local playerid = c.playerid
	--还没完成登录
	if not playerid then
		return
	--已在游戏中	
	else
		local gplayer = players[playerid]
		gplayer.conn = nil --掉线时仅仅取消玩家对象(gplayer)与旧连接(conn)的关联

		--为了防止客户端不再发起重连导致的资源占用，程序会开启一个定时器(skynet.timeout)，若超过时间后依然是断线状态(if gplayer.conn == nil)，则向agentmgr请求下线
		skynet.timeout(300*100, function ()
			if gplayer.conn ~= nil then
				return
			end
			players[playerid] = nil
			local reason = "断线超时"
			skynet.call("agentmgr", "lua", "reqkick", playerid, reason)
		end)
	end
end

function s.init()
	-- local func_name = "tail_table"
	-- local func_name = "head_json"
	local func_name = "head_protobuf"
	local model_func = register.get_model_func("decode_model", func_name)
	-- local isok = pcall(model_func)
	model_func()
	-- print("?????????!!!!! ", isok)
	-- if not isok then
	-- 	skynet.error("gateway init error: ", func_name)
	-- end
end

s.start(...) -- "..."代表可变参数，在用skynet.newservice启动服务时，可以传递参数给它