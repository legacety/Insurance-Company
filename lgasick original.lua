script_name("igasick")
script_author("legacy.")

local fa = require 'fAwesome6_solid'
local imgui = require 'mimgui'
local encoding = require 'encoding'
local acef = require 'arizona-events'
local sampev = require 'samp.events'
script_properties 'work-in-pause'

encoding.default = 'CP1251'
local u8 = encoding.UTF8

local renderWindow = imgui.new.bool(false)
local activeTab = 1

local Clicker = imgui.new.bool(false)
local Konvert = imgui.new.bool(false)
local Office = imgui.new.bool(false)
local TextDraw = imgui.new.bool(false)
local NotifyChat = imgui.new.bool(false)
local NotifyCef = imgui.new.bool(false)
local Notify = imgui.new.bool(false)
local td = {94, 95, 96, 97}
local TdClickDelay = imgui.new.int(300)
local Players = {}
local stats = {}

local zones = {
    { x = 1446.81, y = 1922.35, z = 2006.45, r = 2.5 },
    { x = 1446.81, y = 1924.02, z = 2006.45, r = 2.5 },
    { x = 1446.81, y = 1924.02, z = 2006.45, r = 2.5 },
    { x = 1446.82, y = 1927.50, z = 2006.45, r = 2.5 },
    { x = 1446.82, y = 1927.50, z = 2006.45, r = 2.5 }
}

local tabs = { 
    {name = u8"Главная", icon = fa.HOUSE}, 
    {name = u8"Функции СК", icon = fa.SCREWDRIVER_WRENCH}, 
    {name = u8"Заработок с СК", icon = fa.CIRCLE_DOLLAR_TO_SLOT} 
}

local cfg_path = getWorkingDirectory() .. "\\config\\igasick.cfg"
local function loadConfig()
    local f = io.open(cfg_path, "r")
    if not f then return end
    local section = nil
    for line in f:lines() do
        line = line:match("^%s*(.-)%s*$")
        if line ~= "" and not line:match("^;") then
            if line:match("^%[.-%]") then
                section = line:match("^%[(.-)%]$")
            else
                local k, v = line:match("(.+)=(.+)")
                if k and v then
                    if section == "settings" then
                        if k == "Clicker" then Clicker[0] = v == "true" end
                        if k == "Konvert" then Konvert[0] = v == "true" end
                        if k == "Office" then Office[0] = v == "true" end
                        if k == "TextDraw" then TextDraw[0] = v == "true" end
                        if k == "TdClickDelay" then TdClickDelay[0] = tonumber(v) or TdClickDelay[0] end
                        if k == "Notify" then Notify[0] = v == "true" end
                        if k == "NotifyChat" then NotifyChat[0] = v == "true" end
                        if k == "NotifyCef" then NotifyCef[0] = v == "true" end
                    elseif section == "salary" then
                        stats[k] = tonumber(v)
                    end
                end
            end
        end
    end
    f:close()
end

local function saveConfig()
    local f = io.open(cfg_path, "w+")
    if not f then return end
    f:write("[settings]\n\n")
    f:write("Clicker=" .. tostring(Clicker[0]) .. "\n")
    f:write("Konvert=" .. tostring(Konvert[0]) .. "\n")
    f:write("Office=" .. tostring(Office[0]) .. "\n")
    f:write("TextDraw=" .. tostring(TextDraw[0]) .. "\n")
    f:write("TdClickDelay=" .. TdClickDelay[0] .. "\n")
    f:write("Notify=" .. tostring(Notify[0]) .. "\n")
    f:write("NotifyChat=" .. tostring(NotifyChat[0]) .. "\n")
    f:write("NotifyCef=" .. tostring(NotifyCef[0]) .. "\n")
    f:write("\n[salary]\n\n")
    for date, money in pairs(stats) do
        f:write(date .. "=" .. money .. "\n")
    end
    f:close()
end

function imgui.CenterText(text)
    local colWidth = imgui.GetColumnWidth()
    local colHeight = imgui.GetContentRegionAvail().y
    local textSize = imgui.CalcTextSize(text)
    imgui.SetCursorPosX(imgui.GetCursorPosX() + (colWidth - textSize.x) * 0.5)
    imgui.Text(text)
end

local function applyTheme()
    local bg = imgui.ImVec4(0.06, 0.08, 0.10, 1)
    local childBg = imgui.ImVec4(0.07, 0.09, 0.11, 1)
    local button = imgui.ImVec4(0.12, 0.16, 0.20, 1)
    local buttonHover = imgui.ImVec4(0.18, 0.22, 0.26, 1)
    local frame = imgui.ImVec4(0.10, 0.14, 0.18, 1)
    local text = imgui.ImVec4(0.85, 0.86, 0.88, 1)
    local style = imgui.GetStyle()
    local clr = style.Colors
    style.WindowRounding = 0
    style.ChildRounding = 4
    style.FrameRounding = 4
    style.ScrollbarRounding = 0
    style.ItemSpacing = imgui.ImVec2(10, 12)
style.WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
    style.ScrollbarSize = 13
    clr[imgui.Col.Text] = text
    clr[imgui.Col.WindowBg] = bg
    clr[imgui.Col.ChildBg] = childBg
    clr[imgui.Col.TitleBg] = bg
    clr[imgui.Col.TitleBgActive] = bg
    clr[imgui.Col.Button] = button
    clr[imgui.Col.ButtonHovered] = buttonHover
    clr[imgui.Col.ButtonActive] = buttonHover
    clr[imgui.Col.FrameBg] = frame
    clr[imgui.Col.Separator] = imgui.ImVec4(0.15, 0.18, 0.21, 1)
end

imgui.OnInitialize(function()
    imgui.GetIO().IniFilename = nil
    applyTheme()
    fa.Init(13)
end)

imgui.OnFrame(function() return renderWindow[0] end, function()
    imgui.SetNextWindowSize(imgui.ImVec2(550, 450), imgui.Cond.FirstUseEver)
    local sw, sh = getScreenResolution()
    imgui.SetNextWindowPos(imgui.ImVec2(sw * 0.5, sh * 0.5), imgui.Cond.Appearing, imgui.ImVec2(0.5, 0.5))
    if imgui.Begin(u8"SetVc Tools", renderWindow, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse) then
        imgui.BeginChild("LeftMenu", imgui.ImVec2(150, -1), true)
        for i, tab in ipairs(tabs) do
            if imgui.Button(tab.icon .. "  " .. tab.name, imgui.ImVec2(-1, 35)) then
                activeTab = i
            end
        end
        imgui.EndChild()
        imgui.SameLine()
        imgui.BeginChild("MainContent", imgui.ImVec2(-1, -1), true)

        if activeTab == 1 then
            imgui.TextColored(imgui.ImVec4(0.35, 0.75, 1.0, 1.0), fa.HOUSE .. u8" Информация о скрипте")
            imgui.Separator()

            imgui.BeginChild("InfoBlock", imgui.ImVec2(0, 0), true)
            imgui.TextColored(imgui.ImVec4(1, 1, 1, 1), fa["INFO"] .. u8" Общие сведения")
            imgui.Separator()
            imgui.Dummy(imgui.ImVec2(0, 5))
            
            imgui.Text(u8"Название: SetVc Tools")
            imgui.Text(u8"Автор: legacy")
            imgui.Text(u8"Версия: 4.0")
            imgui.Text(u8"Назначение: Автоматизация работы в СК")

            imgui.Dummy(imgui.ImVec2(0, 15))
            imgui.TextColored(imgui.ImVec4(1, 1, 1, 1), fa.CIRCLE_CHECK .. u8" Возможности")
            imgui.Separator()
            imgui.Dummy(imgui.ImVec2(0, 5))

            imgui.BulletText(u8"Автокликер в 1 кабинете")
            imgui.BulletText(u8"Автопрохождение документов во 2 кабинете")
            imgui.BulletText(u8"Автоклик по TextDraw в 3 кабинете")
            imgui.BulletText(u8"Автозаполнение диалогов в 3 кабинете")
            imgui.BulletText(u8"Уведомления о игроках возле зон СК")
            imgui.BulletText(u8"Cтатистика заработка в СК")

            imgui.Dummy(imgui.ImVec2(0, 20))
            imgui.Separator() 
            imgui.CenterText(fa.CIRCLE_CHECK .. u8" Скрипт готов к работе")

        elseif activeTab == 2 then
            imgui.TextColored(imgui.ImVec4(0.4, 0.8, 1, 1), fa.SCREWDRIVER_WRENCH .. u8" Функции")
            imgui.Separator()
            if imgui.Checkbox(u8"Включить кликер", Clicker) then saveConfig() end
            if imgui.Checkbox(u8"Включить конвертер", Konvert) then saveConfig() end
            if imgui.Checkbox(u8"Автозаполнение документов", Office) then saveConfig() end
            if imgui.Checkbox(u8"Клик по текстдрайвам", TextDraw) then saveConfig() end

            if TextDraw[0] then
                imgui.Separator()
                if imgui.SliderInt(u8"Задержка TD (мс)", TdClickDelay, 1, 500) then saveConfig() end
            end

            imgui.Text(u8"Уведомления о игроках:")
            if imgui.Checkbox(u8"Включить уведомления", Notify) then saveConfig() end
            if Notify[0] then
                imgui.Separator()
                if imgui.Checkbox(u8"Уведомления в чат", NotifyChat) then saveConfig() end
                if imgui.Checkbox(u8"Уведомления в CEF", NotifyCef) then saveConfig() end
            end

        elseif activeTab == 3 then
            imgui.TextColored(imgui.ImVec4(0.4, 0.8, 1, 1), fa.CIRCLE_DOLLAR_TO_SLOT .. u8" Заработок")
            imgui.Separator()
            local totalSelary = 0
             for _, money in pairs(stats) do
                totalSelary = totalSelary + money
            end
            imgui.TextColored(imgui.ImVec4(0, 1, 0, 1),u8"Общий заработок: $ " .. tostring(totalSelary):reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,",""))
            if imgui.Button(u8"Очистить историю", imgui.ImVec2(-1, 20)) then stats = {} saveConfig() end
            imgui.BeginChild("Table", imgui.ImVec2(0, -1), true)
            imgui.SetCursorPos(imgui.ImVec2(0, 0))
            imgui.Columns(2, "IncomeCols", true)
            imgui.Dummy(imgui.ImVec2(0, 1))
            imgui.CenterText(u8"День")
            imgui.NextColumn()
            imgui.Dummy(imgui.ImVec2(0, 1))
            imgui.CenterText(u8"Заработок")
            imgui.NextColumn()
            imgui.Separator()

            local sorted = {}
            for k in pairs(stats) do table.insert(sorted, k) end
            table.sort(sorted, function(a,b) return a > b end)
            for _, date in ipairs(sorted) do
            imgui.CenterText(date); imgui.NextColumn()
            imgui.CenterText("$ " .. tostring(stats[date]):reverse():gsub("(%d%d%d)","%1,"):reverse():gsub("^,","")); imgui.NextColumn()
            imgui.Separator()
            end

            imgui.Columns(1)
            imgui.EndChild()
            end

        imgui.EndChild()
        imgui.End()
    end
end)

function sampev.onServerMessage(color, text)
    local money_str = text:match("Ваша зарплата: %$([%d.,]+)")
    if money_str then
        money_str = money_str:gsub("[,%.]", "")
        local money = tonumber(money_str)
        if money then
            local date = os.date("%d.%m.%Y")
            stats[date] = (stats[date] or 0) + money
            saveConfig()
        end
    end
end


function sampev.onShowTextDraw(id)
    if not TextDraw[0] then return end
    for _, td_id in ipairs(td) do
        if id == td_id then
            lua_thread.create(function()
                for _, click_id in ipairs(td) do
                    wait(TdClickDelay[0])
                    sampSendClickTextdraw(click_id)
                end
            end)
            break
        end
    end
end

function sampev.onShowDialog(id, style, title, button1, button2, text)
    if not Office[0] then return end
    if title:find('{BFBBBA}Заполнение документа') then
        sampSendDialogResponse(id, 1, nil, text:match('{ffff00}(.+)'))
        return false
    end
end

function acef.onArizonaDisplay(packet)
    if Clicker[0] and packet.text:find("window.executeEvent%('event.clicker.setProgress', `%[%d+%]`%);") then
        lua_thread.create(function()
            for i = 1, 4 do
                acef.send("onArizonaSend", { server_id = 0, text = "clickMinigame" })
                wait(69)
            end
        end)
    end

    if Konvert[0] and packet.text:find([[window%.executeEvent%('event%.setActiveView', `%["FindGame"%]`%);]]) then
        for i = 1, 5 do
            acef.send("onArizonaSend", { server_id = 0, text = "findGame.Success" })
        end
        acef.send("onArizonaSend", { server_id = 0, text = "findGame.finish" })
        return false
    end
end

function main()
    while not isSampAvailable() do wait(0) end
    loadConfig()

    sampAddChatMessage("{00FFFF}[SetVc Tools] {FFFFFF}Загружен. Активация {00FFFF}/vc", -1)
    sampRegisterChatCommand("vc", function() renderWindow[0] = not renderWindow[0] end)

    while true do
        wait(250)
        for playerId = 0, 999 do
            if sampIsPlayerConnected(playerId) then
                local res, ped = sampGetCharHandleBySampPlayerId(playerId)
                if res and doesCharExist(ped) then
                    local px, py, pz = getCharCoordinates(ped)
                    for i, zone in ipairs(zones) do
                        if not Players[i] then Players[i] = {} end
                        local inzone = getDistanceBetweenCoords3d(px, py, pz, zone.x, zone.y, zone.z) <= zone.r
                        if inzone ~= (Players[i][playerId] or false) then
                            Players[i][playerId] = inzone
                            local nick = sampGetPlayerNickname(playerId)
                            if NotifyChat[0] then
                                sampAddChatMessage("{00FFFF}[Зоны] {FFFFFF}Игрок " .. nick .. (inzone and " подошел к " or " покинул ") .. "позиции №" .. i, -1)
                            end
                            if NotifyCef[0] then
                                lua_thread.create(function()
                                    acef.emul("onArizonaDisplay", { text = "window.executeEvent('cef.modals.showModal', `[\"dialogTip\",{\"position\":\"rightBottom\",\"backgroundImage\":\"bank_notify_add.webp\",\"icon\":\"icon-info\",\"iconColor\":\"#2ECC71\",\"highlightColor\":\"#5FC6FF\",\"text\":\"Игрок " .. nick .. " " .. (inzone and "подошел к" or "покинул") .. " позиции №" .. i .. "\"}]`);" })
                                    wait(3000)
                                    acef.emul("onArizonaDisplay", { text = "window.executeEvent('cef.modals.closeModal', `[\"dialogTip\"]`);" })
                                end)
                            end
                        end
                    end
                end
            end
        end
    end
end
