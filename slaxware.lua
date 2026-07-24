--[[

 ____ __ __ _ _ _ _ __ ____ ____
/ ___)( ) / _\ ( \/ )/ )( \ / _\ ( _ \( __)
\___ \/ (_/\/ \ ) ( \ /\ // \ ) / ) _)
(____/\____/\_/\_/(_/\_)(_/\_)\_/\_/(__\_)(____)

-- made by grok ai btw lol cry idgaf
-- Features: auto-reset at 10hp (toggle), aimlock, esp, camlock
-- The Streets

]]

-- // Remove 0Box early
if workspace:FindFirstChild("0Box") then
    workspace["0Box"]:Destroy()
end

-- // Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- -----------------------------------------------------
-- // SILENT AIM & AIMLOCK SETTINGS
-- -----------------------------------------------------

getgenv().Settings = {
    Enabled = false,
    TeamCheck = false,
    AliveCheck = true,
    WallCheck = false,
    Hitpart = "Head",
    FOV = 150,
    ShowFOV = false,
    FOVColor = Color3.fromRGB(255, 255, 255),
    FOVTrans = 0.5,
    FOVThickness = 1,
    FOVFilled = false,
}

getgenv().Aiming = getgenv().Settings

local Camera = workspace.CurrentCamera

-- Global targets for Aimlock systems
local NAME_AIMLOCK_TARGET = nil
local NAME_AIMLOCK_ENABLED = false

local CAMLOCK_TARGET = nil
local CAMLOCK_ENABLED = false

-- // New feature states
local LASTPOS_ENABLED = false
local LASTPOS_VALUE = nil -- stores CFrame of last death position
local NOSLOW_ENABLED = false
local NOSLOW_CONNECTION = nil

-- FOV Circle Drawing
local Circle = Drawing.new("Circle")
Circle.Color = Settings.FOVColor
Circle.Thickness = Settings.FOVThickness
Circle.NumSides = 100
Circle.Radius = Settings.FOV
Circle.Filled = Settings.FOVFilled
Circle.Visible = Settings.ShowFOV

-- Sync drawing properties on Heartbeat
RunService.Heartbeat:Connect(function()
    Circle.Radius = Settings.FOV
    Circle.Visible = Settings.ShowFOV
    Circle.Position = UserInputService:GetMouseLocation()
end)

-- Helper: Check if target is alive & visible
local function IsVisible(targetPart, character)
    if not Settings.WallCheck then return true end
    local raycastParams = RaycastParams.new()
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    raycastParams.FilterDescendantsInstances = {LocalPlayer.Character, character}
    raycastParams.IgnoreWater = true

    local startPos = Camera.CFrame.Position
    local direction = targetPart.Position - startPos
    local result = workspace:Raycast(startPos, direction, raycastParams)
    return result == nil
end

-- Fetch valid cursor-aim target based on FOV
local function GetClosestPlayerToCursor()
    local closestPlayer = nil
    local shortestDistance = Settings.FOV

    if NAME_AIMLOCK_ENABLED and NAME_AIMLOCK_TARGET then
        local target = NAME_AIMLOCK_TARGET
        if target and target.Character and target.Character:FindFirstChild(Settings.Hitpart) then
            local humanoid = target.Character:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                return target
            end
        end
    end

    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hitpart = player.Character:FindFirstChild(Settings.Hitpart)
            local humanoid = player.Character:FindFirstChildOfClass("Humanoid")

            if hitpart and humanoid and humanoid.Health > 0 then
                if not (Settings.TeamCheck and player.TeamColor == LocalPlayer.TeamColor) then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(hitpart.Position)
                    if onScreen then
                        local mouseLocation = UserInputService:GetMouseLocation()
                        local distance = (Vector2.new(screenPos.X, screenPos.Y) - mouseLocation).Magnitude
                        if distance < shortestDistance then
                            if IsVisible(hitpart, player.Character) then
                                shortestDistance = distance
                                closestPlayer = player
                            end
                        end
                    end
                end
            end
        end
    end
    return closestPlayer
end

-- // SILENT AIM & ANTI-CHEAT METATABLE HOOKS
local OldIndex = nil
OldIndex = hookmetamethod(game, "__index", newcclosure(function(self, index)
    if self == Mouse and tostring(index) == "Hit" and Settings.Enabled then
        local target = GetClosestPlayerToCursor()
        if target and target.Character then
            local hitpart = target.Character:FindFirstChild(Settings.Hitpart)
            if hitpart then
                local predictedPosition = hitpart.CFrame + (hitpart.Velocity * 0.125)
                return predictedPosition
            end
        end
    end
    return OldIndex(self, index)
end))

local OldNewIndex = nil
OldNewIndex = hookmetamethod(game, "__newindex", newcclosure(function(self, index, val)
    if not checkcaller() then
        local name = tostring(self)
        if name == "HumanoidRootPart" or name == "Torso" then
            if index == "CFrame" or index == "Velocity" or index == "AssemblyLinearVelocity" then
                return
            end
        end
    end
    return OldNewIndex(self, index, val)
end))

local OldNamecall = nil
OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}

    if not checkcaller() then
        local methodName = tostring(method)
        if methodName == "FireServer" then
            local remoteName = tostring(self)
            if remoteName == "Input" then
                local action = args[1]
                if action == "bv" or action == "hb" or action == "ws" then
                    return coroutine.yield()
                end
            elseif remoteName == "WalkSpeed" or remoteName == "JumpPower" or remoteName == "HipHeight" then
                return nil
            end
        elseif methodName == "PivotTo" or methodName == "MoveTo" or methodName == "SetPrimaryPartCFrame" then
            local name = tostring(self)
            if name == "HumanoidRootPart" or name == "Torso" or self:IsA("Model") and (self.Name == LocalPlayer.Name or self == LocalPlayer.Character) then
                return nil
            end
        end
    end

    if tostring(method) == "FindPartOnRayWithIgnoreList" and Settings.Enabled then
        local target = GetClosestPlayerToCursor()
        if target and target.Character then
            local hitpart = target.Character:FindFirstChild(Settings.Hitpart)
            if hitpart then
                local predictedPosition = hitpart.CFrame + (hitpart.Velocity * 0.125)
                args[1] = Ray.new(Camera.CFrame.Position, (predictedPosition.Position - Camera.CFrame.Position).Unit * 1000)
            end
        end
    end
    return OldNamecall(self, unpack(args))
end))

-- -----------------------------------------------------
-- // USER INTERFACE (SLAXWARE MAIN PANEL)
-- -----------------------------------------------------

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SlaxwareGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = game:GetService("CoreGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 280, 0, 792)
Frame.Position = UDim2.new(0.5, -140, 0.5, -396)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = false
Frame.Visible = true
Frame.ClipsDescendants = true
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Title.BorderSizePixel = 0
Title.Text = "slaxware"
Title.TextColor3 = Color3.fromRGB(0, 180, 255)
Title.TextSize = 18
Title.Font = Enum.Font.GothamBold
Title.Parent = Frame

-- GUI Minimize Button
local MinimizeBtn = Instance.new("TextButton")
MinimizeBtn.Size = UDim2.new(0, 40, 0, 40)
MinimizeBtn.Position = UDim2.new(1, -40, 0, 0)
MinimizeBtn.BackgroundTransparency = 1
MinimizeBtn.Text = "-"
MinimizeBtn.TextColor3 = Color3.fromRGB(0, 180, 255)
MinimizeBtn.TextSize = 24
MinimizeBtn.Font = Enum.Font.GothamBold
MinimizeBtn.Parent = Title

local isMinimized = false
local expandedHeight = 792

MinimizeBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    if isMinimized then
        TweenService:Create(Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 280, 0, 40)}):Play()
        MinimizeBtn.Text = "+"
    else
        TweenService:Create(Frame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 280, 0, expandedHeight)}):Play()
        MinimizeBtn.Text = "-"
    end
end)

-- Simple drag script logic
do
    local dragging, dragInput, dragStart, startPos
    Title.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = Frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    Title.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- // TOGGLE BUTTONS
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 40)
ToggleBtn.Position = UDim2.new(0.05, 0, 0, 50)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
ToggleBtn.BorderSizePixel = 0
ToggleBtn.Text = "Disabled CursorLock"
ToggleBtn.TextColor3 = Color3.new(1, 1, 1)
ToggleBtn.TextSize = 14
ToggleBtn.Font = Enum.Font.GothamSemibold
ToggleBtn.Parent = Frame

ToggleBtn.MouseButton1Click:Connect(function()
    Settings.Enabled = not Settings.Enabled
    if Settings.Enabled then
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        ToggleBtn.Text = "Enabled CursorLock"
    else
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        ToggleBtn.Text = "Disabled CursorLock"
    end
end)

local AutoResetToggle = Instance.new("TextButton")
AutoResetToggle.Size = UDim2.new(0.9, 0, 0, 40)
AutoResetToggle.Position = UDim2.new(0.05, 0, 0, 100)
AutoResetToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
AutoResetToggle.BorderSizePixel = 0
AutoResetToggle.Text = "Auto Reset (10 HP): Disabled"
AutoResetToggle.TextColor3 = Color3.new(1, 1, 1)
AutoResetToggle.TextSize = 14
AutoResetToggle.Font = Enum.Font.GothamSemibold
AutoResetToggle.Parent = Frame

local AUTO_RESET_ENABLED = false
AutoResetToggle.MouseButton1Click:Connect(function()
    AUTO_RESET_ENABLED = not AUTO_RESET_ENABLED
    if AUTO_RESET_ENABLED then
        AutoResetToggle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        AutoResetToggle.Text = "Auto Reset (10 HP): Enabled"
    else
        AutoResetToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        AutoResetToggle.Text = "Auto Reset (10 HP): Disabled"
    end
end)

-- // FOV SLIDER CONTROL
local FOVLabel = Instance.new("TextLabel")
FOVLabel.Size = UDim2.new(0.9, 0, 0, 20)
FOVLabel.Position = UDim2.new(0.05, 0, 0, 150)
FOVLabel.BackgroundTransparency = 1
FOVLabel.Text = "FOV: " .. tostring(Settings.FOV)
FOVLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
FOVLabel.TextSize = 12
FOVLabel.Font = Enum.Font.Gotham
FOVLabel.TextXAlignment = Enum.TextXAlignment.Left
FOVLabel.Parent = Frame

local FOVSlider = Instance.new("Frame")
FOVSlider.Size = UDim2.new(0.9, 0, 0, 6)
FOVSlider.Position = UDim2.new(0.05, 0, 0, 175)
FOVSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
FOVSlider.BorderSizePixel = 0
FOVSlider.Parent = Frame

local FOVKnob = Instance.new("Frame")
FOVKnob.Size = UDim2.new(0, 16, 0, 16)
local percent = (Settings.FOV - 10) / 790
FOVKnob.Position = UDim2.new(percent, -8, 0.5, -8)
FOVKnob.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
FOVKnob.BorderSizePixel = 0
FOVKnob.Parent = FOVSlider

do
    local uis = UserInputService
    local active = false
    FOVSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            active = true
        end
    end)
    uis.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            active = false
        end
    end)
    uis.InputChanged:Connect(function(input)
        if active and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local sizeX = FOVSlider.AbsoluteSize.X
            local posX = FOVSlider.AbsolutePosition.X
            local mouseX = uis:GetMouseLocation().X
            local ratio = math.clamp((mouseX - posX) / sizeX, 0, 1)
            FOVKnob.Position = UDim2.new(ratio, -8, 0.5, -8)
            local val = math.floor(10 + (ratio * 790))
            Settings.FOV = val
            FOVLabel.Text = "FOV: " .. tostring(val)
        end
    end)
end

-- // SHOW/HIDE FOV CIRCLE
local FOVCircleToggle = Instance.new("TextButton")
FOVCircleToggle.Size = UDim2.new(0.9, 0, 0, 40)
FOVCircleToggle.Position = UDim2.new(0.05, 0, 0, 195)
FOVCircleToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
FOVCircleToggle.BorderSizePixel = 0
FOVCircleToggle.Text = "CursorLock Circle: Hidden"
FOVCircleToggle.TextColor3 = Color3.new(1, 1, 1)
FOVCircleToggle.TextSize = 14
FOVCircleToggle.Font = Enum.Font.GothamSemibold
FOVCircleToggle.Parent = Frame

FOVCircleToggle.MouseButton1Click:Connect(function()
    Settings.ShowFOV = not Settings.ShowFOV
    if Settings.ShowFOV then
        FOVCircleToggle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        FOVCircleToggle.Text = "CursorLock Circle: Visible"
    else
        FOVCircleToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        FOVCircleToggle.Text = "CursorLock Circle: Hidden"
    end
end)

-- // ESP SYSTEM DROPDOWN (UI Elements only)
local ESPDropBtn = Instance.new("TextBox")
ESPDropBtn.Size = UDim2.new(0.9, 0, 0, 40)
ESPDropBtn.Position = UDim2.new(0.05, 0, 0, 245)
ESPDropBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
ESPDropBtn.Text = "ESP: None ▼"
ESPDropBtn.TextColor3 = Color3.new(1, 1, 1)
ESPDropBtn.TextSize = 14
ESPDropBtn.Font = Enum.Font.GothamSemibold
ESPDropBtn.TextTruncate = Enum.TextTruncate.AtEnd
ESPDropBtn.ClearTextOnFocus = true
ESPDropBtn.PlaceholderText = "🔍 Search players..."
ESPDropBtn.PlaceholderColor3 = Color3.fromRGB(220, 220, 220)
do
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.Parent = ESPDropBtn
end
ESPDropBtn.Parent = Frame

local ESPDropFrame = Instance.new("ScrollingFrame")
ESPDropFrame.Size = UDim2.new(0.9, 0, 0, 0)
ESPDropFrame.Position = UDim2.new(0.05, 0, 0, 286)
ESPDropFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
ESPDropFrame.BorderSizePixel = 0
ESPDropFrame.ClipsDescendants = true
ESPDropFrame.ScrollBarThickness = 4
ESPDropFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
ESPDropFrame.ZIndex = 10
ESPDropFrame.Visible = false
ESPDropFrame.Parent = Frame

local ESPDropLayout = Instance.new("UIListLayout")
ESPDropLayout.SortOrder = Enum.SortOrder.LayoutOrder
ESPDropLayout.Parent = ESPDropFrame

local espDropOpen = false

local function UpdateESPBtnLabel()
    if ESP_All then
        ESPDropBtn.Text = "ESP: All ▼"
        ESPDropBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    else
        local count = 0
        for _ in pairs(ESP_Players) do count = count + 1 end
        if count == 0 then
            ESPDropBtn.Text = "ESP: None ▼"
            ESPDropBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        elseif count == 1 then
            local name = ""
            for plr in pairs(ESP_Players) do name = plr.Name end
            ESPDropBtn.Text = "ESP: " .. name .. " ▼"
            ESPDropBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 0)
        else
            ESPDropBtn.Text = "ESP: " .. count .. " players ▼"
            ESPDropBtn.BackgroundColor3 = Color3.fromRGB(0, 140, 0)
        end
    end
end

-- ESP Mode Booleans
getgenv().ESP_All = false
getgenv().ESP_Players = {}

local function ShouldESP(player)
    if player == LocalPlayer then return false end
    return ESP_All or ESP_Players[player] == true
end

local function RefreshESPDropdown(filterText)
    for _, child in pairs(ESPDropFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end

    local entries = {}
    table.insert(entries, {label = "All Players", isAll = true})

    local filter = filterText and filterText:lower() or ""
    if filter:sub(1, 4) == "esp:" then filter = filter:sub(5) end
    if filter:sub(1, 2) == "▼ " then filter = filter:sub(3) end
    if filter:sub(1, 2) == "🔍 " then filter = filter:sub(3) end
    filter = filter:match("^%s*(.-)%s*$") or ""

    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local label = plr.Name .. " (" .. plr.DisplayName .. ")"
            if filter == "" or plr.Name:lower():find(filter, 1, true) or plr.DisplayName:lower():find(filter, 1, true) then
                table.insert(entries, {label = label, player = plr, isAll = false})
            end
        end
    end

    local rowH = 30
    local maxRows = 6
    local totalH = #entries * rowH
    ESPDropFrame.Size = UDim2.new(0.9, 0, 0, math.min(totalH, maxRows * rowH))
    ESPDropFrame.CanvasSize = UDim2.new(0, 0, 0, totalH)

    for i, entry in ipairs(entries) do
        local isSelected = entry.isAll and ESP_All or (not entry.isAll and entry.player and ESP_Players[entry.player])

        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, rowH)
        btn.BackgroundColor3 = isSelected and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(45, 45, 45)
        btn.BorderSizePixel = 0
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.LayoutOrder = i
        btn.ZIndex = 11
        btn.Font = Enum.Font.GothamSemibold
        btn.TextSize = 12
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextTruncate = Enum.TextTruncate.AtEnd

        local check = isSelected and "☑ " or "☐ "
        btn.Text = check .. entry.label

        do
            local pad = Instance.new("UIPadding")
            pad.PaddingLeft = UDim.new(0, 8)
            pad.Parent = btn
        end
        btn.Parent = ESPDropFrame

        btn.MouseEnter:Connect(function()
            local sel = entry.isAll and ESP_All or (not entry.isAll and entry.player and ESP_Players[entry.player])
            if not sel then btn.BackgroundColor3 = Color3.fromRGB(60, 60, 60) end
        end)
        btn.MouseLeave:Connect(function()
            local sel = entry.isAll and ESP_All or (not entry.isAll and entry.player and ESP_Players[entry.player])
            btn.BackgroundColor3 = sel and Color3.fromRGB(0, 100, 0) or Color3.fromRGB(45, 45, 45)
        end)

        btn.MouseButton1Click:Connect(function()
            if entry.isAll then
                ESP_All = not ESP_All
                if ESP_All then
                    ESP_Players = {}
                end
            else
                if ESP_All then
                    ESP_All = false
                    ESP_Players = {}
                end
                if ESP_Players[entry.player] then
                    ESP_Players[entry.player] = nil
                else
                    ESP_Players[entry.player] = true
                end
            end
            UpdateESPBtnLabel()
            RefreshESPDropdown(ESPDropBtn:IsFocused() and ESPDropBtn.Text or "")
        end)
    end
end

ESPDropBtn.Focused:Connect(function()
    espDropOpen = true
    RefreshESPDropdown("")
    ESPDropFrame.Visible = true
end)

local espFiltering = false
ESPDropBtn:GetPropertyChangedSignal("Text"):Connect(function()
    if espFiltering then return end
    if ESPDropBtn:IsFocused() then
        espFiltering = true
        RefreshESPDropdown(ESPDropBtn.Text)
        espFiltering = false
    end
end)

ESPDropBtn.FocusLost:Connect(function(enterPressed)
    task.delay(0.15, function()
        if not espDropOpen then return end
        if not ESPDropBtn:IsFocused() then
            espDropOpen = false
            ESPDropFrame.Visible = false
            UpdateESPBtnLabel()
        end
    end)
end)

Players.PlayerAdded:Connect(function()
    if espDropOpen then RefreshESPDropdown() end
end)
Players.PlayerRemoving:Connect(function(plr)
    if ESP_Players[plr] then
        ESP_Players[plr] = nil
        UpdateESPBtnLabel()
    end
    if espDropOpen then RefreshESPDropdown() end
end)

-- // TELEPORT WALK (TP WALK)
local TPWalkToggle = Instance.new("TextButton")
TPWalkToggle.Size = UDim2.new(0.9, 0, 0, 40)
TPWalkToggle.Position = UDim2.new(0.05, 0, 0, 295)
TPWalkToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
TPWalkToggle.Text = "TP Walk: Disabled"
TPWalkToggle.TextColor3 = Color3.new(1, 1, 1)
TPWalkToggle.TextSize = 14
TPWalkToggle.Font = Enum.Font.GothamSemibold
TPWalkToggle.BorderSizePixel = 0
TPWalkToggle.Parent = Frame

local TPWalkSpeedLabel = Instance.new("TextLabel")
TPWalkSpeedLabel.Size = UDim2.new(0.9, 0, 0, 20)
TPWalkSpeedLabel.Position = UDim2.new(0.05, 0, 0, 345)
TPWalkSpeedLabel.BackgroundTransparency = 1
TPWalkSpeedLabel.Text = "TP Walk Speed: 15"
TPWalkSpeedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
TPWalkSpeedLabel.TextSize = 12
TPWalkSpeedLabel.Font = Enum.Font.Gotham
TPWalkSpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
TPWalkSpeedLabel.Parent = Frame

local TPWalkSlider = Instance.new("Frame")
TPWalkSlider.Size = UDim2.new(0.9, 0, 0, 6)
TPWalkSlider.Position = UDim2.new(0.05, 0, 0, 370)
TPWalkSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
TPWalkSlider.BorderSizePixel = 0
TPWalkSlider.Parent = Frame

local TPWalkKnob = Instance.new("Frame")
TPWalkKnob.Size = UDim2.new(0, 16, 0, 16)
getgenv().TPWALK_SPEED = 15
local percentWalk = (TPWALK_SPEED - 5) / 145
TPWalkKnob.Position = UDim2.new(percentWalk, -8, 0.5, -8)
TPWalkKnob.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
TPWalkKnob.BorderSizePixel = 0
TPWalkKnob.Parent = TPWalkSlider

do
    local uis = UserInputService
    local active = false
    TPWalkSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            active = true
        end
    end)
    uis.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            active = false
        end
    end)
    uis.InputChanged:Connect(function(input)
        if active and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local sizeX = TPWalkSlider.AbsoluteSize.X
            local posX = TPWalkSlider.AbsolutePosition.X
            local mouseX = uis:GetMouseLocation().X
            local ratio = math.clamp((mouseX - posX) / sizeX, 0, 1)
            TPWalkKnob.Position = UDim2.new(ratio, -8, 0.5, -8)
            local val = math.floor(5 + (ratio * 145))
            TPWALK_SPEED = val
            TPWalkSpeedLabel.Text = "TP Walk Speed: " .. tostring(val)
        end
    end)
end

getgenv().TPWALK_ENABLED = false
TPWalkToggle.MouseButton1Click:Connect(function()
    TPWALK_ENABLED = not TPWALK_ENABLED
    if TPWALK_ENABLED then
        TPWalkToggle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        TPWalkToggle.Text = "TP Walk: Enabled"
    else
        TPWalkToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        TPWalkToggle.Text = "TP Walk: Disabled"
    end
end)

-- TP Walk Loop
RunService.Heartbeat:Connect(function()
    if not TPWALK_ENABLED then return end
    local character = LocalPlayer.Character
    if not character then return end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if humanoid and hrp and humanoid.MoveDirection.Magnitude > 0 then
        hrp.CFrame = hrp.CFrame + humanoid.MoveDirection * (TPWALK_SPEED * 0.016)
    end
end)

-- // CAMLOCK TARGET dropdown
local CamlockToggle = Instance.new("TextButton")
CamlockToggle.Size = UDim2.new(0.9, 0, 0, 40)
CamlockToggle.Position = UDim2.new(0.05, 0, 0, 390)
CamlockToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
CamlockToggle.BorderSizePixel = 0
CamlockToggle.Text = "Camlock: Disabled"
CamlockToggle.TextColor3 = Color3.new(1, 1, 1)
CamlockToggle.TextSize = 14
CamlockToggle.Font = Enum.Font.GothamSemibold
CamlockToggle.Parent = Frame

local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(0.9, 0, 0, 20)
TargetLabel.Position = UDim2.new(0.05, 0, 0, 440)
TargetLabel.BackgroundTransparency = 1
TargetLabel.Text = "Target: none"
TargetLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
TargetLabel.TextSize = 12
TargetLabel.Font = Enum.Font.Gotham
TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
TargetLabel.Parent = Frame

-- // CAMLOCK DROPDOWN
local CamlockDropBtn = Instance.new("TextBox")
CamlockDropBtn.Size = UDim2.new(0.9, 0, 0, 30)
CamlockDropBtn.Position = UDim2.new(0.05, 0, 0, 465)
CamlockDropBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
CamlockDropBtn.BorderSizePixel = 0
CamlockDropBtn.Text = "▼ Select Player..."
CamlockDropBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
CamlockDropBtn.TextSize = 13
CamlockDropBtn.Font = Enum.Font.Gotham
CamlockDropBtn.TextXAlignment = Enum.TextXAlignment.Left
CamlockDropBtn.TextTruncate = Enum.TextTruncate.AtEnd
CamlockDropBtn.ClearTextOnFocus = true
CamlockDropBtn.PlaceholderText = "🔍 Search player..."
CamlockDropBtn.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
do
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.Parent = CamlockDropBtn
end
CamlockDropBtn.Parent = Frame

local CamlockDropFrame = Instance.new("ScrollingFrame")
CamlockDropFrame.Size = UDim2.new(0.9, 0, 0, 0)
CamlockDropFrame.Position = UDim2.new(0.05, 0, 0, 496)
CamlockDropFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
CamlockDropFrame.BorderSizePixel = 0
CamlockDropFrame.ClipsDescendants = true
CamlockDropFrame.ScrollBarThickness = 4
CamlockDropFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
CamlockDropFrame.ZIndex = 10
CamlockDropFrame.Visible = false
CamlockDropFrame.Parent = Frame

local CamlockDropLayout = Instance.new("UIListLayout")
CamlockDropLayout.SortOrder = Enum.SortOrder.LayoutOrder
CamlockDropLayout.Parent = CamlockDropFrame

local camlockDropOpen = false

local function RefreshCamlockDropdown(filterText)
    for _, child in pairs(CamlockDropFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local entries = {}
    table.insert(entries, {label = "None", player = nil})
    local filter = filterText and filterText:lower() or ""
    if filter:sub(1, 2) == "▼ " then filter = filter:sub(3) end
    if filter:sub(1, 2) == "🔍 " then filter = filter:sub(3) end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local label = plr.Name .. " (" .. plr.DisplayName .. ")"
            if filter == "" or plr.Name:lower():find(filter, 1, true) or plr.DisplayName:lower():find(filter, 1, true) then
                table.insert(entries, {label = label, player = plr})
            end
        end
    end
    local rowH = 28
    local maxVisible = 5
    local totalH = #entries * rowH
    CamlockDropFrame.Size = UDim2.new(0.9, 0, 0, math.min(totalH, maxVisible * rowH))
    CamlockDropFrame.CanvasSize = UDim2.new(0, 0, 0, totalH)
    for i, entry in ipairs(entries) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, rowH)
        btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
        btn.BorderSizePixel = 0
        btn.Text = entry.label
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextSize = 12
        btn.Font = Enum.Font.Gotham
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.LayoutOrder = i
        btn.ZIndex = 11
        do
            local pad = Instance.new("UIPadding")
            pad.PaddingLeft = UDim.new(0, 8)
            pad.Parent = btn
        end
        btn.Parent = CamlockDropFrame
        btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(65, 65, 65) end)
        btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(45, 45, 45) end)
        btn.MouseButton1Click:Connect(function()
            CAMLOCK_TARGET = entry.player
            if entry.player then
                CamlockDropBtn.Text = "▼ " .. entry.player.Name
                CamlockDropBtn.TextColor3 = Color3.new(1, 1, 1)
                TargetLabel.Text = "Target: " .. entry.player.Name
            else
                CamlockDropBtn.Text = "▼ Select Player..."
                CamlockDropBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
                TargetLabel.Text = "Target: none"
            end
            CamlockDropFrame.Visible = false
            camlockDropOpen = false
            CamlockDropBtn:ReleaseFocus()
        end)
    end
end

CamlockDropBtn.Focused:Connect(function()
    camlockDropOpen = true
    RefreshCamlockDropdown("")
    CamlockDropFrame.Visible = true
end)

local camlockFiltering = false
CamlockDropBtn:GetPropertyChangedSignal("Text"):Connect(function()
    if camlockFiltering then return end
    if CamlockDropBtn:IsFocused() then
        camlockFiltering = true
        RefreshCamlockDropdown(CamlockDropBtn.Text)
        camlockFiltering = false
    end
end)

CamlockDropBtn.FocusLost:Connect(function(enterPressed)
    task.delay(0.15, function()
        if not camlockDropOpen then return end
        if not CamlockDropBtn:IsFocused() then
            camlockDropOpen = false
            CamlockDropFrame.Visible = false
            if CAMLOCK_TARGET then
                CamlockDropBtn.Text = "▼ " .. CAMLOCK_TARGET.Name
            else
                CamlockDropBtn.Text = "▼ Select Player..."
            end
        end
    end)
end)

Players.PlayerAdded:Connect(function()
    if camlockDropOpen then RefreshCamlockDropdown() end
end)
Players.PlayerRemoving:Connect(function(plr)
    if plr == CAMLOCK_TARGET then
        CAMLOCK_TARGET = nil
        TargetLabel.Text = "Target: none"
        CamlockDropBtn.Text = "▼ Select Player..."
        CamlockDropBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
    end
    if camlockDropOpen then RefreshCamlockDropdown() end
end)

CamlockToggle.MouseButton1Click:Connect(function()
    CAMLOCK_ENABLED = not CAMLOCK_ENABLED
    if CAMLOCK_ENABLED then
        CamlockToggle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        CamlockToggle.Text = "Camlock: Enabled"
    else
        CamlockToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        CamlockToggle.Text = "Camlock: Disabled"
    end
end)

-- Camera Lock Rotation Loop
RunService.RenderStepped:Connect(function()
    if not CAMLOCK_ENABLED or not CAMLOCK_TARGET then return end
    local char = CAMLOCK_TARGET.Character
    if char then
        local part = char:FindFirstChild(Settings.Hitpart)
        if part then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, part.Position)
        end
    end
end)

-- // FLY MODE SYSTEM
local FlyToggle = Instance.new("TextButton")
FlyToggle.Size = UDim2.new(0.9, 0, 0, 40)
FlyToggle.Position = UDim2.new(0.05, 0, 0, 510)
FlyToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
FlyToggle.BorderSizePixel = 0
FlyToggle.Text = "Fly: Disabled"
FlyToggle.TextColor3 = Color3.new(1, 1, 1)
FlyToggle.TextSize = 14
FlyToggle.Font = Enum.Font.GothamSemibold
FlyToggle.Parent = Frame

local FlySpeedLabel = Instance.new("TextLabel")
FlySpeedLabel.Size = UDim2.new(0.9, 0, 0, 20)
FlySpeedLabel.Position = UDim2.new(0.05, 0, 0, 558)
FlySpeedLabel.BackgroundTransparency = 1
FlySpeedLabel.Text = "Fly Speed: 50"
FlySpeedLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
FlySpeedLabel.TextSize = 12
FlySpeedLabel.Font = Enum.Font.Gotham
FlySpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
FlySpeedLabel.Parent = Frame

local FlySpeedSlider = Instance.new("Frame")
FlySpeedSlider.Size = UDim2.new(0.9, 0, 0, 6)
FlySpeedSlider.Position = UDim2.new(0.05, 0, 0, 583)
FlySpeedSlider.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
FlySpeedSlider.BorderSizePixel = 0
FlySpeedSlider.Parent = Frame

local FlySpeedKnob = Instance.new("Frame")
FlySpeedKnob.Size = UDim2.new(0, 16, 0, 16)
getgenv().FLY_SPEED = 50
local percentFly = (FLY_SPEED - 10) / 290
FlySpeedKnob.Position = UDim2.new(percentFly, -8, 0.5, -8)
FlySpeedKnob.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
FlySpeedKnob.BorderSizePixel = 0
FlySpeedKnob.Parent = FlySpeedSlider

do
    local uis = UserInputService
    local active = false
    FlySpeedSlider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            active = true
        end
    end)
    uis.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            active = false
        end
    end)
    uis.InputChanged:Connect(function(input)
        if active and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local sizeX = FlySpeedSlider.AbsoluteSize.X
            local posX = FlySpeedSlider.AbsolutePosition.X
            local mouseX = uis:GetMouseLocation().X
            local ratio = math.clamp((mouseX - posX) / sizeX, 0, 1)
            FlySpeedKnob.Position = UDim2.new(ratio, -8, 0.5, -8)
            local val = math.floor(10 + (ratio * 290))
            FLY_SPEED = val
            FlySpeedLabel.Text = "Fly Speed: " .. tostring(val)
        end
    end)
end

getgenv().FLY_ENABLED = false
local flyConnection = nil
local flySpeedVector = Vector3.new(0, 0, 0)

local savedWalkSpeed = 16
local savedJumpPower = 50

local function StopFly()
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end
    local character = LocalPlayer.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            local bv = hrp:FindFirstChild("SlaxFlyBV")
            local bg = hrp:FindFirstChild("SlaxFlyBG")
            if bv then bv:Destroy() end
            if bg then bg:Destroy() end
        end
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
            humanoid.WalkSpeed = savedWalkSpeed
            humanoid.JumpPower = savedJumpPower
            humanoid:ChangeState(Enum.HumanoidStateType.Running)
        end
    end
end

local function StartFly()
    StopFly()
    local character = LocalPlayer.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        savedWalkSpeed = humanoid.WalkSpeed
        savedJumpPower = humanoid.JumpPower
        humanoid.PlatformStand = true
    end

    local bv = Instance.new("BodyVelocity")
    bv.Name = "SlaxFlyBV"
    bv.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bv.Velocity = Vector3.new(0, 0, 0)
    bv.Parent = hrp

    local bg = Instance.new("BodyGyro")
    bg.Name = "SlaxFlyBG"
    bg.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bg.CFrame = Camera.CFrame
    bg.Parent = hrp

    flyConnection = RunService.RenderStepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        local root = char:FindFirstChild("HumanoidRootPart")
        local gyro = root and root:FindFirstChild("SlaxFlyBG")
        local vel = root and root:FindFirstChild("SlaxFlyBV")
        if not root or not gyro or not vel then return end

        gyro.CFrame = Camera.CFrame
        local direction = Vector3.new(0, 0, 0)

        if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then direction = direction - Vector3.new(0, 1, 0) end

        if direction.Magnitude > 0 then
            local clampedSpeed = math.min(FLY_SPEED, 150)
            vel.Velocity = direction.Unit * clampedSpeed
        else
            vel.Velocity = Vector3.new(0, 0, 0)
        end
    end)
end

FlyToggle.MouseButton1Click:Connect(function()
    FLY_ENABLED = not FLY_ENABLED
    if FLY_ENABLED then
        FlyToggle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        FlyToggle.Text = "Fly: Enabled"
        StartFly()
    else
        FlyToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        FlyToggle.Text = "Fly: Disabled"
        StopFly()
    end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if FLY_ENABLED then
        task.wait(0.5)
        StartFly()
    end
end)

-- // NOCLIP CONTROL
local NoclipToggle = Instance.new("TextButton")
NoclipToggle.Size = UDim2.new(0.9, 0, 0, 40)
NoclipToggle.Position = UDim2.new(0.05, 0, 0, 608)
NoclipToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
NoclipToggle.BorderSizePixel = 0
NoclipToggle.Text = "Noclip: Disabled"
NoclipToggle.TextColor3 = Color3.new(1, 1, 1)
NoclipToggle.TextSize = 14
NoclipToggle.Font = Enum.Font.GothamSemibold
NoclipToggle.Parent = Frame

getgenv().NOCLIP_ENABLED = false
NoclipToggle.MouseButton1Click:Connect(function()
    NOCLIP_ENABLED = not NOCLIP_ENABLED
    if NOCLIP_ENABLED then
        NoclipToggle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        NoclipToggle.Text = "Noclip: Enabled"
    else
        NoclipToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        NoclipToggle.Text = "Noclip: Disabled"
    end
end)

RunService.Stepped:Connect(function()
    if not NOCLIP_ENABLED then return end
    local character = LocalPlayer.Character
    if not character then return end
    for _, part in pairs(character:GetDescendants()) do
        if part:IsA("BasePart") then
            part.CanCollide = false
        end
    end
end)

-- // INFINITE STAMINA CONTROL
local InfStamToggle = Instance.new("TextButton")
InfStamToggle.Size = UDim2.new(0.9, 0, 0, 40)
InfStamToggle.Position = UDim2.new(0.05, 0, 0, 655)
InfStamToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
InfStamToggle.BorderSizePixel = 0
InfStamToggle.Text = "Inf Stamina: Disabled"
InfStamToggle.TextColor3 = Color3.new(1, 1, 1)
InfStamToggle.TextSize = 14
InfStamToggle.Font = Enum.Font.GothamSemibold
InfStamToggle.Parent = Frame

getgenv().INFSTAM_ENABLED = false
local infStamConnection = nil

local function ApplyInfStam(character)
    if not character then return end
    local stamina = character:WaitForChild("Stamina", 5)
    local maxStamina = character:WaitForChild("MaxStamina", 5)
    if stamina and maxStamina then
        if infStamConnection then infStamConnection:Disconnect() end
        infStamConnection = stamina:GetPropertyChangedSignal("Value"):Connect(function()
            if INFSTAM_ENABLED and stamina.Value < maxStamina.Value then
                stamina.Value = maxStamina.Value
            end
        end)
        if INFSTAM_ENABLED then
            stamina.Value = maxStamina.Value
        end
    end
end

InfStamToggle.MouseButton1Click:Connect(function()
    INFSTAM_ENABLED = not INFSTAM_ENABLED
    if INFSTAM_ENABLED then
        InfStamToggle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        InfStamToggle.Text = "Inf Stamina: Enabled"
        ApplyInfStam(LocalPlayer.Character)
    else
        InfStamToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        InfStamToggle.Text = "Inf Stamina: Disabled"
        if infStamConnection then
            infStamConnection:Disconnect()
            infStamConnection = nil
        end
    end
end)

-- // LASTPOS + NOSLOW — standalone approach

local NOSLOW_TAGS = {
    ["reloading"] = true,
    ["ko"] = true,
    ["action"] = true,
    ["creatorslow"] = true,
    ["gunslow"] = true,
}

local _tagSystemHooked = false
local _oldTagHas = nil
local function HookTagSystem()
    if _tagSystemHooked then return end
    pcall(function()
        local RS = game:GetService("ReplicatedStorage")
        local TagSystem = RS:FindFirstChild("TagSystem")
        if TagSystem then
            TagSystem = require(TagSystem)
            if TagSystem and TagSystem.has then
                _oldTagHas = TagSystem.has
                TagSystem.has = function(object, tag)
                    if NOSLOW_ENABLED and object == LocalPlayer.Character and tag and NOSLOW_TAGS[tag:lower()] then
                        return nil
                    end
                    return _oldTagHas(object, tag)
                end
                _tagSystemHooked = true
            end
        end
    end)
end

RunService.Heartbeat:Connect(function()
    if not NOSLOW_ENABLED then return end
    local char = LocalPlayer.Character
    if not char then return end
    for _, child in ipairs(char:GetChildren()) do
        if NOSLOW_TAGS[child.Name:lower()] then
            pcall(function() child:Destroy() end)
        end
    end
end)

task.spawn(HookTagSystem)
LocalPlayer.CharacterAdded:Connect(function()
    task.wait(1)
    HookTagSystem()
end)

local function SlaxHookCharacter(character)
    local humanoid = character:WaitForChild("Humanoid", 10)
    local hrp = character:WaitForChild("HumanoidRootPart", 10)

    if LASTPOS_ENABLED and LASTPOS_VALUE then
        local savedPos = LASTPOS_VALUE
        task.delay(0.25, function()
            pcall(function()
                local freshChar = LocalPlayer.Character
                if not freshChar or not freshChar.Parent then return end
                local freshHrp = freshChar:FindFirstChild("HumanoidRootPart")
                if not freshHrp or not freshHrp.Parent then return end
                if freshChar ~= character then return end
                freshHrp.CFrame = savedPos
                Notify("Last Pos", "Teleported to last position")
            end)
        end)
    end

    if not humanoid then return end
    
    if INFSTAM_ENABLED then
        task.spawn(ApplyInfStam, character)
    end

    humanoid.Died:Connect(function()
        if FLY_ENABLED then StopFly() end
        if hrp and hrp.Parent then
            LASTPOS_VALUE = hrp.CFrame
        end
    end)

    if NOSLOW_ENABLED then
        for _, child in pairs(character:GetChildren()) do
            if NOSLOW_TAGS[child.Name:lower()] then
                pcall(function() child:Destroy() end)
            end
        end
    end
end

LocalPlayer.CharacterAdded:Connect(function(character)
    if NOCLIP_ENABLED then
        NOCLIP_ENABLED = false
        NoclipToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        NoclipToggle.Text = "Noclip: Disabled"
    end
    SlaxHookCharacter(character)
end)

if LocalPlayer.Character then
    task.spawn(SlaxHookCharacter, LocalPlayer.Character)
end

-- // AUTO RESET ON LOW HEALTH (Strong Version)
local RESET_HEALTH_THRESHOLD = 10
local lastResetTime = 0

local function safeResetCharacter()
    if not AUTO_RESET_ENABLED then return end
    local currentTime = tick()
    if currentTime - lastResetTime < 2 then return end

    local character = LocalPlayer.Character
    if not character then return end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    if humanoid.Health > RESET_HEALTH_THRESHOLD or humanoid.Health <= 0 then
        return
    end

    lastResetTime = currentTime
    print("⚠️ Low HP (" .. math.floor(humanoid.Health) .. ") - Forcing Reset!")

    pcall(function()
        LocalPlayer:LoadCharacter()
    end)

    task.delay(0.5, function()
        pcall(function()
            if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
                LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health = 0
            end
        end)
    end)
end

RunService.Heartbeat:Connect(safeResetCharacter)

LocalPlayer.CharacterAdded:Connect(function()
    task.wait(0.8)
    print("✅ Respawned - Auto reset active again")
end)

-- // NAME AIMLOCK GUI
local NameAimlockLabel = Instance.new("TextLabel")
NameAimlockLabel.Size = UDim2.new(0.9, 0, 0, 20)
NameAimlockLabel.Position = UDim2.new(0.05, 0, 0, 705)
NameAimlockLabel.BackgroundTransparency = 1
NameAimlockLabel.Text = "Name Aimlock: none"
NameAimlockLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
NameAimlockLabel.TextSize = 13
NameAimlockLabel.Font = Enum.Font.GothamSemibold
NameAimlockLabel.TextXAlignment = Enum.TextXAlignment.Left
NameAimlockLabel.Parent = Frame

-- // AIMLOCK DROPDOWN
local AimlockDropBtn = Instance.new("TextBox")
AimlockDropBtn.Size = UDim2.new(0.9, 0, 0, 32)
AimlockDropBtn.Position = UDim2.new(0.05, 0, 0, 728)
AimlockDropBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
AimlockDropBtn.BorderSizePixel = 0
AimlockDropBtn.Text = "▼ Select Player..."
AimlockDropBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
AimlockDropBtn.TextSize = 13
AimlockDropBtn.Font = Enum.Font.GothamSemibold
AimlockDropBtn.TextXAlignment = Enum.TextXAlignment.Left
AimlockDropBtn.TextTruncate = Enum.TextTruncate.AtEnd
AimlockDropBtn.ClearTextOnFocus = true
AimlockDropBtn.PlaceholderText = "🔍 Search player..."
AimlockDropBtn.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
do
    local pad = Instance.new("UIPadding")
    pad.PaddingLeft = UDim.new(0, 8)
    pad.Parent = AimlockDropBtn
end
AimlockDropBtn.Parent = Frame

local AimlockDropFrame = Instance.new("ScrollingFrame")
AimlockDropFrame.Size = UDim2.new(0.9, 0, 0, 0)
AimlockDropFrame.Position = UDim2.new(0.05, 0, 0, 761)
AimlockDropFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
AimlockDropFrame.BorderSizePixel = 0
AimlockDropFrame.ClipsDescendants = true
AimlockDropFrame.ScrollBarThickness = 4
AimlockDropFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
AimlockDropFrame.ZIndex = 10
AimlockDropFrame.Visible = false
AimlockDropFrame.Parent = Frame

local AimlockDropLayout = Instance.new("UIListLayout")
AimlockDropLayout.SortOrder = Enum.SortOrder.LayoutOrder
AimlockDropLayout.Parent = AimlockDropFrame

local NameAimlockStatus = Instance.new("TextLabel")
NameAimlockStatus.Size = UDim2.new(0.9, 0, 0, 18)
NameAimlockStatus.Position = UDim2.new(0.05, 0, 0, 764)
NameAimlockStatus.BackgroundTransparency = 1
NameAimlockStatus.Text = "Status: inactive"
NameAimlockStatus.TextColor3 = Color3.fromRGB(170, 0, 0)
NameAimlockStatus.TextSize = 12
NameAimlockStatus.Font = Enum.Font.Gotham
NameAimlockStatus.TextXAlignment = Enum.TextXAlignment.Left
NameAimlockStatus.Parent = Frame

local aimlockDropOpen = false

local function SetAimlockTarget(plr)
    NAME_AIMLOCK_TARGET = plr
    NAME_AIMLOCK_ENABLED = false
    if plr then
        NAME_AIMLOCK_ENABLED = true
        NameAimlockLabel.Text = "Name Aimlock: " .. plr.Name
        AimlockDropBtn.Text = "▼ " .. plr.Name
        AimlockDropBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
        NameAimlockStatus.Text = "Status: LOCKED"
        NameAimlockStatus.TextColor3 = Color3.fromRGB(0, 200, 80)
        Aiming.ShowFOV = false
        Aiming.FOV = 9999
        Settings.ShowFOV = false
        Settings.FOV = 9999
        FOVCircleToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        FOVCircleToggle.Text = "CursorLock Circle: Hidden"
    else
        NameAimlockLabel.Text = "Name Aimlock: none"
        AimlockDropBtn.Text = "▼ Select Player..."
        AimlockDropBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
        NameAimlockStatus.Text = "Status: inactive"
        NameAimlockStatus.TextColor3 = Color3.fromRGB(170, 0, 0)
    end
end

local function RefreshAimlockDropdown(filterText)
    for _, child in pairs(AimlockDropFrame:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    local entries = {}
    table.insert(entries, {label = "None", player = nil})
    local filter = filterText and filterText:lower() or ""
    if filter:sub(1, 2) == "▼ " then filter = filter:sub(3) end
    if filter:sub(1, 2) == "🔍 " then filter = filter:sub(3) end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            local label = plr.Name .. " (" .. plr.DisplayName .. ")"
            if filter == "" or plr.Name:lower():find(filter, 1, true) or plr.DisplayName:lower():find(filter, 1, true) then
                table.insert(entries, {label = label, player = plr})
            end
        end
    end
    local rowH = 28
    local maxVisible = 5
    local totalH = #entries * rowH
    AimlockDropFrame.Size = UDim2.new(0.9, 0, 0, math.min(totalH, maxVisible * rowH))
    AimlockDropFrame.CanvasSize = UDim2.new(0, 0, 0, totalH)
    for i, entry in ipairs(entries) do
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(1, 0, 0, rowH)
        btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
        btn.BorderSizePixel = 0
        btn.Text = entry.label
        btn.TextColor3 = Color3.new(1, 1, 1)
        btn.TextSize = 12
        btn.Font = Enum.Font.GothamSemibold
        btn.TextXAlignment = Enum.TextXAlignment.Left
        btn.LayoutOrder = i
        btn.ZIndex = 11
        do
            local pad = Instance.new("UIPadding")
            pad.PaddingLeft = UDim.new(0, 8)
            pad.Parent = btn
        end
        btn.Parent = AimlockDropFrame
        btn.MouseEnter:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(70, 70, 40) end)
        btn.MouseLeave:Connect(function() btn.BackgroundColor3 = Color3.fromRGB(50, 50, 50) end)
        btn.MouseButton1Click:Connect(function()
            SetAimlockTarget(entry.player)
            AimlockDropFrame.Visible = false
            aimlockDropOpen = false
            AimlockDropBtn:ReleaseFocus()
        end)
    end
end

AimlockDropBtn.Focused:Connect(function()
    aimlockDropOpen = true
    RefreshAimlockDropdown("")
    AimlockDropFrame.Visible = true
end)

local aimlockFiltering = false
AimlockDropBtn:GetPropertyChangedSignal("Text"):Connect(function()
    if aimlockFiltering then return end
    if AimlockDropBtn:IsFocused() then
        aimlockFiltering = true
        RefreshAimlockDropdown(AimlockDropBtn.Text)
        aimlockFiltering = false
    end
end)

AimlockDropBtn.FocusLost:Connect(function(enterPressed)
    task.delay(0.15, function()
        if not aimlockDropOpen then return end
        if not AimlockDropBtn:IsFocused() then
            aimlockDropOpen = false
            AimlockDropFrame.Visible = false
            if NAME_AIMLOCK_TARGET then
                AimlockDropBtn.Text = "▼ " .. NAME_AIMLOCK_TARGET.Name
            else
                AimlockDropBtn.Text = "▼ Select Player..."
            end
        end
    end)
end)

Players.PlayerRemoving:Connect(function(plr)
    if plr == NAME_AIMLOCK_TARGET then
        SetAimlockTarget(nil)
        NameAimlockStatus.Text = "Status: inactive (player left)"
    end
    if aimlockDropOpen then RefreshAimlockDropdown() end
end)

Players.PlayerAdded:Connect(function()
    if aimlockDropOpen then RefreshAimlockDropdown() end
end)

-- -----------------------------------------------------
-- // SLIDING COMMAND BAR STRIP
-- -----------------------------------------------------
local ParseCommand

local CmdBarTweenInfo = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local CmdBarFrame = Instance.new("Frame")
CmdBarFrame.Name = "SlaxCmdBar"
CmdBarFrame.Size = UDim2.new(0, 380, 0, 48)

-- Positioned to slide in from the LEFT side of the screen
local CMD_BAR_OPEN_POS   = UDim2.new(0, 20, 0.5, -24)
local CMD_BAR_CLOSED_POS = UDim2.new(0, -400, 0.5, -24)
CmdBarFrame.Position = CMD_BAR_CLOSED_POS
CmdBarFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
CmdBarFrame.BackgroundTransparency = 0.08
CmdBarFrame.BorderSizePixel = 0
CmdBarFrame.ZIndex = 20
CmdBarFrame.ClipsDescendants = true
CmdBarFrame.Visible = true
CmdBarFrame.Parent = ScreenGui

do
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = CmdBarFrame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(200, 0, 0)
    stroke.Thickness = 1
    stroke.Transparency = 0.5
    stroke.Parent = CmdBarFrame
end

local CmdBarPrompt = Instance.new("TextLabel")
CmdBarPrompt.Size = UDim2.new(0, 28, 1, 0)
CmdBarPrompt.Position = UDim2.new(0, 0, 0, 0)
CmdBarPrompt.BackgroundTransparency = 1
CmdBarPrompt.Text = ":"
CmdBarPrompt.TextColor3 = Color3.fromRGB(0, 180, 255)
CmdBarPrompt.TextSize = 16
CmdBarPrompt.Font = Enum.Font.GothamBold
CmdBarPrompt.ZIndex = 21
CmdBarPrompt.Parent = CmdBarFrame

local CmdBarBox = Instance.new("TextBox")
CmdBarBox.Size = UDim2.new(1, -36, 0, 34)
CmdBarBox.Position = UDim2.new(0, 28, 0.5, -17)
CmdBarBox.BackgroundTransparency = 1
CmdBarBox.PlaceholderText = "camlock / aimlock / esp {player}  | bind aimlock f"
CmdBarBox.PlaceholderColor3 = Color3.fromRGB(90, 90, 90)
CmdBarBox.Text = ""
CmdBarBox.TextColor3 = Color3.new(1, 1, 1)
CmdBarBox.TextSize = 13
CmdBarBox.Font = Enum.Font.Gotham
CmdBarBox.ClearTextOnFocus = false
CmdBarBox.ZIndex = 21
CmdBarBox.Parent = CmdBarFrame

do
    local pad = Instance.new("UIPadding")
    pad.PaddingRight = UDim.new(0, 8)
    pad.Parent = CmdBarBox
end

local MainCmdFeedback = Instance.new("TextLabel")
MainCmdFeedback.Size = UDim2.new(1, -16, 0, 18)
MainCmdFeedback.Position = UDim2.new(0, 8, 0, -20)
MainCmdFeedback.BackgroundTransparency = 1
MainCmdFeedback.Text = ""
MainCmdFeedback.TextColor3 = Color3.fromRGB(0, 200, 80)
MainCmdFeedback.TextSize = 11
MainCmdFeedback.Font = Enum.Font.Gotham
MainCmdFeedback.ZIndex = 21
MainCmdFeedback.Parent = CmdBarFrame

local CmdBox = CmdBarBox
local CmdFeedback = MainCmdFeedback

local isCmdBarOpen = false
local cmdBarCloseThread = nil

local function SlideCmdBarIn()
    if isCmdBarOpen then
        task.defer(function() CmdBarBox:CaptureFocus() end)
        return
    end
    isCmdBarOpen = true
    if cmdBarCloseThread then task.cancel(cmdBarCloseThread) cmdBarCloseThread = nil end
    CmdBarBox.Text = ""
    MainCmdFeedback.Text = ""
    TweenService:Create(CmdBarFrame, CmdBarTweenInfo, {Position = CMD_BAR_OPEN_POS}):Play()
    CmdBarBox:CaptureFocus()
    task.spawn(function() task.wait(0.05) CmdBarBox.Text = "" end)
end

local function SlideCmdBarOut()
    if not isCmdBarOpen then return end
    isCmdBarOpen = false
    if cmdBarCloseThread then task.cancel(cmdBarCloseThread) cmdBarCloseThread = nil end
    if CmdBarBox:IsFocused() then CmdBarBox:ReleaseFocus() end
    TweenService:Create(CmdBarFrame, CmdBarTweenInfo, {Position = CMD_BAR_CLOSED_POS}):Play()
end

-- -----------------------------------------------------
-- // SIDE QUICK-COMMAND BAR
-- -----------------------------------------------------

local SideFrame = Instance.new("Frame")
SideFrame.Name = "SideCmdBarFrame"
SideFrame.Size = UDim2.new(0, 300, 0, 70)
-- Positioned to slide in from the LEFT side of the screen
local sideClosedPos = UDim2.new(0, -310, 0.5, -35)
local sideOpenPos = UDim2.new(0, 10, 0.5, -35)
SideFrame.Position = sideClosedPos
SideFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
SideFrame.BackgroundTransparency = 0.15
SideFrame.BorderSizePixel = 0
SideFrame.ZIndex = 10
SideFrame.Visible = false
SideFrame.Parent = ScreenGui

local SideCorner = Instance.new("UICorner")
SideCorner.CornerRadius = UDim.new(0, 8)
SideCorner.Parent = SideFrame

local SideStroke = Instance.new("UIStroke")
SideStroke.Color = Color3.fromRGB(80, 80, 80)
SideStroke.Thickness = 1
SideStroke.Parent = SideFrame

local SideTitle = Instance.new("TextLabel")
SideTitle.Size = UDim2.new(1, 0, 0, 20)
SideTitle.Position = UDim2.new(0, 0, 0, 4)
SideTitle.BackgroundTransparency = 1
SideTitle.Text = "⚡ SLAXWARE QUICK COMMAND"
SideTitle.TextColor3 = Color3.fromRGB(0, 180, 255)
SideTitle.TextSize = 10
SideTitle.Font = Enum.Font.GothamBold
SideTitle.ZIndex = 11
SideTitle.Parent = SideFrame

local SideCmdBox = Instance.new("TextBox")
SideCmdBox.Size = UDim2.new(0.9, 0, 0, 30)
SideCmdBox.Position = UDim2.new(0.05, 0, 0, 24)
SideCmdBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
SideCmdBox.BorderSizePixel = 0
SideCmdBox.PlaceholderText = "camlock / aimlock {player}..."
SideCmdBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 120)
SideCmdBox.Text = ""
SideCmdBox.TextColor3 = Color3.new(1, 1, 1)
SideCmdBox.TextSize = 12
SideCmdBox.Font = Enum.Font.Gotham
SideCmdBox.ClearTextOnFocus = false
SideCmdBox.ZIndex = 11
SideCmdBox.Parent = SideFrame

local CmdBoxCorner = Instance.new("UICorner")
CmdBoxCorner.CornerRadius = UDim.new(0, 5)
CmdBoxCorner.Parent = SideCmdBox

local SidePad = Instance.new("UIPadding")
SidePad.PaddingLeft = UDim.new(0, 8)
SidePad.PaddingRight = UDim.new(0, 8)
SidePad.Parent = SideCmdBox

local SideCmdFeedback = Instance.new("TextLabel")
SideCmdFeedback.Size = UDim2.new(0.9, 0, 0, 12)
SideCmdFeedback.Position = UDim2.new(0.05, 0, 0, 55)
SideCmdFeedback.BackgroundTransparency = 1
SideCmdFeedback.Text = ""
SideCmdFeedback.TextColor3 = Color3.fromRGB(0, 200, 80)
SideCmdFeedback.TextSize = 9
SideCmdFeedback.Font = Enum.Font.Gotham
SideCmdFeedback.ZIndex = 11
SideCmdFeedback.Parent = SideFrame

local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

local isSideOpen = false
local sideCloseThread = nil

local function OpenSideCommandBar()
    SideCmdBox.Text = ""
    SideCmdFeedback.Text = ""

    if isSideOpen then
        SideCmdBox:CaptureFocus()
        return
    end
    isSideOpen = true
    SideFrame.Visible = true

    if sideCloseThread then
        task.cancel(sideCloseThread)
        sideCloseThread = nil
    end

    local tween = TweenService:Create(SideFrame, tweenInfo, {Position = sideOpenPos})
    tween:Play()
    tween.Completed:Connect(function()
        SideCmdBox:CaptureFocus()
    end)
end

local function HideSideCommandBar()
    if not isSideOpen then return end
    isSideOpen = false

    if sideCloseThread then
        task.cancel(sideCloseThread)
        sideCloseThread = nil
    end

    if SideCmdBox:HasFocus() then
        SideCmdBox:ReleaseFocus()
    end

    local tween = TweenService:Create(SideFrame, tweenInfo, {Position = sideClosedPos})
    tween:Play()
    tween.Completed:Connect(function()
        if not isSideOpen then
            SideFrame.Visible = false
        end
    end)
end

SideCmdBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        CmdFeedback = SideCmdFeedback
        local txt = SideCmdBox.Text
        SideCmdBox.Text = ""
        HideSideCommandBar()
        task.spawn(ParseCommand, txt)
    else
        sideCloseThread = task.delay(0.3, function()
            sideCloseThread = nil
            if not SideCmdBox:HasFocus() then
                HideSideCommandBar()
            end
        end)
    end
end)

local Binds = {}
local _lastNameAimlockTarget = nil
local GET_ITEMS={
    ["money"] ={label="💰 Money",   mesh="rbxassetid://511726060",  texture="rbxassetid://511726139", names={"Money","Cash","Dollar","cash","money"}},
    ["grenade"]={label="💣 Grenade", mesh="rbxassetid://436966955",  texture="rbxassetid://436966973", names={"Grenade","grenade","Frag"}},
    ["flash"] ={label="💥 Flash",   mesh="rbxassetid://454819719",  texture="rbxassetid://454819722", names={"Flashbang","Flash","flashbang"}},
    ["golf"] ={label="⛳ Golf",    mesh="rbxassetid://441573384",  texture="rbxassetid://441573394", names={"Golf Ball","GolfBall","golf ball"}},
    ["ar15"] ={label="🔫 AR15",    mesh="rbxassetid://137762422011047",                              names={"AR15","AR-15","ar15"}},
    ["molotov"]={label="🔥 Molotov", mesh="rbxassetid://454823030",  texture="rbxassetid://91135823000526", names={"Molotov","molotov","Cocktail"}},
    ["brick"] ={label="🧱 Brick",   texture="rbxassetid://8236335288",                               names={"Brick","brick"}},
    ["usas"] ={label="🔫 USAS-12", texture="rbxassetid://97657374427072",                           names={"USAS","USAS-12","usas"}},
    ["uzi"]  ={label="🔫 Uzi ",   texture="rbxassetid://4529712484",                               names={"Uzi","uzi","UZI"}},
}

local function ResolveKeyCode(keyStr)
    if #keyStr == 1 and keyStr:match("^%a$") then return "KeyCode." .. keyStr:upper() end
    if keyStr:match("^[fF]%d%d?$") then return "KeyCode." .. keyStr:upper() end
    local named = {
        ["space"] = "KeyCode.Space", ["shift"] = "KeyCode.LeftShift",
        ["lshift"] = "KeyCode.LeftShift", ["rshift"] = "KeyCode.RightShift",
        ["ctrl"] = "KeyCode.LeftControl", ["lctrl"] = "KeyCode.LeftControl",
        ["rctrl"] = "KeyCode.RightControl", ["alt"] = "KeyCode.LeftAlt",
        ["lalt"] = "KeyCode.LeftAlt", ["ralt"] = "KeyCode.RightAlt",
        ["tab"] = "KeyCode.Tab", ["capslock"] = "KeyCode.CapsLock",
        ["enter"] = "KeyCode.Return", ["return"] = "KeyCode.Return",
        ["backspace"] = "KeyCode.Backspace", ["delete"] = "KeyCode.Delete",
        ["insert"] = "KeyCode.Insert", ["home"] = "KeyCode.Home",
        ["end"] = "KeyCode.End", ["pageup"] = "KeyCode.PageUp",
        ["pagedown"] = "KeyCode.PageDown", ["up"] = "KeyCode.Up",
        ["down"] = "KeyCode.Down", ["left"] = "KeyCode.Left",
        ["right"] = "KeyCode.Right", ["num0"] = "KeyCode.Zero",
        ["num1"] = "KeyCode.One", ["num2"] = "KeyCode.Two",
        ["num3"] = "KeyCode.Three", ["num4"] = "KeyCode.Four",
        ["num5"] = "KeyCode.Five", ["num6"] = "KeyCode.Six",
        ["num7"] = "KeyCode.Seven", ["num8"] = "KeyCode.Eight",
        ["num9"] = "KeyCode.Nine",
    }
    return named[keyStr:lower()]
end

local function Notify(title, text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", {
            Title = title,
            Text = text,
            Duration = 3,
        })
    end)
end

local function FireToggle(name)
    if name == "aimlock" then
        local anyActive = Aiming.Enabled or NAME_AIMLOCK_ENABLED
        if anyActive then
            Aiming.Enabled = false
            Settings.Enabled = false
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
            ToggleBtn.Text = "Disabled CursorLock"
            if NAME_AIMLOCK_ENABLED and NAME_AIMLOCK_TARGET then
                _lastNameAimlockTarget = NAME_AIMLOCK_TARGET
            end
            SetAimlockTarget(nil)
            Notify("Aimlock", "🔴 Turned OFF")
        else
            Aiming.Enabled = true
            Settings.Enabled = true
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
            ToggleBtn.Text = "Enabled CursorLock"
            if _lastNameAimlockTarget then
                SetAimlockTarget(_lastNameAimlockTarget)
                _lastNameAimlockTarget = nil
            end
            Notify("Aimlock", "🟢 Turned ON")
        end
    elseif name == "autoreset" then
        AUTO_RESET_ENABLED = not AUTO_RESET_ENABLED
        AutoResetToggle.BackgroundColor3 = AUTO_RESET_ENABLED and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        AutoResetToggle.Text = "Auto Reset (10 HP): " .. (AUTO_RESET_ENABLED and "Enabled" or "Disabled")
        Notify("Auto Reset", AUTO_RESET_ENABLED and "🟢 Turned ON" or "🔴 Turned OFF")
    elseif name == "fly" then
        FLY_ENABLED = not FLY_ENABLED
        FlyToggle.BackgroundColor3 = FLY_ENABLED and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        FlyToggle.Text = "Fly: " .. (FLY_ENABLED and "Enabled" or "Disabled")
        if FLY_ENABLED then StartFly() else StopFly() end
        Notify("Fly", FLY_ENABLED and "🟢 Turned ON" or "🔴 Turned OFF")
    elseif name == "noclip" then
        NOCLIP_ENABLED = not NOCLIP_ENABLED
        NoclipToggle.BackgroundColor3 = NOCLIP_ENABLED and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        NoclipToggle.Text = "Noclip: " .. (NOCLIP_ENABLED and "Enabled" or "Disabled")
        Notify("Noclip", NOCLIP_ENABLED and "🟢 Turned ON" or "🔴 Turned OFF")
    elseif name == "infstam" then
        INFSTAM_ENABLED = not INFSTAM_ENABLED
        InfStamToggle.BackgroundColor3 = INFSTAM_ENABLED and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        InfStamToggle.Text = "Inf Stamina: " .. (INFSTAM_ENABLED and "Enabled" or "Disabled")
        if INFSTAM_ENABLED then 
            ApplyInfStam(LocalPlayer.Character)
        elseif infStamConnection then 
            infStamConnection:Disconnect() 
            infStamConnection = nil 
        end
        Notify("Inf Stamina", INFSTAM_ENABLED and "🟢 Turned ON" or "🔴 Turned OFF")
    elseif name == "camlock" then
        CAMLOCK_ENABLED = not CAMLOCK_ENABLED
        CamlockToggle.BackgroundColor3 = CAMLOCK_ENABLED and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        CamlockToggle.Text = "Camlock: " .. (CAMLOCK_ENABLED and "Enabled" or "Disabled")
        Notify("Camlock", CAMLOCK_ENABLED and "🟢 Turned ON" or "🔴 Turned OFF")
    elseif name == "tpwalk" then
        TPWALK_ENABLED = not TPWALK_ENABLED
        TPWalkToggle.BackgroundColor3 = TPWALK_ENABLED and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        TPWalkToggle.Text = "TP Walk: " .. (TPWALK_ENABLED and "Enabled" or "Disabled")
        Notify("TP Walk", TPWALK_ENABLED and "🟢 Turned ON" or "🔴 Turned OFF")
    elseif name == "fovvisible" then
        Settings.ShowFOV = not Settings.ShowFOV
        Aiming.ShowFOV = Settings.ShowFOV
        FOVCircleToggle.BackgroundColor3 = Settings.ShowFOV and Color3.fromRGB(0, 170, 0) or Color3.fromRGB(170, 0, 0)
        FOVCircleToggle.Text = Settings.ShowFOV and "CursorLock Circle: Visible" or "CursorLock Circle: Hidden"
        Notify("FOV Circle", Settings.ShowFOV and "🟢 Turned ON" or "🔴 Turned OFF")
    elseif name == "keylock" then
        local target = nil
        local shortestDist = math.huge
        local mouseLocation = UserInputService:GetMouseLocation()
        for _, player in pairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local hitpart = player.Character:FindFirstChild(Settings.Hitpart) or player.Character:FindFirstChild("HumanoidRootPart")
                local humanoid = player.Character:FindFirstChildOfClass("Humanoid")
                if hitpart and humanoid and humanoid.Health > 0 then
                    local screenPos, onScreen = Camera:WorldToViewportPoint(hitpart.Position)
                    if onScreen then
                        local dist = (Vector2.new(screenPos.X, screenPos.Y) - mouseLocation).Magnitude
                        if dist < shortestDist then
                            shortestDist = dist
                            target = player
                        end
                    end
                end
            end
        end
        if target then
            Aiming.Enabled = true
            Settings.Enabled = true
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
            ToggleBtn.Text = "Enabled CursorLock"
            SetAimlockTarget(target)
            Notify("KeyLock", "🎯 Locked → " .. target.Name)
        else
            Aiming.Enabled = false
            Settings.Enabled = false
            ToggleBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
            ToggleBtn.Text = "Disabled CursorLock"
            SetAimlockTarget(nil)
            Notify("KeyLock", "🔴 No target — cleared")
        end
    elseif name == "reset" then
        pcall(function() LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health = 0 end)
        Notify("Reset", "💀 Character reset")
    end
end

local VALID_TOGGLES = {
    ["aimlock"] = true, ["autoreset"] = true, ["fly"] = true,
    ["noclip"] = true, ["infstam"] = true, ["camlock"] = true,
    ["tpwalk"] = true, ["fovvisible"] = true, ["keylock"] = true,
    ["reset"] = true,
}

-- -----------------------------------------------------
-- // CMD POPUP WINDOW
-- -----------------------------------------------------

local CMD_LIST = {
    { cmd = "bind ", desc = "Bind a key to toggle a feature on/off" },
    { cmd = "unbind ", desc = "Remove the bind from a toggle" },
    { cmd = "unbind all", desc = "Remove every active bind at once" },
    { cmd = "binds", desc = "List all your currently active binds" },
    { cmd = "get ", desc = "Teleport to item in world" },
    { cmd = "cmd", desc = "Open command list (close with ✕ button)" },
    { cmd = "help", desc = "Quick tip for the command bar" },
    { cmd = "chatenable", desc = "Re-enable the Roblox chat window & input bar" },
    { cmd = "", desc = "── Get: available items ───────────────" },
    { cmd = "money", desc = "→ Scan workspace for money" },
    { cmd = "grenade", desc = "→ Scan workspace for grenades" },
    { cmd = "flash", desc = "→ Scan workspace for flashbangs"},
    { cmd = "golf", desc = "→ Scan workspace for golf ball" },
    { cmd = "ar15", desc = "→ Scan workspace for AR15" },
    { cmd = "molotov", desc = "→ Scan workspace for molotovs" },
    { cmd = "brick", desc = "→ Scan workspace for brick" },
    { cmd = "usas", desc = "→ Scan workspace for USAS-12" },
    { cmd = "uzi", desc = "→ Scan workspace for Uzi" },
    { cmd = "", desc = "── Bindable toggles ──────────────────" },
    { cmd = "aimlock {player}", desc = "Lock aimlock onto player (or 'off' to clear)" },
    { cmd = "autoreset", desc = "Auto reset character at ≤10 HP" },
    { cmd = "fly", desc = "Enable fly mode" },
    { cmd = "unfly", desc = "Disable fly mode" },
    { cmd = "unaimlock", desc = "Turn off ALL aimlock and sync GUI" },
    { cmd = "noclip", desc = "No-clip through walls" },
    { cmd = "infstam", desc = "Enable infinite stamina" },
    { cmd = "uninfstam", desc = "Disable infinite stamina" },
    { cmd = "rejoin", desc = "Rejoin the current server" },
    { cmd = "camlock {player}", desc = "Camlock onto player by name" },
    { cmd = "tpwalk", desc = "Teleport-step walking" },
    { cmd = "fovvisible", desc = "Show / hide the FOV circle" },
    { cmd = "keylock", desc = "Hover cursor on a player + press bind to lock aimlock on them" },
    { cmd = "esp {player}", desc = "Toggle ESP for player (or 'all', 'off')" },
    { cmd = "", desc = "── Movement & Mods ───────────────────" },
    { cmd = "lastpos", desc = "Teleport back to where you died on respawn" },
    { cmd = "unlastpos", desc = "Disable last position teleport" },
    { cmd = "noslow", desc = "Remove slow/action tags (no reload slow, etc.)" },
    { cmd = "unnoslow", desc = "Disable noslow" },
    { cmd = "", desc = "── Reset ─────────────────────────────" },
    { cmd = "bind reset {key}", desc = "Bind a key to instantly reset your character" },
}

local ROW_H = 34
local POPUP_W = 420
local HEADER_H = 38
local CONTENT_H = #CMD_LIST * ROW_H
local screenH = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 600
local MAX_POPUP_H = math.floor(screenH * 0.80)
local POPUP_H = math.min(HEADER_H + CONTENT_H + 8, MAX_POPUP_H)

local CmdPopup = Instance.new("Frame")
CmdPopup.Name = "SlaxCmdPopup"
CmdPopup.Size = UDim2.new(0, POPUP_W, 0, POPUP_H)
CmdPopup.Position = UDim2.new(0.5, 160, 0.5, -POPUP_H/2)
CmdPopup.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
CmdPopup.BorderSizePixel = 1
CmdPopup.BorderColor3 = Color3.fromRGB(50, 50, 50)
CmdPopup.Active = true
CmdPopup.Draggable = false
CmdPopup.Visible = false
CmdPopup.Parent = ScreenGui

do
    local dragging, dragInput, dragStart, startPos
    CmdPopup.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = CmdPopup.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
            end)
        end
    end)
    CmdPopup.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            CmdPopup.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

local PopTitle = Instance.new("TextLabel")
PopTitle.Size = UDim2.new(1, 0, 0, HEADER_H)
PopTitle.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
PopTitle.BorderSizePixel = 0
PopTitle.Text = "⌨️ SLAXWARE COMMAND LIST"
PopTitle.TextColor3 = Color3.fromRGB(0, 180, 255)
PopTitle.TextSize = 13
PopTitle.Font = Enum.Font.GothamBold
PopTitle.Parent = CmdPopup

local PopCloseBtn = Instance.new("TextButton")
PopCloseBtn.Size = UDim2.new(0, 24, 0, 24)
PopCloseBtn.Position = UDim2.new(1, -30, 0, 7)
PopCloseBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
PopCloseBtn.BorderSizePixel = 0
PopCloseBtn.Text = "✕"
PopCloseBtn.TextColor3 = Color3.new(1, 1, 1)
PopCloseBtn.TextSize = 14
PopCloseBtn.Font = Enum.Font.GothamBold
PopCloseBtn.ZIndex = 2
PopCloseBtn.Parent = CmdPopup

do
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = PopCloseBtn
end

PopCloseBtn.MouseEnter:Connect(function()
    PopCloseBtn.BackgroundColor3 = Color3.fromRGB(220, 50, 50)
end)
PopCloseBtn.MouseLeave:Connect(function()
    PopCloseBtn.BackgroundColor3 = Color3.fromRGB(180, 30, 30)
end)
PopCloseBtn.MouseButton1Click:Connect(function()
    CmdPopup.Visible = false
end)

local PopScroll = Instance.new("ScrollingFrame")
PopScroll.Size = UDim2.new(1, 0, 1, -HEADER_H)
PopScroll.Position = UDim2.new(0, 0, 0, HEADER_H)
PopScroll.BackgroundTransparency = 1
PopScroll.BorderSizePixel = 0
PopScroll.ScrollBarThickness = 6
PopScroll.CanvasSize = UDim2.new(0, 0, 0, CONTENT_H)
PopScroll.Parent = CmdPopup

local PopLayout = Instance.new("UIListLayout")
PopLayout.SortOrder = Enum.SortOrder.LayoutOrder
PopLayout.Parent = PopScroll

for i, cmdInfo in ipairs(CMD_LIST) do
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, ROW_H)
    row.BackgroundTransparency = 1
    row.LayoutOrder = i
    row.Parent = PopScroll

    if cmdInfo.cmd ~= "" then
        local cmdLbl = Instance.new("TextLabel")
        cmdLbl.Size = UDim2.new(0.35, -12, 1, 0)
        cmdLbl.Position = UDim2.new(0, 12, 0, 0)
        cmdLbl.BackgroundTransparency = 1
        cmdLbl.Text = cmdInfo.cmd
        cmdLbl.TextColor3 = Color3.fromRGB(0, 210, 255)
        cmdLbl.TextSize = 12
        cmdLbl.Font = Enum.Font.Code
        cmdLbl.TextXAlignment = Enum.TextXAlignment.Left
        cmdLbl.Parent = row

        local descLbl = Instance.new("TextLabel")
        descLbl.Size = UDim2.new(0.65, -12, 1, 0)
        descLbl.Position = UDim2.new(0.35, 6, 0, 0)
        descLbl.BackgroundTransparency = 1
        descLbl.Text = cmdInfo.desc
        descLbl.TextColor3 = Color3.fromRGB(180, 180, 180)
        descLbl.TextSize = 11
        descLbl.Font = Enum.Font.Gotham
        descLbl.TextXAlignment = Enum.TextXAlignment.Left
        descLbl.Parent = row
    else
        local sepLbl = Instance.new("TextLabel")
        sepLbl.Size = UDim2.new(1, -24, 1, 0)
        sepLbl.Position = UDim2.new(0, 12, 0, 0)
        sepLbl.BackgroundTransparency = 1
        sepLbl.Text = cmdInfo.desc
        sepLbl.TextColor3 = Color3.fromRGB(100, 100, 100)
        sepLbl.TextSize = 11
        sepLbl.Font = Enum.Font.GothamBold
        sepLbl.TextXAlignment = Enum.TextXAlignment.Left
        sepLbl.Parent = row
    end
end

-- -----------------------------------------------------
-- // COMMAND INTERPRETER ENGINE
-- -----------------------------------------------------

local function FindPlayerByName(query)
    if not query or query == "" then return nil end
    local q = query:lower()
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if plr.Name:lower() == q or plr.DisplayName:lower() == q then return plr end
        end
    end
    for _, plr in pairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer then
            if plr.Name:lower():find(q, 1, true) or plr.DisplayName:lower():find(q, 1, true) then return plr end
        end
    end
    return nil
end

local function SetCamlockTarget(plr)
    CAMLOCK_TARGET = plr
    if plr then
        CamlockDropBtn.Text = "▼ " .. plr.Name
        CamlockDropBtn.TextColor3 = Color3.new(1, 1, 1)
        TargetLabel.Text = "Target: " .. plr.Name
    else
        CamlockDropBtn.Text = "▼ Select Player..."
        CamlockDropBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
        TargetLabel.Text = "Target: none"
    end
end

function ParseCommand(inputStr)
    local cleanInput = inputStr:match("^%s*(.-)%s*$")
    if cleanInput == "" then return end

    local parts = {}
    for word in cleanInput:gmatch("%S+") do table.insert(parts, word) end
    if #parts == 0 then return end
    local cmd = parts[1]:lower()

    if cmd == "help" then
        CmdFeedback.TextColor3 = Color3.fromRGB(0, 200, 255)
        CmdFeedback.Text = "Try: bind aimlock f  | unbind aimlock  |  get money  |  cmd"
        return
    end

    if cmd == "cmd" then
        CmdPopup.Visible = true
        CmdFeedback.TextColor3 = Color3.fromRGB(0, 200, 80)
        CmdFeedback.Text = "Opened command list  (press ✕ to close)"
        return
    end

    if cmd == "chatenable" then
        pcall(function() game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Chat, true) end)
        pcall(function()
            local tcs = game:GetService("TextChatService")
            if tcs then
                tcs.ChatWindowConfiguration.Enabled = true
                tcs.ChatInputBarConfiguration.Enabled = true
            end
        end)
        pcall(function() game:GetService("Chat"):SetVisible(true) end)
        pcall(function()
            local pg = LocalPlayer:WaitForChild("PlayerGui", 3)
            if pg then
                for _, gui in ipairs(pg:GetChildren()) do
                    if gui.Name == "Chat" or gui.Name == "BubbleChat" then gui.Enabled = true end
                end
            end
        end)
        CmdFeedback.TextColor3 = Color3.fromRGB(0, 200, 80)
        CmdFeedback.Text = "✅ Chat Re-Enabled"
        Notify("Chat", "✅ Chat restored")
        return
    end

    if cmd == "rejoin" then
        CmdFeedback.TextColor3 = Color3.fromRGB(255, 180, 0)
        CmdFeedback.Text = "Rejoining server..."
        task.wait(0.5)
        pcall(function() game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end)
        return
    end

    if cmd == "camlock" then
        if #parts >= 2 then
            local arg = parts[2]:lower()
            if arg == "off" or arg == "none" or arg == "clear" then
                CAMLOCK_ENABLED = false
                CamlockToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
                CamlockToggle.Text = "Camlock: Disabled"
                SetCamlockTarget(nil)
                CmdFeedback.TextColor3 = Color3.fromRGB(255, 180, 0)
                CmdFeedback.Text = "Camlock cleared"
                Notify("Camlock", "🔴 Cleared")
            else
                local target = FindPlayerByName(parts[2])
                if target then
                    SetCamlockTarget(target)
                    CAMLOCK_ENABLED = true
                    CamlockToggle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
                    CamlockToggle.Text = "Camlock: Enabled"
                    CmdFeedback.TextColor3 = Color3.fromRGB(0, 220, 80)
                    CmdFeedback.Text = "Camlock → " .. target.Name
                    Notify("Camlock", "🟢 Locked onto " .. target.Name)
                else
                    CmdFeedback.TextColor3 = Color3.fromRGB(255, 80, 80)
                    CmdFeedback.Text = "Player not found: " .. parts[2]
                end
            end
        else
            FireToggle("camlock")
        end
        return
    end

    if cmd == "aimlock" then
        if #parts >= 2 then
            local arg = parts[2]:lower()
            if arg == "off" or arg == "none" or arg == "clear" then
                Aiming.Enabled = false
                Settings.Enabled = false
                ToggleBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
                ToggleBtn.Text = "Disabled CursorLock"
                SetAimlockTarget(nil)
                CmdFeedback.TextColor3 = Color3.fromRGB(255, 180, 0)
                CmdFeedback.Text = "Aimlock cleared"
                Notify("Aimlock", "🔴 Cleared")
            else
                local target = FindPlayerByName(parts[2])
                if target then
                    Aiming.Enabled = true
                    Settings.Enabled = true
                    ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
                    ToggleBtn.Text = "Enabled CursorLock"
                    SetAimlockTarget(target)
                    CmdFeedback.TextColor3 = Color3.fromRGB(0, 220, 80)
                    CmdFeedback.Text = "Aimlock → " .. target.Name
                    Notify("Aimlock", "🟢 Locked onto " .. target.Name)
                else
                    CmdFeedback.TextColor3 = Color3.fromRGB(255, 80, 80)
                    CmdFeedback.Text = "Player not found: " .. parts[2]
                end
            end
        else
            FireToggle("aimlock")
        end
        return
    end

    if cmd == "esp" then
        if #parts >= 2 then
            local arg = parts[2]:lower()
            if arg == "all" then
                ESP_All = true
                ESP_Players = {}
                UpdateESPBtnLabel()
                CmdFeedback.TextColor3 = Color3.fromRGB(0, 220, 80)
                CmdFeedback.Text = "ESP: All players"
                Notify("ESP", "🟢 All players")
            elseif arg == "off" or arg == "none" or arg == "clear" then
                ESP_All = false
                ESP_Players = {}
                UpdateESPBtnLabel()
                CmdFeedback.TextColor3 = Color3.fromRGB(255, 180, 0)
                CmdFeedback.Text = "ESP cleared"
                Notify("ESP", "🔴 Cleared")
            else
                local target = FindPlayerByName(parts[2])
                if target then
                    if ESP_All then ESP_All = false ESP_Players = {} end
                    if ESP_Players[target] then
                        ESP_Players[target] = nil
                        CmdFeedback.TextColor3 = Color3.fromRGB(255, 180, 0)
                        CmdFeedback.Text = "ESP removed: " .. target.Name
                        Notify("ESP", "🔴 Removed " .. target.Name)
                    else
                        ESP_Players[target] = true
                        CmdFeedback.TextColor3 = Color3.fromRGB(0, 220, 80)
                        CmdFeedback.Text = "ESP → " .. target.Name
                        Notify("ESP", "🟢 " .. target.Name)
                    end
                    UpdateESPBtnLabel()
                else
                    CmdFeedback.TextColor3 = Color3.fromRGB(255, 80, 80)
                    CmdFeedback.Text = "Player not found: " .. parts[2]
                end
            end
        else
            CmdFeedback.TextColor3 = Color3.fromRGB(200, 200, 200)
            CmdFeedback.Text = "Usage: esp {player} | esp all | esp off"
        end
        return
    end

    if cmd == "fly" then
        if not FLY_ENABLED then
            FLY_ENABLED = true
            FLY_SPEED = 50
            FlySpeedLabel.Text = "Fly Speed: 50"
            FlySpeedKnob.Position = UDim2.new((50 - 10) / 290, -8, 0.5, -8)
            FlyToggle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
            FlyToggle.Text = "Fly: Enabled"
            StartFly()
            Notify("Fly", "🟢 Fly ON")
            CmdFeedback.TextColor3 = Color3.fromRGB(0, 220, 80)
            CmdFeedback.Text = "Fly enabled"
        else
            CmdFeedback.TextColor3 = Color3.fromRGB(180, 180, 180)
            CmdFeedback.Text = "Fly is already on (use unfly to stop)"
        end
        return
    end

    if cmd == "unfly" then
        if FLY_ENABLED then
            FLY_ENABLED = false
            FlyToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
            FlyToggle.Text = "Fly: Disabled"
            StopFly()
            Notify("Fly", "🔴 Fly OFF")
            CmdFeedback.TextColor3 = Color3.fromRGB(255, 180, 0)
            CmdFeedback.Text = "Fly disabled"
        else
            CmdFeedback.TextColor3 = Color3.fromRGB(180, 180, 180)
            CmdFeedback.Text = "Fly is already off"
        end
        return
    end

    if cmd == "infstam" then
        if INFSTAM_ENABLED then
            CmdFeedback.TextColor3 = Color3.fromRGB(180, 180, 180)
            CmdFeedback.Text = "Inf Stamina is already ON"
            return
        end
        INFSTAM_ENABLED = true
        InfStamToggle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
        InfStamToggle.Text = "Inf Stamina: Enabled"
        ApplyInfStam(LocalPlayer.Character)
        CmdFeedback.TextColor3 = Color3.fromRGB(0, 220, 80)
        CmdFeedback.Text = "Inf Stamina: ON"
        Notify("Inf Stamina", "🟢 Enabled")
        return
    end

    if cmd == "uninfstam" then
        if not INFSTAM_ENABLED then
            CmdFeedback.TextColor3 = Color3.fromRGB(180, 180, 180)
            CmdFeedback.Text = "Inf Stamina is already OFF"
            return
        end
        INFSTAM_ENABLED = false
        InfStamToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        InfStamToggle.Text = "Inf Stamina: Disabled"
        if infStamConnection then infStamConnection:Disconnect() infStamConnection = nil end
        CmdFeedback.TextColor3 = Color3.fromRGB(255, 180, 0)
        CmdFeedback.Text = "Inf Stamina: OFF"
        Notify("Inf Stamina", "🔴 Disabled")
        return
    end

    if cmd == "unaimlock" then
        Aiming.Enabled = false
        Settings.Enabled = false
        ToggleBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
        ToggleBtn.Text = "Disabled CursorLock"
        SetAimlockTarget(nil)
        _lastNameAimlockTarget = nil
        Notify("Aimlock", "🔴 All aimlock OFF")
        CmdFeedback.TextColor3 = Color3.fromRGB(255, 180, 0)
        CmdFeedback.Text = "All aimlock cleared"
        return
    end

    if cmd == "bind" then
        if #parts < 3 then
            CmdFeedback.TextColor3 = Color3.fromRGB(255, 80, 80)
            CmdFeedback.Text = "Usage: bind [toggleName] [key]"
            return
        end
        local toggleName = parts[2]:lower()
        local keyStr = parts[3]:lower()

        if not VALID_TOGGLES[toggleName] then
            CmdFeedback.TextColor3 = Color3.fromRGB(255, 80, 80)
            CmdFeedback.Text = "Unknown toggle: " .. toggleName
            return
        end

        local keyEnumName = ResolveKeyCode(keyStr)
        if not keyEnumName then
            CmdFeedback.TextColor3 = Color3.fromRGB(255, 80, 80)
            CmdFeedback.Text = "Invalid key: " .. keyStr
            return
        end

        Binds[toggleName] = Enum.KeyCode[string.split(keyEnumName, ".")[2]]
        CmdFeedback.TextColor3 = Color3.fromRGB(0, 200, 80)
        CmdFeedback.Text = "Bound " .. toggleName .. " to " .. keyStr:upper()
        Notify("Bind Set", "🔑 " .. toggleName .. " → " .. keyStr:upper())
        return
    end

    if cmd == "unbind" then
        if #parts < 2 then
            CmdFeedback.TextColor3 = Color3.fromRGB(255, 80, 80)
            CmdFeedback.Text = "Usage: unbind  | unbind all"
            return
        end
        local toggleName = parts[2]:lower()
        if toggleName == "all" then
            local count = 0
            for k in pairs(Binds) do Binds[k] = nil; count = count + 1 end
            CmdFeedback.TextColor3 = Color3.fromRGB(255, 180, 0)
            CmdFeedback.Text = "Unbound all (" .. count .. ") binds"
            Notify("Unbind All", "🔴 Cleared " .. count .. " bind(s)")
            return
        end
        if not VALID_TOGGLES[toggleName] then
            CmdFeedback.TextColor3 = Color3.fromRGB(255, 80, 80)
            CmdFeedback.Text = "Unknown toggle: " .. toggleName
            return
        end
        if Binds[toggleName] then
            local oldKey = tostring(Binds[toggleName]):gsub("Enum.KeyCode.", "")
            Binds[toggleName] = nil
            CmdFeedback.TextColor3 = Color3.fromRGB(255, 180, 0)
            CmdFeedback.Text = "Unbound " .. toggleName
            Notify("Unbound", "🔴 " .. toggleName .. " (" .. oldKey .. ") removed")
        else
            CmdFeedback.TextColor3 = Color3.fromRGB(160, 160, 160)
            CmdFeedback.Text = toggleName .. " has no bind"
        end
        return
    end

    if cmd == "binds" then
        local out = ""
        for name, key in pairs(Binds) do
            out = out .. name .. "=" .. tostring(key).." "
        end
        CmdFeedback.TextColor3 = Color3.fromRGB(180, 180, 255)
        CmdFeedback.Text = out ~= "" and ("Binds: " .. out) or "No binds set"
        return
    end

    if cmd == "get" then
        if #parts < 2 then
            CmdFeedback.TextColor3 = Color3.fromRGB(255, 80, 80)
            CmdFeedback.Text = "Usage: get (e.g. get money)"
            return
        end

        local ITEM_MAP = { ["ammo"] = "Buy Ammo | $25" }
        local FIND_CLOSEST = { ["Buy Ammo | $25"] = true }
        local itemKey=parts[2]:lower()
        local iDef=GET_ITEMS[itemKey]
        if iDef then
            local function nId(s) return tostring(s):lower():gsub("%s+","") end
            local function mI(o)
                local c=o.ClassName;local m=iDef.mesh and nId(iDef.mesh);local t=iDef.texture and nId(iDef.texture)
                if c=="SpecialMesh" or c=="FileMesh" then return (m and nId(o.MeshId)==m) or (t and nId(o.TextureId)==t)
                elseif c=="MeshPart" then return (m and nId(o.MeshId)==m) or (t and nId(o.TextureId)==t)
                elseif c=="Texture" or c=="Decal" then return t and nId(o.Texture)==t
                end;return false
            end
            CmdFeedback.TextColor3=Color3.fromRGB(255,215,0)
            CmdFeedback.Text="🔍 Scanning for "..itemKey.."..."
            Notify("Get","🔍 "..itemKey)
            task.spawn(function()
                local fd,sn={},{}
                for i,o in ipairs(workspace:GetDescendants()) do
                    if i%200==0 then task.wait() end
                    local ok,h=pcall(mI,o)
                    if ok and h then
                        local a=o.Parent
                        while a and a~=workspace do if a:IsA("Model") then break end;a=a.Parent end
                        local tg=(a and a~=workspace and a:IsA("Model")) and a or (o:IsA("BasePart") and o) or (o.Parent and o.Parent:IsA("BasePart") and o.Parent)
                        if tg and not sn[tg] then sn[tg]=true;table.insert(fd,tg) end
                    end
                end
                if #fd==0 then CmdFeedback.TextColor3=Color3.fromRGB(255,80,80);CmdFeedback.Text="No "..itemKey.." found";Notify("Get","❌ Not found");return end
                local hn=LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart");local cl=fd[1]
                if hn and #fd>1 then local b=math.huge
                    for _,m in ipairs(fd) do local p
                        if m:IsA("Model") then p=m.PrimaryPart and m.PrimaryPart.Position;if not p then for _,v in pairs(m:GetDescendants()) do if v:IsA("BasePart") then p=v.Position;break end end end
                        elseif m:IsA("BasePart") then p=m.Position end
                        if p then local d=(p-hn.Position).Magnitude;if d > 0.01 then hn.CFrame=CFrame.lookAt(hn.Position,p) end end
                    end
                end
                local tp;if cl:IsA("Model") then tp=cl.PrimaryPart and cl.PrimaryPart.Position
                    if not tp then for _,v in pairs(cl:GetDescendants()) do if v:IsA("BasePart") then tp=v.Position;break end end end
                elseif cl:IsA("BasePart") then tp=cl.Position end
                if not tp then CmdFeedback.TextColor3=Color3.fromRGB(255,80,80);CmdFeedback.Text="No position";return end
                if tp.Y < -50 then CmdFeedback.TextColor3=Color3.fromRGB(255,140,0);CmdFeedback.Text="⚠️ "..itemKey.." appears to be in the void — skipped";return end
                local ch=LocalPlayer.Character;local hr=ch and ch:FindFirstChild("HumanoidRootPart")
                if not hr then CmdFeedback.TextColor3=Color3.fromRGB(255,80,80);CmdFeedback.Text="No HRP";return end

                local _wasNoclip = NOCLIP_ENABLED
                NOCLIP_ENABLED = true

                local dY = (tp.Y - hr.Position.Y)
                local steps = math.max(1, math.floor(math.abs(dY)/12))
                for i=1,steps do
                    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
                    hr.CFrame = hr.CFrame + Vector3.new(0, dY/steps, 0)
                    task.wait(0.04)
                end

                local startPos = hr.Position
                local path = tp - startPos
                local dist = path.Magnitude
                local sSpeed = 140 
                local stepCount = math.max(1, math.floor(dist / (sSpeed * 0.03)))
                for i=1,stepCount do
                    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then return end
                    local fp = startPos + (path * (i/stepCount))
                    hr.CFrame = CFrame.new(fp)
                    task.wait(0.03)
                end

                if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                    hr.CFrame = CFrame.new(tp + Vector3.new(0, 3, 0))
                end
                task.wait(0.2)

                local prompt = cl:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    pcall(function()
                        prompt.MaxActivationDistance = 999
                        prompt.HoldDuration = 0
                        prompt.RequiresLineOfSight = false
                        prompt:InputHoldBegin()
                        task.wait(prompt.HoldDuration)
                        prompt:InputHoldEnd()
                    end)
                end
                task.wait(0.1)

                if not _wasNoclip then
                    NOCLIP_ENABLED = false
                    NoclipToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
                    NoclipToggle.Text = "Noclip: Disabled"
                end
                CmdFeedback.TextColor3=Color3.fromRGB(0,220,80);CmdFeedback.Text="✅ Arrived at "..itemKey.."!"
                Notify("Get","✅ "..itemKey)
            end);return
        end

        local modelName = ITEM_MAP[itemKey]
        if not modelName then
            CmdFeedback.TextColor3 = Color3.fromRGB(255, 80, 80)
            CmdFeedback.Text = "Unknown item: " .. itemKey .. " (try: uzi)"
            return
        end

        local model
        if FIND_CLOSEST[modelName] then
            local hrpNow = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            local bestDist = math.huge
            for _, obj in pairs(workspace:GetDescendants()) do
                if obj.Name == modelName then
                    local pos
                    if obj:IsA("Model") then
                        pos = obj.PrimaryPart and obj.PrimaryPart.Position
                            or (function()
                                for _, v in pairs(obj:GetDescendants()) do
                                    if v:IsA("BasePart") then return v.Position end
                                end
                            end)()
                    elseif obj:IsA("BasePart") then
                        pos = obj.Position
                    end
                    if pos and hrpNow then
                        local d = (pos - hrpNow.Position).Magnitude
                        if d < bestDist then bestDist = d; model = obj end
                    end
                end
            end
        else
            model = workspace:FindFirstChild(modelName, true)
        end
        if not model then
            CmdFeedback.TextColor3 = Color3.fromRGB(255, 80, 80)
            CmdFeedback.Text = modelName .. " not found in workspace"
            return
        end

        local targetPos
        if model:IsA("Model") then
            if model.PrimaryPart then
                targetPos = model.PrimaryPart.Position
            else
                for _, v in pairs(model:GetDescendants()) do
                    if v:IsA("BasePart") then
                        targetPos = v.Position
                        break
                    end
                end
            end
        elseif model:IsA("BasePart") then
            targetPos = model.Position
        end

        if not targetPos then
            CmdFeedback.TextColor3 = Color3.fromRGB(255, 80, 80)
            CmdFeedback.Text = "Couldn't find position for " .. modelName
            return
        end

        local character = LocalPlayer.Character
        local hrp = character and character:FindFirstChild("HumanoidRootPart")
        if not hrp then
            CmdFeedback.TextColor3 = Color3.fromRGB(255, 80, 80)
            CmdFeedback.Text = "No character — respawn and try again"
            return
        end

        local destCFrame = CFrame.new(targetPos + Vector3.new(0, 4, 0))
        local baseName = (modelName:match("^(.-)%s*\|") or modelName):match("^%s*(.-)%s*$")

        local function toolInInventory()
            local containers = { LocalPlayer.Backpack }
            if LocalPlayer.Character then
                table.insert(containers, LocalPlayer.Character)
            end
            for _, container in pairs(containers) do
                for _, item in pairs(container:GetChildren()) do
                    if item:IsA("Tool") then
                        local n = item.Name
                        if n == modelName or n == baseName
                            or n:lower():find(baseName:lower(), 1, true) then
                            return true
                        end
                    end
                end
            end
            return false
        end

        CmdFeedback.TextColor3 = Color3.fromRGB(0, 200, 80)
        CmdFeedback.Text = "Going to " .. modelName .. "..."
        Notify("Get", "📦 Going to " .. modelName)

        task.spawn(function()
            local MAX_ATTEMPTS = (itemKey == "ammo") and 1 or 20
            local attempt = 0

            while attempt < MAX_ATTEMPTS and not toolInInventory() do
                attempt = attempt + 1

                do
                    local STEP_SPEED = 140 
                    local ARRIVE_DIST = 0.5 
                    local MAX_STEPS = 400 
                    local finalPos = nil 

                    for _ = 1, MAX_STEPS do
                        local livePos
                        if model:IsA("Model") then
                            livePos = model.PrimaryPart and model.PrimaryPart.Position
                            if not livePos then
                                for _, v in pairs(model:GetDescendants()) do
                                    if v:IsA("BasePart") then livePos = v.Position; break end
                                end
                            end
                        elseif model:IsA("BasePart") then
                            livePos = model.Position
                        end
                        if not livePos then break end 
                        finalPos = livePos
                        local diff = livePos - hrp.Position
                        if diff.Magnitude <= ARRIVE_DIST then break end

                        hrp.CFrame = hrp.CFrame + diff.Unit * math.min(STEP_SPEED * 0.016, diff.Magnitude)
                        task.wait() 
                    end

                    if finalPos then
                        local lookDir = (finalPos - hrp.Position)
                        if lookDir.Magnitude > 0.01 then
                            hrp.CFrame = CFrame.lookAt(hrp.Position, finalPos)
                        end
                    end
                end
                task.wait(0.05)

                local prompt = model:FindFirstChildWhichIsA("ProximityPrompt", true)
                if prompt then
                    pcall(function()
                        prompt.MaxActivationDistance = 999
                        prompt.HoldDuration = 0
                        prompt.RequiresLineOfSight = false
                        prompt:InputHoldBegin()
                        task.wait(prompt.HoldDuration)
                        prompt:InputHoldEnd()
                    end)
                end
                task.wait(0.15)
            end

            if toolInInventory() then
                CmdFeedback.TextColor3 = Color3.fromRGB(0, 220, 80)
                CmdFeedback.Text = "✅ Successfully obtained " .. baseName .. "!"
                Notify("Get", "✅ Got " .. baseName)
            else
                CmdFeedback.TextColor3 = Color3.fromRGB(255, 120, 0)
                CmdFeedback.Text = "⚠️ Finished teleport sequence for " .. baseName
                Notify("Get", "⚠️ Done (" .. baseName .. ")")
            end
        end)
        return
    end

    if cmd == "lastpos" then
        LASTPOS_ENABLED = true
        CmdFeedback.TextColor3 = Color3.fromRGB(0, 220, 80)
        CmdFeedback.Text = "Last Pos: ON — will teleport on next respawn"
        Notify("Last Pos", "🟢 Enabled — die to save a position")
        return
    end

    if cmd == "unlastpos" then
        LASTPOS_ENABLED = false
        CmdFeedback.TextColor3 = Color3.fromRGB(255, 180, 0)
        CmdFeedback.Text = "Last Pos: OFF"
        Notify("Last Pos", "🔴 Disabled")
        return
    end

    if cmd == "noslow" then
        if NOSLOW_ENABLED then
            CmdFeedback.TextColor3 = Color3.fromRGB(180, 180, 180)
            CmdFeedback.Text = "NoSlow is already ON (use unnoslow to disable)"
            return
        end
        NOSLOW_ENABLED = true
        HookTagSystem() 
        local char = LocalPlayer.Character
        if char then
            for _, child in pairs(char:GetChildren()) do
                if NOSLOW_TAGS[child.Name:lower()] then
                    pcall(function() child:Destroy() end)
                end
            end
        end
        CmdFeedback.TextColor3 = Color3.fromRGB(0, 220, 80)
        CmdFeedback.Text = "NoSlow: ON"
        Notify("NoSlow", "🟢 Slow tags blocked (Heartbeat + TagSystem)")
        return
    end

    if cmd == "unnoslow" then
        if not NOSLOW_ENABLED then
            CmdFeedback.TextColor3 = Color3.fromRGB(180, 180, 180)
            CmdFeedback.Text = "NoSlow is already OFF"
            return
        end
        NOSLOW_ENABLED = false
        if NOSLOW_CONNECTION then NOSLOW_CONNECTION:Disconnect() NOSLOW_CONNECTION = nil end
        CmdFeedback.TextColor3 = Color3.fromRGB(255, 180, 0)
        CmdFeedback.Text = "NoSlow: OFF"
        Notify("NoSlow", "🔴 Disabled")
        return
    end

    CmdFeedback.TextColor3 = Color3.fromRGB(255, 80, 80)
    CmdFeedback.Text = "Unknown command: " .. cmd .. " (try: cmd)"
end

CmdBarBox.FocusLost:Connect(function(enterPressed)
    if enterPressed then
        CmdFeedback = MainCmdFeedback
        local txt = CmdBarBox.Text
        CmdBarBox.Text = ""
        SlideCmdBarOut()
        task.spawn(ParseCommand, txt)
    else
        cmdBarCloseThread = task.delay(0.4, function()
            cmdBarCloseThread = nil 
            if not CmdBarBox:IsFocused() then
                SlideCmdBarOut()
            end
        end)
    end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    for toggleName, boundKey in pairs(Binds) do
        if input.KeyCode == boundKey then
            FireToggle(toggleName)
        end
    end

    if input.KeyCode == Enum.KeyCode.K then
        Frame.Visible = not Frame.Visible
        HideSideCommandBar()
        SlideCmdBarOut()
    end
end)

local function handleCmdOpen(actionName, inputState, inputObject)
    if inputState ~= Enum.UserInputState.Begin then
        return Enum.ContextActionResult.Pass
    end

    local focusedTextBox = UserInputService:GetFocusedTextBox()

    if focusedTextBox == CmdBarBox then
        return Enum.ContextActionResult.Pass
    end

    if focusedTextBox == SideCmdBox then
        return Enum.ContextActionResult.Pass
    end

    if isCmdBarOpen then
        SlideCmdBarOut()
    else
        SlideCmdBarIn()
    end
    return Enum.ContextActionResult.Sink
end

ContextActionService:BindAction("ColonBind", handleCmdOpen, false, Enum.KeyCode.Semicolon)

local lastFeedbackTime = 0
local lastSideFeedbackTime = 0
task.spawn(function()
    while true do
        task.wait(1)
        if MainCmdFeedback.Text ~= "" then
            lastFeedbackTime = lastFeedbackTime + 1
            if lastFeedbackTime >= 4 then
                MainCmdFeedback.Text = ""
                lastFeedbackTime = 0
            end
        else
            lastFeedbackTime = 0
        end

        if SideCmdFeedback.Text ~= "" then
            lastSideFeedbackTime = lastSideFeedbackTime + 1
            if lastSideFeedbackTime >= 4 then
                SideCmdFeedback.Text = ""
                lastSideFeedbackTime = 0
            end
        else
            lastSideFeedbackTime = 0
        end
    end
end)

task.spawn(function()
    while true do
        local hue = (tick() % 5) / 5 
        local color = Color3.fromHSV(hue, 1, 1)
        if Title then Title.TextColor3 = color end
        if SideTitle then SideTitle.TextColor3 = color end
        task.wait()
    end
end)

-- // ESP - Full Body Highlight + Classic Nametags
_G.FriendColor = Color3.fromRGB(0, 0, 255)
_G.EnemyColor = Color3.fromRGB(255, 0, 0)
_G.UseTeamColor = true

local function CreateFullHighlight(character, player)
    if not character or not ShouldESP(player) then return end

    for _, v in pairs(character:GetChildren()) do
        if v:IsA("Highlight") and v.Name == "SlaxrFullESP" then v:Destroy() end
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "SlaxrFullESP"
    highlight.Adornee = character
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.OutlineColor = Color3.new(1, 1, 1)

    if _G.UseTeamColor and player.TeamColor then
        highlight.FillColor = player.TeamColor.Color
    else
        highlight.FillColor = (LocalPlayer.TeamColor == player.TeamColor) and _G.FriendColor or _G.EnemyColor
    end

    highlight.Parent = character
end

local function CreateNametag(player)
    if player == LocalPlayer then return end

    local function Setup(char)
        if not char or not char:FindFirstChild("Head") then return end
        local Head = char.Head

        local old = Head:FindFirstChild("SlaxrNametag")
        if old then old:Destroy() end

        local BillboardGui = Instance.new("BillboardGui")
        BillboardGui.Name = "SlaxrNametag"
        BillboardGui.Adornee = Head
        BillboardGui.Size = UDim2.new(0, 200, 0, 50)
        BillboardGui.StudsOffset = Vector3.new(0, 2.5, 0)
        BillboardGui.AlwaysOnTop = true
        BillboardGui.Parent = Head

        local TextLabel = Instance.new("TextLabel")
        TextLabel.Size = UDim2.new(1, 0, 1, 0)
        TextLabel.BackgroundTransparency = 1
        TextLabel.Text = player.Name
        TextLabel.TextColor3 = Color3.new(1, 1, 1)

        TextLabel.TextStrokeTransparency = 0.4
        TextLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
        TextLabel.Font = Enum.Font.SourceSansBold
        TextLabel.TextSize = 16
        TextLabel.Parent = BillboardGui
    end

    if player.Character then Setup(player.Character) end
    player.CharacterAdded:Connect(Setup)
end

local function UpdateESP()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer then
            if ShouldESP(player) and player.Character then
                CreateFullHighlight(player.Character, player)
                CreateNametag(player)
            else
                if player.Character then
                    for _, v in pairs(player.Character:GetChildren()) do
                        if v:IsA("Highlight") and v.Name == "SlaxrFullESP" then
                            v:Destroy()
                        end
                    end
                    local nt = player.Character:FindFirstChild("SlaxrNametag", true)
                    if nt then nt:Destroy() end
                end
            end
        end
    end
end

for _, v in pairs(Players:GetPlayers()) do
    if v ~= LocalPlayer then
        CreateNametag(v)
    end
end

Players.PlayerAdded:Connect(function(plr)
    if plr ~= LocalPlayer then
        CreateNametag(plr)
    end
end)

task.spawn(function()
    while true do
        task.wait(0.4)
        UpdateESP()
    end
end)

-- Execute Start Notification
pcall(function()
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = "SLAXWARE 🐈",
        Text = "K TO HIDE GUI / \":\" KEY FOR CMDBAR",
        Icon = "rbxassetid://93029943108776",
        Duration = 8,
    })
end)

print("✅ SlaxWare Loaded | Press : to open command bar | K to toggle main GUI")
