--[[ Services ]]
local MarketplaceService = game:GetService("MarketplaceService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local Framework = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Framework"))

--[[ Vars ]]
local module = {}
local uiSavedProperties = {}

--[[ Functions ]]

function regFrameProperty(fName: string, fProperty: string, fValue: any)
	if not uiSavedProperties[fName] then
		uiSavedProperties[fName] = {fProperty = fValue}
	else
		print(string.format('Duplicate property (%s)', fName))
	end
end

function fetchFrameProperty(fName: string, fProperty: string)
	if uiSavedProperties[fName] then
		return uiSavedProperties[fName][fProperty]
	else
		print(string.format('Property doesnt exist (%s)', fName))
	end
end

--// Module functions

--//TODO UI Buttons

function module.buttonClick(b: GuiButton, func: () -> ())
	b.MouseButton1Click:Connect(function()
		Framework:play('UI', 'button_click')
		func()
	end)
end

function module.buttonPromptPurchase(b: GuiButton, player: Player, productType: string, productId: number)
	if productType == 'gamepass' then
		b.MouseButton1Click:Connect(function()
			Framework:promptGamepass(player, productId)
		end)
	elseif productType == 'product' then
		b.MouseButton1Click:Connect(function()
			Framework:promptDevProduct(player, productId)
		end)
	end
end

function module.buttonPlrKick()
	local b = script:WaitForChild('kick'):Clone()
	b.MouseEnter:Connect(function()
		module:tween(b, {BackgroundTransparency = 0, TextTransparency = 0}, TweenInfo.new(.3))
	end)
	b.MouseLeave:Connect(function()
		module:tween(b, {BackgroundTransparency = 1, TextTransparency = 1}, TweenInfo.new(.3))
	end)
	
	return b
end

--//TODO UI Frames
function module.frameVisible(show: Frame, hide: Frame)
	if show == hide then return end
	
	if show then
		show.Visible = true
	end
	if hide then
		hide.Visible = false
	end
end

function module.frameToggle(frame: Frame)
	frame.Visible = not frame.Visible
end

function module.closeAllParentFrame(parent: any)
	for _, child in pairs(parent:GetChildren()) do
		if child:IsA('Frame') then
			child.Visible = false
		end
	end
end

function module.clearScrollingFrameList(scroll: ScrollingFrame, instanceName: string)
	if instanceName then
		for _, instance in pairs(scroll:GetChildren()) do
			if instance.Name == instanceName then
				instance:Destroy()
			end
		end
	elseif not instanceName then
		for _, instance in pairs(scroll:GetChildren()) do
			if instance:IsA('GuiObject') then
				instance:Destroy()
			end
		end
	end
end

--//TODO UI Images
function module.playerIcon(plr: Player, size: number)
	return string.format("rbxthumb://type=AvatarHeadShot&id=%s&w=%s&h=%s", tostring(size))
end

--//TODO UI Tweening
function module.createTween(frame: Frame, properties: {[string]: any}, origin: {[string]: any}, info: TweenInfo)
	info = info or TweenInfo.new(.25)
	
	if properties then
		local function tween(trigger: boolean)
			if trigger then
				TweenService:Create(frame, info, properties):Play()
			else
				TweenService:Create(frame, info, origin):Play()
			end
		end
		
		return tween
	end
end

function module:tween(object: GuiObject, properties: {[string]: any}, info: TweenInfo)
	TweenService:Create(object, info, properties):Play()
end

return module
