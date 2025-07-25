--[[ Services ]]
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

--//TODO Framework
local Framework = require(ReplicatedStorage.Shared.Framework)
local print, pcall = Framework.log, Framework.pcall

--[[ Vars ]]
local module = {}
local bParent = workspace.BridgeStart

local barrier = bParent:WaitForChild("Barrier")
local block = barrier.Block

local textLabel = barrier.front:WaitForChild('text')

--[[ Functions ]]

--//TODO Countdown then open the bridge
function module.bCountdown(timer: number, txt: string)
	txt = txt or 'Countdown:'
	local countdownEnd = Instance.new('BindableEvent')
	
	pcall(function()
		task.spawn(function()
			repeat
				module.bWrite(txt .." "..tostring(timer))
				timer -= 1

				task.wait(1)
			until timer < 0
			module.bToggle(false)
			countdownEnd:Fire()
		end)
	end)
	
	return countdownEnd
end

--//TODO Write text on barrier
function module.bWrite(txt: string)
	textLabel.Text = tostring(txt)
end

--//TODO Open/Close barrier
function module.bToggle(open: boolean)
	if open then
		barrier.Parent = bParent
		
	elseif open == false then
		barrier.Parent = ServerStorage.Placeholder
	end
end

return module
