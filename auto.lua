-- -- GlassScripts/Soccer_Fullscreen_Blackout_Final.lua
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local LocalPlayer = Players.LocalPlayer

-- ====================================================================
-- ГЛОБАЛЬНЫЕ ФЛАГИ И ТАБЛИЦЫ ДАННЫХ
-- ====================================================================
_G.AutoPerfectPowerActive = true
getgenv().AutoYeetOrbsActive = true
_G.AutoHatchEnabled = true

_G.SoccerStats = {
    CurrentAction = "Hatching: Soccer Egg 5 Tier 1",
    TimeStarted = os.time(),
    Coins = "0",
    Orbs = "0",
    Gems = "0",
    GemsMin = "0",
    Distance = "0.00M",
    HatchedCount = 0,
    -- Цели со скрина
    G = 0,
    H1 = 0,
    H2 = 0,
    TT = 0,
    Garg = 0
}

-- Изначальные координаты яйца из твоих условий
local eggCFrame = CFrame.new(1425.66479, 20.2455292, -32063.8008, -0.975344896, -4.26336797e-08, -0.220685989, -4.37113883e-08, 1, 0, 0.220685989, 9.64649072e-09, -0.975344896)
local LocalPlayer = game:GetService("Players").LocalPlayer

local function getSoccerUiData()
    local data = {G = 0, H1 = 0, H2 = 0, TT = 0, Garg = 0, Distance = "0.00M studs"}
    local playerGui = LocalPlayer:FindFirstChild("PlayerGui")
    if not playerGui then return data end

    for _, gui in pairs(playerGui:GetDescendants()) do
        if gui:IsA("TextLabel") and gui.Visible then
            local text = gui.Text
            
            -- Парсинг целей (например, "8/10 points")
            if text:find("/10") or text:find("points") then
                local parent = gui.Parent
                if parent then
                    local parentName = parent.Name:lower()
                    local currentPoints = tonumber(text:match("(%d+)/")) or tonumber(text:match("(%d+)")) or 0
                    
                    if parentName == "gift" then data.G = currentPoints
                    elseif parentName == "huge1" or parentName:find("zebra") then data.H1 = currentPoints
                    elseif parentName == "huge2" then data.H2 = currentPoints
                    elseif parentName == "titanic" then data.TT = currentPoints
                    elseif parentName == "gargantuan" or parentName:find("giant") or parentName:find("garg") then data.Garg = currentPoints
                    end
                end
            end

            -- Парсинг силы/дистанции последнего удара (например, "8.3m" или "2.32M studs")
            if text:find("m$") or text:find(" studs") then
                local distMatch = text:match("([%d%.]+)")
                if distMatch and (gui.Parent.Name:find("Сила") or gui.Parent.Name:find("Power") or gui.Parent.Name:lower():find("base")) then
                    data.Distance = distMatch .. "M studs"
                end
            end
        end
    end
    return data
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function getCurrencyData()
    local currency = {Gems = "0", Coins = "0"}
    
    pcall(function()
        local saveModule = require(ReplicatedStorage.Library.Client.Save)
        if saveModule and saveModule.Get then
            local inventory = saveModule.Get()
            if inventory and inventory.Inventory and inventory.Inventory.Currency then
                -- Алмазы (Diamonds)
                if inventory.Inventory.Currency["Diamonds"] then
                    local diamonds = inventory.Inventory.Currency["Diamonds"]._am or 0
                    currency.Gems = string.format("%.2fM", diamonds / 1000000)
                end
                -- Футбольные монеты (Soccer Coins)
                if inventory.Inventory.Currency["Soccer Coins"] then
                    local sCoins = inventory.Inventory.Currency["Soccer Coins"]._am or 0
                    currency.Coins = string.format("%.1fB", sCoins / 1000000000)
                end
            end
        end
    end)
    return currency
end

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local totalHatchedCount = 0 -- Ваша переменная для UI счетчика

local originalHatch = ReplicatedStorage.Network.CustomEggs_Hatch
local oldInvoke = originalHatch.InvokeServer

hookfunction(originalHatch.InvokeServer, function(self, ...)
    local args = {...}
    -- args[1] - это имя яйца, args[2] - это количество (maxAmount)
    if args and args[2] then
        local amount = tonumber(args[2]) or 1
        totalHatchedCount = totalHatchedCount + amount
    end
    return oldInvoke(self, ...)
end)

-- Теперь при каждой отправке пакета закупки переменная totalHatchedCount будет увеличиваться сама



-- ====================================================================
-- ПОЛНОЭКРАННЫЙ BLACKOUT UI С ОТДЕЛЬНЫМ БЛОКОМ СЧЁТЧИКОВ (БЕЗ СТАДОВ)
-- ИЗОЛИРОВАН В ЧИСТЫЙ ПОТОК ДЛЯ ОБХОДА БЛОКИРОВКИ ROBLOX CAPABILITIES
-- ====================================================================
task.spawn(function() -- СТАРТ ЧИСТОГО ПОТОКА UI
    local CoreGui = game:GetService("CoreGui")

    -- Удаляем старый интерфейс при перезапуске
    if CoreGui:FindFirstChild("GlassHub_PremiumBlackout") then
        CoreGui.GlassHub_PremiumBlackout:Destroy()
    end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "GlassHub_PremiumBlackout"
    ScreenGui.ResetOnSpawn = false
    ScreenGui.Parent = CoreGui

    -- Истинный черный задний фон на весь экран
    local MainBackground = Instance.new("Frame")
    MainBackground.Size = UDim2.new(1, 0, 1, 0)
    MainBackground.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    MainBackground.BorderSizePixel = 0
    MainBackground.Parent = ScreenGui

    -- Маленькая кнопка открытия GUI (появляется только в левом углу, когда UI скрыт)
    local OpenButton = Instance.new("TextButton")
    OpenButton.Size = UDim2.new(0, 110, 0, 35)
    OpenButton.Position = UDim2.new(0, 30, 1, -65)
    OpenButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    OpenButton.Text = "[ Open GUI ]"
    OpenButton.TextColor3 = Color3.fromRGB(46, 204, 113)
    OpenButton.TextSize = 14
    OpenButton.Font = Enum.Font.GothamBold
    OpenButton.Visible = false
    OpenButton.Parent = ScreenGui

    local OpenCorner = Instance.new("UICorner")
    OpenCorner.CornerRadius = UDim.new(0, 6)
    OpenCorner.Parent = OpenButton

    -- ОТДЕЛЬНЫЙ ЦЕНТРАЛЬНЫЙ БЛОК ДЛЯ ВСЕХ СЧЁТЧИКОВ И СТАТИСТИКИ
    local StatsContainer = Instance.new("Frame")
    StatsContainer.Name = "StatsContainer"
    StatsContainer.Size = UDim2.new(0, 750, 0, 0) 
    StatsContainer.AutomaticSize = Enum.AutomaticSize.Y 
    StatsContainer.Position = UDim2.new(0.5, -375, 0.4, 0) 
    StatsContainer.BackgroundTransparency = 1 
    StatsContainer.Parent = MainBackground

    local Layout = Instance.new("UIListLayout")
    Layout.FillDirection = Enum.FillDirection.Vertical
    Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    Layout.VerticalAlignment = Enum.VerticalAlignment.Top 
    Layout.SortOrder = Enum.SortOrder.LayoutOrder
    Layout.Padding = UDim.new(0, 14)
    Layout.Parent = StatsContainer

    -- Функция создания текстовых строк внутри блока статистики
    local function createStatLabel(text, size, font, order)
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(0, 750, 0, size + 14) 
        label.BackgroundTransparency = 1
        label.Text = text
        label.TextColor3 = Color3.fromRGB(255, 255, 255)
        label.TextSize = size
        label.Font = font
        label.TextWrapped = true 
        label.LayoutOrder = order
        label.Parent = StatsContainer
        return label
    end

    -- Наполнение блока согласно структуре с фото
    local ActionLabel = createStatLabel("Hatching: Soccer Egg 5 Tier 1", 30, Enum.Font.GothamBold, 1)

    -- Линия-разделитель внутри блока
    local Separator = Instance.new("Frame")
    Separator.Size = UDim2.new(0, 650, 0, 2)
    Separator.Position = UDim2.new(0.5, -325, 0.5, -145) 
    Separator.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Separator.BorderSizePixel = 0
    Separator.Parent = MainBackground 

    local TimerLabel = createStatLabel("00:00:00", 28, Enum.Font.GothamBold, 3)
    local CurrencyLabel = createStatLabel("", 18, Enum.Font.GothamSemibold, 4)
    local GoalsLabel = createStatLabel("", 18, Enum.Font.GothamSemibold, 5)
    local DistanceLabel = createStatLabel("", 18, Enum.Font.GothamSemibold, 6)
    local HatchedLabel = createStatLabel("", 18, Enum.Font.GothamSemibold, 7)

    -- Нижний футер с Дискордом
    local FooterButton = Instance.new("TextButton")
    FooterButton.Size = UDim2.new(0, 400, 0, 30)
    FooterButton.Position = UDim2.new(0.5, -200, 1, -65)
    FooterButton.BackgroundTransparency = 1
    FooterButton.Text = "Made by Le31zy | gg/9XGYrDeU8D"
    FooterButton.TextColor3 = Color3.fromRGB(130, 130, 130)
    FooterButton.TextSize = 14
    FooterButton.Font = Enum.Font.Gotham
    FooterButton.Parent = MainBackground

    FooterButton.MouseButton1Click:Connect(function()
        if setclipboard then
            setclipboard("https://discord.gg/9XGYrDeU8D")
            FooterButton.Text = "[ Ссылка скопирована в буфер! ]"
            FooterButton.TextColor3 = Color3.fromRGB(46, 204, 113)
            task.wait(2)
            FooterButton.Text = "Made by Le31zy | gg/9XGYrDeU8D"
            FooterButton.TextColor3 = Color3.fromRGB(130, 130, 130)
        end
    end)

    -- Кнопка Hide GUI слева снизу
    local HideButton = Instance.new("TextButton")
    HideButton.Size = UDim2.new(0, 110, 0, 35)
    HideButton.Position = UDim2.new(0, 30, 1, -65)
    HideButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    HideButton.Text = "Hide GUI"
    HideButton.TextColor3 = Color3.fromRGB(255, 255, 255)
    HideButton.TextSize = 14
    HideButton.Font = Enum.Font.GothamBold
    HideButton.Parent = MainBackground

    local HideCorner = Instance.new("UICorner")
    HideCorner.CornerRadius = UDim.new(0, 6)
    HideCorner.Parent = HideButton

    -- Логика переключения видимости интерфейса
    HideButton.MouseButton1Click:Connect(function()
        MainBackground.Visible = false
        OpenButton.Visible = true
    end)

    OpenButton.MouseButton1Click:Connect(function()
        MainBackground.Visible = true
        OpenButton.Visible = false
    end)

    -- Рендер-цикл обновления информации
    local timeStarted = os.time()
    task.spawn(function()
        while true do
            -- 1. Таймер времени работы
            local diff = os.time() - timeStarted
            local hours = math.floor(diff / 3600)
            local minutes = math.floor((diff % 3600) / 60)
            local seconds = diff % 60
            TimerLabel.Text = string.format("%02d:%02d:%02d", hours, minutes, seconds)

            -- 2. Сбор данных из твоих функций
            local uiData = typeof(getSoccerUiData) == "function" and getSoccerUiData() or {G=0, H1=0, H2=0, TT=0, Garg=0, Distance="0.00M studs"}
            local walletData = typeof(getCurrencyData) == "function" and getCurrencyData() or {Gems="0", Coins="0"}
            local totalHatched = totalHatchedCount or 0

            -- 3. Вывод строк в блоки как на скрине
            CurrencyLabel.Text = string.format("SoccerCoins: %s | SoccerOrbs: 1.88K | Gems: %s | Gems/Min: 0", walletData.Coins, walletData.Gems)
            GoalsLabel.Text = string.format("G: %d | H1: %d | H2: %d | TT: %d | Garg: %d", uiData.G, uiData.H1, uiData.H2, uiData.TT, uiData.Garg)
            DistanceLabel.Text = "Kick Stats: Distance " .. uiData.Distance
            HatchedLabel.Text = string.format("Hatched Eggs: %s (+1)", totalHatched)
            
            task.wait(0.5)
        end
    end)
end) -- КОНЕЦ ЧИСТОГО ПОТОКА UI




-- Инициализация глобальных флагов (По умолчанию всё включено)
_G.AutoPerfectPowerActive = true
getgenv().AutoYeetOrbsActive = true
_G.AutoHatchEnabled = true

-- ====================================================================
-- 1. АВТО-ВОЗВРАТ В ИВЕНТ ЧЕРЕЗ СИСЕМНЫЙ ТЕЛЕПОРТ
-- ====================================================================
task.spawn(function()
    while true do
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        
        if hrp then
            -- Проверяем, существует ли папка активного футбольного ивента в контейнере
            local things = Workspace:FindFirstChild("__THINGS")
            local container = things and things:FindFirstChild("__INSTANCE_CONTAINER")
            local active = container and container:FindFirstChild("Active")
            local soccerEventActive = active and active:FindFirstChild("SoccerEvent")
            
            -- Если папки SoccerEvent в контейнере нет (вылетели, сбросило) — активируем телепорт
            if not soccerEventActive then
                local instances = things and things:FindFirstChild("Instances")
                local soccerInstance = instances and instances:FindFirstChild("SoccerEvent")
                local teleportsFolder = soccerInstance and soccerInstance:FindFirstChild("Teleports")
                
                -- Ищем любой доступный парт телепортации внутри этой папки
                local targetTeleport = teleportsFolder and (teleportsFolder:FindFirstChildOfClass("Part") or teleportsFolder:FindFirstChildOfClass("MeshPart") or teleportsFolder:FindFirstChild("Enter") or teleportsFolder:FindFirstChildOfClass("Model"))
                
                if targetTeleport then
                    pcall(function()
                        hrp.CFrame = targetTeleport:GetPivot()
                        print("🚪 [GlassHub]: Обнаружен вылет из ивента! Телепортирую в системный телепорт...")
                    end)
                end
                
                -- Ждем 5 секунд, чтобы игра успела прогрузить зону и перекинуть персонажа
                task.wait(5)
            end
        end
        task.wait(2) -- Проверка каждые 2 секунды
    end
end)

-- Инициализация глобальных флагов (Всё включено)
_G.AutoPerfectPowerActive = true
getgenv().AutoYeetOrbsActive = true
_G.AutoHatchEnabled = true

-- ====================================================================
-- 2. ПОЛНЫЙ ПРОПУСК АНИМАЦИЙ ЯИЦ (EGG SKIP)
-- ====================================================================
-- Выносим Egg Skip в изолированный поток безопасности
task.spawn(function()
    if not getgenv().EggSkipApplied then 
        getgenv().EggSkipApplied = true
        for _, v in pairs(getgc(true)) do
            if type(v) == "table" and rawget(v, "Play") and type(v.Play) == "function" then
                local info = getinfo(v.Play)
                if info.source:find("Egg") or info.source:find("Hatch") then v.Play = function() return end end
            elseif type(v) == "function" then
                local info = getinfo(v)
                if info.name == "PlayEggAnimation" or info.name == "ShowHatch" then hookfunction(v, function() return end) end
            end
        end
        task.spawn(function()
            while task.wait(0.5) do
                local pGui = LocalPlayer:FindFirstChild("PlayerGui")
                if pGui then
                    for _, gui in pairs(pGui:GetChildren()) do
                        if gui:IsA("ScreenGui") and (gui.Name:find("Egg") or gui.Name:find("Hatch") or gui.Name:find("Scene")) then
                            gui:Destroy()
                        end
                    end
                end
            end
        end)
        task.spawn(function()
            local Library = require(ReplicatedStorage:WaitForChild("Library"))
            RunService.RenderStepped:Connect(function()
                if Library.Variables then Library.Variables.OpeningEgg = false end
            end)
        end)
        if LocalPlayer:WaitForChild("PlayerGui"):FindFirstChild("EggOpen") then 
            LocalPlayer.PlayerGui.EggOpen.Enabled = false 
        end
    end
end)


-- ====================================================================
-- 3. АВТО-СБОР ОРБОВ (YEET ORBS)
-- ====================================================================
local orbModule, orbTable = nil, nil

local function initOrbModule()
    local things = Workspace:FindFirstChild("__THINGS")
    local container = things and things:FindFirstChild("__INSTANCE_CONTAINER")
    local active = container and container:FindFirstChild("Active")
    local soccerEvent = active and active:FindFirstChild("SoccerEvent")
    local clientModule = soccerEvent and soccerEvent:FindFirstChild("ClientModule")
    local yeetOrbsScript = clientModule and clientModule:FindFirstChild("YeetOrbs")
    if yeetOrbsScript then
        local success, result = pcall(require, yeetOrbsScript)
        if success and type(result) == "table" then
            orbModule = result
            local targetFunc = result.Claim or result.Init
            if targetFunc then
                for _, upv in pairs(debug.getupvalues(targetFunc)) do
                    if type(upv) == "table" and not upv.Claim and not upv.Init then orbTable = upv break end
                end
            end
        end
    end
end

task.spawn(function()
    while true do
        if getgenv().AutoYeetOrbsActive then
            if not orbModule or not orbTable then initOrbModule() end
            if orbModule and orbTable then
                for uid, orbData in pairs(orbTable) do
                    if not getgenv().AutoYeetOrbsActive then break end
                    if orbData and not orbData.Tweening then pcall(orbModule.Claim, uid) end
                end
            end
        end
        task.wait(0.3)
    end
end)

-- ====================================================================
-- 4. АВТОНОМНЫЙ ПИНАТЕЛЬ НА ДАЛЬНОСТЬ + ОТКЛЮЧЕНИЕ ИГРОВОГО АВТОПИНКА
-- ====================================================================
local lastCheckTime = 0

task.spawn(function()
    local invokeCustom = ReplicatedStorage:WaitForChild("Network"):WaitForChild("Instancing_InvokeCustomFromClient")
    local fireCustom = ReplicatedStorage:WaitForChild("Network"):WaitForChild("Instancing_FireCustomFromClient")
    
    while true do
        if _G.AutoPerfectPowerActive then
            local currentTime = tick()
            
            -- Проверка и принудительное выключение игрового автоброска каждые 15 секунд
            if currentTime - lastCheckTime >= 15 then
                lastCheckTime = currentTime
                pcall(function()
                    fireCustom:FireServer("SoccerEvent", "CF_Set", false)
                    print("⚽ [AutoSoccer]: Внутриигровой авто-пинок принудительно отключен (CF_Set -> false).")
                end)
            end

            -- Генерируем случайную силу от 0.94 до 0.99
            local randomPower = math.random(94, 99) / 100
            
            -- Напрямую шлем пакет сильного автономного удара на дальность
            local args = { "SoccerEvent", "GZ_Step", randomPower }
            pcall(function() invokeCustom:InvokeServer(unpack(args)) end)
        end
        task.wait(0.4)
    end
end)

-- ====================================================================
-- 5. ПОДГОТОВКА К ХАТЧУ И ФУНКЦИЯ ПОИСКА ЯЙЦА
-- ====================================================================
local Library = ReplicatedStorage:WaitForChild("Library")
local ClientFolder = Library:WaitForChild("Client")
local EggCmds = require(ClientFolder:WaitForChild("EggCmds"))

-- Твои изначальные координаты яйца
local eggCFrame = CFrame.new(1425.66479, 20.2455292, -32063.8008, -0.975344896, -4.26336797e-08, -0.220685989, -4.37113883e-08, 1, 0, 0.220685989, 9.64649072e-09, -0.975344896)

-- Твоя оригинальная функция поиска без изменений
local function getNearestCustomEgg()
    local nearestID = nil
    local minDist = 25 
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    
    if root then
        local things = Workspace:FindFirstChild("__THINGS")
        local customEggs = things and things:FindFirstChild("CustomEggs")
        if customEggs then
            for _, egg in pairs(customEggs:GetChildren()) do
                if egg:IsA("Model") then
                    local dist = (egg:GetPivot().Position - root.Position).Magnitude
                    if dist < minDist then
                        minDist = dist
                        nearestID = egg.Name
                    end
                end
            end
        end
    end
    return nearestID
end

-- ====================================================================
-- 6. ЦИКЛ АВТОХАТЧА С КОНТРОЛЕМ ДИСТАНЦИИ (УДЕРЖАНИЕ НА КООРДИНАТАХ)
-- ====================================================================
task.spawn(function()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    if playerGui:FindFirstChild("EggOpen") then playerGui.EggOpen.Enabled = false end
    task.wait(5)
    while true do
        if _G.AutoHatchEnabled then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            -- [Фоновая проверка]: Возвращаем персонажа на координаты яйца, если отлетел далеко
            if hrp then
                local distanceToStart = (hrp.Position - eggCFrame.Position).Magnitude
                if distanceToStart > 10 then
                    hrp.CFrame = eggCFrame
                    task.wait(0.02) -- Микро-пауза для стабилизации
                end
            end

            -- Закупка кастомного яйца
            local targetEgg = getNearestCustomEgg()
            local maxAmount = EggCmds.GetMaxHatch()
            
            if targetEgg then
                pcall(function()
                    ReplicatedStorage.Network.CustomEggs_Hatch:InvokeServer(targetEgg, maxAmount)
                end)
            end
        end
        task.wait(0.3) -- Задержка цикла закупки
    end
end)
