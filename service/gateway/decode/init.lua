local tail_table = require "decode.tail_table"
local head_json = require "decode.head_json"
local head_protobuf = require "decode.head_protobuf"
local register = require "register"

local func_mapping_conf = {
	["tail_table"] = tail_table.start,
	["head_json"] = head_json.start,
	["head_protobuf"] = head_protobuf.start,
}

register.register_model("decode_model", func_mapping_conf)

