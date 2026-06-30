-- -- GlassScripts/Soccer_Fullscreen_Blackout.lua
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local playerGui = LocalPlayer:WaitForChild("PlayerGui")


_G.GlassHubConfig = {
    AutoKick = true,      -- Автоматический пинок мяча
    AutoOrbs = true,      -- Авто-сбор орбов
    AutoHatch = true,     -- Автоматическая закупка яиц
    AntiAFK = true,       -- Прыжок раз в минуту
    AntiLag = true,       -- Ультра-оптимизация FPS + AntiDetectLegit
    AutoGifts = true,     -- Автооткрытие гифтов по 8 штук
}
-- Удаляем старый оверлей, если он уже был запущен
if playerGui:FindFirstChild("GlassHubOverlay") then playerGui.GlassHubOverlay:Destroy() end

-- Глобальная таблица обмена данными между сканером и HUD
_G.SoccerStats = {
    TimeText = "00:00:00",
    SoccerCoins = "Загрузка...",
    SoccerOrbs = "Загрузка...",
    Gems = "Загрузка...",
    GemsMin = "0",
    StatsBreakdown = "G: 0 | H1: 0 | H2: 0 | TT: 0 | Garg: 0",
    KickDistance = "0",
    HatchedEggs = "0 (+0)"
}

-- Глобальные переменные сессии фармы
_G.SoccerStartTime = _G.SoccerStartTime or tick()
_G.TotalHatchedSession = _G.TotalHatchedSession or 0
_G.CurrentGemsGained = _G.CurrentGemsGained or 0

_G.StartCoins = nil
_G.StartOrbs = nil
_G.StartGems = nil

-- ====================================================================
-- 1. АВТО-ПАРСЕР ИГРОВЫХ ВАЛЮТ ДЛЯ СТАРТОВОГО БАЛАНСА (ОБХОД ЗАЩИТЫ)
-- ====================================================================
local function parseAbbreviatedNumber(str)
    if not str then return 0 end
    str = string.lower(string.gsub(str, "%s+", ""))
    local num = tonumber(string.match(str, "[%d%.]+")) or 0
    if string.find(str, "k") then return num * 1000
    elseif string.find(str, "m") then return num * 1000000
    elseif string.find(str, "b") then return num * 1000000000
    elseif string.find(str, "t") then return num * 1000000000000 end
    return num
end

-- Считываем балансы с оригинального интерфейса игры TopBar
for _, gui in pairs(playerGui:GetDescendants()) do
    if gui:IsA("TextLabel") and gui.Visible == true then
        local text = gui.Text
        if gui.Name:find("Orb") or (gui.Parent and gui.Parent.Name:find("Orb")) then
            local parsed = parseAbbreviatedNumber(text)
            if parsed > 0 and not _G.StartOrbs then _G.StartOrbs = parsed end
        elseif gui.Name:find("Coin") or (gui.Parent and gui.Parent.Name:find("Coin")) then
            local parsed = parseAbbreviatedNumber(text)
            if parsed > 0 and not _G.StartCoins then _G.StartCoins = parsed end
        elseif gui.Name:find("Diamond") or gui.Name:find("Gem") or (gui.Parent and (gui.Parent.Name:find("Diamond") or gui.Parent.Name:find("Gem"))) then
            local parsed = parseAbbreviatedNumber(text)
            if parsed > 0 and not _G.StartGems then _G.StartGems = parsed end
        end
    end
end

-- Резервный поиск по маске (если имена лейблов скрыты)
if not _G.StartOrbs or not _G.StartCoins or not _G.StartGems then
    for _, gui in pairs(playerGui:GetDescendants()) do
        if gui:IsA("TextLabel") and gui.Visible == true then
            local text = gui.Text
            if text:find("%d+k") or text:find("%d+m") or text:find("%d+b") then
                local parsed = parseAbbreviatedNumber(text)
                if parsed > 0 then
                    if parsed > 1000000000 and not _G.StartCoins then _G.StartCoins = parsed
                    elseif parsed > 1000000 and not _G.StartGems then _G.StartGems = parsed
                    elseif parsed > 500 and parsed < 1000000 and not _G.StartOrbs then _G.StartOrbs = parsed end
                end
            end
        end
    end
end

-- Функция сжатия чисел обратно в формат k/m/b для оверлея
function formatWithSuffix(value)
    if value >= 1000000000 then return string.format("%.1fb", value / 1000000000)
    elseif value >= 1000000 then return string.format("%.1fm", value / 1000000)
    elseif value >= 1000 then return string.format("%.1fk", value / 1000) end
    return tostring(value)
end

-- Выставляем стартовые значения на экран
if _G.StartCoins then _G.SoccerStats.SoccerCoins = formatWithSuffix(_G.StartCoins) .. " (+0)" end
if _G.StartOrbs then _G.SoccerStats.SoccerOrbs = formatWithSuffix(_G.StartOrbs) .. " (+0)" end
if _G.StartGems then _G.SoccerStats.Gems = formatWithSuffix(_G.StartGems) .. " (+0)" end

-- ====================================================================
-- 2. СЕТЕВОЙ ХУК НА ПОКУПКУ ЯИЦ (ИСПРАВЛЕННЫЙ ВЫВОД ПАЧКИ)
-- ====================================================================
task.spawn(function()
    local customEggsHatch = ReplicatedStorage:WaitForChild("Network"):WaitForChild("CustomEggs_Hatch")
    local oldNamecall
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local args = {...}
        local method = getnamecallmethod()
        if method == "InvokeServer" and self == customEggsHatch then
            local success, response = pcall(oldNamecall, self, ...)
            if success and response then
                local amountBought = tonumber(args[2]) or 0 -- Число открываемых за раз яиц (например, 22)
                if amountBought > 0 then
                    _G.TotalHatchedSession = _G.TotalHatchedSession + amountBought
                    -- СТАЛО: Выводим общее число, а в скобках — размер текущей пачки открытия (+22)
                    _G.SoccerStats.HatchedEggs = string.format("%s (+%s)", tostring(_G.TotalHatchedSession), tostring(amountBought))
                end
            end
            return response
        end
        return oldNamecall(self, ...)
    end)
end)
-- ====================================================================
-- 3. СОЗДАНИЕ АДАПТИВНОГО ИНТЕРФЕЙСА (UI OVERLAY)
-- ====================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "GlassHubOverlay"
ScreenGui.ResetOnSpawn = false
ScreenGui.IgnoreGuiInset = true -- Делает верхнюю полосу Роблокса чёрной
ScreenGui.Parent = playerGui

local BlackBackground = Instance.new("Frame")
BlackBackground.Size = UDim2.new(1, 0, 1, 0)
BlackBackground.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
BlackBackground.BorderSizePixel = 0
BlackBackground.Active = true
BlackBackground.Parent = ScreenGui

local HUDFrame = Instance.new("Frame")
HUDFrame.Size = UDim2.new(0.7, 0, 0.55, 0) -- Пропорции в процентах от экрана
HUDFrame.Position = UDim2.new(0.15, 0, 0.22, 0)
HUDFrame.BackgroundTransparency = 1
HUDFrame.BorderSizePixel = 0
HUDFrame.Parent = BlackBackground

local Layout = Instance.new("UIListLayout")
Layout.SortOrder = Enum.SortOrder.LayoutOrder
Layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
Layout.VerticalAlignment = Enum.VerticalAlignment.Center
Layout.Padding = UDim.new(0.02, 0)
Layout.Parent = HUDFrame

local function createCenteredLabel(name, text, order, relativeHeight)
    local label = Instance.new("TextLabel")
    label.Name = name
    label.Size = UDim2.new(1, 0, relativeHeight or 0.08, 0)
    label.Text = text
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.Font = Enum.Font.SourceSansBold
    label.BackgroundTransparency = 1
    label.TextXAlignment = Enum.TextXAlignment.Center
    label.LayoutOrder = order
    label.TextScaled = true -- Текст резиновый, масштабируется сам под окно!
    label.Parent = HUDFrame
    return label
end

HatchingLabel = createCenteredLabel("HatchingLabel", "Hatching: Soccer Egg 5 Tier 1", 1, 0.11)

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(0.9, 0, 0, 2)
Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Divider.BorderSizePixel = 0
Divider.LayoutOrder = 2
Divider.Parent = HUDFrame

TimeLabel = createCenteredLabel("TimeLabel", "00:00:00", 3, 0.14)
BreakdownLabel = createCenteredLabel("BreakdownLabel", "G: 0 | H1: 0 | H2: 0 | TT: 0 | Garg: 0", 4, 0.08)
DistanceLabel = createCenteredLabel("DistanceLabel", "Kick Stats: Distance 0", 5, 0.08)
HatchedEggsLabel = createCenteredLabel("Hatched Eggs: 0 (+0)", "Hatched Eggs: 0 (+0)", 6, 0.08)

-- Настройка копирайтов
local CreditButton = Instance.new("TextButton")
CreditButton.Size = UDim2.new(1, 0, 0, 25)
CreditButton.Text = "Made By Le31zy | gg/9XGYrDeU8D"
CreditButton.TextColor3 = Color3.fromRGB(140, 140, 140)
CreditButton.Font = Enum.Font.SourceSansSemibold
CreditButton.TextSize = 14
CreditButton.BackgroundTransparency = 1
CreditButton.TextXAlignment = Enum.TextXAlignment.Center
CreditButton.LayoutOrder = 7
CreditButton.Parent = HUDFrame

CreditButton.MouseButton1Click:Connect(function()
    if setclipboard or toclipboard then
        local copyFunc = setclipboard or toclipboard
        copyFunc("https://discord.gg/9XGYrDeU8D")
        CreditButton.Text = "Ссылка скопирована!"
        task.wait(2)
        CreditButton.Text = "Made By Le31zy | gg/9XGYrDeU8D"
    end
end)

-- Новая надпись строго под копирайтом
local OneClickLabel = Instance.new("TextLabel")
OneClickLabel.Name = "OneClickLabel"
OneClickLabel.Size = UDim2.new(1, 0, 0, 20)
OneClickLabel.Text = "GlassHub OneClickGUI"
OneClickLabel.TextColor3 = Color3.fromRGB(180, 180, 180) -- Чуть ярче серого
OneClickLabel.Font = Enum.Font.SourceSansItalic
OneClickLabel.TextSize = 13
OneClickLabel.BackgroundTransparency = 1
OneClickLabel.TextXAlignment = Enum.TextXAlignment.Center
OneClickLabel.LayoutOrder = 8
OneClickLabel.Parent = HUDFrame

local HideButton = Instance.new("TextButton")
HideButton.Size = UDim2.new(0, 110, 0, 35)
HideButton.Position = UDim2.new(0, 25, 1, -55)
HideButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
HideButton.Text = "Hide GUI"
HideButton.TextColor3 = Color3.fromRGB(220, 220, 220)
HideButton.Font = Enum.Font.SourceSansBold
HideButton.TextSize = 14
HideButton.Parent = ScreenGui
Instance.new("UICorner").Parent = HideButton

HideButton.MouseButton1Click:Connect(function()
    if BlackBackground.Visible then
        BlackBackground.Visible = false
        HideButton.Text = "Show GUI"
        HideButton.BackgroundColor3 = Color3.fromRGB(40, 120, 40)
    else
        BlackBackground.Visible = true
        HideButton.Text = "Hide GUI"
        HideButton.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    end
end)

-- ====================================================================
-- 4. ПОТОК ОТРИСОВКИ ТЕКСТА И ТАЙМЕРА СЕССИИ
-- ====================================================================
task.spawn(function()
    while true do
        if not playerGui:FindFirstChild("GlassHubOverlay") then break end
        if _G.SoccerStats then
            pcall(function()
                local elapsed = tick() - (_G.SoccerStartTime or tick())
                _G.SoccerStats.TimeText = string.format("%02d:%02d:%02d", math.floor(elapsed / 3600), math.floor((elapsed % 3600) / 60), math.floor(elapsed % 60))
                
                TimeLabel.Text = _G.SoccerStats.TimeText
                BreakdownLabel.Text = _G.SoccerStats.StatsBreakdown
                DistanceLabel.Text = string.format("Kick Stats: Distance %s", _G.SoccerStats.KickDistance)
                HatchedEggsLabel.Text = string.format("Hatched Eggs: %s", _G.SoccerStats.HatchedEggs)
            end)
        end
        task.wait(0.5)
    end
end)

-- ====================================================================
-- 5. ОДНОРАЗОВЫЙ СТАРТОВЫЙ ТЕЛЕПОРТ В ИВЕНТ ПРИ ЗАХОДЕ
-- ====================================================================
task.spawn(function()
    local hrp = nil
    
    -- Ждем, пока персонаж полностью прогрузится в игре
    while not hrp do
        hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        task.wait(0.5)
    end
    
    -- Ищем оригинальный системный телепорт в главном мире (который всегда доступен со старта)
    local targetTeleport = nil
    local things = Workspace:FindFirstChild("__THINGS")
    local instances = things and things:FindFirstChild("Instances")
    local soccerInstance = instances and instances:FindFirstChild("SoccerEvent")
    local teleportsFolder = soccerInstance and soccerInstance:FindFirstChild("Teleports")
    
    -- Проверяем любые доступные парты внутри стартового портала
    if teleportsFolder then
        targetTeleport = teleportsFolder:FindFirstChild("Enter") 
            or teleportsFolder:FindFirstChildOfClass("Part") 
            or teleportsFolder:FindFirstChildOfClass("MeshPart") 
            or teleportsFolder:FindFirstChildOfClass("Model")
    end
    
    -- Если стартовый портал найден — прыгаем в него ОДИН раз для триггера загрузки
    if targetTeleport and hrp then
        pcall(function()
            if targetTeleport:IsA("Model") then
                hrp.CFrame = targetTeleport:GetModelCFrame()
            else
                hrp.CFrame = targetTeleport.CFrame
            end
        end)
    else
    end
    
    -- Поток выполнил свою задачу, запустил локацию и навсегда умер в памяти
end)



-- ====================================================================
-- 6. ФЛАГИ И АВТО-СКИП АНИМАЦИЙ ЯИЦ
-- ====================================================================
_G.AutoPerfectPowerActive = true
getgenv().AutoYeetOrbsActive = true
_G.AutoHatchEnabled = true

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
                    if gui:IsA("ScreenGui") and gui.Name ~= "GlassHubOverlay" and (gui.Name:find("Egg") or gui.Name:find("Hatch") or gui.Name:find("Scene")) then
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
    if playerGui:FindFirstChild("EggOpen") then playerGui.EggOpen.Enabled = false end
end

-- ====================================================================
-- 7. АВТО-ОРБЫ ИЗ CLIENTMODULE
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
-- 8. АВТОХАТЧ С КОНТРОЛЕМ ДИСТАНЦИИ
-- ====================================================================
local EggCmds = require(ReplicatedStorage:WaitForChild("Library").Client:WaitForChild("EggCmds"))
local eggCFrame = CFrame.new(1425.66479, 20.2455292, -32063.8008, -0.975344896, -4.26336797e-08, -0.220685989, -4.37113883e-08, 1, 0, 0.220685989, 9.64649072e-09, -0.975344896)

local function getNearestCustomEgg()
    local nearestID = nil
    local minDist = 25 
    local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if root then
        local customEggs = Workspace.__THINGS:FindFirstChild("CustomEggs")
        if customEggs then
            for _, egg in pairs(customEggs:GetChildren()) do
                if egg:IsA("Model") then
                    local dist = (egg:GetPivot().Position - root.Position).Magnitude
                    if dist < minDist then minDist = dist; nearestID = egg.Name end
                end
            end
        end
    end
    return nearestID
end

task.spawn(function()
    task.wait(9)
    while true do
        if _G.AutoHatchEnabled then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            if hrp then
                local currentPos = hrp.Position
                local startPos = eggCFrame.Position
                
                -- Расстояние по горизонтали (оси X и Z)
                local distanceXZ = math.sqrt((currentPos.X - startPos.X)^2 + (currentPos.Z - startPos.Z)^2)
                -- Расстояние по вертикали (высота Y)
                local distanceY = math.abs(currentPos.Y - startPos.Y)
                
                -- Если унесло по X/Z дальше 10 или по Y дальше 15 стадов
                if distanceXZ > 35 or distanceY > 35 then 
                    -- ИСПРАВЛЕНО: Тепаем на граунд (смещаем координаты яйца вниз на уровень земли)
                    local groundCFrame = eggCFrame * CFrame.new(0, -20, 0)
                    hrp.CFrame = groundCFrame
                    task.wait(0.05) 
                end
            end
            local targetEgg = getNearestCustomEgg()
            local maxAmount = EggCmds.GetMaxHatch()
            if targetEgg then pcall(function() ReplicatedStorage.Network.CustomEggs_Hatch:InvokeServer(targetEgg, maxAmount) end) end
        end
        task.wait(0.3)
    end
end)

-- ====================================================================
-- 9. АВТОНОМНЫЙ ПИНАТЕЛЬ МЯЧА (С ПАУЗОЙ НА 30 СЕК ПРИ СБРОСЕ СФЕР)
-- ====================================================================

-- Глобальный флаг для паузы при сбросе силы
getgenv().SoccerNotificationPause = false

-- Поток для отслеживания уведомления "Orb strength has reset" в интерфейсе
task.spawn(function()
    local player = game.Players.LocalPlayer
    local pGui = player:WaitForChild("PlayerGui")

    local function checkGuiElement(element)
        if element:IsA("TextLabel") or element:IsA("TextBox") then
            -- Проверяем текст уведомления (без учета регистра для надежности)
            if string.find(string.lower(element.Text), "orb strength has reset") then
                if not getgenv().SoccerNotificationPause then
                    getgenv().SoccerNotificationPause = true
                  
                    task.wait(30)
                    
                    getgenv().SoccerNotificationPause = false
                end
            end
        end
    end

    -- Сканируем уже существующие тексты на экране
    for _, desc in pairs(pGui:GetDescendants()) do
        checkGuiElement(desc)
    end

    -- Отслеживаем появление новых элементов интерфейса
    pGui.DescendantAdded:Connect(function(desc)
        task.wait(0.1) -- Даем игре время обновить свойство Text
        checkGuiElement(desc)
    end)
end)

if not _G.SessionGoals then
    _G.SessionGoals = { gift = 0, huge1 = 0, huge2 = 0, titanic = 0, gargantuan = 0 }
end
task.spawn(function()
    local networkFolder = ReplicatedStorage:WaitForChild("Network")
    local invokeCustom = networkFolder:WaitForChild("Instancing_InvokeCustomFromClient")
    
    while true do
        if _G.AutoPerfectPowerActive then
            -- Безопасная пауза без continue
            if getgenv().SoccerNotificationPause then
                task.wait(0.5)
            else
                local randomPower = math.random(94, 99) / 100
                
                -- Передаем аргументы напрямую, без использования ломающегося unpack()
                local success, response = pcall(function() 
                    return invokeCustom:InvokeServer("SoccerEvent", "GZ_Step", randomPower) 
                end)
                
                if success and type(response) == "table" then
                    if response.Success == false then
                        _G.SessionGoals = { gift = 0, huge1 = 0, huge2 = 0, titanic = 0, gargantuan = 0 }
                        _G.SoccerStats.StatsBreakdown = "G: 0 | H1: 0 | H2: 0 | TT: 0 | Garg: 0"
                    else
                        if type(response.Rings) == "table" and #response.Rings > 0 then
                            for _, ringData in pairs(response.Rings) do
                                -- Обходим string.lower: переводим в строку и сравниваем вручную,
                                -- защищая обфускатор от порчи метатаблиц строк
                                local rawId = ringData.Id and tostring(ringData.Id)
                                if rawId then
                                    if rawId == "Gift" or rawId == "gift" then
                                        _G.SessionGoals.gift = _G.SessionGoals.gift + 1
                                    elseif rawId == "Huge1" or rawId == "huge1" then
                                        _G.SessionGoals.huge1 = _G.SessionGoals.huge1 + 1
                                    elseif rawId == "Huge2" or rawId == "huge2" then
                                        _G.SessionGoals.huge2 = _G.SessionGoals.huge2 + 1
                                    elseif rawId == "Titanic" or rawId == "titanic" then
                                        _G.SessionGoals.titanic = _G.SessionGoals.titanic + 1
                                    elseif rawId == "Gargantuan" or rawId == "gargantuan" then
                                        _G.SessionGoals.gargantuan = _G.SessionGoals.gargantuan + 1
                                    end
                                end
                            end
                        end
                        
                        _G.SoccerStats.StatsBreakdown = string.format(
                            "G: %s | H1: %s | H2: %s | TT: %s | Garg: %s",
                            tostring(_G.SessionGoals.gift), tostring(_G.SessionGoals.huge1),
                            tostring(_G.SessionGoals.huge2), tostring(_G.SessionGoals.titanic), tostring(_G.SessionGoals.gargantuan)
                        )
                    end

                    if response.Studs then
                        local studs = tonumber(response.Studs) or 0
                        if studs >= 1000000 then _G.SoccerStats.KickDistance = string.format("%.2fM", studs / 1000000)
                        elseif studs >= 1000 then _G.SoccerStats.KickDistance = string.format("%.1fK", studs / 1000)
                        else _G.SoccerStats.KickDistance = tostring(studs) end
                    end
                    
                    local randomDelay = math.random(1, 4) / 100
                    task.wait(randomDelay)
                else
                    -- Защита от nil (Generation Failure) — просто ждем секунду
                    task.wait(1.0)
                end
            end
        else
            task.wait(0.5)
        end
    end
end)


-- ====================================================================
-- АНТИ-АФК ПОТОК С ПРОВЕРКОЙ КОНФИГА (ДОБАВЛЕНО)
-- ====================================================================
task.spawn(function()
    local vim = game:GetService("VirtualInputManager")
    while true do
        task.wait(60) -- Прыжок раз в минуту
        if _G.GlassHubConfig and _G.GlassHubConfig.AntiAFK == true then
            pcall(function()
                vim:SendKeyEvent(true, "Space", false, game)
                task.wait(0.1)
                vim:SendKeyEvent(false, "Space", false, game)
            end)
        end
    end
end)
-- ====================================================================
-- АНТИ-ЛАГ ПОТОК: ОПТИМИЗАЦИЯ И СДВИГ ЗЕМЛИ (ДОБАВЛЕНО)
-- ====================================================================
task.spawn(function()
    while true do
        task.wait(10) -- Проверка и зачистка каждые 2 секунды
        if _G.GlassHubConfig and _G.GlassHubConfig.AntiLag == true then
            pcall(function()
                local things = Workspace:FindFirstChild("__THINGS")
                
                -- 1. Удаление системного SoccerEvent из папки Instances
                local instances = things and things:FindFirstChild("Instances")
                if instances and instances:FindFirstChild("SoccerEvent") then
                    instances.SoccerEvent:Destroy()
                end
                
                -- Навигация в контейнер активных зон
                local container = things and things:FindFirstChild("__INSTANCE_CONTAINER")
                local active = container and container:FindFirstChild("Active")
                local activeSoccer = active and active:FindFirstChild("SoccerEvent")
                
                if activeSoccer then
                    -- 2. Удаление папок Area 1 - Area 5
                    for i = 1, 5 do
                        local areaName = tostring(i) .. " | Area " .. tostring(i)
                        local areaFolder = activeSoccer:FindFirstChild(areaName)
                        if areaFolder then areaFolder:Destroy() end
                    end
                    
                    -- 3. Удаление BREAK_ZONES
                    local breakZones = activeSoccer:FindFirstChild("BREAK_ZONES")
                    if breakZones then breakZones:Destroy() end
                    
                    -- 4. Смещение ZONE_GROUND["5"] на 9 стадов вниз по оси Y
                    local zoneGround = activeSoccer:FindFirstChild("ZONE_GROUND")
                    local ground5 = zoneGround and zoneGround:FindFirstChild("5")
                    if ground5 then
                        -- Смещаем только один раз, проверяя тег, чтобы земля не улетала в бесконечность вниз
                        if not ground5:GetAttribute("ShiftedY") then
                            ground5:SetAttribute("ShiftedY", true)
                            if ground5:IsA("Model") then
                                ground5:TranslateBy(Vector3.new(0, -20, 0))
                            elseif ground5:IsA("BasePart") then
                                ground5.CFrame = ground5.CFrame * CFrame.new(0, -20, 0)
                            end
                        end
                    end
                end
                
                -- 5. Удаление эффекта BottomLight у кастомного яйца
                local customEggs = things and things:FindFirstChild("CustomEggs")
                local targetEgg = customEggs and customEggs:FindFirstChild("0a4190cd61cc4932a8280600c1453913")
                local bottomLight = targetEgg and targetEgg:FindFirstChild("BottomLight")
                if bottomLight then
                    bottomLight:Destroy()
                end
            end)
        end
    end
end)
-- ====================================================================
-- 10. БЕШЕНОЕ АВТООТКРЫТИЕ ФУТБОЛЬНЫХ ПОДАРКОВ (ПО 8 ШТУК)
-- ====================================================================
task.spawn(function()
    local replicatedStorage = game:GetService("ReplicatedStorage")
    local unlockRemote = replicatedStorage:WaitForChild("Network"):WaitForChild("WR_Unlock")
    
    -- Заранее подготавливаем массив векторов из твоего ремоута, чтобы не тратить FPS на создание векторов в цикле
    local giftVectors = {
        Vector3.new(1428.330322265625, -6.832083702087402, -32052.076171875),
        Vector3.new(1435.823974609375, -6.832083702087402, -32057.38671875),
        Vector3.new(1419.276611328125, -6.832083702087402, -32053.62109375),
        Vector3.new(1437.3677978515625, -6.832083702087402, -32066.44140625),
        Vector3.new(1413.9664306640625, -6.832083702087402, -32061.11328125),
        Vector3.new(1432.0576171875, -6.832083702087402, -32073.93359375),
        Vector3.new(1415.51025390625, -6.832083702087402, -32070.16796875),
        Vector3.new(1423.00390625, -6.832083702087402, -32075.478515625)
    }
    task.wait(10)
    while true do
        -- Проверяем, включена ли функция в конфиге
        if _G.GlassHubConfig and _G.GlassHubConfig.AutoGifts == true then
            pcall(function()
                -- Пакуем аргументы точь-в-точь как в твоем SimpleSpy
                local args = {
                    "5615d7e06a684cbfafa26674ead6cceb", -- ID подарка/сессии
                    8,                                  -- Количество за раз
                    giftVectors                         -- Таблица векторов
                }
                
                -- Шлем пакет на сервер
                unlockRemote:InvokeServer(unpack(args))
            end)
            
            -- Бешеная скорость: минимальный тик задержки Lua (около 0.01 сек), чтобы не крашнуть и не кикнуть за спам
            task.wait(0.01)
        else
            -- Если отключено в кфг — просто ждем полсекунды и проверяем снова
            task.wait(0.5)
        end
    end
end)

print("[GlassScripts]")
