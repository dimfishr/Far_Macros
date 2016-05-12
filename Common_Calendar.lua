-------------------------------------------------------------------------------
-- Calendar by dimfish
-------------------------------------------------------------------------------

local	Key = "CtrlShiftF11"

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


function InitCalendar()
  local Settings = mf.mload("dimfish", "Calendar") or { Format = 1, Weeks = 1 }
  local today = date()
  local dt = date()
  local tableSelected
  local isDraw = false

  local ComboMonths = {} for i = 1,12 do ComboMonths[i] = { Text = Localization().Months[i] } end
  local ComboFormats = {} for i = 1,#Formats do ComboFormats[i] = { Text = Formats[i] } end
  local ComboWeeks = {} for i = 1,#Weeks do ComboWeeks[i] = { Text = Weeks[i] } end

  local I = {}
  I[#I+1] = { F.DI_DOUBLEBOX,  3,  1, 32, 18, 0,0,0,0, Localization().Title}
  I[#I+1] = { F.DI_BUTTON,     5,  3,  0,  3, 0,0,0,F.DIF_BTNNOCLOSE+F.DIF_NOBRACKETS,"<<"}
  local yearDecId = #I
  I[#I+1] = { F.DI_BUTTON,     8,  3,  0,  3, 0,0,0,F.DIF_BTNNOCLOSE+F.DIF_NOBRACKETS," <"}
  local monthDecId = #I
  I[#I+1] = { F.DI_FIXEDIT,   11,  3, 14,  3, 0,0, "9999",F.DIF_MASKEDIT,""}
  local yearId = #I
  I[#I+1] = { F.DI_COMBOBOX,  16,  3, 23,  5, ComboMonths ,0,0,F.DIF_DROPDOWNLIST,""}
  local monthId = #I
  I[#I+1] = { F.DI_BUTTON,    26,  3,  0,  3, 0,0,0,F.DIF_BTNNOCLOSE+F.DIF_NOBRACKETS,"> "}
  local monthIncId = #I
  I[#I+1] = { F.DI_BUTTON,    29,  3,  0,  3, 0,0,0,F.DIF_BTNNOCLOSE+F.DIF_NOBRACKETS,">>"}
  local yearIncId = #I

  local row = 5
  for d = 1,7 do 
		I[#I+1] = { F.DI_TEXT, d*4+1, row , 0, row, 0,0,0, d>5 and F.DIF_DISABLE or 0, Localization().DaysOfWeek[d] }
	end
	local tableId = #I
	for w = 0,5 do
		for d = 1,7 do
      I[#I+1] = { F.DI_TEXT, d*4, row+1+w, 0, row+1+w, 0,0,0,0, "" }
    end
  end

  I[#I+1] = { F.DI_USERCONTROL,4,  row+1, 31, row+6, 0,0,0,F.DIF_FOCUS }
  local userControlId = #I
  I[#I+1] = { F.DI_COMBOBOX,   6, 13, 15, 13, ComboFormats ,0,0,F.DIF_DROPDOWNLIST,""}
  local formatId = #I
  I[#I+1] = { F.DI_COMBOBOX,   19, 13, 28, 13, ComboWeeks ,0,0,F.DIF_DROPDOWNLIST,""}
  local weeksId = #I
  I[#I+1] = { F.DI_TEXT,       6, 15, 15, 15, 0,0,0,0,""}
  local textId = #I
  I[#I+1] = { F.DI_TEXT,       19, 15, 28, 15, 0,0,0,0,""}
  local textAddId = #I
  I[#I+1] = { F.DI_BUTTON,     0, 17,  0, 17, 0,0,0,F.DIF_DEFAULTBUTTON+F.DIF_CENTERGROUP,Localization().Ok}
  local submitId = #I
  I[#I+1] = { F.DI_TEXT,       0, 16,  0, 16, 0,0,0,F.DIF_SEPARATOR,""}

  local function Redraw(hDlg)
    isDraw = true
    far.SendDlgMessage(hDlg, "DM_ENABLEREDRAW", 0)
    far.SendDlgMessage(hDlg, "DM_SETTEXT", yearId, dt:fmt("%Y"))
    far.SendDlgMessage(hDlg, "DM_LISTSETCURPOS", monthId, { SelectPos = dt:getmonth() })

    local day = date(dt:getyear(), dt:getmonth(), 1)
		day:adddays(-(day:getisoweekday() == 1 and 7 or day:getisoweekday() - 1))

    tableSelected = nil
		for w = 0,5 do
			for d = 1,7 do
        local dayFormat = " %2s "
        local currentId = w * 7 + d
        if day:getyear()==today:getyear() and day:getmonth()==today:getmonth() and day:getday()==today:getday() then
          dayFormat = "[%2s]"
          tableSelected = tableSelected or currentId
        elseif day:getmonth()==dt:getmonth() and day:getday()==dt:getday() then
          dayFormat = "{%2s}"
          tableSelected = currentId
        end
        far.SendDlgMessage(hDlg,"DM_ENABLE", tableId + currentId, day:getmonth()==dt:getmonth() and 1 or 0)
        far.SendDlgMessage(hDlg,"DM_SETTEXT", tableId + currentId, fmt(dayFormat, day:getday()))
        day:adddays(1)
      end
    end
    far.SendDlgMessage(hDlg,"DM_LISTSETCURPOS", formatId, { SelectPos = Settings.Format })
    far.SendDlgMessage(hDlg,"DM_LISTSETCURPOS", weeksId, { SelectPos = Settings.Weeks })
    far.SendDlgMessage(hDlg,"DM_SETTEXT", textId, dt:fmt(Formats[Settings.Format]))
    far.SendDlgMessage(hDlg,"DM_SETTEXT", textAddId, dt:fmt(Weeks[Settings.Weeks]))
    far.SendDlgMessage(hDlg,"DM_ENABLEREDRAW", 1)
    isDraw = false
  end

  local function DlgProc(hDlg,Msg,Param1,Param2)
    if isDraw then
    elseif Msg == F.DN_INITDIALOG then
      Redraw(hDlg)
    elseif Param1 == submitId then
      Text = far.SendDlgMessage(hDlg, "DM_GETTEXT", textId, nil)
    elseif Param1 == -1 then
      Text = ""
    elseif Msg == F.DN_EDITCHANGE then
			if Param1 == yearId then
				local selY = tonumber(far.SendDlgMessage(hDlg, "DM_GETTEXT", yearId, nil))
				if selY ~= dt:getyear() then 
					dt:setyear(selY) 
					Redraw(hDlg)
				end
			elseif Param1 == monthId then
				local selM = (far.SendDlgMessage(hDlg, "DM_LISTGETCURPOS", monthId, nil)).SelectPos
				if selM ~= dt:getmonth() then 
					dt:setmonth(selM)	
					Redraw(hDlg)
				end
      elseif Param1 == formatId then
				Settings.Format = (far.SendDlgMessage(hDlg, "DM_LISTGETCURPOS", formatId, nil)).SelectPos
				mf.msave("dimfish", "Calendar", Settings)
				Redraw(hDlg)
      elseif Param1 == weeksId then
				Settings.Weeks = (far.SendDlgMessage(hDlg, "DM_LISTGETCURPOS", weeksId, nil)).SelectPos
				mf.msave("dimfish", "Calendar", Settings)
				Redraw(hDlg)
			end
    elseif Msg == F.DN_BTNCLICK then
      if Param1 == yearDecId then
        dt:addyears(-1)
      elseif Param1 == yearIncId then
        dt:addyears(1)
      elseif Param1 == monthDecId then
        dt:addmonths(-1)
      elseif Param1 == monthIncId then
        dt:addmonths(1)
      end
      Redraw(hDlg)
    elseif Msg == F.DN_CONTROLINPUT and Param1 == userControlId then
      if Param2.ControlKeyState and band(Param2.ControlKeyState, 0x0008+0x0004) ~= 0 then
        if Param2.VirtualKeyCode == 37 then
					dt:addmonths(-1)
        elseif Param2.VirtualKeyCode == 38 then
					dt:addyears(1)
        elseif Param2.VirtualKeyCode == 39 then
					dt:addmonths(1)
        elseif Param2.VirtualKeyCode == 40 then
					dt:addyears(-1)
        end
      elseif Param2.VirtualKeyCode == 37 then
				dt:adddays(-1)
      elseif Param2.VirtualKeyCode == 38 then
				dt:adddays(-7)
      elseif Param2.VirtualKeyCode == 39 then
				dt:adddays(1)
      elseif Param2.VirtualKeyCode == 40 then
				dt:adddays(7)
      elseif Param2.ButtonState == 1 then
        dt:adddays(math.floor(Param2.MousePositionX/4)  + Param2.MousePositionY * 7 + 1 - tableSelected)
      end
      Redraw(hDlg)
    end
  end

  local guid = win.Uuid("06a13b89-3fec-46a2-be11-a50b68ceaa56")
  far.Dialog (guid, -1, -1, 36, 20, nil, I, nil, DlgProc)
  if Text then print(Text) end
end

Macro { area="Common"; key=Key; description=Localization().Title; flags=""; 
	action=InitCalendar;
}
