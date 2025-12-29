--[[
    ZL MODS - CORRUPT ZOMBIES v15.0 (FINAL RELEASE)
    - Rapid Fire Removido
    - Intro Sequencial (Intro -> Menu)
    - Farm F1 Estável
    - Player Mods & Unlock Map
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local Player = Players.LocalPlayer

-- ==================== CONFIGURAÇÕES ====================
local Config = {
    Aimbot = false,
    FovRadius = 150,
    Farm = false, -- F1
    AimKey = Enum.UserInputType.MouseButton2,
    MenuOpen = false, -- Começa fechado para a intro
    
    -- Player
    Fly = false,
    FlySpeed = 50,
    SpeedEnabled = false,
    WalkSpeed = 50, 
    JumpEnabled = false,
    JumpPower = 100,
    Noclip = false
}

local EspCache = {}
local RgbObjects = {Strokes = {}, Texts = {}} 

-- ==================== UI SETUP ====================
local CoreGui = game:GetService("CoreGui") or Player:WaitForChild("PlayerGui")

for _, v in pairs(CoreGui:GetChildren()) do
    if v.Name == "ZLModsHub" or v.Name == "ZLIntro" then v:Destroy() end
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZLModsHub"
ScreenGui.ResetOnSpawn = false
ScreenGui.DisplayOrder = 10000
ScreenGui.Parent = CoreGui

local function GetRainbowColor()
    local hue = tick() * 0.5 % 1
    return Color3.fromHSV(hue, 1, 1)
end

-- ==================== UI PRINCIPAL ====================
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 600, 0, 450)
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -225)
MainFrame.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
MainFrame.BorderSizePixel = 0
MainFrame.Visible = false -- IMPORTANTE: Começa invisível
MainFrame.Active = true
MainFrame.Draggable = true
MainFrame.Parent = ScreenGui

local MainStroke = Instance.new("UIStroke")
MainStroke.Thickness = 3
MainStroke.Color = Color3.fromRGB(255, 0, 0)
MainStroke.Parent = MainFrame
table.insert(RgbObjects.Strokes, MainStroke) -- RGB apenas na borda do menu

Instance.new("UICorner", MainFrame).CornerRadius = UDim.new(0, 10)

-- Título
local Title = Instance.new("TextLabel")
Title.Text = "ZL MODS // CORRUPT ZOMBIES"
Title.Size = UDim2.new(1, -20, 0, 40)
Title.Position = UDim2.new(0, 20, 0, 0)
Title.BackgroundTransparency = 1
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 20
Title.TextColor3 = Color3.new(1,1,1)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Parent = MainFrame
table.insert(RgbObjects.Texts, Title)

-- Sidebar
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 140, 1, -50)
Sidebar.Position = UDim2.new(0, 10, 0, 45)
Sidebar.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
Sidebar.Parent = MainFrame
Instance.new("UICorner", Sidebar).CornerRadius = UDim.new(0, 8)

local TabList = Instance.new("UIListLayout")
TabList.Parent = Sidebar
TabList.Padding = UDim.new(0, 5)
TabList.SortOrder = Enum.SortOrder.LayoutOrder

local PagesContainer = Instance.new("Frame")
PagesContainer.Size = UDim2.new(1, -170, 1, -50)
PagesContainer.Position = UDim2.new(0, 160, 0, 45)
PagesContainer.BackgroundTransparency = 1
PagesContainer.Parent = MainFrame

-- ==================== BOTÃO FLUTUANTE (FIXO) ====================
local FloatBtn = Instance.new("TextButton")
FloatBtn.Name = "ZLFloat"
FloatBtn.Size = UDim2.new(0, 60, 0, 60)
FloatBtn.Position = UDim2.new(0.1, 0, 0.2, 0)
FloatBtn.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
FloatBtn.Text = "ZL"
FloatBtn.Font = Enum.Font.GothamBlack
FloatBtn.TextColor3 = Color3.new(1,1,1)
FloatBtn.TextSize = 28
FloatBtn.Visible = false -- Começa invisível
FloatBtn.Active = true
FloatBtn.Draggable = true
FloatBtn.Parent = ScreenGui
Instance.new("UICorner", FloatBtn).CornerRadius = UDim.new(1,0) -- Redondo

local FloatStroke = Instance.new("UIStroke")
FloatStroke.Thickness = 3
FloatStroke.Color = Color3.fromRGB(255, 255, 255) -- Borda Branca Fixa
FloatStroke.Parent = FloatBtn

-- ==================== FOV (FIXO) ====================
local FovRing = Instance.new("Frame")
FovRing.Size = UDim2.new(0, Config.FovRadius*2, 0, Config.FovRadius*2)
FovRing.AnchorPoint = Vector2.new(0.5, 0.5)
FovRing.Position = UDim2.new(0.5,0,0.5,0)
FovRing.BackgroundTransparency = 1
FovRing.Visible = false
FovRing.Parent = ScreenGui

local RingStr = Instance.new("UIStroke")
RingStr.Thickness = 1
RingStr.Color = Color3.fromRGB(255, 0, 0) -- Vermelho Fixo
RingStr.Parent = FovRing

Instance.new("UICorner", FovRing).CornerRadius = UDim.new(1,0)

-- ==================== HELPER FUNCTIONS ====================
local Tabs = {}

local function CreateTab(name)
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1, 0, 0, 40)
    Btn.BackgroundTransparency = 1
    Btn.Text = name
    Btn.TextColor3 = Color3.fromRGB(150, 150, 150)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 14
    Btn.Parent = Sidebar

    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.ScrollBarThickness = 3
    Page.Visible = false
    Page.Parent = PagesContainer
    Instance.new("UIListLayout", Page).Padding = UDim.new(0, 8)
    
    Btn.MouseButton1Click:Connect(function()
        for _, t in pairs(Tabs) do 
            t.Btn.TextColor3 = Color3.fromRGB(150,150,150)
            t.Page.Visible = false
        end
        Btn.TextColor3 = Color3.new(1,1,1)
        Page.Visible = true
    end)
    table.insert(Tabs, {Btn=Btn, Page=Page})
    return Page
end

local function CreateSection(page, text)
    local L = Instance.new("TextLabel")
    L.Size = UDim2.new(1, 0, 0, 25)
    L.BackgroundTransparency = 1
    L.Text = "  > " .. text
    L.TextColor3 = Color3.new(1,1,1)
    L.Font = Enum.Font.GothamBlack
    L.TextSize = 14
    L.TextXAlignment = Enum.TextXAlignment.Left
    L.Parent = page
    table.insert(RgbObjects.Texts, L)
end

local function CreateButton(page, text, callback)
    local Holder = Instance.new("Frame")
    Holder.Size = UDim2.new(1, -10, 0, 35)
    Holder.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    Holder.Parent = page
    Instance.new("UICorner", Holder).CornerRadius = UDim.new(0, 6)
    
    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1,0,1,0)
    Btn.BackgroundTransparency = 1
    Btn.Text = text
    Btn.TextColor3 = Color3.fromRGB(220, 220, 220)
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 13
    Btn.Parent = Holder
    
    local S = Instance.new("UIStroke")
    S.Color = Color3.fromRGB(60,60,60)
    S.Thickness = 1
    S.Parent = Holder
    
    Btn.MouseButton1Click:Connect(function()
        if callback then pcall(callback) end
    end)
end

local function CreateToggleButton(page, title, configKey, callback)
    local Holder = Instance.new("Frame")
    Holder.Size = UDim2.new(1, -10, 0, 35)
    Holder.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Holder.Parent = page
    Instance.new("UICorner", Holder).CornerRadius = UDim.new(0, 6)
    
    local S = Instance.new("UIStroke")
    S.Thickness = 1
    S.Parent = Holder

    local Btn = Instance.new("TextButton")
    Btn.Size = UDim2.new(1,0,1,0)
    Btn.BackgroundTransparency = 1
    Btn.Font = Enum.Font.GothamBold
    Btn.TextSize = 13
    Btn.Parent = Holder

    local function UpdateState()
        if Config[configKey] then
            Btn.Text = title .. ": ON"
            Btn.TextColor3 = Color3.fromRGB(0, 255, 100)
            S.Color = Color3.fromRGB(0, 200, 80)
        else
            Btn.Text = title .. ": OFF"
            Btn.TextColor3 = Color3.fromRGB(150, 150, 150)
            S.Color = Color3.fromRGB(60, 60, 60)
        end
    end

    Btn.MouseButton1Click:Connect(function()
        Config[configKey] = not Config[configKey]
        UpdateState()
        if callback then pcall(callback, Config[configKey]) end
    end)
    UpdateState()
end

local function CreateControl(page, title, valueKey, step, suffix)
    local Holder = Instance.new("Frame")
    Holder.Size = UDim2.new(1, -10, 0, 40)
    Holder.BackgroundColor3 = Color3.fromRGB(30, 30, 35)
    Holder.Parent = page
    Instance.new("UICorner", Holder).CornerRadius = UDim.new(0, 6)
    
    local TitleL = Instance.new("TextLabel")
    TitleL.Size = UDim2.new(0.5, 0, 1, 0)
    TitleL.Position = UDim2.new(0, 10, 0, 0)
    TitleL.BackgroundTransparency = 1
    TitleL.Text = title .. ": " .. Config[valueKey] .. (suffix or "")
    TitleL.TextColor3 = Color3.new(1,1,1)
    TitleL.Font = Enum.Font.GothamBold
    TitleL.TextSize = 12
    TitleL.TextXAlignment = Enum.TextXAlignment.Left
    TitleL.Parent = Holder
    
    local Minus = Instance.new("TextButton")
    Minus.Size = UDim2.new(0, 30, 0, 30)
    Minus.Position = UDim2.new(1, -70, 0.5, -15)
    Minus.BackgroundColor3 = Color3.fromRGB(50, 20, 20)
    Minus.Text = "-"
    Minus.TextColor3 = Color3.new(1,1,1)
    Minus.Parent = Holder
    Instance.new("UICorner", Minus).CornerRadius = UDim.new(0,4)
    
    local Plus = Instance.new("TextButton")
    Plus.Size = UDim2.new(0, 30, 0, 30)
    Plus.Position = UDim2.new(1, -35, 0.5, -15)
    Plus.BackgroundColor3 = Color3.fromRGB(20, 50, 20)
    Plus.Text = "+"
    Plus.TextColor3 = Color3.new(1,1,1)
    Plus.Parent = Holder
    Instance.new("UICorner", Plus).CornerRadius = UDim.new(0,4)
    
    Minus.MouseButton1Click:Connect(function()
        Config[valueKey] = Config[valueKey] - step
        TitleL.Text = title .. ": " .. Config[valueKey] .. (suffix or "")
    end)
    Plus.MouseButton1Click:Connect(function()
        Config[valueKey] = Config[valueKey] + step
        TitleL.Text = title .. ": " .. Config[valueKey] .. (suffix or "")
    end)
end

-- ==================== ABAS ====================

-- 1. COMBATE
local P_Combat = CreateTab("COMBATE")
CreateSection(P_Combat, "Assistência")
CreateToggleButton(P_Combat, "Aimbot", "Aimbot", function(state) FovRing.Visible = state end)

CreateSection(P_Combat, "FOV")
CreateButton(P_Combat, "Aumentar (+)", function()
    Config.FovRadius = math.clamp(Config.FovRadius + 10, 20, 800)
    FovRing.Size = UDim2.new(0, Config.FovRadius*2, 0, Config.FovRadius*2)
end)
CreateButton(P_Combat, "Diminuir (-)", function()
    Config.FovRadius = math.clamp(Config.FovRadius - 10, 20, 800)
    FovRing.Size = UDim2.new(0, Config.FovRadius*2, 0, Config.FovRadius*2)
end)

-- 2. VISUAL
local P_Visual = CreateTab("VISUAL")
CreateSection(P_Visual, "ESP")
CreateButton(P_Visual, "ESP Ligado (Auto)", function() end)

-- 3. PLAYER
local P_Player = CreateTab("PLAYER")
CreateSection(P_Player, "Fly")
CreateToggleButton(P_Player, "Ativar Fly", "Fly", function(state)
    if not state and Player.Character and Player.Character:FindFirstChild("HumanoidRootPart") then
        Player.Character.HumanoidRootPart.AssemblyLinearVelocity = Vector3.new(0,0,0)
    end
end)
CreateControl(P_Player, "Velocidade", "FlySpeed", 10)

CreateSection(P_Player, "Movimento")
CreateToggleButton(P_Player, "Speed Hack", "SpeedEnabled", function(state)
    if not state and Player.Character then Player.Character.Humanoid.WalkSpeed = 16 end
end)
CreateControl(P_Player, "Força", "WalkSpeed", 5)

CreateToggleButton(P_Player, "Super Pulo", "JumpEnabled", function(state)
    if not state and Player.Character then Player.Character.Humanoid.JumpPower = 50 end
end)
CreateControl(P_Player, "Força", "JumpPower", 10)

CreateSection(P_Player, "Outros")
CreateToggleButton(P_Player, "Noclip", "Noclip")

-- 4. MISC (LIMPO)
local P_Misc = CreateTab("MISC")
CreateSection(P_Misc, "Farming")
CreateToggleButton(P_Misc, "FARM F1 (ESTÁVEL)", "Farm")

CreateSection(P_Misc, "Mundo")
CreateButton(P_Misc, "DESBLOQUEAR MAPA", function()
    local map = Workspace:FindFirstChild("MapFolder")
    if map then
        if map:FindFirstChild("Doors") then map.Doors:ClearAllChildren() end
        if map:FindFirstChild("Barriers") then map.Barriers:ClearAllChildren() end
        game.StarterGui:SetCore("SendNotification", {Title="Sucesso", Text="Portas removidas!"})
    end
end)

-- 5. CRÉDITOS (BOTÃO UNICO)
local P_Creds = CreateTab("CRÉDITOS")
CreateSection(P_Creds, "Desenvolvedor")

CreateButton(P_Creds, "CRIADOR: ZL MODS (COPIAR DISCORD)", function()
    if setclipboard then
        setclipboard("https://discord.gg/vq2F6fUtXQ")
        game.StarterGui:SetCore("SendNotification", {Title="ZL Mods", Text="Discord Copiado!"})
    else
        game.StarterGui:SetCore("SendNotification", {Title="Erro", Text="Seu executor não suporta Copiar."})
    end
end)

-- ==================== LÓGICA DO JOGO ====================
local function HandleESP(model)
    pcall(function()
        if not model or EspCache[model] then return end
        local head = model:FindFirstChild("Head")
        if not head then return end
        local h = Instance.new("Highlight")
        h.FillColor = Color3.fromRGB(255, 0, 0)
        h.OutlineColor = Color3.new(1,1,1)
        h.FillTransparency = 0.5
        h.Parent = model
        EspCache[model] = h
    end)
end

RunService.RenderStepped:Connect(function()
    pcall(function()
        -- RGB apenas no MainFrame e Título
        local rgb = GetRainbowColor()
        for _, v in pairs(RgbObjects.Strokes) do v.Color = rgb end
        for _, v in pairs(RgbObjects.Texts) do v.TextColor3 = rgb end
        
        local char = Player.Character
        local hrp = char and char:FindFirstChild("HumanoidRootPart")
        local hum = char and char:FindFirstChild("Humanoid")

        -- PLAYER MODS
        if char and hrp and hum then
            if Config.Fly then
                local camCF = Camera.CFrame
                local vel = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then vel = vel + camCF.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then vel = vel - camCF.LookVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then vel = vel - camCF.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then vel = vel + camCF.RightVector end
                if UserInputService:IsKeyDown(Enum.KeyCode.Space) then vel = vel + Vector3.yAxis end
                if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then vel = vel - Vector3.yAxis end
                hrp.AssemblyLinearVelocity = vel * Config.FlySpeed
                hum.PlatformStand = true 
            elseif not Config.Farm then
                hum.PlatformStand = false
            end

            if Config.SpeedEnabled then hum.WalkSpeed = Config.WalkSpeed end
            if Config.JumpEnabled then hum.UseJumpPower = true; hum.JumpPower = Config.JumpPower end
            if Config.Noclip then
                for _, p in pairs(char:GetChildren()) do
                    if p:IsA("BasePart") then p.CanCollide = false end
                end
            end
        end

        -- ZOMBIE LOGIC
        local zFolder = Workspace:FindFirstChild("Zombies")
        if zFolder then
            for _, z in pairs(zFolder:GetChildren()) do
                if z:FindFirstChild("Head") and z:FindFirstChild("Humanoid") and z.Humanoid.Health > 0 then
                    HandleESP(z)
                    local zRoot = z:FindFirstChild("HumanoidRootPart")
                    local zHum = z.Humanoid
                    
                    -- FARM F1 (ESTÁVEL)
                    if Config.Farm and zRoot and hrp then
                        for _, p in pairs(z:GetChildren()) do
                            if p:IsA("BasePart") then 
                                p.CanCollide = false 
                                p.Massless = true 
                            end
                        end
                        zHum.PlatformStand = true
                        zHum.WalkSpeed = 0
                        zRoot.Anchored = true 
                        zRoot.CFrame = hrp.CFrame * CFrame.new(0, 0, -5)
                    elseif not Config.Farm and zRoot and zRoot.Anchored then
                        zRoot.Anchored = false
                        zHum.PlatformStand = false
                        zHum.WalkSpeed = 16
                    end
                end
            end
        end

        -- Limpar Cache
        for m, e in pairs(EspCache) do
            if not m.Parent or m.Humanoid.Health <= 0 then
                e:Destroy()
                EspCache[m] = nil
            end
        end
        
        -- Aimbot
        if Config.Aimbot and (UserInputService:IsMouseButtonPressed(Config.AimKey) or UserInputService:IsKeyDown(Config.AimKey)) then
            local closest, minDist = nil, Config.FovRadius
            local center = Camera.ViewportSize/2
            for m, _ in pairs(EspCache) do
                if m:FindFirstChild("Head") then
                    local pos, vis = Camera:WorldToViewportPoint(m.Head.Position)
                    if vis then
                        local dist = (Vector2.new(pos.X, pos.Y) - center).Magnitude
                        if dist < minDist then minDist=dist; closest=m end
                    end
                end
            end
            if closest then
                Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, closest.Head.Position), 0.5)
            end
        end
    end)
end)

-- ==================== TOGGLE & INTRO (SEQUÊNCIA CORRETA) ====================
local function Toggle(state)
    Config.MenuOpen = state
    MainFrame.Visible = state
    FloatBtn.Visible = not state
end

UserInputService.InputBegan:Connect(function(io, gp)
    if io.KeyCode == Enum.KeyCode.Insert then Toggle(not Config.MenuOpen) end
    if io.KeyCode == Enum.KeyCode.F1 then Config.Farm = not Config.Farm end
end)

FloatBtn.MouseButton1Click:Connect(function() Toggle(true) end)
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.BackgroundTransparency = 1
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1,1,1)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Parent = MainFrame
CloseBtn.MouseButton1Click:Connect(function() Toggle(false) end)

-- INTRODUÇÃO SEGURA E SEQUENCIAL
task.spawn(function()
    local IntroGui = Instance.new("ScreenGui")
    IntroGui.Name = "ZLIntro"
    IntroGui.DisplayOrder = 10001
    IntroGui.Parent = CoreGui

    local Text = Instance.new("TextLabel")
    Text.Size = UDim2.new(1, 0, 1, 0)
    Text.BackgroundTransparency = 1
    Text.Text = "ZL MODS"
    Text.Font = Enum.Font.GothamBlack
    Text.TextSize = 0
    Text.TextColor3 = Color3.new(1, 1, 1)
    Text.Parent = IntroGui
    
    local S = Instance.new("UIStroke")
    S.Thickness = 3
    S.Color = Color3.new(0,0,0)
    S.Parent = Text

    -- Animação de Entrada
    local t1 = TweenService:Create(Text, TweenInfo.new(1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {TextSize = 90})
    t1:Play()
    t1.Completed:Wait()
    
    -- Espera 1.5s com o texto na tela
    wait(1.5)
    
    -- Animação de Saída
    local t2 = TweenService:Create(Text, TweenInfo.new(0.5), {TextTransparency = 1})
    t2:Play()
    t2.Completed:Wait()
    
    -- Destroi a Intro e ABRE O MENU
    IntroGui:Destroy()
    Toggle(true) 
end)

-- Abre a primeira aba automaticamente (após o menu ficar visível)
if Tabs[1] then Tabs[1].Btn.TextColor3 = Color3.new(1,1,1); Tabs[1].Page.Visible = true end
