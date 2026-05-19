--[[

 ____ __ __ _ _ _ _ __ ____ ____
/ ___)( ) / _ ( \/ )/ )(  / _ ( _ \( __)
\___ \/ (_/\/  ) (  / //  ) / ) _)
(____/\____/\_/\_/(_/\_)(_/\_)\_/\_/(__\_)(____)

-- made by grok ai btw lol cry idgaf
-- Features: auto-reset at 10hp (toggle), aimlock, esp, camlock
-- The Streets

]]

-- // Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- // ─────────────────────────────────────────────
-- // AUTO-FIRE PROXIMITY PROMPTS
-- // Fires any ProximityPrompt the moment the player
-- // enters its activation radius — no key, no hold.
-- // ─────────────────────────────────────────────

local function hookAutoFire(prompt)
 prompt.PromptShown:Connect(function()
 task.wait(0.05) -- one frame buffer so the game registers proximity
 pcall(function()
 prompt.HoldDuration = 0 -- instant, no hold needed
 prompt.RequiresLineOfSight = false
 prompt:InputHoldBegin()
 task.wait(prompt.HoldDuration) -- 0 = fires instantly
 prompt:InputHoldEnd()
 end)
 end)
end

-- Hook all prompts already in the workspace
for _, desc in pairs(workspace:GetDescendants()) do
 if desc:IsA("ProximityPrompt") then
 hookAutoFire(desc)
 end
end

-- Hook any prompts added later (e.g. when a new shop area loads)
workspace.DescendantAdded:Connect(function(desc)
 if desc:IsA("ProximityPrompt") then
 hookAutoFire(desc)
 end
end)

-- // Load Aiming Library
local Aiming = loadstring(game:HttpGet("https://raw.githubusercontent.com/Ezucii/new/main/sourceeeeeeeeeeeeee.lua"))()

Aiming.TeamCheck(false)
Aiming.ShowFOV = true
Aiming.FOV = 60

-- // Settings
local Settings = {
 Enabled = true,
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
 return targetPart.CFrame + (targetPart.Velocity * 0.125)
 else
 return targetPart
 end
 end
 end
 end

 -- // Standard FOV aimlock (only runs when Name Aimlock is off)
 if t:IsA("Mouse") and (k == "Hit" or k == "Target") and CanSilentAim() and Settings.Enabled then
 local TargetPart = Aiming.SelectedPart
 local Predicted = TargetPart.CFrame + (TargetPart.Velocity * 0.125)

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
Frame.Size = UDim2.new(0, 280, 0, 840)
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

-- // AUTORESET TOGGLE
local AUTO_RESET_ENABLED = true

local AutoResetToggle = Instance.new("TextButton")
AutoResetToggle.Size = UDim2.new(0.9, 0, 0, 40)
AutoResetToggle.Position = UDim2.new(0.05, 0, 0, 100)
AutoResetToggle.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
AutoResetToggle.Text = "Auto Reset (10 HP): Enabled"
AutoResetToggle.TextColor3 = Color3.new(1, 1, 1)
AutoResetToggle.TextSize = 14
AutoResetToggle.Font = Enum.Font.GothamSemibold
AutoResetToggle.Parent = Frame

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
CamlockDropBtn.Text = "▼ Select Player..."
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
local RESET_HEALTH_THRESHOLD = 10
local lastResetTime = 0

local function safeResetCharacter()
 if not AUTO_RESET_ENABLED then return end
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
AimlockDropBtn.Text = "▼ Select Player..."
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
 AimlockDropBtn.Text = "▼ " .. plr.Name
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
 AimlockDropBtn.Text = "▼ Select Player..."
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

-- // ─────────────────────────────────────────────
-- // COMMAND BAR
-- // ─────────────────────────────────────────────

-- Separator line above command bar
local CmdSeparator = Instance.new("Frame")
CmdSeparator.Size = UDim2.new(0.9, 0, 0, 1)
CmdSeparator.Position = UDim2.new(0.05, 0, 0, 768)
CmdSeparator.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
CmdSeparator.BorderSizePixel = 0
CmdSeparator.Parent = Frame

-- Label above the box
local CmdLabel = Instance.new("TextLabel")
CmdLabel.Size = UDim2.new(0.9, 0, 0, 16)
CmdLabel.Position = UDim2.new(0.05, 0, 0, 773)
CmdLabel.BackgroundTransparency = 1
CmdLabel.Text = "Command Bar"
CmdLabel.TextColor3 = Color3.fromRGB(160, 160, 160)
CmdLabel.TextSize = 11
CmdLabel.Font = Enum.Font.Gotham
CmdLabel.TextXAlignment = Enum.TextXAlignment.Left
CmdLabel.Parent = Frame

-- The text input box
local CmdBox = Instance.new("TextBox")
CmdBox.Size = UDim2.new(0.9, 0, 0, 34)
CmdBox.Position = UDim2.new(0.05, 0, 0, 792)
CmdBox.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
CmdBox.BorderSizePixel = 1
CmdBox.BorderColor3 = Color3.fromRGB(80, 80, 80)
CmdBox.PlaceholderText = "e.g. bind aimlock f"
CmdBox.PlaceholderColor3 = Color3.fromRGB(90, 90, 90)
CmdBox.Text = ""
CmdBox.TextColor3 = Color3.new(1, 1, 1)
CmdBox.TextSize = 13
CmdBox.Font = Enum.Font.Gotham
CmdBox.ClearTextOnFocus = false
CmdBox.ZIndex = 5
CmdBox.Parent = Frame

do
 local pad = Instance.new("UIPadding")
 pad.PaddingLeft = UDim.new(0, 8)
 pad.PaddingRight = UDim.new(0, 8)
 pad.Parent = CmdBox
end

-- Feedback label shown below the box
local CmdFeedback = Instance.new("TextLabel")
CmdFeedback.Size = UDim2.new(0.9, 0, 0, 14)
CmdFeedback.Position = UDim2.new(0.05, 0, 0, 829)
CmdFeedback.BackgroundTransparency = 1
CmdFeedback.Text = ""
CmdFeedback.TextColor3 = Color3.fromRGB(0, 200, 80)
CmdFeedback.TextSize = 11
CmdFeedback.Font = Enum.Font.Gotham
CmdFeedback.TextXAlignment = Enum.TextXAlignment.Left
CmdFeedback.ZIndex = 5
CmdFeedback.Parent = Frame

-- Binds table: [toggleName] = KeyCode enum name string
local Binds = {}

-- Remembers the last Name Aimlock target so we can restore it when re-enabling
local _lastNameAimlockTarget = nil

-- Helper: map a simple key string to the Enum.KeyCode name
local function ResolveKeyCode(keyStr)
 -- Single letter A-Z
 if #keyStr == 1 and keyStr:match("^%a$") then
 return "KeyCode." .. keyStr:upper()
 end
 -- F1-F12
 if keyStr:match("^[fF]%d%d?$") then
 return "KeyCode." .. keyStr:upper()
 end
 -- Named keys mapping
 local named = {
 ["space"] = "KeyCode.Space",
 ["shift"] = "KeyCode.LeftShift",
 ["lshift"] = "KeyCode.LeftShift",
 ["rshift"] = "KeyCode.RightShift",
 ["ctrl"] = "KeyCode.LeftControl",
 ["lctrl"] = "KeyCode.LeftControl",
 ["rctrl"] = "KeyCode.RightControl",
 ["alt"] = "KeyCode.LeftAlt",
 ["lalt"] = "KeyCode.LeftAlt",
 ["ralt"] = "KeyCode.RightAlt",
 ["tab"] = "KeyCode.Tab",
 ["capslock"] = "KeyCode.CapsLock",
 ["enter"] = "KeyCode.Return",
 ["return"] = "KeyCode.Return",
 ["backspace"] = "KeyCode.Backspace",
 ["delete"] = "KeyCode.Delete",
 ["insert"] = "KeyCode.Insert",
 ["home"] = "KeyCode.Home",
 ["end"] = "KeyCode.End",
 ["pageup"] = "KeyCode.PageUp",
 ["pagedown"] = "KeyCode.PageDown",
 ["up"] = "KeyCode.Up",
 ["down"] = "KeyCode.Down",
 ["left"] = "KeyCode.Left",
 ["right"] = "KeyCode.Right",
 ["num0"] = "KeyCode.Zero",
 ["num1"] = "KeyCode.One",
 ["num2"] = "KeyCode.Two",
 ["num3"] = "KeyCode.Three",
 ["num4"] = "KeyCode.Four",
 ["num5"] = "KeyCode.Five",
 ["num6"] = "KeyCode.Six",
 ["num7"] = "KeyCode.Seven",
 ["num8"] = "KeyCode.Eight",
 ["num9"] = "KeyCode.Nine",
 }
 return named[keyStr:lower()]
end

-- Toggle dispatcher: given a name, flip the toggle
-- Helper: fire a Roblox toast notification
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
 -- True if either the main aimlock OR the name aimlock is currently active
 local anyActive = Aiming.Enabled or NAME_AIMLOCK_ENABLED
 if anyActive then
 -- ── Turn EVERYTHING off ──────────────────────────────────────────
 Aiming.Enabled = false
 Settings.Enabled = false
 ToggleBtn.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
 ToggleBtn.Text = "Disabled CursorLock"
 -- Save + clear the Name Aimlock target
 if NAME_AIMLOCK_ENABLED and NAME_AIMLOCK_TARGET then
 _lastNameAimlockTarget = NAME_AIMLOCK_TARGET
 end
 SetAimlockTarget(nil)
 Notify("Aimlock", "🔴 Turned OFF")
 else
 -- ── Turn main aimlock back ON ─────────────────────────────────────
 Aiming.Enabled = true
 Settings.Enabled = true
 ToggleBtn.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
 ToggleBtn.Text = "Enabled CursorLock"
 -- Restore the last Name Aimlock target if one was saved
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
 end
end

-- Valid toggle names for validation
local VALID_TOGGLES = {
 ["aimlock"] = true,
 ["autoreset"] = true,
 ["fly"] = true,
 ["noclip"] = true,
 ["camlock"] = true,
 ["tpwalk"] = true,
 ["fovvisible"] = true,
 ["keylock"] = true, -- mouse-target aimlock setter
}

-- // ─────────────────────────────────────────────
-- // CMD POPUP WINDOW
-- // ─────────────────────────────────────────────

local CMD_LIST = {
 { cmd = "bind <command> <key>", desc = "Bind a key to toggle a feature on/off" },
 { cmd = "unbind ", desc = "Remove the bind from a toggle" },
 { cmd = "binds", desc = "List all your currently active binds" },
 { cmd = "cmd", desc = "Open / close this command list" },
 { cmd = "help", desc = "Quick tip for the command bar" },
 { cmd = "chatenable", desc = "Re-enable the Roblox chat window & input bar" },
 { cmd = "", desc = "── Bindable toggles ──────────────────" },
 { cmd = "aimlock", desc = "CursorLock + Name Aimlock (kill-switch)" },
 { cmd = "autoreset", desc = "Auto reset character at ≤10 HP" },
 { cmd = "fly", desc = "Fly mode" },
 { cmd = "noclip", desc = "No-clip through walls" },
 { cmd = "camlock", desc = "Lock camera onto selected player" },
 { cmd = "tpwalk", desc = "Teleport-step walking" },
 { cmd = "fovvisible", desc = "Show / hide the FOV circle" },
 { cmd = "keylock", desc = "Hover cursor on a player + press bind to lock aimlock on them" },
}

local ROW_H = 36
local POPUP_W = 400
local HEADER_H = 38
local FOOTER_H = 36
local POPUP_H = HEADER_H + (#CMD_LIST * ROW_H) + FOOTER_H + 8

-- Popup container (floating, draggable, starts hidden)
local CmdPopup = Instance.new("Frame")
CmdPopup.Name = "CmdPopup"
CmdPopup.Size = UDim2.new(0, POPUP_W, 0, POPUP_H)
CmdPopup.Position = UDim2.new(0.5, -(POPUP_W / 2), 0.5, -(POPUP_H / 2) - 60)
CmdPopup.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
CmdPopup.BorderSizePixel = 0
CmdPopup.Visible = false
CmdPopup.ZIndex = 20
CmdPopup.Active = true
CmdPopup.Draggable = false
CmdPopup.Parent = ScreenGui

do
 local corner = Instance.new("UICorner")
 corner.CornerRadius = UDim.new(0, 6)
 corner.Parent = CmdPopup
end

-- Drag logic for the popup
do
 local popupDragging = false
 local popupDragStart = nil
 local popupStartPos = nil

 CmdPopup.InputBegan:Connect(function(input)
 if input.UserInputType == Enum.UserInputType.MouseButton1 then
 popupDragging = true
 popupDragStart = input.Position
 popupStartPos = CmdPopup.Position
 end
 end)
 CmdPopup.InputEnded:Connect(function(input)
 if input.UserInputType == Enum.UserInputType.MouseButton1 then
 popupDragging = false
 end
 end)
 UserInputService.InputChanged:Connect(function(input)
 if popupDragging and input.UserInputType == Enum.UserInputType.MouseMovement then
 local delta = input.Position - popupDragStart
 CmdPopup.Position = UDim2.new(
 popupStartPos.X.Scale, popupStartPos.X.Offset + delta.X,
 popupStartPos.Y.Scale, popupStartPos.Y.Offset + delta.Y
 )
 end
 end)
end

-- Header bar
local PopupHeader = Instance.new("Frame")
PopupHeader.Size = UDim2.new(1, 0, 0, HEADER_H)
PopupHeader.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
PopupHeader.BorderSizePixel = 0
PopupHeader.ZIndex = 21
PopupHeader.Parent = CmdPopup

do
 local corner = Instance.new("UICorner")
 corner.CornerRadius = UDim.new(0, 6)
 corner.Parent = PopupHeader
end

-- Patch bottom corners of header (UICorner rounds all four)
local headerPatch = Instance.new("Frame")
headerPatch.Size = UDim2.new(1, 0, 0, 8)
headerPatch.Position = UDim2.new(0, 0, 1, -8)
headerPatch.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
headerPatch.BorderSizePixel = 0
headerPatch.ZIndex = 21
headerPatch.Parent = PopupHeader

local PopupTitle = Instance.new("TextLabel")
PopupTitle.Size = UDim2.new(1, -44, 1, 0)
PopupTitle.Position = UDim2.new(0, 12, 0, 0)
PopupTitle.BackgroundTransparency = 1
PopupTitle.Text = "⌨ Command List"
PopupTitle.TextColor3 = Color3.new(1, 1, 1)
PopupTitle.TextSize = 14
PopupTitle.Font = Enum.Font.GothamSemibold
PopupTitle.TextXAlignment = Enum.TextXAlignment.Left
PopupTitle.ZIndex = 22
PopupTitle.Parent = PopupHeader

-- Close button (×)
local PopupClose = Instance.new("TextButton")
PopupClose.Size = UDim2.new(0, 28, 0, 28)
PopupClose.Position = UDim2.new(1, -34, 0.5, -14)
PopupClose.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
PopupClose.Text = "✕"
PopupClose.TextColor3 = Color3.new(1, 1, 1)
PopupClose.TextSize = 14
PopupClose.Font = Enum.Font.GothamSemibold
PopupClose.BorderSizePixel = 0
PopupClose.ZIndex = 22
PopupClose.Parent = PopupHeader

do
 local corner = Instance.new("UICorner")
 corner.CornerRadius = UDim.new(0, 4)
 corner.Parent = PopupClose
end

PopupClose.MouseButton1Click:Connect(function()
 CmdPopup.Visible = false
end)

-- Scrolling body
local PopupScroll = Instance.new("ScrollingFrame")
PopupScroll.Size = UDim2.new(1, 0, 1, -(HEADER_H + FOOTER_H + 4))
PopupScroll.Position = UDim2.new(0, 0, 0, HEADER_H + 2)
PopupScroll.BackgroundTransparency = 1
PopupScroll.BorderSizePixel = 0
PopupScroll.ScrollBarThickness = 4
PopupScroll.ScrollBarImageColor3 = Color3.fromRGB(80, 80, 80)
PopupScroll.CanvasSize = UDim2.new(0, 0, 0, #CMD_LIST * ROW_H)
PopupScroll.ZIndex = 21
PopupScroll.Parent = CmdPopup

-- Populate rows
for i, entry in ipairs(CMD_LIST) do
 local isSeparator = entry.cmd == ""

 local row = Instance.new("Frame")
 row.Size = UDim2.new(1, -8, 0, ROW_H - 2)
 row.Position = UDim2.new(0, 4, 0, (i - 1) * ROW_H + 2)
 row.BackgroundColor3 = isSeparator
 and Color3.fromRGB(28, 28, 28)
 or (i % 2 == 0 and Color3.fromRGB(28, 28, 28) or Color3.fromRGB(33, 33, 33))
 row.BorderSizePixel = 0
 row.ZIndex = 22
 row.Parent = PopupScroll

 do
 local corner = Instance.new("UICorner")
 corner.CornerRadius = UDim.new(0, 4)
 corner.Parent = row
 end

 if isSeparator then
 -- Section divider label
 local sepLabel = Instance.new("TextLabel")
 sepLabel.Size = UDim2.new(1, -10, 1, 0)
 sepLabel.Position = UDim2.new(0, 8, 0, 0)
 sepLabel.BackgroundTransparency = 1
 sepLabel.Text = entry.desc
 sepLabel.TextColor3 = Color3.fromRGB(120, 120, 120)
 sepLabel.TextSize = 11
 sepLabel.Font = Enum.Font.Gotham
 sepLabel.TextXAlignment = Enum.TextXAlignment.Left
 sepLabel.ZIndex = 23
 sepLabel.Parent = row
 else
 -- Command name (left, highlighted)
 local cmdLabel = Instance.new("TextLabel")
 cmdLabel.Size = UDim2.new(0.42, -4, 1, 0)
 cmdLabel.Position = UDim2.new(0, 10, 0, 0)
 cmdLabel.BackgroundTransparency = 1
 cmdLabel.Text = entry.cmd
 cmdLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
 cmdLabel.TextSize = 12
 cmdLabel.Font = Enum.Font.GothamSemibold
 cmdLabel.TextXAlignment = Enum.TextXAlignment.Left
 cmdLabel.ZIndex = 23
 cmdLabel.Parent = row

 -- Description (right, muted)
 local descLabel = Instance.new("TextLabel")
 descLabel.Size = UDim2.new(0.58, -10, 1, 0)
 descLabel.Position = UDim2.new(0.42, 4, 0, 0)
 descLabel.BackgroundTransparency = 1
 descLabel.Text = entry.desc
 descLabel.TextColor3 = Color3.fromRGB(190, 190, 190)
 descLabel.TextSize = 11
 descLabel.Font = Enum.Font.Gotham
 descLabel.TextXAlignment = Enum.TextXAlignment.Left
 descLabel.ZIndex = 23
 descLabel.Parent = row
 end
end

-- Footer hint
local PopupFooter = Instance.new("TextLabel")
PopupFooter.Size = UDim2.new(1, -16, 0, FOOTER_H)
PopupFooter.Position = UDim2.new(0, 8, 1, -FOOTER_H - 2)
PopupFooter.BackgroundTransparency = 1
PopupFooter.Text = "Type a command in the bar below • drag this window to move it"
PopupFooter.TextColor3 = Color3.fromRGB(90, 90, 90)
PopupFooter.TextSize = 10
PopupFooter.Font = Enum.Font.Gotham
PopupFooter.TextXAlignment = Enum.TextXAlignment.Center
PopupFooter.ZIndex = 21
PopupFooter.Parent = CmdPopup

-- // ─────────────────────────────────────────────
-- Command parser
local function ParseCommand(raw)
 local parts = {}
 for word in raw:gmatch("%S+") do
 table.insert(parts, word:lower())
 end
 if #parts == 0 then return end

 local cmd = parts[1]

 -- BIND command: bind
 if cmd == "bind" then
 if #parts < 3 then
 CmdFeedback.TextColor3 = Color3.fromRGB(255, 80, 80)
 CmdFeedback.Text = "Usage: bind "
 return
 end
 local toggleName = parts[2]
 local keyName = parts[3]

 if not VALID_TOGGLES[toggleName] then
 CmdFeedback.TextColor3 = Color3.fromRGB(255, 80, 80)
 CmdFeedback.Text = "Unknown toggle: " .. toggleName
 return
 end

 local keyCodePath = ResolveKeyCode(keyName)
 if not keyCodePath then
 CmdFeedback.TextColor3 = Color3.fromRGB(255, 80, 80)
 CmdFeedback.Text = "Unknown key: " .. keyName
 return
 end

 -- e.g. keyCodePath = "KeyCode.F" → split to get the actual Enum value
 local enumName = keyCodePath:match("KeyCode%.(.+)")
 local ok, keyEnum = pcall(function()
 return Enum.KeyCode[enumName]
 end)
 if not ok or not keyEnum then
 CmdFeedback.TextColor3 = Color3.fromRGB(255, 80, 80)
 CmdFeedback.Text = "Invalid key: " .. keyName
 return
 end

 -- Unbind previous if same toggle was already bound to another key
 Binds[toggleName] = keyEnum

 CmdFeedback.TextColor3 = Color3.fromRGB(0, 200, 80)
 CmdFeedback.Text = "Bound " .. toggleName .. " → " .. keyName:upper()
 return
 end

 -- UNBIND command: unbind
 if cmd == "unbind" then
 if #parts < 2 then
 CmdFeedback.TextColor3 = Color3.fromRGB(255, 80, 80)
 CmdFeedback.Text = "Usage: unbind "
 return
 end
 local toggleName = parts[2]
 if not VALID_TOGGLES[toggleName] then
 CmdFeedback.TextColor3 = Color3.fromRGB(255, 80, 80)
 CmdFeedback.Text = "Unknown toggle: " .. toggleName
 return
 end
 if Binds[toggleName] then
 Binds[toggleName] = nil
 CmdFeedback.TextColor3 = Color3.fromRGB(255, 180, 0)
 CmdFeedback.Text = "Unbound " .. toggleName
 else
 CmdFeedback.TextColor3 = Color3.fromRGB(160, 160, 160)
 CmdFeedback.Text = toggleName .. " has no bind"
 end
 return
 end

 -- BINDS command: list all current binds
 if cmd == "binds" then
 local out = ""
 for name, key in pairs(Binds) do
 out = out .. name .. "=" .. tostring(key).." "
 end
 CmdFeedback.TextColor3 = Color3.fromRGB(180, 180, 255)
 CmdFeedback.Text = out ~= "" and ("Binds: " .. out) or "No binds set"
 return
 end



 -- HELP command (alias)
 if cmd == "help" then
 CmdFeedback.TextColor3 = Color3.fromRGB(180, 180, 255)
 CmdFeedback.Text = "type 'cmd' to open the command list"
 return
 end

 -- CMD command: open the command list popup
 if cmd == "cmd" then
 CmdPopup.Visible = not CmdPopup.Visible
 CmdFeedback.TextColor3 = Color3.fromRGB(180, 180, 255)
 CmdFeedback.Text = CmdPopup.Visible and "Command list opened" or "Command list closed"
 return
 end

 -- CHATENABLE command: re-enable Roblox chat window and input bar
 if cmd == "chatenable" then
 local TCS = game:GetService("TextChatService")
 -- Enable chat window
 local CWC = TCS:FindFirstChildOfClass("ChatWindowConfiguration")
 if CWC then
 CWC.Enabled = true
 end
 -- Enable chat input bar
 local CIBC = TCS:FindFirstChildOfClass("ChatInputBarConfiguration")
 if CIBC then
 CIBC.Enabled = true
 end
 -- Legacy chat fallback
 local isLegacy = TCS.ChatVersion == Enum.ChatVersion.LegacyChatService
 if isLegacy then
 pcall(function()
 game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("Chat").Enabled = true
 end)
 end
 CmdFeedback.TextColor3 = Color3.fromRGB(80, 255, 120)
 CmdFeedback.Text = "Chat enabled!"
 return
 end

 CmdFeedback.TextColor3 = Color3.fromRGB(255, 80, 80)
 CmdFeedback.Text = "Unknown command: " .. cmd .. " (try: cmd)"
end

-- Submit on Enter
CmdBox.FocusLost:Connect(function(enterPressed)
 if enterPressed then
 ParseCommand(CmdBox.Text)
 CmdBox.Text = ""
 end
end)

-- Listen for bind keystrokes globally (only when GUI not focused)
UserInputService.InputBegan:Connect(function(input, gameProcessed)
 -- Block binds if ANY text box is focused (chat bar, cmd box, any input field)
 if UserInputService:GetFocusedTextBox() then return end
 for toggleName, keyEnum in pairs(Binds) do
 if input.KeyCode == keyEnum then
 if toggleName == "keylock" then
 -- Keylock: project every player's HumanoidRootPart to screen space
 -- and pick whoever is closest to the mouse cursor.
 -- No raycast = no distance limit, works through walls, any range.
 local camera = workspace.CurrentCamera
 local mousePos = UserInputService:GetMouseLocation()
 local closestPlr = nil
 local closestDist = math.huge
 for _, plr in pairs(Players:GetPlayers()) do
 if plr ~= LocalPlayer and plr.Character then
 local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
 if hrp then
 local screenPos, onScreen = camera:WorldToScreenPoint(hrp.Position)
 if onScreen then
 local d = (Vector2.new(screenPos.X, screenPos.Y) - mousePos).Magnitude
 if d < closestDist then
 closestDist = d
 closestPlr = plr
 end
 end
 end
 end
 end
 if closestPlr then
 -- Atomic swap: never set ENABLED = false so aimlock
 -- stays hot the whole time while switching targets.
 NAME_AIMLOCK_TARGET = closestPlr
 NAME_AIMLOCK_ENABLED = true
 -- Sync UI so dropdown reflects the new target
 NameAimlockLabel.Text = "Name Aimlock: " .. closestPlr.Name
 AimlockDropBtn.Text = "▼ " .. closestPlr.Name
 AimlockDropBtn.TextColor3 = Color3.fromRGB(255, 200, 50)
 NameAimlockStatus.Text = "Status: LOCKED"
 NameAimlockStatus.TextColor3 = Color3.fromRGB(0, 200, 80)
 Aiming.ShowFOV = false
 Aiming.FOV = 9999
 Settings.ShowFOV = false
 Settings.FOV = 9999
 FOVCircleToggle.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
 FOVCircleToggle.Text = "CursorLock Circle: Hidden"
 Notify("Keylock", "[LOCKED] " .. closestPlr.Name)
 end
 else
 FireToggle(toggleName)
 end
 end
 end
end)

-- Clear feedback after 4 seconds automatically
local lastFeedbackTime = 0
task.spawn(function()
 while true do
 task.wait(1)
 if CmdFeedback.Text ~= "" then
 lastFeedbackTime = lastFeedbackTime + 1
 if lastFeedbackTime >= 4 then
 CmdFeedback.Text = ""
 lastFeedbackTime = 0
 end
 else
 lastFeedbackTime = 0
 end
 end
end)

print("✅ Command Bar Loaded | try: bind aimlock f")

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
