local pb = require "protobuf"
local mysql = require "skynet.db.mysql"

local s = require "service"
local com = require "com.init"

pb.register_file("./storage/playerdata.pb")

local db

function connectdb()
	--连接数据库
	db = assert(mysql.connect({
		host="192.168.184.130",
		port=3306,
		database="message_board",
		user="root",
		password="123456",
		max_packet_size=1024*1024,
		on_connect=nil
	}))

	--com初始化
	com.start()
end

function create_new_data_model()
	--创角(按照功能模块划分的玩家数据)
	local playerdata = {
		--基本信息
		baseinfo = {
			playerid = s.id,
			hp = 100,
			coin = 97,
			name = "Tiny",
			level = 3,
			last_login_time = os.time(),
		}, 
		--背包
		bag = {
			slots = {
				{uid=1, attach={uid = 1001, num = 10}},
				{uid=2, attach={uid = 1001, num = 10}},
				{uid=3, attach={uid = 1001, num = 10}},
			}
		}, 
		--任务
		task = {
			tasks = {
				{id=1, is_finish=true},
				{id=2, is_finish=true},
			}
		}, 
		--朋友
		friend = {
			friends = {
				{id=1001},
				{id=1002},
			}
		}, 
		--邮件
		mail = {
			mails = {
				{id=1,content="aaa"},
				{id=2,content="bbb"},
			}
		}, 
		--成就
		achieve = {
			achieves = {
				{id=1},
				{id=2},
			}
		}, 
		--称号
		title = {
			titles = {
				{id=1},
				{id=2},
			}
		}, 
	}
	for k,v in pairs(playerdata) do
		local table_name = k
		local table_value = v
		--序列化
		local data = pb.encode("playerdata."..table_name, table_value)
		--存入数据库
		local sql = string.format("insert into %s(playerid, data) values (%d, %s)", table_name, s.id, mysql.quote_sql_str(data)) --由于变量data是二进制数据，因此，拼接成SQL语句时，需用mysql.quote_sql_str做转换。
		local res = db:query(sql)
		if res.err then
			print("[create_new_data_model playerdata] " .. k ..  " error:" .. res.err)
		else
			print("ok")
		end
	end
end

function save_all_data()
	for k,v in pairs(s.data) do
		local table_name = k
		local table_value = v 
		--序列化
		local data = pb.encode("playerdata."..table_name, table_value)
		--存入数据库
		local sql = string.format("update %s set playerid = %d, data = %s", table_name, s.id, mysql.quote_sql_str(data)) --由于变量data是二进制数据，因此，拼接成SQL语句时，需用mysql.quote_sql_str做转换。
		local res = db:query(sql)
		if res.err then
			print("[save_all_data playerdata] " .. k ..  " error:" .. res.err)
		else
			print("ok")
		end
	end
end

function load_all_data()
	s.data = {
		--基本信息
		baseinfo = {}, 
		--背包
		bag = {}, 
		--任务
		task = {}, 
		--朋友
		friend = {}, 
		--邮件
		mail = {}, 
		--成就
		achieve = {}, 
		--称号
		title = {}, 
	}

	for k,v in pairs(s.data) do
		local table_name = k
		local table_value = v
		local sql = string.format("select * from %s where playerid = %d", table_name, s.id)
		local res = db:query(sql)
		if res and res[1] then
			--反序列化
			local data = res[1].data
			local udata = pb.decode("playerdata."..table_name, data)
			if not udata then
				print("[load_all_data playerdata] " .. k ..  " error:" .. res.err)
			else
				s.data[table_name] = udata
			end
		else
			print("error" .. k)
		end
	end
end