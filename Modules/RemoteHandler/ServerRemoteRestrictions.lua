--// Services
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Staff = require(ServerScriptService.GameData.Staff)

local module = {}

--// Module functions

function module.adminOnly()
	return function (p: Player, data: {any})
		return table.find(Staff.Admins, p.UserId) ~= nil
	end
end

function module.teamOnly(t: {string})
	return function (p: Player, data: {any})
		for _, v in t do
			if not Staff[v] then
				warn('RR :: Unknown staff team: ', v)
			end
			
			if table.find(Staff[v], p.UserId) ~= nil then
				return true
			end
		end
		
		return false
	end
end

-- Only allows players with the specified UserId
function module.Whitelisted(id: number)
	return function(p: Player, data: {any})
		return p.UserId == id
	end
end

-- Only allows data with correct types
function module.typeChecking(t: {[string]: string})
	return function (p: Player, data: {any})
		local t = table.clone(t)
		for i, v in data do
			if not t[i] then
				warn('RR :: Unknown argument', i, t, data)
			elseif typeof(v) ~= t[i] then
				warn('RR :: Type checking failed', t, data)
				return false
			end
		end
		
		return true
	end
end

-- Only allows RIGHT AMOUNT of data with correct types
function module.typeStrict(t: {[string]: string})
	return function (p: Player, data: {any})
		local t = table.clone(t)
		for i, v in data do
			if ( not t[i] ) or ( typeof(v) ~= t[i] ) then
				warn('RR :: Type stricted', t, data)
				return false
			end
			
			t[i] = nil
		end
		
		if next(t) then
			warn('RR :: Type overflow', t, data)
			return false
		end
		
		return true
	end
end

function module.forceData(t: {[string]: string})
	local t = table.clone(t)
	return function (p: Player, data: {any})
		for i, v in t do
			if not data[i] or data[i] ~= t[i] then
				return false
			end
		end
		
		return true
	end
end

return module
