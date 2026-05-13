--[[

  ____  __     __   _  _  _  _   __   ____  ____ 
/ ___)(  )   / _\ ( \/ )/ )( \ / _\ (  _ \(  __)
\___ \/ (_/\/    \ )  ( \ /\ //    \ )   / ) _) 
(____/\____/\_/\_/(_/\_)(_/\_)\_/\_/(__\_)(____)

-- made by grok ai btw lol cry idgaf
-- Features: auto-reset at 10hp, aimlock, esp, camlock
-- The Streets



]]

-- // Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- // Load Aiming Library
local Aiming = loadstring(game:HttpGet("https://raw.githubusercontent.com/Ezucii/new/main/sourceeeeeeeeeeeeee.lua"))()

Aiming.TeamCheck(false)
Aiming.ShowFOV = true
Aiming.FOV = 60

-- // Settings
local Settings = {
 Enabled = true,
 Prediction = 0.125,
 FOV = 60,
 ShowFOV = true,
}

-- // ESP Toggle
-- // ESP state: "all" mode flag + per-player set
local ESP_All = false
local ESP_Players = {} -- [Player] = true when selected individually

-- // Check function
local function CanSilentAim()
 if not (Aiming.Enabled and Aiming.Selected and Aiming.Selected ~= LocalPlayer and Aiming.SelectedPart) then
 return false
 end

 local Character = Aiming.Character(Aiming.Selected)
 if not Character then return false end

 local KOd = Character:FindFirstChild("BodyEffects") and Character.BodyEffects:FindFirstChild("K.O") and Character.BodyEffects["K.O"].Value
 local Grabbed = Character:FindFirstChild("GRABBING_CONSTRAINT") ~= nil

 return not (KOd or Grabbed)
end

-- // Name Aimlock State (declared early so __index closure can see them)
local NAME_AIMLOCK_ENABLED = false
local NAME_AIMLOCK_TARGET = nil

-- // Mouse Hook
local __index
__index = hookmetamethod(game, "__index", function(t, k)
 -- // NAME AIMLOCK: bypasses FOV, distance, and camera direction entirely
 if t:IsA("Mouse") and (k == "Hit" or k == "Target") and NAME_AIMLOCK_ENABLED and NAME_AIMLOCK_TARGET then
 local char = NAME_AIMLOCK_TARGET.Character
 if char then
 local targetPart = char:FindFirstChild("HumanoidRootPart")
 or char:FindFirstChild("Head")
 or char:FindFirstChildWhichIsA("BasePart")
 if targetPart then
 if k == "Hit" then
 -- Predict movement so bullets lead the target
 return targetPart.CFrame + (targetPart.Velocity * Settings.Prediction)
 else
 return targetPart
 end
 end
 end
 end

 -- // Standard FOV aimlock (only runs when Name Aimlock is off)
 if t:IsA("Mouse") and (k == "Hit" or k == "Target") and CanSilentAim() and Settings.Enabled then
 local TargetPart = Aiming.SelectedPart
 local Predicted = TargetPart.CFrame + (TargetPart.Velocity * Settings.Prediction)

 if k == "Hit" then
 return Predicted
 else
 return TargetPart
 end
 end
 return __index(t, k)
end)

-- // GUI
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SilentAimGUI"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local Frame = Instance.new("Frame")
Frame.Size = UDim2.new(0, 280, 0, 770)
Frame.Position = UDim2.new(0.5, -140, 0.5, -285)
Frame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Draggable = false
Frame.Visible = true
Frame.Parent = ScreenGui

local Title = Instance.new("TextLabel")
Title.Size = UDim2.new(1, 0, 0, 40)
Title.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
Title.Text = "slaxware"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 16
Title.Font = Enum.Font.GothamBold
Title.Parent = Frame

local dragging = false
local dragInput
local dragStart
local startPos

local function updateInput(input)
 local delta = input.Position - dragStart
 Frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
end

Title.InputBegan:Connect(function(input)
 if input.UserInputType == Enum.UserInputType.MouseButton1 then
 dragging = true
 dragStart = input.Position
 startPos = Frame.Position
 end
end)

Title.InputChanged:Connect(function(input)
 if input.UserInputType == Enum.UserInputType.MouseMovement then
 dragInput = input
 end
end)

UserInputService.InputChanged:Connect(function(input)
 if dragging and input == dragInput then
 updateInput(input)
 end
end)

UserInputService.InputEnded:Connect(function(input)
 if input.UserInputType == Enum.UserInputType.MouseButton1 then
 dragging = false
 end
end)

-- // AIMLOCK TOGGLE
local ToggleBtn = Instance.new("TextButton")
ToggleBtn.Size = UDim2.new(0.9, 0, 0, 40)
ToggleBtn.Position = UDim2.new(0.05, 0, 0, 50)
ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
ToggleBtn.Text = "Enabled CursorLock"
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

-- // PREDICTION SLIDER
local PredLabel = Instance.new("TextLabel")
PredLabel.Size = UDim2.new(0.9, 0, 0, 20)
PredLabel.Position = UDim2.new(0.05, 0, 0, 100)
PredLabel.BackgroundTransparency = 1
PredLabel.Text = "Prediction: " .. string.format("%.3f", Settings.Prediction)
PredLabel.TextColor3 = Color3.new(1, 1, 1)
PredLabel.TextSize = 14
PredLabel.Font = Enum.Font.Gotham
PredLabel.Parent = Frame

local PredSlider = Instance.new("Frame")
PredSlider.Size = UDim2.new(0.9, 0, 0, 8)
PredSlider.Position = UDim2.new(0.05, 0, 0, 125)
PredSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
PredSlider.BorderSizePixel = 0
PredSlider.Parent = Frame

local PredKnob = Instance.new("Frame")
PredKnob.Size = UDim2.new(0, 16, 0, 16)
PredKnob.Position = UDim2.new(0.5, -8, 0.5, -8)
PredKnob.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
PredKnob.BorderSizePixel = 0
PredKnob.Parent = PredSlider

local predDragging = false

local function updatePredSlider()
 local percent = math.clamp((Settings.Prediction - 0.05) / 0.20, 0, 1)
 PredKnob.Position = UDim2.new(percent, -8, 0.5, -8)
 PredLabel.Text = "Prediction: " .. string.format("%.3f", Settings.Prediction)
end

PredSlider.InputBegan:Connect(function(input)
 if input.UserInputType == Enum.UserInputType.MouseButton1 then
 predDragging = true
 end
end)

UserInputService.InputEnded:Connect(function(input)
 if input.UserInputType == Enum.UserInputType.MouseButton1 then
 predDragging = false
 end
end)

RunService.RenderStepped:Connect(function()
 if predDragging then
 local mouseX = UserInputService:GetMouseLocation().X
 local sliderX = PredSlider.AbsolutePosition.X
 local sliderWidth = PredSlider.AbsoluteSize.X
 local percent = math.clamp((mouseX - sliderX) / sliderWidth, 0, 1)
 Settings.Prediction = 0.05 + (percent * 0.20)
 updatePredSlider()
 end
end)

updatePredSlider()

-- // FOV SLIDER
local FOVLabel = Instance.new("TextLabel")
FOVLabel.Size = UDim2.new(0.9, 0, 0, 20)
FOVLabel.Position = UDim2.new(0.05, 0, 0, 150)
FOVLabel.BackgroundTransparency = 1
FOVLabel.Text = "FOV: " .. math.floor(Settings.FOV)
FOVLabel.TextColor3 = Color3.new(1, 1, 1)
FOVLabel.TextSize = 14
FOVLabel.Font = Enum.Font.Gotham
FOVLabel.Parent = Frame

local FOVSlider = Instance.new("Frame")
FOVSlider.Size = UDim2.new(0.9, 0, 0, 8)
FOVSlider.Position = UDim2.new(0.05, 0, 0, 175)
FOVSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
FOVSlider.BorderSizePixel = 0
FOVSlider.Parent = Frame

local FOVKnob = Instance.new("Frame")
FOVKnob.Size = UDim2.new(0, 16, 0, 16)
FOVKnob.Position = UDim2.new(0.5, -8, 0.5, -8)
FOVKnob.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
FOVKnob.BorderSizePixel = 0
FOVKnob.Parent = FOVSlider

local fovDragging = false

local function updateFOVSlider()
 local percent = math.clamp((Settings.FOV - 10) / 290, 0, 1)
 FOVKnob.Position = UDim2.new(percent, -8, 0.5, -8)
 FOVLabel.Text = "FOV: " .. math.floor(Settings.FOV)
 Aiming.FOV = Settings.FOV
end

FOVSlider.InputBegan:Connect(function(input)
 if input.UserInputType == Enum.UserInputType.MouseButton1 then
 fovDragging = true
 end
end)

UserInputService.InputEnded:Connect(function(input)
 if input.UserInputType == Enum.UserInputType.MouseButton1 then
 fovDragging = false
 end
end)

RunService.RenderStepped:Connect(function()
 if fovDragging then
 local mouseX = UserInputService:GetMouseLocation().X
 local sliderX = FOVSlider.AbsolutePosition.X
 local sliderWidth = FOVSlider.AbsoluteSize.X
 local percent = math.clamp((mouseX - sliderX) / sliderWidth, 0, 1)
 Settings.FOV = 10 + (percent * 290)
 updateFOVSlider()
 end
end)

updateFOVSlider()

-- // CursorLock TOGGLE
local FOVCircleToggle = Instance.new("TextButton")
FOVCircleToggle.Size = UDim2.new(0.9, 0, 0, 40)
FOVCircleToggle.Position = UDim2.new(0.05, 0, 0, 195)
FOVCircleToggle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
FOVCircleToggle.Text = "CursorLock Circle: Visible"
FOVCircleToggle.TextColor3 = Color3.new(1, 1, 1)
FOVCircleToggle.TextSize = 14
FOVCircleToggle.Font = Enum.Font.GothamSemibold
FOVCircleToggle.Parent = Frame

FOVCircleToggle.MouseButton1Click:Connect(function()
 Settings.ShowFOV = not Settings.ShowFOV
 Aiming.ShowFOV = Settings.ShowFOV
 if Settings.ShowFOV then
 FOVCircleToggle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
 FOVCircleToggle.Text = "CursorLock Circle: Visible"
 else
 FOVCircleToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
 FOVCircleToggle.Text = "CursorLock Circle: Hidden"
 end
end)

-- // ESP DROPDOWN (multi-select)
local ESPDropBtn = Instance.new("TextButton")
ESPDropBtn.Size = UDim2.new(0.9, 0, 0, 40)
ESPDropBtn.Position = UDim2.new(0.05, 0, 0, 245)
ESPDropBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
ESPDropBtn.Text = "ESP: None ▼"
ESPDropBtn.TextColor3 = Color3.new(1, 1, 1)
ESPDropBtn.TextSize = 14
ESPDropBtn.Font = Enum.Font.GothamSemibold
ESPDropBtn.TextTruncate = Enum.TextTruncate.AtEnd
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

-- Helper: should this player have ESP?
local function ShouldESP(player)
 if player == LocalPlayer then return false end
 return ESP_All or ESP_Players[player] == true
end

local function RefreshESPDropdown()
 for _, child in pairs(ESPDropFrame:GetChildren()) do
  if child:IsA("TextButton") then child:Destroy() end
 end

 local entries = {}
 table.insert(entries, {label = "All Players", isAll = true})
 for _, plr in pairs(Players:GetPlayers()) do
  if plr ~= LocalPlayer then
   table.insert(entries, {label = plr.Name .. " (" .. plr.DisplayName .. ")", player = plr, isAll = false})
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
   RefreshESPDropdown()
  end)
 end
end

ESPDropBtn.MouseButton1Click:Connect(function()
 espDropOpen = not espDropOpen
 if espDropOpen then
  RefreshESPDropdown()
  ESPDropFrame.Visible = true
 else
  ESPDropFrame.Visible = false
 end
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

-- // TP WALK TOGGLE
local TPWALK_ENABLED = false
local TPWALK_SPEED = 50

local TPWalkToggle = Instance.new("TextButton")
TPWalkToggle.Size = UDim2.new(0.9, 0, 0, 40)
TPWalkToggle.Position = UDim2.new(0.05, 0, 0, 295)
TPWalkToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
TPWalkToggle.Text = "TP Walk: Disabled"
TPWalkToggle.TextColor3 = Color3.new(1, 1, 1)
TPWalkToggle.TextSize = 14
TPWalkToggle.Font = Enum.Font.GothamSemibold
TPWalkToggle.Parent = Frame

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

-- // TP WALK SPEED SLIDER
local TPWalkSpeedLabel = Instance.new("TextLabel")
TPWalkSpeedLabel.Size = UDim2.new(0.9, 0, 0, 20)
TPWalkSpeedLabel.Position = UDim2.new(0.05, 0, 0, 345)
TPWalkSpeedLabel.BackgroundTransparency = 1
TPWalkSpeedLabel.Text = "TP Walk Speed: " .. TPWALK_SPEED
TPWalkSpeedLabel.TextColor3 = Color3.new(1, 1, 1)
TPWalkSpeedLabel.TextSize = 14
TPWalkSpeedLabel.Font = Enum.Font.Gotham
TPWalkSpeedLabel.Parent = Frame

local TPWalkSlider = Instance.new("Frame")
TPWalkSlider.Size = UDim2.new(0.9, 0, 0, 8)
TPWalkSlider.Position = UDim2.new(0.05, 0, 0, 370)
TPWalkSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
TPWalkSlider.BorderSizePixel = 0
TPWalkSlider.Parent = Frame

local TPWalkKnob = Instance.new("Frame")
TPWalkKnob.Size = UDim2.new(0, 16, 0, 16)
TPWalkKnob.Position = UDim2.new(0.5, -8, 0.5, -8)
TPWalkKnob.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
TPWalkKnob.BorderSizePixel = 0
TPWalkKnob.Parent = TPWalkSlider

local tpwalkDragging = false

local function updateTPWalkSlider()
 local percent = math.clamp((TPWALK_SPEED - 10) / 190, 0, 1)
 TPWalkKnob.Position = UDim2.new(percent, -8, 0.5, -8)
 TPWalkSpeedLabel.Text = "TP Walk Speed: " .. math.floor(TPWALK_SPEED)
end

TPWalkSlider.InputBegan:Connect(function(input)
 if input.UserInputType == Enum.UserInputType.MouseButton1 then
 tpwalkDragging = true
 end
end)

UserInputService.InputEnded:Connect(function(input)
 if input.UserInputType == Enum.UserInputType.MouseButton1 then
 tpwalkDragging = false
 end
end)

RunService.RenderStepped:Connect(function()
 if tpwalkDragging then
 local mouseX = UserInputService:GetMouseLocation().X
 local sliderX = TPWalkSlider.AbsolutePosition.X
 local sliderWidth = TPWalkSlider.AbsoluteSize.X
 local percent = math.clamp((mouseX - sliderX) / sliderWidth, 0, 1)
 TPWALK_SPEED = 10 + (percent * 190)
 updateTPWalkSlider()
 end
end)

updateTPWalkSlider()

-- TP Walk logic
RunService.Heartbeat:Connect(function()
 if not TPWALK_ENABLED then return end
 local character = LocalPlayer.Character
 if not character then return end
 local hrp = character:FindFirstChild("HumanoidRootPart")
 local humanoid = character:FindFirstChildOfClass("Humanoid")
 if not hrp or not humanoid then return end
 if humanoid.MoveDirection.Magnitude > 0 then
 hrp.CFrame = hrp.CFrame + humanoid.MoveDirection * (TPWALK_SPEED * 0.016)
 end
end)

-- // CAMLOCK TOGGLE
local CAMLOCK_ENABLED = false
local CAMLOCK_TARGET = nil

local CamlockToggle = Instance.new("TextButton")
CamlockToggle.Size = UDim2.new(0.9, 0, 0, 40)
CamlockToggle.Position = UDim2.new(0.05, 0, 0, 390)
CamlockToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
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
TargetLabel.TextColor3 = Color3.new(1, 1, 1)
TargetLabel.TextSize = 13
TargetLabel.Font = Enum.Font.Gotham
TargetLabel.TextXAlignment = Enum.TextXAlignment.Left
TargetLabel.Parent = Frame

-- // CAMLOCK DROPDOWN
local CamlockDropBtn = Instance.new("TextButton")
CamlockDropBtn.Size = UDim2.new(0.9, 0, 0, 30)
CamlockDropBtn.Position = UDim2.new(0.05, 0, 0, 465)
CamlockDropBtn.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
CamlockDropBtn.BorderSizePixel = 0
CamlockDropBtn.Text = "▼  Select Player..."
CamlockDropBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
CamlockDropBtn.TextSize = 13
CamlockDropBtn.Font = Enum.Font.Gotham
CamlockDropBtn.TextXAlignment = Enum.TextXAlignment.Left
CamlockDropBtn.TextTruncate = Enum.TextTruncate.AtEnd
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

local function RefreshCamlockDropdown()
	for _, child in pairs(CamlockDropFrame:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	local entries = {}
	table.insert(entries, {label = "None", player = nil})
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			table.insert(entries, {label = plr.Name .. " (" .. plr.DisplayName .. ")", player = plr})
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
				CamlockDropBtn.Text = "▼  " .. entry.player.Name
				CamlockDropBtn.TextColor3 = Color3.new(1, 1, 1)
				TargetLabel.Text = "Target: " .. entry.player.Name
			else
				CamlockDropBtn.Text = "▼  Select Player..."
				CamlockDropBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
				TargetLabel.Text = "Target: none"
			end
			CamlockDropFrame.Visible = false
			camlockDropOpen = false
		end)
	end
end

CamlockDropBtn.MouseButton1Click:Connect(function()
	camlockDropOpen = not camlockDropOpen
	if camlockDropOpen then
		RefreshCamlockDropdown()
		CamlockDropFrame.Visible = true
	else
		CamlockDropFrame.Visible = false
	end
end)

Players.PlayerAdded:Connect(function()
	if camlockDropOpen then RefreshCamlockDropdown() end
end)
Players.PlayerRemoving:Connect(function(plr)
	if plr == CAMLOCK_TARGET then
		CAMLOCK_TARGET = nil
		TargetLabel.Text = "Target: none"
		CamlockDropBtn.Text = "▼  Select Player..."
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

-- Camlock logic
RunService.RenderStepped:Connect(function()
 if not CAMLOCK_ENABLED or not CAMLOCK_TARGET then return end
 local char = CAMLOCK_TARGET.Character
 if not char then return end
 local head = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
 if not head then return end
 local camera = workspace.CurrentCamera
 local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
 if not hrp then return end
 camera.CFrame = CFrame.new(camera.CFrame.Position, head.Position)
end)

-- // FLY TOGGLE
local FLY_ENABLED = false
local FLY_SPEED = 25
local flyBodyVelocity = nil
local flyBodyGyro = nil
local flyConnection = nil

local FlyToggle = Instance.new("TextButton")
FlyToggle.Size = UDim2.new(0.9, 0, 0, 40)
FlyToggle.Position = UDim2.new(0.05, 0, 0, 510)
FlyToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
FlyToggle.Text = "Fly: Disabled"
FlyToggle.TextColor3 = Color3.new(1, 1, 1)
FlyToggle.TextSize = 14
FlyToggle.Font = Enum.Font.GothamSemibold
FlyToggle.Parent = Frame

local function StartFly()
 local character = LocalPlayer.Character
 if not character then return end
 local hrp = character:FindFirstChild("HumanoidRootPart")
 if not hrp then return end
 local humanoid = character:FindFirstChildOfClass("Humanoid")
 if humanoid then humanoid.PlatformStand = true end

 flyBodyVelocity = Instance.new("BodyVelocity")
 flyBodyVelocity.Velocity = Vector3.zero
 flyBodyVelocity.MaxForce = Vector3.new(1e5, 1e5, 1e5)
 flyBodyVelocity.Parent = hrp

 flyBodyGyro = Instance.new("BodyGyro")
 flyBodyGyro.MaxTorque = Vector3.new(1e5, 1e5, 1e5)
 flyBodyGyro.P = 1e4
 flyBodyGyro.CFrame = hrp.CFrame
 flyBodyGyro.Parent = hrp

 flyConnection = RunService.RenderStepped:Connect(function()
 if not FLY_ENABLED then return end
 local camera = workspace.CurrentCamera
 local direction = Vector3.zero
 if UserInputService:IsKeyDown(Enum.KeyCode.W) then direction = direction + camera.CFrame.LookVector end
 if UserInputService:IsKeyDown(Enum.KeyCode.S) then direction = direction - camera.CFrame.LookVector end
 if UserInputService:IsKeyDown(Enum.KeyCode.A) then direction = direction - camera.CFrame.RightVector end
 if UserInputService:IsKeyDown(Enum.KeyCode.D) then direction = direction + camera.CFrame.RightVector end
 if UserInputService:IsKeyDown(Enum.KeyCode.Space) then direction = direction + Vector3.new(0, 1, 0) end
 if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) then direction = direction - Vector3.new(0, 1, 0) end
 if direction.Magnitude > 0 then
 flyBodyVelocity.Velocity = direction.Unit * FLY_SPEED
 else
 flyBodyVelocity.Velocity = Vector3.zero
 end
 flyBodyGyro.CFrame = camera.CFrame
 end)
end

local function StopFly()
 if flyConnection then flyConnection:Disconnect() flyConnection = nil end
 if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
 if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
 local character = LocalPlayer.Character
 if character then
 local humanoid = character:FindFirstChildOfClass("Humanoid")
 if humanoid then humanoid.PlatformStand = false end
 end
end

-- // FLY SPEED SLIDER
local FlySpeedLabel = Instance.new("TextLabel")
FlySpeedLabel.Size = UDim2.new(0.9, 0, 0, 20)
FlySpeedLabel.Position = UDim2.new(0.05, 0, 0, 558)
FlySpeedLabel.BackgroundTransparency = 1
FlySpeedLabel.Text = "Fly Speed: " .. math.floor(FLY_SPEED)
FlySpeedLabel.TextColor3 = Color3.new(1, 1, 1)
FlySpeedLabel.TextSize = 14
FlySpeedLabel.Font = Enum.Font.Gotham
FlySpeedLabel.Parent = Frame

local FlySpeedSlider = Instance.new("Frame")
FlySpeedSlider.Size = UDim2.new(0.9, 0, 0, 8)
FlySpeedSlider.Position = UDim2.new(0.05, 0, 0, 583)
FlySpeedSlider.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
FlySpeedSlider.BorderSizePixel = 0
FlySpeedSlider.Parent = Frame

local FlySpeedKnob = Instance.new("Frame")
FlySpeedKnob.Size = UDim2.new(0, 16, 0, 16)
FlySpeedKnob.BackgroundColor3 = Color3.fromRGB(0, 170, 255)
FlySpeedKnob.BorderSizePixel = 0
FlySpeedKnob.Parent = FlySpeedSlider

local flySpeedDragging = false

local function updateFlySpeedSlider()
 local percent = math.clamp((FLY_SPEED - 5) / 195, 0, 1)
 FlySpeedKnob.Position = UDim2.new(percent, -8, 0.5, -8)
 FlySpeedLabel.Text = "Fly Speed: " .. math.floor(FLY_SPEED)
end

FlySpeedSlider.InputBegan:Connect(function(input)
 if input.UserInputType == Enum.UserInputType.MouseButton1 then
 flySpeedDragging = true
 end
end)

UserInputService.InputEnded:Connect(function(input)
 if input.UserInputType == Enum.UserInputType.MouseButton1 then
 flySpeedDragging = false
 end
end)

RunService.RenderStepped:Connect(function()
 if flySpeedDragging then
 local mouseX = UserInputService:GetMouseLocation().X
 local sliderX = FlySpeedSlider.AbsolutePosition.X
 local sliderWidth = FlySpeedSlider.AbsoluteSize.X
 local percent = math.clamp((mouseX - sliderX) / sliderWidth, 0, 1)
 FLY_SPEED = math.floor(5 + (percent * 195)) -- range 5 to 200
 updateFlySpeedSlider()
 end
end)

updateFlySpeedSlider()

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
 FLY_ENABLED = false
 FlyToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
 FlyToggle.Text = "Fly: Disabled"
 StopFly()
 end
 if CAMLOCK_ENABLED then
 CAMLOCK_ENABLED = false
 CamlockToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
 CamlockToggle.Text = "Camlock: Disabled"
 end
end)

-- // NOCLIP TOGGLE
local NOCLIP_ENABLED = false

local NoclipToggle = Instance.new("TextButton")
NoclipToggle.Size = UDim2.new(0.9, 0, 0, 40)
NoclipToggle.Position = UDim2.new(0.05, 0, 0, 608)
NoclipToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
NoclipToggle.Text = "Noclip: Disabled"
NoclipToggle.TextColor3 = Color3.new(1, 1, 1)
NoclipToggle.TextSize = 14
NoclipToggle.Font = Enum.Font.GothamSemibold
NoclipToggle.Parent = Frame

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

-- Noclip logic
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

LocalPlayer.CharacterAdded:Connect(function()
 if NOCLIP_ENABLED then
 NOCLIP_ENABLED = false
 NoclipToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
 NoclipToggle.Text = "Noclip: Disabled"
 end
end)

UserInputService.InputBegan:Connect(function(input, gameProcessed)
 if gameProcessed then return end
 if input.KeyCode == Enum.KeyCode.K then
 Frame.Visible = not Frame.Visible
 end
end)

print("✅ Silent Aim GUI Loaded (K = Toggle GUI)")

-- // AUTO RESET ON LOW HEALTH (Strong Version)
local AUTO_RESET_ENABLED = true
local RESET_HEALTH_THRESHOLD = 10
local lastResetTime = 0

local function safeResetCharacter()
 local currentTime = tick()
 if currentTime - lastResetTime < 2 then return end -- 2 second cooldown

 local character = LocalPlayer.Character
 if not character then return end

 local humanoid = character:FindFirstChildOfClass("Humanoid")
 if not humanoid then return end

 if humanoid.Health > RESET_HEALTH_THRESHOLD or humanoid.Health <= 0 then
 return
 end

 lastResetTime = currentTime
 print("⚠️ Low HP (" .. math.floor(humanoid.Health) .. ") - Forcing Reset!")

 -- Primary reset method
 pcall(function()
 LocalPlayer:LoadCharacter()
 end)

 -- Backup: Kill humanoid if LoadCharacter didn't work
 task.delay(0.5, function()
 pcall(function()
 if LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid") then
 LocalPlayer.Character:FindFirstChildOfClass("Humanoid").Health = 0
 end
 end)
 end)
end

-- Main monitoring loop (very frequent)
RunService.Heartbeat:Connect(safeResetCharacter)

-- Reconnect on respawn
LocalPlayer.CharacterAdded:Connect(function()
 task.wait(0.8)
 print("✅ Respawned - Auto reset active again")
end)

print("✅ Strong Auto Reset on ≤10 HP Loaded")

-- // NAME AIMLOCK GUI
local NameAimlockLabel = Instance.new("TextLabel")
NameAimlockLabel.Size = UDim2.new(0.9, 0, 0, 20)
NameAimlockLabel.Position = UDim2.new(0.05, 0, 0, 665)
NameAimlockLabel.BackgroundTransparency = 1
NameAimlockLabel.Text = "Name Aimlock: none"
NameAimlockLabel.TextColor3 = Color3.fromRGB(255, 200, 50)
NameAimlockLabel.TextSize = 13
NameAimlockLabel.Font = Enum.Font.GothamSemibold
NameAimlockLabel.TextXAlignment = Enum.TextXAlignment.Left
NameAimlockLabel.Parent = Frame

-- // AIMLOCK DROPDOWN
local AimlockDropBtn = Instance.new("TextButton")
AimlockDropBtn.Size = UDim2.new(0.9, 0, 0, 32)
AimlockDropBtn.Position = UDim2.new(0.05, 0, 0, 688)
AimlockDropBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
AimlockDropBtn.BorderSizePixel = 0
AimlockDropBtn.Text = "▼  Select Player..."
AimlockDropBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
AimlockDropBtn.TextSize = 13
AimlockDropBtn.Font = Enum.Font.GothamSemibold
AimlockDropBtn.TextXAlignment = Enum.TextXAlignment.Left
AimlockDropBtn.TextTruncate = Enum.TextTruncate.AtEnd
do
	local pad = Instance.new("UIPadding")
	pad.PaddingLeft = UDim.new(0, 8)
	pad.Parent = AimlockDropBtn
end
AimlockDropBtn.Parent = Frame

local AimlockDropFrame = Instance.new("ScrollingFrame")
AimlockDropFrame.Size = UDim2.new(0.9, 0, 0, 0)
AimlockDropFrame.Position = UDim2.new(0.05, 0, 0, 721)
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
NameAimlockStatus.Position = UDim2.new(0.05, 0, 0, 724)
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
		AimlockDropBtn.Text = "▼  " .. plr.Name
		AimlockDropBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
		NameAimlockStatus.Text = "Status: LOCKED"
		NameAimlockStatus.TextColor3 = Color3.fromRGB(0, 200, 80)
		-- Auto-disable FOV lock so name aimlock has full range
		Aiming.ShowFOV = false
		Aiming.FOV = 9999
		Settings.ShowFOV = false
		Settings.FOV = 9999
		FOVCircleToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
		FOVCircleToggle.Text = "CursorLock Circle: Hidden"
	else
		NameAimlockLabel.Text = "Name Aimlock: none"
		AimlockDropBtn.Text = "▼  Select Player..."
		AimlockDropBtn.TextColor3 = Color3.fromRGB(180, 180, 180)
		NameAimlockStatus.Text = "Status: inactive"
		NameAimlockStatus.TextColor3 = Color3.fromRGB(170, 0, 0)
	end
end

local function RefreshAimlockDropdown()
	for _, child in pairs(AimlockDropFrame:GetChildren()) do
		if child:IsA("TextButton") then child:Destroy() end
	end
	local entries = {}
	table.insert(entries, {label = "None", player = nil})
	for _, plr in pairs(Players:GetPlayers()) do
		if plr ~= LocalPlayer then
			table.insert(entries, {label = plr.Name .. " (" .. plr.DisplayName .. ")", player = plr})
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
		end)
	end
end

AimlockDropBtn.MouseButton1Click:Connect(function()
	aimlockDropOpen = not aimlockDropOpen
	if aimlockDropOpen then
		RefreshAimlockDropdown()
		AimlockDropFrame.Visible = true
	else
		AimlockDropFrame.Visible = false
	end
end)

-- Auto-clear Name Aimlock if the target leaves the game
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
