--[[

Womp womp wompppp XD

]]

local p = game.Players.LocalPlayer
local g = Instance.new('ScreenGui')
local t = Instance.new('TextLabel')

g.Parent = p.PlayerGui
t.Parent = g
t.Size = UDim2.new(.2,0,.1,0)
t.Active = true
t.Draggable = true
t.TextScaled = true
t.Text = 'Loading...'

workspace.ChildAdded:Connect(function(c)
    if game.Players:FindFirstChild(c.Name) then return end
    local s, r = pcall(function() 
        local cT = c.Part:WaitForChild('Info', 5):WaitForChild('AnimalOverhead'):WaitForChild('DisplayName', 5)
        if cT then 
          t.Text = cT.ContextText 
        end
    end)

    if not s then print(r) end
end)
