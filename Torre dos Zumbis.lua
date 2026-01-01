--[[ 
    ZOMBIE TESTER V61 - RESTORED & FIXED
    
    CORREÇÕES CRÍTICAS:
    1. AUTO LOOT: 
       - Agora visita Spawns, Caixas, Plankton e Jail.
       - PAUSA funções (F1, F2, F3) durante o loot.
       - RESTAURA as funções automaticamente ao terminar.
       - Botão de TEMPO adicionado de volta.
    2. F1 BRING: 
       - Zumbis na frente (distância 8) e de costas para o player.
    3. UI:
       - Visual Profissional mantido.
       - Botão de Fechar e Tempo incluídos.
]]

-- 1. SERVIÇOS E SETUP
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

if not game:IsLoaded() then game.Loaded:Wait() end

-- 2. VARIÁVEIS GLOBAIS
local Connections = {} 
local ButtonToggles = {} -- Para sincronizar teclas e botões UI

-- Estados
local F2_Mode = false
local F3_Mode = false
local Hitbox_Enabled = false
local AutoLoot_Enabled = false
local CombineAmmo_Enabled = false
local AutoSwitch_Enabled = false
local Bring_Enabled = false
local RemoveLava_Enabled = false

-- Configurações
local JailPos = Vector3.new(133, 431, -135)
local LootInterval = 60 -- Tempo padrão
local LastLootTime = 0
local IsTeleporting = false
local HeadSize = 30
local BringDistance = 8 -- Ajustado para não bugar na câmera
local IsShooting = false

-- Pastas
local MysteryFolder = workspace:FindFirstChild("MysteryBoxes")
local PlanktonFolder = workspace:FindFirstChild("LivePlankton")
local ZombieFolder = workspace:FindFirstChild("ActiveZombies")
local MapFolder = workspace:FindFirstChild("LoadedMap") 
local SpawnsFolder = MapFolder and MapFolder:FindFirstChild("ZombieSpawns")

--------------------------------------------------------------------------------
-- 3. FUNÇÕES DE LÓGICA (BACKEND)
--------------------------------------------------------------------------------

local function Notify(title, text)
    game:GetService("StarterGui"):SetCore("SendNotification", {
        Title = title, Text = text, Duration = 3
    })
end

local function GetCurrentAmmo(tool)
    if not tool then return 0 end
    local folders = {"Info", "ServerInfo", "Settings", "Configuration"}
    for _, fName in pairs(folders) do
        local folder = tool:FindFirstChild(fName)
        if folder then
            local Clip = folder:FindFirstChild("Clip") or folder:FindFirstChild("Ammo")
            if Clip and (Clip:IsA("IntValue") or Clip:IsA("NumberValue")) then return Clip.Value end
        end
    end
    return 999
end

local function IsHoldingFireGun()
    local Char = LocalPlayer.Character
    if not Char then return false end
    local Tool = Char:FindFirstChildOfClass("Tool")
    if Tool then
        local Name = Tool.Name:lower()
        if Name:match("fire") or Name:match("fogo") then return true end
    end
    return false
end

local function UnfreezeZombies()
    if ZombieFolder then
        for _, z in pairs(ZombieFolder:GetChildren()) do
            local r = z:FindFirstChild("HumanoidRootPart") or z:FindFirstChild("Torso")
            if r then r.Anchored = false end
        end
    end
end

local function CheckAndRemoveLava()
    if RemoveLava_Enabled then
        local LavaFolder = workspace:FindFirstChild("TouchLava")
        if LavaFolder then LavaFolder:Destroy() end
    end
end

-- --- AUTO LOOT COMPLEXO (SALVA E RESTAURA) ---
local function PerformLootRun()
    if IsTeleporting then return end
    IsTeleporting = true
    
    local Character = LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then 
        IsTeleporting = false
        return 
    end

    -- 1. SALVAR ESTADOS ATUAIS
    local Saved_F1 = Bring_Enabled
    local Saved_F2 = F2_Mode
    local Saved_F3 = F3_Mode
    local Saved_Switch = AutoSwitch_Enabled
    
    -- 2. DESATIVAR TUDO TEMPORARIAMENTE
    if Saved_F1 or Saved_F2 or Saved_F3 then
        Notify("AUTO LOOT", "Pausando funções...")
        Bring_Enabled = false
        F2_Mode = false
        F3_Mode = false
        UnfreezeZombies() -- Solta os zumbis para não bugarem
    end

    local Root = Character.HumanoidRootPart
    local SavedPos = Root.CFrame

    -- ROTA 1: KILLZONE (JAIL)
    Root.CFrame = CFrame.new(JailPos)
    for i = 1, 15 do RunService.Heartbeat:Wait() end -- Espera coletar

    -- ROTA 2: SPAWNS (Verificando se pasta existe a cada loop)
    if not SpawnsFolder then 
        local M = workspace:FindFirstChild("LoadedMap")
        SpawnsFolder = M and M:FindFirstChild("ZombieSpawns")
    end
    
    if SpawnsFolder then
        for _, s in pairs(SpawnsFolder:GetChildren()) do
            if not AutoLoot_Enabled then break end
            if s:IsA("BasePart") then Root.CFrame = s.CFrame
            elseif s:IsA("Model") and s.PrimaryPart then Root.CFrame = s.PrimaryPart.CFrame end
            RunService.Heartbeat:Wait() -- Espera 1 frame por spawn
        end
    end
    
    -- ROTA 3: CAIXAS
    if MysteryFolder then
        for _, box in pairs(MysteryFolder:GetChildren()) do
            if not AutoLoot_Enabled then break end
            Root.CFrame = box:IsA("Model") and box.PrimaryPart.CFrame or box.CFrame
            RunService.Heartbeat:Wait()
        end
    end
    
    -- ROTA 4: PLANKTON
    if PlanktonFolder then
        for _, item in pairs(PlanktonFolder:GetChildren()) do
            if not AutoLoot_Enabled then break end
            Root.CFrame = item:IsA("Model") and item.PrimaryPart.CFrame or item.CFrame
            RunService.Heartbeat:Wait()
        end
    end

    -- 3. VOLTA E RESTAURAÇÃO
    Root.CFrame = SavedPos
    
    if Saved_F1 or Saved_F2 or Saved_F3 then
        Notify("AUTO LOOT", "Restaurando funções!")
        Bring_Enabled = Saved_F1
        F2_Mode = Saved_F2
        F3_Mode = Saved_F3
    end
    
    IsTeleporting = false
end

-- LOOP DE CHECAGEM DO LOOT
task.spawn(function()
    while true do
        if AutoLoot_Enabled then
            if (tick() - LastLootTime) >= LootInterval then
                PerformLootRun()
                LastLootTime = tick()
            end
        end
        task.wait(1)
    end
end)

-- --- LOOPS DE COMBATE ---
local function LogicLoop()
    -- JAIL
    if F2_Mode and ZombieFolder then
        for _, z in pairs(ZombieFolder:GetChildren()) do
            local Root = z:FindFirstChild("HumanoidRootPart") or z:FindFirstChild("Torso")
            if Root then
                if (Root.Position - JailPos).Magnitude > 2 then
                    local Jitter = Vector3.new(math.random(-1,1)/2, 0, math.random(-1,1)/2)
                    Root.CFrame = CFrame.new(JailPos + Jitter)
                    Root.Velocity = Vector3.zero
                end
                Root.Anchored = false
            end
        end
    end

    -- SMART FIRE
    if F3_Mode and not IsHoldingFireGun() then
        local Target = nil
        if ZombieFolder then
            for _, z in pairs(ZombieFolder:GetChildren()) do
                local H = z:FindFirstChild("Head")
                local Hum = z:FindFirstChild("Humanoid")
                if H and Hum and Hum.Health > 0 then Target = H; break end
            end
        end
        if Target then
            Camera.CFrame = CFrame.new(Camera.CFrame.Position, Target.Position)
            if not IsShooting then
                IsShooting = true
                VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
                task.wait(0.01)
                VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
                IsShooting = false
            end
        end
    end

    -- HITBOX
    if Hitbox_Enabled and ZombieFolder then
        for _, z in pairs(ZombieFolder:GetChildren()) do
            local h = z:FindFirstChild("Head")
            if h then
                h.Size = Vector3.new(HeadSize, HeadSize, HeadSize)
                h.Transparency = 0.5; h.CanCollide = false; h.Color = Color3.fromRGB(255, 0, 255)
            end
        end
    end

    -- COMBINE AMMO
    if CombineAmmo_Enabled then
        local locs = {LocalPlayer.Backpack, LocalPlayer.Character}
        for _, loc in pairs(locs) do
            if loc then
                for _, t in pairs(loc:GetChildren()) do
                    if t:IsA("Tool") then
                        local f = t:FindFirstChild("Info") or t:FindFirstChild("Settings") or t:FindFirstChild("Configuration")
                        if f then
                            local C = f:FindFirstChild("Clip") or f:FindFirstChild("Ammo")
                            local R = f:FindFirstChild("Reserve") or f:FindFirstChild("Stored") or f:FindFirstChild("StoredAmmo")
                            if C and R and R.Value > 0 then
                                C.Value = C.Value + R.Value
                                R.Value = 0
                            end
                        end
                    end
                end
            end
        end
    end

    -- AUTO SWITCH
    if AutoSwitch_Enabled then
        local Char = LocalPlayer.Character
        if Char then
            local Tool = Char:FindFirstChildOfClass("Tool")
            local Backpack = LocalPlayer:FindFirstChild("Backpack")
            if not Tool and Backpack then
                local tools = Backpack:GetChildren()
                for _,t in pairs(tools) do if t:IsA("Tool") then Char.Humanoid:EquipTool(t); break end end
            elseif Tool and Backpack then
                local ammo = GetCurrentAmmo(Tool)
                if ammo <= 0 then
                    local tools = Backpack:GetChildren()
                    for _,t in pairs(tools) do if t:IsA("Tool") and t ~= Tool then Char.Humanoid:EquipTool(t); break end end
                end
            end
        end
    end

    -- BRING (F1) - AJUSTADO PARA COSTAS
    if Bring_Enabled and not F2_Mode and ZombieFolder then
        local LookVec = Camera.CFrame.LookVector
        -- Posição na frente do player
        local TargetPos = Camera.CFrame.Position + (LookVec * BringDistance)
        
        for _, z in pairs(ZombieFolder:GetChildren()) do
            local R = z:FindFirstChild("HumanoidRootPart")
            if R then
                -- Define a posição para TargetPos
                -- Define o LookAt para (TargetPos + LookVec), ou seja, olhando para a mesma direção que o player olha
                -- Se o player olha pro Norte, o zumbi olha pro Norte. Logo, o zumbi dá as costas pro player.
                R.CFrame = CFrame.new(TargetPos, TargetPos + LookVec)
                R.Anchored = true
                R.Velocity = Vector3.zero
            end
        end
    end

    CheckAndRemoveLava()
end

table.insert(Connections, RunService.RenderStepped:Connect(LogicLoop))

--------------------------------------------------------------------------------
-- 4. INTERFACE GRÁFICA (UI)
--------------------------------------------------------------------------------

local function CreateUI()
    for _, v in pairs(CoreGui:GetChildren()) do if v.Name == "ZombieV61" then v:Destroy() end end
    
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ZombieV61"
    ScreenGui.Parent = CoreGui
    
    local SoundClick = Instance.new("Sound", ScreenGui)
    SoundClick.SoundId = "rbxassetid://6895079853" 
    SoundClick.Volume = 0.6

    -- DRAGGABLE
    local function MakeDraggable(frame)
        local dragging, dragInput, dragStart, startPos
        frame.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                dragging = true; dragStart = input.Position; startPos = frame.Position
                input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false end end)
            end
        end)
        frame.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then dragInput = input end
        end)
        UserInputService.InputChanged:Connect(function(input)
            if input == dragInput and dragging then
                local delta = input.Position - dragStart
                local targetPos = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
                TweenService:Create(frame, TweenInfo.new(0.1), {Position = targetPos}):Play()
            end
        end)
    end

    -- FLOAT BTN
    local FloatBtn = Instance.new("ImageButton", ScreenGui)
    FloatBtn.Size = UDim2.new(0, 50, 0, 50); FloatBtn.Position = UDim2.new(0.05, 0, 0.2, 0)
    FloatBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 30); FloatBtn.Visible = false
    local FC = Instance.new("UICorner", FloatBtn); FC.CornerRadius = UDim.new(1,0)
    local FS = Instance.new("UIStroke", FloatBtn); FS.Color = Color3.fromRGB(0, 200, 255); FS.Thickness = 2
    local FT = Instance.new("TextLabel", FloatBtn); FT.Size = UDim2.new(1,0,1,0); FT.BackgroundTransparency=1; FT.Text="Z"; FT.Font=Enum.Font.GothamBlack; FT.TextSize=24; FT.TextColor3=Color3.fromRGB(0,200,255)
    MakeDraggable(FloatBtn)

    -- MAIN FRAME
    local MainFrame = Instance.new("Frame", ScreenGui)
    MainFrame.Size = UDim2.new(0, 250, 0, 480) -- Mais alto para caber tudo
    MainFrame.Position = UDim2.new(0.5, -125, 0.5, -240)
    MainFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
    local MC = Instance.new("UICorner", MainFrame); MC.CornerRadius = UDim.new(0, 10)
    local MS = Instance.new("UIStroke", MainFrame); MS.Color = Color3.fromRGB(50, 50, 60); MS.Thickness = 1
    MakeDraggable(MainFrame)

    -- HEADER
    local Header = Instance.new("Frame", MainFrame)
    Header.Size = UDim2.new(1, 0, 0, 40); Header.BackgroundColor3 = Color3.fromRGB(25, 25, 30)
    local HC = Instance.new("UICorner", Header); HC.CornerRadius = UDim.new(0, 10)
    local HTilde = Instance.new("TextLabel", Header); HTilde.Text=" ZOMBIE V61"; HTilde.Size=UDim2.new(0.8,0,1,0); HTilde.BackgroundTransparency=1; HTilde.TextColor3=Color3.fromRGB(0,200,255); HTilde.Font=Enum.Font.GothamBold; HTilde.TextSize=16; HTilde.TextXAlignment=Enum.TextXAlignment.Left; HTilde.Position=UDim2.new(0.05,0,0,0)
    local Mini = Instance.new("TextButton", Header); Mini.Text="-"; Mini.Size=UDim2.new(0,30,0,30); Mini.Position=UDim2.new(1,-35,0.5,-15); Mini.BackgroundColor3=Color3.fromRGB(40,40,45); Mini.TextColor3=Color3.new(1,1,1); local MiC=Instance.new("UICorner", Mini); MiC.CornerRadius=UDim.new(0,6)

    -- LISTA
    local Container = Instance.new("ScrollingFrame", MainFrame)
    Container.Size = UDim2.new(1, -16, 1, -50); Container.Position = UDim2.new(0, 8, 0, 45); Container.BackgroundTransparency=1; Container.ScrollBarThickness=2
    local List = Instance.new("UIListLayout", Container); List.Padding = UDim.new(0, 6); List.SortOrder = Enum.SortOrder.LayoutOrder

    -- TOGGLE CREATOR
    local function AddToggle(text, default, keyCode, callback)
        local Btn = Instance.new("TextButton", Container)
        Btn.Size = UDim2.new(1, 0, 0, 38); Btn.BackgroundColor3 = Color3.fromRGB(30, 30, 35); Btn.Text = ""; Btn.AutoButtonColor = false
        local BC = Instance.new("UICorner", Btn); BC.CornerRadius = UDim.new(0, 6)
        
        local Lbl = Instance.new("TextLabel", Btn); Lbl.Text=text; Lbl.Size=UDim2.new(0.7,0,1,0); Lbl.Position=UDim2.new(0.05,0,0,0); Lbl.BackgroundTransparency=1; Lbl.TextColor3=Color3.fromRGB(200,200,200); Lbl.Font=Enum.Font.GothamSemibold; Lbl.TextSize=13; Lbl.TextXAlignment=Enum.TextXAlignment.Left
        
        local Ind = Instance.new("Frame", Btn); Ind.Size=UDim2.new(0,40,0,4); Ind.Position=UDim2.new(1,-45,0.5,-2); Ind.BackgroundColor3=Color3.fromRGB(50,50,50); local IC=Instance.new("UICorner", Ind); IC.CornerRadius=UDim.new(1,0)
        local Circ = Instance.new("Frame", Ind); Circ.Size=UDim2.new(0,12,0,12); Circ.Position=UDim2.new(0,-4,0.5,-6); Circ.BackgroundColor3=Color3.fromRGB(100,100,100); local CC=Instance.new("UICorner", Circ); CC.CornerRadius=UDim.new(1,0)
        
        local Enabled = default
        local function Update()
            if Enabled then
                TweenService:Create(Circ, TweenInfo.new(0.2), {Position=UDim2.new(1,-8,0.5,-6), BackgroundColor3=Color3.fromRGB(0,255,150)}):Play()
                TweenService:Create(Ind, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(0,100,50)}):Play()
                TweenService:Create(Lbl, TweenInfo.new(0.2), {TextColor3=Color3.new(1,1,1)}):Play()
            else
                TweenService:Create(Circ, TweenInfo.new(0.2), {Position=UDim2.new(0,-4,0.5,-6), BackgroundColor3=Color3.fromRGB(100,100,100)}):Play()
                TweenService:Create(Ind, TweenInfo.new(0.2), {BackgroundColor3=Color3.fromRGB(50,50,50)}):Play()
                TweenService:Create(Lbl, TweenInfo.new(0.2), {TextColor3=Color3.fromRGB(200,200,200)}):Play()
            end
            callback(Enabled, Lbl) -- Passa Label para edição se precisar
        end
        
        Btn.MouseButton1Click:Connect(function() SoundClick:Play(); Enabled = not Enabled; Update() end)
        if keyCode then
            ButtonToggles[keyCode] = function() SoundClick:Play(); Enabled = not Enabled; Update() end
        end
        
        return Btn, Lbl
    end

    -- BOTÕES
    AddToggle("F2: Jail (Micro Move)", false, Enum.KeyCode.F2, function(s) F2_Mode = s; if not s then UnfreezeZombies() end end)
    AddToggle("F3: Smart Fire", false, Enum.KeyCode.F3, function(s) F3_Mode = s end)
    AddToggle("F1: Bring (Costas)", false, Enum.KeyCode.F1, function(s) Bring_Enabled = s; if not s then UnfreezeZombies() end end)
    
    AddToggle("Auto Remove Lava", false, nil, function(s) RemoveLava_Enabled = s; if s then CheckAndRemoveLava() end end)
    AddToggle("Hitbox Gigante (30)", false, nil, function(s) Hitbox_Enabled = s end)
    AddToggle("Auto Switch (No Ammo)", false, nil, function(s) AutoSwitch_Enabled = s end)
    AddToggle("Combine Ammo", false, nil, function(s) CombineAmmo_Enabled = s end)
    AddToggle("Auto Loot (Killzone)", false, nil, function(s) AutoLoot_Enabled = s; if s then PerformLootRun() end end)

    -- BOTÃO DE TEMPO (EXTRA)
    local TimeBtn = Instance.new("TextButton", Container)
    TimeBtn.Size = UDim2.new(1, 0, 0, 35); TimeBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70); TimeBtn.Text = "Tempo Loot: 60s"; TimeBtn.TextColor3 = Color3.new(1,1,1); TimeBtn.Font = Enum.Font.GothamBold; local TC = Instance.new("UICorner", TimeBtn); TC.CornerRadius = UDim.new(0,6)
    
    TimeBtn.MouseButton1Click:Connect(function()
        SoundClick:Play()
        if LootInterval == 30 then LootInterval = 60
        elseif LootInterval == 60 then LootInterval = 120
        elseif LootInterval == 120 then LootInterval = 300
        else LootInterval = 30 end
        TimeBtn.Text = "Tempo Loot: " .. LootInterval .. "s"
    end)
    
    -- ESPAÇO
    local Space = Instance.new("Frame", Container); Space.Size=UDim2.new(1,0,0,10); Space.BackgroundTransparency=1

    -- BOTÃO FECHAR
    local CloseBtn = Instance.new("TextButton", Container)
    CloseBtn.Size = UDim2.new(1, 0, 0, 35); CloseBtn.BackgroundColor3 = Color3.fromRGB(150, 40, 40); CloseBtn.Text = "FECHAR SCRIPT"; CloseBtn.TextColor3 = Color3.new(1,1,1); CloseBtn.Font = Enum.Font.GothamBlack; local CC = Instance.new("UICorner", CloseBtn); CC.CornerRadius = UDim.new(0,6)
    
    CloseBtn.MouseButton1Click:Connect(function()
        ScreenGui:Destroy()
        for _,c in pairs(Connections) do c:Disconnect() end
        Connections = nil
    end)

    -- MINIMIZE LOGIC
    local function ToggleMini() SoundClick:Play(); MainFrame.Visible = not MainFrame.Visible; FloatBtn.Visible = not MainFrame.Visible end
    Mini.MouseButton1Click:Connect(ToggleMini); FloatBtn.MouseButton1Click:Connect(ToggleMini)
end

-- KEY LISTENER
if Connections then
    table.insert(Connections, UserInputService.InputBegan:Connect(function(i,p)
        if not p and ButtonToggles[i.KeyCode] then ButtonToggles[i.KeyCode]() end
    end))
end

CreateUI()
