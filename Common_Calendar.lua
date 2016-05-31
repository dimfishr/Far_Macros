-------------------------------------------------------------------------------
-- Calendar by dimfish
-------------------------------------------------------------------------------

local CalendarKey = "CtrlShiftF11"

local Formats = {
    "%d.%m.%Y",
    "%d-%m-%Y",
    "%d/%m/%Y",
    "%m/%d/%Y",
    "%Y_%m_%d",
    "%Y-%m-%d",
    "%Y.%m.%d",
    "%d-%b-%y",
    "%d-%b-%Y",
}

local InfoFormats = {
    "[%U] [%j]",
    "[%V] [%j]",
    "[%W] [%j]",
}

local DayFormats = {
    " %2s ",
    "[%2s]",
    "{%2s}",
    "<%2s>",
    "‹%2s›",
    "-%2s-",
}

local CalendarColors = {
    Normal = 0x0,
    Weekend = 0x4,
    Disabled = 0x8,
    TextDate = 0xE,
    TextInfo = 0x0,
}

local VK = { Enter = 13; Left = 37; Up = 38; Right = 39; Down = 40; Ins = 45, C = 67, F1 = 112, F2 = 113, F3 = 114 }
local LeftOrRightCtrl = 0x0008 + 0x0004
local LeftOrRightAlt = 0x0001 + 0x0002
local LeftOrRightShift = 0x0010

local F = far.Flags
local FarSendDlgMessage = far.SendDlgMessage
local FarCopyToClipboard = far.CopyToClipboard
local FarColorDialog = far.ColorDialog
local FarShowHelp = far.ShowHelp
local FarDialog = far.Dialog
local FarMenu = far.Menu

local WinUuid = win.Uuid
local WinGetEnv = win.GetEnv
local WinGetFileAttr = win.GetFileAttr

local mfmload = mf.mload
local mfmsave = mf.msave
local fmt = string.format
local band = bit.band
local bshr = bit.rshift
local tonumber = tonumber
local tostring = tostring
local pcall = pcall
local print = print
local dofile = dofile
local floor = math.floor
local sort = table.sort

local date = require("date")

local FarLang = WinGetEnv("FARLANG"):sub(1, 3)
local MacrosPath = (...):match("(.*)%.lua") .. "_"
local L = dofile(MacrosPath .. (WinGetFileAttr(MacrosPath .. FarLang .. ".lul") and FarLang or "Eng") .. ".lul")

local function mod(n, d) return n - d * floor(n / d) end

local function getFG(c) return band(c, 0x0F) end

local function getBG(c) return bshr(band(c, 0xF0), 4) end

local function LoadCalendarSettings() return mfmload("dimfish", "Calendar") end

local function SaveCalendarSettings(s) mfmsave("dimfish", "Calendar", s) end

local function CalendarHelp(a) FarShowHelp(MacrosPath .. (WinGetFileAttr(MacrosPath .. FarLang .. ".hlf") and FarLang or "Eng") .. ".hlf", a, F.FHELP_CUSTOMFILE) end

local function ParseDateFormat(format, text)
    local months = { ['jan'] = 1, ['feb'] = 2, ['mar'] = 3, ['apr'] = 4, ['may'] = 5, ['jun'] = 6, ['jul'] = 7, ['aug'] = 8, ['sep'] = 9, ['oct'] = 10, ['nov'] = 11, ['dec'] = 12, ['янв'] = 1, ['фев'] = 2, ['мар'] = 3, ['апр'] = 4, ['май'] = 5, ['мая'] = 5, ['июн'] = 6, ['июл'] = 7, ['авг'] = 8, ['сен'] = 9, ['окт'] = 10, ['ноя'] = 11, ['дек'] = 12, }
    local _, dp, mp, yp, arr, yy, mm, dd, isMonthText

    isMonthText = format:find("%%[hbB]")
    yp = format:find("%%[yY]")
    mp = format:find("%%[mhbB]")
    dp = format:find("%%d")

    if not yp or not mp or not dp then
        return nil
    end

    arr = { { pos = yp, sort = 1 }, { pos = mp, sort = 2 }, { pos = dp, sort = 3 } }
    sort(arr, function(a, b) return (a.pos < b.pos) end)

    format = format:gsub("${%a+}", "")
    format = format:gsub("%%[yYmd]", "(%%d+)"):gsub("%%[hbB]", "(%%a+)")
    format = format:gsub("%-", "%%-"):gsub("%.", "%%."):gsub("%/", "%%/")

    _, _, arr[1].val, arr[2].val, arr[3].val = text:lower():find(format)

    sort(arr, function(a, b) return (a.sort < b.sort) end)
    yy = arr[1].val
    mm = arr[2].val
    dd = arr[3].val

    if not yy or not mm or not dd then
        return nil
    end

    if (isMonthText) then
        mm = months[mm:sub(1, 3)]
        if not mm then
            return nil
        end
    end

    if yy:len() == 2 then
        yy = (tonumber(yy) > 40 and 19 or 20) .. yy
    end

    local ok, dateObj = pcall(date, tonumber(yy), tonumber(mm), tonumber(dd))
    return ok and dateObj or nil
end

local function ParseDate(format, text)
    if not format or not text then
        return nil
    end

    local ok
    local dateObj = ParseDateFormat(tostring(format), text)
    if not dateObj then
        ok, dateObj = pcall(date, text)
        dateObj = ok and dateObj or nil
    end
    return dateObj
end

local function addmonthsFix(dateObj, m)
    local d = dateObj:getday()
    dateObj:addmonths(m)
    local dd = dateObj:getday()
    if dd ~= d then
        dateObj:adddays(-dd)
    end
end

local function setmonthFix(dateObj, m)
    local d = dateObj:getday()
    dateObj:setmonth(m)
    local dd = dateObj:getday()
    if dd ~= d then
        dateObj:adddays(-dd)
    end
end



local function ExecCalendar()
    local dt = date()
    local today = date()
    local isRendering = false
    local tableSelected
    local Text

    local I = {}
    local ID = {}
    local CF = {}
    local CB = {}
    local ComboMonths = {} for i = 1, 12 do ComboMonths[i] = { Text = L.Months[i] } end

    local Settings = LoadCalendarSettings() or { Format = Formats[1], Info = InfoFormats[1] }

    Settings.Today = Settings.Today or 0x87
    Settings.Selected = Settings.Selected or 0x3E
    Settings.SelectedToday = Settings.SelectedToday or 0x3E
    Settings.TodayWeekend = Settings.TodayWeekend or 0x84
    Settings.SelectedWeekend = Settings.SelectedWeekend or 0x3E
    Settings.SelectedTodayWeekend = Settings.SelectedTodayWeekend or 0x3E
    Settings.FormatToday = Settings.FormatToday or DayFormats[1]
    Settings.FormatSelected = Settings.FormatSelected or DayFormats[1]
    Settings.FormatSelectedToday = Settings.FormatSelectedToday or DayFormats[1]

    I[#I + 1] = { F.DI_DOUBLEBOX, 3, 1, 32, 20, 0, 0, 0, 0, L.Title }
    ID.title = #I

    local row = 2
    I[#I + 1] = { F.DI_BUTTON, 7, row, 0, row, 0, 0, 0, F.DIF_BTNNOCLOSE + F.DIF_NOBRACKETS, "Ctrl←" }
    ID.yearDec = #I
    I[#I + 1] = { F.DI_TEXT, 5, row + 1, 0, row + 1, 0, 0, 0, 0, L.Year }
    I[#I + 1] = { F.DI_FIXEDIT, 7, row + 1, 11, row + 1, 0, 0, "9999", F.DIF_MASKEDIT, "" }
    ID.year = #I
    I[#I + 1] = { F.DI_BUTTON, 7, row + 2, 0, row + 2, 0, 0, 0, F.DIF_BTNNOCLOSE + F.DIF_NOBRACKETS, "Ctrl→" }
    ID.yearInc = #I
    I[#I + 1] = { F.DI_BUTTON, 15, row, 0, row, 0, 0, 0, F.DIF_BTNNOCLOSE + F.DIF_NOBRACKETS, "Ctrl↑" }
    ID.monthDec = #I
    I[#I + 1] = { F.DI_TEXT, 13, row + 1, 0, row + 1, 0, 0, 0, 0, L.Month }
    -- FAR has Polish localization; Polish has “październik” (11 chars). Note: e.g. Moroccan Arabic has a 15-char month name
    I[#I + 1] = { F.DI_COMBOBOX, 15, row + 1, 22, row + 1, ComboMonths, 0, 0, F.DIF_DROPDOWNLIST + F.DIF_LISTNOAMPERSAND + F.DIF_LISTAUTOHIGHLIGHT, "" }
    ID.month = #I
    I[#I + 1] = { F.DI_BUTTON, 15, row + 2, 0, row + 2, 0, 0, 0, F.DIF_BTNNOCLOSE + F.DIF_NOBRACKETS, "Ctrl↓" }
    ID.monthInc = #I
    I[#I + 1] = { F.DI_RADIOBUTTON, 25, row, 0, row, Settings.FirstSunday and 0 or 1, 0, 0, 0, L.Mon }
    ID.firstMo = #I
    I[#I + 1] = { F.DI_RADIOBUTTON, 25, row + 1, 0, row + 1, Settings.FirstSunday and 1 or 0, 0, 0, 0, L.Sun }
    ID.firstSu = #I

    I[#I + 1] = { F.DI_TEXT, 20, row + 3, 30, row + 3, 0, 0, 0, F.DIF_RIGHTTEXT, L.Select }

    row = 6
    for d = 1, 7 do
        I[#I + 1] = { F.DI_TEXT, d * 4 + 1, row, 0, row, 0, 0, 0, 0, "" }
    end
    ID.table = #I
    for w = 0, 5 do
        for d = 1, 7 do
            I[#I + 1] = { F.DI_TEXT, d * 4, row + 1 + w, 0, row + 1 + w, 0, 0, 0, 0, "" }
        end
    end
    I[#I + 1] = { F.DI_USERCONTROL, 4, row + 1, 31, row + 6, 0, 0, 0, F.DIF_FOCUS }
    ID.userControl = #I

    row = 14
    I[#I + 1] = { F.DI_TEXT, 5, row, 0, row, 0, 0, 0, 0, L.DateFormat }
    I[#I + 1] = { F.DI_EDIT, 7, row, 15, row, 0, "Format", 0, F.DIF_HISTORY, Settings.Format }
    ID.format = #I
    I[#I + 1] = { F.DI_TEXT, 18, row, 0, row, 0, 0, 0, 0, L.Info }
    I[#I + 1] = { F.DI_EDIT, 20, row, 29, row, 0, "Info", 0, F.DIF_HISTORY, Settings.Info }
    ID.info = #I
    I[#I + 1] = { F.DI_BUTTON, 7, row + 1, 0, row + 1, 0, 0, 0, F.DIF_BTNNOCLOSE + F.DIF_NOBRACKETS, L.Help }
    ID.help = #I
    I[#I + 1] = { F.DI_TEXT, 5, row + 2, 0, row + 2, 0, 0, 0, 0, L.FormattedDate }
    I[#I + 1] = { F.DI_EDIT, 7, row + 2, 18, row + 2, 0, 0, 0, F.DIF_SELECTONENTRY, "" }
    ID.textDate = #I
    I[#I + 1] = { F.DI_TEXT, 20, row + 2, 29, row + 2, 0, 0, 0, 0, "" }
    ID.textInfo = #I
    I[#I + 1] = { F.DI_BUTTON, 7, row + 3, 17, row + 3, 0, 0, 0, F.DIF_BTNNOCLOSE, L.Refresh }
    ID.parse = #I
    I[#I + 1] = { F.DI_BUTTON, 20, row + 3, 29, row + 3, 0, 0, 0, F.DIF_BTNNOCLOSE, L.Today }
    ID.today = #I
    I[#I + 1] = { F.DI_TEXT, 0, row + 4, 0, row + 4, 0, 0, 0, F.DIF_SEPARATOR, "" }
    I[#I + 1] = { F.DI_BUTTON, 0, row + 5, 0, row + 5, 0, 0, 0, F.DIF_CENTERGROUP + F.DIF_DEFAULTBUTTON, L.Insert }
    ID.insert = #I
    I[#I + 1] = { F.DI_BUTTON, 0, row + 5, 0, row + 5, 0, 0, 0, F.DIF_CENTERGROUP, L.Copy }
    ID.copyDate = #I

    CF[ID.firstSu] = CalendarColors.Weekend
    CF[ID.textDate] = CalendarColors.TextDate
    CF[ID.textInfo] = CalendarColors.TextInfo

    CF[ID.yearInc] = CalendarColors.Disabled
    CF[ID.yearDec] = CalendarColors.Disabled
    CF[ID.monthInc] = CalendarColors.Disabled
    CF[ID.monthDec] = CalendarColors.Disabled
    CF[ID.help] = CalendarColors.Disabled

    local function GetDateText(hDlg)
        return FarSendDlgMessage(hDlg, "DM_GETTEXT", ID.textDate, 0)
    end

    local function UpdateControlsState(hDlg)
        FarSendDlgMessage(hDlg, "DM_ENABLE", ID.parse, ParseDate(Settings.Format, GetDateText(hDlg)) and 1 or 0)
    end

    local function Redraw(hDlg)
        isRendering = true
        FarSendDlgMessage(hDlg, "DM_ENABLEREDRAW", 0)
        FarSendDlgMessage(hDlg, "DM_SETTEXT", ID.year, dt:fmt("%Y"))
        FarSendDlgMessage(hDlg, "DM_LISTSETCURPOS", ID.month, { SelectPos = dt:getmonth() })

        local day = date(dt:getyear(), dt:getmonth(), 1)
        if Settings.FirstSunday then
            day:adddays(-(day:getweekday() == 1 and 7 or day:getweekday() - 1))
        else
            day:adddays(-(day:getisoweekday() == 1 and 7 or day:getisoweekday() - 1))
        end

        for d = 1, 7 do
            local id = ID.table - 7 + (Settings.FirstSunday and mod(d, 7) + 1 or d)
            FarSendDlgMessage(hDlg, "DM_SETTEXT", id, L.DaysOfWeek[d])
            CF[id] = d > 5 and CalendarColors.Weekend or nil
        end

        for w = 0, 5 do
            for d = 1, 7 do
                local currentId = w * 7 + d
                local id = ID.table + currentId

                local dayFormat = DayFormats[1]
                CB[id] = nil

                local dayDisabled = day:getmonth() ~= dt:getmonth()
                local daySelected = day:getmonth() == dt:getmonth() and day:getday() == dt:getday()
                local dayIsToday = day:getyear() == today:getyear() and day:getmonth() == today:getmonth() and day:getday() == today:getday()
                local dayIsWeekend = ((Settings.FirstSunday and mod(d - 2, 7) + 1 or d)) > 5

                tableSelected = daySelected and currentId or tableSelected

                if dayDisabled then
                    CF[id] = CalendarColors.Disabled
                elseif daySelected and dayIsToday then
                    CB[id] = getBG(dayIsWeekend and Settings.SelectedTodayWeekend or Settings.SelectedToday)
                    CF[id] = getFG(dayIsWeekend and Settings.SelectedTodayWeekend or Settings.SelectedToday)
                    dayFormat = Settings.FormatSelectedToday
                elseif daySelected then
                    CB[id] = getBG(dayIsWeekend and Settings.SelectedWeekend or Settings.Selected)
                    CF[id] = getFG(dayIsWeekend and Settings.SelectedWeekend or Settings.Selected)
                    dayFormat = Settings.FormatSelected
                elseif dayIsToday then
                    CB[id] = getBG(dayIsWeekend and Settings.TodayWeekend or Settings.Today)
                    CF[id] = getFG(dayIsWeekend and Settings.TodayWeekend or Settings.Today)
                    dayFormat = Settings.FormatToday
                elseif dayIsWeekend then
                    CF[id] = CalendarColors.Weekend
                else
                    CF[id] = CalendarColors.Normal
                end

                FarSendDlgMessage(hDlg, "DM_ENABLE", id, dayDisabled and 0 or 1)
                FarSendDlgMessage(hDlg, "DM_SETTEXT", id, fmt(dayFormat, day:getday()))
                day:adddays(1)
            end
        end

        FarSendDlgMessage(hDlg, "DM_SETTEXT", ID.title, dt:fmt(Settings.Format))
        FarSendDlgMessage(hDlg, "DM_SETTEXT", ID.textDate, dt:fmt(Settings.Format))
        FarSendDlgMessage(hDlg, "DM_SETTEXT", ID.textInfo, dt:fmt(Settings.Info))

        UpdateControlsState(hDlg)
        FarSendDlgMessage(hDlg, "DM_ENABLEREDRAW", 1)
        isRendering = false
    end

    local function GetItemColor(hDlg, Param1, Color)
        local _ = hDlg -- suppress the "unused argument" warning
        if CF[Param1] then
            Color[1].ForegroundColor = CF[Param1]
        end
        if CB[Param1] then
            Color[1].BackgroundColor = CB[Param1]
        end
        if Param1 == ID.month or Param1 == ID.format or Param1 == ID.info or Param1 == ID.textDate then
            Color[3] = Color[1]
        end
        return Color
    end

    -- Not all formats are supported, see https://tieske.github.io/date/
    local function SetDate(hDlg)
        local dateObj = ParseDate(Settings.Format, GetDateText(hDlg))
        if dateObj then
            dt = dateObj
            return true
        end
        return false
    end

    local function getDelta(Mouse)
        return floor(Mouse.MousePositionX / 4) + Mouse.MousePositionY * 7 + 1 - tableSelected
    end

    local function ColorSettings(name)
        local color = FarColorDialog(Settings[name], F.FCF_FG_4BIT + F.FCF_BG_4BIT)
        if color then
            Settings[name] = color
            SaveCalendarSettings(Settings)
        end
    end

    local function MenuSettings(name)
        local props = {
            Title = L.Format,
        }
        local items = {}
        for i = 1, #DayFormats do
            items[i] = {
                text = DayFormats[i],
                selected = Settings[name] == DayFormats[i]
            }
        end

        local result = FarMenu(props, items, nil)
        if result then
            Settings[name] = result.text
            SaveCalendarSettings(Settings)
        end
    end

    local function DlgProc(hDlg, Msg, Param1, Param2)
        if Msg == F.DN_CTLCOLORDLGITEM then
            return GetItemColor(hDlg, Param1, Param2)
        elseif isRendering then
            return
        elseif Msg == F.DN_INITDIALOG then
            for i = 1, #Formats do
                FarSendDlgMessage(hDlg, "DM_ADDHISTORY", ID.format, Formats[i], i)
            end
            FarSendDlgMessage(hDlg, "DM_ADDHISTORY", ID.format, Settings.Format, 1)

            for i = 1, #InfoFormats do
                FarSendDlgMessage(hDlg, "DM_ADDHISTORY", ID.info, InfoFormats[i], i)
            end
            FarSendDlgMessage(hDlg, "DM_ADDHISTORY", ID.info, Settings.Info, 1)
            Redraw(hDlg)
        elseif Msg == F.DN_HELP or (Msg == F.DN_BTNCLICK and Param1 == ID.help) then
            local topic = (Param1 == ID.format or Param1 == ID.info) and "formats" or nil
            CalendarHelp(topic)
        elseif Param1 == ID.insert then
            Text = GetDateText(hDlg)
        elseif Param1 == -1 then
            Text = nil
        elseif Msg == F.DN_EDITCHANGE then
            if Param1 == ID.year then
                local selY = tonumber(FarSendDlgMessage(hDlg, "DM_GETTEXT", Param1, 0))
                if selY ~= dt:getyear() then
                    dt:setyear(selY)
                    Redraw(hDlg)
                end
            elseif Param1 == ID.month then
                local selM = (FarSendDlgMessage(hDlg, "DM_LISTGETCURPOS", Param1, 0)).SelectPos
                if selM ~= dt:getmonth() then
                    setmonthFix(dt, selM)
                    Redraw(hDlg)
                end
            elseif Param1 == ID.format then
                Settings.Format = FarSendDlgMessage(hDlg, "DM_GETTEXT", Param1, 0)
                SaveCalendarSettings(Settings)
                Redraw(hDlg)
            elseif Param1 == ID.info then
                Settings.Info = FarSendDlgMessage(hDlg, "DM_GETTEXT", Param1, 0)
                SaveCalendarSettings(Settings)
                Redraw(hDlg)
            elseif Param1 == ID.textDate then
                UpdateControlsState(hDlg)
            end
        elseif Msg == F.DN_BTNCLICK then
            if Param1 == ID.yearDec then
                dt:addyears(-1)
            elseif Param1 == ID.yearInc then
                dt:addyears(1)
            elseif Param1 == ID.monthDec then
                addmonthsFix(dt, -1)
            elseif Param1 == ID.monthInc then
                addmonthsFix(dt, 1)
            elseif Param1 == ID.parse then
                SetDate(hDlg)
                FarSendDlgMessage(hDlg, "DM_SETFOCUS", ID.userControl, 0)
            elseif Param1 == ID.today then
                dt = date()
                FarSendDlgMessage(hDlg, "DM_SETFOCUS", ID.userControl, 0)
            elseif Param1 == ID.copyDate then
                FarCopyToClipboard(GetDateText(hDlg))
                Text = nil
            elseif Param1 == ID.firstSu or Param1 == ID.firstMo then
                Settings.FirstSunday = FarSendDlgMessage(hDlg, "DM_GETCHECK", ID.firstSu, 0) == 1 and true or false
                SaveCalendarSettings(Settings)
            else
                return
            end
            Redraw(hDlg)
        elseif Msg == F.DN_CONTROLINPUT then
            if Param2.ControlKeyState and
                    band(Param2.ControlKeyState, LeftOrRightCtrl) ~= 0 and
                    band(Param2.ControlKeyState, LeftOrRightAlt) == 0 then
                local week = band(Param2.ControlKeyState, LeftOrRightShift) ~= 0 and "Weekend" or ""
                local arrowsAllowed = Param1 ~= ID.month and Param1 ~= ID.format and Param1 ~= ID.info

                if arrowsAllowed and Param2.VirtualKeyCode == VK.Left then
                    dt:addyears(-1)
                elseif arrowsAllowed and Param2.VirtualKeyCode == VK.Up then
                    addmonthsFix(dt, -1)
                elseif arrowsAllowed and Param2.VirtualKeyCode == VK.Right then
                    dt:addyears(1)
                elseif arrowsAllowed and Param2.VirtualKeyCode == VK.Down then
                    addmonthsFix(dt, 1)
                elseif Param1 ~= ID.textDate and Param2.VirtualKeyCode == VK.Ins or Param2.VirtualKeyCode == VK.C then
                    FarCopyToClipboard(GetDateText(hDlg))
                    return true
                elseif Param2.VirtualKeyCode == VK.F1 then
                    ColorSettings("SelectedToday" .. week)
                elseif Param2.VirtualKeyCode == VK.F2 then
                    ColorSettings("Selected" .. week)
                elseif Param2.VirtualKeyCode == VK.F3 then
                    ColorSettings("Today" .. week)
                elseif Param1 == ID.userControl and Param2.ButtonState == 1 then
                    local delta = getDelta(Param2)
                    local isToday = dt:getyear() == today:getyear() and dt:getmonth() == today:getmonth() and dt:getday() + delta == today:getday()
                    if delta == 0 and isToday then
                        ColorSettings("SelectedToday" .. week)
                    elseif delta == 0 then
                        ColorSettings("Selected" .. week)
                    elseif isToday then
                        ColorSettings("Today" .. week)
                    else
                        return
                    end
                else
                    return
                end
                Redraw(hDlg)
                return true
            elseif Param2.ControlKeyState and
                    band(Param2.ControlKeyState, LeftOrRightCtrl) ~= 0 and
                    band(Param2.ControlKeyState, LeftOrRightAlt) ~= 0 then
                if Param2.VirtualKeyCode == VK.F1 then
                    MenuSettings("FormatSelectedToday")
                elseif Param2.VirtualKeyCode == VK.F2 then
                    MenuSettings("FormatSelected")
                elseif Param2.VirtualKeyCode == VK.F3 then
                    MenuSettings("FormatToday")
                elseif Param1 == ID.userControl and Param2.ButtonState == 1 then
                    local delta = getDelta(Param2)
                    local isToday = dt:getyear() == today:getyear() and dt:getmonth() == today:getmonth() and dt:getday() + delta == today:getday()
                    if delta == 0 and isToday then
                        MenuSettings("FormatSelectedToday")
                    elseif delta == 0 then
                        MenuSettings("FormatSelected")
                    elseif isToday then
                        MenuSettings("FormatToday")
                    else
                        return
                    end
                else
                    return
                end
                Redraw(hDlg)
                return true
            elseif Param1 == ID.userControl then
                if Param2.VirtualKeyCode == VK.Left then
                    dt:adddays(-1)
                elseif Param2.VirtualKeyCode == VK.Up then
                    dt:adddays(-7)
                elseif Param2.VirtualKeyCode == VK.Right then
                    dt:adddays(1)
                elseif Param2.VirtualKeyCode == VK.Down then
                    dt:adddays(7)
                elseif Param2.ButtonState == 1 then
                    dt:adddays(getDelta(Param2))
                else
                    return
                end
                Redraw(hDlg)
                return true
            elseif Param1 == ID.textDate and Param2.VirtualKeyCode == VK.Enter then
                if SetDate(hDlg) then
                    Redraw(hDlg)
                end
                return true
            end
        end
    end

    local guid = WinUuid("06a13b89-3fec-46a2-be11-a50b68ceaa56")
    FarDialog(guid, -1, -1, 36, 22, nil, I, nil, DlgProc)
    if Text then print(Text) end
end

Macro {
    area = "Common"; key = CalendarKey; description = L.Title; flags = "";
    action = ExecCalendar;
}
