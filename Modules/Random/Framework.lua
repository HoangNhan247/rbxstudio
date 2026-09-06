--// Services
local module = {}

--// Module functions
function module.removeFromTable(t: {any}, v: any): boolean
	local pos = table.find(t, v)
	if pos then
		table.remove(t, pos)
		return true
	else
		return false
	end
end

function module.deepCopy(t: {any})
	if (t and typeof(t) == 'table') then
		local clone = table.clone(t) 

		for key, value in t do
			if type(value) == "table" then
				clone[key] = module.deepCopy(value)
			end
		end

		return clone
	else
		return nil
	end
end

function module.inTable(t: {any}, v: any)
	return table.find(t, v) ~= nil
end

function module.typeCheck(data: {any}, types: {[string]: string})
	for key, value in types do
		if data[key] then
			if typeof(data[key]) ~= string.lower(types[key]) then
				warn('FW :: Invalid type', data, types)
				return false
			end
		else
			warn('FW :: Missing key', data, types)
			return false
		end
	end
	
	return true
end

return module
