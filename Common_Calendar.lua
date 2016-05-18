-------------------------------------------------------------------------------
-- Calendar by dimfish
-------------------------------------------------------------------------------

local Key = "CtrlShiftF11"

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

local Info = {
    "[%U] [%j]",
    "[%V] [%j]",
    "[%W] [%j]",
}

local Colors = {
    Normal = 0x0,
    Weekend = 0x4,
    Today = 0x9,
    Selected = 0xE,
    Disabled = 0x8,
}

-- See http://www.omniglot.com/language/time/days.htm, http://www.omniglot.com/language/time/months.htm
local function Localization()
    if far.lang == "Russian" then
        return {
            Title = "Календарь";
            DaysOfWeek = { "Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс" }; Mon = "Пн"; Sun = "Вс";
            Months = { "&Январь", "&Февраль", "&Март", "&Апрель", "Ма&й", "И&юнь", "Ию&ль", "Ав&густ", "&Сентябрь", "&Октябрь", "&Ноябрь", "&Декабрь" };
            Year = '&Г:'; Month = '&М:'; DateFormat = '&Ф:'; Info = '&И:'; FormattedDate = '&Д:';
            Today = "&Сегодня"; Select = '&Выберите:'; Refresh = "&Обновить"; Insert = "Вставить"; Copy = "&Копировать";
        }
    else
        return {
            Title = "Calendar";
            DaysOfWeek = { "Mo", "Tu", "We", "Th", "Fr", "Sa", "Su" }; Mon = "M&o"; Sun = "S&u";
            Months = { "&January", "&February", "&March", "&April", "Ma&y", "Ju&ne", "Ju&ly", "Au&gust", "&September", "&October", "&November", "&December" };
            Year = '&Y:'; Month = '&M:'; DateFormat = '&F:'; Info = '&I:'; FormattedDate = '&D:';
            Today = "&Today"; Select = '&Select:'; Refresh = "&Refresh"; Insert = "Insert"; Copy = "&Copy";
        }
    end
end

local VK = { Enter = 13; Left = 37; Up = 38; Right = 39; Down = 40; Ins = 45, C = 67 }
local leftOrRightCtrl = 0x0008 + 0x0004
local leftOrRightAlt = 0x0001 + 0x0002

local F = far.Flags
local SendDlgMessage = far.SendDlgMessage
local fmt = string.format
local band = bit.band
local tonumber = tonumber
local tostring = tostring
local floor = math.floor
local sort = table.sort

local date = require("date")

local function mod(n, d) return n - d * floor(n / d) end

local function ParseDateFormat(format, text)
    local months = { jan = 1, feb = 2, mar = 3, apr = 4, may = 5, jun = 6, jul = 7, aug = 8, sep = 9, oct = 10, nov = 11, dec = 12 }
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

    format = format:gsub("%%[yYmd]", "(%%d+)"):gsub("%%[hbB]", "(%%a+)")
    format = format:gsub("%-", "%%-"):gsub("%.", "%%."):gsub("%/", "%%/")

    _, _, arr[1].val, arr[2].val, arr[3].val = string.find(text:lower(), format)

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
    local Settings = mf.mload("dimfish", "Calendar") or { Format = Formats[1], Info = Info[1] }
    local Text
    local today = date()
    local dt = date()
    local tableSelected
    local isRendering = false

    local ComboMonths = {} for i = 1, 12 do ComboMonths[i] = { Text = Localization().Months[i] } end

    local I = {}
    local ID = {}
    local CF = {}

    I[#I + 1] = { F.DI_DOUBLEBOX, 3, 1, 32, 19, 0, 0, 0, 0, Localization().Title }
    ID.title = #I
    I[#I + 1] = { F.DI_BUTTON, 7, 2, 0, 2, 0, 0, 0, F.DIF_BTNNOCLOSE + F.DIF_NOBRACKETS, "Ctrl←" }
    ID.yearDec = #I
    I[#I + 1] = { F.DI_TEXT, 5, 3, 0, 3, 0, 0, 0, 0, Localization().Year }
    I[#I + 1] = { F.DI_FIXEDIT, 7, 3, 11, 3, 0, 0, "9999", F.DIF_MASKEDIT, "" }
    ID.year = #I
    I[#I + 1] = { F.DI_BUTTON, 7, 4, 0, 4, 0, 0, 0, F.DIF_BTNNOCLOSE + F.DIF_NOBRACKETS, "Ctrl→" }
    ID.yearInc = #I
    I[#I + 1] = { F.DI_BUTTON, 15, 2, 0, 2, 0, 0, 0, F.DIF_BTNNOCLOSE + F.DIF_NOBRACKETS, "Ctrl↑" }
    ID.monthDec = #I
    I[#I + 1] = { F.DI_TEXT, 13, 3, 0, 3, 0, 0, 0, 0, Localization().Month }
    -- FAR has Polish localization; Polish has “październik” (11 chars). Note: e.g. Moroccan Arabic has a 15-char month name
    I[#I + 1] = { F.DI_COMBOBOX, 15, 3, 22, 3, ComboMonths, 0, 0, F.DIF_DROPDOWNLIST + F.DIF_LISTNOAMPERSAND + F.DIF_LISTAUTOHIGHLIGHT, "" }
    ID.month = #I
    I[#I + 1] = { F.DI_BUTTON, 15, 4, 0, 4, 0, 0, 0, F.DIF_BTNNOCLOSE + F.DIF_NOBRACKETS, "Ctrl↓" }
    ID.monthInc = #I
    I[#I + 1] = { F.DI_RADIOBUTTON, 25, 2, 0, 2, Settings.FirstSunday and 0 or 1, 0, 0, 0, Localization().Mon }
    ID.firstMo = #I
    I[#I + 1] = { F.DI_RADIOBUTTON, 25, 3, 0, 3, Settings.FirstSunday and 1 or 0, 0, 0, 0, Localization().Sun }
    ID.firstSu = #I

    I[#I + 1] = { F.DI_TEXT, 20, 4, 30, 4, 0, 0, 0, F.DIF_RIGHTTEXT, Localization().Select }
    local row = 5
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
    I[#I + 1] = { F.DI_TEXT, 5, 13, 0, 13, 0, 0, 0, 0, Localization().DateFormat }
    I[#I + 1] = { F.DI_EDIT, 7, 13, 15, 13, 0, "Format", 0, F.DIF_HISTORY, Settings.Format }
    ID.format = #I
    I[#I + 1] = { F.DI_TEXT, 18, 13, 0, 13, 0, 0, 0, 0, Localization().Info }
    I[#I + 1] = { F.DI_EDIT, 20, 13, 29, 13, 0, "Info", 0, F.DIF_HISTORY, Settings.Info }
    ID.info = #I
    I[#I + 1] = { F.DI_TEXT, 5, 15, 0, 15, 0, 0, 0, 0, Localization().FormattedDate }
    I[#I + 1] = { F.DI_EDIT, 7, 15, 18, 15, 0, 0, 0, F.DIF_SELECTONENTRY, "" }
    ID.textDate = #I
    I[#I + 1] = { F.DI_TEXT, 20, 15, 29, 15, 0, 0, 0, 0, "" }
    ID.textInfo = #I
    I[#I + 1] = { F.DI_BUTTON, 7, 16, 17, 16, 0, 0, 0, F.DIF_BTNNOCLOSE, Localization().Refresh }
    ID.parse = #I
    I[#I + 1] = { F.DI_BUTTON, 20, 16, 29, 16, 0, 0, 0, F.DIF_BTNNOCLOSE, Localization().Today }
    ID.today = #I
    I[#I + 1] = { F.DI_TEXT, 0, 17, 0, 16, 0, 0, 0, F.DIF_SEPARATOR, "" }
    I[#I + 1] = { F.DI_BUTTON, 0, 18, 0, 18, 0, 0, 0, F.DIF_CENTERGROUP + F.DIF_DEFAULTBUTTON, Localization().Insert }
    ID.insert = #I
    I[#I + 1] = { F.DI_BUTTON, 0, 18, 0, 18, 0, 0, 0, F.DIF_CENTERGROUP, Localization().Copy }
    ID.copyDate = #I

    CF[ID.yearInc] = Colors.Disabled
    CF[ID.yearDec] = Colors.Disabled
    CF[ID.monthInc] = Colors.Disabled
    CF[ID.monthDec] = Colors.Disabled
    CF[ID.textDate] = Colors.Selected
    CF[ID.firstSu] = Colors.Weekend

    local function GetDateText(hDlg)
        return SendDlgMessage(hDlg, "DM_GETTEXT", ID.textDate, 0)
    end

    local function UpdateControlsState(hDlg)
        SendDlgMessage(hDlg, "DM_ENABLE", ID.parse, ParseDate(Settings.Format, GetDateText(hDlg)) and 1 or 0)
    end

    local function Redraw(hDlg)
        isRendering = true
        SendDlgMessage(hDlg, "DM_ENABLEREDRAW", 0)
        SendDlgMessage(hDlg, "DM_SETTEXT", ID.year, dt:fmt("%Y"))
        SendDlgMessage(hDlg, "DM_LISTSETCURPOS", ID.month, { SelectPos = dt:getmonth() })

        local day = date(dt:getyear(), dt:getmonth(), 1)
        if Settings.FirstSunday then
            day:adddays(-(day:getweekday() == 1 and 7 or day:getweekday() - 1))
        else
            day:adddays(-(day:getisoweekday() == 1 and 7 or day:getisoweekday() - 1))
        end

        for d = 1, 7 do
            local id = ID.table - 7 + (Settings.FirstSunday and mod(d, 7) + 1 or d)
            SendDlgMessage(hDlg, "DM_SETTEXT", id, Localization().DaysOfWeek[d])
            CF[id] = d > 5 and Colors.Weekend or nil
        end

        for w = 0, 5 do
            for d = 1, 7 do
                local dayFormat = " %2s "
                local currentId = w * 7 + d
                local id = ID.table + currentId
                local daySelected = day:getmonth() == dt:getmonth() and day:getday() == dt:getday()
                local dayIsToday = day:getyear() == today:getyear() and day:getmonth() == today:getmonth() and day:getday() == today:getday()

                if daySelected then
                    CF[id] = Colors.Selected
                    dayFormat = dayIsToday and "{%2s}" or "[%2s]"
                    tableSelected = currentId
                elseif dayIsToday then
                    CF[id] = Colors.Today
                    dayFormat = "-%2s-"
                elseif day:getmonth() ~= dt:getmonth() then
                    CF[id] = Colors.Disabled
                elseif ((Settings.FirstSunday and mod(d - 2, 7) + 1 or d)) > 5 then
                    CF[id] = Colors.Weekend
                else
                    CF[id] = Colors.Normal
                end

                SendDlgMessage(hDlg, "DM_ENABLE", id, day:getmonth() == dt:getmonth() and 1 or 0)
                SendDlgMessage(hDlg, "DM_SETTEXT", id, fmt(dayFormat, day:getday()))
                day:adddays(1)
            end
        end
        SendDlgMessage(hDlg, "DM_SETTEXT", ID.title, dt:fmt(Settings.Format))
        SendDlgMessage(hDlg, "DM_SETTEXT", ID.textDate, dt:fmt(Settings.Format))
        SendDlgMessage(hDlg, "DM_SETTEXT", ID.textInfo, dt:fmt(Settings.Info))

        UpdateControlsState(hDlg)
        SendDlgMessage(hDlg, "DM_ENABLEREDRAW", 1)
        isRendering = false
    end

    local function GetItemColor(hDlg, Param1, Color)
        local _ = hDlg -- suppress the "unused argument" warning
        if CF[Param1] then
            Color[1].ForegroundColor = CF[Param1]
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

    local function DlgProc(hDlg, Msg, Param1, Param2)
        if Msg == F.DN_CTLCOLORDLGITEM then
            return GetItemColor(hDlg, Param1, Param2)
        elseif isRendering then
            return
        elseif Msg == F.DN_INITDIALOG then
            for i = 1, #Formats do
                SendDlgMessage(hDlg, "DM_ADDHISTORY", ID.format, Formats[i], i)
            end
            SendDlgMessage(hDlg, "DM_ADDHISTORY", ID.format, Settings.Format, 1)

            for i = 1, #Info do
                SendDlgMessage(hDlg, "DM_ADDHISTORY", ID.info, Info[i], i)
            end
            SendDlgMessage(hDlg, "DM_ADDHISTORY", ID.info, Settings.Info, 1)
            Redraw(hDlg)
        elseif Msg == F.DN_HELP then
            os.execute 'start https://github.com/dimfishr/Far_Macros#format'
        elseif Param1 == ID.insert then
            Text = GetDateText(hDlg)
        elseif Param1 == -1 then
            Text = ""
        elseif Msg == F.DN_EDITCHANGE then
            if Param1 == ID.year then
                local selY = tonumber(SendDlgMessage(hDlg, "DM_GETTEXT", Param1, 0))
                if selY ~= dt:getyear() then
                    dt:setyear(selY)
                    Redraw(hDlg)
                end
            elseif Param1 == ID.month then
                local selM = (SendDlgMessage(hDlg, "DM_LISTGETCURPOS", Param1, 0)).SelectPos
                if selM ~= dt:getmonth() then
                    setmonthFix(dt, selM)
                    Redraw(hDlg)
                end
            elseif Param1 == ID.format then
                Settings.Format = SendDlgMessage(hDlg, "DM_GETTEXT", Param1, 0)
                mf.msave("dimfish", "Calendar", Settings)
                Redraw(hDlg)
            elseif Param1 == ID.info then
                Settings.Info = SendDlgMessage(hDlg, "DM_GETTEXT", Param1, 0)
                mf.msave("dimfish", "Calendar", Settings)
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
                SendDlgMessage(hDlg, "DM_SETFOCUS", ID.userControl, 0)
            elseif Param1 == ID.today then
                dt = date()
                SendDlgMessage(hDlg, "DM_SETFOCUS", ID.userControl, 0)
            elseif Param1 == ID.copyDate then
                far.CopyToClipboard(GetDateText(hDlg))
                Text = "" -- do not print
            elseif Param1 == ID.firstSu or Param1 == ID.firstMo then
                Settings.FirstSunday = SendDlgMessage(hDlg, "DM_GETCHECK", ID.firstSu, 0) == 1 and true or false
                mf.msave("dimfish", "Calendar", Settings)
            else
                return
            end
            Redraw(hDlg)
        elseif Msg == F.DN_CONTROLINPUT then
            if Param1 ~= ID.month and Param1 ~= ID.format and Param1 ~= ID.info and Param2.ControlKeyState and
                    band(Param2.ControlKeyState, leftOrRightCtrl) ~= 0 and
                    band(Param2.ControlKeyState, leftOrRightAlt) == 0 then
                if Param2.VirtualKeyCode == VK.Left then
                    dt:addyears(-1)
                elseif Param2.VirtualKeyCode == VK.Up then
                    addmonthsFix(dt, -1)
                elseif Param2.VirtualKeyCode == VK.Right then
                    dt:addyears(1)
                elseif Param2.VirtualKeyCode == VK.Down then
                    addmonthsFix(dt, 1)
                elseif Param1 ~= ID.textDate and Param2.VirtualKeyCode == VK.Ins or Param2.VirtualKeyCode == VK.C then
                    far.CopyToClipboard(GetDateText(hDlg))
                    return
                else
                    return
                end
                Redraw(hDlg)
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
                    dt:adddays(math.floor(Param2.MousePositionX / 4) + Param2.MousePositionY * 7 + 1 - tableSelected)
                else
                    return
                end
                Redraw(hDlg)
            elseif Param1 == ID.textDate and Param2.VirtualKeyCode == VK.Enter then
                if SetDate(hDlg) then
                    Redraw(hDlg)
                end
                return true -- don't pass the keypress to the standard handler
            end
        end
    end

    local guid = win.Uuid("06a13b89-3fec-46a2-be11-a50b68ceaa56")
    far.Dialog(guid, -1, -1, 36, 21, nil, I, nil, DlgProc)
    if Text then print(Text) end
end

Macro {
    area = "Common"; key = Key; description = Localization().Title; flags = "";
    action = ExecCalendar;
}
