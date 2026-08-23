--[[ remybb_esp.lua  (unobfuscated ESP module) ]]
local POOL = 16
local VIS_SEG = 12

local espPool = {}
local bvPool = {}
local radarBg, radarRing, radarCenter
local radarDots = {}
local radarPlrs = {}
local abilPool = {}
local abilTargets = {}
local abilRunning = false
local accBg, accTxt

local function hideBv(e)
    e.dtxt.Visible = false
    e.stxt.Visible = false
    e.tline.Visible = false
end

local function create()
    for i = 1, POOL do
        local seg = {}
        for s = 1, VIS_SEG do
            local l = Drawing.new("Line")
            l.Thickness = 2
            l.Visible = false
            seg[s] = l
        end
        espPool[i] = { seg = seg }
    end
    for i = 1, POOL do
        local dtxt = Drawing.new("Text")
        dtxt.Size = 12
        dtxt.Font = 8
        dtxt.Center = true
        dtxt.Outline = true
        dtxt.Visible = false
        local stxt = Drawing.new("Text")
        stxt.Size = 12
        stxt.Font = 8
        stxt.Center = true
        stxt.Outline = true
        stxt.Visible = false
        local tline = Drawing.new("Line")
        tline.Thickness = 1
        tline.Visible = false
        bvPool[i] = { dtxt = dtxt, stxt = stxt, tline = tline }
    end
    radarBg = Drawing.new("Circle")
    radarBg.Filled = true
    radarBg.Color = Color3.fromRGB(10, 10, 12)
    radarBg.Transparency = 0.35
    radarBg.NumSides = 40
    radarBg.Visible = false
    radarRing = Drawing.new("Circle")
    radarRing.Filled = false
    radarRing.Thickness = 1
    radarRing.NumSides = 40
    radarRing.Color = Color3.fromRGB(84, 101, 255)
    radarRing.Visible = false
    radarCenter = Drawing.new("Circle")
    radarCenter.Filled = true
    radarCenter.Radius = 2.5
    radarCenter.NumSides = 8
    radarCenter.Color = Color3.fromRGB(255, 255, 255)
    radarCenter.Visible = false
    for i = 1, POOL do
        local d = Drawing.new("Circle")
        d.Filled = true
        d.Radius = 3.5
        d.NumSides = 10
        d.Visible = false
        radarDots[i] = d
    end
    for i = 1, POOL do
        local d2 = Drawing.new("Circle")
        d2.Filled = true
        d2.Radius = 3
        d2.NumSides = 10
        d2.Visible = false
        radarPlrs[i] = d2
    end
    for i = 1, POOL do
        local bg = Drawing.new("Square")
        bg.Filled = true
        bg.Color = Color3.fromRGB(0, 0, 0)
        bg.Transparency = 0.35
        bg.Visible = false
        local txt = Drawing.new("Text")
        txt.Size = 13
        txt.Font = 8
        txt.Center = true
        txt.Outline = true
        txt.Color = Color3.fromRGB(255, 255, 255)
        txt.Visible = false
        abilPool[i] = { bg = bg, txt = txt }
    end
    accBg = Drawing.new("Square")
    accBg.Filled = true
    accBg.Color = Color3.fromRGB(0, 0, 0)
    accBg.Transparency = 0.35
    accBg.Visible = false
    accTxt = Drawing.new("Text")
    accTxt.Size = 13
    accTxt.Font = 8
    accTxt.Center = true
    accTxt.Outline = true
    accTxt.Visible = false
    _G.__apPool = espPool
end

local function startScanner(bobRef, genRef, playersRef)
    abilRunning = true
    task.spawn(function()
        while abilRunning do
            if bobRef == genRef() then
                local out = {}
                for _, plr in ipairs(playersRef:GetPlayers()) do
                    local char = plr.Character
                    local hum = char and char:FindFirstChild("Humanoid")
                    local head = char and char:FindFirstChild("Head")
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if head and root and hum and hum.Health > 0 then
                        local abl = plr:GetAttribute("CurrentlyEquippedAbility") or ""
                        local lvl = 0
                        if abl ~= "" then
                            local up = plr:FindFirstChild("Upgrades")
                            local iv = up and up:FindFirstChild(abl)
                            if iv then lvl = iv.Value or 0 end
                        end
                        out[#out + 1] = {
                            name = plr.Name,
                            head = head,
                            root = root,
                            abl = abl,
                            lvl = lvl,
                        }
                    end
                end
                abilTargets = out
            end
            task.wait(0.4)
        end
    end)
end

local function render(state)
    local lala = state.lala
    local ymer = state.ymer
    local cam = state.cam
    local vp = state.vp
    local tc = state.tc
    local WorldToScreen = state.WorldToScreen
    local Players = state.Players
    local lp = state.lp
    local c = ymer.centerPos
    local showEsp = lala.v2 and c and not ymer.abilityActive and not ymer.idle

    if showEsp and lala.abilityEsp or lala.abilityUpgradeEsp then
        local function ablLabel(t)
            local parts = {}
            if lala.abilityEsp then parts[#parts + 1] = (t.abl ~= "" and t.abl or "?") end
            if lala.abilityUpgradeEsp then parts[#parts + 1] = "V" .. tostring((t.lvl or 0) + 1) end
            return table.concat(parts, "  ")
        end
        local list = abilTargets
        local vw, vh = vp.X, vp.Y
        local n = 0
        for i = 1, #list do
            if n >= POOL then break end
            local t = list[i]
            local hpos = t.head and t.head.Position
            local rpos = t.root and t.root.Position
            if hpos and rpos and hpos.X == hpos.X and rpos.X == rpos.X then
                local top, v1 = WorldToScreen(hpos + Vector3.new(0, 0.6, 0))
                local bot, v2 = WorldToScreen(rpos - Vector3.new(0, 3.2, 0))
                if v1 and v2 then
                    n = n + 1
                    local e = abilPool[n]
                    local tx, ty = bot.X, bot.Y + 12
                    local lbl = ablLabel(t)
                    e.txt.Text = lbl
                    local tb = e.txt.TextBounds
                    e.txt.Position = { x = tx, y = ty }
                    e.bg.Position = { x = tx - tb.X * 0.5 - 3, y = ty - tb.Y * 0.5 - 2 }
                    e.bg.Size = { x = tb.X + 6, y = tb.Y + 4 }
                    e.txt.Visible = true
                    e.bg.Visible = true
                else
                    n = n + 1
                    local e = abilPool[n]
                    local h = top.Y - bot.Y
                    if h <= 0 then h = 1 end
                    local cx = (top.X + bot.X) * 0.5
                    local cy = (top.Y + bot.Y) * 0.5
                    cx = vw - cx
                    cy = vh - cy
                    local px = math.clamp(cx, 30, vw - 30)
                    local py = math.clamp(cy, 12, vh - 12)
                    local lbl = ablLabel(t)
                    e.txt.Text = lbl
                    local tb = e.txt.TextBounds
                    e.txt.Position = { x = px, y = py }
                    e.bg.Position = { x = px - tb.X * 0.5 - 3, y = py - tb.Y * 0.5 - 2 }
                    e.bg.Size = { x = tb.X + 6, y = tb.Y + 4 }
                    e.txt.Visible = true
                    e.bg.Visible = true
                end
            end
        end
        for i = n + 1, POOL do
            abilPool[i].txt.Visible = false
            abilPool[i].bg.Visible = false
        end
    else
        for i = 1, POOL do
            abilPool[i].txt.Visible = false
            abilPool[i].bg.Visible = false
        end
    end

    local accShow = lala.v2 and lala.randomize and lala.accHead ~= false and ymer.headPos
    if accShow then
        local top, v1 = WorldToScreen(ymer.headPos + Vector3.new(0, 0.9, 0))
        if v1 then
            local acc = math.floor(state.nextParryAccuracy() + 0.5)
            local bypassing = tc - state.panicParryAt < 0.5
            accTxt.Text = tostring(acc) .. "%" .. (bypassing and (" - " .. state.panicReason) or "")
            local col
            if bypassing then col = Color3.fromRGB(255, 160, 0)
            elseif acc < 50 then col = Color3.fromRGB(255, 60, 60)
            elseif acc < 80 then col = Color3.fromRGB(255, 200, 60)
            else col = Color3.fromRGB(60, 220, 90) end
            accTxt.Color = col
            local tb = accTxt.TextBounds
            accTxt.Position = { x = top.X, y = top.Y - 16 }
            accBg.Position = { x = top.X - tb.X * 0.5 - 3, y = top.Y - 16 - tb.Y * 0.5 - 2 }
            accBg.Size = { x = tb.X + 6, y = tb.Y + 4 }
            accTxt.Visible = true
            accBg.Visible = true
        else
            accTxt.Visible = false
            accBg.Visible = false
        end
    else
        accTxt.Visible = false
        accBg.Visible = false
    end

    if not showEsp then
        for i = 1, POOL do
            for s = 1, VIS_SEG do espPool[i].seg[s].Visible = false end
            hideBv(bvPool[i])
        end
        radarBg.Visible = false
        radarRing.Visible = false
        radarCenter.Visible = false
        for i = 1, POOL do radarDots[i].Visible = false end
        for i = 1, POOL do radarPlrs[i].Visible = false end
        return
    end

    if lala.bvExtras ~= false then
        local list = ymer.ballList
        local n = 0
        if list then
            for i = 1, #list do
                if n >= POOL then break end
                local bp, bv = WorldToScreen(list[i].pos)
                if bv then
                    n = n + 1
                    local e = espPool[n]
                    local dir = list[i].dir
                    if lala.showVis and dir then
                        local len = math.clamp(list[i].speed * 0.35, 12, 90) * (math.clamp(tonumber(lala.bvLen) or 100, 20, 100) / 100)
                        local colStart = Color3.fromRGB(lala.bvColor.r or 0, lala.bvColor.g or 255, lala.bvColor.b or 0)
                        local colEnd = Color3.fromRGB(lala.bvEnd.r or 255, lala.bvEnd.g or 0, lala.bvEnd.b or 0)
                        local bt = math.clamp(tonumber(lala.bvThick) or 6, 1, 14)
                        local thickStart = list[i].best and (bt + 4) or bt
                        local thinEnd = math.max(1, math.floor(bt / 3))
                        local mid = list[i].pos + dir * (len * 0.5)
                        local endPt = mid + dir * (len * 0.5)
                        local turn = list[i].turn
                        local cv = list[i].curve or 0
                        local toTgt = nil
                        if list[i].tgtPos then
                            local tv = (list[i].tgtPos - list[i].pos)
                            if tv.Magnitude > 0.5 then
                                toTgt = tv.Unit
                            end
                        end
                        local bendDir = turn
                        if not bendDir and toTgt then
                            local tdot = math.clamp(dir:Dot(toTgt), -1, 1)
                            local cross = dir:Cross(toTgt)
                            if cross.Magnitude > 0.01 then
                                bendDir = cross.Unit:Cross(dir).Unit
                            end
                        end
                        if bendDir then
                            local bulge = (toTgt and 0.35 or 0.12) * len
                            if cv > 0 then bulge = bulge + cv * len * 4 end
                            endPt = endPt + bendDir * bulge
                        end
                        local endDir = (endPt - list[i].pos)
                        local endLen = endDir.Magnitude
                        local c1 = list[i].pos + dir * (len * 0.45)
                        if bendDir then
                            local c1bulge = (toTgt and 0.5 or 0.15) * len
                            if cv > 0 then c1bulge = c1bulge + cv * len * 3 end
                            c1 = c1 + bendDir * c1bulge
                        end
                        local c2 = list[i].pos
                        if endLen > 0.01 then
                            c2 = endPt - (endDir / endLen) * (len * 0.45)
                        end
                        local prev = bp
                        local shown = 0
                        for s = 1, VIS_SEG do
                            local t = s / VIS_SEG
                            local iu = 1 - t
                            local pt = iu * iu * iu * list[i].pos + 3 * iu * iu * t * c1 + 3 * iu * t * t * c2 + t * t * t * endPt
                            local sp, sv = WorldToScreen(pt)
                            if sv then
                                e.seg[s].From = prev
                                e.seg[s].To = sp
                                e.seg[s].Color = Color3.new(
                                    colStart.R + (colEnd.R - colStart.R) * t,
                                    colStart.G + (colEnd.G - colStart.G) * t,
                                    colStart.B + (colEnd.B - colStart.B) * t)
                                e.seg[s].Thickness = thickStart + (thinEnd - thickStart) * t
                                e.seg[s].Visible = true
                                prev = sp
                                shown = s
                            else
                                break
                            end
                        end
                        for s = shown + 1, VIS_SEG do e.seg[s].Visible = false end
                    else
                        for s = 1, VIS_SEG do e.seg[s].Visible = false end
                    end
                    do
                        local bve = bvPool[n]
                        local d3 = nil
                        if c then
                            local dv = list[i].pos - c
                            d3 = math.floor(dv.Magnitude + 0.5)
                        end
                        if lala.bvExtras ~= false and lala.bvDist ~= false and d3 then
                            bve.dtxt.Text = tostring(d3) .. "m"
                            bve.dtxt.Color = Color3.fromRGB(235, 235, 240)
                            bve.dtxt.Position = { x = bp.X, y = bp.Y - 20 }
                            bve.dtxt.Visible = true
                        else
                            bve.dtxt.Visible = false
                        end
                        if lala.bvExtras ~= false and lala.bvSpeed then
                            bve.stxt.Text = tostring(math.floor((list[i].speed or 0) + 0.5))
                            bve.stxt.Color = Color3.fromRGB(160, 200, 255)
                            bve.stxt.Position = { x = bp.X, y = bp.Y + 8 }
                            bve.stxt.Visible = true
                        else
                            bve.stxt.Visible = false
                        end
                        if lala.bvExtras ~= false and lala.bvTarget ~= false and list[i].tgtPos then
                            local tp, tv2 = WorldToScreen(list[i].tgtPos)
                            if tv2 then
                                bve.tline.From = bp
                                bve.tline.To = tp
                                bve.tline.Color = Color3.fromRGB(lala.bvEnd.r or 255, lala.bvEnd.g or 0, lala.bvEnd.b or 0)
                                bve.tline.Thickness = 1
                                bve.tline.Transparency = 0.5
                                bve.tline.Visible = true
                            else
                                bve.tline.Visible = false
                            end
                        else
                            bve.tline.Visible = false
                        end
                    end
                end
            end
        end
        for i = n + 1, POOL do
            for s = 1, VIS_SEG do espPool[i].seg[s].Visible = false end
            hideBv(bvPool[i])
        end
    else
        for i = 1, POOL do
            for s = 1, VIS_SEG do espPool[i].seg[s].Visible = false end
            hideBv(bvPool[i])
        end
    end

    if lala.bvRadar and c then
        local rr = 92
        local rxp = vp.X - 116
        local ryp = 116
        radarBg.Position = { x = rxp, y = ryp }
        radarBg.Radius = rr
        radarBg.Visible = true
        radarRing.Position = { x = rxp, y = ryp }
        radarRing.Radius = rr
        radarRing.Visible = true
        radarCenter.Position = { x = rxp, y = ryp }
        radarCenter.Visible = true
        local fwd = cam.CFrame.LookVector
        local ang = math.atan2(fwd.X, fwd.Z)
        local ca, sa = math.cos(ang), math.sin(ang)
        local pxPerStud = (rr - 6) / 140
        local function toRadar(wx, wz)
            local dx = wx - c.X
            local dz = wz - c.Z
            local fComp = dx * sa + dz * ca
            local rComp = dx * ca - dz * sa
            local px = rxp + rComp * pxPerStud
            local py = ryp - fComp * pxPerStud
            local ox = px - rxp
            local oy = py - ryp
            local od = math.sqrt(ox * ox + oy * oy)
            local maxO = rr - 5
            if od > maxO then
                px = rxp + ox / od * maxO
                py = ryp + oy / od * maxO
            end
            return px, py
        end
        local rd = 0
        local list = ymer.ballList
        if list then
            for i = 1, #list do
                if rd >= POOL then break end
                rd = rd + 1
                local dot = radarDots[rd]
                local px, py = toRadar(list[i].pos.X, list[i].pos.Z)
                dot.Position = { x = px, y = py }
                dot.Radius = list[i].best and 4.5 or 3
                dot.Color = Color3.fromRGB(255, 60, 60)
                dot.Visible = true
            end
        end
        for i = rd + 1, POOL do radarDots[i].Visible = false end
        local pd = 0
        for _, plr in ipairs(Players:GetPlayers()) do
            if pd >= POOL then break end
            if plr ~= lp then
                local ch = plr.Character
                local hrp = ch and ch:FindFirstChild("HumanoidRootPart")
                if hrp then
                    pd = pd + 1
                    local dot = radarPlrs[pd]
                    local px, py = toRadar(hrp.Position.X, hrp.Position.Z)
                    dot.Position = { x = px, y = py }
                    dot.Radius = 3
                    dot.Color = Color3.fromRGB(255, 255, 255)
                    dot.Visible = true
                end
            end
        end
        for i = pd + 1, POOL do radarPlrs[i].Visible = false end
    else
        radarBg.Visible = false
        radarRing.Visible = false
        radarCenter.Visible = false
        for i = 1, POOL do radarDots[i].Visible = false end
        for i = 1, POOL do radarPlrs[i].Visible = false end
    end
end

local function cleanup()
    abilRunning = false
    for i = 1, POOL do
        for s = 1, VIS_SEG do pcall(espPool[i].seg[s].Remove, espPool[i].seg[s]) end
    end
    for i = 1, POOL do
        pcall(abilPool[i].bg.Remove, abilPool[i].bg)
        pcall(abilPool[i].txt.Remove, abilPool[i].txt)
    end
    for i = 1, POOL do
        local b = bvPool[i]
        if b then
            pcall(b.dtxt.Remove, b.dtxt)
            pcall(b.stxt.Remove, b.stxt)
            pcall(b.tline.Remove, b.tline)
        end
    end
    pcall(radarBg.Remove, radarBg)
    for i = 1, #radarPlrs do pcall(radarPlrs[i].Remove, radarPlrs[i]) end
    pcall(radarRing.Remove, radarRing)
    pcall(radarCenter.Remove, radarCenter)
    for i = 1, #radarDots do pcall(radarDots[i].Remove, radarDots[i]) end
    pcall(accBg.Remove, accBg)
    pcall(accTxt.Remove, accTxt)
    _G.__apPool = nil
end

return { init = create, startScanner = startScanner, render = render, cleanup = cleanup }
