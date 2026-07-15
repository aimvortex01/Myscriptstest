local P = game:GetService("Players").LocalPlayer
local RS = game:GetService("RunService")
local VU = game:GetService("VirtualUser")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- ================================
-- TOWER CLIMB v12 VARIABLES
-- ================================
local speedMult = 1.0
local baseSpeed = 300
local climbOn = false
local loopOn = false
local con = nil
local bv = nil
local dur = 3
local restTime = 2
local totalCycles = 0
local scriptAlive = true

-- ================================
-- JOIN NOTIFICATION VARIABLES
-- ================================
local NOTIF_DURATION = 4
local NOTIF_WIDTH = 320
local NOTIF_HEIGHT = 80
local SPACING = 10
local SLIDE_TIME = 0.4
local EDGE_PAD = 20
local activeNotifs = {}

-- ================================
-- TOWER CLIMB FUNCTIONS
-- ================================
local function hrp()
    local c = P.Character
    if c then return c:FindFirstChild("HumanoidRootPart") end
end

local function hum()
    local c = P.Character
    if c then return c:FindFirstChild("Humanoid") end
end

local function getPhysicsSpeed()
    return math.min(baseSpeed * speedMult, 350)
end

local function getActualDuration()
    return dur * speedMult
end

local function properReset()
    local h = hrp()
    local hm = hum()
    if not h or not hm then return end
    for _, v in pairs(h:GetChildren()) do
        if v:IsA("BodyVelocity") or v:IsA("BodyForce") or v:IsA("BodyPosition") then
            v:Destroy()
        end
    end
    h.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    h.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
    hm:ChangeState(Enum.HumanoidStateType.GettingUp)
    task.wait(0.15)
    hm:ChangeState(Enum.HumanoidStateType.Running)
    task.wait(0.2)
    local ray = workspace:Raycast(h.Position, Vector3.new(0, -50, 0))
    if ray then
        h.CFrame = CFrame.new(h.Position.X, ray.Position.Y + 3, h.Position.Z)
    end
    h.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
    task.wait(0.3)
end

local function startClimb()
    if con then con:Disconnect() end
    bv = nil
    local physSpeed = getPhysicsSpeed()
    con = RS.Heartbeat:Connect(function(dt)
        if not climbOn then
            if bv then bv:Destroy() bv = nil end
            return
        end
        local h = hrp()
        if not h then return end
        if not bv or not bv.Parent then
            bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(0, math.huge, 0)
            bv.Velocity = Vector3.new(0, 0, 0)
            bv.Parent = h
        end
        bv.Velocity = Vector3.new(0, physSpeed, 0)
    end)
end

local function stopClimb()
    if con then con:Disconnect() con = nil end
    if bv then bv:Destroy() bv = nil end
    local h = hrp()
    if h then
        for _, v in pairs(h:GetChildren()) do
            if v:IsA("BodyVelocity") or v:IsA("BodyForce") or v:IsA("BodyPosition") then
                v:Destroy()
            end
        end
    end
end

local function waitLand()
    local t = 0
    while t < 25 do
        task.wait(0.25)
        t = t + 0.25
        local hm = hum()
        if hm then
            local st = hm:GetState()
            if st == Enum.HumanoidStateType.Running then break end
            if st == Enum.HumanoidStateType.Landed then break end
            if hm.FloorMaterial ~= Enum.Material.Air then break end
        end
    end
end

local function doLoop()
    task.spawn(function()
        while loopOn and scriptAlive do
            local h = hrp()
            local hm = hum()
            if not h or not hm then
                task.wait(1)
                continue
            end
            properReset()
            climbOn = true
            startClimb()
            task.wait(getActualDuration())
            climbOn = false
            stopClimb()
            local h2 = hrp()
            if h2 then
                h2.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
                h2.AssemblyAngularVelocity = Vector3.new(0, 0, 0)
            end
            task.wait(0.1)
            if hm then
                hm:ChangeState(Enum.HumanoidStateType.Freefall)
            end
            waitLand()
            task.wait(restTime)
            totalCycles = totalCycles + 1
        end
    end)
end

local function stopLoop()
    loopOn = false
    climbOn = false
    stopClimb()
    properReset()
end
-- ================================
-- JOIN NOTIFICATION FUNCTIONS
-- ================================
local notifGui = nil

local function repositionNotifs()
    for i, data in ipairs(activeNotifs) do
        local frame = data.Frame
        if not frame or not frame.Parent then continue end
        local targetY = -(EDGE_PAD + (NOTIF_HEIGHT + SPACING) * (i - 1))
        TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(1, -EDGE_PAD, 1, targetY)
        }):Play()
    end
end

local function createNotification(player)
    local frame = Instance.new("Frame")
    frame.Name = "JoinNotif_" .. player.UserId
    frame.Size = UDim2.new(0, NOTIF_WIDTH, 0, NOTIF_HEIGHT)
    frame.AnchorPoint = Vector2.new(1, 1)
    frame.Position = UDim2.new(1, NOTIF_WIDTH + 50, 1, -EDGE_PAD)
    frame.BackgroundColor3 = Color3.fromRGB(25, 25, 35)
    frame.BackgroundTransparency = 0.1
    frame.BorderSizePixel = 0
    frame.ZIndex = 100
    frame.Parent = notifGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 12)
    corner.Parent = frame

    local stroke = Instance.new("UIStroke")
    stroke.Color = Color3.fromRGB(0, 170, 255)
    stroke.Thickness = 1.5
    stroke.Transparency = 0.3
    stroke.Parent = frame

    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(0, 5, 1, -8)
    accentBar.Position = UDim2.new(0, 2, 0, 4)
    accentBar.BackgroundColor3 = Color3.fromRGB(0, 200, 255)
    accentBar.BorderSizePixel = 0
    accentBar.ZIndex = 101
    accentBar.Parent = frame

    local accentCorner = Instance.new("UICorner")
    accentCorner.CornerRadius = UDim.new(0, 8)
    accentCorner.Parent = accentBar

    local glow = Instance.new("Frame")
    glow.Size = UDim2.new(0, 15, 1, -4)
    glow.Position = UDim2.new(0, -2, 0, 2)
    glow.BackgroundColor3 = Color3.fromRGB(0, 180, 255)
    glow.BackgroundTransparency = 0.7
    glow.BorderSizePixel = 0
    glow.ZIndex = 100
    glow.Parent = frame

    local glowCorner = Instance.new("UICorner")
    glowCorner.CornerRadius = UDim.new(0, 8)
    glowCorner.Parent = glow

    local avatar = Instance.new("ImageLabel")
    avatar.Size = UDim2.new(0, 56, 0, 56)
    avatar.Position = UDim2.new(0, 20, 0.5, -28)
    avatar.BackgroundColor3 = Color3.fromRGB(40, 40, 55)
    avatar.Image = ""
    avatar.ZIndex = 102
    avatar.Parent = frame

    local avatarCorner = Instance.new("UICorner")
    avatarCorner.CornerRadius = UDim.new(1, 0)
    avatarCorner.Parent = avatar

    local avatarStroke = Instance.new("UIStroke")
    avatarStroke.Color = Color3.fromRGB(0, 140, 200)
    avatarStroke.Thickness = 1.5
    avatarStroke.Transparency = 0.5
    avatarStroke.Parent = avatar

    task.spawn(function()
        local success, content = pcall(function()
            return Players:GetUserThumbnailAsync(
                player.UserId,
                Enum.ThumbnailType.HeadShot,
                Enum.ThumbnailSize.Size100x100
            )
        end)
        if success and avatar.Parent then
            avatar.Image = content
        end
    end)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -95, 0, 18)
    titleLabel.Position = UDim2.new(0, 86, 0, 10)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = "PLAYER JOINED"
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 11
    titleLabel.TextColor3 = Color3.fromRGB(0, 200, 255)
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.ZIndex = 102
    titleLabel.Parent = frame

    local nameLabel = Instance.new("TextLabel")
    nameLabel.Size = UDim2.new(1, -95, 0, 26)
    nameLabel.Position = UDim2.new(0, 86, 0, 28)
    nameLabel.BackgroundTransparency = 1
    nameLabel.Text = player.DisplayName
    nameLabel.Font = Enum.Font.GothamBold
    nameLabel.TextSize = 18
    nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    nameLabel.TextXAlignment = Enum.TextXAlignment.Left
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd
    nameLabel.ZIndex = 102
    nameLabel.Parent = frame

    if player.DisplayName ~= player.Name then
        local usernameLabel = Instance.new("TextLabel")
        usernameLabel.Size = UDim2.new(1, -95, 0, 14)
        usernameLabel.Position = UDim2.new(0, 86, 0, 54)
        usernameLabel.BackgroundTransparency = 1
        usernameLabel.Text = "@" .. player.Name
        usernameLabel.Font = Enum.Font.Gotham
        usernameLabel.TextSize = 10
        usernameLabel.TextColor3 = Color3.fromRGB(140, 140, 155)
        usernameLabel.TextXAlignment = Enum.TextXAlignment.Left
        usernameLabel.ZIndex = 102
        usernameLabel.Parent = frame
    end

    local data = { Frame = frame, Removing = false }
    table.insert(activeNotifs, 1, data)
    repositionNotifs()

    task.wait()
    local myIndex = 1
    for i, d in ipairs(activeNotifs) do
        if d == data then myIndex = i break end
    end
    local slideTargetY = -(EDGE_PAD + (NOTIF_HEIGHT + SPACING) * (myIndex - 1))

    TweenService:Create(frame, TweenInfo.new(SLIDE_TIME, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -EDGE_PAD, 1, slideTargetY)
    }):Play()

    task.delay(NOTIF_DURATION, function()
        if not frame.Parent then return end
        data.Removing = true

        local slideOut = TweenService:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Position = UDim2.new(1, NOTIF_WIDTH + 50, 1, frame.Position.Y.Offset),
            BackgroundTransparency = 1
        })

        for _, child in ipairs(frame:GetDescendants()) do
            if child:IsA("TextLabel") then
                TweenService:Create(child, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
            elseif child:IsA("ImageLabel") then
                TweenService:Create(child, TweenInfo.new(0.3), {ImageTransparency = 1}):Play()
            elseif child:IsA("Frame") and child ~= frame then
                TweenService:Create(child, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
            elseif child:IsA("UIStroke") then
                TweenService:Create(child, TweenInfo.new(0.3), {Transparency = 1}):Play()
            end
        end

        slideOut:Play()
        slideOut.Completed:Wait()

        for i, d in ipairs(activeNotifs) do
            if d == data then
                table.remove(activeNotifs, i)
                break
            end
        end
        frame:Destroy()
        repositionNotifs()
    end)
end
-- ================================
-- MAIN GUI
-- ================================
local function makeGUI()
    local old = P.PlayerGui:FindFirstChild("TC12")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "TC12"
    sg.ResetOnSpawn = false
    sg.Parent = P.PlayerGui

    local oldNotif = P.PlayerGui:FindFirstChild("JoinNotificationGui")
    if oldNotif then oldNotif:Destroy() end

    notifGui = Instance.new("ScreenGui")
    notifGui.Name = "JoinNotificationGui"
    notifGui.ResetOnSpawn = false
    notifGui.IgnoreGuiInset = true
    notifGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    notifGui.Parent = P.PlayerGui

    local f = Instance.new("Frame")
    f.Size = UDim2.new(0, 210, 0, 510)
    f.Position = UDim2.new(0, 8, 0.2, 0)
    f.BackgroundColor3 = Color3.fromRGB(10, 10, 20)
    f.BorderSizePixel = 0
    f.Active = true
    f.Draggable = true
    f.Parent = sg
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 10)
    local sk = Instance.new("UIStroke", f)
    sk.Color = Color3.fromRGB(0, 160, 255)

    -- ===== TITLE BAR =====
    local titleBar = Instance.new("Frame")
    titleBar.Size = UDim2.new(1, 0, 0, 32)
    titleBar.BackgroundColor3 = Color3.fromRGB(6, 6, 14)
    titleBar.BorderSizePixel = 0
    titleBar.Parent = f
    Instance.new("UICorner", titleBar).CornerRadius = UDim.new(0, 10)

    local tl = Instance.new("TextLabel")
    tl.Size = UDim2.new(1, -70, 1, 0)
    tl.Position = UDim2.new(0, 8, 0, 0)
    tl.BackgroundTransparency = 1
    tl.Text = "TOWER CLIMB v12"
    tl.TextColor3 = Color3.fromRGB(0, 180, 255)
    tl.TextSize = 13
    tl.Font = Enum.Font.GothamBlack
    tl.TextXAlignment = Enum.TextXAlignment.Left
    tl.Parent = titleBar

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 28, 0, 28)
    minBtn.Position = UDim2.new(1, -64, 0, 2)
    minBtn.BackgroundColor3 = Color3.fromRGB(180, 150, 0)
    minBtn.Text = "—"
    minBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    minBtn.TextSize = 16
    minBtn.Font = Enum.Font.GothamBold
    minBtn.BorderSizePixel = 0
    minBtn.Parent = titleBar
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

    local killBtn = Instance.new("TextButton")
    killBtn.Size = UDim2.new(0, 28, 0, 28)
    killBtn.Position = UDim2.new(1, -33, 0, 2)
    killBtn.BackgroundColor3 = Color3.fromRGB(200, 30, 30)
    killBtn.Text = "X"
    killBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    killBtn.TextSize = 14
    killBtn.Font = Enum.Font.GothamBold
    killBtn.BorderSizePixel = 0
    killBtn.Parent = titleBar
    Instance.new("UICorner", killBtn).CornerRadius = UDim.new(0, 6)

    local showBtn = Instance.new("TextButton")
    showBtn.Size = UDim2.new(0, 44, 0, 44)
    showBtn.Position = UDim2.new(0, 8, 0.5, -22)
    showBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 200)
    showBtn.Text = "SHOW"
    showBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    showBtn.TextSize = 8
    showBtn.Font = Enum.Font.GothamBold
    showBtn.BorderSizePixel = 0
    showBtn.Visible = false
    showBtn.Parent = sg
    Instance.new("UICorner", showBtn).CornerRadius = UDim.new(0, 22)
    local showStroke = Instance.new("UIStroke", showBtn)
    showStroke.Color = Color3.fromRGB(0, 200, 255)
    showStroke.Thickness = 1.5

    local miniStatus = Instance.new("TextLabel")
    miniStatus.Size = UDim2.new(0, 100, 0, 16)
    miniStatus.Position = UDim2.new(0, 56, 0.5, -8)
    miniStatus.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    miniStatus.BackgroundTransparency = 0.5
    miniStatus.Text = "RUNNING"
    miniStatus.TextColor3 = Color3.fromRGB(0, 255, 100)
    miniStatus.TextSize = 9
    miniStatus.Font = Enum.Font.GothamBold
    miniStatus.BorderSizePixel = 0
    miniStatus.Visible = false
    miniStatus.Parent = sg
    Instance.new("UICorner", miniStatus).CornerRadius = UDim.new(0, 4)

    minBtn.MouseButton1Click:Connect(function()
        f.Visible = false
        showBtn.Visible = true
        miniStatus.Visible = true
    end)

    showBtn.MouseButton1Click:Connect(function()
        f.Visible = true
        showBtn.Visible = false
        miniStatus.Visible = false
    end)

    killBtn.MouseButton1Click:Connect(function()
        scriptAlive = false
        loopOn = false
        climbOn = false
        stopClimb()
        properReset()
        sg:Destroy()
        if notifGui then notifGui:Destroy() end
        print("TOWER CLIMB v12 - SCRIPT KILLED")
    end)

    task.spawn(function()
        while scriptAlive do
            task.wait(0.5)
            if loopOn then
                miniStatus.Text = "LOOP | " .. totalCycles
                miniStatus.TextColor3 = Color3.fromRGB(0, 255, 100)
            elseif climbOn then
                miniStatus.Text = "CLIMB | " .. math.floor(getPhysicsSpeed())
                miniStatus.TextColor3 = Color3.fromRGB(0, 180, 255)
            else
                miniStatus.Text = "IDLE"
                miniStatus.TextColor3 = Color3.fromRGB(150, 150, 150)
            end
        end
    end)

    -- ===== STATUS LABELS =====
    local st = Instance.new("TextLabel")
    st.Size = UDim2.new(1, -12, 0, 28)
    st.Position = UDim2.new(0, 6, 0, 36)
    st.BackgroundTransparency = 1
    st.Text = "Ready - Physics speed locked at 350"
    st.TextColor3 = Color3.fromRGB(0, 200, 100)
    st.TextSize = 9
    st.Font = Enum.Font.Gotham
    st.TextWrapped = true
    st.TextXAlignment = Enum.TextXAlignment.Left
    st.Parent = f

    local info = Instance.new("TextLabel")
    info.Size = UDim2.new(1, -12, 0, 18)
    info.Position = UDim2.new(0, 6, 0, 58)
    info.BackgroundTransparency = 1
    info.Text = "Higher mult = longer climb = more coins"
    info.TextColor3 = Color3.fromRGB(180, 160, 0)
    info.TextSize = 8
    info.Font = Enum.Font.Gotham
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.Parent = f

    local counter = Instance.new("TextLabel")
    counter.Size = UDim2.new(1, -12, 0, 14)
    counter.Position = UDim2.new(0, 6, 0, 76)
    counter.BackgroundTransparency = 1
    counter.Text = "Cycles: 0"
    counter.TextColor3 = Color3.fromRGB(150, 150, 170)
    counter.TextSize = 10
    counter.Font = Enum.Font.Gotham
    counter.TextXAlignment = Enum.TextXAlignment.Left
    counter.Parent = f

    task.spawn(function()
        while scriptAlive do
            task.wait(0.5)
            local phys = getPhysicsSpeed()
            local actDur = getActualDuration()
            counter.Text = "Cycles: " .. totalCycles .. " | Phys: " .. math.floor(phys) .. " | Dur: " .. string.format("%.1f", actDur) .. "s"
        end
    end)

    local yy = 94

    local function btn(txt, color, cb)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -12, 0, 32)
        b.Position = UDim2.new(0, 6, 0, yy)
        b.BackgroundColor3 = color
        b.Text = txt
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.TextSize = 13
        b.Font = Enum.Font.GothamBold
        b.BorderSizePixel = 0
        b.Parent = f
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        b.MouseButton1Click:Connect(cb)
        yy = yy + 38
        return b
    end

    local function tog(txt, cb)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(1, -12, 0, 32)
        b.Position = UDim2.new(0, 6, 0, yy)
        b.BackgroundColor3 = Color3.fromRGB(55, 15, 15)
        b.Text = txt .. " [OFF]"
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.TextSize = 13
        b.Font = Enum.Font.GothamBold
        b.BorderSizePixel = 0
        b.Parent = f
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
        local on = false
        b.MouseButton1Click:Connect(function()
            on = not on
            if on then
                b.BackgroundColor3 = Color3.fromRGB(0, 120, 55)
                b.Text = txt .. " [ON]"
            else
                b.BackgroundColor3 = Color3.fromRGB(55, 15, 15)
                b.Text = txt .. " [OFF]"
            end
            cb(on)
        end)
        yy = yy + 38
        return b
    end

    -- TOGGLES
    tog("Auto Climb", function(v)
        climbOn = v
        if v then
            startClimb()
            st.Text = "Climbing | Phys: " .. math.floor(getPhysicsSpeed())
            st.TextColor3 = Color3.fromRGB(0, 200, 100)
        else
            stopClimb()
            st.Text = "Stopped"
            st.TextColor3 = Color3.fromRGB(200, 160, 0)
        end
    end)

    tog("Auto Loop", function(v)
        loopOn = v
        if v then
            totalCycles = 0
            doLoop()
            st.Text = "Loop: Reset > Climb > Fall > Coins"
            st.TextColor3 = Color3.fromRGB(0, 180, 255)
        else
            stopLoop()
            st.Text = "Loop stopped"
            st.TextColor3 = Color3.fromRGB(200, 80, 80)
        end
    end)

    btn("STOP ALL", Color3.fromRGB(160, 30, 30), function()
        stopLoop()
        st.Text = "All stopped + Reset"
        st.TextColor3 = Color3.fromRGB(200, 60, 60)
    end)

    btn("RESET STATE", Color3.fromRGB(140, 100, 0), function()
        properReset()
        st.Text = "Character state reset"
        st.TextColor3 = Color3.fromRGB(0, 200, 100)
    end)    -- DIVIDER 1
    yy = yy + 2
    local dv1 = Instance.new("Frame")
    dv1.Size = UDim2.new(1, -12, 0, 1)
    dv1.Position = UDim2.new(0, 6, 0, yy)
    dv1.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    dv1.BorderSizePixel = 0
    dv1.Parent = f
    yy = yy + 8

    -- SPEED MULTIPLIER
    local sml = Instance.new("TextLabel")
    sml.Size = UDim2.new(1, -12, 0, 14)
    sml.Position = UDim2.new(0, 6, 0, yy)
    sml.BackgroundTransparency = 1
    sml.Text = "Speed Multiplier"
    sml.TextColor3 = Color3.fromRGB(100, 100, 130)
    sml.TextSize = 9
    sml.Font = Enum.Font.Gotham
    sml.TextXAlignment = Enum.TextXAlignment.Left
    sml.Parent = f
    yy = yy + 18

    local speedOpts = {
        {mult = 0.5, label = "0.5x"},
        {mult = 1.0, label = "1x"},
        {mult = 1.5, label = "1.5x"},
        {mult = 2.0, label = "2x"},
        {mult = 3.0, label = "3x"},
        {mult = 4.0, label = "4x"},
        {mult = 5.0, label = "5x"},
        {mult = 7.0, label = "7x"},
        {mult = 10.0, label = "10x"},
    }

    local sBtns = {}
    for i, opt in ipairs(speedOpts) do
        local row = math.ceil(i / 5)
        local idx = ((i - 1) % 5) + 1
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 34, 0, 24)
        b.Position = UDim2.new(0, 6 + (idx - 1) * 38, 0, yy + (row - 1) * 28)
        b.BackgroundColor3 = (opt.mult == 1.0) and Color3.fromRGB(0, 120, 200) or Color3.fromRGB(20, 20, 38)
        b.Text = opt.label
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.TextSize = 9
        b.Font = Enum.Font.GothamBold
        b.BorderSizePixel = 0
        b.Parent = f
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
        sBtns[opt.mult] = b
        b.MouseButton1Click:Connect(function()
            speedMult = opt.mult
            for k, v in pairs(sBtns) do
                v.BackgroundColor3 = (k == opt.mult) and Color3.fromRGB(0, 120, 200) or Color3.fromRGB(20, 20, 38)
            end
            st.Text = "Speed: " .. opt.label .. " | Dur: " .. string.format("%.1f", getActualDuration()) .. "s"
            st.TextColor3 = Color3.fromRGB(0, 180, 255)
        end)
    end
    yy = yy + 60

    -- DIVIDER 2
    local dv2 = Instance.new("Frame")
    dv2.Size = UDim2.new(1, -12, 0, 1)
    dv2.Position = UDim2.new(0, 6, 0, yy)
    dv2.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    dv2.BorderSizePixel = 0
    dv2.Parent = f
    yy = yy + 8

    -- BASE DURATION
    local dl = Instance.new("TextLabel")
    dl.Size = UDim2.new(1, -12, 0, 14)
    dl.Position = UDim2.new(0, 6, 0, yy)
    dl.BackgroundTransparency = 1
    dl.Text = "Base Climb Duration"
    dl.TextColor3 = Color3.fromRGB(100, 100, 130)
    dl.TextSize = 9
    dl.Font = Enum.Font.Gotham
    dl.TextXAlignment = Enum.TextXAlignment.Left
    dl.Parent = f
    yy = yy + 16

    local durs = {2, 3, 4, 5, 6}
    local dBtns = {}
    for i, d in ipairs(durs) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 34, 0, 22)
        b.Position = UDim2.new(0, 6 + (i - 1) * 38, 0, yy)
        b.BackgroundColor3 = (d == 3) and Color3.fromRGB(0, 100, 160) or Color3.fromRGB(20, 20, 38)
        b.Text = d .. "s"
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.TextSize = 10
        b.Font = Enum.Font.GothamBold
        b.BorderSizePixel = 0
        b.Parent = f
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
        dBtns[d] = b
        b.MouseButton1Click:Connect(function()
            dur = d
            for k, v in pairs(dBtns) do
                v.BackgroundColor3 = (k == d) and Color3.fromRGB(0, 100, 160) or Color3.fromRGB(20, 20, 38)
            end
        end)
    end
    yy = yy + 28

    -- REST TIME
    local rl = Instance.new("TextLabel")
    rl.Size = UDim2.new(1, -12, 0, 14)
    rl.Position = UDim2.new(0, 6, 0, yy)
    rl.BackgroundTransparency = 1
    rl.Text = "Rest After Landing"
    rl.TextColor3 = Color3.fromRGB(100, 100, 130)
    rl.TextSize = 9
    rl.Font = Enum.Font.Gotham
    rl.TextXAlignment = Enum.TextXAlignment.Left
    rl.Parent = f
    yy = yy + 16

    local rests = {1, 2, 3, 4, 5}
    local rBtns = {}
    for i, r in ipairs(rests) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 34, 0, 22)
        b.Position = UDim2.new(0, 6 + (i - 1) * 38, 0, yy)
        b.BackgroundColor3 = (r == 2) and Color3.fromRGB(0, 100, 160) or Color3.fromRGB(20, 20, 38)
        b.Text = r .. "s"
        b.TextColor3 = Color3.fromRGB(255, 255, 255)
        b.TextSize = 10
        b.Font = Enum.Font.GothamBold
        b.BorderSizePixel = 0
        b.Parent = f
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 4)
        rBtns[r] = b
        b.MouseButton1Click:Connect(function()
            restTime = r
            for k, v in pairs(rBtns) do
                v.BackgroundColor3 = (k == r) and Color3.fromRGB(0, 100, 160) or Color3.fromRGB(20, 20, 38)
            end
        end)
    end
    yy = yy + 30

    -- DIVIDER 3
    local dv3 = Instance.new("Frame")
    dv3.Size = UDim2.new(1, -12, 0, 1)
    dv3.Position = UDim2.new(0, 6, 0, yy)
    dv3.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
    dv3.BorderSizePixel = 0
    dv3.Parent = f
    yy = yy + 8

    -- NOTIFICATION TOGGLE
    local notifOn = true
    local notifBtn = Instance.new("TextButton")
    notifBtn.Size = UDim2.new(1, -12, 0, 32)
    notifBtn.Position = UDim2.new(0, 6, 0, yy)
    notifBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 55)
    notifBtn.Text = "Join Alert [ON]"
    notifBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    notifBtn.TextSize = 13
    notifBtn.Font = Enum.Font.GothamBold
    notifBtn.BorderSizePixel = 0
    notifBtn.Parent = f
    Instance.new("UICorner", notifBtn).CornerRadius = UDim.new(0, 6)
    notifBtn.MouseButton1Click:Connect(function()
        notifOn = not notifOn
        if notifOn then
            notifBtn.BackgroundColor3 = Color3.fromRGB(0, 120, 55)
            notifBtn.Text = "Join Alert [ON]"
        else
            notifBtn.BackgroundColor3 = Color3.fromRGB(55, 15, 15)
            notifBtn.Text = "Join Alert [OFF]"
        end
    end)
    yy = yy + 38

    -- KILL SCRIPT
    btn("KILL SCRIPT", Color3.fromRGB(180, 20, 20), function()
        scriptAlive = false
        loopOn = false
        climbOn = false
        stopClimb()
        properReset()
        sg:Destroy()
        if notifGui then notifGui:Destroy() end
        print("SCRIPT KILLED - Run again to restart")
    end)

    -- JOIN NOTIFICATION EVENT
    Players.PlayerAdded:Connect(function(player)
        if not scriptAlive then return end
        if not notifOn then return end
        if player == P then return end
        task.wait(0.5)
        if not notifOn then return end
        createNotification(player)
    end)
end

-- ================================
-- ANTI AFK + RESPAWN + LAUNCH
-- ================================
P.Idled:Connect(function()
    pcall(function()
        VU:Button2Down(Vector2.new(), workspace.CurrentCamera.CFrame)
        task.wait(0.1)
        VU:Button2Up(Vector2.new(), workspace.CurrentCamera.CFrame)
    end)
end)

P.CharacterAdded:Connect(function()
    task.wait(3)
    if not scriptAlive then return end
    properReset()
    if climbOn then startClimb() end
    if loopOn then doLoop() end
end)

makeGUI()
print("TOWER CLIMB v12 + JOIN ALERTS LOADED")
print("— = Minimize | X = Kill Script")
