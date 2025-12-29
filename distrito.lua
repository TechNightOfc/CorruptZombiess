-- ==========================================================
--  ZL MODS | KORRUPT ZOMBIES - V5.0 (REMASTERED UI)
-- ==========================================================

-- [1] SERVIÇOS
local Players          = game:GetService("Players")
local RunService       = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService     = game:GetService("TweenService")
local VirtualUser      = game:GetService("VirtualUser")
local CoreGui          = game:GetService("CoreGui")
local Camera           = workspace.CurrentCamera
local LocalPlayer      = Players.LocalPlayer

-- [2] CONFIGURAÇÕES (Variáveis de Controle)
local Config = {
    KillAura     = false,
    ManualTP     = false,
    -- Visuais
    ESP_Box      = false,
    ESP_Name     = false,
    ESP_Health   = false,
    ESP_Line     = false,
    -- Exploits
    Speed_Active = false,
    Speed_Value  = 16,
    Jump_Active  = false,
    Jump_Value   = 50,
    Fly_Active   = false,
    Fly_Speed    = 50,
    Noclip       = false,
    GodMode      = false
}

local SelectedTarget = nil
local ESP_Cache = {}

-- [3] TEMA & ESTILO
local Theme = {
    Background  = Color3.fromRGB(15, 15, 20),      -- Fundo Principal
    Sidebar     = Color3.fromRGB(20, 20, 25),      -- Barra Lateral
    Element     = Color3.fromRGB(28, 28, 35),      -- Elementos/Botões
    Accent      = Color3.fromRGB(140, 0, 255),     -- Cor Principal (Roxo Neon)
    AccentGrad  = Color3.fromRGB(100, 0, 200),     -- Gradiente do Roxo
    GreenESP    = Color3.fromRGB(0, 255, 120),     -- Verde Neon (ESP)
    Red         = Color3.fromRGB(255, 60, 60),     -- Vermelho
    Text        = Color3.fromRGB(240, 240, 240),   -- Texto Branco
    TextDark    = Color3.fromRGB(140, 140, 150)    -- Texto Cinza
}

-- [4] FUNÇÕES AUXILIARES (UI)
local function MakeDraggable(frame, handle)
    local dragging, dragInput, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            TweenService:Create(frame, TweenInfo.new(0.05), {
                Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            }):Play()
        end
    end)
end

local function CreateCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius)
    corner.Parent = parent
    return corner
end

local function CreateStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color
    stroke.Thickness = thickness
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = parent
    return stroke
end

-- [5] INTERFACE PRINCIPAL
-- Remove interface antiga se existir
if game.CoreGui:FindFirstChild("ZL_Mods_V5_Remaster") then
    game.CoreGui.ZL_Mods_V5_Remaster:Destroy()
end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "ZL_Mods_V5_Remaster"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

-- Proteção GUI
if syn and syn.protect_gui then syn.protect_gui(ScreenGui) ScreenGui.Parent = CoreGui
elseif getgenv and getgenv().gethui then ScreenGui.Parent = getgenv().gethui()
else ScreenGui.Parent = LocalPlayer:WaitForChild("PlayerGui") end

-- > BOTÃO FLUTUANTE (MINIMIZADO)
local OpenBtn = Instance.new("TextButton")
OpenBtn.Name = "OpenIcon"
OpenBtn.Size = UDim2.new(0, 50, 0, 50)
OpenBtn.Position = UDim2.new(0.02, 0, 0.5, -25)
OpenBtn.BackgroundColor3 = Theme.Sidebar
OpenBtn.Text = "ZL"
OpenBtn.TextColor3 = Theme.Accent
OpenBtn.Font = Enum.Font.GothamBlack
OpenBtn.TextSize = 22
OpenBtn.Visible = false
OpenBtn.Parent = ScreenGui
CreateCorner(OpenBtn, 12)
CreateStroke(OpenBtn, Theme.Accent, 2)
MakeDraggable(OpenBtn, OpenBtn)

-- > JANELA PRINCIPAL
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Size = UDim2.new(0, 600, 0, 380)
MainFrame.Position = UDim2.new(0.5, -300, 0.5, -190)
MainFrame.BackgroundColor3 = Theme.Background
MainFrame.BorderSizePixel = 0
MainFrame.ClipsDescendants = false
MainFrame.Parent = ScreenGui
CreateCorner(MainFrame, 10)
CreateStroke(MainFrame, Theme.Element, 1)

-- Sombra
local Shadow = Instance.new("ImageLabel", MainFrame)
Shadow.Name = "Shadow"
Shadow.AnchorPoint = Vector2.new(0.5, 0.5)
Shadow.Position = UDim2.new(0.5, 0, 0.5, 0)
Shadow.Size = UDim2.new(1, 140, 1, 140)
Shadow.BackgroundTransparency = 1
Shadow.Image = "rbxassetid://6015897843"
Shadow.ImageColor3 = Color3.new(0, 0, 0)
Shadow.ImageTransparency = 0.4
Shadow.ZIndex = -1

-- > BARRA LATERAL (SIDEBAR)
local Sidebar = Instance.new("Frame")
Sidebar.Size = UDim2.new(0, 160, 1, 0)
Sidebar.BackgroundColor3 = Theme.Sidebar
Sidebar.BorderSizePixel = 0
Sidebar.Parent = MainFrame
CreateCorner(Sidebar, 10)

-- Correção visual (tampa o canto arredondado direito da sidebar)
local SidebarFix = Instance.new("Frame", Sidebar)
SidebarFix.Size = UDim2.new(0, 20, 1, 0)
SidebarFix.Position = UDim2.new(1, -10, 0, 0)
SidebarFix.BackgroundColor3 = Theme.Sidebar
SidebarFix.BorderSizePixel = 0
SidebarFix.ZIndex = 0

-- Gradiente na Sidebar
local SideGradient = Instance.new("UIGradient", Sidebar)
SideGradient.Rotation = 45
SideGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Theme.Sidebar),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 15, 20))
}

-- Título
local Title = Instance.new("TextLabel")
Title.Text = "ZL MODS"
Title.Size = UDim2.new(1, 0, 0, 40)
Title.Position = UDim2.new(0, 0, 0, 15)
Title.BackgroundTransparency = 1
Title.TextColor3 = Theme.Accent
Title.Font = Enum.Font.GothamBlack
Title.TextSize = 26
Title.Parent = Sidebar

local SubTitle = Instance.new("TextLabel")
SubTitle.Text = "V5.0 ULTIMATE"
SubTitle.Size = UDim2.new(1, 0, 0, 20)
SubTitle.Position = UDim2.new(0, 0, 0, 42)
SubTitle.BackgroundTransparency = 1
SubTitle.TextColor3 = Theme.TextDark
SubTitle.Font = Enum.Font.GothamBold
SubTitle.TextSize = 11
SubTitle.Parent = Sidebar

-- Container de Abas
local TabContainer = Instance.new("Frame")
TabContainer.Size = UDim2.new(1, 0, 1, -80)
TabContainer.Position = UDim2.new(0, 0, 0, 80)
TabContainer.BackgroundTransparency = 1
TabContainer.ZIndex = 2
TabContainer.Parent = Sidebar
local TabList = Instance.new("UIListLayout", TabContainer)
TabList.Padding = UDim.new(0, 6)
TabList.HorizontalAlignment = Enum.HorizontalAlignment.Center

-- > CONTEÚDO
local PageContainer = Instance.new("Frame")
PageContainer.Size = UDim2.new(1, -170, 1, -20)
PageContainer.Position = UDim2.new(0, 170, 0, 10)
PageContainer.BackgroundTransparency = 1
PageContainer.ClipsDescendants = true
PageContainer.Parent = MainFrame

-- > BOTÃO FECHAR
local CloseBtn = Instance.new("TextButton")
CloseBtn.Size = UDim2.new(0, 24, 0, 24)
CloseBtn.Position = UDim2.new(1, -30, 0, 10)
CloseBtn.BackgroundColor3 = Theme.Red
CloseBtn.Text = "×"
CloseBtn.TextColor3 = Theme.Text
CloseBtn.Font = Enum.Font.GothamBlack
CloseBtn.TextSize = 18
CloseBtn.AutoButtonColor = true
CloseBtn.Parent = MainFrame
CreateCorner(CloseBtn, 6)

CloseBtn.MouseButton1Click:Connect(function()
    MainFrame.Visible = false
    OpenBtn.Visible = true
end)
OpenBtn.MouseButton1Click:Connect(function()
    OpenBtn.Visible = false
    MainFrame.Visible = true
end)

-- Sistema de arrastar na barra lateral
MakeDraggable(MainFrame, Sidebar)

-- [6] SISTEMA DE COMPONENTES (UI BUILDER)
local Tabs = {}

local function CreateTab(name, iconID)
    local TabBtn = Instance.new("TextButton")
    TabBtn.Size = UDim2.new(0.85, 0, 0, 36)
    TabBtn.BackgroundColor3 = Theme.Background
    TabBtn.BackgroundTransparency = 1
    TabBtn.Text = "  " .. name
    TabBtn.TextColor3 = Theme.TextDark
    TabBtn.Font = Enum.Font.GothamBold
    TabBtn.TextSize = 13
    TabBtn.TextXAlignment = Enum.TextXAlignment.Left
    TabBtn.AutoButtonColor = false
    TabBtn.Parent = TabContainer
    CreateCorner(TabBtn, 6)

    -- Barra indicadora (lado esquerdo)
    local Indicator = Instance.new("Frame", TabBtn)
    Indicator.Size = UDim2.new(0, 3, 0.6, 0)
    Indicator.Position = UDim2.new(0, 0, 0.2, 0)
    Indicator.BackgroundColor3 = Theme.Accent
    Indicator.Visible = false
    CreateCorner(Indicator, 4)

    -- Página de Scroll
    local Page = Instance.new("ScrollingFrame")
    Page.Size = UDim2.new(1, 0, 1, 0)
    Page.BackgroundTransparency = 1
    Page.ScrollBarThickness = 2
    Page.ScrollBarImageColor3 = Theme.Accent
    Page.Visible = false
    Page.Parent = PageContainer
    local PList = Instance.new("UIListLayout", Page)
    PList.Padding = UDim.new(0, 8)
    PList.SortOrder = Enum.SortOrder.LayoutOrder

    -- Padding interno
    local PPad = Instance.new("UIPadding", Page)
    PPad.PaddingTop = UDim.new(0, 5)
    PPad.PaddingLeft = UDim.new(0, 0)
    PPad.PaddingRight = UDim.new(0, 6)

    TabBtn.MouseButton1Click:Connect(function()
        -- Resetar todas as abas
        for _, t in pairs(Tabs) do
            TweenService:Create(t.Btn, TweenInfo.new(0.2), {BackgroundTransparency = 1, TextColor3 = Theme.TextDark}):Play()
            t.Page.Visible = false
            t.Ind.Visible = false
        end
        -- Ativar atual
        TweenService:Create(TabBtn, TweenInfo.new(0.2), {BackgroundTransparency = 0.9, TextColor3 = Theme.Text}):Play()
        TabBtn.BackgroundColor3 = Theme.Accent -- Usado apenas com transparency 0.9
        Page.Visible = true
        Indicator.Visible = true
    end)

    table.insert(Tabs, {Btn = TabBtn, Page = Page, Ind = Indicator})
    return Page
end

local function CreateSection(parent, text)
    local Section = Instance.new("Frame")
    Section.Size = UDim2.new(1, 0, 0, 30)
    Section.BackgroundTransparency = 1
    Section.Parent = parent

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, 0, 1, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Theme.Accent
    Label.Font = Enum.Font.GothamBlack
    Label.TextSize = 14
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Parent = Section
    
    local Line = Instance.new("Frame", Section)
    Line.Size = UDim2.new(1, 0, 0, 1)
    Line.Position = UDim2.new(0, 0, 1, -2)
    Line.BackgroundColor3 = Theme.Element
    Line.BorderSizePixel = 0
end

local function CreateToggle(parent, text, default, callback)
    local ToggleFrame = Instance.new("Frame")
    ToggleFrame.Size = UDim2.new(1, 0, 0, 42)
    ToggleFrame.BackgroundColor3 = Theme.Element
    ToggleFrame.Parent = parent
    CreateCorner(ToggleFrame, 6)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(0.7, 0, 1, 0)
    Label.Position = UDim2.new(0, 12, 0, 0)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 13
    Label.Parent = ToggleFrame

    local SwitchBG = Instance.new("TextButton")
    SwitchBG.Size = UDim2.new(0, 44, 0, 22)
    SwitchBG.Position = UDim2.new(1, -56, 0.5, -11)
    SwitchBG.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    SwitchBG.Text = ""
    SwitchBG.AutoButtonColor = false
    SwitchBG.Parent = ToggleFrame
    local SwitchCorner = CreateCorner(SwitchBG, 100)

    local Circle = Instance.new("Frame", SwitchBG)
    Circle.Size = UDim2.new(0, 18, 0, 18)
    Circle.Position = UDim2.new(0, 2, 0.5, -9)
    Circle.BackgroundColor3 = Theme.TextDark
    CreateCorner(Circle, 100)

    local toggled = default
    
    -- Função de animação
    local function UpdateToggle()
        if toggled then
            TweenService:Create(SwitchBG, TweenInfo.new(0.2), {BackgroundColor3 = Theme.Accent}):Play()
            TweenService:Create(Circle, TweenInfo.new(0.2), {Position = UDim2.new(1, -20, 0.5, -9), BackgroundColor3 = Theme.Text}):Play()
        else
            TweenService:Create(SwitchBG, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 45)}):Play()
            TweenService:Create(Circle, TweenInfo.new(0.2), {Position = UDim2.new(0, 2, 0.5, -9), BackgroundColor3 = Theme.TextDark}):Play()
        end
        callback(toggled)
    end

    SwitchBG.MouseButton1Click:Connect(function()
        toggled = not toggled
        UpdateToggle()
    end)
    
    -- Inicializa
    if default then UpdateToggle() end
end

local function CreateSlider(parent, text, min, max, default, callback)
    local SliderFrame = Instance.new("Frame")
    SliderFrame.Size = UDim2.new(1, 0, 0, 50)
    SliderFrame.BackgroundColor3 = Theme.Element
    SliderFrame.Parent = parent
    CreateCorner(SliderFrame, 6)

    local Label = Instance.new("TextLabel")
    Label.Size = UDim2.new(1, -24, 0, 20)
    Label.Position = UDim2.new(0, 12, 0, 5)
    Label.BackgroundTransparency = 1
    Label.Text = text
    Label.TextColor3 = Theme.Text
    Label.TextXAlignment = Enum.TextXAlignment.Left
    Label.Font = Enum.Font.GothamBold
    Label.TextSize = 13
    Label.Parent = SliderFrame

    local ValueLabel = Instance.new("TextLabel")
    ValueLabel.Size = UDim2.new(0, 50, 0, 20)
    ValueLabel.Position = UDim2.new(1, -60, 0, 5)
    ValueLabel.BackgroundTransparency = 1
    ValueLabel.Text = tostring(default)
    ValueLabel.TextColor3 = Theme.Accent
    ValueLabel.Font = Enum.Font.GothamBold
    ValueLabel.TextSize = 13
    ValueLabel.TextXAlignment = Enum.TextXAlignment.Right
    ValueLabel.Parent = SliderFrame

    local BarBG = Instance.new("TextButton")
    BarBG.Size = UDim2.new(1, -24, 0, 6)
    BarBG.Position = UDim2.new(0, 12, 0, 32)
    BarBG.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    BarBG.Text = ""
    BarBG.AutoButtonColor = false
    BarBG.Parent = SliderFrame
    CreateCorner(BarBG, 3)

    local Fill = Instance.new("Frame", BarBG)
    Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
    Fill.BackgroundColor3 = Theme.Accent
    Fill.BorderSizePixel = 0
    CreateCorner(Fill, 3)

    local dragging = false

    local function UpdateSlider(input)
        local pos = UDim2.new(math.clamp((input.Position.X - BarBG.AbsolutePosition.X) / BarBG.AbsoluteSize.X, 0, 1), 0, 1, 0)
        TweenService:Create(Fill, TweenInfo.new(0.1), {Size = pos}):Play()
        
        local val = math.floor(((pos.X.Scale * (max - min)) + min))
        ValueLabel.Text = tostring(val)
        callback(val)
    end

    BarBG.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = true
            UpdateSlider(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
            UpdateSlider(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            dragging = false
        end
    end)
end

-- [7] CONSTRUÇÃO DAS ABAS (LÓGICA DO JOGO)

-- === ABA COMBATE ===
local CombatTab = CreateTab("COMBATE")

CreateSection(CombatTab, "ALVO & SELEÇÃO")
local TargetLabel = Instance.new("TextLabel")
TargetLabel.Size = UDim2.new(1, 0, 0, 20)
TargetLabel.BackgroundTransparency = 1
TargetLabel.Text = "Nenhum alvo selecionado"
TargetLabel.TextColor3 = Theme.TextDark
TargetLabel.Font = Enum.Font.Gotham
TargetLabel.TextSize = 12
TargetLabel.Parent = CombatTab

local PScroll = Instance.new("ScrollingFrame")
PScroll.Size = UDim2.new(1, 0, 0, 100)
PScroll.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
PScroll.Parent = CombatTab
CreateCorner(PScroll, 6)
local PL = Instance.new("UIListLayout", PScroll) PL.Padding = UDim.new(0, 2)

local function RefreshList()
    for _,v in pairs(PScroll:GetChildren()) do if v:IsA("TextButton") then v:Destroy() end end
    for _,p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then
            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 0, 28)
            Btn.BackgroundColor3 = Color3.fromRGB(28, 28, 35)
            Btn.Text = p.DisplayName
            Btn.TextColor3 = Theme.Text
            Btn.Font = Enum.Font.Gotham
            Btn.TextSize = 12
            Btn.Parent = PScroll
            
            Btn.MouseButton1Click:Connect(function()
                SelectedTarget = p
                TargetLabel.Text = "Alvo Atual: " .. p.DisplayName
                TargetLabel.TextColor3 = Theme.GreenESP
            end)
        end
    end
end
CreateToggle(CombatTab, "Atualizar Lista de Jogadores", false, function() RefreshList() end)
RefreshList()

-- Funções de Combate
local function HeadStomp()
    if SelectedTarget and SelectedTarget.Character and SelectedTarget.Character:FindFirstChild("HumanoidRootPart") then
        local MyChar = LocalPlayer.Character
        if MyChar and MyChar:FindFirstChild("HumanoidRootPart") then
            MyChar.HumanoidRootPart.CFrame = SelectedTarget.Character.HumanoidRootPart.CFrame * CFrame.new(0, 3.5, 0)
            MyChar.HumanoidRootPart.CFrame = CFrame.lookAt(MyChar.HumanoidRootPart.Position, SelectedTarget.Character.HumanoidRootPart.Position)
        end
    end
end

CreateSection(CombatTab, "AUTOMAÇÃO")

CreateToggle(CombatTab, "TP Manual (Cabeça)", false, function(state)
    Config.ManualTP = state
    Config.KillAura = false 
    if state then
        task.spawn(function()
            while Config.ManualTP do
                HeadStomp()
                task.wait()
            end
        end)
    end
end)

CreateToggle(CombatTab, "Kill Aura (Auto Attack)", false, function(state)
    Config.KillAura = state
    Config.ManualTP = false
    if state then
        task.spawn(function()
            while Config.KillAura do
                HeadStomp()
                local Char = LocalPlayer.Character
                local Tool = Char and Char:FindFirstChildWhichIsA("Tool")
                if not Tool then
                    local BP = LocalPlayer.Backpack:FindFirstChildWhichIsA("Tool")
                    if BP and Char.Humanoid then Char.Humanoid:EquipTool(BP) Tool = BP end
                end
                
                if Tool then
                    Tool:Activate()
                    VirtualUser:CaptureController()
                    VirtualUser:ClickButton1(Vector2.new(0,0))
                end
                task.wait()
            end
        end)
    end
end)

-- === ABA VISUAIS ===
local VisualTab = CreateTab("VISUAIS")

CreateSection(VisualTab, "ESP JOGADORES")
CreateToggle(VisualTab, "ESP Caixa (Box)", false, function(s) Config.ESP_Box = s end)
CreateToggle(VisualTab, "ESP Nome", false, function(s) Config.ESP_Name = s end)
CreateToggle(VisualTab, "ESP Vida", false, function(s) Config.ESP_Health = s end)
CreateToggle(VisualTab, "ESP Linha (Tracer)", false, function(s) Config.ESP_Line = s end)

-- Sistema ESP
local function DrawLine()
    local L = Instance.new("Frame")
    L.Name = "Tracer"
    L.AnchorPoint = Vector2.new(0.5, 0.5)
    L.BackgroundColor3 = Theme.GreenESP
    L.BorderSizePixel = 0
    L.Visible = false
    L.Parent = ScreenGui
    return L
end

local function UpdateESP(player)
    if ESP_Cache[player] then return end
    
    local hl = Instance.new("Highlight")
    hl.FillTransparency = 1
    hl.OutlineColor = Theme.GreenESP
    hl.OutlineTransparency = 0
    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    hl.Enabled = false
    
    local bb = Instance.new("BillboardGui")
    bb.Size = UDim2.new(0, 200, 0, 50)
    bb.StudsOffset = Vector3.new(0, 4, 0)
    bb.AlwaysOnTop = true
    bb.Enabled = false
    
    local txtName = Instance.new("TextLabel", bb)
    txtName.Size = UDim2.new(1, 0, 0, 20)
    txtName.BackgroundTransparency = 1
    txtName.Text = player.DisplayName
    txtName.TextColor3 = Theme.Text
    txtName.Font = Enum.Font.GothamBold
    txtName.TextSize = 13
    txtName.TextStrokeTransparency = 0.5
    
    local txtHP = Instance.new("TextLabel", bb)
    txtHP.Size = UDim2.new(1, 0, 0, 20)
    txtHP.Position = UDim2.new(0, 0, 0.4, 0)
    txtHP.BackgroundTransparency = 1
    txtHP.Text = "100 HP"
    txtHP.TextColor3 = Theme.GreenESP
    txtHP.Font = Enum.Font.GothamBold
    txtHP.TextSize = 12
    txtHP.TextStrokeTransparency = 0.5
    
    local line = DrawLine()
    
    ESP_Cache[player] = {HL = hl, BB = bb, TN = txtName, TH = txtHP, LN = line}
    
    RunService.RenderStepped:Connect(function()
        if not player or not player.Parent then
            hl:Destroy(); bb:Destroy(); line:Destroy()
            ESP_Cache[player] = nil
            return
        end
        
        local Char = player.Character
        if Char and Char:FindFirstChild("HumanoidRootPart") and Char:FindFirstChild("Humanoid") then
            if hl.Parent ~= Char then hl.Parent = Char end
            if bb.Parent ~= Char.HumanoidRootPart then bb.Parent = Char.HumanoidRootPart end
            
            hl.Enabled = Config.ESP_Box
            bb.Enabled = (Config.ESP_Name or Config.ESP_Health)
            ESP_Cache[player].TN.Visible = Config.ESP_Name
            ESP_Cache[player].TH.Visible = Config.ESP_Health
            
            if Config.ESP_Health then
                local hp = math.floor(Char.Humanoid.Health)
                ESP_Cache[player].TH.Text = hp .. " HP"
                ESP_Cache[player].TH.TextColor3 = hp < 30 and Theme.Red or Theme.GreenESP
            end
            
            if Config.ESP_Line then
                local vector, onScreen = Camera:WorldToViewportPoint(Char.HumanoidRootPart.Position)
                if onScreen then
                    local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
                    local targetPos = Vector2.new(vector.X, vector.Y)
                    local length = (targetPos - screenCenter).Magnitude
                    local angle = math.atan2(targetPos.Y - screenCenter.Y, targetPos.X - screenCenter.X)
                    
                    line.Visible = true
                    line.Size = UDim2.new(0, length, 0, 1.5)
                    line.Position = UDim2.new(0, (screenCenter.X + targetPos.X)/2, 0, (screenCenter.Y + targetPos.Y)/2)
                    line.Rotation = math.deg(angle)
                else
                    line.Visible = false
                end
            else
                line.Visible = false
            end
        else
            hl.Enabled = false; bb.Enabled = false; line.Visible = false
        end
    end)
end
Players.PlayerAdded:Connect(UpdateESP)
for _, p in pairs(Players:GetPlayers()) do if p ~= LocalPlayer then UpdateESP(p) end end

-- === ABA EXPLOIT ===
local ExploitTab = CreateTab("EXPLOIT")

CreateSection(ExploitTab, "MOVIMENTAÇÃO")
CreateToggle(ExploitTab, "Speed Hack", false, function(s) Config.Speed_Active = s end)
CreateSlider(ExploitTab, "Velocidade", 16, 200, 16, function(v) Config.Speed_Value = v end)

CreateToggle(ExploitTab, "Super Pulo", false, function(s) Config.Jump_Active = s end)
CreateSlider(ExploitTab, "Força Pulo", 50, 300, 50, function(v) Config.Jump_Value = v end)

CreateSection(ExploitTab, "VOO (FLY)")
CreateToggle(ExploitTab, "Ativar Fly", false, function(s) 
    Config.Fly_Active = s 
    if s then
        local bg, bv
        local root = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if root then
            bg = Instance.new("BodyGyro", root); bg.P=9e4; bg.maxTorque=Vector3.new(9e9,9e9,9e9); bg.cframe=root.CFrame
            bv = Instance.new("BodyVelocity", root); bv.velocity=Vector3.zero; bv.maxForce=Vector3.new(9e9,9e9,9e9)
            
            task.spawn(function()
                while Config.Fly_Active and root do
                    bg.cframe = Camera.CFrame
                    local dir = Vector3.zero
                    if UserInputService:IsKeyDown(Enum.KeyCode.W) then dir = dir + Camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.S) then dir = dir - Camera.CFrame.LookVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.D) then dir = dir + Camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.A) then dir = dir - Camera.CFrame.RightVector end
                    if UserInputService:IsKeyDown(Enum.KeyCode.Space) then dir = dir + Vector3.new(0,1,0) end
                    if UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then dir = dir - Vector3.new(0,1,0) end
                    
                    bv.velocity = dir * Config.Fly_Speed
                    RunService.RenderStepped:Wait()
                end
                if bg then bg:Destroy() end
                if bv then bv:Destroy() end
            end)
        end
    end
end)
CreateSlider(ExploitTab, "Velocidade Fly", 20, 200, 50, function(v) Config.Fly_Speed = v end)

CreateSection(ExploitTab, "OUTROS")
CreateToggle(ExploitTab, "Noclip (Atravessar)", false, function(s) Config.Noclip = s end)
CreateToggle(ExploitTab, "God Mode (Vida Inf.)", false, function(s) 
    Config.GodMode = s 
    if s and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
        LocalPlayer.Character.Humanoid.MaxHealth = 999999
        LocalPlayer.Character.Humanoid.Health = 999999
    end
end)

-- [8] LOOP DE MONITORAMENTO GLOBAL
RunService.Stepped:Connect(function()
    if LocalPlayer.Character then
        local Hum = LocalPlayer.Character:FindFirstChild("Humanoid")
        
        if Config.Speed_Active and Hum then Hum.WalkSpeed = Config.Speed_Value end
        if Config.Jump_Active and Hum then Hum.JumpPower = Config.Jump_Value end
        
        if Config.Noclip then
            for _, v in pairs(LocalPlayer.Character:GetDescendants()) do
                if v:IsA("BasePart") then v.CanCollide = false end
            end
        end
    end
end)

-- Anti-AFK
LocalPlayer.Idled:Connect(function()
    VirtualUser:Button2Down(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
    wait(1)
    VirtualUser:Button2Up(Vector2.new(0,0), workspace.CurrentCamera.CFrame)
end)

-- Abre a primeira aba por padrão
Tabs[1].Btn.MouseButton1Click:Fire()
print("ZL MODS REMASTERED LOADED")
