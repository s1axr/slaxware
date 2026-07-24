--[[

 ____ __ __ _ _ _ _ __ ____ ____
/ ___)( ) / _\ ( \/ )/ )( \ / _\ ( _ \( __)
\___ \/ (_/\/ \ ) ( \ /\ // \ ) / ) _)
(____/\____/\_/\_/(_/\_)(_/\_)\_/\_/(__\_)(____)

-- made by grok ai btw lol cry idgaf
-- Optimized UI Framework (Zero Local Limits)
-- Features: auto-reset at 10hp, aimlock, esp, camlock, custom bullets, config save

]]

-- // Remove 0Box early
if workspace:FindFirstChild("0Box") then workspace["0Box"]:Destroy() end

-- // Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local ContextActionService = game:GetService("ContextActionService")
local HttpService = game:GetService("HttpService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- // GLOBAL VARIABLES & CONFIG
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
getgenv().FLY_SPEED = 50
getgenv().TPWALK_SPEED = 15

local Camera = workspace.CurrentCamera
local Binds = {}

local BULLET_TRAILS_ENABLED = false
local APPLY_TO_EVERYONE = false
local BulletColour = ColorSequence.new(Color3.fromRGB(255, 255, 255))
local TrailTime = 0.2
local BulletTransparency = 0.0

local CONFIG_FILE = "slaxware_config.json"

local function SaveConfig()
    if not writefile then return end
    local config = {
        Binds = {}, FlySpeed = FLY_SPEED, TPWalkSpeed = TPWALK_SPEED,
        FOVSize = Settings.FOV, TrailTime = TrailTime, BulletTransparency = BulletTransparency,
        BulletR = BulletColour.Keypoints[1].Value.R, BulletG = BulletColour.Keypoints[1].Value.G, BulletB = BulletColour.Keypoints[1].Value.B
    }
    for tName, key in pairs(Binds) do config.Binds[tName] = key.Name end
    pcall(function() writefile(CONFIG_FILE, HttpService:JSONEncode(config)) end)
end

local function LoadConfig()
    if not (isfile and readfile) then return end
    pcall(function()
        if isfile(CONFIG_FILE) then
            local data = HttpService:JSONDecode(readfile(CONFIG_FILE))
            if type(data) ~= "table" then return end
            if data.Binds then
                for tName, kName in pairs(data.Binds) do pcall(function() Binds[tName] = Enum.KeyCode[kName] end) end
            end
            if data.FlySpeed then FLY_SPEED = tonumber(data.FlySpeed) or FLY_SPEED end
            if data.TPWalkSpeed then TPWALK_SPEED = tonumber(data.TPWalkSpeed) or TPWALK_SPEED end
            if data.FOVSize then Settings.FOV = tonumber(data.FOVSize) or Settings.FOV end
            if data.TrailTime then TrailTime = tonumber(data.TrailTime) or TrailTime end
            if data.BulletTransparency then BulletTransparency = tonumber(data.BulletTransparency) or BulletTransparency end
            if data.BulletR and data.BulletG and data.BulletB then
                BulletColour = ColorSequence.new(Color3.new(data.BulletR, data.BulletG, data.BulletB))
            end
        end
    end)
end
LoadConfig()

-- // SILENT AIM & AIMLOCK SETTINGS
local NAME_AIMLOCK_TARGET = nil
local NAME_AIMLOCK_ENABLED = false
local CAMLOCK_TARGET = nil
local CAMLOCK_ENABLED = false
local LASTPOS_ENABLED = false
local LASTPOS_VALUE = nil
local NOSLOW_ENABLED = false
local NOSLOW_CONNECTION = nil
local AUTO_RESET_ENABLED = false
local FLY_ENABLED = false
local NOCLIP_ENABLED = false
local INFSTAM_ENABLED = false
local TPWALK_ENABLED = false

local Circle = Drawing.new("Circle")
Circle.Color = Settings.FOVColor
Circle.Thickness = Settings.FOVThickness
Circle.NumSides = 100
Circle.Radius = Settings.FOV
Circle.Filled = Settings.FOVFilled
Circle.Visible = Settings.ShowFOV

RunService.Heartbeat:Connect(function()
    Circle.Radius = Settings.FOV
    Circle.Visible = Settings.ShowFOV
    Circle.Position = UserInputService:GetMouseLocation()
end)

local function IsVisible(targetPart, character)
    if not Settings.WallCheck then return true end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {LocalPlayer.Character, character}
    params.IgnoreWater = true
    local startPos = Camera.CFrame.Position
    local result = workspace:Raycast(startPos, targetPart.Position - startPos, params)
    return result == nil
end

local function GetClosestPlayerToCursor()
    local closest, shortest = nil, Settings.FOV
    if NAME_AIMLOCK_ENABLED and NAME_AIMLOCK_TARGET then
        local t = NAME_AIMLOCK_TARGET
        if t and t.Character and t.Character:FindFirstChild(Settings.Hitpart) then
            local hum = t.Character:FindFirstChildOfClass("Humanoid")
            if hum and hum.Health > 0 then return t end
        end
    end
    for _, player in pairs(Players:GetPlayers()) do
        if player ~= LocalPlayer and player.Character then
            local hitp = player.Character:FindFirstChild(Settings.Hitpart)
            local hum = player.Character:FindFirstChildOfClass("Humanoid")
            if hitp and hum and hum.Health > 0 and not (Settings.TeamCheck and player.TeamColor == LocalPlayer.TeamColor) then
                local screenPos, onScreen = Camera:WorldToViewportPoint(hitp.Position)
                if onScreen then
                    local dist = (Vector2.new(screenPos.X, screenPos.Y) - UserInputService:GetMouseLocation()).Magnitude
                    if dist < shortest and IsVisible(hitp, player.Character) then
                        shortest = dist; closest = player
                    end
                end
            end
        end
    end
    return closest
end

-- // HOOKS
local OldIndex, OldNewIndex, OldNamecall
OldIndex = hookmetamethod(game, "__index", newcclosure(function(self, index)
    if self == Mouse and tostring(index) == "Hit" and Settings.Enabled then
        local t = GetClosestPlayerToCursor()
        if t and t.Character and t.Character:FindFirstChild(Settings.Hitpart) then
            local hit = t.Character[Settings.Hitpart]
            return hit.CFrame + (hit.Velocity * 0.125)
        end
    end
    return OldIndex(self, index)
end))
OldNewIndex = hookmetamethod(game, "__newindex", newcclosure(function(self, index, val)
    if not checkcaller() then
        local name = tostring(self)
        if (name == "HumanoidRootPart" or name == "Torso") and (index == "CFrame" or index == "Velocity" or index == "AssemblyLinearVelocity") then
            return
        end
    end
    return OldNewIndex(self, index, val)
end))
OldNamecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    if not checkcaller() then
        local mName = tostring(method)
        if mName == "FireServer" then
            local rName = tostring(self)
            if rName == "Input" and (args[1] == "bv" or args[1] == "hb" or args[1] == "ws") then return coroutine.yield()
            elseif rName == "WalkSpeed" or rName == "JumpPower" or rName == "HipHeight" then return nil end
        elseif mName == "PivotTo" or mName == "MoveTo" or mName == "SetPrimaryPartCFrame" then
            local name = tostring(self)
            if name == "HumanoidRootPart" or name == "Torso" or (self:IsA("Model") and self.Name == LocalPlayer.Name) then return nil end
        end
    end
    if tostring(method) == "FindPartOnRayWithIgnoreList" and Settings.Enabled then
        local t = GetClosestPlayerToCursor()
        if t and t.Character and t.Character:FindFirstChild(Settings.Hitpart) then
            local hit = t.Character[Settings.Hitpart]
            local pred = hit.CFrame + (hit.Velocity * 0.125)
            args[1] = Ray.new(Camera.CFrame.Position, (pred.Position - Camera.CFrame.Position).Unit * 1000)
        end
    end
    return OldNamecall(self, unpack(args))
end))

-- // BULLETS ENGINE
local OwnTrails = setmetatable({}, {__mode = "k"})
local function IsOwnBullet(trail)
    if OwnTrails[trail] ~= nil then return OwnTrails[trail] end
    local isOwn = false
    if LocalPlayer.Character then
        local hrp = LocalPlayer.Character:FindFirstChild("HumanoidRootPart") or LocalPlayer.Character:FindFirstChild("Torso")
        local part = trail.Parent
        if trail:IsDescendantOf(LocalPlayer.Character) then isOwn = true
        elseif hrp and part and part:IsA("BasePart") and (part.Position - hrp.Position).Magnitude <= 15 then isOwn = true end
    end
    OwnTrails[trail] = isOwn; return isOwn
end

local function ApplyChanges(T)
    if not BULLET_TRAILS_ENABLED or not T or not T:IsA("Trail") then return end
    if not APPLY_TO_EVERYONE and not IsOwnBullet(T) then return end
    T.Color = BulletColour; T.Lifetime = TrailTime; T.Transparency = NumberSequence.new(BulletTransparency)
end

local function UpdateActiveBullets()
    for _, v in pairs(workspace:GetDescendants()) do
        if v:IsA("Trail") and v.Parent and v.Parent.Name:lower():find("bullet") then ApplyChanges(v) end
    end
    if LocalPlayer.Character then
        for _, v in pairs(LocalPlayer.Character:GetDescendants()) do if v:IsA("Trail") then ApplyChanges(v) end end
    end
end

workspace.DescendantAdded:Connect(function(desc) if desc:IsA("Trail") then ApplyChanges(desc) end end)
if LocalPlayer.Character then LocalPlayer.Character.DescendantAdded:Connect(function(desc) if desc:IsA("Trail") then ApplyChanges(desc) end end) end
LocalPlayer.CharacterAdded:Connect(function(char) char.DescendantAdded:Connect(function(desc) if desc:IsA("Trail") then ApplyChanges(desc) end end) end)

local BulletColourTable = {
    ["Black"]  = ColorSequence.new(Color3.fromRGB(0,0,0)), ["White"]  = ColorSequence.new(Color3.fromRGB(255,255,255)),
    ["Red"]    = ColorSequence.new(Color3.fromRGB(255,0,0)), ["Green"]  = ColorSequence.new(Color3.fromRGB(0,255,0)),
    ["Blue"]   = ColorSequence.new(Color3.fromRGB(0,0,255)), ["Yellow"] = ColorSequence.new(Color3.fromRGB(255,255,0)),
    ["Pink"]   = ColorSequence.new(Color3.fromRGB(255,20,147)), ["Purple"] = ColorSequence.new(Color3.fromRGB(128,0,128))
}

-- -----------------------------------------------------
-- // GLOBAL UI COMPONENT REGISTRY & UTILS
-- -----------------------------------------------------
local UI = {}
local Utils = {}

function Utils.Corner(p, r) local c=Instance.new("UICorner",p); c.CornerRadius=UDim.new(0,r or 6) end
function Utils.Stroke(p, c, t) local s=Instance.new("UIStroke",p); s.Color=c or Color3.fromRGB(45,45,45); s.Thickness=t or 1; s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border end
function Utils.Pad(p, t, b, l, r) local pd=Instance.new("UIPadding",p); if t then pd.PaddingTop=UDim.new(0,t) end; if b then pd.PaddingBottom=UDim.new(0,b) end; if l then pd.PaddingLeft=UDim.new(0,l) end; if r then pd.PaddingRight=UDim.new(0,r) end end

function Utils.SetBtnState(btn, state, onText, offText)
    if state then
        btn.BackgroundColor3 = Color3.fromRGB(0,120,60)
        local s = btn:FindFirstChildOfClass("UIStroke"); if s then s.Color=Color3.fromRGB(0,180,90) end
        if onText then btn.Text = onText end
    else
        btn.BackgroundColor3 = Color3.fromRGB(35,35,35)
        local s = btn:FindFirstChildOfClass("UIStroke"); if s then s.Color=Color3.fromRGB(60,60,60) end
        if offText then btn.Text = offText end
    end
end

function Utils.CreateButton(parent, layoutOrder, text)
    local btn = Instance.new("TextButton", parent)
    btn.Size = UDim2.new(1, -20, 0, 28); btn.LayoutOrder = layoutOrder
    btn.BackgroundColor3 = Color3.fromRGB(35,35,35); btn.BorderSizePixel = 0
    btn.Text = text; btn.TextColor3 = Color3.fromRGB(220,220,220); btn.TextSize = 12; btn.Font = Enum.Font.GothamSemibold
    Utils.Corner(btn, 4); Utils.Stroke(btn, Color3.fromRGB(60,60,60))
    return btn
end

function Utils.CreateTextBox(parent, layoutOrder, text, placeholder)
    local box = Instance.new("TextBox", parent)
    box.Size = UDim2.new(1,-20,0,28); box.LayoutOrder = layoutOrder
    box.BackgroundColor3 = Color3.fromRGB(30,30,30); box.BorderSizePixel = 0
    box.Text = text; box.TextColor3 = Color3.fromRGB(220,220,220)
    box.PlaceholderText = placeholder; box.PlaceholderColor3 = Color3.fromRGB(100,100,100)
    box.TextSize = 12; box.Font = Enum.Font.Gotham; box.ClearTextOnFocus = true
    box.TextTruncate = Enum.TextTruncate.AtEnd; box.TextXAlignment = Enum.TextXAlignment.Left
    Utils.Corner(box, 4); Utils.Stroke(box, Color3.fromRGB(60,60,60)); Utils.Pad(box, 0,0,8,0)
    return box
end

function Utils.CreateDropFrame(parent, layoutOrder)
    local drop = Instance.new("ScrollingFrame", parent)
    drop.Size = UDim2.new(1,-20,0,0); drop.LayoutOrder = layoutOrder
    drop.BackgroundColor3 = Color3.fromRGB(30,30,30); drop.BorderSizePixel = 0
    drop.ClipsDescendants = true; drop.ScrollBarThickness = 4
    drop.CanvasSize = UDim2.new(0,0,0,0); drop.ZIndex = 10; drop.Visible = false
    Utils.Stroke(drop, Color3.fromRGB(60,60,60)); Utils.Corner(drop, 4)
    local layout = Instance.new("UIListLayout", drop); layout.SortOrder = Enum.SortOrder.LayoutOrder
    return drop
end

function Utils.CreateSlider(parent, layoutOrder, labelText, minVal, maxVal, currentVal, decimals, callback)
    local container = Instance.new("Frame", parent)
    container.Size = UDim2.new(1,-20,0,32); container.BackgroundTransparency = 1; container.LayoutOrder = layoutOrder
    local label = Instance.new("TextLabel", container)
    label.Size = UDim2.new(1,0,0,14); label.BackgroundTransparency = 1
    local function getTxt(v) if decimals > 0 then return string.format("%s: %."..decimals.."f", labelText, v) else return labelText..": "..math.floor(v) end end
    label.Text = getTxt(currentVal); label.TextColor3 = Color3.fromRGB(180,180,180); label.TextSize = 11; label.Font = Enum.Font.Gotham; label.TextXAlignment = Enum.TextXAlignment.Left
    local bar = Instance.new("Frame", container)
    bar.Size = UDim2.new(1,0,0,4); bar.Position = UDim2.new(0,0,0,20); bar.BackgroundColor3 = Color3.fromRGB(50,50,50); bar.BorderSizePixel = 0
    Utils.Corner(bar, 2)
    local knob = Instance.new("Frame", bar)
    knob.Size = UDim2.new(0,12,0,12)
    local pct = (currentVal - minVal) / (maxVal - minVal)
    knob.Position = UDim2.new(pct, -6, 0.5, -6); knob.BackgroundColor3 = Color3.fromRGB(0,180,255); knob.BorderSizePixel = 0
    Utils.Corner(knob, 6)
    
    local active = false
    bar.InputBegan:Connect(function(input) if input.UserInputType.Name:find("MouseButton1") or input.UserInputType.Name:find("Touch") then active = true end end)
    UserInputService.InputEnded:Connect(function(input) if input.UserInputType.Name:find("MouseButton1") or input.UserInputType.Name:find("Touch") then active = false end end)
    UserInputService.InputChanged:Connect(function(input)
        if active and (input.UserInputType.Name:find("MouseMovement") or input.UserInputType.Name:find("Touch")) then
            local r = math.clamp((UserInputService:GetMouseLocation().X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
            knob.Position = UDim2.new(r, -6, 0.5, -6)
            local val = minVal + (r * (maxVal - minVal)); if decimals == 0 then val = math.floor(val) end
            label.Text = getTxt(val); callback(val)
        end
    end)
    return function(newVal)
        label.Text = getTxt(newVal); local r = (newVal - minVal) / (maxVal - minVal)
        knob.Position = UDim2.new(r, -6, 0.5, -6)
    end
end

-- -----------------------------------------------------
-- // MAIN UI ASSEMBLY
-- -----------------------------------------------------
UI.ScreenGui = Instance.new("ScreenGui")
UI.ScreenGui.Name = "SlaxwareGUI"; UI.ScreenGui.ResetOnSpawn = false
UI.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; UI.ScreenGui.Parent = game:GetService("CoreGui")

UI.Container = Instance.new("Frame", UI.ScreenGui)
UI.Container.Size = UDim2.new(0, 240, 0, 440); UI.Container.Position = UDim2.new(0.5, -120, 0.5, -220)
UI.Container.BackgroundTransparency = 1; UI.Container.Active = true

-- Slaxware Frame
do
    local Frame = Instance.new("Frame", UI.Container)
    Frame.Size = UDim2.new(1,0,1,0); Frame.BackgroundColor3 = Color3.fromRGB(22,22,22); Frame.BorderSizePixel = 0; Frame.ZIndex = 10; Frame.ClipsDescendants = true
    Utils.Corner(Frame); Utils.Stroke(Frame)
    
    local Title = Instance.new("TextLabel", Frame)
    Title.Size = UDim2.new(1,0,0,30); Title.BackgroundColor3 = Color3.fromRGB(15,15,15); Title.Text = "  SLAXWARE 🐈"; Title.TextXAlignment = Enum.TextXAlignment.Left; Title.TextColor3 = Color3.fromRGB(0,180,255); Title.TextSize = 13; Title.Font = Enum.Font.GothamBold
    local TLine = Instance.new("Frame", Title); TLine.Size = UDim2.new(1,0,0,1); TLine.Position = UDim2.new(0,0,1,0); TLine.BackgroundColor3 = Color3.fromRGB(45,45,45); TLine.BorderSizePixel = 0
    
    local MinBtn = Instance.new("TextButton", Title)
    MinBtn.Size = UDim2.new(0,30,0,30); MinBtn.Position = UDim2.new(1,-30,0,0); MinBtn.BackgroundTransparency = 1; MinBtn.Text = "—"; MinBtn.TextColor3 = Color3.fromRGB(0,180,255); MinBtn.TextSize = 14; MinBtn.Font = Enum.Font.GothamBold
    local isMin = false
    MinBtn.MouseButton1Click:Connect(function()
        isMin = not isMin
        TweenService:Create(UI.Container, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Size = UDim2.new(0, 240, 0, isMin and 30 or 440)}):Play()
        MinBtn.Text = isMin and "+" or "—"
    end)
    
    local dragging, dragInput, dragStart, startPos
    Title.InputBegan:Connect(function(input) if input.UserInputType.Name:find("MouseButton1") or input.UserInputType.Name:find("Touch") then dragging = true; dragStart = input.Position; startPos = UI.Container.Position; input.Changed:Connect(function() if input.UserInputState.Name == "End" then dragging = false end end) end end)
    Title.InputChanged:Connect(function(input) if input.UserInputType.Name:find("MouseMovement") or input.UserInputType.Name:find("Touch") then dragInput = input end end)
    UserInputService.InputChanged:Connect(function(input) if input == dragInput and dragging then local delta = input.Position - dragStart; UI.Container.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
    
    task.spawn(function() while true do Title.TextColor3 = Color3.fromHSV((tick()%5)/5,1,1); task.wait() end end)
    
    UI.Content = Instance.new("ScrollingFrame", Frame)
    UI.Content.Size = UDim2.new(1,0,1,-30); UI.Content.Position = UDim2.new(0,0,0,30); UI.Content.BackgroundTransparency = 1; UI.Content.BorderSizePixel = 0; UI.Content.ScrollBarThickness = 4
    Utils.Pad(UI.Content, 8,8,0,0)
    local layout = Instance.new("UIListLayout", UI.Content); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0,6); layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() UI.Content.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 16) end)
end

-- Binds Slide-Out
UI.BindsFrame = Instance.new("Frame", UI.Container)
UI.BindsFrame.Size = UDim2.new(1,0,1,0); UI.BindsFrame.BackgroundColor3 = Color3.fromRGB(22,22,22); UI.BindsFrame.BorderSizePixel = 0; UI.BindsFrame.ZIndex = 4; UI.BindsFrame.ClipsDescendants = true
do
    Utils.Corner(UI.BindsFrame); Utils.Stroke(UI.BindsFrame)
    local Title = Instance.new("TextLabel", UI.BindsFrame)
    Title.Size = UDim2.new(1,0,0,30); Title.BackgroundColor3 = Color3.fromRGB(15,15,15); Title.Text = "  ⌨️ ACTIVE BINDS"; Title.TextColor3 = Color3.fromRGB(0,180,255); Title.TextXAlignment = Enum.TextXAlignment.Left; Title.TextSize = 13; Title.Font = Enum.Font.GothamBold
    local line = Instance.new("Frame", Title); line.Size = UDim2.new(1,0,0,1); line.Position = UDim2.new(0,0,1,0); line.BackgroundColor3 = Color3.fromRGB(45,45,45); line.BorderSizePixel = 0
    local CBtn = Instance.new("TextButton", Title); CBtn.Size = UDim2.new(0,30,0,30); CBtn.Position = UDim2.new(1,-30,0,0); CBtn.BackgroundTransparency = 1; CBtn.Text = "X"; CBtn.TextColor3 = Color3.fromRGB(180,50,50); CBtn.Font = Enum.Font.GothamBold; CBtn.TextSize = 14
    CBtn.MouseButton1Click:Connect(function() TweenService:Create(UI.BindsFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0,0,0,0)}):Play() end)
    task.spawn(function() while true do Title.TextColor3 = Color3.fromHSV((tick()%5)/5,1,1); task.wait() end end)
    
    UI.BindsScroll = Instance.new("ScrollingFrame", UI.BindsFrame)
    UI.BindsScroll.Size = UDim2.new(1,0,1,-30); UI.BindsScroll.Position = UDim2.new(0,0,0,30); UI.BindsScroll.BackgroundTransparency = 1; UI.BindsScroll.BorderSizePixel = 0; UI.BindsScroll.ScrollBarThickness = 4
    Utils.Pad(UI.BindsScroll, 8,8,10,10)
    local layout = Instance.new("UIListLayout", UI.BindsScroll); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0,6)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() UI.BindsScroll.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 16) end)
end

function Utils.RefreshBindsList()
    for _, child in pairs(UI.BindsScroll:GetChildren()) do if child:IsA("Frame") then child:Destroy() end end
    local count = 0
    for name, key in pairs(Binds) do
        count = count + 1
        local row = Instance.new("Frame", UI.BindsScroll); row.Size = UDim2.new(1,0,0,28); row.BackgroundColor3 = Color3.fromRGB(30,30,30); row.BorderSizePixel = 0; row.LayoutOrder = count
        Utils.Corner(row, 4); Utils.Stroke(row, Color3.fromRGB(50,50,50))
        local lbl = Instance.new("TextLabel", row); lbl.Size = UDim2.new(1,-12,1,0); lbl.Position = UDim2.new(0,6,0,0); lbl.BackgroundTransparency = 1; lbl.Text = name:upper() .. "  →  " .. key.Name:upper(); lbl.TextColor3 = Color3.fromRGB(220,220,220); lbl.TextSize = 11; lbl.Font = Enum.Font.GothamSemibold; lbl.TextXAlignment = Enum.TextXAlignment.Left
    end
    if count == 0 then
        local row = Instance.new("Frame", UI.BindsScroll); row.Size = UDim2.new(1,0,0,28); row.BackgroundTransparency = 1
        local lbl = Instance.new("TextLabel", row); lbl.Size = UDim2.new(1,0,1,0); lbl.BackgroundTransparency = 1; lbl.Text = "No active binds"; lbl.TextColor3 = Color3.fromRGB(120,120,120); lbl.TextSize = 11; lbl.Font = Enum.Font.Gotham
    end
end

-- Bullet Slide-Out
UI.BulletFrame = Instance.new("Frame", UI.Container)
UI.BulletFrame.Size = UDim2.new(1,0,1,0); UI.BulletFrame.BackgroundColor3 = Color3.fromRGB(22,22,22); UI.BulletFrame.BorderSizePixel = 0; UI.BulletFrame.ZIndex = 5; UI.BulletFrame.ClipsDescendants = true
do
    Utils.Corner(UI.BulletFrame); Utils.Stroke(UI.BulletFrame)
    local Title = Instance.new("TextLabel", UI.BulletFrame)
    Title.Size = UDim2.new(1,0,0,30); Title.BackgroundColor3 = Color3.fromRGB(15,15,15); Title.Text = "  🔫 BULLET TRAILS"; Title.TextColor3 = Color3.fromRGB(0,180,255); Title.TextXAlignment = Enum.TextXAlignment.Left; Title.TextSize = 13; Title.Font = Enum.Font.GothamBold
    local line = Instance.new("Frame", Title); line.Size = UDim2.new(1,0,0,1); line.Position = UDim2.new(0,0,1,0); line.BackgroundColor3 = Color3.fromRGB(45,45,45); line.BorderSizePixel = 0
    local CBtn = Instance.new("TextButton", Title); CBtn.Size = UDim2.new(0,30,0,30); CBtn.Position = UDim2.new(1,-30,0,0); CBtn.BackgroundTransparency = 1; CBtn.Text = "X"; CBtn.TextColor3 = Color3.fromRGB(180,50,50); CBtn.Font = Enum.Font.GothamBold; CBtn.TextSize = 14
    CBtn.MouseButton1Click:Connect(function() TweenService:Create(UI.BulletFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0,0,0,0)}):Play() end)
    task.spawn(function() while true do Title.TextColor3 = Color3.fromHSV((tick()%5)/5,1,1); task.wait() end end)
    
    local BContent = Instance.new("ScrollingFrame", UI.BulletFrame)
    BContent.Size = UDim2.new(1,0,1,-30); BContent.Position = UDim2.new(0,0,0,30); BContent.BackgroundTransparency = 1; BContent.BorderSizePixel = 0; BContent.ScrollBarThickness = 4
    Utils.Pad(BContent, 8,8,10,0)
    local layout = Instance.new("UIListLayout", BContent); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0,6)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() BContent.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 16) end)
    
    local blO = 0; local function bn() blO = blO + 1 return blO end
    local BTog = Utils.CreateButton(BContent, bn(), "Bullet Trails: OFF")
    BTog.MouseButton1Click:Connect(function() BULLET_TRAILS_ENABLED = not BULLET_TRAILS_ENABLED; Utils.SetBtnState(BTog, BULLET_TRAILS_ENABLED, "Bullet Trails: ON", "Bullet Trails: OFF"); if BULLET_TRAILS_ENABLED then UpdateActiveBullets() end end)
    
    local TgtTog = Utils.CreateButton(BContent, bn(), "Target: ME ONLY")
    TgtTog.MouseButton1Click:Connect(function() APPLY_TO_EVERYONE = not APPLY_TO_EVERYONE; TgtTog.BackgroundColor3 = APPLY_TO_EVERYONE and Color3.fromRGB(0,100,160) or Color3.fromRGB(35,35,35); TgtTog.Text = APPLY_TO_EVERYONE and "Target: EVERYONE" or "Target: ME ONLY"; if BULLET_TRAILS_ENABLED then UpdateActiveBullets() end end)
    
    local lbl = Instance.new("TextLabel", BContent); lbl.Size = UDim2.new(1,-20,0,16); lbl.BackgroundTransparency = 1; lbl.Text = "Color Presets"; lbl.TextColor3 = Color3.fromRGB(200,200,200); lbl.Font = Enum.Font.GothamBold; lbl.TextSize = 11; lbl.TextXAlignment = Enum.TextXAlignment.Left; lbl.LayoutOrder = bn()
    local gridF = Instance.new("Frame", BContent); gridF.Size = UDim2.new(1,-20,0,86); gridF.BackgroundTransparency = 1; gridF.LayoutOrder = bn()
    local grid = Instance.new("UIGridLayout", gridF); grid.CellSize = UDim2.new(0,64,0,24); grid.CellPadding = UDim2.new(0,6,0,6); grid.SortOrder = Enum.SortOrder.Name
    
    local prev = Instance.new("Frame", BContent); prev.Size = UDim2.new(1,-20,0,16); prev.BackgroundColor3 = BulletColour.Keypoints[1].Value; prev.LayoutOrder = bn(); Utils.Corner(prev,4); Utils.Stroke(prev, Color3.fromRGB(60,60,60))
    for name, cSeq in pairs(BulletColourTable) do
        local btn = Instance.new("TextButton", gridF); btn.Name = name; btn.Text = name; btn.BackgroundColor3 = Color3.fromRGB(35,35,35); btn.TextColor3 = Color3.fromRGB(220,220,220); btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 10; Utils.Corner(btn,4); Utils.Stroke(btn, Color3.fromRGB(60,60,60))
        btn.MouseButton1Click:Connect(function() BulletColour = cSeq; prev.BackgroundColor3 = cSeq.Keypoints[1].Value; if BULLET_TRAILS_ENABLED then UpdateActiveBullets() end; SaveConfig() end)
    end
    
    local rF = Instance.new("Frame", BContent); rF.Size = UDim2.new(1,-20,0,28); rF.BackgroundTransparency = 1; rF.LayoutOrder = bn()
    local function M(p,c,x) local bx=Instance.new("TextBox",rF); bx.Size=UDim2.new(0.31,0,1,0); bx.Position=UDim2.new(x,0,0,0); bx.BackgroundColor3=Color3.fromRGB(30,30,30); bx.PlaceholderText=p; bx.TextColor3=c; bx.Font=Enum.Font.Gotham; bx.TextSize=11; Utils.Corner(bx,4); Utils.Stroke(bx,Color3.fromRGB(60,60,60)); return bx end
    local rB, gB, bB = M("R", Color3.fromRGB(255,100,100), 0), M("G", Color3.fromRGB(100,255,100), 0.345), M("B", Color3.fromRGB(100,100,255), 0.69)
    local aBtn = Utils.CreateButton(BContent, bn(), "Apply Custom RGB")
    aBtn.MouseButton1Click:Connect(function()
        local r,g,b = tonumber(rB.Text), tonumber(gB.Text), tonumber(bB.Text)
        if not r and not g and not b then return end
        local nc = Color3.fromRGB(math.clamp(r or 255,0,255), math.clamp(g or 255,0,255), math.clamp(b or 255,0,255))
        BulletColour = ColorSequence.new(nc); prev.BackgroundColor3 = nc; if BULLET_TRAILS_ENABLED then UpdateActiveBullets() end; SaveConfig()
    end)
    Utils.CreateSlider(BContent, bn(), "Lifetime (s)", 0.05, 3.0, TrailTime, 2, function(v) TrailTime = v; if BULLET_TRAILS_ENABLED then UpdateActiveBullets() end; SaveConfig() end)
    Utils.CreateSlider(BContent, bn(), "Opacity", 0.0, 1.0, BulletTransparency, 2, function(v) BulletTransparency = v; if BULLET_TRAILS_ENABLED then UpdateActiveBullets() end; SaveConfig() end)
end

-- Toggles Assembly
do
    local cO = 0; local function co() cO = cO + 1 return cO end
    UI.ToggleBtn = Utils.CreateButton(UI.Content, co(), "CursorLock: OFF")
    UI.ToggleBtn.MouseButton1Click:Connect(function() Settings.Enabled = not Settings.Enabled; Utils.SetBtnState(UI.ToggleBtn, Settings.Enabled, "CursorLock: ON", "CursorLock: OFF") end)
    
    UI.FOVCircleToggle = Utils.CreateButton(UI.Content, co(), "FOV: Hidden")
    UI.FOVCircleToggle.MouseButton1Click:Connect(function() Settings.ShowFOV = not Settings.ShowFOV; Aiming.ShowFOV = Settings.ShowFOV; Utils.SetBtnState(UI.FOVCircleToggle, Settings.ShowFOV, "FOV: Visible", "FOV: Hidden") end)
    Utils.CreateSlider(UI.Content, co(), "FOV Size", 10, 800, Settings.FOV, 0, function(v) Settings.FOV = v; SaveConfig() end)

    UI.AimlockDropBtn = Utils.CreateTextBox(UI.Content, co(), "▼ Aimlock Target", "🔍 Search aimlock...")
    UI.NameAimlockStatus = Instance.new("TextLabel", UI.Content); UI.NameAimlockStatus.Size = UDim2.new(1,-24,0,16); UI.NameAimlockStatus.LayoutOrder = co(); UI.NameAimlockStatus.BackgroundTransparency = 1; UI.NameAimlockStatus.Text = "Status: inactive"; UI.NameAimlockStatus.TextColor3 = Color3.fromRGB(150,150,150); UI.NameAimlockStatus.TextSize = 11; UI.NameAimlockStatus.Font = Enum.Font.Gotham; UI.NameAimlockStatus.TextXAlignment = Enum.TextXAlignment.Left
    UI.AimlockDropFrame = Utils.CreateDropFrame(UI.Content, co())

    UI.CamlockToggle = Utils.CreateButton(UI.Content, co(), "Camlock: OFF")
    UI.CamlockToggle.MouseButton1Click:Connect(function() CAMLOCK_ENABLED = not CAMLOCK_ENABLED; Utils.SetBtnState(UI.CamlockToggle, CAMLOCK_ENABLED, "Camlock: ON", "Camlock: OFF") end)
    UI.CamlockDropBtn = Utils.CreateTextBox(UI.Content, co(), "▼ Camlock Target", "🔍 Search camlock...")
    UI.CamlockDropFrame = Utils.CreateDropFrame(UI.Content, co())

    UI.ESPDropBtn = Utils.CreateTextBox(UI.Content, co(), "ESP: None ▼", "🔍 Search players...")
    UI.ESPDropFrame = Utils.CreateDropFrame(UI.Content, co())

    UI.FlyToggle = Utils.CreateButton(UI.Content, co(), "Fly: OFF")
    local updateFlySpeed = Utils.CreateSlider(UI.Content, co(), "Fly Speed", 10, 300, FLY_SPEED, 0, function(v) FLY_SPEED = v; SaveConfig() end)
    UI.NoclipToggle = Utils.CreateButton(UI.Content, co(), "Noclip: OFF")
    UI.NoclipToggle.MouseButton1Click:Connect(function() NOCLIP_ENABLED = not NOCLIP_ENABLED; Utils.SetBtnState(UI.NoclipToggle, NOCLIP_ENABLED, "Noclip: ON", "Noclip: OFF") end)
    
    UI.TPWalkToggle = Utils.CreateButton(UI.Content, co(), "TPWalk: OFF")
    UI.TPWalkToggle.MouseButton1Click:Connect(function() TPWALK_ENABLED = not TPWALK_ENABLED; Utils.SetBtnState(UI.TPWalkToggle, TPWALK_ENABLED, "TPWalk: ON", "TPWalk: OFF") end)
    local updateTPWalkSpeed = Utils.CreateSlider(UI.Content, co(), "Walk Speed", 5, 150, TPWALK_SPEED, 0, function(v) TPWALK_SPEED = v; SaveConfig() end)

    UI.AutoResetToggle = Utils.CreateButton(UI.Content, co(), "AutoReset (10HP): OFF")
    UI.AutoResetToggle.MouseButton1Click:Connect(function() AUTO_RESET_ENABLED = not AUTO_RESET_ENABLED; Utils.SetBtnState(UI.AutoResetToggle, AUTO_RESET_ENABLED, "AutoReset: ON", "AutoReset (10HP): OFF") end)

    UI.InfStamToggle = Utils.CreateButton(UI.Content, co(), "InfStamina: OFF")
    
    local initialKeylockText = Binds["keylock"] and ("Keylock Bind: " .. Binds["keylock"].Name) or "Keylock Bind: None"
    UI.KeylockBtn = Utils.CreateButton(UI.Content, co(), initialKeylockText)
    UI.isBindingKeylock = false
    UI.KeylockBtn.MouseButton1Click:Connect(function() UI.isBindingKeylock = true; UI.KeylockBtn.Text = "Keylock Bind: [ Press Any Key ]" end)

    local CustomTrailsBtn = Utils.CreateButton(UI.Content, co(), "Custom Bullet Trails")
    CustomTrailsBtn.MouseButton1Click:Connect(function() TweenService:Create(UI.BulletFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, -250, 0, 0)}):Play() end)
end

-- // COMMAND POPUP
local CMD_LIST = {
    { cmd = "bind {key} {cmd}", desc = "Bind command to key" }, { cmd = "unbind {key} {cmd}", desc = "Unbind command from key" },
    { cmd = "unbind all", desc = "Remove all keybinds" }, { cmd = "bindlist", desc = "View active binds gui" },
    { cmd = "get {item}", desc = "Teleport to item (uzi, money, ar15...)" }, { cmd = "cmd", desc = "Open command list" },
    { cmd = "chatenable", desc = "Enable chatspy/chat" }, { cmd = "aimlock {player}", desc = "Aimlocks chosen player" },
    { cmd = "unaimlock", desc = "Turn off aimlock" }, { cmd = "camlock {player}", desc = "Camera locks onto player" },
    { cmd = "autoreset", desc = "Auto reset at 10HP" }, { cmd = "fly / unfly", desc = "Toggle fly mode" },
    { cmd = "noclip / clip", desc = "Toggle noclip" }, { cmd = "infstam / uninfstam", desc = "Toggle infinite stamina" },
    { cmd = "rejoin", desc = "Rejoin server" }, { cmd = "tpwalk {1-150}", desc = "Enable tpwalk at speed" },
    { cmd = "fov on / fov off", desc = "Toggle FOV visibility" }, { cmd = "esp {player} / all / off", desc = "ESP controls" },
    { cmd = "lastpos / unlastpos", desc = "Toggle respawn teleport" }, { cmd = "noslow / unnoslow", desc = "Remove slow tags" },
    { cmd = "keylock", desc = "Lock target on hover w/ key" }, { cmd = "reset", desc = "Reset character instantly" },
}
UI.CmdPopup = Instance.new("Frame", UI.ScreenGui)
UI.CmdPopup.Size = UDim2.new(0, 240, 0, 440); UI.CmdPopup.Position = UDim2.new(0.5, 140, 0.5, -220); UI.CmdPopup.BackgroundColor3 = Color3.fromRGB(22, 22, 22); UI.CmdPopup.BorderSizePixel = 0; UI.CmdPopup.Active = true; UI.CmdPopup.Visible = false; UI.CmdPopup.ClipsDescendants = true
do
    Utils.Corner(UI.CmdPopup); Utils.Stroke(UI.CmdPopup)
    local Title = Instance.new("TextLabel", UI.CmdPopup)
    Title.Size = UDim2.new(1,0,0,30); Title.BackgroundColor3 = Color3.fromRGB(15,15,15); Title.Text = "  ⌨️ COMMAND LIST"; Title.TextColor3 = Color3.fromRGB(0,180,255); Title.TextXAlignment = Enum.TextXAlignment.Left; Title.TextSize = 13; Title.Font = Enum.Font.GothamBold
    local line = Instance.new("Frame", Title); line.Size = UDim2.new(1,0,0,1); line.Position = UDim2.new(0,0,1,0); line.BackgroundColor3 = Color3.fromRGB(45,45,45); line.BorderSizePixel = 0
    local CBtn = Instance.new("TextButton", Title); CBtn.Size = UDim2.new(0,30,0,30); CBtn.Position = UDim2.new(1,-30,0,0); CBtn.BackgroundTransparency = 1; CBtn.Text = "X"; CBtn.TextColor3 = Color3.fromRGB(0,180,255); CBtn.Font = Enum.Font.GothamBold; CBtn.TextSize = 14; CBtn.ZIndex = 2
    CBtn.MouseButton1Click:Connect(function() UI.CmdPopup.Visible = false end)
    local d, di, ds, sp
    Title.InputBegan:Connect(function(i) if i.UserInputType.Name:find("MouseButton1") or i.UserInputType.Name:find("Touch") then d = true; ds = i.Position; sp = UI.CmdPopup.Position; i.Changed:Connect(function() if i.UserInputState.Name == "End" then d = false end end) end end)
    Title.InputChanged:Connect(function(i) if i.UserInputType.Name:find("MouseMovement") or i.UserInputType.Name:find("Touch") then di = i end end)
    UserInputService.InputChanged:Connect(function(i) if i == di and d then local del = i.Position - ds; UI.CmdPopup.Position = UDim2.new(sp.X.Scale, sp.X.Offset + del.X, sp.Y.Scale, sp.Y.Offset + del.Y) end end)
    task.spawn(function() while true do Title.TextColor3 = Color3.fromHSV((tick()%5)/5,1,1); task.wait() end end)
    
    local Scr = Instance.new("ScrollingFrame", UI.CmdPopup)
    Scr.Size = UDim2.new(1,0,1,-30); Scr.Position = UDim2.new(0,0,0,30); Scr.BackgroundTransparency = 1; Scr.BorderSizePixel = 0; Scr.ScrollBarThickness = 4
    Utils.Pad(Scr, 8,8,8,8)
    local layout = Instance.new("UIListLayout", Scr); layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0,6)
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() Scr.CanvasSize = UDim2.new(0,0,0,layout.AbsoluteContentSize.Y + 16) end)
    
    for i, inf in ipairs(CMD_LIST) do
        local r = Instance.new("Frame", Scr); r.Size = UDim2.new(1,0,0,38); r.BackgroundColor3 = Color3.fromRGB(30,30,30); r.BorderSizePixel = 0; r.LayoutOrder = i
        Utils.Corner(r, 4); Utils.Stroke(r, Color3.fromRGB(50,50,50))
        local cLbl = Instance.new("TextLabel", r); cLbl.Size = UDim2.new(1,-12,0,16); cLbl.Position = UDim2.new(0,6,0,2); cLbl.BackgroundTransparency = 1; cLbl.Text = inf.cmd; cLbl.TextColor3 = Color3.fromRGB(220,220,220); cLbl.TextSize = 12; cLbl.Font = Enum.Font.GothamBold; cLbl.TextXAlignment = Enum.TextXAlignment.Left
        local dLbl = Instance.new("TextLabel", r); dLbl.Size = UDim2.new(1,-12,0,14); dLbl.Position = UDim2.new(0,6,0,20); dLbl.BackgroundTransparency = 1; dLbl.Text = inf.desc; dLbl.TextColor3 = Color3.fromRGB(150,150,150); dLbl.TextSize = 10; dLbl.Font = Enum.Font.Gotham; dLbl.TextXAlignment = Enum.TextXAlignment.Left
    end
end

-- // COMMAND BARS
local CmdBarTweenInfo = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
local CMD_BAR_OPEN_POS   = UDim2.new(0, 20, 0.5, -24)
local CMD_BAR_CLOSED_POS = UDim2.new(0, -400, 0.5, -24)

UI.CmdBarFrame = Instance.new("Frame", UI.ScreenGui)
UI.CmdBarFrame.Size = UDim2.new(0, 380, 0, 48); UI.CmdBarFrame.Position = CMD_BAR_CLOSED_POS; UI.CmdBarFrame.BackgroundColor3 = Color3.fromRGB(30,30,30); UI.CmdBarFrame.BorderSizePixel = 0; UI.CmdBarFrame.ZIndex = 20; UI.CmdBarFrame.ClipsDescendants = true
do
    Utils.Corner(UI.CmdBarFrame, 6); Utils.Stroke(UI.CmdBarFrame, Color3.fromRGB(60,60,60))
    local Prm = Instance.new("TextLabel", UI.CmdBarFrame); Prm.Size = UDim2.new(0,28,1,0); Prm.BackgroundTransparency = 1; Prm.Text = ":"; Prm.TextColor3 = Color3.fromRGB(0,180,255); Prm.TextSize = 16; Prm.Font = Enum.Font.GothamBold; Prm.ZIndex = 21
    UI.CmdBarShadow = Instance.new("TextLabel", UI.CmdBarFrame); UI.CmdBarShadow.Size = UDim2.new(1,-36,0,34); UI.CmdBarShadow.Position = UDim2.new(0,28,0.5,-17); UI.CmdBarShadow.BackgroundTransparency = 1; UI.CmdBarShadow.Text = ""; UI.CmdBarShadow.TextColor3 = Color3.fromRGB(120,120,120); UI.CmdBarShadow.TextSize = 13; UI.CmdBarShadow.Font = Enum.Font.Gotham; UI.CmdBarShadow.TextXAlignment = Enum.TextXAlignment.Left; UI.CmdBarShadow.ZIndex = 21; Utils.Pad(UI.CmdBarShadow, 0,0,0,8)
    UI.CmdBarBox = Instance.new("TextBox", UI.CmdBarFrame); UI.CmdBarBox.Size = UDim2.new(1,-36,0,34); UI.CmdBarBox.Position = UDim2.new(0,28,0.5,-17); UI.CmdBarBox.BackgroundTransparency = 1; UI.CmdBarBox.PlaceholderText = "camlock / aimlock / esp {player}  | bind f aimlock"; UI.CmdBarBox.PlaceholderColor3 = Color3.fromRGB(100,100,100); UI.CmdBarBox.Text = ""; UI.CmdBarBox.TextColor3 = Color3.new(1,1,1); UI.CmdBarBox.TextSize = 13; UI.CmdBarBox.Font = Enum.Font.Gotham; UI.CmdBarBox.ClearTextOnFocus = false; UI.CmdBarBox.TextXAlignment = Enum.TextXAlignment.Left; UI.CmdBarBox.ZIndex = 22; Utils.Pad(UI.CmdBarBox, 0,0,0,8)
    UI.MainCmdFeedback = Instance.new("TextLabel", UI.CmdBarFrame); UI.MainCmdFeedback.Size = UDim2.new(1,-16,0,18); UI.MainCmdFeedback.Position = UDim2.new(0,8,0,-20); UI.MainCmdFeedback.BackgroundTransparency = 1; UI.MainCmdFeedback.Text = ""; UI.MainCmdFeedback.TextColor3 = Color3.fromRGB(0,200,80); UI.MainCmdFeedback.TextSize = 11; UI.MainCmdFeedback.Font = Enum.Font.Gotham; UI.MainCmdFeedback.ZIndex = 21
end

local sideClosedPos = UDim2.new(0, -310, 0.5, -35)
local sideOpenPos = UDim2.new(0, 10, 0.5, -35)
UI.SideFrame = Instance.new("Frame", UI.ScreenGui)
UI.SideFrame.Size = UDim2.new(0, 300, 0, 70); UI.SideFrame.Position = sideClosedPos; UI.SideFrame.BackgroundColor3 = Color3.fromRGB(22,22,22); UI.SideFrame.BorderSizePixel = 0; UI.SideFrame.ZIndex = 10; UI.SideFrame.Visible = false
do
    Utils.Corner(UI.SideFrame, 6); Utils.Stroke(UI.SideFrame, Color3.fromRGB(45,45,45))
    local SideTitle = Instance.new("TextLabel", UI.SideFrame); SideTitle.Size = UDim2.new(1,0,0,20); SideTitle.Position = UDim2.new(0,0,0,4); SideTitle.BackgroundTransparency = 1; SideTitle.Text = "⚡ SLAXWARE QUICK COMMAND"; SideTitle.TextColor3 = Color3.fromRGB(0,180,255); SideTitle.TextSize = 10; SideTitle.Font = Enum.Font.GothamBold; SideTitle.ZIndex = 11
    local Container = Instance.new("Frame", UI.SideFrame); Container.Size = UDim2.new(0.9,0,0,30); Container.Position = UDim2.new(0.05,0,0,24); Container.BackgroundColor3 = Color3.fromRGB(30,30,30); Container.BorderSizePixel = 0; Container.ZIndex = 11
    Utils.Corner(Container, 4); Utils.Stroke(Container, Color3.fromRGB(60,60,60))
    UI.SideCmdShadow = Instance.new("TextLabel", Container); UI.SideCmdShadow.Size = UDim2.new(1,0,1,0); UI.SideCmdShadow.BackgroundTransparency = 1; UI.SideCmdShadow.Text = ""; UI.SideCmdShadow.TextColor3 = Color3.fromRGB(120,120,120); UI.SideCmdShadow.TextSize = 12; UI.SideCmdShadow.Font = Enum.Font.Gotham; UI.SideCmdShadow.TextXAlignment = Enum.TextXAlignment.Left; UI.SideCmdShadow.ZIndex = 11; Utils.Pad(UI.SideCmdShadow, 0,0,8,8)
    UI.SideCmdBox = Instance.new("TextBox", Container); UI.SideCmdBox.Size = UDim2.new(1,0,1,0); UI.SideCmdBox.BackgroundTransparency = 1; UI.SideCmdBox.PlaceholderText = "camlock / aimlock {player}..."; UI.SideCmdBox.PlaceholderColor3 = Color3.fromRGB(100,100,100); UI.SideCmdBox.Text = ""; UI.SideCmdBox.TextColor3 = Color3.new(1,1,1); UI.SideCmdBox.TextSize = 12; UI.SideCmdBox.Font = Enum.Font.Gotham; UI.SideCmdBox.ClearTextOnFocus = false; UI.SideCmdBox.TextXAlignment = Enum.TextXAlignment.Left; UI.SideCmdBox.ZIndex = 12; Utils.Pad(UI.SideCmdBox, 0,0,8,8)
    UI.SideCmdFeedback = Instance.new("TextLabel", UI.SideFrame); UI.SideCmdFeedback.Size = UDim2.new(0.9,0,0,12); UI.SideCmdFeedback.Position = UDim2.new(0.05,0,0,55); UI.SideCmdFeedback.BackgroundTransparency = 1; UI.SideCmdFeedback.Text = ""; UI.SideCmdFeedback.TextColor3 = Color3.fromRGB(0,200,80); UI.SideCmdFeedback.TextSize = 9; UI.SideCmdFeedback.Font = Enum.Font.Gotham; UI.SideCmdFeedback.ZIndex = 11
    task.spawn(function() while true do SideTitle.TextColor3 = Color3.fromHSV((tick()%5)/5,1,1); task.wait() end end)
end

-- // DROPDOWN & NOTIFY LOGIC
getgenv().ESP_All = false
getgenv().ESP_Players = {}

function Utils.UpdateESPBtnLabel()
    if ESP_All then UI.ESPDropBtn.Text = "ESP: All ▼"; UI.ESPDropBtn.BackgroundColor3 = Color3.fromRGB(0, 100, 50)
    else
        local c = 0; for _ in pairs(ESP_Players) do c = c + 1 end
        if c == 0 then UI.ESPDropBtn.Text = "ESP: None ▼"; UI.ESPDropBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        elseif c == 1 then for p in pairs(ESP_Players) do UI.ESPDropBtn.Text = "ESP: "..p.Name.." ▼" end; UI.ESPDropBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 40)
        else UI.ESPDropBtn.Text = "ESP: "..c.." players ▼"; UI.ESPDropBtn.BackgroundColor3 = Color3.fromRGB(0, 80, 40) end
    end
end

function Utils.SetAimlockTarget(plr)
    NAME_AIMLOCK_TARGET = plr
    NAME_AIMLOCK_ENABLED = (plr ~= nil)
    if plr then
        UI.AimlockDropBtn.Text = "▼ " .. plr.Name; UI.NameAimlockStatus.Text = "Status: " .. plr.Name; UI.NameAimlockStatus.TextColor3 = Color3.fromRGB(0, 200, 80)
        Aiming.ShowFOV, Aiming.FOV, Settings.ShowFOV, Settings.FOV = false, 9999, false, 9999
        Utils.SetBtnState(UI.FOVCircleToggle, false, "FOV: Visible", "FOV: Hidden")
    else
        UI.AimlockDropBtn.Text = "▼ Aimlock Target"; UI.NameAimlockStatus.Text = "Status: inactive"; UI.NameAimlockStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
    end
end

function Utils.SetCamlockTarget(plr)
    CAMLOCK_TARGET = plr
    UI.CamlockDropBtn.Text = plr and ("▼ " .. plr.Name) or "▼ Camlock Target"
end

local function Notify(title, text)
    pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", { Title = title, Text = text, Duration = 3 }) end)
end

do
    local function populateDrop(frame, btn, filterTxt, getEntries, clickCallback)
        for _, c in pairs(frame:GetChildren()) do if c:IsA("TextButton") then c:Destroy() end end
        local f = filterTxt:lower(); if f:sub(1,2)=="▼ " or f:sub(1,2)=="🔍 " then f=f:sub(3) end; if f:sub(1,4)=="esp:" then f=f:sub(5) end
        f = f:match("^%s*(.-)%s*$") or ""
        local entries = getEntries(f)
        frame.Size = UDim2.new(1, -20, 0, math.min(#entries * 24, 5 * 24)); frame.CanvasSize = UDim2.new(0,0,0, #entries * 24)
        for i, ent in ipairs(entries) do
            local b = Instance.new("TextButton", frame); b.Size = UDim2.new(1,0,0,24); b.BackgroundColor3 = ent.sel and Color3.fromRGB(0,100,0) or Color3.fromRGB(40,40,40); b.BorderSizePixel = 0; b.Text = (ent.check and (ent.sel and "☑ " or "☐ ") or "") .. ent.label; b.TextColor3 = Color3.new(1,1,1); b.TextSize = 11; b.Font = Enum.Font.Gotham; b.TextXAlignment = Enum.TextXAlignment.Left; b.LayoutOrder = i; b.ZIndex = 11; b.TextTruncate = Enum.TextTruncate.AtEnd; Utils.Pad(b,0,0,8,0)
            b.MouseEnter:Connect(function() if not ent.sel then b.BackgroundColor3 = Color3.fromRGB(60,60,60) end end)
            b.MouseLeave:Connect(function() b.BackgroundColor3 = ent.sel and Color3.fromRGB(0,100,0) or Color3.fromRGB(40,40,40) end)
            b.MouseButton1Click:Connect(function() clickCallback(ent) end)
        end
    end
    
    local eO, eF = false, false
    UI.ESPDropBtn.Focused:Connect(function() eO=true; populateDrop(UI.ESPDropFrame, UI.ESPDropBtn, "", function(f) local res={{label="All Players", isAll=true, check=true, sel=ESP_All}}; for _, p in pairs(Players:GetPlayers()) do if p~=LocalPlayer and (f=="" or p.Name:lower():find(f,1,true) or p.DisplayName:lower():find(f,1,true)) then table.insert(res, {label=p.Name.." ("..p.DisplayName..")", player=p, check=true, sel=not ESP_All and ESP_Players[p]}) end end return res end, function(ent) if ent.isAll then ESP_All = not ESP_All; if ESP_All then ESP_Players = {} end else if ESP_All then ESP_All = false; ESP_Players = {} end; ESP_Players[ent.player] = not ESP_Players[ent.player] end; Utils.UpdateESPBtnLabel(); populateDrop(UI.ESPDropFrame, UI.ESPDropBtn, UI.ESPDropBtn:IsFocused() and UI.ESPDropBtn.Text or "", function() return {} end, function()end) end); UI.ESPDropFrame.Visible=true end)
    UI.ESPDropBtn:GetPropertyChangedSignal("Text"):Connect(function() if eF or not UI.ESPDropBtn:IsFocused() then return end; eF=true; UI.ESPDropBtn:ReleaseFocus(); UI.ESPDropBtn:CaptureFocus(); eF=false end)
    UI.ESPDropBtn.FocusLost:Connect(function() task.delay(0.15, function() if eO and not UI.ESPDropBtn:IsFocused() then eO=false; UI.ESPDropFrame.Visible=false; Utils.UpdateESPBtnLabel() end end) end)

    local aO, aF = false, false
    UI.AimlockDropBtn.Focused:Connect(function() aO=true; populateDrop(UI.AimlockDropFrame, UI.AimlockDropBtn, "", function(f) local res={{label="None"}}; for _, p in pairs(Players:GetPlayers()) do if p~=LocalPlayer and (f=="" or p.Name:lower():find(f,1,true) or p.DisplayName:lower():find(f,1,true)) then table.insert(res, {label=p.Name.." ("..p.DisplayName..")", player=p}) end end return res end, function(ent) Utils.SetAimlockTarget(ent.player); UI.AimlockDropFrame.Visible=false; aO=false; UI.AimlockDropBtn:ReleaseFocus() end); UI.AimlockDropFrame.Visible=true end)
    UI.AimlockDropBtn.FocusLost:Connect(function() task.delay(0.15, function() if aO and not UI.AimlockDropBtn:IsFocused() then aO=false; UI.AimlockDropFrame.Visible=false; UI.AimlockDropBtn.Text = NAME_AIMLOCK_TARGET and ("▼ " .. NAME_AIMLOCK_TARGET.Name) or "▼ Aimlock Target" end end) end)

    local cO, cF = false, false
    UI.CamlockDropBtn.Focused:Connect(function() cO=true; populateDrop(UI.CamlockDropFrame, UI.CamlockDropBtn, "", function(f) local res={{label="None"}}; for _, p in pairs(Players:GetPlayers()) do if p~=LocalPlayer and (f=="" or p.Name:lower():find(f,1,true) or p.DisplayName:lower():find(f,1,true)) then table.insert(res, {label=p.Name.." ("..p.DisplayName..")", player=p}) end end return res end, function(ent) Utils.SetCamlockTarget(ent.player); UI.CamlockDropFrame.Visible=false; cO=false; UI.CamlockDropBtn:ReleaseFocus() end); UI.CamlockDropFrame.Visible=true end)
    UI.CamlockDropBtn.FocusLost:Connect(function() task.delay(0.15, function() if cO and not UI.CamlockDropBtn:IsFocused() then cO=false; UI.CamlockDropFrame.Visible=false; UI.CamlockDropBtn.Text = CAMLOCK_TARGET and ("▼ " .. CAMLOCK_TARGET.Name) or "▼ Camlock Target" end end) end)
end

-- // MODS & LOGIC
RunService.Heartbeat:Connect(function()
    if TPWALK_ENABLED and LocalPlayer.Character then
        local hrp, hum = LocalPlayer.Character:FindFirstChild("HumanoidRootPart"), LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum and hrp and hum.MoveDirection.Magnitude > 0 then hrp.CFrame = hrp.CFrame + hum.MoveDirection * (TPWALK_SPEED * 0.016) end
    end
end)

RunService.RenderStepped:Connect(function()
    if CAMLOCK_ENABLED and CAMLOCK_TARGET and CAMLOCK_TARGET.Character then
        local p = CAMLOCK_TARGET.Character:FindFirstChild(Settings.Hitpart)
        if p then Camera.CFrame = CFrame.new(Camera.CFrame.Position, p.Position) end
    end
end)

local flyConnection = nil
local savedWalkSpeed, savedJumpPower = 16, 50
local function StopFly()
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end
    local c = LocalPlayer.Character
    if c then
        local hrp = c:FindFirstChild("HumanoidRootPart")
        if hrp then local bv, bg = hrp:FindFirstChild("SlaxFlyBV"), hrp:FindFirstChild("SlaxFlyBG"); if bv then bv:Destroy() end; if bg then bg:Destroy() end end
        local hum = c:FindFirstChildOfClass("Humanoid"); if hum then hum.PlatformStand = false; hum.WalkSpeed = savedWalkSpeed; hum.JumpPower = savedJumpPower; hum:ChangeState(Enum.HumanoidStateType.Running) end
    end
end

local function StartFly()
    StopFly()
    local c = LocalPlayer.Character; if not c then return end
    local hrp, hum = c:FindFirstChild("HumanoidRootPart"), c:FindFirstChildOfClass("Humanoid")
    if not hrp then return end
    if hum then savedWalkSpeed = hum.WalkSpeed; savedJumpPower = hum.JumpPower; hum.PlatformStand = true end
    local bv, bg = Instance.new("BodyVelocity", hrp), Instance.new("BodyGyro", hrp)
    bv.Name = "SlaxFlyBV"; bv.MaxForce = Vector3.new(9e9, 9e9, 9e9); bv.Velocity = Vector3.new(0,0,0)
    bg.Name = "SlaxFlyBG"; bg.MaxTorque = Vector3.new(9e9, 9e9, 9e9); bg.CFrame = Camera.CFrame
    flyConnection = RunService.RenderStepped:Connect(function()
        if not LocalPlayer.Character then return end
        local r = LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if not r or not r:FindFirstChild("SlaxFlyBG") then return end
        r.SlaxFlyBG.CFrame = Camera.CFrame
        local dir = Vector3.new(0,0,0)
        if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then dir = dir - Vector3.new(0,1,0) end
        r.SlaxFlyBV.Velocity = dir.Magnitude > 0 and (dir.Unit * math.min(FLY_SPEED, 150)) or Vector3.new(0,0,0)
    end)
end
UI.FlyToggle.MouseButton1Click:Connect(function() FLY_ENABLED = not FLY_ENABLED; Utils.SetBtnState(UI.FlyToggle, FLY_ENABLED, "Fly: ON", "Fly: OFF"); if FLY_ENABLED then StartFly() else StopFly() end end)

RunService.Stepped:Connect(function()
    if NOCLIP_ENABLED and LocalPlayer.Character then for _, p in pairs(LocalPlayer.Character:GetDescendants()) do if p:IsA("BasePart") then p.CanCollide = false end end end
end)

local function ApplyInfStam(char)
    if not char then return end
    local stam, mstam = char:WaitForChild("Stamina", 5), char:WaitForChild("MaxStamina", 5)
    if stam and mstam then
        if infStamConnection then infStamConnection:Disconnect() end
        infStamConnection = stam:GetPropertyChangedSignal("Value"):Connect(function() if INFSTAM_ENABLED and stam.Value < mstam.Value then stam.Value = mstam.Value end end)
        if INFSTAM_ENABLED then stam.Value = mstam.Value end
    end
end
UI.InfStamToggle.MouseButton1Click:Connect(function() INFSTAM_ENABLED = not INFSTAM_ENABLED; Utils.SetBtnState(UI.InfStamToggle, INFSTAM_ENABLED, "InfStamina: ON", "InfStamina: OFF"); if INFSTAM_ENABLED then ApplyInfStam(LocalPlayer.Character) elseif infStamConnection then infStamConnection:Disconnect(); infStamConnection = nil end end)

local NOSLOW_TAGS = { ["reloading"]=true, ["ko"]=true, ["action"]=true, ["creatorslow"]=true, ["gunslow"]=true }
local tagHooked, oldTagHas = false, nil
local function HookTagSystem()
    if tagHooked then return end
    pcall(function()
        local TS = require(game:GetService("ReplicatedStorage"):FindFirstChild("TagSystem"))
        if TS and TS.has then
            oldTagHas = TS.has
            TS.has = function(obj, tag)
                if NOSLOW_ENABLED and obj == LocalPlayer.Character and tag and NOSLOW_TAGS[tag:lower()] then return nil end
                return oldTagHas(obj, tag)
            end
            tagHooked = true
        end
    end)
end
RunService.Heartbeat:Connect(function() if NOSLOW_ENABLED and LocalPlayer.Character then for _, c in ipairs(LocalPlayer.Character:GetChildren()) do if NOSLOW_TAGS[c.Name:lower()] then pcall(function() c:Destroy() end) end end end end)
task.spawn(HookTagSystem)

local function SlaxHookCharacter(char)
    local hum, hrp = char:WaitForChild("Humanoid", 10), char:WaitForChild("HumanoidRootPart", 10)
    if LASTPOS_ENABLED and LASTPOS_VALUE then task.delay(0.25, function() pcall(function() local fH = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart"); if fH then fH.CFrame = LASTPOS_VALUE end end) end) end
    if not hum then return end
    if INFSTAM_ENABLED then task.spawn(ApplyInfStam, char) end
    hum.Died:Connect(function() if FLY_ENABLED then StopFly() end; if hrp and hrp.Parent then LASTPOS_VALUE = hrp.CFrame end end)
    if NOSLOW_ENABLED then for _, c in pairs(char:GetChildren()) do if NOSLOW_TAGS[c.Name:lower()] then pcall(function() c:Destroy() end) end end end
end

LocalPlayer.CharacterAdded:Connect(function(char)
    if NOCLIP_ENABLED then NOCLIP_ENABLED = false; Utils.SetBtnState(UI.NoclipToggle, false, "Noclip: ON", "Noclip: OFF") end
    if FLY_ENABLED then task.wait(0.5) StartFly() end
    task.wait(1) HookTagSystem()
    SlaxHookCharacter(char)
end)
if LocalPlayer.Character then task.spawn(SlaxHookCharacter, LocalPlayer.Character) end

local lastResetTime = 0
RunService.Heartbeat:Connect(function()
    if not AUTO_RESET_ENABLED or (tick() - lastResetTime < 2) then return end
    local c = LocalPlayer.Character; if not c then return end
    local h = c:FindFirstChildOfClass("Humanoid")
    if h and h.Health <= 10 and h.Health > 0 then
        lastResetTime = tick(); pcall(function() LocalPlayer:LoadCharacter() end)
        task.delay(0.5, function() pcall(function() LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health = 0 end) end)
    end
end)

-- // COMMAND ENGINE
local AUTOCOMPLETE_COMMANDS = { "bind ", "unbind ", "unbind all", "bindlist", "get ", "cmd", "chatenable", "aimlock ", "autoreset", "fly", "unfly", "unaimlock", "noclip", "clip", "infstam", "uninfstam", "rejoin", "camlock ", "tpwalk ", "fov on", "fov off", "keylock", "esp ", "lastpos", "unlastpos", "noslow", "unnoslow", "reset" }

local function GetAutocomplete(inputText)
    if not inputText or inputText == "" then return "" end
    local lowerInput = inputText:lower()
    local bestMatch = nil
    for _, cmd in ipairs(AUTOCOMPLETE_COMMANDS) do if cmd:sub(1, #lowerInput) == lowerInput then bestMatch = cmd; break end end
    local cmdWithSpace = lowerInput:match("^(%w+%s+)")
    if cmdWithSpace then
        local rem = lowerInput:sub(#cmdWithSpace + 1)
        if rem ~= "" then
            if cmdWithSpace == "aimlock " or cmdWithSpace == "camlock " or cmdWithSpace == "esp " then
                for _, p in ipairs(Players:GetPlayers()) do
                    if p ~= LocalPlayer and (p.Name:lower():sub(1,#rem)==rem or p.DisplayName:lower():sub(1,#rem)==rem) then return cmdWithSpace .. p.Name:lower() end
                end
            elseif cmdWithSpace == "get " then
                for _, i in ipairs({"money", "grenade", "flash", "golf", "ar15", "molotov", "brick", "usas", "uzi"}) do if i:sub(1,#rem)==rem then return cmdWithSpace..i end end
            end
        end
    end
    local mBind = lowerInput:match("^bind%s+(%w+)%s+(%w*)$")
    if mBind then
        local key = lowerInput:match("^bind%s+(%w+)%s+"); local r = lowerInput:match("^bind%s+%w+%s+(%w*)$")
        if r then for _, t in ipairs({"aimlock","autoreset","fly","noclip","infstam","camlock","tpwalk","fovvisible","keylock","reset"}) do if t:sub(1,#r)==r then return "bind "..key.." "..t end end end
    end
    local mUnb = lowerInput:match("^unbind%s+(%w+)%s+(%w*)$")
    if mUnb then
        local key = lowerInput:match("^unbind%s+(%w+)%s+"); local r = lowerInput:match("^unbind%s+%w+%s+(%w*)$")
        if r then for _, t in ipairs({"aimlock","autoreset","fly","noclip","infstam","camlock","tpwalk","fovvisible","keylock","reset"}) do if t:sub(1,#r)==r then return "unbind "..key.." "..t end end end
    end
    return bestMatch or ""
end

local function HandleTextBoxChange(box, shadowLabel)
    local t = box.Text; if t:find("\n") then t = t:gsub("\n",""); box.Text = t end
    local s = GetAutocomplete(t); shadowLabel.Text = (s ~= "" and t ~= "") and (t .. s:sub(#t + 1)) or ""
end

UI.CmdBarBox:GetPropertyChangedSignal("Text"):Connect(function() HandleTextBoxChange(UI.CmdBarBox, UI.CmdBarShadow) end)
UI.SideCmdBox:GetPropertyChangedSignal("Text"):Connect(function() HandleTextBoxChange(UI.SideCmdBox, UI.SideCmdShadow) end)

local ParseCommand; local UI_Feedback
local isCmdBarOpen, isSideOpen, cmdBarCloseThread, sideCloseThread = false, false, nil, nil

local function SlideCmdBarOut()
    if not isCmdBarOpen then return end; isCmdBarOpen = false; if cmdBarCloseThread then task.cancel(cmdBarCloseThread) cmdBarCloseThread=nil end
    if UI.CmdBarBox:IsFocused() then UI.CmdBarBox:ReleaseFocus() end; TweenService:Create(UI.CmdBarFrame, CmdBarTweenInfo, {Position = CMD_BAR_CLOSED_POS}):Play()
end
local function SlideCmdBarIn()
    if isCmdBarOpen then task.defer(function() UI.CmdBarBox:CaptureFocus() end) return end
    isCmdBarOpen = true; if cmdBarCloseThread then task.cancel(cmdBarCloseThread) cmdBarCloseThread=nil end
    UI.CmdBarBox.Text, UI.CmdBarShadow.Text, UI.MainCmdFeedback.Text = "", "", ""
    TweenService:Create(UI.CmdBarFrame, CmdBarTweenInfo, {Position = CMD_BAR_OPEN_POS}):Play()
    UI.CmdBarBox:CaptureFocus(); task.spawn(function() task.wait(0.05) UI.CmdBarBox.Text = "" end)
end
local function HideSideCommandBar()
    if not isSideOpen then return end; isSideOpen = false; if sideCloseThread then task.cancel(sideCloseThread) sideCloseThread=nil end
    if UI.SideCmdBox:IsFocused() then UI.SideCmdBox:ReleaseFocus() end
    local t = TweenService:Create(UI.SideFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = sideClosedPos})
    t:Play(); t.Completed:Connect(function() if not isSideOpen then UI.SideFrame.Visible = false end end)
end
local function OpenSideCommandBar()
    UI.SideCmdBox.Text, UI.SideCmdShadow.Text, UI.SideCmdFeedback.Text = "", "", ""; if isSideOpen then UI.SideCmdBox:CaptureFocus() return end
    isSideOpen = true; UI.SideFrame.Visible = true; if sideCloseThread then task.cancel(sideCloseThread) sideCloseThread=nil end
    local t = TweenService:Create(UI.SideFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = sideOpenPos})
    t:Play(); t.Completed:Connect(function() UI.SideCmdBox:CaptureFocus() end)
end

UI.CmdBarBox.FocusLost:Connect(function(e)
    if e then
        UI_Feedback = UI.MainCmdFeedback; local t = UI.CmdBarBox.Text; local s = GetAutocomplete(t); if s ~= "" and t ~= "" then t = s end
        UI.CmdBarBox.Text, UI.CmdBarShadow.Text = "", ""; SlideCmdBarOut(); task.spawn(ParseCommand, t)
    else
        cmdBarCloseThread = task.delay(0.4, function() cmdBarCloseThread=nil if not UI.CmdBarBox:IsFocused() then SlideCmdBarOut() end end)
    end
end)
UI.SideCmdBox.FocusLost:Connect(function(e)
    if e then
        UI_Feedback = UI.SideCmdFeedback; local t = UI.SideCmdBox.Text; local s = GetAutocomplete(t); if s ~= "" and t ~= "" then t = s end
        UI.SideCmdBox.Text, UI.SideCmdShadow.Text = "", ""; HideSideCommandBar(); task.spawn(ParseCommand, t)
    else
        sideCloseThread = task.delay(0.3, function() sideCloseThread=nil if not UI.SideCmdBox:IsFocused() then HideSideCommandBar() end end)
    end
end)

ContextActionService:BindAction("ColonBind", function(a,s,i)
    if s ~= Enum.UserInputState.Begin then return Enum.ContextActionResult.Pass end
    local fb = UserInputService:GetFocusedTextBox()
    if fb == UI.CmdBarBox or fb == UI.SideCmdBox then return Enum.ContextActionResult.Pass end
    if isCmdBarOpen then SlideCmdBarOut() else SlideCmdBarIn() end; return Enum.ContextActionResult.Sink
end, false, Enum.KeyCode.Semicolon)

local _lastNameAimlockTarget = nil
local GET_ITEMS={
    ["money"] ={mesh="rbxassetid://511726060",texture="rbxassetid://511726139"}, ["grenade"]={mesh="rbxassetid://436966955",texture="rbxassetid://436966973"},
    ["flash"] ={mesh="rbxassetid://454819719",texture="rbxassetid://454819722"}, ["golf"] ={mesh="rbxassetid://441573384",texture="rbxassetid://441573394"},
    ["ar15"] ={mesh="rbxassetid://137762422011047"}, ["molotov"]={mesh="rbxassetid://454823030",texture="rbxassetid://91135823000526"},
    ["brick"] ={texture="rbxassetid://8236335288"}, ["usas"] ={texture="rbxassetid://97657374427072"}, ["uzi"]={texture="rbxassetid://4529712484"}
}

local function ResolveKeyCode(k)
    if #k == 1 and k:match("^%a$") then return "KeyCode." .. k:upper() end
    if k:match("^[fF]%d%d?$") then return "KeyCode." .. k:upper() end
    local n = { ["space"]="Space", ["shift"]="LeftShift", ["ctrl"]="LeftControl", ["alt"]="LeftAlt", ["enter"]="Return", ["backspace"]="Backspace", ["num1"]="One", ["1"]="One", ["2"]="Two" }
    return n[k:lower()] and ("KeyCode."..n[k:lower()]) or nil
end

local function FireToggle(name)
    if name == "aimlock" then
        local active = Aiming.Enabled or NAME_AIMLOCK_ENABLED
        Aiming.Enabled, Settings.Enabled = not active, not active
        Utils.SetBtnState(UI.ToggleBtn, not active, "CursorLock: ON", "CursorLock: OFF")
        if active then
            if NAME_AIMLOCK_TARGET then _lastNameAimlockTarget = NAME_AIMLOCK_TARGET end; Utils.SetAimlockTarget(nil); Notify("Aimlock", "🔴 Turned OFF")
        else
            if _lastNameAimlockTarget then Utils.SetAimlockTarget(_lastNameAimlockTarget); _lastNameAimlockTarget = nil end; Notify("Aimlock", "🟢 Turned ON")
        end
    elseif name == "autoreset" then AUTO_RESET_ENABLED = not AUTO_RESET_ENABLED; Utils.SetBtnState(UI.AutoResetToggle, AUTO_RESET_ENABLED, "AutoReset: ON", "AutoReset (10HP): OFF"); Notify("Auto Reset", AUTO_RESET_ENABLED and "🟢 Turned ON" or "🔴 Turned OFF")
    elseif name == "fly" then FLY_ENABLED = not FLY_ENABLED; Utils.SetBtnState(UI.FlyToggle, FLY_ENABLED, "Fly: ON", "Fly: OFF"); if FLY_ENABLED then StartFly() else StopFly() end; Notify("Fly", FLY_ENABLED and "🟢 Turned ON" or "🔴 Turned OFF")
    elseif name == "noclip" then NOCLIP_ENABLED = not NOCLIP_ENABLED; Utils.SetBtnState(UI.NoclipToggle, NOCLIP_ENABLED, "Noclip: ON", "Noclip: OFF"); Notify("Noclip", NOCLIP_ENABLED and "🟢 Turned ON" or "🔴 Turned OFF")
    elseif name == "infstam" then INFSTAM_ENABLED = not INFSTAM_ENABLED; Utils.SetBtnState(UI.InfStamToggle, INFSTAM_ENABLED, "InfStamina: ON", "InfStamina: OFF"); if INFSTAM_ENABLED then ApplyInfStam(LocalPlayer.Character) elseif infStamConnection then infStamConnection:Disconnect() infStamConnection = nil end; Notify("Inf Stamina", INFSTAM_ENABLED and "🟢 Turned ON" or "🔴 Turned OFF")
    elseif name == "camlock" then CAMLOCK_ENABLED = not CAMLOCK_ENABLED; Utils.SetBtnState(UI.CamlockToggle, CAMLOCK_ENABLED, "Camlock: ON", "Camlock: OFF"); Notify("Camlock", CAMLOCK_ENABLED and "🟢 Turned ON" or "🔴 Turned OFF")
    elseif name == "tpwalk" then TPWALK_ENABLED = not TPWALK_ENABLED; Utils.SetBtnState(UI.TPWalkToggle, TPWALK_ENABLED, "TPWalk: ON", "TPWalk: OFF"); Notify("TP Walk", TPWALK_ENABLED and "🟢 Turned ON" or "🔴 Turned OFF")
    elseif name == "fovvisible" then Settings.ShowFOV = not Settings.ShowFOV; Aiming.ShowFOV = Settings.ShowFOV; Utils.SetBtnState(UI.FOVCircleToggle, Settings.ShowFOV, "FOV: Visible", "FOV: Hidden"); Notify("FOV Circle", Settings.ShowFOV and "🟢 Turned ON" or "🔴 Turned OFF")
    elseif name == "keylock" then
        local t, sDist, mLoc = nil, math.huge, UserInputService:GetMouseLocation()
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character and p.Character:FindFirstChild(Settings.Hitpart) and p.Character:FindFirstChildOfClass("Humanoid") and p.Character:FindFirstChildOfClass("Humanoid").Health > 0 then
                local sPos, on = Camera:WorldToViewportPoint(p.Character[Settings.Hitpart].Position)
                if on then
                    local d = (Vector2.new(sPos.X, sPos.Y) - mLoc).Magnitude
                    if d < sDist then sDist = d; t = p end
                end
            end
        end
        if t then Aiming.Enabled, Settings.Enabled = true, true; Utils.SetBtnState(UI.ToggleBtn, true, "CursorLock: ON", "CursorLock: OFF"); Utils.SetAimlockTarget(t); Notify("KeyLock", "🎯 Locked → " .. t.Name) else Aiming.Enabled, Settings.Enabled = false, false; Utils.SetBtnState(UI.ToggleBtn, false, "CursorLock: ON", "CursorLock: OFF"); Utils.SetAimlockTarget(nil); Notify("KeyLock", "🔴 No target — cleared") end
    elseif name == "reset" then pcall(function() LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health = 0 end); Notify("Reset", "💀 Character reset") end
end

ParseCommand = function(inputStr)
    local cl = inputStr:match("^%s*(.-)%s*$"); if cl == "" then return end
    local pts = {}; for w in cl:gmatch("%S+") do table.insert(pts, w) end
    if #pts == 0 then return end; local cmd = pts[1]:lower()
    local F = UI_Feedback or UI.MainCmdFeedback

    if cmd == "cmd" then UI.CmdPopup.Visible = true; F.TextColor3 = Color3.fromRGB(0, 200, 80); F.Text = "Opened command list" return end
    if cmd == "bindlist" then Utils.RefreshBindsList(); TweenService:Create(UI.BindsFrame, TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {Position = UDim2.new(0, -250, 0, 0)}):Play(); F.TextColor3 = Color3.fromRGB(0, 220, 80); F.Text = "Opened bind list" return end
    if cmd == "rejoin" then F.TextColor3 = Color3.fromRGB(255, 180, 0); F.Text = "Rejoining server..."; task.wait(0.5); pcall(function() game:GetService("TeleportService"):TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer) end) return end
    
    if cmd == "bind" then
        if #pts < 3 then F.TextColor3 = Color3.fromRGB(255,80,80); F.Text = "Usage: bind {key} {command}" return end
        local kEnum = ResolveKeyCode(pts[2]:lower())
        if not kEnum then F.TextColor3 = Color3.fromRGB(255,80,80); F.Text = "Invalid key" return end
        Binds[pts[3]:lower()] = Enum.KeyCode[kEnum:sub(9)]
        SaveConfig(); Utils.RefreshBindsList(); F.TextColor3 = Color3.fromRGB(0,200,80); F.Text = "Bound "..pts[3].." to "..pts[2]:upper(); Notify("Bind", "🔑 " .. pts[3]) return
    end
    
    F.TextColor3 = Color3.fromRGB(255, 80, 80); F.Text = "Unknown command (try: cmd)"
end

UserInputService.InputBegan:Connect(function(input, gp)
    if UI.isBindingKeylock and input.UserInputType == Enum.UserInputType.Keyboard then
        UI.isBindingKeylock = false
        if input.KeyCode.Name ~= "Unknown" and input.KeyCode.Name ~= "Escape" then
            Binds["keylock"] = input.KeyCode; SaveConfig(); Utils.RefreshBindsList()
            UI.KeylockBtn.Text = "Keylock Bind: " .. input.KeyCode.Name; Notify("Keylock", "Bound to " .. input.KeyCode.Name)
        else UI.KeylockBtn.Text = "Keylock Bind: None" end
        return
    end
    if input.KeyCode == Enum.KeyCode.Tab then
        if UI.CmdBarBox:IsFocused() and UI.CmdBarShadow.Text ~= "" then UI.CmdBarBox.Text = UI.CmdBarShadow.Text; UI.CmdBarShadow.Text = ""; UI.CmdBarBox.CursorPosition = #UI.CmdBarBox.Text+1; task.delay(0, function() UI.CmdBarBox.Text = UI.CmdBarBox.Text end) return
        elseif UI.SideCmdBox:IsFocused() and UI.SideCmdShadow.Text ~= "" then UI.SideCmdBox.Text = UI.SideCmdShadow.Text; UI.SideCmdShadow.Text = ""; UI.SideCmdBox.CursorPosition = #UI.SideCmdBox.Text+1; task.delay(0, function() UI.SideCmdBox.Text = UI.SideCmdBox.Text end) return end
    end
    if gp then return end
    for tName, bKey in pairs(Binds) do if input.KeyCode == bKey then FireToggle(tName) end end
    if input.KeyCode == Enum.KeyCode.K then UI.Container.Visible = not UI.Container.Visible; HideSideCommandBar(); SlideCmdBarOut() end
end)

local function clearFb(fb, tVar) task.spawn(function() while true do task.wait(1); if fb.Text ~= "" then tVar = tVar + 1; if tVar >= 4 then fb.Text = ""; tVar = 0 end else tVar = 0 end end end) end
clearFb(UI.MainCmdFeedback, 0); clearFb(UI.SideCmdFeedback, 0)

-- // ESP LOOP
local function ShouldESP(p) return p ~= LocalPlayer and (ESP_All or ESP_Players[p] == true) end
task.spawn(function()
    while true do
        task.wait(0.4)
        for _, p in ipairs(Players:GetPlayers()) do
            if p ~= LocalPlayer then
                if ShouldESP(p) and p.Character then
                    if not p.Character:FindFirstChild("SlaxrFullESP") then
                        local h = Instance.new("Highlight", p.Character); h.Name = "SlaxrFullESP"; h.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop; h.FillTransparency = 0.5; h.OutlineTransparency = 0; h.OutlineColor = Color3.new(1,1,1)
                        h.FillColor = p.TeamColor and p.TeamColor.Color or ((LocalPlayer.TeamColor == p.TeamColor) and Color3.fromRGB(0,0,255) or Color3.fromRGB(255,0,0))
                    end
                    if p.Character:FindFirstChild("Head") and not p.Character.Head:FindFirstChild("SlaxrNametag") then
                        local bg = Instance.new("BillboardGui", p.Character.Head); bg.Name = "SlaxrNametag"; bg.Size = UDim2.new(0,200,0,50); bg.StudsOffset = Vector3.new(0,2.5,0); bg.AlwaysOnTop = true
                        local t = Instance.new("TextLabel", bg); t.Size = UDim2.new(1,0,1,0); t.BackgroundTransparency = 1; t.Text = p.Name; t.TextColor3 = Color3.new(1,1,1); t.TextStrokeTransparency = 0.4; t.TextStrokeColor3 = Color3.new(0,0,0); t.Font = Enum.Font.SourceSansBold; t.TextSize = 16
                    end
                elseif p.Character then
                    for _, v in pairs(p.Character:GetChildren()) do if v.Name == "SlaxrFullESP" then v:Destroy() end end
                    local nt = p.Character:FindFirstChild("SlaxrNametag", true); if nt then nt:Destroy() end
                end
            end
        end
    end
end)

pcall(function() game:GetService("StarterGui"):SetCore("SendNotification", { Title = "SLAXWARE", Text = "K TO HIDE GUI / \":\" KEY FOR CMDBAR", Icon = "rbxassetid://11706449560", Duration = 8 }) end)
print("✅ SlaxWare Loaded | Press : to open command bar | K to toggle main GUI")
