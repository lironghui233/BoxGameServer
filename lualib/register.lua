

local M = {}

M.model = {}

function M.register_model(model_type, func_list)
	M.model[model_type] = {}
	for k,v in pairs(func_list or {}) do
		M.model[model_type][k] = v
	end
end

function M.get_model(model_type)
	return M.model[model_type]
end

function M.get_model_func(model_type, func_name)
	return M.model[model_type] and M.model[model_type][func_name] or nil
end

function M.register_model_by_conf(model_type, base_conf_path, model_conf_list)
	M.model[model_type] = {}
	for k,v in pairs(model_conf_list) do
		local conf_path = base_conf_path .. v .. ".lua"
		local file = assert(io.open(conf_path, "rb"))
		local source = file:read("*a")
		local tlb = load(source)()
		file:close()
		source = nil
		for func_name, func in pairs(tlb) do
			M.model[model_type][func_name] = func
		end
	end	
end

return M