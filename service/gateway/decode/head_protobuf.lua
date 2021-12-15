local skynet = require "skynet"
local socket = require "skynet.socket"
local runconfig = require "runconfig"
local pb = require "protobuf"

pb.register_file("./service/proto/all.bytes")

local s = require"service"

local head_json_decode = {}

local proto_id_map = nil
local get_proto_name = function (msgid)
	if not proto_id_map then
		local file = io.open("./service/proto/message_define.bytes", "rb")
		local source = file:read("*a")
		proto_id_map = load(source)()
		file:close()
		source = nil
	end
	return proto_id_map[msgid]
end

local encode_protobuf_msg = function(msgid, data)
	local msg_name = get_proto_name(msgid)						-- 根据协议id获取协议名
    local stringbuffer =  pb.encode(msg_name, data)         	-- 根据协议名和协议数据  protobuf序列化 返回lua_string
    local body = string.pack(">I2s2", msgid, stringbuffer)      -- 打包包体 协议id + 协议数据
    local head = string.pack(">I2", #body)                    	-- 打包包体长度
    return head .. body                                       	-- 包体长度 + 协议id + 协议数据
end

local decode_protobuf_msg = function (msgstr)
	local msgid, stringbuffer = string.unpack(">I2s2", msgstr)	-- 解包包体 协议id + 协议数据
	local proto_name = get_proto_name(msgid)					-- 根据协议id获取协议名
    local body = pb.decode(proto_name, stringbuffer)			-- 根据协议名和协议数据  protobuf反序列化  返回lua_table

	return proto_name, body
end

local process_msg = function (fd, msgstr)
	local cmd, msg = decode_protobuf_msg(msgstr)
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