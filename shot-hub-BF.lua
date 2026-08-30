-- SHOT HUB / Blox Fruit • v1.14
-- ESP + Fly + Fly to Island + Farm (исправлена ошибка LoadAnimation)

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")
local LocalPlayer = Players.LocalPlayer
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")

-- Настройки
local espEnabled = false
local flyEnabled = false
local flySpeed = 50
local espObjects = {}
local menuVisible = false
local selectedTab = "Home"
local isDraggingSlider = false
local selectedIsland = nil
local islandDropdownOpen = false
local flyingToIsland = false
local flyToIslandConnection = nil
local farmEnabled = false
local farmConnection = nil
local selectedFarmMob = nil
local farmMobDropdownOpen = false

-- Цвета
local NeonPurple = Color3.fromRGB(170, 0, 255)
local ElectricBlue = Color3.fromRGB(0, 100, 255)
local DarkBackground = Color3.fromRGB(20, 20, 25)
local DarkerBackground = Color3.fromRGB(15, 15, 20)
local WhiteText = Color3.fromRGB(255, 255, 255)

-- Список Sea 1 островов
local Sea1Islands = {
    {name = "Пустыня", position = Vector3.new(910.5, 89.7, 4373.3)},
    {name = "Средний город", position = Vector3.new(-718.2, 108.6, 1611.9)},
    {name = "Джунгли", position = Vector3.new(-1566.9, 109.9, 179.8)},
    {name = "Колизей", position = Vector3.new(-1584.5, 55.9, -2935.5)},
    {name = "Небесные земли", position = Vector3.new(-4869.0, 746.5, -2650.9)},
    {name = "Небесные земли высокие", position = Vector3.new(-4744.0, 862.5, -1998.3)},
    {name = "Морской начинающий", position = Vector3.new(-2757.2, 98.6, 2177.9)},
    {name = "Пиратская деревня", position = Vector3.new(-1206.9, 63.9, 3904.0)},
    {name = "Остров мафии", position = Vector3.new(-2860.3, 80.6, 5424.7)},
    {name = "Морская крепость", position = Vector3.new(-5021.0, 102.3, 4305.4)},
    {name = "Остров начинающих пиратов", position = Vector3.new(1084.0, 56.3, 1439.0)},
    {name = "Ледяная деревня", position = Vector3.new(1234.8, 148.7, -1420.7)},
    {name = "Тюрьма", position = Vector3.new(5125.0, 85.2, 757.9)},
    {name = "Город фонтанов", position = Vector3.new(5204.8, 100.1, 4355.1)},
    {name = "Магмовая деревня", position = Vector3.new(-5336.8, 32.5, 8506.7)},
}

-- ====================================================================
-- УНИВЕРСАЛЬНЫЙ ХЭНДЛЕР МОРЕЙ
-- ====================================================================

local Sea1Objects = {
    "FortBuilderPlacedSurfaces", "FortBuilderPotentialSurfaces", "Colosseum", "Desert", 
    "Fishmen", "Fountain", "Ice", "Jungle", "Magma", "MarineBase", 
    "MarineStart", "MobBoss", "Pirate", "Prison", "Sky", "SkyArea1", 
    "SkyArea2", "TeleportSpawn", "Town", "Windmill"
}

local Sea2Objects = {
    "CircleIsland", "DarkbeardArena", "Dressrosa", "ForgottenIsland",
    "GhostShip", "GhostShipInterior", "GravelIsland", "GreenBit",
    "IceCastle", "IndraIsland", "Mini1", "Mini2", "MiniSky",
    "RaidMap", "SnowMountain"
}

local Sea3Objects = {
    "Port", "TikiOutpost", "GreatTree", "Boat Castle", "CakeLoaf", 
    "CandyCane", "ChocolateIsland", "HauntedCastle", "Ice Cream Island", "Peanut Island"
}

local function getCurrentSea()
    local mapFolder = workspace:FindFirstChild("Map")
    
    if not mapFolder then 
        return "Map не найден" 
    end
    
    for _, objectName in ipairs(Sea3Objects) do
        if mapFolder:FindFirstChild(objectName) then 
            return "Sea 3" 
        end
    end
    
    for _, objectName in ipairs(Sea2Objects) do
        if mapFolder:FindFirstChild(objectName) then 
            return "Sea 2" 
        end
    end
    
    for _, objectName in ipairs(Sea1Objects) do
        if mapFolder:FindFirstChild(objectName) then 
            return "Sea 1" 
        end
    end
    
    return "Неизвестно"
end

local function findIsland(islandName)
    local mapFolder = workspace:FindFirstChild("Map")
    if mapFolder then
        local island = mapFolder:FindFirstChild(islandName)
        if island then 
            return island 
        end
    end
    return nil
end

-- ====================================================================
-- ФАРМ МОБОВ (ПОДЛЕТ НА 30 СТАДОВ И АТАКА ЛКМ)
-- ====================================================================

local Sea1Mobs = {
    "Bandit", "Monkey", "Pirate", "Brute", "Desert Bandit", 
    "Desert Officer", "Snow Bandit", "Snowman", "Military Soldier",
    "Military Spy", "Fishman Warrior", "Fishman Commando", "Galley Pirate",
    "Galley Captain", "Bobby", "Yeti", "Mob Leader", "Vice Admiral"
}

-- Функция расширения хитбокса моба
local function expandMobHitbox(mob)
    if not mob then return end
    
    local humanoidRootPart = mob:FindFirstChild("HumanoidRootPart")
    if not humanoidRootPart then return end
    
    -- Проверяем, есть ли уже расширенный хитбокс
    if humanoidRootPart:FindFirstChild("ExpandedHitbox") then return end
    
    -- Создаем невидимый расширенный хитбокс
    local hitbox = Instance.new("Part")
    hitbox.Name = "ExpandedHitbox"
    hitbox.Size = Vector3.new(20, 20, 20)
    hitbox.Transparency = 1
    hitbox.CanCollide = false
    hitbox.Anchored = false
    hitbox.Parent = humanoidRootPart
    
    -- Привязываем хитбокс к мобу
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = humanoidRootPart
    weld.Part1 = hitbox
    weld.Parent = hitbox
end

local function findNearestMob(mobName)
    local nearestMob = nil
    local nearestDistance = math.huge
    
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local myPosition = LocalPlayer.Character.HumanoidRootPart.Position
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Model") and obj:FindFirstChild("Humanoid") and obj:FindFirstChild("HumanoidRootPart") then
            local humanoid = obj:FindFirstChild("Humanoid")
            if humanoid.Health > 0 then
                local objName = obj.Name:lower()
                local targetName = mobName:lower()
                if objName:find(targetName) then
                    local rootPart = obj:FindFirstChild("HumanoidRootPart")
                    local distance = (myPosition - rootPart.Position).Magnitude
                    if distance < nearestDistance then
                        nearestDistance = distance
                        nearestMob = obj
                    end
                end
            end
        end
    end
    
    return nearestMob
end

-- Функция фарма (подлет на 30 стадов и атака ЛКМ)
local function startFarm(mobName)
    if farmConnection then return end
    
    farmEnabled = true
    
    farmConnection = RunService.RenderStepped:Connect(function()
        if not farmEnabled then return end
        
        local character = LocalPlayer.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then return end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        
        if not humanoid or not rootPart then return end
        
        local nearestMob = findNearestMob(mobName)
        if nearestMob and nearestMob:FindFirstChild("HumanoidRootPart") then
            local mobRoot = nearestMob:FindFirstChild("HumanoidRootPart")
            
            -- Расширяем хитбокс моба
            expandMobHitbox(nearestMob)
            
            -- Подлетаем на 30 стадов выше моба
            rootPart.CFrame = mobRoot.CFrame + Vector3.new(0, 30, 0)
            
            -- Направляем персонажа вниз на моба
            rootPart.CFrame = CFrame.lookAt(rootPart.Position, mobRoot.Position)
            
            -- Атакуем левой кнопкой мыши
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, true, nil, 0)
            task.wait(0.05)
            VirtualInputManager:SendMouseButtonEvent(0, 0, 0, false, nil, 0)
        end
        
        task.wait(0.2)
    end)
end

local function stopFarm()
    farmEnabled = false
    if farmConnection then
        farmConnection:Disconnect()
        farmConnection = nil
    end
end

-- Функция проверки Fruit
local function hasFruitInName(obj)
    if not obj or not obj.Name then return false end
    local name = obj.Name:lower()
    return name:find("fruit") ~= nil
end

-- Функция удаления ESP
local function removeToolESP(tool)
    if espObjects[tool] then
        if espObjects[tool].Highlight then pcall(function() espObjects[tool].Highlight:Destroy() end) end
        if espObjects[tool].Billboard then pcall(function() espObjects[tool].Billboard:Destroy() end) end
        espObjects[tool] = nil
    end
end

-- Функция создания ESP
local function createToolESP(tool)
    if not tool then return end
    removeToolESP(tool)
    
    local handle = tool:FindFirstChild("Handle") or tool:FindFirstChildOfClass("BasePart")
    if not handle then return end
    
    local highlight = Instance.new("Highlight")
    highlight.Name = "FruitESP_Highlight"
    highlight.FillColor = NeonPurple
    highlight.OutlineColor = ElectricBlue
    highlight.FillTransparency = 0.5
    highlight.OutlineTransparency = 0
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.Parent = tool
    
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "FruitESP_Billboard"
    billboard.Size = UDim2.new(0, 120, 0, 40)
    billboard.StudsOffset = Vector3.new(0, 2, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = handle
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = WhiteText
    textLabel.TextStrokeTransparency = 0
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextSize = 14
    textLabel.Text = "Fruit: " .. tool.Name
    textLabel.Parent = billboard
    
    espObjects[tool] = {Highlight = highlight, Billboard = billboard}
end

local function scanForFruitTools()
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") and hasFruitInName(obj) then
            createToolESP(obj)
        end
    end
    
    for _, player in ipairs(Players:GetPlayers()) do
        local backpack = player:FindFirstChild("Backpack")
        if backpack then
            for _, tool in ipairs(backpack:GetChildren()) do
                if tool:IsA("Tool") and hasFruitInName(tool) then
                    createToolESP(tool)
                end
            end
        end
        
        local character = player.Character
        if character then
            for _, tool in ipairs(character:GetChildren()) do
                if tool:IsA("Tool") and hasFruitInName(tool) then
                    createToolESP(tool)
                end
            end
        end
    end
end

local function clearAllESP()
    for tool, data in pairs(espObjects) do
        removeToolESP(tool)
    end
end

local function findNearestFruit()
    local nearestFruit = nil
    local nearestDistance = math.huge
    
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return nil
    end
    
    local myPosition = LocalPlayer.Character.HumanoidRootPart.Position
    
    for _, obj in ipairs(Workspace:GetDescendants()) do
        if obj:IsA("Tool") and hasFruitInName(obj) then
            local handle = obj:FindFirstChild("Handle") or obj:FindFirstChildOfClass("BasePart")
            if handle then
                local distance = (myPosition - handle.Position).Magnitude
                if distance < nearestDistance then
                    nearestDistance = distance
                    nearestFruit = handle
                end
            end
        end
    end
    
    return nearestFruit
end

local function teleportToNearestFruit()
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local nearestFruit = findNearestFruit()
    if nearestFruit then
        character.HumanoidRootPart.CFrame = nearestFruit.CFrame + Vector3.new(0, 5, 0)
    end
end

-- ========================== ОБЫЧНЫЙ ПОЛЕТ (ИСПРАВЛЕН) ==========================
local flyConnection = nil
local flyBodyVelocity = nil
local flyBodyGyro = nil
local flyAntiFallConnection = nil

local function startFly()
    if flyConnection then return end
    
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return end
    
    humanoid.PlatformStand = true
    humanoid.AutoRotate = false
    
    for _, child in ipairs(rootPart:GetChildren()) do
        if child:IsA("BodyVelocity") or child:IsA("BodyGyro") then
            child:Destroy()
        end
    end
    
    flyBodyVelocity = Instance.new("BodyVelocity")
    flyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
    flyBodyVelocity.Parent = rootPart
    
    flyBodyGyro = Instance.new("BodyGyro")
    flyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    flyBodyGyro.D = 100
    flyBodyGyro.P = 9000
    flyBodyGyro.Parent = rootPart
    
    flyAntiFallConnection = RunService.RenderStepped:Connect(function()
        if not flyEnabled then return end
        
        local currentChar = LocalPlayer.Character
        if not currentChar or not currentChar:FindFirstChild("HumanoidRootPart") then return end
        
        local currentRoot = currentChar:FindFirstChild("HumanoidRootPart")
        local currentHumanoid = currentChar:FindFirstChildOfClass("Humanoid")
        
        if not currentHumanoid or not currentRoot then return end
        
        if not currentHumanoid.PlatformStand then
            currentHumanoid.PlatformStand = true
        end
        
        if not flyBodyVelocity or not flyBodyVelocity.Parent then
            flyBodyVelocity = Instance.new("BodyVelocity")
            flyBodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
            flyBodyVelocity.Velocity = Vector3.new(0, 0, 0)
            flyBodyVelocity.Parent = currentRoot
        end
        
        if not flyBodyGyro or not flyBodyGyro.Parent then
            flyBodyGyro = Instance.new("BodyGyro")
            flyBodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
            flyBodyGyro.D = 100
            flyBodyGyro.P = 9000
            flyBodyGyro.Parent = currentRoot
        end
    end)
    
    flyConnection = RunService.RenderStepped:Connect(function()
        if not flyEnabled then return end
        
        local currentChar = LocalPlayer.Character
        if not currentChar or not currentChar:FindFirstChild("HumanoidRootPart") then return end
        
        local currentRoot = currentChar:FindFirstChild("HumanoidRootPart")
        
        local camera = Workspace.CurrentCamera
        if camera and flyBodyGyro then
            flyBodyGyro.CFrame = camera.CFrame
        end
        
        local moveDirection = Vector3.new(0, 0, 0)
        
        if camera then
            local cameraCFrame = camera.CFrame
            if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveDirection = moveDirection + cameraCFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveDirection = moveDirection - cameraCFrame.LookVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveDirection = moveDirection - cameraCFrame.RightVector end
            if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveDirection = moveDirection + cameraCFrame.RightVector end
        end
        
        if UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveDirection = moveDirection + Vector3.new(0, 1, 0) end
        if UserInputService:IsKeyDown(Enum.KeyCode.LeftShift) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then
            moveDirection = moveDirection - Vector3.new(0, 1, 0)
        end
        
        if moveDirection.Magnitude > 0 then
            moveDirection = moveDirection.Unit
        end
        
        if flyBodyVelocity then
            flyBodyVelocity.Velocity = moveDirection * flySpeed
        end
    end)
end

local function stopFly()
    if flyConnection then flyConnection:Disconnect() flyConnection = nil end
    if flyAntiFallConnection then flyAntiFallConnection:Disconnect() flyAntiFallConnection = nil end
    if flyBodyVelocity then flyBodyVelocity:Destroy() flyBodyVelocity = nil end
    if flyBodyGyro then flyBodyGyro:Destroy() flyBodyGyro = nil end
    
    local character = LocalPlayer.Character
    if character then
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
            humanoid.AutoRotate = true
        end
        if character:FindFirstChild("HumanoidRootPart") then
            character:FindFirstChild("HumanoidRootPart").Velocity = Vector3.new(0, 0, 0)
        end
    end
end

-- ========================== ПОЛЕТ К ОСТРОВУ ==========================
local function stopFlyToIsland()
    flyingToIsland = false
    
    if flyToIslandConnection then
        flyToIslandConnection:Disconnect()
        flyToIslandConnection = nil
    end
    
    local character = LocalPlayer.Character
    if character then
        local rootPart = character:FindFirstChild("HumanoidRootPart")
        if rootPart then
            for _, child in ipairs(rootPart:GetChildren()) do
                if child:IsA("BodyVelocity") or child:IsA("BodyGyro") then
                    child:Destroy()
                end
            end
            rootPart.Velocity = Vector3.new(0, 0, 0)
        end
        
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
            humanoid.PlatformStand = false
            humanoid.AutoRotate = true
        end
    end
end

local function flyToPosition(targetPosition, islandName)
    if not targetPosition then return end
    
    local character = LocalPlayer.Character
    if not character or not character:FindFirstChild("HumanoidRootPart") then return end
    
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local rootPart = character:FindFirstChild("HumanoidRootPart")
    
    if not humanoid or not rootPart then return end
    
    if flyToIslandConnection then
        flyToIslandConnection:Disconnect()
        flyToIslandConnection = nil
    end
    
    if flyEnabled then
        stopFly()
        flyEnabled = false
    end
    
    flyingToIsland = true
    
    humanoid.PlatformStand = true
    humanoid.AutoRotate = false
    
    for _, child in ipairs(rootPart:GetChildren()) do
        if child:IsA("BodyVelocity") or child:IsA("BodyGyro") then
            child:Destroy()
        end
    end
    
    local bodyVelocity = Instance.new("BodyVelocity")
    bodyVelocity.MaxForce = Vector3.new(math.huge, math.huge, math.huge)
    bodyVelocity.Velocity = Vector3.new(0, 0, 0)
    bodyVelocity.Parent = rootPart
    
    local bodyGyro = Instance.new("BodyGyro")
    bodyGyro.MaxTorque = Vector3.new(math.huge, math.huge, math.huge)
    bodyGyro.D = 100
    bodyGyro.P = 9000
    bodyGyro.Parent = rootPart
    
    local flySpeedToIsland = 240
    local stopDistance = 10
    local flyHeight = 100
    local descendDistance = 150
    local lastPosition = rootPart.Position
    local stuckTime = 0
    local maxStuckTime = 2
    
    flyToIslandConnection = RunService.RenderStepped:Connect(function()
        if not flyingToIsland then return end
        
        local currentChar = LocalPlayer.Character
        if not currentChar or not currentChar:FindFirstChild("HumanoidRootPart") then
            stopFlyToIsland()
            return
        end
        
        local currentRoot = currentChar:FindFirstChild("HumanoidRootPart")
        
        if not currentRoot then
            stopFlyToIsland()
            return
        end
        
        local currentPosition = currentRoot.Position
        
        local deltaX = targetPosition.X - currentPosition.X
        local deltaZ = targetPosition.Z - currentPosition.Z
        local distanceXZ = math.sqrt(deltaX * deltaX + deltaZ * deltaZ)
        
        local targetHeight
        
        if distanceXZ > descendDistance then
            targetHeight = targetPosition.Y + flyHeight
        else
            targetHeight = targetPosition.Y + 5
        end
        
        local movementDelta = (currentPosition - lastPosition).Magnitude
        
        if movementDelta < 1 then
            stuckTime = stuckTime + 1/60
        else
            stuckTime = 0
        end
        
        lastPosition = currentPosition
        
        if distanceXZ <= stopDistance or stuckTime >= maxStuckTime then
            stopFlyToIsland()
            
            local char = LocalPlayer.Character
            if char then
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hum then
                    hum.PlatformStand = false
                    hum.AutoRotate = true
                end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Velocity = Vector3.new(0, 0, 0)
                end
            end
            
            print("Прилетели: " .. islandName)
            return
        end
        
        local deltaY = targetHeight - currentPosition.Y
        
        local moveDirection
        
        if distanceXZ > descendDistance then
            local horizontalDir = Vector3.new(deltaX, 0, deltaZ).Unit
            local verticalComponent = math.clamp(deltaY / 20, -1, 1)
            moveDirection = (horizontalDir + Vector3.new(0, verticalComponent * 0.3, 0)).Unit
        else
            local horizontalDir = Vector3.new(deltaX, 0, deltaZ).Unit
            local verticalComponent = deltaY / math.max(math.abs(deltaY), 1)
            moveDirection = (horizontalDir + Vector3.new(0, verticalComponent * 0.3, 0)).Unit
        end
        
        bodyVelocity.Velocity = moveDirection * flySpeedToIsland
        
        if moveDirection.Magnitude > 0.1 then
            bodyGyro.CFrame = CFrame.lookAt(currentPosition, currentPosition + moveDirection)
        end
    end)
    
    print("Летим: " .. islandName)
end

-- ========================== СОЗДАНИЕ МЕНЮ ==========================
local function createGradient(parent, color1, color2)
    local gradient = Instance.new("UIGradient")
    gradient.Color = ColorSequence.new{
        ColorSequenceKeypoint.new(0, color1),
        ColorSequenceKeypoint.new(1, color2)
    }
    gradient.Rotation = 0
    gradient.Parent = parent
    return gradient
end

local function createToggle(parent, position, text, defaultState, callback)
    local toggleFrame = Instance.new("Frame")
    toggleFrame.Size = UDim2.new(1, -40, 0, 40)
    toggleFrame.Position = position
    toggleFrame.BackgroundColor3 = DarkBackground
    toggleFrame.BorderSizePixel = 0
    toggleFrame.Parent = parent
    
    local toggleCorner = Instance.new("UICorner")
    toggleCorner.CornerRadius = UDim.new(0, 10)
    toggleCorner.Parent = toggleFrame
    
    local toggleLabel = Instance.new("TextLabel")
    toggleLabel.Size = UDim2.new(0.7, 0, 1, 0)
    toggleLabel.Position = UDim2.new(0, 10, 0, 0)
    toggleLabel.BackgroundTransparency = 1
    toggleLabel.Text = text
    toggleLabel.TextColor3 = WhiteText
    toggleLabel.Font = Enum.Font.Gotham
    toggleLabel.TextSize = 13
    toggleLabel.TextXAlignment = Enum.TextXAlignment.Left
    toggleLabel.Parent = toggleFrame
    
    local switchButton = Instance.new("TextButton")
    switchButton.Size = UDim2.new(0, 50, 0, 25)
    switchButton.Position = UDim2.new(1, -60, 0.5, -12)
    switchButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
    switchButton.BorderSizePixel = 0
    switchButton.Text = ""
    switchButton.AutoButtonColor = false
    switchButton.Parent = toggleFrame
    
    local switchCorner = Instance.new("UICorner")
    switchCorner.CornerRadius = UDim.new(1, 0)
    switchCorner.Parent = switchButton
    
    local switchKnob = Instance.new("Frame")
    switchKnob.Size = UDim2.new(0, 20, 0, 20)
    switchKnob.Position = UDim2.new(0, 2, 0.5, -10)
    switchKnob.BackgroundColor3 = WhiteText
    switchKnob.BorderSizePixel = 0
    switchKnob.Parent = switchButton
    
    local switchKnobCorner = Instance.new("UICorner")
    switchKnobCorner.CornerRadius = UDim.new(1, 0)
    switchKnobCorner.Parent = switchKnob
    
    local isOn = defaultState or false
    
    local function updateVisual()
        if isOn then
            switchButton.BackgroundColor3 = NeonPurple
            switchKnob.Position = UDim2.new(1, -22, 0.5, -10)
        else
            switchButton.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
            switchKnob.Position = UDim2.new(0, 2, 0.5, -10)
        end
    end
    
    switchButton.MouseButton1Click:Connect(function()
        isOn = not isOn
        updateVisual()
        if callback then callback(isOn) end
    end)
    
    updateVisual()
    
    return {
        SetState = function(state) isOn = state updateVisual() end,
        GetState = function() return isOn end
    }
end

-- Создание ScreenGui
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ShotHubMenu"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui")

local MainFrame = Instance.new("Frame")
MainFrame.Size = UDim2.new(0, 550, 0, 500)
MainFrame.Position = UDim2.new(0.5, -275, 0.5, -250)
MainFrame.BackgroundColor3 = DarkBackground
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false
MainFrame.Parent = ScreenGui

local MainCorner = Instance.new("UICorner")
MainCorner.CornerRadius = UDim.new(0, 15)
MainCorner.Parent = MainFrame

local Header = Instance.new("TextButton")
Header.Size = UDim2.new(1, 0, 0, 50)
Header.BackgroundColor3 = DarkerBackground
Header.BorderSizePixel = 0
Header.Text = ""
Header.AutoButtonColor = false
Header.Parent = MainFrame

local HeaderCorner = Instance.new("UICorner")
HeaderCorner.CornerRadius = UDim.new(0, 15)
HeaderCorner.Parent = Header

createGradient(Header, ElectricBlue, NeonPurple)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Size = UDim2.new(0, 200, 1, 0)
TitleLabel.Position = UDim2.new(0, 15, 0, 0)
TitleLabel.BackgroundTransparency = 1
TitleLabel.Text = "SHOT HUB"
TitleLabel.TextColor3 = WhiteText
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.TextSize = 18
TitleLabel.TextXAlignment = Enum.TextXAlignment.Left
TitleLabel.Parent = Header

local CloseButton = Instance.new("TextButton")
CloseButton.Size = UDim2.new(0, 30, 0, 30)
CloseButton.Position = UDim2.new(1, -35, 0, 10)
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
CloseButton.BorderSizePixel = 0
CloseButton.Text = "X"
CloseButton.TextColor3 = WhiteText
CloseButton.Font = Enum.Font.GothamBold
CloseButton.TextSize = 14
CloseButton.Parent = Header

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseButton

local TabBar = Instance.new("Frame")
TabBar.Size = UDim2.new(1, 0, 0, 40)
TabBar.Position = UDim2.new(0, 0, 0, 50)
TabBar.BackgroundColor3 = DarkerBackground
TabBar.BorderSizePixel = 0
TabBar.Parent = MainFrame

local tabs = {
    {name = "Home", icon = "🏠"},
    {name = "ESP", icon = "👁️"},
    {name = "Teleport", icon = "📍"},
    {name = "Fly", icon = "✈️"},
    {name = "Farm", icon = "⚔️"},
    {name = "Debug", icon = "🔧"}
}

local tabButtons = {}
local tabPages = {}

for i, tab in ipairs(tabs) do
    local tabButton = Instance.new("TextButton")
    tabButton.Size = UDim2.new(0, 85, 1, 0)
    tabButton.Position = UDim2.new(0, (i-1) * 85, 0, 0)
    tabButton.BackgroundTransparency = 1
    tabButton.Text = tab.icon .. " " .. tab.name
    tabButton.TextColor3 = WhiteText
    tabButton.Font = Enum.Font.Gotham
    tabButton.TextSize = 11
    tabButton.Parent = TabBar
    tabButtons[tab.name] = tabButton
end

local ActiveLine = Instance.new("Frame")
ActiveLine.Size = UDim2.new(0, 85, 0, 3)
ActiveLine.Position = UDim2.new(0, 0, 1, -3)
ActiveLine.BackgroundColor3 = NeonPurple
ActiveLine.BorderSizePixel = 0
ActiveLine.Parent = TabBar

local ContentArea = Instance.new("Frame")
ContentArea.Size = UDim2.new(1, 0, 1, -90)
ContentArea.Position = UDim2.new(0, 0, 0, 90)
ContentArea.BackgroundTransparency = 1
ContentArea.Parent = MainFrame

local function createPage(pageName)
    local page = Instance.new("Frame")
    page.Size = UDim2.new(1, 0, 1, 0)
    page.BackgroundTransparency = 1
    page.Visible = false
    page.Parent = ContentArea
    tabPages[pageName] = page
    return page
end

-- Home Page
local homePage = createPage("Home")

local LeftColumn = Instance.new("Frame")
LeftColumn.Size = UDim2.new(0.48, 0, 1, -20)
LeftColumn.Position = UDim2.new(0.01, 0, 0, 10)
LeftColumn.BackgroundColor3 = DarkerBackground
LeftColumn.BorderSizePixel = 0
LeftColumn.Parent = homePage

local LeftCorner = Instance.new("UICorner")
LeftCorner.CornerRadius = UDim.new(0, 12)
LeftCorner.Parent = LeftColumn

local LeftTitle = Instance.new("TextLabel")
LeftTitle.Size = UDim2.new(1, 0, 0, 40)
LeftTitle.BackgroundTransparency = 1
LeftTitle.Text = "Main"
LeftTitle.TextColor3 = WhiteText
LeftTitle.Font = Enum.Font.GothamBold
LeftTitle.TextSize = 15
LeftTitle.Parent = LeftColumn

local LeftLine = Instance.new("Frame")
LeftLine.Size = UDim2.new(1, -40, 0, 2)
LeftLine.Position = UDim2.new(0, 20, 0, 40)
LeftLine.BorderSizePixel = 0
LeftLine.Parent = LeftColumn
createGradient(LeftLine, ElectricBlue, NeonPurple)

local toggleESP = createToggle(LeftColumn, UDim2.new(0, 20, 0, 50), "ESP Fruit Tools", false, function(state)
    espEnabled = state
    if state then scanForFruitTools() else clearAllESP() end
end)

local toggleFly = createToggle(LeftColumn, UDim2.new(0, 20, 0, 100), "Fly Mode", false, function(state)
    flyEnabled = state
    if state then startFly() else stopFly() end
end)

local TeleportButton = Instance.new("TextButton")
TeleportButton.Size = UDim2.new(1, -40, 0, 40)
TeleportButton.Position = UDim2.new(0, 20, 0, 150)
TeleportButton.BackgroundColor3 = NeonPurple
TeleportButton.BorderSizePixel = 0
TeleportButton.Text = "Teleport to Fruit"
TeleportButton.TextColor3 = WhiteText
TeleportButton.Font = Enum.Font.GothamBold
TeleportButton.TextSize = 13
TeleportButton.Parent = LeftColumn

local TeleportCorner = Instance.new("UICorner")
TeleportCorner.CornerRadius = UDim.new(0, 10)
TeleportCorner.Parent = TeleportButton
createGradient(TeleportButton, ElectricBlue, NeonPurple)

TeleportButton.MouseButton1Click:Connect(function() teleportToNearestFruit() end)

-- Right Column
local RightColumn = Instance.new("Frame")
RightColumn.Size = UDim2.new(0.48, 0, 1, -20)
RightColumn.Position = UDim2.new(0.51, 0, 0, 10)
RightColumn.BackgroundColor3 = DarkerBackground
RightColumn.BorderSizePixel = 0
RightColumn.Parent = homePage

local RightCorner = Instance.new("UICorner")
RightCorner.CornerRadius = UDim.new(0, 12)
RightCorner.Parent = RightColumn

local RightTitle = Instance.new("TextLabel")
RightTitle.Size = UDim2.new(1, 0, 0, 40)
RightTitle.BackgroundTransparency = 1
RightTitle.Text = "Fly Settings"
RightTitle.TextColor3 = WhiteText
RightTitle.Font = Enum.Font.GothamBold
RightTitle.TextSize = 15
RightTitle.Parent = RightColumn

local RightLine = Instance.new("Frame")
RightLine.Size = UDim2.new(1, -40, 0, 2)
RightLine.Position = UDim2.new(0, 20, 0, 40)
RightLine.BorderSizePixel = 0
RightLine.Parent = RightColumn
createGradient(RightLine, ElectricBlue, NeonPurple)

local SpeedLabel = Instance.new("TextLabel")
SpeedLabel.Size = UDim2.new(1, -40, 0, 25)
SpeedLabel.Position = UDim2.new(0, 20, 0, 50)
SpeedLabel.BackgroundTransparency = 1
SpeedLabel.Text = "Speed: " .. flySpeed
SpeedLabel.TextColor3 = WhiteText
SpeedLabel.Font = Enum.Font.GothamBold
SpeedLabel.TextSize = 14
SpeedLabel.TextXAlignment = Enum.TextXAlignment.Left
SpeedLabel.Parent = RightColumn

local SliderFrame = Instance.new("TextButton")
SliderFrame.Size = UDim2.new(1, -40, 0, 20)
SliderFrame.Position = UDim2.new(0, 20, 0, 80)
SliderFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
SliderFrame.BorderSizePixel = 0
SliderFrame.Text = ""
SliderFrame.AutoButtonColor = false
SliderFrame.Parent = RightColumn

local SliderCorner = Instance.new("UICorner")
SliderCorner.CornerRadius = UDim.new(1, 0)
SliderCorner.Parent = SliderFrame

local SliderFill = Instance.new("Frame")
SliderFill.Size = UDim2.new(flySpeed / 300, 0, 1, 0)
SliderFill.BackgroundColor3 = NeonPurple
SliderFill.BorderSizePixel = 0
SliderFill.Parent = SliderFrame

local SliderFillCorner = Instance.new("UICorner")
SliderFillCorner.CornerRadius = UDim.new(1, 0)
SliderFillCorner.Parent = SliderFill
createGradient(SliderFill, ElectricBlue, NeonPurple)

local SliderKnob = Instance.new("Frame")
SliderKnob.Size = UDim2.new(0, 20, 0, 20)
SliderKnob.Position = UDim2.new(flySpeed / 300, -10, 0.5, -10)
SliderKnob.BackgroundColor3 = WhiteText
SliderKnob.BorderSizePixel = 0
SliderKnob.Parent = SliderFrame

local SliderKnobCorner = Instance.new("UICorner")
SliderKnobCorner.CornerRadius = UDim.new(1, 0)
SliderKnobCorner.Parent = SliderKnob

local function updateSlider()
    local mousePos = UserInputService:GetMouseLocation()
    local sliderPos = SliderFrame.AbsolutePosition
    local sliderSize = SliderFrame.AbsoluteSize
    local relativeX = math.clamp((mousePos.X - sliderPos.X) / sliderSize.X, 0, 1)
    flySpeed = math.floor(relativeX * 300)
    SliderFill.Size = UDim2.new(relativeX, 0, 1, 0)
    SliderKnob.Position = UDim2.new(relativeX, -10, 0.5, -10)
    SpeedLabel.Text = "Speed: " .. flySpeed
end

SliderFrame.MouseButton1Down:Connect(function()
    isDraggingSlider = true
    updateSlider()
end)

-- ESP Page
local espPage = createPage("ESP")
local toggleESP2 = createToggle(espPage, UDim2.new(0, 20, 0, 60), "ESP Fruit Tools", false, function(state)
    espEnabled = state
    if state then scanForFruitTools() toggleESP.SetState(true) else clearAllESP() toggleESP.SetState(false) end
end)

-- Teleport Page
local teleportPage = createPage("Teleport")

local IslandDropdown = Instance.new("TextButton")
IslandDropdown.Size = UDim2.new(1, -40, 0, 40)
IslandDropdown.Position = UDim2.new(0, 20, 0, 60)
IslandDropdown.BackgroundColor3 = DarkBackground
IslandDropdown.BorderSizePixel = 0
IslandDropdown.Text = "Select Island"
IslandDropdown.TextColor3 = WhiteText
IslandDropdown.Font = Enum.Font.Gotham
IslandDropdown.TextSize = 14
IslandDropdown.TextXAlignment = Enum.TextXAlignment.Left
IslandDropdown.Parent = teleportPage

local IslandCorner = Instance.new("UICorner")
IslandCorner.CornerRadius = UDim.new(0, 8)
IslandCorner.Parent = IslandDropdown

local IslandList = Instance.new("ScrollingFrame")
IslandList.Size = UDim2.new(1, -40, 0, 200)
IslandList.Position = UDim2.new(0, 20, 0, 105)
IslandList.BackgroundColor3 = DarkBackground
IslandList.BorderSizePixel = 0
IslandList.Visible = false
IslandList.CanvasSize = UDim2.new(0, 0, 0, 0)
IslandList.ScrollBarThickness = 4
IslandList.ScrollBarImageColor3 = NeonPurple
IslandList.Parent = teleportPage

local FlyToIslandButton = Instance.new("TextButton")
FlyToIslandButton.Size = UDim2.new(1, -40, 0, 40)
FlyToIslandButton.Position = UDim2.new(0, 20, 0, 315)
FlyToIslandButton.BackgroundColor3 = NeonPurple
FlyToIslandButton.BorderSizePixel = 0
FlyToIslandButton.Text = "Fly to Island"
FlyToIslandButton.TextColor3 = WhiteText
FlyToIslandButton.Font = Enum.Font.GothamBold
FlyToIslandButton.TextSize = 14
FlyToIslandButton.Parent = teleportPage

createGradient(FlyToIslandButton, ElectricBlue, NeonPurple)

local function updateIslandList()
    for _, child in ipairs(IslandList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    local yPos = 0
    for _, island in ipairs(Sea1Islands) do
        local islandButton = Instance.new("TextButton")
        islandButton.Size = UDim2.new(1, -10, 0, 35)
        islandButton.Position = UDim2.new(0, 5, 0, yPos)
        islandButton.BackgroundColor3 = DarkerBackground
        islandButton.BorderSizePixel = 0
        islandButton.Text = island.name
        islandButton.TextColor3 = WhiteText
        islandButton.Font = Enum.Font.Gotham
        islandButton.TextSize = 13
        islandButton.Parent = IslandList
        
        islandButton.MouseButton1Click:Connect(function()
            selectedIsland = island
            IslandDropdown.Text = island.name
            IslandList.Visible = false
        end)
        
        yPos = yPos + 40
    end
    IslandList.CanvasSize = UDim2.new(0, 0, 0, yPos)
end

IslandDropdown.MouseButton1Click:Connect(function()
    islandDropdownOpen = not islandDropdownOpen
    IslandList.Visible = islandDropdownOpen
    if islandDropdownOpen then updateIslandList() end
end)

FlyToIslandButton.MouseButton1Click:Connect(function()
    if selectedIsland then
        flyToPosition(selectedIsland.position, selectedIsland.name)
    end
end)

-- Farm Page
local farmPage = createPage("Farm")

local FarmTitle = Instance.new("TextLabel")
FarmTitle.Size = UDim2.new(1, -40, 0, 30)
FarmTitle.Position = UDim2.new(0, 20, 0, 60)
FarmTitle.BackgroundTransparency = 1
FarmTitle.Text = "Auto Farm"
FarmTitle.TextColor3 = WhiteText
FarmTitle.Font = Enum.Font.GothamBold
FarmTitle.TextSize = 15
FarmTitle.TextXAlignment = Enum.TextXAlignment.Left
FarmTitle.Parent = farmPage

local MobDropdown = Instance.new("TextButton")
MobDropdown.Size = UDim2.new(1, -40, 0, 40)
MobDropdown.Position = UDim2.new(0, 20, 0, 100)
MobDropdown.BackgroundColor3 = DarkBackground
MobDropdown.BorderSizePixel = 0
MobDropdown.Text = "Select Mob"
MobDropdown.TextColor3 = WhiteText
MobDropdown.Font = Enum.Font.Gotham
MobDropdown.TextSize = 14
MobDropdown.TextXAlignment = Enum.TextXAlignment.Left
MobDropdown.Parent = farmPage

local MobCorner = Instance.new("UICorner")
MobCorner.CornerRadius = UDim.new(0, 8)
MobCorner.Parent = MobDropdown

local MobList = Instance.new("ScrollingFrame")
MobList.Size = UDim2.new(1, -40, 0, 150)
MobList.Position = UDim2.new(0, 20, 0, 145)
MobList.BackgroundColor3 = DarkBackground
MobList.BorderSizePixel = 0
MobList.Visible = false
MobList.CanvasSize = UDim2.new(0, 0, 0, 0)
MobList.ScrollBarThickness = 4
MobList.ScrollBarImageColor3 = NeonPurple
MobList.Parent = farmPage

local FarmToggle = createToggle(farmPage, UDim2.new(0, 20, 0, 305), "Auto Farm", false, function(state)
    farmEnabled = state
    if state and selectedFarmMob then
        startFarm(selectedFarmMob)
    else
        stopFarm()
    end
end)

local function updateMobList()
    for _, child in ipairs(MobList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    local yPos = 0
    for _, mobName in ipairs(Sea1Mobs) do
        local mobButton = Instance.new("TextButton")
        mobButton.Size = UDim2.new(1, -10, 0, 35)
        mobButton.Position = UDim2.new(0, 5, 0, yPos)
        mobButton.BackgroundColor3 = DarkerBackground
        mobButton.BorderSizePixel = 0
        mobButton.Text = mobName
        mobButton.TextColor3 = WhiteText
        mobButton.Font = Enum.Font.Gotham
        mobButton.TextSize = 13
        mobButton.Parent = MobList
        
        mobButton.MouseButton1Click:Connect(function()
            selectedFarmMob = mobName
            MobDropdown.Text = mobName
            MobList.Visible = false
        end)
        
        yPos = yPos + 40
    end
    MobList.CanvasSize = UDim2.new(0, 0, 0, yPos)
end

MobDropdown.MouseButton1Click:Connect(function()
    farmMobDropdownOpen = not farmMobDropdownOpen
    MobList.Visible = farmMobDropdownOpen
    if farmMobDropdownOpen then updateMobList() end
end)

-- Debug Page
local debugPage = createPage("Debug")

local SeaLabel = Instance.new("TextLabel")
SeaLabel.Size = UDim2.new(1, -40, 0, 30)
SeaLabel.Position = UDim2.new(0, 20, 0, 60)
SeaLabel.BackgroundColor3 = DarkBackground
SeaLabel.BorderSizePixel = 0
SeaLabel.Text = "Sea: " .. getCurrentSea()
SeaLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
SeaLabel.Font = Enum.Font.GothamBold
SeaLabel.TextSize = 14
SeaLabel.TextXAlignment = Enum.TextXAlignment.Left
SeaLabel.Parent = debugPage

local CoordLabel = Instance.new("TextLabel")
CoordLabel.Size = UDim2.new(1, -40, 0, 30)
CoordLabel.Position = UDim2.new(0, 20, 0, 100)
CoordLabel.BackgroundColor3 = DarkBackground
CoordLabel.BorderSizePixel = 0
CoordLabel.Text = "Pos: "
CoordLabel.TextColor3 = WhiteText
CoordLabel.Font = Enum.Font.Gotham
CoordLabel.TextSize = 14
CoordLabel.TextXAlignment = Enum.TextXAlignment.Left
CoordLabel.Parent = debugPage

local function updateDebugInfo()
    if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        local pos = LocalPlayer.Character.HumanoidRootPart.Position
        CoordLabel.Text = string.format("X: %.1f | Y: %.1f | Z: %.1f", pos.X, pos.Y, pos.Z)
    end
    SeaLabel.Text = "Sea: " .. getCurrentSea()
end

-- ========================== DRAG ==========================
local dragging = false
local dragStartPos = nil
local frameStartPos = nil

Header.MouseButton1Down:Connect(function()
    dragging = true
    dragStartPos = UserInputService:GetMouseLocation()
    frameStartPos = MainFrame.Position
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = UserInputService:GetMouseLocation() - dragStartPos
        MainFrame.Position = UDim2.new(frameStartPos.X.Scale, frameStartPos.X.Offset + delta.X, frameStartPos.Y.Scale, frameStartPos.Y.Offset + delta.Y)
    end
    if isDraggingSlider and input.UserInputType == Enum.UserInputType.MouseMovement then
        updateSlider()
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
        isDraggingSlider = false
    end
end)

-- ========================== SHOW/HIDE ==========================
local function showMenu() menuVisible = true MainFrame.Visible = true end
local function hideMenu() menuVisible = false MainFrame.Visible = false end

CloseButton.MouseButton1Click:Connect(hideMenu)

local function switchTab(tabName)
    selectedTab = tabName
    for name, page in pairs(tabPages) do page.Visible = (name == tabName) end
    for name, btn in pairs(tabButtons) do
        btn.TextColor3 = (name == tabName) and WhiteText or Color3.fromRGB(150, 150, 160)
    end
    if tabName == "Debug" then updateDebugInfo() end
end

for tabName, tabButton in pairs(tabButtons) do
    tabButton.MouseButton1Click:Connect(function() switchTab(tabName) end)
end

switchTab("Home")

task.spawn(function()
    while true do
        if menuVisible and selectedTab == "Debug" then updateDebugInfo() end
        task.wait(0.1)
    end
end)

-- ========================== KEYS ==========================
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    
    if input.KeyCode == Enum.KeyCode.F then
        if menuVisible then hideMenu() else showMenu() end
    end
    
    if input.KeyCode == Enum.KeyCode.E then
        espEnabled = not espEnabled
        if espEnabled then scanForFruitTools() toggleESP.SetState(true) toggleESP2.SetState(true)
        else clearAllESP() toggleESP.SetState(false) toggleESP2.SetState(false) end
    end
    
    if input.KeyCode == Enum.KeyCode.V then
        flyEnabled = not flyEnabled
        if flyEnabled then startFly() toggleFly.SetState(true) else stopFly() toggleFly.SetState(false) end
    end
    
    if input.KeyCode == Enum.KeyCode.T then teleportToNearestFruit() end
end)

-- ========================== HANDLERS ==========================
Workspace.DescendantAdded:Connect(function(descendant)
    if espEnabled and descendant:IsA("Tool") and hasFruitInName(descendant) then
        task.wait(0.5)
        createToolESP(descendant)
    end
end)

Workspace.DescendantRemoving:Connect(function(descendant)
    if descendant:IsA("Tool") then removeToolESP(descendant) end
end)

LocalPlayer.CharacterAdded:Connect(function()
    if flyEnabled then stopFly() flyEnabled = false end
    if flyingToIsland then stopFlyToIsland() end
    if farmEnabled then stopFarm() farmEnabled = false end
end)

print("SHOT HUB loaded!")
print("Текущее море: " .. getCurrentSea())
