local skynet = require "skynet"
local socket = require "skynet.socket"
local runconfig = require "runconfig"

local s = require"service"

local tail_table_decode = {}

local str_unpack = function (msgstr)
	local msg = {}

	while true do
		local arg, rest = string.match(msgstr, "(.-),(.*)")
		if arg then
			msgstr = rest
			table.insert(msg, arg)
		else
			table.insert(msg, msgstr)
			break
		end	
	end

	return msg[1], msg
end

local process_msg = function (fd, msgstr)
	local cmd, msg = str_unpack(msgstr)
	skynet.error("recv " .. fd .. " [" .. cmd .. "] {" .. table.concat(msg, ",") .. "}")

	local conn = conns[fd]
	local playerid = conn.playerid
	--特殊断线重连
	if cmd == "reconnect" then
		process_reconnect(fd, msg)
		return
	end
	--尚未完成登录流程
	if not playerid then
		local node = skynet.getenv("node")
		local nodecfg = runconfig[node]
		local loginid = math.random(1, #nodecfg.login)
		local login = "login" .. loginid
		skynet.send(login, "lua", "client", fd, cmd, msg)
	--完成登录流程	
	else
		local gplayer = players[playerid]
		local agent = gplayer.agent
		skynet.send(agent, "lua", "client", cmd, msg)
	end	
end

local process_buff = function (fd, readbuff)
	while true do
		local msgstr, rest = string.match(readbuff, "(.-)\r\n(.*)")
		if msgstr then
			readbuff = rest
			process_msg(fd, msgstr)
		else
			return readbuff
		end	
	end
end

--每一条连接接收数据处理
--协议格式 cmd,arg1,arg2,...#
local recv_loop = function (fd)
	socket.start(fd)
	skynet.error("Socket connected " .. fd)
	local readbuff = ""
	while true do
		local recvstr = socket.read(fd)
		if recvstr then
			readbuff = readbuff .. recvstr
			readbuff = process_buff(fd, readbuff) --process_buff返回尚未处理的剩余数据
		else
			skynet.error("socket close " .. fd)
			disconnect(fd)
			socket.close(fd)
			return
		end
	end
end

--有新连接时
local connect = function (fd, addr)
	if closing then
		return
	end
	print("connect from " .. addr .. " " .. fd)
	local c = conn()
	conns[fd] = c
	c.fd = fd
	skynet.fork(recv_loop, fd) --开启协程
end

function tail_table_decode.start()
	local node = skynet.getenv("node")
	local nodecfg = runconfig[node]
	local port = nodecfg.gateway[s.id].port

	local listenfd = socket.listen("0.0.0.0", port)
	skynet.error("Listen socket :", "0.0.0.0", port)
	socket.start(listenfd, connect)
end

return tail_table_decode