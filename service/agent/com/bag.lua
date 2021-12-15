local s = require "service"
local table_insert = table.insert

local gbag_com = {}


-- 生成背包格子
local function gen_bag_slot(idx)
    local data = {
        uid = idx,
        -- attach = nil
    }
    return data
end

-- 生成数量格子
local function gen_bag_slots(num)
    local data = {}
    for i = 1, num do
        table_insert(data, gen_bag_slot(i))
    end
    return data
end

-- 生产背包
local function gen_bag(uid, num)
    num = num or 20
    local data = {
        uid = uid,
        num = num,
        slots = gen_bag_slots(num)
    }
    return data
end

function gbag_com:gen_data_impl()
	s.data.bag = gen_bag()
end

return gbag_com