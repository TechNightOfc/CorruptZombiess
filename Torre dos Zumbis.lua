--[[ 
    ZOMBIE V1 - ULTIMATE (FIXED FLY EDITION)
    
    CORREÇÃO:
    - FLY: Matemática corrigida. Não voa mais rápido demais.
    - NOVO BOTÃO: "VELOCIDADE FLY" para escolher entre 20, 50 ou 100.
    
    FUNCIONALIDADES:
    - F1: Bring (Puxar Zumbis).
    - Botão "REMOVER LAVA".
    - Fly & Noclip.
    - Extended Mag, Auto Loot, Jail, etc.
]]

-- Aguarda carregamento
if not game:IsLoaded() then game.Loaded:Wait() end

-- SERVIÇOS
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService") 
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local StarterGui = game:GetService("StarterGui")
local Mouse = LocalPlayer:GetMouse()

-- PASTAS DO MAPA
local MysteryFolder = workspace:FindFirstChild("MysteryBoxes")
local PlanktonFolder = workspace:FindFirstChild("LivePlankton")
local ZombieFolder = workspace:FindFirstChild("ActiveZombies")
local MapFolder = workspace:FindFirstChild("LoadedMap") 
local SpawnsFolder = MapFolder and MapFolder:FindFirstChild("ZombieSpawns")

-- LOCALIZAÇÃO DA PRISÃO (JAIL / KILLZONE)
local JailPos = Vector3.new(133, 431, -135)

-- VARIÁVEIS GLOBAIS
local Connections = {} 

-- ESTADOS
local Bring_Enabled = false -- F1 (BRING)
local F2_Mode = false -- JAIL
local F3_Mode = false -- FIRE
local Fly_Enabled = false -- FLY (Botão)
local Noclip_Enabled = false -- NOCLIP
local Hitbox_Enabled = false 
local AutoLoot_Enabled = false 
local CombineAmmo_Enabled = false 
local AutoSwitch_Enabled = false   

-- CONFIGURAÇÕES
local LootInterval = 60 
local LastLootTime = 0
local IsTeleporting = false
local HeadSize = 30 
local IsShooting = false
local BringDistance = 5 
local FlySpeed = 20 -- Velocidade Inicial Corrigida

-- CONTROLES DE VOO
local CONTROL = {F = 0, B = 0, L = 0, R = 0, U = 0, D = 0}
local lCONTROL = {F = 0, B = 0, L = 0, R = 0, U = 0, D = 0}
local SPEED = 0

-- NOTIFICAÇÃO
local function Notify(title, text)
    StarterGui:SetCore("SendNotification", {
        Title = title,
        Text = text,
        Duration = 3
    })
end

-------------------------------------------------------------------------
-- 1. UTILS
-------------------------------------------------------------------------
local function GetCurrentAmmo(tool)
    if not tool then return 0 end 
    local folders = {"Info", "ServerInfo", "Settings", "Configuration"}
    for _, fName in pairs(folders) do
        local folder = tool:FindFirstChild(fName)
        if folder then
            local Clip = folder:FindFirstChild("Clip") or folder:FindFirstChild("Ammo")
            if Clip and (Clip:IsA("IntValue") or Clip:IsA("NumberValue")) then
                return Clip.Value
            end
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

-------------------------------------------------------------------------
-- 2. FLY & NOCLIP (CORRIGIDO)
-------------------------------------------------------------------------
local function FlyFunction()
    local BG = Instance.new('BodyGyro')
    local BV = Instance.new('BodyVelocity')
    
    task.spawn(function()
        while Fly_Enabled do
            if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then 
                Fly_Enabled = false 
                break 
            end
            
            local Humanoid = LocalPlayer.Character:FindFirstChild("Humanoid")
            local Root = LocalPlayer.Character.HumanoidRootPart

            if Humanoid and Root then
                Humanoid.PlatformStand = true
                
                if not Root:FindFirstChild("IY_BG") then
                    BG = Instance.new('BodyGyro', Root)
                    BG.Name = "IY_BG"; BG.P = 9e4; BG.maxTorque = Vector3.new(9e9, 9e9, 9e9); BG.cframe = Root.CFrame
                end
                if not Root:FindFirstChild("IY_BV") then
                    BV = Instance.new('BodyVelocity', Root)
                    BV.Name = "IY_BV"; BV.velocity = Vector3.new(0, 0, 0); BV.maxForce = Vector3.new(9e9, 9e9, 9e9)
                end

                BG.cframe = Camera.CFrame
                
                -- CONTROLES AGORA RETORNAM 1 (DIREÇÃO) E NÃO A VELOCIDADE
                CONTROL.F = (UserInputService:IsKeyDown(Enum.KeyCode.W) and 1 or 0)
                CONTROL.B = (UserInputService:IsKeyDown(Enum.KeyCode.S) and -1 or 0)
                CONTROL.L = (UserInputService:IsKeyDown(Enum.KeyCode.A) and -1 or 0)
                CONTROL.R = (UserInputService:IsKeyDown(Enum.KeyCode.D) and 1 or 0)
                CONTROL.U = (UserInputService:IsKeyDown(Enum.KeyCode.E) and 1 or 0)
                CONTROL.D = (UserInputService:IsKeyDown(Enum.KeyCode.Q) and -1 or 0)
                
                if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.U + CONTROL.D) ~= 0 then 
                    SPEED = FlySpeed -- Usa a variável global configurada
                elseif not (CONTROL.L + CONTROL.R ~= 0 or CONTROL.F + CONTROL.B ~= 0 or CONTROL.U + CONTROL.D ~= 0) and SPEED ~= 0 then 
                    SPEED = 0 
                end
                
                if (CONTROL.L + CONTROL.R) ~= 0 or (CONTROL.F + CONTROL.B) ~= 0 or (CONTROL.U + CONTROL.D) ~= 0 then
                    BV.velocity = ((Camera.CFrame.lookVector * (CONTROL.F + CONTROL.B)) + ((Camera.CFrame * CFrame.new(CONTROL.L + CONTROL.R, (CONTROL.F + CONTROL.B + CONTROL.U + CONTROL.D) * 0.2, 0).p) - Camera.CFrame.p)) * SPEED
                    lCONTROL = {F = CONTROL.F, B = CONTROL.B, L = CONTROL.L, R = CONTROL.R, U = CONTROL.U, D = CONTROL.D}
                elseif (CONTROL.L + CONTROL.R) == 0 and (CONTROL.F + CONTROL.B) == 0 and (CONTROL.U + CONTROL.D) == 0 and SPEED ~= 0 then
                    BV.velocity = ((Camera.CFrame.lookVector * (lCONTROL.F + lCONTROL.B)) + ((Camera.CFrame * CFrame.new(lCONTROL.L + lCONTROL.R, (lCONTROL.F + lCONTROL.B + lCONTROL.U + lCONTROL.D) * 0.2, 0).p) - Camera.CFrame.p)) * SPEED
                else
                    BV.velocity = Vector3.new(0, 0, 0)
                end
            end
            RunService.RenderStepped:Wait()
        end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then LocalPlayer.Character.Humanoid.PlatformStand = false end
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
            local r = LocalPlayer.Character.HumanoidRootPart
            if r:FindFirstChild("IY_BG") then r.IY_BG:Destroy() end
            if r:FindFirstChild("IY_BV") then r.IY_BV:Destroy() end
        end
    end)
end

table.insert(Connections, RunService.Stepped:Connect(function()
    if Noclip_Enabled and LocalPlayer.Character then
        for _, part in pairs(LocalPlayer.Character:GetDescendants()) do
            if part:IsA("BasePart") and part.CanCollide == true then part.CanCollide = false end
        end
    end
end))

-------------------------------------------------------------------------
-- 3. AUTO SWITCH
-------------------------------------------------------------------------
local function AutoSwitchLoop()
    if not AutoSwitch_Enabled then return end
    local Char = LocalPlayer.Character
    if not Char or not Char:FindFirstChild("Humanoid") then return end
    local CurrentTool = Char:FindFirstChildOfClass("Tool")
    local Backpack = LocalPlayer:FindFirstChild("Backpack")
    
    if not CurrentTool then
        if Backpack then
            local Tools = Backpack:GetChildren()
            if #Tools > 0 then
                for _, t in pairs(Tools) do
                    if t:IsA("Tool") then Char.Humanoid:EquipTool(t); return end
                end
            end
        end
        return
    end
    local Ammo = GetCurrentAmmo(CurrentTool)
    if Ammo <= 0 and Backpack then
        local Tools = Backpack:GetChildren()
        if #Tools > 0 then
            for _, t in pairs(Tools) do
                if t:IsA("Tool") and t ~= CurrentTool then Char.Humanoid:EquipTool(t); return end
            end
        end
    end
end
table.insert(Connections, RunService.Heartbeat:Connect(AutoSwitchLoop))

-------------------------------------------------------------------------
-- 4. AUTO LOOT
-------------------------------------------------------------------------
local function PerformLootRun()
    if IsTeleporting then return end
    IsTeleporting = true
    local Character = LocalPlayer.Character
    if not Character or not Character:FindFirstChild("HumanoidRootPart") then IsTeleporting = false return end
    
    local Saved_F1 = Bring_Enabled
    local Saved_F2 = F2_Mode
    local Saved_F3 = F3_Mode
    local Saved_Fly = Fly_Enabled
    
    if Saved_F1 or Saved_F2 or Saved_F3 then Notify("AUTO LOOT", "Coletando...") end
    Bring_Enabled = false; F2_Mode = false; F3_Mode = false; Fly_Enabled = false
    
    local SavedPos = Character.HumanoidRootPart.CFrame
    
    -- JAIL
    if AutoLoot_Enabled then
        Character.HumanoidRootPart.CFrame = CFrame.new(JailPos)
        for i = 1, 15 do RunService.Heartbeat:Wait() end
    end
    -- SPAWNS
    if SpawnsFolder then
        for _, s in pairs(SpawnsFolder:GetChildren()) do
            if not AutoLoot_Enabled then break end
            if s:IsA("BasePart") then Character.HumanoidRootPart.CFrame = s.CFrame
            elseif s:IsA("Model") and s.PrimaryPart then Character.HumanoidRootPart.CFrame = s.PrimaryPart.CFrame end
            RunService.Heartbeat:Wait()
        end
    end
    -- ITENS
    if MysteryFolder and AutoLoot_Enabled then
        for _, box in pairs(MysteryFolder:GetChildren()) do
            if box:IsA("BasePart") then Character.HumanoidRootPart.CFrame = box.CFrame
            elseif box:IsA("Model") and box.PrimaryPart then Character.HumanoidRootPart.CFrame = box.PrimaryPart.CFrame end
            RunService.Heartbeat:Wait()
        end
    end
    if PlanktonFolder and AutoLoot_Enabled then
        for _, item in pairs(PlanktonFolder:GetChildren()) do
            if item:IsA("BasePart") then Character.HumanoidRootPart.CFrame = item.CFrame end
            RunService.Heartbeat:Wait()
        end
    end

    Character.HumanoidRootPart.CFrame = SavedPos
    Bring_Enabled = Saved_F1; F2_Mode = Saved_F2; F3_Mode = Saved_F3
    if Saved_Fly then Fly_Enabled = true; FlyFunction() end
    IsTeleporting = false
end

task.spawn(function()
    while true do
        if AutoLoot_Enabled then
            if (tick() - LastLootTime) >= LootInterval then PerformLootRun(); LastLootTime = tick() end
        end
        task.wait(1)
    end
end)

-------------------------------------------------------------------------
-- 5. F1 BRING & F2 JAIL
-------------------------------------------------------------------------
local function BringZombiesLoop()
    if not Bring_Enabled or F2_Mode then return end
    local LookVector = Camera.CFrame.LookVector
    local CamPos = Camera.CFrame.Position
    local TargetPos = CamPos + (LookVector * BringDistance)
    if ZombieFolder then
        for _, zombie in pairs(ZombieFolder:GetChildren()) do
            if zombie:IsA("Model") then
                local ZRoot = zombie:FindFirstChild("HumanoidRootPart") or zombie:FindFirstChild("Torso")
                local ZHead = zombie:FindFirstChild("Head")
                local ZHum = zombie:FindFirstChild("Humanoid")
                if ZRoot and ZHead and ZHum and ZHum.Health > 0 then
                    local HeadOffset = ZHead.Position - ZRoot.Position
                    local FinalPos = TargetPos - HeadOffset
                    local BackToPlayer = CFrame.new(FinalPos, FinalPos + LookVector)
                    ZRoot.CFrame = BackToPlayer
                    ZRoot.Anchored = true; ZRoot.Velocity = Vector3.zero
                end
            end
        end
    end
end

local function JailLoop()
    if not F2_Mode then return end
    if ZombieFolder then
        for _, zombie in pairs(ZombieFolder:GetChildren()) do
            if zombie:IsA("Model") then
                local Root = zombie:FindFirstChild("HumanoidRootPart") or zombie:FindFirstChild("Torso")
                if Root then
                    if (Root.Position - JailPos).Magnitude > 2 then
                        local RandomJitter = Vector3.new(math.random(-1,1)/2, 0, math.random(-1,1)/2)
                        Root.CFrame = CFrame.new(JailPos + RandomJitter)
                        Root.Velocity = Vector3.zero 
                    end
                    Root.Anchored = false 
                end
            end
        end
    end
end

-------------------------------------------------------------------------
-- 6. F3 AUTO FIRE
-------------------------------------------------------------------------
local function GetAnyTarget()
    if ZombieFolder then
        for _, z in pairs(ZombieFolder:GetChildren()) do
            local Head = z:FindFirstChild("Head")
            local Hum = z:FindFirstChild("Humanoid")
            if Head and Hum and Hum.Health > 0 then return Head end
        end
    end
    return nil
end

local function AimAndShootLoop()
    if not F3_Mode then return end
    if IsHoldingFireGun() then return end
    local TargetHead = GetAnyTarget()
    if TargetHead then
        Camera.CFrame = CFrame.new(Camera.CFrame.Position, TargetHead.Position)
        if not IsShooting then
            IsShooting = true
            VirtualInputManager:SendMouseButtonEvent(0,0,0,true,game,1)
            task.wait(0.01) 
            VirtualInputManager:SendMouseButtonEvent(0,0,0,false,game,1)
            IsShooting = false
        end
    end
end

-------------------------------------------------------------------------
-- 7. HITBOX & COMBINE AMMO
-------------------------------------------------------------------------
local function ExpandHitbox(model)
    if not Hitbox_Enabled then return end
    local head = model:FindFirstChild("Head")
    if head then
        head.Size = Vector3.new(HeadSize, HeadSize, HeadSize)
        head.Transparency = 0.5; head.CanCollide = false; head.Color = Color3.fromRGB(255, 0, 255) 
    end
end

local function RunCombineAmmo()
    local locations = {LocalPlayer.Backpack, LocalPlayer.Character}
    for _, location in pairs(locations) do
        if location then
            for _, tool in pairs(location:GetChildren()) do
                if tool:IsA("Tool") then
                    local folders = {"Info", "ServerInfo", "Settings", "Configuration"}
                    for _, fName in pairs(folders) do
                        local folder = tool:FindFirstChild(fName)
                        if folder then
                            local Clip = folder:FindFirstChild("Clip") or folder:FindFirstChild("Ammo") or folder:FindFirstChild("CurrentAmmo")
                            local Reserve = folder:FindFirstChild("Reserve") or folder:FindFirstChild("Stored") or folder:FindFirstChild("StoredAmmo") or folder:FindFirstChild("MaxAmmo")
                            if Clip and Reserve and (Clip:IsA("IntValue") or Clip:IsA("NumberValue")) and (Reserve:IsA("IntValue") or Reserve:IsA("NumberValue")) then
                                if Reserve.Value > 0 then
                                    local total = Clip.Value + Reserve.Value
                                    Clip.Value = total; Reserve.Value = 0
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

-------------------------------------------------------------------------
-- 8. MENU UI
-------------------------------------------------------------------------
local function CriarMenu()
    if CoreGui:FindFirstChild("ZombieV1") then CoreGui.ZombieV1:Destroy() end
    if LocalPlayer.PlayerGui:FindFirstChild("ZombieV1") then LocalPlayer.PlayerGui.ZombieV1:Destroy() end

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "ZombieV1"
    if pcall(function() ScreenGui.Parent = CoreGui end) then else ScreenGui.Parent = LocalPlayer.PlayerGui end

    local MainFrame = Instance.new("Frame")
    MainFrame.Parent = ScreenGui; MainFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 25)
    MainFrame.Position = UDim2.new(0.5, -110, 0.3, 0); MainFrame.Size = UDim2.new(0, 220, 0, 560) 
    MainFrame.Active = true; MainFrame.Draggable = true; MainFrame.BorderSizePixel = 0
    local UICorner = Instance.new("UICorner"); UICorner.CornerRadius = UDim.new(0, 8); UICorner.Parent = MainFrame

    local Header = Instance.new("Frame"); Header.Parent = MainFrame; Header.BackgroundColor3 = Color3.fromRGB(40, 40, 40); Header.Size = UDim2.new(1, 0, 0, 35)
    local HeaderCorner = Instance.new("UICorner"); HeaderCorner.CornerRadius = UDim.new(0, 8); HeaderCorner.Parent = Header
    local HeaderFill = Instance.new("Frame"); HeaderFill.Parent = Header; HeaderFill.BackgroundColor3 = Color3.fromRGB(40, 40, 40); HeaderFill.Size = UDim2.new(1, 0, 0, 10); HeaderFill.Position = UDim2.new(0, 0, 1, -10); HeaderFill.BorderSizePixel = 0

    local Title = Instance.new("TextLabel"); Title.Parent = Header; Title.Text = "ZOMBIE V1"
    Title.Size = UDim2.new(0.7, 0, 1, 0); Title.Position = UDim2.new(0.05, 0, 0, 0); Title.BackgroundTransparency = 1; Title.TextColor3 = Color3.fromRGB(0, 255, 120); Title.Font = Enum.Font.GothamBlack; Title.TextSize = 14; Title.TextXAlignment = Enum.TextXAlignment.Left

    local MinBtn = Instance.new("TextButton"); MinBtn.Parent = Header; MinBtn.Text = "-"; MinBtn.Size = UDim2.new(0, 30, 0, 30); MinBtn.Position = UDim2.new(1, -35, 0, 2)
    MinBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60); MinBtn.TextColor3 = Color3.new(1,1,1); MinBtn.Font = Enum.Font.GothamBold; MinBtn.TextSize = 18
    local MinCorner = Instance.new("UICorner"); MinCorner.CornerRadius = UDim.new(0, 6); MinCorner.Parent = MinBtn

    local Container = Instance.new("ScrollingFrame"); Container.Parent = MainFrame; Container.BackgroundTransparency = 1; Container.Size = UDim2.new(1, -10, 1, -45); Container.Position = UDim2.new(0, 5, 0, 40); Container.BorderSizePixel = 0; Container.ScrollBarThickness = 2
    local UIList = Instance.new("UIListLayout"); UIList.Parent = Container; UIList.SortOrder = Enum.SortOrder.LayoutOrder; UIList.Padding = UDim.new(0, 5)

    local Minimized = false
    MinBtn.MouseButton1Click:Connect(function()
        Minimized = not Minimized
        if Minimized then Container.Visible = false; MainFrame:TweenSize(UDim2.new(0, 220, 0, 35), "Out", "Quad", 0.3, true); MinBtn.Text = "+"
        else Container.Visible = true; MainFrame:TweenSize(UDim2.new(0, 220, 0, 560), "Out", "Quad", 0.3, true); MinBtn.Text = "-" end
    end)

    local function CreateButton(text, callback, colorOff)
        local btn = Instance.new("TextButton"); btn.Parent = Container; btn.Text = text; btn.Size = UDim2.new(1, 0, 0, 32)
        btn.BackgroundColor3 = colorOff or Color3.fromRGB(35, 35, 35); btn.TextColor3 = Color3.fromRGB(200, 200, 200); btn.Font = Enum.Font.GothamSemibold; btn.TextSize = 12; btn.AutoButtonColor = true
        local bc = Instance.new("UICorner"); bc.CornerRadius = UDim.new(0, 6); bc.Parent = btn
        btn.MouseButton1Click:Connect(callback)
        return btn
    end

    -- F1 BRING (Agora no F1)
    local B_F1 = CreateButton("BRING (F1): OFF", function() 
        Bring_Enabled = not Bring_Enabled
        Notify("BRING (F1)", Bring_Enabled and "ATIVADO" or "DESATIVADO")
        if not Bring_Enabled and ZombieFolder then for _,z in pairs(ZombieFolder:GetChildren()) do local r = z:FindFirstChild("HumanoidRootPart"); if r then r.Anchored = false end end end
    end)
    
    -- DISTANCIA DO BRING
    local B_Dist = CreateButton("DISTÂNCIA BRING: " .. BringDistance, function()
        if BringDistance == 5 then BringDistance = 10
        elseif BringDistance == 10 then BringDistance = 15
        elseif BringDistance == 15 then BringDistance = 20
        else BringDistance = 5 end
    end)

    -- FLY 
    local B_Fly = CreateButton("FLY (VOO): OFF", function() 
        Fly_Enabled = not Fly_Enabled
        Notify("FLY", Fly_Enabled and "ATIVADO" or "DESATIVADO")
        if Fly_Enabled then FlyFunction() end
    end)
    
    -- VELOCIDADE FLY
    local B_FlySpeed = CreateButton("VELOCIDADE FLY: " .. FlySpeed, function()
        if FlySpeed == 20 then FlySpeed = 50
        elseif FlySpeed == 50 then FlySpeed = 100
        else FlySpeed = 20 end
    end)

    local B_Noclip = CreateButton("NOCLIP: OFF", function() Noclip_Enabled = not Noclip_Enabled; Notify("NOCLIP", Noclip_Enabled and "ATIVADO" or "DESATIVADO") end)

    local B_F2 = CreateButton("F2 (JAIL): OFF", function() 
        F2_Mode = not F2_Mode; Notify("F2 JAIL", F2_Mode and "ATIVADO" or "DESATIVADO")
        if not F2_Mode and ZombieFolder then for _,z in pairs(ZombieFolder:GetChildren()) do local r = z:FindFirstChild("HumanoidRootPart"); if r then r.Anchored = false end end end
    end)

    local B_F3 = CreateButton("F3 (FIRE): OFF", function() F3_Mode = not F3_Mode; Notify("F3 FIRE", F3_Mode and "ATIVADO" or "DESATIVADO") end)

    local B_Switch = CreateButton("AUTO SWITCH: OFF", function() AutoSwitch_Enabled = not AutoSwitch_Enabled; Notify("AUTO SWITCH", AutoSwitch_Enabled and "ATIVADO" or "DESATIVADO") end)
    local B_Loot = CreateButton("AUTO LOOT (TP): OFF", function() AutoLoot_Enabled = not AutoLoot_Enabled; if AutoLoot_Enabled then PerformLootRun() end end)
    local B_Time = CreateButton("TEMPO LOOT: 60s", function()
        if LootInterval == 30 then LootInterval = 60 elseif LootInterval == 60 then LootInterval = 120 elseif LootInterval == 120 then LootInterval = 300 else LootInterval = 30 end
    end)
    local B_Hitbox = CreateButton("HITBOX: OFF", function() Hitbox_Enabled = not Hitbox_Enabled end)
    local B_Ammo = CreateButton("EXTENDED MAG: OFF", function() CombineAmmo_Enabled = not CombineAmmo_Enabled; Notify("MUNIÇÃO", CombineAmmo_Enabled and "ATIVADO" or "DESATIVADO") end)
    
    local B_Lava = CreateButton("REMOVER LAVA", function()
        if workspace:FindFirstChild("TouchLava") then workspace.TouchLava:Destroy(); Notify("MAPA", "Lava removida com sucesso!") else Notify("MAPA", "Lava não encontrada.") end
    end, Color3.fromRGB(200, 80, 0))

    local B_Close = CreateButton("FECHAR SCRIPT", function()
        Bring_Enabled = false; Fly_Enabled = false; Noclip_Enabled = false; F2_Mode = false; F3_Mode = false; Hitbox_Enabled = false
        AutoLoot_Enabled = false; IsShooting = false; AutoSwitch_Enabled = false; CombineAmmo_Enabled = false
        if ZombieFolder then for _,z in pairs(ZombieFolder:GetChildren()) do local r = z:FindFirstChild("HumanoidRootPart"); if r then r.Anchored = false end end end
        for _,c in pairs(Connections) do c:Disconnect() end
        ScreenGui:Destroy()
    end, Color3.fromRGB(100, 0, 0))

    task.spawn(function()
        while ScreenGui.Parent do
            local function Paint(btn, state, txtOn, txtOff)
                btn.Text = state and txtOn or txtOff
                btn.TextColor3 = state and Color3.fromRGB(0, 255, 100) or Color3.fromRGB(200, 200, 200)
                btn.BackgroundColor3 = state and Color3.fromRGB(30, 50, 30) or Color3.fromRGB(35, 35, 35)
            end
            Paint(B_F1, Bring_Enabled, "BRING (F1): ON", "BRING (F1): OFF")
            Paint(B_Fly, Fly_Enabled, "FLY (VOO): ON", "FLY (VOO): OFF")
            Paint(B_Noclip, Noclip_Enabled, "NOCLIP: ON", "NOCLIP: OFF")
            Paint(B_F2, F2_Mode, "F2 (JAIL): ON", "F2 (JAIL): OFF")
            Paint(B_F3, F3_Mode, "F3 (FIRE): ON", "F3 (FIRE): OFF")
            Paint(B_Switch, AutoSwitch_Enabled, "AUTO SWITCH: ON", "AUTO SWITCH: OFF")
            Paint(B_Loot, AutoLoot_Enabled, "AUTO LOOT (TP): ON", "AUTO LOOT (TP): OFF")
            Paint(B_Hitbox, Hitbox_Enabled, "HITBOX: ON", "HITBOX: OFF")
            Paint(B_Ammo, CombineAmmo_Enabled, "EXTENDED MAG: ON", "EXTENDED MAG: OFF")
            
            B_Time.Text = "TEMPO LOOT: " .. LootInterval .. "s"
            B_Dist.Text = "DISTÂNCIA BRING: " .. BringDistance
            B_FlySpeed.Text = "VELOCIDADE FLY: " .. FlySpeed
            task.wait(0.2)
        end
    end)

    table.insert(Connections, UserInputService.InputBegan:Connect(function(i,p)
        if not p then
            if i.KeyCode == Enum.KeyCode.F1 then
                Bring_Enabled = not Bring_Enabled
                Notify("BRING (F1)", Bring_Enabled and "ATIVADO" or "DESATIVADO")
                if not Bring_Enabled and ZombieFolder then for _,z in pairs(ZombieFolder:GetChildren()) do local r = z:FindFirstChild("HumanoidRootPart"); if r then r.Anchored = false end end end
            elseif i.KeyCode == Enum.KeyCode.F2 then
                F2_Mode = not F2_Mode; Notify("F2 JAIL", F2_Mode and "ATIVADO" or "DESATIVADO")
                if not F2_Mode and ZombieFolder then for _,z in pairs(ZombieFolder:GetChildren()) do local r = z:FindFirstChild("HumanoidRootPart"); if r then r.Anchored = false end end end
            elseif i.KeyCode == Enum.KeyCode.F3 then
                F3_Mode = not F3_Mode; Notify("F3 FIRE", F3_Mode and "ATIVADO" or "DESATIVADO")
            end
        end
    end))
end

if ZombieFolder then
    table.insert(Connections, ZombieFolder.ChildAdded:Connect(function(c) if c:IsA("Model") and Hitbox_Enabled then task.wait(0.1); ExpandHitbox(c) end end))
    table.insert(Connections, ZombieFolder.ChildRemoved:Connect(function(c) local n = c.Name:lower(); if n:match("fire") or n:match("fogo") then Notify("DROP DE FOGO", "Zumbi de fogo morreu!") end end))
end

table.insert(Connections, RunService.RenderStepped:Connect(function()
    JailLoop(); AimAndShootLoop(); BringZombiesLoop()  
    if Hitbox_Enabled and ZombieFolder then for _,z in pairs(ZombieFolder:GetChildren()) do if z:IsA("Model") then ExpandHitbox(z) end end end
    if CombineAmmo_Enabled then RunCombineAmmo() end
end))

CriarMenu()
