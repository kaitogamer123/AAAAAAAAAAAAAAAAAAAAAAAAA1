

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()
local UserInputService = game:GetService("UserInputService")

-- -- GlassScripts/Soccer_Fullscreen_Blackout.lua
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer or Players.PlayerAdded:Wait()

-- ====================================================================
-- 1. ИНИЦИАЛИЗАЦИЯ И СНЕСЕНИЕ СТАРЫХ ГУИ
-- ====================================================================
local playerGui = LocalPlayer:WaitForChild("PlayerGui")
if playerGui:FindFirstChild("SoccerBlackoutGui") then playerGui.SoccerBlackoutGui:Destroy() end

-- Глобальная таблица обмена данными
_G.SoccerStats = {
    TimeText = "00:00:00",
    SoccerCoins = "0",
    SoccerOrbs = "0",
    Gems = "0",
    GemsMin = "0",
    StatsBreakdown = "G: 0 | H1: 0 | H2: 0 | TT: 0 | Garg: 0",
    KickDistance = "0",
    HatchedEggs = "0"
}

-- Настройки сессии
local startBalances = {}
local isFirstRun = true
local startTime = tick()

-- ====================================================================
-- 2. СОЗДАНИЕ СПЛОШНОГО ПОЛНОЭКРАННОГО ЧЕРНОГО HUD
-- ====================================================================
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "SoccerBlackoutGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.Parent = playerGui

-- Сплошной черный фон (Экономит батарею, отключает 3D рендер под собой)
local BlackBackground = Instance.new("Frame")
BlackBackground.Size = UDim2.new(1, 0, 1, 0)
BlackBackground.Position = UDim2.new(0, 0, 0, 0)
BlackBackground.BackgroundColor3 = Color3.fromRGB(10, 10, 10)
BlackBackground.BorderSizePixel = 0
BlackBackground.Active = true -- Защита от случайных тапов в игру
BlackBackground.Parent = ScreenGui

-- Центральный блок текста
local HUDFrame = Instance.new("Frame")
HUDFrame.Size = UDim2.new(0, 500, 0, 280)
HUDFrame.Position = UDim2.new(0.5, -250, 0.5, -140)
HUDFrame.BackgroundTransparency = 1
HUDFrame.BorderSizePixel = 0
HUDFrame.Parent = BlackBackground

local HatchingLabel = Instance.new("TextLabel")
HatchingLabel.Size = UDim2.new(1, 0, 0, 35)
HatchingLabel.Position = UDim2.new(0, 0, 0, 10)
HatchingLabel.Text = "Hatching: Soccer Egg 5 Tier 1"
HatchingLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
HatchingLabel.Font = Enum.Font.SourceSansBold
HatchingLabel.TextSize = 24
HatchingLabel.BackgroundTransparency = 1
HatchingLabel.Parent = HUDFrame

local Divider = Instance.new("Frame")
Divider.Size = UDim2.new(0.9, 0, 0, 2)
Divider.Position = UDim2.new(0.05, 0, 0, 50)
Divider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
Divider.BorderSizePixel = 0
Divider.Parent = HUDFrame

local TimeLabel = Instance.new("TextLabel")
TimeLabel.Size = UDim2.new(1, 0, 0, 30)
TimeLabel.Position = UDim2.new(0, 0, 0, 60)
TimeLabel.Text = "00:00:00"
TimeLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
TimeLabel.Font = Enum.Font.SourceSansBold
TimeLabel.TextSize = 22
TimeLabel.BackgroundTransparency = 1
TimeLabel.Parent = HUDFrame

local MainStatsLabel = Instance.new("TextLabel")
MainStatsLabel.Size = UDim2.new(1, 0, 0, 30)
MainStatsLabel.Position = UDim2.new(0, 0, 0, 100)
MainStatsLabel.Text = "SoccerCoins: 0 | SoccerOrbs: 0 | Gems: 0 | Gems/Min: 0"
MainStatsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
MainStatsLabel.Font = Enum.Font.SourceSansBold
MainStatsLabel.TextSize = 16
MainStatsLabel.BackgroundTransparency = 1
MainStatsLabel.Parent = HUDFrame

local BreakdownLabel = Instance.new("TextLabel")
BreakdownLabel.Size = UDim2.new(1, 0, 0, 30)
BreakdownLabel.Position = UDim2.new(0, 0, 0, 135)
BreakdownLabel.Text = "G: 0 | H1: 0 | H2: 0 | TT: 0 | Garg: 0"
BreakdownLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
BreakdownLabel.Font = Enum.Font.SourceSansBold
BreakdownLabel.TextSize = 16
BreakdownLabel.BackgroundTransparency = 1
BreakdownLabel.Parent = HUDFrame

local DistanceLabel = Instance.new("TextLabel")
DistanceLabel.Size = UDim2.new(1, 0, 0, 30)
DistanceLabel.Position = UDim2.new(0, 0, 0, 165)
DistanceLabel.Text = "Kick Stats: Distance 0" -- Без слова studs
DistanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
DistanceLabel.Font = Enum.Font.SourceSansBold
DistanceLabel.TextSize = 16
DistanceLabel.BackgroundTransparency = 1
DistanceLabel.Parent = HUDFrame

local HatchedEggsLabel = Instance.new("TextLabel")
HatchedEggsLabel.Size = UDim2.new(1, 0, 0, 30)
HatchedEggsLabel.Position = UDim2.new(0, 0, 0, 195)
HatchedEggsLabel.Text = "Hatched Eggs: 0 (+1)"
HatchedEggsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
HatchedEggsLabel.Font = Enum.Font.SourceSansBold
HatchedEggsLabel.TextSize = 16
HatchedEggsLabel.BackgroundTransparency = 1
HatchedEggsLabel.Parent = HUDFrame

local CreditButton = Instance.new("TextButton")
CreditButton.Size = UDim2.new(1, 0, 0, 25)
CreditButton.Position = UDim2.new(0, 0, 1, -25)
CreditButton.Text = "Made By Le31zy | gg/9XGYrDeU8D"
CreditButton.TextColor3 = Color3.fromRGB(140, 140, 140)
CreditButton.Font = Enum.Font.SourceSansSemibold
CreditButton.TextSize = 14
CreditButton.BackgroundTransparency = 1
CreditButton.Parent = HUDFrame

CreditButton.MouseButton1Click:Connect(function()
    if setclipboard or toclipboard then
        local copyFunc = setclipboard or toclipboard
        copyFunc("https://discord.gg")
        CreditButton.Text = "Ссылка скопирована!"
        task.wait(2)
        CreditButton.Text = "Made By Le31zy | gg/9XGYrDeU8D"
    end
end)

-- Маленькая кнопка полного удаления черного экрана (Чтобы вернуться в саму игру)
local HideButton = Instance.new("TextButton")
HideButton.Size = UDim2.new(0, 100, 0, 35)
HideButton.Position = UDim2.new(0, 15, 1, -50)
HideButton.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
HideButton.Text = "Hide GUI"
HideButton.TextColor3 = Color3.fromRGB(220, 220, 220)
HideButton.Font = Enum.Font.SourceSansBold
HideButton.TextSize = 14
HideButton.Parent = HUDFrame
Instance.new("UICorner").Parent = HideButton

HideButton.MouseButton1Click:Connect(function()
    ScreenGui:Destroy() -- Удаляет весь черный оверлей и возвращает в обычную игру
end)

-- ====================================================================
-- 3. АВТОМАТИЧЕСКИЙ ХУК ДАННЫХ ИНВЕНТАРЯ И ЦЕЛЕЙ С ЭКРАНА
-- ====================================================================
task.spawn(function()
    local Library = require(ReplicatedStorage:WaitForChild("Library"))
    local SaveModule = Library.Save

    while true do
        pcall(function()
            if not ScreenGui or not ScreenGui.Parent then return end -- Стоп поток, если GUI удален
            
            local s = SaveModule.Get(LocalPlayer)
            local inv = s and s.Inventory
            
            if inv then
                -- Валюты
                local currencies = inv.Currency or {}
                for id, data in pairs(currencies) do
                    local currentAmount = data._am or 0
                    if isFirstRun then startBalances[id] = currentAmount end
                    local gained = currentAmount - (startBalances[id] or currentAmount)
                    
                    if id:find("Coins") or id:find("Soccer") then
                        _G.SoccerStats.SoccerCoins = string.format("%s (+%s)", tostring(currentAmount), tostring(gained))
                    elseif id:find("Diamonds") or id:find("Gems") then
                        _G.SoccerStats.Gems = string.format("%s (+%s)", tostring(currentAmount), tostring(gained))
                    end
                end

                -- Предметы/Орбы
                local miscItems = inv.Misc or {}
                for id, data in pairs(miscItems) do
                    local currentAmount = data._am or 0
                    if isFirstRun then startBalances[id] = currentAmount end
                    local gained = currentAmount - (startBalances[id] or currentAmount)
                    
                    if id:find("Orb") or id:find("Soccer") then
                        _G.SoccerStats.SoccerOrbs = string.format("%s (+%s)", tostring(currentAmount), tostring(gained))
                    end
                end
            end

            -- Сортировка и парсинг Soccer Goals по Y-высоте (сверху вниз)
            local foundPointsLabels = {}
            for _, gui in pairs(playerGui:GetDescendants()) do
                if gui:IsA("TextLabel") then
                    local text = gui.Text
                    if text:find("points") and text:find("/10") then
                        local num = tonumber(text:match("(%d+)/10")) or 0
                        table.insert(foundPointsLabels, {
                            num = num,
                            yPos = gui.AbsolutePosition.Y
                        })
                    end
                end
            end

            table.sort(foundPointsLabels, function(a, b) return a.yPos < b.yPos end)

            local g    = foundPointsLabels[1] and foundPointsLabels[1].num or 0
            local h1   = foundPointsLabels[2] and foundPointsLabels[2].num or 0
            local h2   = foundPointsLabels[3] and foundPointsLabels[3].num or 0
            local tt   = foundPointsLabels[4] and foundPointsLabels[4].num or 0
            local garg = foundPointsLabels[5] and foundPointsLabels[5].num or 0
            _G.SoccerStats.StatsBreakdown = string.format("G: %s | H1: %s | H2: %s | TT: %s | Garg: %s", g, h1, h2, tt, garg)

            -- Яйца и дистанция
            if s then
                if s.EggHatches then
                    local totalHatched = 0
                    for _, count in pairs(s.EggHatches) do totalHatched = totalHatched + count end
                    if isFirstRun then startBalances["_eggs"] = totalHatched end
                    _G.SoccerStats.HatchedEggs = string.format("%s (+%s)", tostring(totalHatched), tostring(totalHatched - (startBalances["_eggs"] or totalHatched)))
                end
                if s.SoccerEventStats and s.SoccerEventStats.MaxDistance then
                    _G.SoccerStats.KickDistance = tostring(s.SoccerEventStats.MaxDistance)
                elseif s.SoccerStats and s.SoccerStats.MaxDistance then
                    _G.SoccerStats.KickDistance = tostring(s.SoccerStats.MaxDistance)
                end
            end

            isFirstRun = false
            
            -- Таймер и Gems/Min
            local elapsed = tick() - startTime
            _G.SoccerStats.TimeText = string.format("%02d:%02d:%02d", math.floor(elapsed / 3600), math.floor((elapsed % 3600) / 60), math.floor(elapsed % 60))
            
            local totalGemsGained = 0
            if inv and inv.Currency and inv.Currency["Diamonds"] then
                totalGemsGained = (inv.Currency["Diamonds"]._am or 0) - (startBalances["Diamonds"] or 0)
            end
            _G.SoccerStats.GemsMin = tostring(elapsed > 60 and math.floor(totalGemsGained / (elapsed / 60)) or 0)
        end)
        task.wait(1)
    end
end)

-- ====================================================================
-- 4. ПОТОК ОТРИСОВКИ ТЕКСТА НА ХУД
-- ====================================================================
task.spawn(function()
    while true do
        if not ScreenGui or not ScreenGui.Parent then break end
        if _G.SoccerStats then
            pcall(function()
                TimeLabel.Text = _G.SoccerStats.TimeText
                MainStatsLabel.Text = string.format("SoccerCoins: %s | SoccerOrbs: %s | Gems: %s | Gems/Min: %s", 
                    _G.SoccerStats.SoccerCoins, _G.SoccerStats.SoccerOrbs, _G.SoccerStats.Gems, _G.SoccerStats.GemsMin)
                BreakdownLabel.Text = _G.SoccerStats.StatsBreakdown
                DistanceLabel.Text = string.format("Kick Stats: Distance %s", _G.SoccerStats.KickDistance)
                HatchedEggsLabel.Text = string.format("Hatched Eggs: %s", _G.SoccerStats.HatchedEggs)
            end)
        end
        task.wait(0.5)
    end
end)

print("[GlassScripts] Полноэкранный HUD с авто-хуком целей запущен!")






-- ====================================================================
-- АВТО-ВОЗВРАТ В ИВЕНТ ЧЕРЕЗ СИСЕМНЫЙ ТЕЛЕПОРТ
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




local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local LocalPlayer = game:GetService("Players").LocalPlayer

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

local Workspace = game:GetService("Workspace")
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
-- 5. АВТОНОМНЫЙ ПИНАТЕЛЬ НА ДАЛЬНОСТЬ + ОТКЛЮЧЕНИЕ ИГРОВОГО АВТОПИНКА
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
-- 6. АВТОХАТЧ С ХУКОМ ОРИГИНАЛЬНОЙ ФУНКЦИИ И КОНТРОЛЕМ ДИСТАНЦИИ
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
        local customEggs = Workspace.__THINGS:FindFirstChild("CustomEggs")
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

-- Твой оригинальный цикл, дополненный проверкой на 10 стадов от изначальных координат
task.spawn(function()
    local playerGui = LocalPlayer:WaitForChild("PlayerGui")
    if playerGui:FindFirstChild("EggOpen") then playerGui.EggOpen.Enabled = false end
    task.wait(5)
    while true do
        if _G.AutoHatchEnabled then
            local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
            
            -- Контроль дистанции: если унесло на 10 стадов от ИЗНАЧАЛЬНЫХ координат, тепаем обратно
            if hrp then
                local distanceToStart = (hrp.Position - eggCFrame.Position).Magnitude
                if distanceToStart > 10 then
                    hrp.CFrame = eggCFrame
                    task.wait(0.02) -- Микро-пауза для стабилизации физики персонажа
                end
            end

            -- Твой оригинальный вызов закупки
            local targetEgg = getNearestCustomEgg()
            local maxAmount = EggCmds.GetMaxHatch()
            
            if targetEgg then
                pcall(function()
                    ReplicatedStorage.Network.CustomEggs_Hatch:InvokeServer(targetEgg, maxAmount)
                end)
            end
        end
        task.wait(0.3) -- Твоя оригинальная задержка
    end
end)


print("[GlassScripts] Скрипт успешно собран, полностью автономен и готов к работе!")
