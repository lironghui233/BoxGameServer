local skynet = require "skynet"
local socket = require "skynet.socket"
local runconfig = require "runconfig"
local cjson = require "cjson"

local s = require"service"

local head_json_decode = {}

local function json_pack(cmd, msg)
	msg._cmd = cmd
	local body = cjson.encode(msg) --协议体字节流
	local namelen = string.len(cmd) --协议名长度
	local bodylen = string.len(body) --协议体长度
	local len = namelen + bodylen + 2 --协议总长度
	local format = string.format("> i2 i2 c%d c%d", namelen, bodylen)
	local buff = string.pack(format, len, namelen, cmd, body)
	return buff
end

local function json_unpack(buff) 
	local len = string.len(buff)
	
	local namelen_format = string.format("> i2 c%d", len-2)
	local namelen, other = string.unpack(namelen_format, buff)
	local bodylen = len-2-namelen
	local format = string.format("> c%d c%d", namelen, bodylen)
	local cmd, bodybuff = string.unpack(format, other)

	local isok, msg = pcall(cjson.decode, bodybuff)
	if not isok or not msg or not msg._cmd or not cmd == msg._cmd then
		print("error")
		return
	end

	return cmd, msg
end

local process_msg = function (fd, msgstr)
	local cmd, msg = json_unpack(msgstr)
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

local get_complete_msg = function(buf)
	if not buf or buf == "" or #buf == o then
		return nil
	end

    --取得头部2字节的内容，此为后续数据的长度
    local s = buf:byte(1) * 256 + buf:byte(2)

    --不足以一个包
    if #buf < (s+2) then
        return nil
    end

    --完整包
    return buf:sub(3, 2+s), buf:sub(3+s, #buf)
end

local process_buff = function (fd, readbuff)
	while true do
		local msgstr, rest = get_complete_msg(readbuff)
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

function head_json_decode.start()
	local node = skynet.getenv("node")
	local nodecfg = runconfig[node]
	local port = nodecfg.gateway[s.id].port

	local listenfd = socket.listen("0.0.0.0", port)
	skynet.error("Listen socket :", "0.0.0.0", port)
	socket.start(listenfd, connect)
end

return head_json_decode