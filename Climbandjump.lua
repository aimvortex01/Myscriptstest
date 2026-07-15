-- ========================================
-- TOWER CLIMB v12 — GOD LEVEL UI
-- ========================================
local Players = game:GetService("Players")
local RS = game:GetService("RunService")
local VU = game:GetService("VirtualUser")
local TS = game:GetService("TweenService")
local P = Players.LocalPlayer

local speedMult, baseSpeed = 1.0, 300
local climbOn, loopOn = false, false
local con, bv = nil, nil
local dur, restTime = 3, 2
local totalCycles = 0
local scriptAlive = true

local CLR = {
    bg = Color3.fromRGB(6, 8, 15),
    surface = Color3.fromRGB(17, 24, 39),
    elevated = Color3.fromRGB(25, 35, 55),
    border = Color3.fromRGB(30, 41, 59),
    accent = Color3.fromRGB(0, 212, 255),
    purple = Color3.fromRGB(124, 58, 237),
    green = Color3.fromRGB(16, 185, 129),
    red = Color3.fromRGB(239, 68, 68),
    amber = Color3.fromRGB(245, 158, 11),
    text = Color3.fromRGB(248, 250, 252),
    text2 = Color3.fromRGB(148, 163, 184),
    muted = Color3.fromRGB(100, 116, 139),
}

local function hrp() local c = P.Character; return c and c:FindFirstChild("HumanoidRootPart") end
local function hum() local c = P.Character; return c and c:FindFirstChild("Humanoid") end
local function getPhysicsSpeed() return math.min(baseSpeed * speedMult, 350) end
local function getActualDuration() return dur * speedMult end

local function properReset()
    local h, hm = hrp(), hum()
    if not h or not hm then return end
    for _, v in pairs(h:GetChildren()) do
        if v:IsA("BodyVelocity") or v:IsA("BodyForce") or v:IsA("BodyPosition") then v:Destroy() end
    end
    h.AssemblyLinearVelocity = Vector3.zero
    h.AssemblyAngularVelocity = Vector3.zero
    hm:ChangeState(Enum.HumanoidStateType.GettingUp)
    task.wait(0.15)
    hm:ChangeState(Enum.HumanoidStateType.Running)
    task.wait(0.2)
    local ray = workspace:Raycast(h.Position, Vector3.new(0, -50, 0))
    if ray then h.CFrame = CFrame.new(h.Position.X, ray.Position.Y + 3, h.Position.Z) end
    h.AssemblyLinearVelocity = Vector3.zero
    task.wait(0.3)
end

local function startClimb()
    if con then con:Disconnect() end; bv = nil
    local spd = getPhysicsSpeed()
    con = RS.Heartbeat:Connect(function()
        if not climbOn then if bv then bv:Destroy() bv = nil end; return end
        local h = hrp(); if not h then return end
        if not bv or not bv.Parent then
            bv = Instance.new("BodyVelocity")
            bv.MaxForce = Vector3.new(0, math.huge, 0)
            bv.Velocity = Vector3.zero; bv.Parent = h
        end
        bv.Velocity = Vector3.new(0, spd, 0)
    end)
end

local function stopClimb()
    if con then con:Disconnect() con = nil end
    if bv then bv:Destroy() bv = nil end
    local h = hrp()
    if h then for _, v in pairs(h:GetChildren()) do
        if v:IsA("BodyVelocity") or v:IsA("BodyForce") or v:IsA("BodyPosition") then v:Destroy() end
    end end
end

local function waitLand()
    local t = 0
    while t < 25 do
        task.wait(0.25); t += 0.25
        local hm = hum()
        if hm then
            local s = hm:GetState()
            if s == Enum.HumanoidStateType.Running or s == Enum.HumanoidStateType.Landed then break end
            if hm.FloorMaterial ~= Enum.Material.Air then break end
        end
    end
end

local function doLoop()
    task.spawn(function()
        while loopOn and scriptAlive do
            local h, hm = hrp(), hum()
            if not h or not hm then task.wait(1) continue end
            properReset(); climbOn = true; startClimb()
            task.wait(getActualDuration())
            climbOn = false; stopClimb()
            local h2 = hrp()
            if h2 then h2.AssemblyLinearVelocity = Vector3.zero; h2.AssemblyAngularVelocity = Vector3.zero end
            task.wait(0.1)
            if hm then hm:ChangeState(Enum.HumanoidStateType.Freefall) end
            waitLand(); task.wait(restTime); totalCycles += 1
        end
    end)
end

local function stopLoop()
    loopOn = false; climbOn = false; stopClimb(); properReset()
end
-- ========================================
-- GUI HELPERS
-- ========================================
local function addCorner(p, r) local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0, r or 8); c.Parent = p; return c end
local function addStroke(p, col, th) local s = Instance.new("UIStroke"); s.Color = col or CLR.border; s.Thickness = th or 1; s.Parent = p; return s end

local function makeToggle(parent, text, default, cb)
    local fr = Instance.new("Frame")
    fr.Size = UDim2.new(1, 0, 0, 44)
    fr.BackgroundColor3 = CLR.surface; fr.BorderSizePixel = 0
    fr.Parent = parent; addCorner(fr, 10); addStroke(fr, CLR.border, 1)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -72, 1, 0); lbl.Position = UDim2.new(0, 14, 0, 0)
    lbl.BackgroundTransparency = 1; lbl.Text = text
    lbl.TextColor3 = CLR.text; lbl.TextSize = 13
    lbl.Font = Enum.Font.GothamMedium; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = fr

    local tk = Instance.new("Frame")
    tk.Size = UDim2.new(0, 46, 0, 24); tk.Position = UDim2.new(1, -60, 0.5, -12)
    tk.BackgroundColor3 = default and CLR.green or Color3.fromRGB(55, 65, 81)
    tk.BorderSizePixel = 0; tk.Parent = fr; addCorner(tk, 12)

    local ci = Instance.new("Frame")
    ci.Size = UDim2.new(0, 20, 0, 20)
    ci.Position = default and UDim2.new(1, -22, 0, 2) or UDim2.new(0, 2, 0, 2)
    ci.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ci.BorderSizePixel = 0; ci.Parent = tk; addCorner(ci, 10)

    local on = default
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0); btn.BackgroundTransparency = 1
    btn.Text = ""; btn.ZIndex = 2; btn.Parent = fr

    btn.MouseButton1Click:Connect(function()
        on = not on
        TS:Create(ci, TweenInfo.new(0.2), {Position = on and UDim2.new(1, -22, 0, 2) or UDim2.new(0, 2, 0, 2)}):Play()
        TS:Create(tk, TweenInfo.new(0.2), {BackgroundColor3 = on and CLR.green or Color3.fromRGB(55, 65, 81)}):Play()
        cb(on)
    end)
    return {Set = function(v)
        on = v
        ci.Position = on and UDim2.new(1, -22, 0, 2) or UDim2.new(0, 2, 0, 2)
        tk.BackgroundColor3 = on and CLR.green or Color3.fromRGB(55, 65, 81)
    end}
end

local function makeBtn(parent, text, color, hover, cb)
    local b = Instance.new("TextButton")
    b.Size = UDim2.new(1, 0, 0, 40); b.BackgroundColor3 = color
    b.Text = ""; b.BorderSizePixel = 0; b.AutoButtonColor = false
    b.Parent = parent; addCorner(b, 10)

    local l = Instance.new("TextLabel")
    l.Size = UDim2.new(1, 0, 1, 0); l.BackgroundTransparency = 1
    l.Text = text; l.TextColor3 = CLR.text; l.TextSize = 14
    l.Font = Enum.Font.GothamBold; l.ZIndex = 2; l.Parent = b

    b.MouseEnter:Connect(function() TS:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = hover}):Play() end)
    b.MouseLeave:Connect(function() TS:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = color}):Play() end)
    b.MouseButton1Down:Connect(function() TS:Create(b, TweenInfo.new(0.05), {Size = UDim2.new(1, -4, 0, 38)}):Play() end)
    b.MouseButton1Up:Connect(function() TS:Create(b, TweenInfo.new(0.05), {Size = UDim2.new(1, 0, 0, 40)}):Play() end)
    b.MouseButton1Click:Connect(cb)
    return b
end

local function makeDivider(parent)
    local w = Instance.new("Frame"); w.Size = UDim2.new(1, 0, 0, 14)
    w.BackgroundTransparency = 1; w.Parent = parent
    local l = Instance.new("Frame"); l.Size = UDim2.new(1, 0, 0, 1)
    l.Position = UDim2.new(0, 0, 0.5, 0); l.AnchorPoint = Vector2.new(0, 0.5)
    l.BackgroundColor3 = CLR.border; l.BorderSizePixel = 0; l.Parent = w
    return w
end

local function makeSelectorRow(parent, labelText, options, defaultVal, cols, cb)
    local rowH, gap = 30, 4
    local rows = math.ceil(#options / cols)
    local totalH = 20 + rows * rowH + (rows - 1) * gap

    local fr = Instance.new("Frame")
    fr.Size = UDim2.new(1, 0, 0, totalH)
    fr.BackgroundTransparency = 1; fr.Parent = parent

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 18); lbl.BackgroundTransparency = 1
    lbl.Text = labelText; lbl.TextColor3 = CLR.muted; lbl.TextSize = 10
    lbl.Font = Enum.Font.GothamBold; lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.Parent = fr

    local availW = 260
    local btnW = math.floor((availW - gap * (cols - 1)) / cols)

    local btns = {}
    for i, opt in ipairs(options) do
        local row = math.ceil(i / cols) - 1
        local col = ((i - 1) % cols)
        local itemsInRow = math.min(cols, #options - row * cols)
        local rowWidth = itemsInRow * btnW + (itemsInRow - 1) * gap
        local startX = (availW - rowWidth) / 2
        local sel = (opt.value == defaultVal)

        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, btnW, 0, rowH)
        b.Position = UDim2.new(0, startX + col * (btnW + gap), 0, 20 + row * (rowH + gap))
        b.BackgroundColor3 = sel and CLR.accent or CLR.surface
        b.Text = opt.label; b.TextColor3 = CLR.text; b.TextSize = 11
        b.Font = Enum.Font.GothamBold; b.BorderSizePixel = 0
        b.AutoButtonColor = false; b.Parent = fr
        addCorner(b, 8)
        local s = addStroke(b, sel and CLR.accent or CLR.border, 1)
        btns[opt.value] = {btn = b, stroke = s}

        b.MouseEnter:Connect(function()
            if opt.value ~= defaultVal then TS:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = CLR.elevated}):Play() end
        end)
        b.MouseLeave:Connect(function()
            if opt.value ~= defaultVal then TS:Create(b, TweenInfo.new(0.15), {BackgroundColor3 = CLR.surface}):Play() end
        end)
        b.MouseButton1Click:Connect(function()
            defaultVal = opt.value
            for v, d in pairs(btns) do
                local isSel = (v == opt.value)
                TS:Create(d.btn, TweenInfo.new(0.2), {BackgroundColor3 = isSel and CLR.accent or CLR.surface}):Play()
                TS:Create(d.stroke, TweenInfo.new(0.2), {Color = isSel and CLR.accent or CLR.border}):Play()
            end
            cb(opt.value)
        end)
    end
    return fr
end
-- ========================================
-- MAIN GUI
-- ========================================
local function makeGUI()
    local old = P.PlayerGui:FindFirstChild("TC12")
    if old then old:Destroy() end

    local sg = Instance.new("ScreenGui")
    sg.Name = "TC12"; sg.ResetOnSpawn = false
    sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; sg.Parent = P.PlayerGui

    local mf = Instance.new("Frame")
    mf.Size = UDim2.new(0, 290, 0, 510)
    mf.Position = UDim2.new(-0.3, 0, 0.2, 0)
    mf.BackgroundColor3 = CLR.bg; mf.BackgroundTransparency = 0.05
    mf.BorderSizePixel = 0; mf.Active = true; mf.Draggable = true
    mf.Parent = sg; addCorner(mf, 14)

    local bs = addStroke(mf, CLR.accent, 1.5); bs.Transparency = 0.2
    local bg = Instance.new("UIGradient")
    bg.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, CLR.accent),
        ColorSequenceKeypoint.new(0.3, CLR.purple),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(59, 130, 246)),
        ColorSequenceKeypoint.new(1, CLR.accent),
    }); bg.Parent = bs

    task.spawn(function()
        while scriptAlive do
            for i = 0, 360, 2 do
                if not scriptAlive then break end
                bg.Rotation = i; task.wait(0.04)
            end
        end
    end)

    TS:Create(mf, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 15, 0.2, 0)
    }):Play()

    -- TITLE BAR
    local tb = Instance.new("Frame")
    tb.Size = UDim2.new(1, 0, 0, 42)
    tb.BackgroundColor3 = Color3.fromRGB(8, 10, 18)
    tb.BackgroundTransparency = 0.1; tb.BorderSizePixel = 0; tb.Parent = mf

    local tlGlow = Instance.new("Frame")
    tlGlow.Size = UDim2.new(1, 0, 0, 6); tlGlow.Position = UDim2.new(0, 0, 1, -6)
    tlGlow.BorderSizePixel = 0; tlGlow.BackgroundTransparency = 0.7; tlGlow.Parent = tb
    local tlg = Instance.new("UIGradient"); tlg.Color = ColorSequence.new(CLR.accent, CLR.purple); tlg.Parent = tlGlow

    local tlLine = Instance.new("Frame")
    tlLine.Size = UDim2.new(1, 0, 0, 2); tlLine.Position = UDim2.new(0, 0, 1, -2)
    tlLine.BorderSizePixel = 0; tlLine.Parent = tb
    local tlg2 = Instance.new("UIGradient"); tlg2.Color = ColorSequence.new(CLR.accent, CLR.purple); tlg2.Parent = tlLine

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -80, 1, 0); title.Position = UDim2.new(0, 14, 0, 0)
    title.BackgroundTransparency = 1; title.Text = "\xe2\x9a\xa1 TOWER CLIMB"
    title.TextColor3 = CLR.text; title.TextSize = 15
    title.Font = Enum.Font.GothamBlack; title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = tb

    local badge = Instance.new("TextLabel")
    badge.Size = UDim2.new(0, 30, 0, 14); badge.Position = UDim2.new(0, 138, 0.5, -7)
    badge.BackgroundColor3 = CLR.purple; badge.BackgroundTransparency = 0.3
    badge.Text = "v12"; badge.TextColor3 = CLR.text; badge.TextSize = 8
    badge.Font = Enum.Font.GothamBold; badge.Parent = tb; addCorner(badge, 4)

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.new(0, 30, 0, 30); minBtn.Position = UDim2.new(1, -72, 0, 6)
    minBtn.BackgroundColor3 = CLR.amber; minBtn.BackgroundTransparency = 0.85
    minBtn.Text = "\xe2\x80\x94"; minBtn.TextColor3 = CLR.amber; minBtn.TextSize = 14
    minBtn.Font = Enum.Font.GothamBold; minBtn.BorderSizePixel = 0
    minBtn.AutoButtonColor = false; minBtn.Parent = tb; addCorner(minBtn, 6)
    minBtn.MouseEnter:Connect(function() TS:Create(minBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.5}):Play() end)
    minBtn.MouseLeave:Connect(function() TS:Create(minBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.85}):Play() end)

    local clsBtn = Instance.new("TextButton")
    clsBtn.Size = UDim2.new(0, 30, 0, 30); clsBtn.Position = UDim2.new(1, -38, 0, 6)
    clsBtn.BackgroundColor3 = CLR.red; clsBtn.BackgroundTransparency = 0.85
    clsBtn.Text = "\xe2\x9c\x95"; clsBtn.TextColor3 = CLR.red; clsBtn.TextSize = 14
    clsBtn.Font = Enum.Font.GothamBold; clsBtn.BorderSizePixel = 0
    clsBtn.AutoButtonColor = false; clsBtn.Parent = tb; addCorner(clsBtn, 6)
    clsBtn.MouseEnter:Connect(function() TS:Create(clsBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.5}):Play() end)
    clsBtn.MouseLeave:Connect(function() TS:Create(clsBtn, TweenInfo.new(0.15), {BackgroundTransparency = 0.85}):Play() end)

    -- MINIMIZED BUTTON
    local miniBtn = Instance.new("TextButton")
    miniBtn.Size = UDim2.new(0, 52, 0, 52); miniBtn.Position = UDim2.new(0, 15, 0.5, -26)
    miniBtn.BackgroundColor3 = CLR.bg; miniBtn.BorderSizePixel = 0
    miniBtn.Text = "\xe2\x9a\xa1"; miniBtn.TextSize = 22
    miniBtn.Visible = false; miniBtn.AutoButtonColor = false
    miniBtn.Parent = sg; addCorner(miniBtn, 26)
    local ms = addStroke(miniBtn, CLR.accent, 1.5)
    local mg = Instance.new("UIGradient"); mg.Color = ColorSequence.new(CLR.accent, CLR.purple); mg.Parent = ms

    local ml = Instance.new("TextLabel")
    ml.Size = UDim2.new(0, 80, 0, 20); ml.Position = UDim2.new(1, 10, 0.5, -10)
    ml.BackgroundColor3 = CLR.bg; ml.BackgroundTransparency = 0.2
    ml.Text = "IDLE"; ml.TextColor3 = CLR.muted; ml.TextSize = 10
    ml.Font = Enum.Font.GothamBold; ml.Parent = miniBtn
    addCorner(ml, 6); addStroke(ml, CLR.border, 1)

    task.spawn(function()
        while scriptAlive do task.wait(0.5)
            if loopOn then ml.Text = "LOOP \xc2\xb7 " .. totalCycles; ml.TextColor3 = CLR.green
            elseif climbOn then ml.Text = "CLIMB \xc2\xb7 " .. math.floor(getPhysicsSpeed()); ml.TextColor3 = CLR.accent
            else ml.Text = "IDLE"; ml.TextColor3 = CLR.muted end
        end
    end)

    minBtn.MouseButton1Click:Connect(function()
        TS:Create(mf, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
            Size = UDim2.new(0, 0, 0, 0), Position = UDim2.new(0, 40, 0.5, 0)
        }):Play()
        task.wait(0.35); mf.Visible = false; miniBtn.Visible = true
    end)

    miniBtn.MouseButton1Click:Connect(function()
        miniBtn.Visible = false; mf.Visible = true
        mf.Size = UDim2.new(0, 0, 0, 0); mf.Position = UDim2.new(0, 40, 0.5, 0)
        TS:Create(mf, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, 290, 0, 510), Position = UDim2.new(0, 15, 0.2, 0)
        }):Play()
    end)

    clsBtn.MouseButton1Click:Connect(function()
        scriptAlive = false; loopOn = false; climbOn = false
        stopClimb(); properReset(); sg:Destroy()
    end)

    -- TAB BAR
    local tabF = Instance.new("Frame")
    tabF.Size = UDim2.new(1, 0, 0, 38); tabF.Position = UDim2.new(0, 0, 0, 44)
    tabF.BackgroundColor3 = Color3.fromRGB(10, 13, 22)
    tabF.BorderSizePixel = 0; tabF.Parent = mf

    local tabNames = {"MAIN", "CONFIG", "INFO"}
    local tabBtns, tabFrames = {}, {}
    local activeTab = 1; local tw = 1 / #tabNames

    for i, n in ipairs(tabNames) do
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(tw, 0, 1, 0); b.Position = UDim2.new(tw * (i - 1), 0, 0, 0)
        b.BackgroundTransparency = 1; b.Text = n
        b.TextColor3 = (i == 1) and CLR.accent or CLR.muted
        b.TextSize = 12; b.Font = Enum.Font.GothamBold
        b.AutoButtonColor = false; b.Parent = tabF; tabBtns[i] = b
    end

    local ind = Instance.new("Frame")
    ind.Size = UDim2.new(tw, -24, 0, 3); ind.Position = UDim2.new(0, 12, 1, -3)
    ind.BackgroundColor3 = CLR.accent; ind.BorderSizePixel = 0
    ind.Parent = tabF; addCorner(ind, 2)

    local cFrame = Instance.new("Frame")
    cFrame.Size = UDim2.new(1, 0, 1, -82); cFrame.Position = UDim2.new(0, 0, 0, 82)
    cFrame.BackgroundTransparency = 1; cFrame.ClipsDescendants = true; cFrame.Parent = mf

    for i = 1, #tabNames do
        local sf = Instance.new("ScrollingFrame")
        sf.Size = UDim2.new(1, 0, 1, 0); sf.BackgroundTransparency = 1; sf.BorderSizePixel = 0
        sf.ScrollBarThickness = 2; sf.ScrollBarImageColor3 = CLR.accent
        sf.CanvasSize = UDim2.new(0, 0, 0, 0)
        sf.AutomaticCanvasSize = Enum.AutomaticSize.Y
        sf.Visible = (i == 1); sf.Parent = cFrame

        local pad = Instance.new("UIPadding")
        pad.PaddingTop = UDim.new(0, 10); pad.PaddingBottom = UDim.new(0, 10)
        pad.PaddingLeft = UDim.new(0, 12); pad.PaddingRight = UDim.new(0, 12); pad.Parent = sf

        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 8); layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        layout.Parent = sf

        tabFrames[i] = sf
    end

    local function switchTab(idx)
        activeTab = idx
        for i, b in ipairs(tabBtns) do
            TS:Create(b, TweenInfo.new(0.2), {TextColor3 = (i == idx) and CLR.accent or CLR.muted}):Play()
        end
        TS:Create(ind, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(tw * (idx - 1), 12, 1, -3)
        }):Play()
        for i, f in ipairs(tabFrames) do f.Visible = (i == idx) end
    end

    for i, b in ipairs(tabBtns) do
        b.MouseEnter:Connect(function()
            if activeTab ~= i then TS:Create(b, TweenInfo.new(0.15), {TextColor3 = CLR.text2}):Play() end
        end)
        b.MouseLeave:Connect(function()
            if activeTab ~= i then TS:Create(b, TweenInfo.new(0.15), {TextColor3 = CLR.muted}):Play() end
        end)
        b.MouseButton1Click:Connect(function() switchTab(i) end)
    end

    -- ===== MAIN TAB =====
    local main = tabFrames[1]

    local sc = Instance.new("Frame")
    sc.Size = UDim2.new(1, 0, 0, 52); sc.BackgroundColor3 = CLR.surface
    sc.BorderSizePixel = 0; sc.Parent = main; addCorner(sc, 10); addStroke(sc, CLR.border, 1)

    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 10, 0, 10); dot.Position = UDim2.new(0, 14, 0.5, -5)
    dot.BackgroundColor3 = CLR.green; dot.BorderSizePixel = 0
    dot.Parent = sc; addCorner(dot, 5)

    task.spawn(function()
        while scriptAlive do
            TS:Create(dot, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.6}):Play()
            task.wait(0.8)
            TS:Create(dot, TweenInfo.new(0.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0}):Play()
            task.wait(0.8)
        end
    end)

    local stxt = Instance.new("TextLabel")
    stxt.Size = UDim2.new(1, -36, 0, 20); stxt.Position = UDim2.new(0, 32, 0, 8)
    stxt.BackgroundTransparency = 1; stxt.Text = "Ready"
    stxt.TextColor3 = CLR.text; stxt.TextSize = 13
    stxt.Font = Enum.Font.GothamBold; stxt.TextXAlignment = Enum.TextXAlignment.Left
    stxt.Parent = sc

    local ssub = Instance.new("TextLabel")
    ssub.Size = UDim2.new(1, -36, 0, 14); ssub.Position = UDim2.new(0, 32, 0, 28)
    ssub.BackgroundTransparency = 1; ssub.Text = "Physics capped at 350 studs/s"
    ssub.TextColor3 = CLR.muted; ssub.TextSize = 9
    ssub.Font = Enum.Font.Gotham; ssub.TextXAlignment = Enum.TextXAlignment.Left
    ssub.Parent = sc

    makeToggle(main, "Auto Climb", false, function(on)
        climbOn = on
        if on then startClimb(); stxt.Text = "Climbing"; stxt.TextColor3 = CLR.green; dot.BackgroundColor3 = CLR.green
        else stopClimb(); stxt.Text = "Stopped"; stxt.TextColor3 = CLR.amber; dot.BackgroundColor3 = CLR.amber end
    end)

    makeToggle(main, "Auto Loop", false, function(on)
        loopOn = on
        if on then totalCycles = 0; doLoop(); stxt.Text = "Looping"; stxt.TextColor3 = CLR.accent; dot.BackgroundColor3 = CLR.accent
        else stopLoop(); stxt.Text = "Loop stopped"; stxt.TextColor3 = CLR.red; dot.BackgroundColor3 = CLR.red end
    end)

    makeDivider(main)

    makeBtn(main, "STOP ALL", Color3.fromRGB(160, 30, 50), Color3.fromRGB(200, 40, 60), function()
        stopLoop(); stxt.Text = "All stopped + Reset"; stxt.TextColor3 = CLR.red; dot.BackgroundColor3 = CLR.red
    end)

    makeBtn(main, "RESET STATE", Color3.fromRGB(140, 100, 0), Color3.fromRGB(180, 130, 0), function()
        properReset(); stxt.Text = "Character reset"; stxt.TextColor3 = CLR.green; dot.BackgroundColor3 = CLR.green
    end)

    makeDivider(main)

    -- LIVE STATS CARD
    local statsFr = Instance.new("Frame")
    statsFr.Size = UDim2.new(1, 0, 0, 56); statsFr.BackgroundColor3 = CLR.surface
    statsFr.BorderSizePixel = 0; statsFr.Parent = main; addCorner(statsFr, 10); addStroke(statsFr, CLR.border, 1)

    local statData = {
        {label = "CYCLES", val = "0", color = CLR.accent},
        {label = "SPEED", val = "300", color = CLR.green},
        {label = "DURATION", val = "3.0s", color = CLR.purple},
    }
    local statLabels = {}

    for i, sd in ipairs(statData) do
        local col = Instance.new("Frame")
        col.Size = UDim2.new(1 / 3, 0, 1, 0)
        col.Position = UDim2.new((i - 1) / 3, 0, 0, 0)
        col.BackgroundTransparency = 1; col.Parent = statsFr

        local v = Instance.new("TextLabel")
        v.Size = UDim2.new(1, 0, 0, 26); v.Position = UDim2.new(0, 0, 0, 6)
        v.BackgroundTransparency = 1; v.Text = sd.val
        v.TextColor3 = sd.color; v.TextSize = 16
        v.Font = Enum.Font.GothamBlack; v.Parent = col

        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, 0, 0, 14); l.Position = UDim2.new(0, 0, 0, 32)
        l.BackgroundTransparency = 1; l.Text = sd.label
        l.TextColor3 = CLR.muted; l.TextSize = 8
        l.Font = Enum.Font.GothamBold; l.Parent = col

        statLabels[i] = v

        if i < #statData then
            local vd = Instance.new("Frame")
            vd.Size = UDim2.new(0, 1, 0, 28)
            vd.Position = UDim2.new(1, 0, 0, 14); vd.AnchorPoint = Vector2.new(0.5, 0)
            vd.BackgroundColor3 = CLR.border; vd.BorderSizePixel = 0; vd.Parent = col
        end
    end

    task.spawn(function()
        while scriptAlive do task.wait(0.5)
            statLabels[1].Text = tostring(totalCycles)
            statLabels[2].Text = math.floor(getPhysicsSpeed())
            statLabels[3].Text = string.format("%.1fs", getActualDuration())
        end
    end)
        -- ===== CONFIG TAB =====
    local config = tabFrames[2]

    makeSelectorRow(config, "SPEED MULTIPLIER", {
        {value = 0.5, label = "0.5x"}, {value = 1.0, label = "1x"},
        {value = 1.5, label = "1.5x"}, {value = 2.0, label = "2x"},
        {value = 3.0, label = "3x"}, {value = 4.0, label = "4x"},
        {value = 5.0, label = "5x"}, {value = 7.0, label = "7x"},
        {value = 10.0, label = "10x"},
    }, 1.0, 5, function(v)
        speedMult = v
        stxt.Text = "Speed: " .. v .. "x | Dur: " .. string.format("%.1f", getActualDuration()) .. "s"
        stxt.TextColor3 = CLR.accent
    end)

    makeDivider(config)

    makeSelectorRow(config, "BASE CLIMB DURATION", {
        {value = 2, label = "2s"}, {value = 3, label = "3s"},
        {value = 4, label = "4s"}, {value = 5, label = "5s"},
        {value = 6, label = "6s"},
    }, 3, 5, function(v) dur = v end)

    makeDivider(config)

    makeSelectorRow(config, "REST AFTER LANDING", {
        {value = 1, label = "1s"}, {value = 2, label = "2s"},
        {value = 3, label = "3s"}, {value = 4, label = "4s"},
        {value = 5, label = "5s"},
    }, 2, 5, function(v) restTime = v end)

    -- ===== INFO TAB =====
    local info = tabFrames[3]

    local function makeInfoCard(parent, title, lines)
        local h = 28 + #lines * 18
        local fr = Instance.new("Frame")
        fr.Size = UDim2.new(1, 0, 0, h); fr.BackgroundColor3 = CLR.surface
        fr.BorderSizePixel = 0; fr.Parent = parent; addCorner(fr, 10); addStroke(fr, CLR.border, 1)

        local t = Instance.new("TextLabel")
        t.Size = UDim2.new(1, -20, 0, 20); t.Position = UDim2.new(0, 12, 0, 8)
        t.BackgroundTransparency = 1; t.Text = title
        t.TextColor3 = CLR.accent; t.TextSize = 12
        t.Font = Enum.Font.GothamBold; t.TextXAlignment = Enum.TextXAlignment.Left
        t.Parent = fr

        for i, line in ipairs(lines) do
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1, -24, 0, 16)
            l.Position = UDim2.new(0, 12, 0, 28 + (i - 1) * 18)
            l.BackgroundTransparency = 1; l.Text = line
            l.TextColor3 = CLR.text2; l.TextSize = 11
            l.Font = Enum.Font.Gotham; l.TextXAlignment = Enum.TextXAlignment.Left
            l.Parent = fr
        end
        return fr
    end

    makeInfoCard(info, "SCRIPT INFO", {
        "Name: Tower Climb v12",
        "Type: Auto Climb + Loop Farm",
        "Engine: BodyVelocity Physics",
        "Max Speed: 350 studs/s",
    })

    makeInfoCard(info, "HOW IT WORKS", {
        "1. Reset character state",
        "2. Climb up with BodyVelocity",
        "3. Stop climbing, fall down",
        "4. Collect coins on landing",
        "5. Rest and repeat the cycle",
    })

    makeInfoCard(info, "TIPS", {
        "Higher speed = faster climb",
        "Longer duration = higher climb",
        "More coins per cycle = more profit",
        "If stuck, press RESET STATE",
    })
end

-- ===== EVENTS =====
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
print("TOWER CLIMB v12 -- GOD LEVEL UI LOADED")
