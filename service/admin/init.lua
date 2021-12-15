local skynet = require "skynet"
local socket = require "skynet.socket"
local s = require "service"
local runconfig = require "runconfig"
require "skynet.manager"


function shutdown_gate()
	local mynode = skynet.getenv("node")
	for node, _ in pairs(runconfig.cluster) do
		if node == mynode then
			local nodecfg = runconfig[node]
			for k,v in pairs(nodecfg.gateway) do
				local name = "gateway" .. k
				s.call(node, name, "shutdown")
			end
		end
	end
end

--通知agentmgr，通过每次踢掉一定数量玩家实现缓慢把所有玩家踢下线(因为玩家下线时需要保存数据，如果成千上万的玩家同时下线，会给数据库造成很大压力。服务端要“缓缓”地把玩家踢下线才行)
function shutdown_agent()
	local anode = runconfig.agentmgr.node
	while true do
		local online_num = s.call(anode, "agentmgr", "shutdown", 3) --最后一个参数代表要踢下线3人，返回值online_num表示剩余的在线人数
		if online_num <= 0 then
			break
		end
		skynet.sleep(100)
	end
end

function stop()
	--1. 阻止新玩家连入
	shutdown_gate()
	--2. 让所有玩家下线
	shutdown_agent()
	--3. 保存全局数据(如公会、世界Boss、排行榜等)
	--TODO
	--4.关闭节点
	skynet.abort() --skynet.abort是结束skynet进程的方法
	return "ok"
end

function connect(fd, addr)
	socket.start(fd)
	socket.write(fd, "Please enter cmd\r\n")
	local cmd = socket.readline(fd, "\r\n")
	if cmd == "stop" then
		--关闭服务器
		stop() 
	else
		--预留命令
		--如给玩家发送邮件、发访道具等
	end
end

s.init = function ()
	local listenfd = socket.listen("0.0.0.0", 9999)
	socket.start(listenfd, connect)
end

s.start(...)