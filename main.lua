-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

-- States
local Holding = false
local Typing = false

-- Global Toggles
_G.AimbotEnabled = true
_G.TeamCheck = false
_G.AimPart = "Head"
_G.Sensitivity = 0

_G.WRDClickTeleport = true

-- ESP Settings
_G.SendNotifications = true
_G.DefaultSettings = false
_G.ESPVisible = true
_G.TextColor = Color3.fromRGB(255, 80, 10)
_G.TextSize = 14
_G.Center = true
_G.Outline = true
_G.OutlineColor = Color3.fromRGB(0, 0, 0)
_G.TextTransparency = 0.7
_G.TextFont = Drawing.Fonts.UI
_G.DisableKey = Enum.KeyCode.I

-- Helper function for sending notifications
local function sendNotification(title, text)
    game.StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = 5,
    })
end

-- Closest Player Finder (updated for no circle)
local function GetClosestPlayer()
    local maxDist, target = math.huge, nil  -- Use math.huge for maximum distance initially
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer and v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Humanoid") and v.Character.Humanoid.Health > 0 then
            if not _G.TeamCheck or v.Team ~= LocalPlayer.Team then
                local screenPos = Camera:WorldToScreenPoint(v.Character.HumanoidRootPart.Position)
                local mousePos = UserInputService:GetMouseLocation()
                local dist = (Vector2.new(mousePos.X, mousePos.Y) - Vector2.new(screenPos.X, screenPos.Y)).Magnitude
                if dist < maxDist then
                    maxDist = dist
                    target = v
                end
            end
        end
    end
    return target
end

-- Aimbot Holding
UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then Holding = true end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton2 then Holding = false end
end)

-- Aimbot Lock Feature
local LockedTarget = nil
local AimbotLocked = false

-- Toggle Lock with F1
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F1 then
        AimbotLocked = not AimbotLocked
        if AimbotLocked then
            LockedTarget = GetClosestPlayer()
            if LockedTarget then
                sendNotification("Aimbot Lock", "Locked onto " .. LockedTarget.Name)
            end
        else
            LockedTarget = nil
            sendNotification("Aimbot Lock", "Aimbot unlocked")
        end
    end
end)

-- Keybind: Toggle Aimbot (Right Ctrl)
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightControl then
        _G.AimbotEnabled = not _G.AimbotEnabled
        updateToggleText()
        sendNotification("Aimbot Toggle", _G.AimbotEnabled and "Aimbot Enabled" or "Aimbot Disabled")
    end
end)

-- Keybind: Toggle Click Teleport (Right Shift)
UserInputService.InputBegan:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.RightShift then
        _G.WRDClickTeleport = not _G.WRDClickTeleport
        updateToggleText()
        sendNotification("Click Teleport Toggle", _G.WRDClickTeleport and "Click Teleport Enabled" or "Click Teleport Disabled")
    end
end)

-- Click Teleport Logic
local mouse = LocalPlayer:GetMouse()
UserInputService.InputBegan:Connect(function(input, gp)
    if not gp and input.UserInputType == Enum.UserInputType.MouseButton1 then
        if _G.WRDClickTeleport and UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            LocalPlayer.Character:MoveTo(mouse.Hit.Position)
        end
    end
end)

-- ESP Setup
local function CreateESP()
    for _, v in pairs(Players:GetPlayers()) do
        if v ~= LocalPlayer then
            local ESP = Drawing.new("Text")
            local renderConnection
            renderConnection = RunService.RenderStepped:Connect(function()
                if v.Character and v.Character:FindFirstChild("HumanoidRootPart") and v.Character:FindFirstChild("Head") then
                    local pos, onScreen = Camera:WorldToViewportPoint(v.Character.Head.Position)
                    local dist = (v.Character.HumanoidRootPart.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
                    ESP.Size = _G.TextSize
                    ESP.Center = _G.Center
                    ESP.Outline = _G.Outline
                    ESP.OutlineColor = _G.OutlineColor
                    ESP.Color = _G.TextColor
                    ESP.Transparency = _G.TextTransparency
                    ESP.Font = _G.TextFont
                    ESP.Position = Vector2.new(pos.X, pos.Y - 25)
                    ESP.Text = "(" .. math.floor(dist) .. ") " .. v.Name .. " [" .. math.floor(v.Character.Humanoid.Health) .. "]"
                    ESP.Visible = onScreen and (_G.TeamCheck == false or LocalPlayer.Team ~= v.Team) and _G.ESPVisible
                else
                    ESP.Visible = false
                end
            end)
            
            -- Disconnect when player leaves
            Players.PlayerRemoving:Connect(function(removing)
                if removing == v then
                    ESP:Remove()
                    renderConnection:Disconnect()  -- Disconnect the RenderStepped listener
                end
            end)
        end
    end
end

-- Disable ESP Key
UserInputService.TextBoxFocused:Connect(function() Typing = true end)
UserInputService.TextBoxFocusReleased:Connect(function() Typing = false end)

UserInputService.InputBegan:Connect(function(Input)
    if Input.KeyCode == _G.DisableKey and not Typing then
        if _G.ESPVisible == false then
            pcall(CreateESP)
        end
        _G.ESPVisible = not _G.ESPVisible
        updateToggleText()
        if _G.SendNotifications then
            sendNotification("ESP", "ESP visibility: " .. tostring(_G.ESPVisible))
        end
    end
end)

-- Start ESP
pcall(CreateESP)

-- Update loop
RunService.RenderStepped:Connect(function()
	if _G.AimbotEnabled and (Holding or AimbotLocked) then
		local target = AimbotLocked and LockedTarget or GetClosestPlayer()
		if target and target.Character and target.Character:FindFirstChild(_G.AimPart) then
			TweenService:Create(Camera, TweenInfo.new(_G.Sensitivity, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
				CFrame = CFrame.new(Camera.CFrame.Position, target.Character[_G.AimPart].Position)
			}):Play()
		end
	end
end)


-- UI Display for Toggles
local toggleGui = Instance.new("ScreenGui", game.CoreGui)
toggleGui.Name = "ToggleStatusGUI"

local toggleText = Instance.new("TextLabel", toggleGui)
toggleText.Size = UDim2.new(0, 300, 0, 80)
toggleText.Position = UDim2.new(0, 10, 1, -90)
toggleText.BackgroundTransparency = 1
toggleText.TextXAlignment = Enum.TextXAlignment.Left
toggleText.TextYAlignment = Enum.TextYAlignment.Top
toggleText.Font = Enum.Font.Code
toggleText.TextSize = 14
toggleText.TextColor3 = Color3.fromRGB(255, 255, 255)
toggleText.RichText = true
toggleText.TextStrokeTransparency = 0.8

function updateToggleText()
    local aimbotColor = _G.AimbotEnabled and "rgb(0,255,0)" or "rgb(255,0,0)"
    local tpColor = _G.WRDClickTeleport and "rgb(0,255,0)" or "rgb(255,0,0)"
    local espColor = _G.ESPVisible and "rgb(0,255,0)" or "rgb(255,0,0)"

    toggleText.Text = string.format(
        '<font color="%s">Aimbot [Right Ctrl]: %s</font>\n<font color="%s">Click TP [Right Shift]: %s</font>\n<font color="%s">ESP [I]: %s</font>',
        aimbotColor, _G.AimbotEnabled and "On" or "Off",
        tpColor, _G.WRDClickTeleport and "On" or "Off",
        espColor, _G.ESPVisible and "On" or "Off"
    )
end

-- Initial display
updateToggleText()
