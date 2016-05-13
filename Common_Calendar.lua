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
}

local Weeks = {
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


local function Localization()
    if far.lang == "Russian" then
        return {
            Title = "Календарь";
            DaysOfWeek = { "Пн", "Вт", "Ср", "Чт", "Пт", "Сб", "Вс" };
            Months = { "Январь", "Февраль", "Март", "Апрель", "Май", "Июнь", "Июль", "Август", "Сентябрь", "Октябрь", "Ноябрь", "Декабрь" };
            Ok = "Вставить";
        }
    else
        return {
            Title = "Calendar";
            DaysOfWeek = { "Mo", "Tu", "We", "Th", "Fr", "Sa", "Su" };
            Months = { "January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December" };
            Ok = "Insert";
        }
    end
end

local F = far.Flags
local date = require("date")
local fmt = string.format
local band = bit.band

function InitCalendar()
    local Settings = mf.mload("dimfish", "Calendar") or { Format = 1, Weeks = 1 }
    local Text
    local today = date()
    local dt = date()
    local tableSelected
    local isRendering = false

    local ComboMonths = {} for i = 1, 12 do ComboMonths[i] = { Text = Localization().Months[i] } end
    local ComboFormats = {} for i = 1, #Formats do ComboFormats[i] = { Text = Formats[i] } end
    local ComboWeeks = {} for i = 1, #Weeks do ComboWeeks[i] = { Text = Weeks[i] } end

    local I = {}
    local ID = {}
    local CF = {}

    I[#I + 1] = { F.DI_DOUBLEBOX, 3, 1, 32, 18, 0, 0, 0, 0, Localization().Title }
    I[#I + 1] = { F.DI_BUTTON, 11, 2, 0, 2, 0, 0, 0, F.DIF_BTNNOCLOSE + F.DIF_NOBRACKETS, "Ctl→" }
    ID.yearInc = #I
    I[#I + 1] = { F.DI_BUTTON, 18, 2, 0, 2, 0, 0, 0, F.DIF_BTNNOCLOSE + F.DIF_NOBRACKETS, "Ctrl↑" }
    ID.monthInc = #I
    I[#I + 1] = { F.DI_FIXEDIT, 11, 3, 14, 3, 0, 0, "9999", F.DIF_MASKEDIT, "" }
    ID.year = #I
    I[#I + 1] = { F.DI_COMBOBOX, 16, 3, 24, 5, ComboMonths, 0, 0, F.DIF_DROPDOWNLIST, "" }
    ID.month = #I
    I[#I + 1] = { F.DI_BUTTON, 11, 4, 0, 4, 0, 0, 0, F.DIF_BTNNOCLOSE + F.DIF_NOBRACKETS, "Ctl←" }
    ID.yearDec = #I
    I[#I + 1] = { F.DI_BUTTON, 18, 4, 0, 4, 0, 0, 0, F.DIF_BTNNOCLOSE + F.DIF_NOBRACKETS, "Ctrl↓" }
    ID.monthDec = #I

    local row = 5
    for d = 1, 7 do
        I[#I + 1] = { F.DI_TEXT, d * 4 + 1, row, 0, row, 0, 0, 0, d > 5 and F.DIF_DISABLE or 0, Localization().DaysOfWeek[d] }
        if d > 5 then
            CF[#I] = Colors.Weekend
        end
    end
    ID.table = #I
    for w = 0, 5 do
        for d = 1, 7 do
            I[#I + 1] = { F.DI_TEXT, d * 4, row + 1 + w, 0, row + 1 + w, 0, 0, 0, 0, "" }
            if d > 5 then
                CF[#I] = Colors.Weekend
            end
        end
    end

    I[#I + 1] = { F.DI_USERCONTROL, 4, row + 1, 31, row + 6, 0, 0, 0, F.DIF_FOCUS }
    ID.userControl = #I
    I[#I + 1] = { F.DI_COMBOBOX, 6, 13, 15, 13, ComboFormats, 0, 0, F.DIF_DROPDOWNLIST, "" }
    ID.format = #I
    I[#I + 1] = { F.DI_COMBOBOX, 19, 13, 28, 13, ComboWeeks, 0, 0, F.DIF_DROPDOWNLIST, "" }
    ID.weeks = #I
    I[#I + 1] = { F.DI_FIXEDIT, 6, 15, 15, 15, 0, 0, "9999999999", F.DIF_READONLY, "" }
    ID.text = #I
    I[#I + 1] = { F.DI_TEXT, 19, 15, 28, 15, 0, 0, 0, 0, "" }
    ID.textAdd = #I
    I[#I + 1] = { F.DI_BUTTON, 0, 17, 0, 17, 0, 0, 0, F.DIF_DEFAULTBUTTON + F.DIF_CENTERGROUP, Localization().Ok }
    ID.submit = #I
    I[#I + 1] = { F.DI_TEXT, 0, 16, 0, 16, 0, 0, 0, F.DIF_SEPARATOR, "" }

    CF[ID.yearInc] = Colors.Disabled
    CF[ID.yearDec] = Colors.Disabled
    CF[ID.monthInc] = Colors.Disabled
    CF[ID.monthDec] = Colors.Disabled
    CF[ID.text] = Colors.Selected

    local function Redraw(hDlg)
        isRendering = true
        far.SendDlgMessage(hDlg, "DM_ENABLEREDRAW", 0)
        far.SendDlgMessage(hDlg, "DM_SETTEXT", ID.year, dt:fmt("%Y"))
        far.SendDlgMessage(hDlg, "DM_LISTSETCURPOS", ID.month, { SelectPos = dt:getmonth() })

        local day = date(dt:getyear(), dt:getmonth(), 1)
        day:adddays(-(day:getisoweekday() == 1 and 7 or day:getisoweekday() - 1))

        for w = 0, 5 do
            for d = 1, 7 do
                local dayFormat = " %2s "
                local currentId = w * 7 + d
                local id = ID.table + currentId

                if day:getmonth() == dt:getmonth() and day:getday() == dt:getday() then
                    CF[id] = Colors.Selected
                    dayFormat = "[%2s]"
                    tableSelected = currentId
                elseif day:getyear() == today:getyear() and day:getmonth() == today:getmonth() and day:getday() == today:getday() then
                    CF[id] = Colors.Today
                elseif day:getmonth() ~= dt:getmonth() then
                    CF[id] = Colors.Disabled
                elseif d > 5 then
                    CF[id] = Colors.Weekend
                else
                    CF[id] = Colors.Normal
                end

                far.SendDlgMessage(hDlg, "DM_ENABLE", id, day:getmonth() == dt:getmonth() and 1 or 0)
                far.SendDlgMessage(hDlg, "DM_SETTEXT", id, fmt(dayFormat, day:getday()))
                day:adddays(1)
            end
        end
        far.SendDlgMessage(hDlg, "DM_LISTSETCURPOS", ID.format, { SelectPos = Settings.Format })
        far.SendDlgMessage(hDlg, "DM_LISTSETCURPOS", ID.weeks, { SelectPos = Settings.Weeks })
        far.SendDlgMessage(hDlg, "DM_SETTEXT", ID.text, dt:fmt(Formats[Settings.Format]))
        far.SendDlgMessage(hDlg, "DM_SETTEXT", ID.textAdd, dt:fmt(Weeks[Settings.Weeks]))
        far.SendDlgMessage(hDlg, "DM_ENABLEREDRAW", 1)
        isRendering = false
    end

    local function DlgGetItemColor(hDlg, Param1, Color)
        if Param1 == ID.month or Param1 == ID.format or Param1 == ID.weeks then
            Color[3] = Color[1]
            return Color
        elseif CF[Param1] then
            Color[1].ForegroundColor = CF[Param1]
            return Color
        end
    end

    local function DlgProc(hDlg, Msg, Param1, Param2)
        if Msg == F.DN_CTLCOLORDLGITEM then
            return DlgGetItemColor(hDlg, Param1, Param2)
        elseif isRendering then
            return
        elseif Msg == F.DN_INITDIALOG then
            Redraw(hDlg)
        elseif Param1 == ID.submit then
            Text = far.SendDlgMessage(hDlg, "DM_GETTEXT", ID.text, nil)
        elseif Param1 == -1 then
            Text = ""
        elseif Msg == F.DN_EDITCHANGE then
            if Param1 == ID.year then
                local selY = tonumber(far.SendDlgMessage(hDlg, "DM_GETTEXT", Param1, nil))
                if selY ~= dt:getyear() then
                    dt:setyear(selY)
                    Redraw(hDlg)
                end
            elseif Param1 == ID.month then
                local selM = (far.SendDlgMessage(hDlg, "DM_LISTGETCURPOS", Param1, nil)).SelectPos
                if selM ~= dt:getmonth() then
                    dt:setmonth(selM)
                    Redraw(hDlg)
                end
            elseif Param1 == ID.format then
                Settings.Format = (far.SendDlgMessage(hDlg, "DM_LISTGETCURPOS", Param1, nil)).SelectPos
                mf.msave("dimfish", "Calendar", Settings)
                Redraw(hDlg)
            elseif Param1 == ID.weeks then
                Settings.Weeks = (far.SendDlgMessage(hDlg, "DM_LISTGETCURPOS", Param1, nil)).SelectPos
                mf.msave("dimfish", "Calendar", Settings)
                Redraw(hDlg)
            end
        elseif Msg == F.DN_BTNCLICK then
            if Param1 == ID.yearDec then
                dt:addyears(-1)
            elseif Param1 == ID.yearInc then
                dt:addyears(1)
            elseif Param1 == ID.monthDec then
                dt:addmonths(-1)
            elseif Param1 == ID.monthInc then
                dt:addmonths(1)
            end
            Redraw(hDlg)
        elseif Msg == F.DN_CONTROLINPUT then
            if Param1 ~= ID.month and Param1 ~= ID.format and Param1 ~= ID.weeks and
                    Param2.ControlKeyState and band(Param2.ControlKeyState, 0x0008 + 0x0004) ~= 0 then
                if Param2.VirtualKeyCode == 37 then
                    dt:addyears(-1)
                elseif Param2.VirtualKeyCode == 38 then
                    dt:addmonths(1)
                elseif Param2.VirtualKeyCode == 39 then
                    dt:addyears(1)
                elseif Param2.VirtualKeyCode == 40 then
                    dt:addmonths(-1)
                end
                Redraw(hDlg)
            elseif Param1 == ID.userControl then
                if Param2.VirtualKeyCode == 37 then
                    dt:adddays(-1)
                elseif Param2.VirtualKeyCode == 38 then
                    dt:adddays(-7)
                elseif Param2.VirtualKeyCode == 39 then
                    dt:adddays(1)
                elseif Param2.VirtualKeyCode == 40 then
                    dt:adddays(7)
                elseif Param2.ButtonState == 1 then
                    dt:adddays(math.floor(Param2.MousePositionX / 4) + Param2.MousePositionY * 7 + 1 - tableSelected)
                end
                Redraw(hDlg)
            end
        end
    end

    local guid = win.Uuid("06a13b89-3fec-46a2-be11-a50b68ceaa56")
    far.Dialog(guid, -1, -1, 36, 20, nil, I, nil, DlgProc)
    if Text then print(Text) end
end

Macro {
    area = "Common"; key = Key; description = Localization().Title; flags = "";
    action = InitCalendar;
}
