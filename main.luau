-- Services
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local localPlayer = Players.LocalPlayer

-- Parent GUI safely (Executor / Studio compatibility)
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "DeltaBlueNetGui"
screenGui.ResetOnSpawn = false

if gethui then
    screenGui.Parent = gethui()
elseif syn and syn.protect_gui then
    syn.protect_gui(screenGui)
    screenGui.Parent = CoreGui
else
    pcall(function() screenGui.Parent = CoreGui end)
    if not screenGui.Parent then
        screenGui.Parent = localPlayer:WaitForChild("PlayerGui")
    end
end

-- Create 60x60 Solid Blue Net Part (Platform)
local netPart = Instance.new("Part")
netPart.Name = "BlueNetSquare"
netPart.Size = Vector3.new(60, 1, 60)
netPart.Color = Color3.fromRGB(0, 162, 255)
netPart.Material = Enum.Material.Neon
netPart.Transparency = 0.3
netPart.CanCollide = true
netPart.Anchored = true -- Anchored kinematic movement ensures it ignores parts/obstacles completely
netPart.Massless = true
netPart.Parent = workspace

-- Draggable Main Container Frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainContainer"
mainFrame.Size = UDim2.new(0, 290, 0, 65)
mainFrame.Position = UDim2.new(0.5, -145, 0.75, 0)
mainFrame.BackgroundTransparency = 1
mainFrame.Active = true
mainFrame.Parent = screenGui

-- Mobile & PC Smooth Dragging Implementation
local dragging = false
local dragInput, dragStart, startPos

mainFrame.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = mainFrame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

mainFrame.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
        dragInput = input
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if input == dragInput and dragging then
        local delta = input.Position - dragStart
        mainFrame.Position = UDim2.new(
            startPos.X.Scale,
            startPos.X.Offset + delta.X,
            startPos.Y.Scale,
            startPos.Y.Offset + delta.Y
        )
    end
end)

-- Styling helper for UI buttons
local function createButton(name, text, position)
    local button = Instance.new("TextButton")
    button.Name = name
    button.Size = UDim2.new(0, 135, 0, 65)
    button.Position = position
    button.BackgroundColor3 = Color3.fromRGB(220, 220, 220)
    button.BackgroundTransparency = 0.2
    button.Text = text
    button.TextColor3 = Color3.fromRGB(80, 80, 80)
    button.TextSize = 18
    button.Font = Enum.Font.SourceSans
    button.AutoButtonColor = true
    button.Parent = mainFrame

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 4)
    corner.Parent = button

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(160, 160, 160)
    stroke.Thickness = 1.5
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = button

    return button
end

-- Create Buttons side-by-side
local enableBtn = createButton("EnableNetBtn", "Enable Net", UDim2.new(0, 0, 0, 0))
local lockBtn = createButton("LockNetBtn", "Lock Net", UDim2.new(0, 155, 0, 0))

-- States
local isFollowing = true
local isLocked = false
local leftBusy = false

-- Left Button Logic ("Enable Net")
enableBtn.MouseButton1Click:Connect(function()
    if leftBusy then return end

    if lockBtn.Text == "Lock Net" then
        -- Net is already unlocked/following -> shows "Net Already Unlocked" for 1 sec
        leftBusy = true
        enableBtn.Text = "Net Already Unlocked"
        task.wait(1)
        enableBtn.Text = "Enable Net"
        leftBusy = false
    elseif lockBtn.Text == "Net Locked" then
        -- Net is locked -> unlocks net and turns "Net Locked" back to "Lock Net"
        isLocked = false
        isFollowing = true
        netPart.Anchored = true
        lockBtn.Text = "Lock Net"
    end
end)

-- Right Button Logic ("Lock Net" / "Net Locked")
lockBtn.MouseButton1Click:Connect(function()
    if lockBtn.Text == "Lock Net" then
        isLocked = true
        isFollowing = false
        netPart.Anchored = true
        lockBtn.Text = "Net Locked"
    elseif lockBtn.Text == "Net Locked" then
        isLocked = false
        isFollowing = true
        netPart.Anchored = true
        lockBtn.Text = "Lock Net"
    end
end)

-- Player Following & Fall Detection Loop
local function setupFollow(character)
    local rootPart = character:WaitForChild("HumanoidRootPart", 5)
    local humanoid = character:WaitForChild("Humanoid", 5)
    if not rootPart or not humanoid then return end

    local connection
    connection = RunService.RenderStepped:Connect(function()
        if not netPart or not netPart.Parent then
            connection:Disconnect()
            return
        end

        if isFollowing and not isLocked and rootPart then
            -- Smoothly follow feet while ignoring all parts/obstacles
            netPart.CFrame = CFrame.new(rootPart.Position.X, rootPart.Position.Y - 3.5, rootPart.Position.Z)

            -- Detect falling once and auto-lock
            local velocityY = rootPart.AssemblyLinearVelocity.Y
            local isFreefall = humanoid:GetState() == Enum.HumanoidStateType.Freefall

            if velocityY < -15 or isFreefall then
                isLocked = true
                isFollowing = false
                netPart.Anchored = true
                lockBtn.Text = "Net Locked"
            end
        end
    end)
end

if localPlayer.Character then
    setupFollow(localPlayer.Character)
end
localPlayer.CharacterAdded:Connect(setupFollow)
