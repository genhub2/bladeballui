
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local lp = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

local _G_ = _G
local GEN = (_G_._genGEN or 0) + 1
_G_._genGEN = GEN
local old = _G_._genToken
if old then
    if old.unload then pcall(function() old.unload() end) end
end

local running = true

local C_ACC  = Color3.fromRGB(84, 101, 255)
local C_TACC = Color3.fromRGB(78, 93, 234)
local C_WBG  = Color3.fromRGB(15, 15, 15)
local C_SOUT = Color3.fromRGB(9, 10, 14)
local C_SBDR = Color3.new(0, 0, 0)
local C_CNT  = Color3.fromRGB(12, 13, 17)
local C_CTRL = Color3.fromRGB(27, 28, 36)
local C_TOFF = Color3.fromRGB(30, 30, 30)
local C_GRY  = Color3.fromRGB(150, 150, 150)
local C_GRY2 = Color3.fromRGB(200, 200, 200)
local C_WHT  = Color3.fromRGB(255, 255, 255)
local C_SL1  = Color3.fromRGB(79, 95, 239)
local C_UL   = Color3.fromRGB(81, 97, 243)

local function colLerp(a, b, k)
    return Color3.new(a.R + (b.R - a.R) * k, a.G + (b.G - a.G) * k, a.B + (b.B - a.B) * k)
end

local accentReg = {}

local PRESETS = {
    { "White", Color3.fromRGB(255, 255, 255) },
    { "Blue", Color3.fromRGB(84, 101, 255) },
    { "Red", Color3.fromRGB(255, 60, 60) },
    { "Green", Color3.fromRGB(60, 235, 90) },
    { "Yellow", Color3.fromRGB(255, 215, 60) },
    { "Orange", Color3.fromRGB(255, 140, 40) },
    { "Purple", Color3.fromRGB(160, 100, 255) },
    { "Pink", Color3.fromRGB(255, 90, 180) },
    { "Cyan", Color3.fromRGB(60, 220, 255) },
    { "Black", Color3.new(0, 0, 0) },
    { "Lime", Color3.fromRGB(140, 255, 60) },
    { "Teal", Color3.fromRGB(0, 180, 180) },
    { "Sky", Color3.fromRGB(90, 170, 255) },
    { "Lavender", Color3.fromRGB(190, 150, 255) },
    { "Gold", Color3.fromRGB(255, 200, 0) },
    { "Crimson", Color3.fromRGB(220, 20, 60) },
}

local allD = {}
local baseTs = {}
local function D(type, props)
    local d = Drawing.new(type)

    if props then for k, v in pairs(props) do d[k] = v end end
    allD[#allD + 1] = d
    baseTs[#allD] = (props and props.Transparency) or 1
    return d
end
local function T(size, col)
    return D("Text", { Size = size, Font = 11, Color = col, ZIndex = 9, Visible = false })
end

local function fakeOutline(z, thickness)
    local parts = {
        D("Square", { Filled = true, ZIndex = z }),
        D("Square", { Filled = true, ZIndex = z }),
        D("Square", { Filled = true, ZIndex = z }),
        D("Square", { Filled = true, ZIndex = z }),
    }
    local t = thickness or 1
    local px, py, pw, ph = 0, 0, 0, 0
    local function upd()
        parts[1].Position = Vector2.new(px, py)
        parts[1].Size = Vector2.new(pw, t)
        parts[2].Position = Vector2.new(px, py + ph - t)
        parts[2].Size = Vector2.new(pw, t)
        parts[3].Position = Vector2.new(px, py)
        parts[3].Size = Vector2.new(t, ph)
        parts[4].Position = Vector2.new(px + pw - t, py)
        parts[4].Size = Vector2.new(t, ph)
    end
    return setmetatable({}, {
        __newindex = function(self, k, v)
            if k == "Position" then px, py = v.X, v.Y
            elseif k == "Size" then pw, ph = v.X, v.Y
            elseif k == "Visible" then for _, p in ipairs(parts) do p.Visible = v end
            elseif k == "Color" then for _, p in ipairs(parts) do p.Color = v end
            elseif k == "Thickness" then t = v
            else rawset(self, k, v) end
            if k == "Position" or k == "Size" or k == "Thickness" then upd() end
        end,
        __index = function(self, k)
            if k == "_parts" then return parts end
            if k == "_rect" then return { px, py, pw, ph } end
            return nil
        end,
    })
end

local function polyLines(radius, segs)
    local out = {}
    for i = 1, segs do
        local a1 = (i - 1) / segs * math.pi * 2
        local a2 = i / segs * math.pi * 2
        out[#out + 1] = {
            fx = math.cos(a1) * radius, fy = math.sin(a1) * radius,
            tx = math.cos(a2) * radius, ty = math.sin(a2) * radius,
        }
    end
    return out
end

local nameToVK = {}
do
    for i = 65, 90 do nameToVK[string.char(i)] = i end
    for i = 0, 9 do nameToVK[tostring(i)] = 48 + i end
    for i = 1, 12 do nameToVK["F" .. i] = 111 + i end
    local sp = {
        Escape = 27, Backspace = 8, Tab = 9, Enter = 13, Space = 32,
        Left = 37, Up = 38, Right = 39, Down = 40,
        Shift = 16, LeftShift = 16, RightShift = 16,
        Control = 17, LeftControl = 17, RightControl = 17,
        Alt = 18, LeftAlt = 18, RightAlt = 18,
        Backquote = 192, Minus = 189, Equals = 187,
        LeftBracket = 219, RightBracket = 221, Backslash = 220,
        Semicolon = 186, Quote = 222, Comma = 188, Period = 190, Slash = 191,
        CapsLock = 20, Home = 36, End = 35, PageUp = 33, PageDown = 34,
        Insert = 45, Delete = 46,
    }
    for n, vk in pairs(sp) do nameToVK[n] = vk end
end
local vkToName = {}
do
    for n, vk in pairs(nameToVK) do
        if not vkToName[vk] or #vkToName[vk] > #n then vkToName[vk] = n end
    end
end
local function keyName(v) return vkToName[v] or tostring(v) end
local commonVKs = {}
do
    local seen = {}
    for _, vk in pairs(nameToVK) do
        if not seen[vk] then seen[vk] = true; commonVKs[#commonVKs + 1] = vk end
    end
    table.sort(commonVKs)
end
local function vkChar(vk)
    if vk >= 65 and vk <= 90 then return string.char(vk) end
    local map = {
        [48] = "0", [49] = "1", [50] = "2", [51] = "3", [52] = "4", [53] = "5",
        [54] = "6", [55] = "7", [56] = "8", [57] = "9",
        [189] = "-", [187] = "=", [219] = "[", [221] = "]", [220] = "\\",
        [186] = ";", [222] = "'", [188] = ",", [190] = ".", [191] = "/", [192] = "`",
        [32] = " ",
    }
    return map[vk]
end

local uiPos = Vector2.new(400, 120)
local menuOpen = true
local activeTab = 1
local tabHandles = {}
local values = {}
local openPopup = nil
local focusTextBox = nil
local bindingKB = nil
local kbHeld = {}
local lastM1, lastM2 = false, false
local winDrag = false
local dragOffX, dragOffY = 0, 0
local hovEl, hovKB, hovSwatch = nil, nil, nil
local hovTab, hovSec = nil, nil
local hovSector = nil
local hovRow = nil
local gShow = true

local function inRect(mx, my, x, y, w, h)
    return mx >= x and mx <= x + w and my >= y and my <= y + h
end

local WIN_W, WIN_H = 700, 500
local winBg = D("Square", { Filled = true, Color = C_WBG, ZIndex = 2 })
local uiAlpha = 1
local winBd = fakeOutline(4, 1)
winBd.Color = C_ACC
accentReg[#accentReg + 1] = winBd
local GRAD_N = 24
local gradStrips = {}
do
    local topK, botK = 0.20, 0.35
    for i = 1, GRAD_N do
        local t = (i - 1) / (GRAD_N - 1)
        local c
        if t < 0.55 then
            local k = 1 - t / 0.55
            k = k * k * (3 - 2 * k)
            c = Color3.new(
                C_WBG.R + (C_ACC.R - C_WBG.R) * topK * k,
                C_WBG.G + (C_ACC.G - C_WBG.G) * topK * k,
                C_WBG.B + (C_ACC.B - C_WBG.B) * topK * k)
        else
            local k = (t - 0.55) / 0.45
            k = k * k
            c = Color3.new(
                C_WBG.R * (1 - botK * k),
                C_WBG.G * (1 - botK * k),
                C_WBG.B * (1 - botK * k))
        end
        gradStrips[i] = D("Square", { Filled = true, Color = c, ZIndex = 3 })
        local sh = math.ceil(WIN_H / GRAD_N)
        gradStrips[i].Size = Vector2.new(WIN_W, i < GRAD_N and (sh + 1) or (WIN_H - (GRAD_N - 1) * sh))
        gradStrips[i].Visible = false
    end
end
local gradPos = nil
local titleSepSegs = {}
do
    local K = 14
    for k = 1, K do
        local f = math.abs(k - (K + 1) * 0.5) / ((K + 1) * 0.5)
        local v = 0.95 - (0.95 - 0.06) * f
        titleSepSegs[k] = D("Square", { Filled = true, Color = C_UL, Size = Vector2.new(1, 1), ZIndex = 6, Transparency = v })
        accentReg[#accentReg + 1] = titleSepSegs[k]
        titleSepSegs[k].Visible = false
    end
end
local contentBd = fakeOutline(4, 1)
contentBd.Color = C_SBDR
local titleTxt = T(16, C_WHT)
titleTxt.Outline = true
local railBd = fakeOutline(4, 1)
railBd.Color = C_SBDR

local avRing = D("Circle", { Filled = true, Radius = 21, Color = C_CNT, ZIndex = 4, Visible = false })
local avImg = D("Image", { Size = Vector2.new(40, 40), ZIndex = 5, Visible = false })
local avName = T(13, C_WHT)
avName.Outline = true
avName.Visible = false
task.spawn(function()
    local plrs = game:GetService("Players")
    local hs = game:GetService("HttpService")
    local lp = plrs.LocalPlayer
    if lp then avName.Text = lp.Name end
    for _ = 1, 10 do
        if lp then break end
        task.wait(0.5)
        lp = plrs.LocalPlayer
        if lp then avName.Text = lp.Name end
    end
    if not lp then return end
    local okj, body = pcall(httpget, "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds=" .. tostring(lp.UserId) .. "&size=150x150&format=Png&isCircular=false")
    if not okj or not body then return end
    local okd, dec = pcall(function() return hs:JSONDecode(body) end)
    if not okd or type(dec) ~= "table" or type(dec.data) ~= "table" or not dec.data[1] or not dec.data[1].imageUrl then return end
    local okb, bytes = pcall(httpget, dec.data[1].imageUrl)
    if not okb or not bytes then return end
    avImg.Data = bytes
end)

local TAB_PNG = {
    sword = "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",
    eye = "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",
    gear = "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",
}

local iconInfo = {}
local function makeIcon(kind)
    local g = {}
    local img
    if TAB_PNG[kind] then
        local ok, dec = pcall(base64decode, TAB_PNG[kind])
        if ok and dec then
            img = D("Image", { Size = Vector2.new(42, 42), ZIndex = 9, Visible = false })
            pcall(function() img.Data = dec end)
        end
    end
    local g = {}
    local function add(d, info)
        g[#g + 1] = d
        iconInfo[d] = info or {}
    end
    if kind == "crosshair" then
        for _, seg in ipairs(polyLines(9, 16)) do
            add(D("Line", { Thickness = 1.5 }), seg)
        end
        add(D("Circle", { Filled = true, Radius = 1.5 }))
        for _, a in ipairs({ 0, 90, 180, 270 }) do
            local r = math.rad(a)
            add(D("Line", { Thickness = 1.5 }), {
                fx = math.cos(r) * 13, fy = math.sin(r) * 13,
                tx = math.cos(r) * 16, ty = math.sin(r) * 16,
            })
        end
    elseif kind == "target" then
        for _, seg in ipairs(polyLines(11, 20)) do
            add(D("Line", { Thickness = 1.5 }), seg)
        end
        add(D("Circle", { Filled = true, Radius = 3 }))
    elseif kind == "person" then
        for _, seg in ipairs(polyLines(4, 14)) do
            add(D("Line", { Thickness = 1.5 }), seg)
        end
        add(D("Line", { Thickness = 1.5 }), { fx = -6, fy = 4, tx = 6, ty = 4 })
        add(D("Line", { Thickness = 1.5 }), { fx = -6, fy = 4, tx = -6, ty = 9 })
        add(D("Line", { Thickness = 1.5 }), { fx = 6, fy = 4, tx = 6, ty = 9 })
        add(D("Line", { Thickness = 1.5 }), { fx = -6, fy = 9, tx = 6, ty = 9 })
    elseif kind == "sliders" then
        for i = 0, 2 do
            local y = -6 + i * 6
            add(D("Line", { Thickness = 1.5 }), { fx = -10, fy = y, tx = 10, ty = y })
            add(D("Square", { Filled = true, Size = Vector2.new(4, 4) }), { kx = 6, ky = y - 2 })
        end
    elseif kind == "sword" then
        add(D("Line", { Thickness = 2 }), { fx = -7, fy = 7, tx = 8, ty = -8 })
        add(D("Line", { Thickness = 2 }), { fx = -7.5, fy = 0.5, tx = -0.5, ty = 7.5 })
        add(D("Circle", { Filled = true, Radius = 1.8 }), { kx = -9, ky = 9 })
    elseif kind == "eye" then
        local n = 10
        for i = 1, n do
            local t1 = (i - 1) / n
            local t2 = i / n
            local x1 = -12 + 24 * t1
            local x2 = -12 + 24 * t2
            add(D("Line", { Thickness = 2 }), {
                fx = x1, fy = -6 * math.sin(math.pi * t1),
                tx = x2, ty = -6 * math.sin(math.pi * t2),
            })
            add(D("Line", { Thickness = 2 }), {
                fx = x1, fy = 6 * math.sin(math.pi * t1),
                tx = x2, ty = 6 * math.sin(math.pi * t2),
            })
        end
        add(D("Circle", { Filled = true, Radius = 2.5 }))
    elseif kind == "gear" then
        for _, seg in ipairs(polyLines(7, 16)) do
            add(D("Line", { Thickness = 2 }), seg)
        end
        for i = 0, 7 do
            local r = math.rad(i * 45)
            add(D("Line", { Thickness = 2 }), {
                fx = math.cos(r) * 7, fy = math.sin(r) * 7,
                tx = math.cos(r) * 11, ty = math.sin(r) * 11,
            })
        end
        add(D("Circle", { Radius = 2.5 }))
    end
    for _, d in ipairs(g) do
        d.Color = C_GRY
        d.ZIndex = 4
    end
    return g, img
end

local popBg = D("Square", { Filled = true, Color = C_CTRL, ZIndex = 10 })
local popBd = fakeOutline(10, 1)
popBd.Color = Color3.new(0, 0, 0)
local popRows = {}
for i = 1, 12 do
    popRows[i] = {
        bg = D("Square", { Filled = true, Color = C_CTRL, ZIndex = 10 }),
        dec = D("Square", { Filled = true, Color = C_ACC, Size = Vector2.new(1, 20), ZIndex = 11 }),
        sw = D("Square", { Filled = true, Size = Vector2.new(16, 14), ZIndex = 11 }),
        tx = T(13, C_GRY),
    }
    popRows[i].tx.ZIndex = 12
    accentReg[#accentReg + 1] = popRows[i].dec
end

local function renderPopup()
    local p = openPopup
    if not p then
        popBg.Visible = false
        popBd.Visible = false
        for i = 1, 12 do
            popRows[i].bg.Visible = false
            popRows[i].dec.Visible = false
            popRows[i].sw.Visible = false
            popRows[i].tx.Visible = false
        end
        return
    end
    if not gShow then
        popBg.Visible = false
        popBd.Visible = false
        for i = 1, 12 do
            popRows[i].bg.Visible = false
            popRows[i].dec.Visible = false
            popRows[i].sw.Visible = false
            popRows[i].tx.Visible = false
        end
        return
    end
    local h = p.h
    popBg.Visible = true
    popBg.Position = Vector2.new(p.x, p.y)
    popBg.Size = Vector2.new(260, h)
    popBd.Visible = true
    popBd.Position = Vector2.new(p.x, p.y)
    popBd.Size = Vector2.new(260, h)
    for i = 1, 12 do
        local r = popRows[i]
        local py = p.y + (i - 1) * 20
        if i > #p.rows then
            r.bg.Visible = false; r.dec.Visible = false; r.sw.Visible = false; r.tx.Visible = false
        else
            r.bg.Visible = true
            r.bg.Position = Vector2.new(p.x, py)
            r.bg.Size = Vector2.new(260, 20)
            r.tx.Visible = true
            r.tx.Position = Vector2.new(p.x + 8, py + 3)
            local row = p.rows[i]
            local hov = hovRow == i
            r.tx.Text = row.txt or ""
            if p.kind == "color" then
                r.sw.Visible = true
                r.sw.Position = Vector2.new(p.x + 8, py + 3)
                r.sw.Color = row.color
                r.tx.Position = Vector2.new(p.x + 30, py + 3)
                r.tx.Color = (hov or row.sel) and C_WHT or C_GRY
                r.dec.Visible = row.sel
            else
                r.sw.Visible = false
                r.tx.Color = (hov or row.sel) and C_WHT or C_GRY
                r.dec.Visible = row.sel
            end
        end
    end
end

local function openDrop(el)
    if openPopup then if openPopup.owner then openPopup.owner.open = false end end
    openPopup = { kind = el.kind, x = el.popX, y = el.popY, h = el.popH, owner = el, rows = {} }
    for i, o in ipairs(el.opts) do
        local sel
        if el.kind == "Dropdown" then sel = o == el.value.Dropdown
        else sel = table.find(el.value.Combo, o) ~= nil end
        openPopup.rows[i] = { txt = o, sel = sel }
    end
    el.open = true
end

local function makeElement(type, text, data, cb, sector, tabNum, secName)
    local el = {
        text = text, cb = cb, kind = type, opts = data.options or {}, hov = false,
        min = data.default and data.default.min or 0,
        max = data.default and data.default.max or 100,
        open = false, x = 0, y = 0, w = 282, h = 18, rect = { x = 0, y = 0, w = 282, h = 18 },
        show = false,
    }
    local flag = text
    local value = values[tabNum][secName][sector.name][flag] or {}

    local function commit()
        values[tabNum][secName][sector.name][flag] = el.value
    end

    el.get_value = function() return el.value end
    el.set_value = function(self, v, noCb)
        el.value = v or el.value
        commit()
        if not noCb and el.cb then pcall(el.cb, el.value) end
    end

    if type == "Toggle" then
        el.h = 18
        el.value = { Toggle = value.Toggle ~= nil and value.Toggle or (data.default and data.default.Toggle or false) }
        el.def = { Toggle = el.value.Toggle }
        el.animT = el.value.Toggle and 1 or 0
        el.track = D("Square", { Filled = true, Color = C_CTRL, Size = Vector2.new(26, 13), ZIndex = 6, Rounding = 6 })
        el.knob = D("Circle", { Filled = true, Radius = 4, Color = C_GRY, ZIndex = 7 })
        el.lab = T(13, C_GRY)
        el.parts = { el.track, el.knob, el.lab }
        el.draw = function()
            local tgt = el.value.Toggle and 1 or 0
            local d = tgt - el.animT
            if math.abs(d) < 0.02 then el.animT = tgt else el.animT = el.animT + d * 0.28 end
            local t = el.animT
            el.track.Position = Vector2.new(el.x + 9, el.y + 3)
            el.track.Color = colLerp(Color3.fromRGB(40, 41, 52), C_SL1, t)
            el.knob.Position = Vector2.new(el.x + 15 + t * 14, el.y + 9.5)
            el.knob.Color = colLerp(C_GRY, C_WHT, t)
            el.lab.Position = Vector2.new(el.x + 44, el.y + 4)
            el.lab.Text = el.text
            el.lab.Color = C_WHT
            for _, p in ipairs(el.parts) do p.Visible = el.show end
            if el.kb then el.kb:draw() end
            if el.cl then el.cl:draw() end
        end
        el.click = function()
            el.value.Toggle = not el.value.Toggle
            commit()
            if el.cb then pcall(el.cb, el.value) end
        end
        el.kb = nil
        el.add_keybind = function()
            if el.kb then return el.kb end
            el.kb = {
                bg = D("Square", { Filled = true, Color = C_CTRL, Size = Vector2.new(36, 16), ZIndex = 7, Rounding = 3 }),
                txt = T(12, C_GRY),
                value = { Key = nil, Type = "Always", Active = true },
                cb = nil,
                toggleElement = true,
                rect = { x = 0, y = 0, w = 60, h = 18 },
                draw = function()
                    local k = el.kb.value.Key
                    el.kb.txt.Text = k and keyName(k):upper() or "NONE"
                    local hov = hovKB == el.kb
                    local cw = math.max(36, math.min(el.kb.txt.TextBounds.X + 14, 84))
                    el.kb.bg.Size = Vector2.new(cw, 16)
                    el.kb.bg.Position = Vector2.new(el.x + el.w - 10 - cw, el.y + 3)
                    el.kb.bg.Color = hov and colLerp(C_CTRL, Color3.fromRGB(45, 47, 60), 0.9) or C_CTRL
                    el.kb.txt.Center = true
                    el.kb.txt.Position = Vector2.new(el.x + el.w - 10 - cw * 0.5, el.y + 11 + (16 - el.kb.txt.TextBounds.Y) * 0.5)
                    el.kb.txt.Color = hov and C_WHT or C_GRY
                    el.kb.txt.Visible = el.show
                    el.kb.bg.Visible = el.show
                    el.kb.rect.x = el.x + el.w - 10 - cw
                    el.kb.rect.y = el.y + 2
                    el.kb.rect.w = cw
                end,
            }
            values[tabNum][secName][sector.name]["$" .. flag] = el.kb.value
            return el.kb
        end
        el.cl = nil
        el.add_color = function(default)
            if el.cl then return el.cl end
            el.cl = {
                swatch = D("Square", { Filled = true, Color = C_WHT, Size = Vector2.new(35, 11), ZIndex = 7 }),
                value = { Color = (default and default.Color) or Color3.fromRGB(255, 255, 255), Transparency = 0 },
                defC = (default and default.Color) or Color3.fromRGB(255, 255, 255),
                rect = { x = 0, y = 0, w = 35, h = 11 },
                draw = function()
                    el.cl.swatch.Position = Vector2.new(el.x + el.w - 45, el.y + 4)
                    el.cl.swatch.Color = el.cl.value.Color
                    el.cl.swatch.Visible = el.show
                    el.cl.rect.x = el.x + el.w - 45
                    el.cl.rect.y = el.y + 4
                end,
            }
            values[tabNum][secName][sector.name]["$" .. flag] = el.cl.value
            return el.cl
        end
        commit()

    elseif type == "Dropdown" or type == "Combo" then
        el.h = 45
        if type == "Dropdown" then
            el.value = { Dropdown = value.Dropdown or (data.default and data.default.Dropdown) or el.opts[1] }
        else
            el.value = { Combo = value.Combo or (data.default and data.default.Combo) or {} }
        end
        el.def = { Dropdown = el.value.Dropdown, Combo = el.value.Combo }
        el.lab = T(13, C_GRY)
        el.btnBg = D("Square", { Filled = true, Color = C_CTRL, Size = Vector2.new(260, 20), ZIndex = 6 })
        el.btnTxt = T(13, C_GRY)
        el.arrow = D("Triangle", { Filled = true, Color = C_GRY })
        el.parts = { el.lab, el.btnBg, el.btnTxt, el.arrow }
        el.display = function()
            if type == "Dropdown" then return el.value.Dropdown end
            local sel = {}
            for _, o in ipairs(el.opts) do if table.find(el.value.Combo, o) then sel[#sel + 1] = o end end
            if #sel == 0 then return "..."
            elseif #sel == 1 then return sel[1]
            else
                local s = sel[1]
                for i = 2, math.min(3, #sel) do s = s .. ",  " .. sel[i] end
                if #sel > 3 then s = s .. ",  ..." end
                return s
            end
        end
        el.draw = function()
            local active = el.open or el.hov
            el.lab.Position = Vector2.new(el.x + 9, el.y + 5)
            el.lab.Text = el.text
            el.lab.Color = C_WHT
            el.btnBg.Position = Vector2.new(el.x + 9, el.y + 20)
            el.btnTxt.Position = Vector2.new(el.x + 15, el.y + 25)
            el.btnTxt.Text = el.display()
            el.btnTxt.Color = active and C_WHT or C_GRY
            el.arrow.PointA = Vector2.new(el.x + 254, el.y + 28)
            el.arrow.PointB = Vector2.new(el.x + 262, el.y + 28)
            el.arrow.PointC = Vector2.new(el.x + 258, el.y + 32)
            el.arrow.Color = active and C_WHT or C_GRY
            for _, p in ipairs(el.parts) do p.Visible = el.show end
        end
        local nOpts = #el.opts
        el.popH = nOpts >= 4 and 80 or nOpts * 20
        el.popX, el.popY = 0, 0
        el.openPopup = function()
            el.popX = el.x + 9
            el.popY = el.y + 41
            openDrop(el)
        end
        el.select = function(self, idx)
            local o = el.opts[idx]
            if not o then return end
            if type == "Dropdown" then
                el.value.Dropdown = o
            else
                local found = table.find(el.value.Combo, o)
                if found then table.remove(el.value.Combo, found)
                else table.insert(el.value.Combo, o) end
            end
            commit()
            if el.cb then pcall(el.cb, el.value) end
        end
        commit()

    elseif type == "Slider" then
        el.h = 35
        el.value = { Slider = value.Slider or (data.default and data.default.default) or 0 }
        el.def = { Slider = el.value.Slider }
        el.lab = T(13, C_GRY)
        el.valTxt = T(13, C_GRY)
        el.track = D("Square", { Filled = true, Color = C_CTRL, Size = Vector2.new(260, 10), ZIndex = 6 })
        el.fill = D("Square", { Filled = true, Color = C_SL1, ZIndex = 7 })
        accentReg[#accentReg + 1] = el.fill
        el.parts = { el.lab, el.valTxt, el.track, el.fill }
        el.dragging = false
        el.draw = function()
            el.lab.Position = Vector2.new(el.x + 9, el.y + 4)
            el.lab.Text = el.text
            el.lab.Color = C_WHT
            el.valTxt.Text = el.disp and el.disp(el.value.Slider) or tostring(el.value.Slider)
            el.valTxt.Position = Vector2.new(el.x + 269 - el.valTxt.TextBounds.X, el.y + 4)
            el.valTxt.Color = (el.hov or el.dragging) and C_WHT or C_GRY
            el.track.Position = Vector2.new(el.x + 9, el.y + 20)
            local frac = (el.value.Slider - el.min) / (el.max - el.min)
            el.fill.Position = Vector2.new(el.x + 9, el.y + 20)
            el.fill.Size = Vector2.new(math.max(1, math.floor(260 * frac)), 10)
            for _, p in ipairs(el.parts) do p.Visible = el.show end
        end
        el.drag = function(self, mx)
            local frac = math.max(0, math.min(1, (mx - (el.x + 9)) / 260))
            local v = math.floor(el.min + (el.max - el.min) * frac)
            if v ~= el.value.Slider then
                el.value.Slider = v
                commit()
                if el.cb then pcall(el.cb, el.value) end
            end
        end
        commit()

    elseif type == "Button" then
        el.h = 30
        el.value = {}
        el.bg = D("Square", { Filled = true, Color = C_CTRL, Size = Vector2.new(215, 20), ZIndex = 6 })
        el.tx = T(13, C_GRY)
        el.parts = { el.bg, el.tx }
        el.draw = function()
            el.bg.Position = Vector2.new(el.x + (el.w - 215) / 2, el.y + 5)
            el.tx.Text = el.text
            el.tx.Position = Vector2.new(el.x + el.w / 2 - el.tx.TextBounds.X / 2, el.y + 9)
            local bgTgt = el.hov and Color3.fromRGB(45, 47, 60) or C_CTRL
            el._bgC = colLerp(el._bgC or bgTgt, bgTgt, 0.25)
            el.bg.Color = el._bgC
            local txTgt = el.hov and C_WHT or C_GRY
            el._txC = colLerp(el._txC or txTgt, txTgt, 0.25)
            el.tx.Color = el._txC
            for _, p in ipairs(el.parts) do p.Visible = el.show end
        end
        el.click = function()
            if el.cb then pcall(el.cb) end
        end

    elseif type == "Label" then
        el.h = 18
        el.value = {}
        el.lab = T(13, C_GRY)
        el.parts = { el.lab }
        el.draw = function()
            el.lab.Position = Vector2.new(el.x + 9, el.y + 4)
            el.lab.Text = el.text
            el.lab.Color = C_WHT
            for _, p in ipairs(el.parts) do p.Visible = el.show end
        end
        el.click = function() end

    elseif type == "TextBox" then
        el.h = 30
        el.value = { Text = (value.Text ~= nil and value.Text) or (data.default and data.default.Text) or "" }
        el.def = { Text = el.value.Text }
        el.bg = D("Square", { Filled = true, Color = C_CTRL, Size = Vector2.new(215, 20), ZIndex = 6 })
        el.tx = T(13, C_GRY)
        el.parts = { el.bg, el.tx }
        el.draw = function()
            el.bg.Position = Vector2.new(el.x + (el.w - 215) / 2, el.y + 5)
            el.tx.Position = Vector2.new(el.x + el.w / 2 - 100, el.y + 9)
            if el.value.Text == "" and focusTextBox ~= el then
                el.tx.Text = el.text .. "..."
            else
                el.tx.Text = el.value.Text
            end
            el.tx.Color = (el.hov or focusTextBox == el) and C_WHT or C_GRY
            for _, p in ipairs(el.parts) do p.Visible = el.show end
        end
        el.click = function()
            focusTextBox = el
        end

    elseif type == "Scroll" then
        local ss = math.max(1, data.scrollsize or 5)
        el.h = ss * 20 + 10
        el.value = { Scroll = value.Scroll or el.opts[1] }
        el.sel = el.value.Scroll
        el.scroll = 0
        el.rows = {}
        for i = 1, 12 do
            el.rows[i] = {
                bg = D("Square", { Filled = true, Color = C_CTRL, ZIndex = 6 }),
                dec = D("Square", { Filled = true, Color = C_ACC, Size = Vector2.new(1, 20), ZIndex = 7 }),
                tx = T(13, C_GRY),
            }
            accentReg[#accentReg + 1] = el.rows[i].dec
        end
        el.draw = function()
            for i = 1, 12 do
                local r = el.rows[i]
                local idx = el.scroll + i
                local showRow = el.show and idx <= #el.opts
                r.bg.Visible = showRow
                r.tx.Visible = showRow
                r.dec.Visible = showRow and el.opts[idx] == el.sel
                if showRow then
                    r.bg.Position = Vector2.new(el.x + (el.w - 215) / 2, el.y + 5 + (i - 1) * 20)
                    r.bg.Size = Vector2.new(215, 20)
                    r.tx.Text = el.opts[idx]
                    r.tx.Position = Vector2.new(el.x + (el.w - 215) / 2 + 7, el.y + 9 + (i - 1) * 20)
                    local isSel = el.opts[idx] == el.sel
                    r.tx.Color = isSel and C_WHT or (hovEl == el and hovRow == idx and C_GRY2 or C_GRY)
                    r.dec.Position = Vector2.new(el.x + (el.w - 215) / 2, el.y + 5 + (i - 1) * 20)
                end
            end
        end
        el.select = function(self, idx)
            local o = el.opts[idx]
            if not o then return end
            el.sel = o
            el.value.Scroll = o
            commit()
            if el.cb then pcall(el.cb, el.value) end
        end
        el.add_value = function(self, v)
            for _, o in ipairs(el.opts) do if o == v then return end end
            el.opts[#el.opts + 1] = v
        end
        commit()
    end

    return el
end

local library = {}

local function ensureDir(d)
    pcall(function() makefolder(d) end)
end
local function listCfg(d)
    local out = {}
    local ok, files = pcall(listfiles, d)
    if ok and files then
        for _, f in ipairs(files) do
            local n = f:gsub("^.+[\\/]", ""):gsub("%.txt$", "")
            if n ~= "" then out[#out + 1] = n end
        end
    end
    return out
end

local CFG_DIR = "nemv2"

local function deepcopy(o)
    if type(o) ~= "table" then return o end
    local c = {}
    for k, v in pairs(o) do c[k] = deepcopy(v) end
    return c
end

function library:set_accent(col)
    C_ACC = col
    C_TACC = Color3.new(col.R * 0.93, col.G * 0.93, col.B * 0.93)
    C_SL1 = col
    C_UL = col
    for _, d in ipairs(accentReg) do d.Color = col end
    for i = 1, GRAD_N do
        local t = (i - 1) / (GRAD_N - 1)
        if t < 0.55 then
            local k = 1 - t / 0.55
            k = k * k * (3 - 2 * k)
            gradStrips[i].Color = Color3.new(
                C_WBG.R + (col.R - C_WBG.R) * 0.20 * k,
                C_WBG.G + (col.G - C_WBG.G) * 0.20 * k,
                C_WBG.B + (col.B - C_WBG.B) * 0.20 * k)
        end
    end
end

function library:save_cfg(name)
    ensureDir(CFG_DIR)
    local flat = {}
    for t, tabV in pairs(values) do
        for s, secV in pairs(tabV) do
            for k, sec in pairs(secV) do
                for flag, v in pairs(sec) do
                    local vc = deepcopy(v)
                    if type(vc) == "table" and vc.Color then
                        vc.Color = { R = vc.Color.R, G = vc.Color.G, B = vc.Color.B }
                    end
                    flat[(tostring(t) .. "|" .. tostring(s) .. "|" .. tostring(k) .. "|" .. tostring(flag))] = vc
                end
            end
        end
    end
    local ok, err = pcall(function() writefile(CFG_DIR .. "\\" .. name .. ".txt", HttpService:JSONEncode(flat)) end)
end

function library:load_cfg(name)
    local ok, data = pcall(function() return HttpService:JSONDecode(readfile(CFG_DIR .. "\\" .. name .. ".txt")) end)
    if not ok then return end
    for key, v in pairs(data) do
        local t, s, k, flag = key:match("^(.-)|(.-)|(.-)|(.*)$")
        if t and values[t] and values[t][s] and values[t][s][k] and values[t][s][k][flag] ~= nil then
            if type(v) == "table" and v.Color then
                v.Color = Color3.new(v.Color.R or 1, v.Color.G or 1, v.Color.B or 1)
            end
            values[t][s][k][flag] = v
        end
    end
end

function library:set_alpha(a)
    uiAlpha = math.clamp(a, 0, 1)
    for i = 1, #allD do
        local bt = baseTs[i]
        if type(bt) ~= "number" then bt = 0 end
        pcall(function() allD[i].Transparency = bt * uiAlpha end)
    end
end

function library:fire_all()
    for _, tb in ipairs(tabHandles) do
        for _, sec in ipairs(tb.sections) do
            for _, sector in ipairs(sec.sectors) do
                for _, el in ipairs(sector.elements) do
                    if el.cb and el.value and el.def then pcall(el.cb, el.value) end
                end
            end
        end
    end
end

function library:set_all_toggles(state)
    for _, tb in ipairs(tabHandles) do
        for _, sec in ipairs(tb.sections) do
            for _, sector in ipairs(sec.sectors) do
                for _, el in ipairs(sector.elements) do
                    if el.def and el.def.Toggle ~= nil and el.value.Toggle ~= state then
                        el.value.Toggle = state
                        pcall(el.cb, el.value)
                    end
                end
            end
        end
    end
end

function library:reset_ui()
    for _, tb in ipairs(tabHandles) do
        for _, sec in ipairs(tb.sections) do
            for _, sector in ipairs(sec.sectors) do
                for _, el in ipairs(sector.elements) do
                    if el.def then
                        if el.def.Toggle ~= nil then el.value.Toggle = el.def.Toggle end
                        if el.def.Slider ~= nil then el.value.Slider = el.def.Slider end
                        if el.def.Dropdown ~= nil then el.value.Dropdown = el.def.Dropdown end
                        if el.def.Combo ~= nil then
                            local c = {}
                            for _, o in ipairs(el.def.Combo) do c[#c + 1] = o end
                            el.value.Combo = c
                        end
                        if el.def.Text ~= nil then el.value.Text = el.def.Text end
                        if el.cb then pcall(el.cb, el.value) end
                    end
                    if el.cl and el.cl.defC then
                        el.cl.value.Color = el.cl.defC
                        if el.cl.cb then pcall(el.cl.cb, el.cl.value) end
                    end
                end
            end
        end
    end
end

function library.new(title, cfgDir)
    if cfgDir then CFG_DIR = cfgDir:gsub("[\\/]+$", "") end
    local cam = pcall(function() return workspace.CurrentCamera end)
    local vs = pcall(function() return workspace.CurrentCamera.ViewportSize end)
    local cx = type(vs) == "table" and vs.X or 1600
    local cy = type(vs) == "table" and vs.Y or 900
    uiPos = Vector2.new(math.floor(cx / 2 - WIN_W / 2), math.max(0, math.floor(cy / 2 - WIN_H / 2)))

    local menu = {}
    menu.values = values
    menu.open = menuOpen

    menu.save_cfg = function(n) library:save_cfg(n) end
    menu.load_cfg = function(n) library:load_cfg(n) end

    function menu.new_tab(icon)
        local gi, im = makeIcon(icon)
    local tab = { sections = {}, activeSection = 1, tabNum = #tabHandles + 1, icon = gi, img = im }
            tab.btnBg = D("Square", { Filled = true, Color = C_WBG, ZIndex = 5 })
        values[tab.tabNum] = {}
        tabHandles[#tabHandles + 1] = tab

        function tab.new_section(name)
            local sec = { name = name, hov = false }
            sec.txt = T(15, C_GRY)
            sec.txt.Outline = true
            sec.ulSegs = {}
            local K = 14
            for k = 1, K do
                local f = math.abs(k - (K + 1) * 0.5) / ((K + 1) * 0.5)
                local v = 0.95 - (0.95 - 0.06) * f
                sec.ulSegs[k] = D("Square", { Filled = true, Color = C_UL, Size = Vector2.new(1, 1), ZIndex = 6, Transparency = v })
                accentReg[#accentReg + 1] = sec.ulSegs[k]
            end
            sec.sectors = {}
            values[tab.tabNum][name] = {}

            tab.sections[#tab.sections + 1] = sec

            function sec.new_sector(sname, side)
                local sector = {
                    name = sname,
                    side = side or "Left",
                    elements = {},
                    height = 20,
                }
                sec.sectors[#sec.sectors + 1] = sector
                sector.outer = D("Square", { Filled = true, Color = C_SOUT, ZIndex = 4 })
                sector.cont = D("Square", { Filled = true, Color = C_CNT, ZIndex = 5 })
                sector.border = fakeOutline(4, 1)
                sector.border.Color = C_SBDR
                sector.title = T(14, C_WHT)
                sector.title.Text = sname
                sector.title.Outline = true
                values[tab.tabNum][name][sname] = {}

                function sector.element(type, text, data, cb)
                    local el = makeElement(type, text, data or {}, cb or function() end, sector, tab.tabNum, name)
                    sector.height = sector.height + el.h
                    sector.elements[#sector.elements + 1] = el
                    return el
                end

                return sector
            end

            return sec
        end

        return tab
    end

    return menu
end

local RAIL_X, RAIL_Y, RAIL_W, RAIL_H = 12, 41, 76, 447
local TB_W, TB_H = 76, 90
local COL_X, COL_Y, COL_W = 102, 42, 586
local COL_GAP, COL_LEFT_W = 8, 282
local SEC_H = 28

local function layout()
    local x0, y0 = uiPos.X, uiPos.Y

    winBg.Position = uiPos
    winBg.Size = Vector2.new(WIN_W, WIN_H)
    winBd.Position = uiPos
    winBd.Size = Vector2.new(WIN_W, WIN_H)
    if not gradPos or gradPos.X ~= uiPos.X or gradPos.Y ~= uiPos.Y then
        local sh = math.ceil(WIN_H / GRAD_N)
        for i = 1, GRAD_N do
            gradStrips[i].Position = Vector2.new(uiPos.X, uiPos.Y + (i - 1) * sh)
        end
        railBd.Position = Vector2.new(uiPos.X + RAIL_X - 2, uiPos.Y + RAIL_Y - 2)
        railBd.Size = Vector2.new(TB_W + 4, #tabHandles * TB_H + 4)
        gradPos = uiPos
    end
    do
        local K = #titleSepSegs
        local tw = (WIN_W - 20) / K
        for k, seg in ipairs(titleSepSegs) do
            seg.Position = Vector2.new(x0 + 10 + (k - 1) * tw, y0 + 36)
            seg.Size = Vector2.new(tw + 1, 1)
        end
    end
    titleTxt.Position = Vector2.new(x0 + 11, y0 + 8)
    titleTxt.Text = "gennegen"
    do
        local ax = x0 + RAIL_X + 4
        local ay = y0 + WIN_H - 62
        avRing.Position = Vector2.new(ax + 20, ay + 20)
        avImg.Position = Vector2.new(ax, ay)
        avName.Position = Vector2.new(ax + 48, ay + 12)
    end

    for i, tb in ipairs(tabHandles) do
        local bx = x0 + RAIL_X
        local by = y0 + RAIL_Y + (i - 1) * TB_H
        tb.rect = { x = bx, y = by, w = TB_W, h = TB_H }
        local pt = (hovTab == tb) and 1 or 0
        local pd = pt - (tb._pop or 0)
        if math.abs(pd) < 0.02 then tb._pop = pt else tb._pop = (tb._pop or 0) + pd * 0.25 end
        local p = tb._pop
        local grow = 1 + 0.04 * p
        local bw, bh = TB_W * grow, TB_H * grow
        tb.btnBg.Position = Vector2.new(bx + p * 5 - (bw - TB_W) * 0.5, by - (bh - TB_H) * 0.5)
        tb.btnBg.Size = Vector2.new(bw, bh)
        tb.btnBg.ZIndex = (hovTab == tb) and 6 or 5
        local active = i == activeTab
        local bgTgt = active and C_TACC or (hovTab == tb and C_CNT or C_WBG)
        tb._bgC = colLerp(tb._bgC or bgTgt, bgTgt, 0.22)
        tb.btnBg.Color = tb._bgC
        local icTgt = active and C_WHT or (hovTab == tb and C_GRY2 or C_GRY)
        tb._icC = colLerp(tb._icC or icTgt, icTgt, 0.22)
        local s = 1 + 0.22 * p
        local cx, cy = bx + 38 + p * 5, by + 45
        local im = tb.img
        local imgOn = im and im.IsLoaded
        for _, g in ipairs(tb.icon) do
            g.Visible = not imgOn
        end
        if im then
            if imgOn then
                im.ZIndex = (hovTab == tb) and 10 or 9
                im.Position = Vector2.new(cx - 21 * s, cy - 21 * s)
                im.Size = Vector2.new(42 * s, 42 * s)
            end
            im.Visible = imgOn
        end
    for _, g in ipairs(tb.icon) do
        local info = iconInfo[g]
        g.Color = tb._icC
        g.ZIndex = (hovTab == tb) and 10 or 9
        if info and info.fx then
            g.From = Vector2.new(cx + info.fx * s, cy + info.fy * s)
            g.To = Vector2.new(cx + info.tx * s, cy + info.ty * s)
        elseif info and info.kx then
            g.Position = Vector2.new(cx + info.kx * s, cy + info.ky * s)
        else
            g.Position = Vector2.new(cx, cy)
        end
    end
    end

    local tab = tabHandles[activeTab]
    if not tab then return end
    local sX0 = x0 + COL_X
    local sY0 = y0 + COL_Y
    local n = #tab.sections
    local sw = n > 0 and (COL_W / n) or COL_W
    for i, sec in ipairs(tab.sections) do
        local hx = sX0 + (i - 1) * sw
        sec.rect = { x = hx, y = sY0, w = sw, h = SEC_H }
        sec.txt.Text = sec.name
        local tw = sec.txt.TextBounds.X
        sec.txt.Position = Vector2.new(hx + sw * 0.5 - tw * 0.5, sY0 + 11)
        local active = i == tab.activeSection
        sec.txt.Color = active and C_ACC or C_WHT
        local K = #sec.ulSegs
        local tw = sw / K
        for k, seg in ipairs(sec.ulSegs) do
            seg.Position = Vector2.new(hx + (k - 1) * tw, sY0 + 27)
            seg.Size = Vector2.new(tw + 1, 1)
            seg.Visible = active
        end
    end

    local cy0 = y0 + COL_Y + SEC_H + 1
    local colL = { x = x0 + COL_X + 8, y = cy0 + 14 }
    local colR = { x = x0 + COL_X + 298, y = cy0 + 14 }
    local activeSec = tab.sections[tab.activeSection]
    if not activeSec then return end

    local curL, curR = 0, 0
    for _, sec in ipairs(activeSec.sectors) do
        local isR = sec.side == "Right"
        local col = isR and colR or colL
        local top = isR and curR or curL
        local sy = col.y + top
        local pt = (hovSector == sec) and 1 or 0
        local pd = pt - (sec._pop or 0)
        if math.abs(pd) < 0.02 then sec._pop = pt else sec._pop = (sec._pop or 0) + pd * 0.25 end
        local po = sec._pop * 4
        sec.outer.Position = Vector2.new(col.x + po, sy)
        sec.outer.Size = Vector2.new(COL_LEFT_W, sec.height)
        sec.cont.Position = Vector2.new(col.x + 1 + po, sy + 1)
        sec.cont.Size = Vector2.new(COL_LEFT_W - 2, sec.height - 2)
        sec.border.Position = Vector2.new(col.x + po, sy)
        sec.border.Size = Vector2.new(COL_LEFT_W, sec.height)
        sec.title.Position = Vector2.new(col.x + po + COL_LEFT_W / 2 - sec.title.TextBounds.X / 2, sy - 8)

        local ey = sy + 13
        for _, el in ipairs(sec.elements) do
            el.x = col.x + po
            el.y = ey
            el.w = COL_LEFT_W
            el.rect = { x = col.x + po, y = ey, w = COL_LEFT_W, h = el.h }
            el.show = true
            el:draw()
            if el.kb then el.kb.rect.x = col.x + po + COL_LEFT_W - 10 - el.kb.rect.w end
            ey = ey + el.h
        end
        sec.bounds = { x = col.x, y = sy, w = COL_LEFT_W, h = sec.height }
        local inc = top + sec.height + 12
        if isR then curR = inc else curL = inc end
    end

    local bdX = sX0 - 1
    local bdW = COL_W + 2
    local bdY = sY0 - 1
    local bdH = math.max(1, (colL.y + math.max(curL, curR) - 2) - bdY + 1)
    contentBd.Position = Vector2.new(bdX, bdY)
    contentBd.Size = Vector2.new(bdW, bdH)
end

local m1Prev = false
local function handleClick(mx, my)
    if openPopup then
        if inRect(mx, my, openPopup.x, openPopup.y, 260, openPopup.h) then
            local idx = math.floor((my - openPopup.y) / 20) + 1
            if idx >= 1 and idx <= #openPopup.rows then
                local p = openPopup
                if p.owner and (p.owner.kind == "Dropdown" or p.owner.kind == "Combo") then
                    p.owner:select(idx)
                elseif p.kind == "color" and p.owner then
                    p.owner.value.Color = p.rows[idx].color
                    if p.owner.cb then pcall(p.owner.cb, p.owner.value) end
                elseif p.kind == "keybind" and p.owner then
                    p.owner.value.Type = p.rows[idx].txt
                    p.owner.value.Active = true
                    if p.owner.cb then pcall(p.owner.cb, p.owner.value) end
                end
            end
            openPopup = nil
            return true
        else
            if openPopup.owner then openPopup.owner.open = false end
            openPopup = nil
        end
    end

    for i, tb in ipairs(tabHandles) do
        if tb.rect and inRect(mx, my, tb.rect.x, tb.rect.y, tb.rect.w, tb.rect.h) then
            activeTab = i
            openPopup = nil
            return true
        end
    end

    local tab = tabHandles[activeTab]
    if tab then
        for i, sec in ipairs(tab.sections) do
            if sec.rect and inRect(mx, my, sec.rect.x, sec.rect.y, sec.rect.w, sec.rect.h) then
                tab.activeSection = i
                openPopup = nil
                return true
            end
        end
    end

    if tab then
                local activeSec = tab.sections[tab.activeSection]
                if activeSec then
                    for _, sec in ipairs(activeSec.sectors) do
                        for _, el in ipairs(sec.elements) do
                    local r = el.rect
                    if r and inRect(mx, my, r.x, r.y, r.w, r.h) then
                        if el.kind == "Toggle" then
                            if el.kb and inRect(mx, my, el.kb.rect.x, el.kb.rect.y, el.kb.rect.w, el.kb.rect.h) then
                                bindingKB = el.kb
                                return true
                            end
                            if el.cl and inRect(mx, my, el.cl.rect.x, el.cl.rect.y, el.cl.rect.w, el.cl.rect.h) then
                                openPopup = { kind = "color", owner = el.cl, x = r.x + r.w - 55, y = r.y, h = #PRESETS * 20, rows = {} }
                                local cur = el.cl.value.Color
                                for i, pr in ipairs(PRESETS) do
                                    local m = math.abs(cur.R - pr[2].R) < 0.01 and math.abs(cur.G - pr[2].G) < 0.01 and math.abs(cur.B - pr[2].B) < 0.01
                                    openPopup.rows[i] = { txt = pr[1], color = pr[2], sel = m }
                                end
                                return true
                            end
                            el:click()
                            return true
                        elseif el.kind == "Dropdown" or el.kind == "Combo" then
                            el.openPopup()
                            return true
                        elseif el.kind == "Slider" then
                            el.dragging = true
                            el:drag(mx)
                            return true
                        elseif el.kind == "Button" then
                            el:click()
                            return true
                        elseif el.kind == "TextBox" then
                            focusTextBox = el
                            return true
                        elseif el.kind == "Scroll" then
                            local boxX = r.x + (r.w - 215) / 2
                            local boxY = r.y + 5
                            if inRect(mx, my, boxX, boxY, 215, 60) then
                                local idx = el.scroll + math.floor((my - boxY) / 20) + 1
                                el:select(idx)
                            end
                            return true
                        end
                    end
                end
            end
        end
    end

    if inRect(mx, my, uiPos.X, uiPos.Y, WIN_W, WIN_H) then
        winDrag = true
        dragOffX = mx - uiPos.X
        dragOffY = my - uiPos.Y
        return true
    end
    return false
end

local m2Prev = false
local function handleRightClick(mx, my)
    if openPopup then
        openPopup = nil
        return true
    end
    local tab = tabHandles[activeTab]
    if not tab then return false end
    local activeSec = tab.sections[tab.activeSection]
    if not activeSec then return false end
    for _, sec in ipairs(activeSec.sectors) do
        for _, el in ipairs(sec.elements) do
            if el.kind == "Toggle" and el.kb and el.kb.rect and inRect(mx, my, el.kb.rect.x, el.kb.rect.y, el.kb.rect.w, el.kb.rect.h) then
                openPopup = { kind = "keybind", owner = el.kb, x = el.kb.rect.x, y = el.kb.rect.y, h = 60, rows = {} }
                local types = { "Always", "Hold", "Toggle" }
                for i, t in ipairs(types) do
                    openPopup.rows[i] = { txt = t, sel = el.kb.value.Type == t }
                end
                return true
            end
        end
    end
    return false
end

local conn
conn = RunService.RenderStepped:Connect(function()
    if not running or GEN ~= _G_._genGEN then
        conn:Disconnect()
        return
    end

    local m = nil
    if lp then pcall(function() m = lp:GetMouse() end) end
    local mx, my = 0, 0
    if m then mx, my = m.X, m.Y end

    if menuOpen then
        gShow = true
        local m1 = ismouse1pressed()
        local m2 = ismouse2pressed()

        hovEl, hovKB, hovSwatch, hovTab, hovSec, hovRow, hovSector = nil, nil, nil, nil, nil, nil, nil
        if openPopup and inRect(mx, my, openPopup.x, openPopup.y, 260, openPopup.h) then
            hovRow = math.floor((my - openPopup.y) / 20) + 1
        else
            for _, tb in ipairs(tabHandles) do
                if tb.rect and inRect(mx, my, tb.rect.x, tb.rect.y, tb.rect.w, tb.rect.h) then hovTab = tb end
            end
            local tab = tabHandles[activeTab]
            if tab then
                for _, sec in ipairs(tab.sections) do
                    if sec.rect and inRect(mx, my, sec.rect.x, sec.rect.y, sec.rect.w, sec.rect.h) then hovSec = sec end
                end
                local activeSec = tab.sections[tab.activeSection]
                if activeSec then
                    for _, sec in ipairs(activeSec.sectors) do
                        if sec.bounds and inRect(mx, my, sec.bounds.x, sec.bounds.y, sec.bounds.w, sec.bounds.h) then
                            hovSector = sec
                        end
                        for _, el in ipairs(sec.elements) do
                            if el.rect and inRect(mx, my, el.rect.x, el.rect.y, el.rect.w, el.rect.h) then
                                hovEl = el
                                if el.kb and inRect(mx, my, el.kb.rect.x, el.kb.rect.y, el.kb.rect.w, el.kb.rect.h) then
                                    hovKB = el.kb
                                end
                                if el.cl and inRect(mx, my, el.cl.rect.x, el.cl.rect.y, el.cl.rect.w, el.cl.rect.h) then
                                    hovSwatch = el.cl
                                end
                                if el.kind == "Scroll" then
                                    hovRow = el.scroll + math.floor((my - (el.rect.y + 5)) / 20) + 1
                                end
                            end
                        end
                    end
                end
            end
        end

        if m1 and not m1Prev then
            handleClick(mx, my)
        end
        if m2 and not m2Prev then
            handleRightClick(mx, my)
        end
        m1Prev, m2Prev = m1, m2

        if m1 then
            for _, tb in ipairs(tabHandles) do
                if tb.tabNum == activeTab then
                    local activeSec = tb.sections[tb.activeSection]
                    if activeSec then
                        for _, sec in ipairs(activeSec.sectors) do
                            for _, el in ipairs(sec.elements) do
                                if el.dragging and el.kind == "Slider" then el:drag(mx) end
                            end
                        end
                    end
                end
            end
        else
            for _, tb in ipairs(tabHandles) do
                if tb.tabNum == activeTab then
                    local activeSec = tb.sections[tb.activeSection]
                    if activeSec then
                        for _, sec in ipairs(activeSec.sectors) do
                            for _, el in ipairs(sec.elements) do
                                if el.dragging then el.dragging = false end
                            end
                        end
                    end
                end
            end
        end

        if winDrag then
            uiPos = Vector2.new(mx - dragOffX, math.max(0, my - dragOffY))
        end
        if not m1 then winDrag = false end

        winBg.Visible = true
        winBd.Visible = true
        for i = 1, GRAD_N do gradStrips[i].Visible = true end
        for _, seg in ipairs(titleSepSegs) do seg.Visible = true end
        contentBd.Visible = true
        titleTxt.Visible = true
        railBd.Visible = true
        avRing.Visible = avImg.IsLoaded and not _G._genHideCard
        avImg.Visible = avImg.IsLoaded and not _G._genHideCard
        avName.Visible = not _G._genHideCard
        for _, tb in ipairs(tabHandles) do
            tb.btnBg.Visible = true
            for _, g in ipairs(tb.icon) do g.Visible = true end
            local isActiveTab = tb.tabNum == activeTab
            local activeSec = isActiveTab and tb.sections[tb.activeSection]
            for _, sec in ipairs(tb.sections) do
                sec.txt.Visible = isActiveTab
                local ulVis = isActiveTab and sec == activeSec
                for _, seg in ipairs(sec.ulSegs) do seg.Visible = ulVis end
                for _, sector in ipairs(sec.sectors) do
                    local svis = isActiveTab and sec == activeSec
                    sector.outer.Visible = svis
                    sector.cont.Visible = svis
                    sector.border.Visible = svis
                    sector.title.Visible = svis
                    for _, el in ipairs(sector.elements) do
                        el.show = svis
                        el:draw()
                    end
                end
            end
        end

        layout()
        renderPopup()
    else
        gShow = false
        winBg.Visible = false
        winBd.Visible = false
        for i = 1, GRAD_N do gradStrips[i].Visible = false end
        for _, seg in ipairs(titleSepSegs) do seg.Visible = false end
        contentBd.Visible = false
        titleTxt.Visible = false
        railBd.Visible = false
        avRing.Visible = false
        avImg.Visible = false
        avName.Visible = false
        for _, tb in ipairs(tabHandles) do
            tb.btnBg.Visible = false
            for _, g in ipairs(tb.icon) do g.Visible = false end
            if tb.img then tb.img.Visible = false end
            for _, sec in ipairs(tb.sections) do
                sec.txt.Visible = false
                for _, seg in ipairs(sec.ulSegs) do seg.Visible = false end
                for _, sector in ipairs(sec.sectors) do
                    sector.outer.Visible = false
                    sector.cont.Visible = false
                    sector.border.Visible = false
                    sector.title.Visible = false
                    for _, el in ipairs(sector.elements) do
                        el.show = false
                        el:draw()
                    end
                end
            end
        end
        renderPopup()
    end
end)

local keyPrev = {}
local insertVK = nameToVK["Insert"]
local insertPrev = false

task.spawn(function()
    while running and GEN == _G_._genGEN do
        pcall(function()
        local ins = false
        local uiVK = _G._genUIKey or insertVK
        pcall(function() ins = iskeypressed(uiVK) end)
        if ins and not insertPrev then
            menuOpen = not menuOpen
        end
        insertPrev = ins

        if bindingKB then
            for _, vk in ipairs(commonVKs) do
                local down = false
                pcall(function() down = iskeypressed(vk) end)
                if down and not keyPrev[vk] then
                    if vk == nameToVK["Escape"] then
                        bindingKB.value.Key = nil
                    else
                        bindingKB.value.Key = vk
                    end
                    bindingKB.value.Active = true
                    if bindingKB.cb then pcall(bindingKB.cb, bindingKB.value) end
                        bindingKB = nil
                    break
                end
                keyPrev[vk] = down
            end
        elseif focusTextBox then
            for _, vk in ipairs(commonVKs) do
                local down = false
                pcall(function() down = iskeypressed(vk) end)
                if down and not keyPrev[vk] then
                    if vk == nameToVK["Enter"] or vk == nameToVK["Escape"] then
                        focusTextBox = nil
                    elseif vk == nameToVK["Backspace"] then
                        local txt = focusTextBox.value.Text or ""
                        focusTextBox.value.Text = txt:sub(1, #txt - 1)
                    else
                        local ch = vkChar(vk)
                        if ch and #(focusTextBox.value.Text or "") < 60 then
                            focusTextBox.value.Text = (focusTextBox.value.Text or "") .. ch
                        end
                    end
                    if focusTextBox and focusTextBox.cb then pcall(focusTextBox.cb, focusTextBox.value) end
                    break
                end
                keyPrev[vk] = down
            end
        else
            for _, tb in ipairs(tabHandles) do
                for _, sec in ipairs(tb.sections) do
                    for _, sector in ipairs(sec.sectors) do
                        for _, el in ipairs(sector.elements) do
                            if el.kb and el.kb.value.Key then
                                local k = el.kb.value.Key
                                local down = false
                                pcall(function() down = iskeypressed(k) end)
                                local v = el.kb.value
                                local was = kbHeld[el.kb]
                                if v.Type == "Always" then
                                    v.Active = true
                                elseif v.Type == "Hold" then
                                    v.Active = down
                                    if down and not was then
                                        if el.kb.cb then pcall(el.kb.cb, v) end
                                        if el.kb.toggleElement and el.click then el:click() end
                                    end
                                elseif v.Type == "Toggle" then
                                    if down and not was then
                                        v.Active = not v.Active
                                        if el.kb.cb then pcall(el.kb.cb, v) end
                                        if el.kb.toggleElement and el.click then el:click() end
                                    end
                                end
                                kbHeld[el.kb] = down
                            end
                        end
                    end
                end
            end
        end
        end)
        task.wait(0.03)
    end
end)

task.spawn(function()
    while running and GEN == _G_._genGEN do
        pcall(function()
        local files = listCfg(CFG_DIR)
        for _, tb in ipairs(tabHandles) do
            for _, sec in ipairs(tb.sections) do
                for _, sector in ipairs(sec.sectors) do
                    for _, el in ipairs(sector.elements) do
                        if el.kind == "Scroll" then
                            for _, f in ipairs(files) do el:add_value(f) end
                        end
                    end
                end
            end
        end
        end)
        task.wait(1)
    end
end)

_G_._genToken = {
    unload = function()
        running = false
        if conn then pcall(function() conn:Disconnect() end) end
        for _, d in ipairs(allD) do pcall(function() d:Remove() end) end
        _G_._genToken = nil
    end,
}

_G.GenDbg = {
    state = function()
        local out = {}
        out.activeTab = activeTab
        out.uiPos = { uiPos.X, uiPos.Y }
        out.drawings = #allD
        out.winBorder = (winBd._parts and winBd._parts[1].Visible) or false
        out.contentBd = (contentBd._parts and contentBd._parts[1].Visible) or false
        out.contentRect = contentBd._rect and { contentBd._rect[1], contentBd._rect[2], contentBd._rect[3], contentBd._rect[4] } or {}
        out.tabs = {}
        for i, tb in ipairs(tabHandles) do
            out.tabs[i] = { activeSection = tb.activeSection, sections = #tb.sections }
        end
        local tb = tabHandles[activeTab]
        if tb then
            local sec = tb.sections[tb.activeSection]
            out.activeSectionName = sec and sec.name
            if sec then
                out.sectors = {}
                for _, s in ipairs(sec.sectors) do
                    local bvis = false
                    local bpos = { 0, 0 }
                    if s.border and s.border._parts then
                        bvis = s.border._parts[1].Visible
                        local r = s.border._rect
                        bpos = { r[1], r[2] }
                    end
                    out.sectors[#out.sectors + 1] = {
                        name = s.name, h = s.height, side = s.side,
                        outerVis = s.outer.Visible,
                        outerPos = { s.outer.Position.X, s.outer.Position.Y },
                        outerSize = { s.outer.Size.X, s.outer.Size.Y },
                        titleVis = s.title.Visible,
                        borderVis = bvis,
                        borderPos = bpos,
                    }
                end
            end
        end
        return out
    end,
    simDrag = function(x, y)
        local tab = tabHandles[activeTab]
        if not tab then return "no tab" end
        local activeSec = tab.sections[tab.activeSection]
        if not activeSec then return "no section" end
        for _, sec in ipairs(activeSec.sectors) do
            for _, el in ipairs(sec.elements) do
                if el.kind == "Slider" and el.rect and inRect(x, y, el.rect.x, el.rect.y, el.rect.w, el.rect.h) then
                    el.dragging = true
                    local okd, errd = pcall(function() el:drag(x) end)
                    if not okd then
                        return "drag ERROR: " .. tostring(errd)
                            .. " | x=" .. tostring(x) .. "(" .. typeof(x) .. ")"
                            .. " | el.x=" .. tostring(el.x) .. "(" .. typeof(el.x) .. ")"
                            .. " | el.min=" .. tostring(el.min) .. " | el.max=" .. tostring(el.max)
                    end
                    return "hit " .. el.text .. " -> " .. tostring(el.value.Slider)
                end
            end
        end
        return "no slider at " .. tostring(x) .. "," .. tostring(y)
    end,
    sliderValues = function()
        local out = {}
        local tab = tabHandles[activeTab]
        if not tab then return out end
        local activeSec = tab.sections[tab.activeSection]
        if not activeSec then return out end
        for _, sec in ipairs(activeSec.sectors) do
            for _, el in ipairs(sec.elements) do
                if el.kind == "Slider" then
                    out[#out + 1] = { name = el.text, val = el.value.Slider, x = math.floor(el.x), y = math.floor(el.y), rect = { el.rect.x, el.rect.y, el.rect.w, el.rect.h } }
                end
            end
        end
        return out
    end,
    setTab = function(i)
        if tabHandles[i] then activeTab = i end
    end,
    openDD = function(label)
        local tab = tabHandles[activeTab]
        if not tab then return "no tab" end
        local activeSec = tab.sections[tab.activeSection]
        if not activeSec then return "no sec" end
        for _, sec in ipairs(activeSec.sectors) do
            for _, el in ipairs(sec.elements) do
                if (el.kind == "Dropdown" or el.kind == "Combo") and (label == nil or el.text == label) then
                    el.openPopup()
                    return "opened"
                end
            end
        end
        return "no dropdown"
    end,
    setOpen = function(b)
        menuOpen = b and true or false
        return menuOpen
    end,
    visSample = function()
        local out = { menuOpen = menuOpen }
        local tb = tabHandles[activeTab]
        if not tb then return out end
        local sec = tb.sections[tb.activeSection]
        if not sec then return out end
        for _, s in ipairs(sec.sectors) do
            for _, el in ipairs(s.elements) do
                out[#out + 1] = {
                    text = el.text, show = tostring(el.show),
                    labVis = el.lab and el.lab.Visible,
                    boxVis = el.box and el.box.Visible,
                    kbVis = el.kb and el.kb.txt.Visible,
                }
                if #out >= 6 then return out end
            end
        end
        return out
    end,
    popState = function()
        local out = {}
        if not openPopup then return { open = false } end
        out.open = true
        for i = 1, #openPopup.rows do
            local pr = popRows[i]
            out[#out + 1] = { txt = tostring(pr.tx.Text), vis = tostring(pr.tx.Visible), z = tostring(pr.tx.ZIndex) }
        end
        return out
    end,
    findEl = function(label)
        local res = {}
        for _, tb in ipairs(tabHandles) do
            for _, sec in ipairs(tb.sections) do
                for _, sector in ipairs(sec.sectors) do
                    for _, el in ipairs(sector.elements) do
                        if el.text == label or (el.kind == "Dropdown" and el.value and el.value.Dropdown) then
                            if el.kind == "Dropdown" then
                                res[#res + 1] = {
                                    text = el.text, kind = el.kind,
                                    val = tostring(el.value and el.value.Dropdown),
                                    x = el.x, y = el.y, show = tostring(el.show),
                                    btnTxt = tostring(el.btnTxt and el.btnTxt.Text),
                                    btnVis = tostring(el.btnTxt and el.btnTxt.Visible),
                                    btnPos = el.btnTxt and (el.btnTxt.Position.X .. "," .. el.btnTxt.Position.Y) or "none",
                                }
                            end
                        end
                    end
                end
            end
        end
        return res
    end,
}

_G.GenLib = library
return library
