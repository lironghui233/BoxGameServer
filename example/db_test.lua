local skynet = require "skynet"
local mysql = require "skynet.db.mysql"
local pb = require "protobuf"

local db = nil

--创角
function test()
	pb.register_file("../storage/playerdata.pb")
	--创角(按照功能模块划分的玩家数据)
	local playerdata = {
		baseinfo = {
			playerid = 109,
			coin = 97,
			name = "Tiny",
			level = 3,
			last_login_time = os.time(),
		}, --基本信息
		bag = {}, --背包
		task = {}, --任务
		friend = {}, --朋友
		mail = {}, --邮件
		achieve = {}, --成就
		title = {}, --称号
	}
	--序列化
	local data = pb.encode("playerdata.BaseInfo", playerdata.baseinfo)
	print("data len:" .. string.len(data))
	--存入数据库
	local sql = string.format("insert into baseinfo(playerid, data) values (%d, %s)", 109, mysql.quote_sql_str(data)) --由于变量data是二进制数据，因此，拼接成SQL语句时，需用mysql.quote_sql_str做转换。
	local res = db:query(sql)
	--查看存储结果
	if res.err then
		print("error:" .. res.err)
	else
		print("ok")
	end
end

--读取角色数据
function test2()
	pb.register_file("../storage/playerdata.pb")
	--读取数据库（忽略读取失败的情况）
	local sql = string.format("select * from baseinfo where playerid = 109")
	local res = db:query(sql)
	--反序列化
	local data = res[1].data
	print("data len:" .. string.len(data))
	local udata = pb.decode("playerdata.BaseInfo", data)
	if not udata then
		print("error")
		return false
	end
	--输出
	local playerdata = {}
	playerdata.baseinfo = udata
	print("coin:" .. playerdata.baseinfo.coin)
	print("name:" .. playerdata.baseinfo.name)
	print("time:" .. playerdata.baseinfo.last_login_time)
	print("skin:" .. playerdata.baseinfo.skin)
end

skynet.start(function ()
	--连接数据库
	db = mysql.connect({
		host="192.168.184.130",
		port=3306,
		database="message_board",
		user="root",
		password="123456",
		max_packet_size=1024*1024,
		on_connect=nil
	})

	-- test()
	test2()
end)