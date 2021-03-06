#Calendar FAR macro

![alt text](http://i79.fastpic.ru/big/2016/0530/88/d6073dc13cadcd39bb5d448241510d88.png "Calendar")

##Features:

* Print or copy custom date format
* First day option
* Parse date by selected format or any format
* Macros Key: Ctrl+Alt+F11
* Hotkeys: Ctrl+Arrows - change Month/Year
* Hotkeys: Ctrl+Ins, Ctrl+C - copy to Clipboard
* Hotkeys: Ctrl+\[F1,F2,F3,LMB\] - change Color of Selected Today or Selected or Today 
* Hotkeys: Ctrl+Shift+\[F1,F2,F3,LMB\] - change Color of Selected Today Weekend or Selected Weekend or Today Weekend 
* Hotkeys: Ctrl+Alt+\[F1,F2,F3,LMB\] - change Format of Selected Today or Selected or Today 

#### Format
|Spec|Description|
|------|---|
|**%a**|Abbreviated weekday name (Sun)
|**%A**|Full weekday name (Sunday)
|**%b**|Abbreviated month name (Dec)
|**%B**|Full month name (December)
|**%C**|Year/100 (19, 20, 30)
|**%d**|The day of the month as a number (range 1 - 31)
|**%g**|year for ISO 8601 week, from 00 (79)
|**%G**|year for ISO 8601 week, from 0000 (1979)
|**%h**|same as %b
|**%H**|hour of the 24-hour day, from 00 (06)
|**%I**|The hour as a number using a 12-hour clock (01 - 12)
|**%j**|The day of the year as a number (001 - 366)
|**%m**|Month of the year, from 01 to 12
|**%M**|Minutes after the hour 55
|**%p**|AM/PM indicator (AM)
|**%S**|The second as a number (59, 20 , 01)
|**%u**|ISO 8601 day of the week, to 7 for Sunday (7, 1)
|**%U**|Sunday week of the year, from 00 (48)
|**%V**|ISO 8601 week of the year, from 01 (48)
|**%w**|The day of the week as a decimal, Sunday being 0
|**%W**|Monday week of the year, from 00 (48)
|**%y**|The year as a number without a century (range 00 to 99)
|**%Y**|Year with century (2000, 1914, 0325, 0001)
|**%z**|Time zone offset, the date object is assumed local time (+1000, -0230)
|**%Z**|Time zone name, the date object is assumed local time
|**%\b**|Year, if year is in BCE, prints the BCE Year representation, otherwise result is similar to "%Y" (1 BCE, 40 BCE) #
|**%\f**|Seconds including fraction (59.998, 01.123) #
|**%%**|percent character %
|**%r**|12-hour time, from 01:00:00 AM (06:55:15 AM); same as "%I:%M:%S %p"
|**%R**|hour:minute, from 01:00 (06:55); same as "%I:%M"
|**%T**|24-hour time, from 00:00:00 (06:55:15); same as "%H:%M:%S"
|**%D**|month/day/year from 01/01/00 (12/02/79); same as "%m/%d/%y"
|**%F**|year-month-day (1979-12-02); same as "%Y-%m-%d"
|**%c**|The preferred date and time representation; same as "%x %X"
|**%x**|The preferred date representation, same as "%a %b %d %\b"
|**%X**|The preferred time representation, same as "%H:%M:%\f"
|**${iso}**|Iso format, same as "%Y-%m-%dT%T"
|**${http}**|http format, same as "%a, %d %b %Y %T GMT"
|**${ctime}**|ctime format, same as "%a %b %d %T GMT %Y"
|**${rfc850}**|RFC850 format, same as "%A, %d-%b-%y %T GMT"
|**${rfc1123}**|RFC1123 format, same as "%a, %d %b %Y %T GMT"
|**${asctime}**|asctime format, same as "%a %b %d %T %Y"
|**${ru}**|Russian locale for month and week names

[Full Specification](https://tieske.github.io/date/)

##### Default Colors
* Normal - 0x0 (black)
* Weekend - 0x4 (maroon)
* Selected - 0xE (yellow)
* Disabled - 0x8 (gray)

## Requirement

[LuaDate](https://github.com/dimfishr/date/)

## License

[BSD 3-Clause](https://opensource.org/licenses/BSD-3-Clause)

