
if _G._genToken then pcall(function() _G._genToken.unload() end) end
_G.GenLib = nil

loadstring(readfile("gennegen_lib.lua"))()
local library = _G.GenLib
local lala = _G.autoParry or {}

local hs = game:GetService("HttpService")
local UI_CFG = "remybbui-config.json"

local function num(v, d) return type(v) == "number" and v or d end
local function boo(v, d) return type(v) == "boolean" and v or d end

local function cfgData()
    local L = _G.autoParry
    if not L then return nil end
    return {
        _version = 1,
        keyP = L.keyP, keyV = L.keyV, keyC = L.keyC, keyX = L.keyX,
        keyL = L.keyL, keyB = L.keyB, keyR = L.keyR, keyN = L.keyN, keyG = L.keyG,
        v2 = L.v2, autoplay = L.autoplay, abilityParry = L.abilityParry,
        abilityEsp = L.abilityEsp, abilityUpgradeEsp = L.abilityUpgradeEsp, accuracy = L.accuracy, randomize = L.randomize,
        pingComp = L.pingComp, leadTime = L.leadTime, pingMax = L.pingMax,
        customLeadMode = L.customLeadMode, customLeadValue = L.customLeadValue,
        accelLead = L.accelLead, fastFrame1 = L.fastFrame1, fastBallThreshold = L.fastBallThreshold,
        minDist = L.minDist, maxDist = L.maxDist, panicBase = L.panicBase,
        panicSpeedMul = L.panicSpeedMul, cooldown = L.cooldown, perBallCooldown = L.perBallCooldown,
        maxSpeed = L.maxSpeed, closeRangeDist = L.closeRangeDist,
        facingMin = L.facingMin, customFacingMinMode = L.customFacingMinMode, customFacingMinValue = L.customFacingMinValue,
        showVis = L.showVis, dome = L.dome, cone = L.cone, clash = L.clash,
        viewEnabled = L.viewEnabled, parryDistInd = L.parryDistInd,
        uiKey = _G._genUIKey,
        uiAccent = _G._genUIAccent,
        uiTrans = _G._genUITrans,
        hideCard = _G._genHideCard,
    }
end

local lastSnap = hs:JSONEncode(cfgData() or {})

local pendingSave = false
local lastSaveT = 0

local function flushSave()
    if not pendingSave then return end
    if tick() - lastSaveT < 0.5 then return end
    pendingSave = false
    lastSaveT = tick()
    local data = cfgData()
    if not data then return end
    pcall(function() writefile(UI_CFG, hs:JSONEncode(data)) end)
    lastSnap = hs:JSONEncode(data)
end

local function saveUI()
    pendingSave = true
end

local function loadUI()
    pcall(function()
        if not isfile(UI_CFG) then return end
        local data = hs:JSONDecode(readfile(UI_CFG))
        if type(data) ~= "table" then return end
        for k, v in pairs(data) do
            if k ~= "_version" then lala[k] = v end
        end
        if type(data.uiKey) == "number" then _G._genUIKey = data.uiKey end
        if type(data.uiAccent) == "string" then _G._genUIAccent = data.uiAccent end
        if type(data.uiTrans) == "number" then _G._genUITrans = math.clamp(data.uiTrans, 35, 100) end
        if type(data.hideCard) == "boolean" then _G._genHideCard = data.hideCard end
    end)
end
loadUI()

local menu = library.new("gennegen", "nemv2")

local ELS = {}

local MENU_GEN = (_G.__remyMenuGen or 0) + 1
_G.__remyMenuGen = MENU_GEN

local function T(sector, label, field, keyField)
    local el = sector.element("Toggle", label, {
        default = { Toggle = boo(lala[field], false) },
    }, function(v)
        lala[field] = v.Toggle
        saveUI()
    end)
    if keyField then
        local kb = el:add_keybind()
        kb.toggleElement = false
        kb.value.Key = lala[keyField] or nil
        kb.cb = function(v)
            lala[keyField] = v.Key
            saveUI()
        end
    end
    ELS[field] = { el = el, keyField = keyField }
    return el
end

local function S(sector, label, field, min, max, scale, fallback)
    local src = (_G.remybbDefaults and _G.remybbDefaults[field] ~= nil) and _G.remybbDefaults or lala
    local def = math.floor(num(src[field], fallback or 0) * scale + 0.5)
    def = math.max(min, math.min(max, def))
    local el = sector.element("Slider", label, {
        default = { min = min, max = max, default = def },
    }, function(v)
        lala[field] = v.Slider / scale
        saveUI()
    end)
    if scale ~= 1 then
        el.disp = function(v) return string.format("%.2f", v / scale) end
    end
    ELS[field] = { el = el, scale = scale }
    return el
end

do
    local main = menu.new_tab("sword")

    local autoParry = main.new_section("Auto Parry")

    local parry = autoParry.new_sector("Parry")
    T(parry, "Autoparry", "v2", "keyP")
    T(parry, "Clash", "clash", "keyX")
    T(parry, "Ability Parry", "abilityParry", "keyB")

    local lead = autoParry.new_sector("Lead")
    local autoEl = lead.element("Toggle", "Auto-lead", {
        default = { Toggle = (not boo(lala.customLeadMode, false)) and boo(lala.pingComp, false) },
    }, function(v)
        if v.Toggle then
            lala.pingComp = true
            lala.customLeadMode = false
        else
            lala.pingComp = false
        end
        saveUI()
    end)
    ELS.autolead = { el = autoEl }

    local custEl = lead.element("Toggle", "Custom-lead", {
        default = { Toggle = boo(lala.customLeadMode, false) },
    }, function(v)
        if v.Toggle then
            lala.customLeadMode = true
            lala.pingComp = false
        else
            lala.customLeadMode = false
        end
        saveUI()
    end)
    ELS.customlead = { el = custEl }
    do
        local kb = custEl:add_keybind()
        kb.toggleElement = false
        kb.value.Key = lala.keyL or nil
        kb.cb = function(v)
            lala.keyL = v.Key
            saveUI()
        end
    end

    S(lead, "Custom Lead Value", "customLeadValue", 5, 100, 100, 0.10)

    local curve = autoParry.new_sector("Anti-Curve")

    local autoC = curve.element("Toggle", "Auto Anti-Curve", {
        default = { Toggle = not boo(lala.customFacingMinMode, false) },
    }, function(v)
        lala.customFacingMinMode = not v.Toggle
        saveUI()
    end)
    ELS.autocurve = { el = autoC }

    local custC = curve.element("Toggle", "Custom Anti-Curve", {
        default = { Toggle = boo(lala.customFacingMinMode, false) },
    }, function(v)
        lala.customFacingMinMode = v.Toggle
        saveUI()
    end)
    ELS.customcurve = { el = custC }
    do
        local kb = custC:add_keybind()
        kb.toggleElement = false
        kb.value.Key = lala.keyN or nil
        kb.cb = function(v)
            lala.keyN = v.Key
            saveUI()
        end
    end

    S(curve, "Custom Anti-Curve Value", "customFacingMinValue", -100, 0, 100, -0.35)

    local accuracy = main.new_section("Parry Accuracy")
    local acc = accuracy.new_sector("Accuracy")
    S(acc, "Parry Accuracy", "accuracy", 1, 100, 1, 100)
    T(acc, "Randomize", "randomize", "keyR")
    S(acc, "Randomize Min", "randMin", 1, 99, 1, 20)
    S(acc, "Randomize Max", "randMax", 2, 100, 1, 100)
    T(acc, "Show Above Head", "accHead")

    local pset = main.new_section("Parry Settings")
    local psec = pset.new_sector("Distances")
    S(psec, "Minimum Distance", "minDist", 1, 100, 1, 16)
    S(psec, "Maximum Distance", "maxDist", 50, 2000, 1, 400)
    S(psec, "Panic Range", "panicBase", 5, 100, 1, 28)
    S(psec, "Panic Speed", "panicSpeedMul", 1, 200, 1000, 0.08)

    local apsec = main.new_section("Auto Play")
    local aps = apsec.new_sector("Automation")
    T(aps, "Autoplay", "autoplay", "keyG")
    T(aps, "Auto Walk", "apWalk")
    T(aps, "Auto Jump", "apJump")
    T(aps, "Auto Aim", "apAim")
end

do
    local vis = menu.new_tab("eye").new_section("Visuals")

    local ball = vis.new_sector("Ball Visuals")
    T(ball, "Ball Visuals", "bvExtras", "keyV")
    T(ball, "Ball Curve", "showVis")
    S(ball, "Trail Length", "bvLen", 20, 100, 1, 100)
    S(ball, "Trail Thickness", "bvThick", 1, 14, 1, 6)
    T(ball, "Distance Label", "bvDist")
    T(ball, "Speed Label", "bvSpeed")
    T(ball, "Target Line", "bvTarget")
    T(ball, "Mini Radar", "bvRadar")
    do
        local bvEl = ball.element("Toggle", "Trail Start", { default = { Toggle = false } }, function() end)
        local rd = bvEl.draw
        bvEl.draw = function()
            rd()
            bvEl.track.Visible = false
            bvEl.knob.Visible = false
        end
        local c0 = lala.bvColor or { r = 0, g = 255, b = 0 }
        local cl = bvEl:add_color({ Color = Color3.fromRGB(tonumber(c0.r) or 0, tonumber(c0.g) or 255, tonumber(c0.b) or 0) })
        cl.defC = Color3.fromRGB(0, 255, 0)
        cl.cb = function(v)
            lala.bvColor = { r = math.floor(v.Color.R * 255 + 0.5), g = math.floor(v.Color.G * 255 + 0.5), b = math.floor(v.Color.B * 255 + 0.5) }
            saveUI()
        end
    end
    do
       local bvEndEl = ball.element("Toggle", "Trail End", { default = { Toggle = false } }, function() end)
        local rd = bvEndEl.draw
        bvEndEl.draw = function()
            rd()
            bvEndEl.track.Visible = false
            bvEndEl.knob.Visible = false
        end
        local c1 = lala.bvEnd or { r = 255, g = 0, b = 0 }
        local cl = bvEndEl:add_color({ Color = Color3.fromRGB(tonumber(c1.r) or 255, tonumber(c1.g) or 0, tonumber(c1.b) or 0) })
        cl.defC = Color3.fromRGB(255, 0, 0)
        cl.cb = function(v)
            lala.bvEnd = { r = math.floor(v.Color.R * 255 + 0.5), g = math.floor(v.Color.G * 255 + 0.5), b = math.floor(v.Color.B * 255 + 0.5) }
            saveUI()
        end
    end

    local apv = vis.new_sector("Autoparry Visuals", "Right")
    if lala.parryDistInd == nil then lala.parryDistInd = true end
    local viewSel = "Off"
    if lala.viewEnabled ~= false then
        viewSel = lala.cone and "Cone" or "Circle"
    end
    local viewDD = apv.element("Dropdown", "View", {
        options = { "Off", "Circle", "Cone" },
        default = { Dropdown = viewSel },
    }, function(v)
        local sel = v.Dropdown
        if sel == "Off" then
            lala.viewEnabled = false
        elseif sel == "Circle" then
            lala.viewEnabled = true
            lala.cone = false
        else
            lala.viewEnabled = true
            lala.cone = true
        end
        saveUI()
    end)
    ELS.viewmode = { el = viewDD }
    T(apv, "Parry Distance Indicator", "parryDistInd")
    do
        local apLookEl = apv.element("Toggle", "AP Color", { default = { Toggle = false } }, function() end)
        do
            local rd = apLookEl.draw
            apLookEl.draw = function()
                rd()
                apLookEl.track.Visible = false
                apLookEl.knob.Visible = false
            end
        end
        local c0 = lala.apColor or { r = 0, g = 255, b = 120 }
        local cl = apLookEl:add_color({ Color = Color3.fromRGB(tonumber(c0.r) or 0, tonumber(c0.g) or 255, tonumber(c0.b) or 120) })
        cl.defC = Color3.fromRGB(0, 255, 120)
        cl.cb = function(v)
            lala.apColor = { r = math.floor(v.Color.R * 255 + 0.5), g = math.floor(v.Color.G * 255 + 0.5), b = math.floor(v.Color.B * 255 + 0.5) }
            saveUI()
        end
    end
    S(apv, "AP Thickness", "apThick", 1, 8, 1, 2)
    S(apv, "AP Transparency", "apTrans", 0, 100, 1, 5)
    do
        local pdLookEl = apv.element("Toggle", "Indicator Color", { default = { Toggle = false } }, function() end)
        do
            local rd = pdLookEl.draw
            pdLookEl.draw = function()
                rd()
                pdLookEl.track.Visible = false
                pdLookEl.knob.Visible = false
            end
        end
        local c1 = lala.pdColor or { r = 255, g = 0, b = 0 }
        local cl = pdLookEl:add_color({ Color = Color3.fromRGB(tonumber(c1.r) or 255, tonumber(c1.g) or 0, tonumber(c1.b) or 0) })
        cl.defC = Color3.fromRGB(255, 0, 0)
        cl.cb = function(v)
            lala.pdColor = { r = math.floor(v.Color.R * 255 + 0.5), g = math.floor(v.Color.G * 255 + 0.5), b = math.floor(v.Color.B * 255 + 0.5) }
            saveUI()
        end
    end
    S(apv, "Indicator Thickness", "pdThick", 1, 8, 1, 3)
    S(apv, "Indicator Transparency", "pdTrans", 0, 100, 1, 15)

    local esp = vis.new_sector("ESP", "Left")
    T(esp, "Ability ESP", "abilityEsp")
    T(esp, "Ability Upgrade ESP", "abilityUpgradeEsp")
end

do
    local cfg = menu.new_tab("gear").new_section("Settings")
    local gen = cfg.new_sector("General")

    local profSlot = "1"
    gen.element("Dropdown", "Config Slot", { options = _G.remybbProfiles and _G.remybbProfiles.slots or { "1" } }, function(v)
        profSlot = v.Dropdown
    end)
    gen.element("Button", "Save To Slot", {}, function()
        if _G.remybbProfiles and _G.remybbProfiles.save(profSlot) then
            pcall(_G.remybbSaveConfig)
            notify("gennegen", "saved to slot " .. profSlot, 2)
        end
    end)
    gen.element("Button", "Load Slot", {}, function()
        if _G.remybbProfiles and _G.remybbProfiles.load(profSlot) then
            task.delay(0.3, function()
                if library.fire_all then library:fire_all() end
                notify("gennegen", "loaded slot " .. profSlot, 2)
            end)
        else
            notify("gennegen", "slot " .. profSlot .. " is empty", 2)
        end
    end)

    local uiKeyEl = gen.element("Toggle", "UI Toggle Key", { default = { Toggle = false } }, function() end)
    do
        local rd = uiKeyEl.draw
        uiKeyEl.draw = function()
            rd()
            uiKeyEl.track.Visible = false
            uiKeyEl.knob.Visible = false
        end
    end
    do
        local kb = uiKeyEl:add_keybind()
        kb.toggleElement = false
        kb.value.Key = _G._genUIKey or 45
        kb.cb = function(v)
            _G._genUIKey = v.Key
            saveUI()
        end
    end

    local uiset = cfg.new_sector("UI Settings", "Right")
    local accEl = uiset.element("Toggle", "Accent Color", { default = { Toggle = false } }, function() end)
    do
        if library.set_alpha then library:set_alpha((tonumber(_G._genUITrans) or 100) / 100) end
        local trEl = uiset.element("Slider", "UI Transparency", {
            default = { min = 35, max = 100, default = math.max(35, tonumber(_G._genUITrans) or 100) },
        }, function(v)
            _G._genUITrans = v.Slider
            if library.set_alpha then library:set_alpha(v.Slider / 100) end
            saveUI()
        end)
    end
    do
        local hcEl = uiset.element("Toggle", "Hide User Card", { default = { Toggle = boo(_G._genHideCard, false) } }, function(v)
            _G._genHideCard = v.Toggle
            saveUI()
        end)
    end
    T(uiset, "Keybinds List", "keybindsHud")
    do
        local rd = accEl.draw
        accEl.draw = function()
            rd()
            accEl.track.Visible = false
            accEl.knob.Visible = false
        end
    end
    do
        local defC = Color3.fromRGB(84, 101, 255)
        if _G._genUIAccent then
            local h = _G._genUIAccent
            defC = Color3.fromRGB(tonumber(h:sub(1, 2), 16) or 84, tonumber(h:sub(3, 4), 16) or 101, tonumber(h:sub(5, 6), 16) or 255)
        end
        local cl = accEl:add_color({ Color = defC })
        cl.defC = Color3.fromRGB(84, 101, 255)
        cl.cb = function(v)
            if library.set_accent then library:set_accent(v.Color) end
            _G._genUIAccent = string.format("%02X%02X%02X", math.floor(v.Color.R * 255 + 0.5), math.floor(v.Color.G * 255 + 0.5), math.floor(v.Color.B * 255 + 0.5))
            saveUI()
        end
        if _G._genUIAccent and library.set_accent then library:set_accent(defC) end
    end

    uiset.element("Button", "Reset All Settings", {}, function()
        local d = _G.remybbDefaults
        if d then
            for k, v in pairs(d) do
                if type(v) == "table" then
                    local c = {}
                    for k2, v2 in pairs(v) do c[k2] = v2 end
                    lala[k] = c
                else
                    lala[k] = v
                end
            end
        end
        if library.reset_ui then library:reset_ui() end
        if library.set_all_toggles then library:set_all_toggles(false) end
        lala.customLeadMode = false
        lala.pingComp = true
        lala.customFacingMinMode = false
        lala.viewEnabled = false
        if _G.remybbSaveConfig then pcall(_G.remybbSaveConfig) end
        _G._genUIAccent = nil
        _G._genUIKey = nil
        uiKeyEl.kb.value.Key = 45
        saveUI()
        notify("gennegen", "all settings reset to defaults", 2)
    end)

    uiset.element("Button", "Unload Script", {}, function()
        notify("gennegen", "unloading script", 1)
        task.delay(0.4, function()
            _G.__apGen = (_G.__apGen or 0) + 1
            if _G.__apCleanup then pcall(_G.__apCleanup) end
            pcall(function()
                for _, k in ipairs({ 87, 65, 83, 68, 32 }) do keyrelease(k) end
            end)
            if _G._genToken and _G._genToken.unload then pcall(_G._genToken.unload) end
            _G.GenLib = nil
            _G.remybbMenu = nil
            _G.autoParry = nil
        end)
    end)
end

_G.remybbMenu = menu

local function leadForPing(pingMs)
    local tiers = lala.pingTiers or { 30, 50, 70, 120, 170 }
    local leads = lala.pingLead or { 0.34, 0.38, 0.44, 0.52, 0.58, 0.64 }
    for i = 1, #tiers do
        if pingMs <= tiers[i] then return leads[i] end
    end
    return leads[#leads]
end

task.spawn(function()
    while _G.__remyMenuGen == MENU_GEN and _G._genToken ~= nil do
        pcall(function()
        local snap = hs:JSONEncode(cfgData() or {})
        if snap ~= lastSnap then saveUI() end
        flushSave()
        for field, rec in pairs(ELS) do
            local e = rec.el
            if field == "autolead" then
                local on = (not boo(lala.customLeadMode, false)) and boo(lala.pingComp, false)
                if on ~= e.value.Toggle then e.value.Toggle = on end
                local label = "Auto-lead"
                if on then
                    local ping = 0
                    pcall(function() ping = GetPingValue() or 0 end)
                    label = label .. "  (" .. string.format("%.2f", leadForPing(ping)) .. "s)"
                end
                if e.text ~= label then e.text = label end
            elseif field == "customlead" then
                local on = boo(lala.customLeadMode, false)
                if on ~= e.value.Toggle then e.value.Toggle = on end
            elseif field == "autocurve" then
                local on = not boo(lala.customFacingMinMode, false)
                if on ~= e.value.Toggle then e.value.Toggle = on end
                local label = "Auto Anti-Curve"
                if on then
                    label = label .. "  (" .. string.format("%.2f", num(lala.facingMin, -0.35)) .. ")"
                end
                if e.text ~= label then e.text = label end
            elseif field == "customcurve" then
                local on = boo(lala.customFacingMinMode, false)
                if on ~= e.value.Toggle then e.value.Toggle = on end
            elseif field == "viewmode" then
                local sel
                if lala.viewEnabled == false then
                    sel = "Off"
                elseif lala.cone then
                    sel = "Cone"
                else
                    sel = "Circle"
                end
                if e.value.Dropdown ~= sel then e.value.Dropdown = sel end
            else
                local lv = lala[field]
                if e.kind == "Toggle" and type(lv) == "boolean" and lv ~= e.value.Toggle then
                    e.value.Toggle = lv
                elseif e.kind == "Slider" and type(lv) == "number" then
                    local scaled = math.floor(lv * (rec.scale or 1) + 0.5)
                    scaled = math.max(e.min, math.min(e.max, scaled))
                    if scaled ~= e.value.Slider then e.value.Slider = scaled end
                end
                if rec.keyField and e.kb and lala[rec.keyField] ~= e.kb.value.Key then
                    e.kb.value.Key = lala[rec.keyField]
                end
            end
        end
        end)
        task.wait(0.1)
    end
end)
