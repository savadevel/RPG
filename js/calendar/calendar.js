/*
    Содержит класс управления календарем

    где
        param - хешь параметров календаря
            
*/

$include('../js/', 'stdtypes.js');
$include('../js/', 'utils.js');

// 
function GetSetDate(strDate)
{
    return ((new CDate()).StrToDate(strDate));
}

// возвращает текущий день в установленном формате
function GetCurrDate()
{           
    return ((new CDate()).DateToStr());
}

function CCalendar(name, param)
{                                                                                                           
    var hParam   = param;
    var self     = this;    
    var date     = null;
    var controls = {body:null, form:null, year:null, month:null, day:null, years:null, months:null, days:null};
    var relation = undefined; // связь с получателем значения календаря при Hide
    var parent   = null;

    this.Show = function(oParent, oPosition, param)
    {
        parent = oParent || document.body;

        if (controls.body.parentNode != parent)
        {
            // устанавливаем нового родителя
            if (controls.body.parentNode)
                controls.body.parentNode.removeChild(controls.body);
            parent.appendChild(controls.body);
        }
        
        // сбрасываем предыддущую связь
        relation = undefined;

        if (!param.value)
        {
            date = new CDate();
        }
        else if ('object' == typeof(param.value) && 'undefined' == typeof(param.value.constructor))
        {
            switch(param.value.getAttribute('tagName'))
            {
                case 'INPUT':
                    date = new CDate(param.value.value);
                    // по умолчанию связь значения календаря будет со входным параметром - объектом
                    relation = param.value;
                    break;
                                    
                default:
                    alert('Error, unknown type of object: ' + param.value);
                    date = new CDate();
                    break;
            }
        }
        else
        {
            date = new CDate(value);
        }
        
        if (SPosition.prototype.isPrototypeOf(oPosition))
        {
            // позиция фиксированная
            controls.body.style.pixelLeft = oPosition.left;
            controls.body.style.pixelTop  = oPosition.top;
        }
        else if (oPosition)
        {
            // вычисление относительной позиции 
            controls.body.style.pixelLeft = calc_left(oPosition);
            controls.body.style.pixelTop  = calc_top(oPosition) + oPosition.offsetHeight;            
        }
        
        if (param.dtop)
            controls.body.style.pixelTop += param.dtop;

        if (param.dleft)
            controls.body.style.pixelLeft += param.dleft;
            
        draw_calendar();

        controls.body.style.display = 'block';        

        self.Dispatch('ON_CALENDAR_SHOW', self);        
    }    

    this.Hide=function(receiver)
    {
        if (!self.IsShow())
            return;
    
        self.Dispatch('ON_CALENDAR_HIDE', self);
        controls.body.style.display  = 'none';
        
        // если связь не заданна явно по умолчанию 
        // используем которая была определенна при отображении календаря
        if (!arguments.length)
            receiver = relation;
        
        if ('object' == typeof(receiver) && 'undefined' == typeof(receiver.constructor))
        {
            switch(receiver.getAttribute('tagName'))
            {
                case 'INPUT':
                    receiver.value = date.ToString();
                    break;
                                    
                default:
                    break;
            }
        }
        
        controls.body.parentNode.removeChild(controls.body);
        
        self.Dispatch('ON_CALENDAR_AFTER_HIDE', self);
    }
    
    this.IsShow=function(oParent)
    {
        return (oParent ? (oParent == controls.body.parentNode && controls.body.style.display != 'none')  : (controls.body.style.display != 'none'));
    }

    this.GetDate=function()
    {
        return (date);
    }

    this.GetParent=function()
    {
        return (parent);
    }
    
    function on_mouse_over() 
    {
        if (this.className != "day_selected")
            this.className = "day_mouseover";
    }

    function on_mouse_out() 
    {
        if (this.className != "day_selected")
            (this.cellIndex>0) ? this.className="day": this.className="day_off";
    }

    function on_mouse_click() 
    {
        var day = this.innerHTML;

        if (this.className == "day_disabled") // день вне текущего месяца            
            date = date.AddMonths(parseInt(day) > 20 ? -1: 1);
        date.SetDay(day); 
        draw_calendar();
    }
    
    function on_mouse_dblclick()
    {
        var day = this.innerHTML;

        if (this.className == "day_disabled") // день вне текущего месяца            
            date = date.AddMonths(parseInt(day) > 20 ? -1: 1);
        date.SetDay(day);         
        self.Hide();
    }

    function set_date(year, month, day)
    {
        date.SetDate(year, month, day);        
        draw_calendar();
    }


    function add_days(days)
    {
        days = parseInt(days);

        if (isNaN(days))
             return;

        date = date.AddDays(days);
        draw_calendar();
    }

    function add_months(months)
    {
        months = parseInt(months);

        if (isNaN(months))
             return;

        date = date.AddMonths(months);
        draw_calendar();
    }

    function add_years(years)
    {   
        years = parseInt(years);

        if (isNaN(years))
             return;
        
        date = date.AddYears(years);
        draw_calendar();
    }

    function set_today()
    {
        date = date.Now();
        draw_calendar();
    }

    function extend()
    {
        if (controls.body.style.width == "180px")
        {
            controls.body.style.width          = "265px";
            controls.ext.value                 = "<<";
            controls.counters.style.visibility ="visible";
        }
        else 
        {
            controls.body.style.width          = "180px";
            controls.ext.value                 = ">>";
            controls.counters.style.visibility = "hidden";
        }    
    }

    function draw_calendar() 
    {
        var iDaysInMonth     = date.DaysInMonth(); 
        var iDaysInPrevMonth = date.AddMonths(-1).DaysInMonth();
        var iDay             = 0; // счетчик дней, размещаемых на календаре
        var iStartWeek       = date.GetFirstDayOfWeekInMonth(); // определяем день недели первого числа текущего месяца, 0 - воскресение

        controls.month.selectedIndex = date.GetMonth();
        controls.year.selectedIndex  = date.GetYear() - 1900;

        // цикл по всем дням календаря
        for (var i = 0; i < 42; i++)
        {
            // размер календаря 7х6, т.е. 7 дней в строке и 6 недель       
            var cell = controls.day.rows[Math.floor(i/7) + 1].cells[i%7];
            
            iDay           = i - iStartWeek + 1;  // учитываем расположение в первой неделе календаря, первого дня месяца
            cell.className = (cell.cellIndex > 0 ? "day" : "day_off");  // подсвечиваем выходные (первый день недели воскресение)
            
            // ячейка должна содержать дочерний текстовой объект
            if (0 == cell.childNodes.length)
            {
                cell.appendChild(document.createTextNode(''));
            }
            
            var text = cell.childNodes(0);
            
            if (iDay <= 0 ) 
            {
                // день из предыдущего месяца
                text.nodeValue   = iDay + iDaysInPrevMonth;
                cell.className   = "day_disabled";
                cell.onmouseover = "";
                cell.onmouseout  = "";
            }
            else if (iDay > 0 && iDay <= iDaysInMonth) 
            {
                text.nodeValue   = iDay;
                cell.onmouseover = on_mouse_over;
                cell.onmouseout  = on_mouse_out;
            }
            else if (iDay > iDaysInMonth) 
            {
                text.nodeValue   = iDay - iDaysInMonth;
                cell.className   = "day_disabled"
                cell.onmouseover = "";
                cell.onmouseout  = "";
            }

            cell.onclick    = on_mouse_click;
            cell.ondblclick = on_mouse_dblclick;

            if (iDay == date.GetDay()) 
                cell.className = "day_selected";
        }
    }
    
    function calc_top(obj)
    {
        var oParent = obj.offsetParent;

        if (oParent == null)
            return 0
        
        if (parent == document.body) 
            return (obj.offsetTop + oParent.clientTop);
        
        return (obj.offsetTop + oParent.clientTop + calc_top(oParent));
    }

    function calc_left(obj)
    {
        var oParent = obj.offsetParent;

        if (oParent == null)
            return 0

        if (parent == document.body) 
            return (obj.offsetLeft + oParent.clientLeft);
            
        return (obj.offsetLeft + oParent.clientLeft + calc_left(oParent));
    }    

    function constr()
    {
        // наследование от базового класса CEventsHandler
        self.parent = CEventsHandler; // наследуем свойства и методы                
        self.parent(hParam.events);   // вызов родительского конструктора           

        var html;

        controls.body  = document.createElement("DIV");

        controls.body.onselectstart = function () {return (event.returnValue == true);};
        controls.body.style.cssText = 'padding:0 0 0 0;margin:0 0 0 0;z-index:444;position:absolute; top:0; left:0; width:180px; height:160px; border:1px solid threeddarkshadow; border-top:1px solid buttonface; border-left:1px solid buttonface;';
        controls.body.style.display = 'none';

        controls.form  = document.createElement('<form name="' + name + '"></form>');

        controls.body.appendChild(controls.form); 

        controls.basis  = document.createElement("<DIV style='z-index:444;position:absolute; top:0; left:0; width:100%; height:100%; background:buttonface; border:1px solid buttonshadow; border-top:1px solid buttonhighlight; border-left:1px solid white;'></DIV>");
        controls.form.appendChild(controls.basis);

        controls.lframe = document.createElement("<DIV style='z-index:444;position:absolute; left:0px; top:5px; width:176px;'></DIV>");
        controls.basis.appendChild(controls.lframe);

        controls.rframe = document.createElement("<DIV style='position:absolute; visibility: hidden; left:180px; top:10px; width:70px; height:150px; z-index:1'></DIV>");
        controls.basis.appendChild(controls.rframe);                

        html  = "<CENTER><SELECT ID=month class=control style='width:77px'>";
        html += "<OPTION>Январь<OPTION>Февраль<OPTION>Март<OPTION>Апрель<OPTION>Май<OPTION>Июнь<OPTION>Июль<OPTION>Август<OPTION>Сентябрь<OPTION>Октябрь<OPTION>Ноябрь<OPTION>Декабрь</SELECT>&nbsp;";
        html += "<SELECT ID=year class=control onchange=displayCalendar(month.selectedIndex,this.selectedIndex+1900) style='width:57px'>";

        for (var i=1900; i<2100; i++) 
            html += "<OPTION>"+i;

        html += "</SELECT>";
        html += "&nbsp;<INPUT id=ext TYPE=BUTTON class=control style='width:20px' VALUE='>>' onClick='setWindowsWidth(this)'><BR>";
        html += "<style type=text/css>";
        html += "<!--";
        html += ".control  { font-family:Arial, Helvetica, sans-serif; font-size: 10px; height: 18px}";
        html += ".control1 { font-family:Arial, Helvetica, sans-serif; font-size: 10px; height: 18px; width: 35px;}";
        html += ".control2 { font-family:Arial, Helvetica, sans-serif; font-size: 11px;height: 15px}";
        html += ".day_off_header { font-family:Arial, Helvetica, sans-serif; background-color: #FF3333; height: 14px; width: 20px; font-size: 9px; font-weight: bold; color: #FFFFFF; text-align: center; cursor: default; border: 1px #FFFFFF outset; padding-top: 0px; padding-right: 0px; padding-bottom: 0px; padding-left: 0px}";
        html += ".day_header { font-family:Arial, Helvetica, sans-serif; background-color: #666666; height: 14px; width: 20px; font-size: 9px; font-weight: bold; color: #FFFFFF; text-align: center; cursor: default; border: 1px #FFFFFF outset; padding-top: 0px; padding-right: 0px; padding-bottom: 0px; padding-left: 0px}";
        html += ".day_disabled { font-family:Arial, Helvetica, sans-serif; font-size: 9px; color:#999999; font-weight: bold; background-color: buttonface; height: 14px; width: 20px; text-align: center; cursor: default; border: 1px #B4B4B4 solid; padding-top: 0px; padding-right: 0px; padding-bottom: 0px; padding-left: 0px}";
        html += ".day { font-family:Arial, Helvetica, sans-serif; font-size: 9px; font-weight: bold; background-color: buttonface; height: 14px; width: 20px; text-align: center; cursor: default; border: 1px #FFFFFF outset; padding-top: 0px; padding-right: 0px; padding-bottom: 0px; padding-left: 0px}";
        html += ".day_selected { font-family:Arial, Helvetica, sans-serif; font-size: 9px; color: #FFFFFF; font-weight: bold; background-color: #000080; height: 12px; width: 18px; text-align: center; cursor: default; border: 1px #CCCCCC inset; padding-top: 0px; padding-right: 0px; padding-bottom: 0px; padding-left: 0px}";
        html += ".day_off { font-family:Arial, Helvetica, sans-serif; font-size: 9px; font-weight: bold; background-color: buttonface; height: 14px; width: 20px; text-align: center ; color: #FF0000 ; cursor: default; border: 1px #FFFFFF outset; padding-top: 0px; padding-right: 0px; padding-bottom: 0px; padding-left: 0px}";
        html += ".day_mouseover { font-family:Arial, Helvetica, sans-serif; font-size: 9px; font-weight: bold; color: #990000; background-color: buttonface; height: 14px; width: 20px; text-align: center; cursor: default; border: 1px #FFFFFF outset; padding-top: 0px; padding-right: 0px; padding-bottom: 0px; padding-left: 0px}";
        html += "-->";
        html += "</style>";
        html += "<table border=0  cellspacing=1>";
        html += "<tr> ";
        html += "<td class=day_off_header>Вс</td><td class=day_header>Пн</td><td class=day_header>Вт</td><td class=day_header>Ср</td><td class=day_header>Чт</td><td class=day_header>Пт</td><td class=day_header>Сб</td>";
        html += "</tr>";
        
        for (var i=0; i<7; i++) 
            html +="<tr><td></td><td></td><td></td><td></td><td></td><td></td><td></td></tr>";

        html += "</table>";
        html += "<INPUT TYPE=BUTTON class=control style='width:20px' VALUE='<<' TITLE='Предыдущий год' ID='pyear'>";
        html += "&nbsp;<INPUT TYPE=BUTTON class=control style='width:20px' VALUE=' < ' TITLE='Предыдущий месяц'  ID='pmonth'>";
        html += "&nbsp;<INPUT TYPE=BUTTON class=control style='width:67px' VALUE=' Сегод. '    ID='today'>";
        html += "&nbsp;<INPUT TYPE=BUTTON class=control style='width:20px' VALUE=' > ' TITLE='Следующий месяц'  ID='nmonth'>";
        html += "&nbsp;<INPUT TYPE=BUTTON class=control style='width:20px' VALUE='>>'  TITLE='Следующий год' ID='nyear'></CENTER>";

        controls.lframe.innerHTML = html;
        
        html  = "<CENTER><span class=control2>День:</span><BR>";
        html += "<INPUT TYPE=BUTTON style='width:15px' class=control VALUE='-' id='ddays'>";
        html += "<INPUT TYPE=text class=control1 VALUE='' style='width:40px'   id='days'>";
        html += "<INPUT TYPE=BUTTON class=control style='width:15px' VALUE='+' id='idays'><BR>";
        html += "<span class=control2>Месяц:</span><BR>";
        html += "<INPUT TYPE=BUTTON class=control style='width:15px' VALUE='-' id='dmonths'>";
        html += "<INPUT TYPE=text class=control1 VALUE=''                      id='months'>";
        html += "<INPUT TYPE=BUTTON class=control style='width:15px' VALUE='+' id='imonths'><BR>";
        html += "<span class=control2>Год:</span><BR>";
        html += "<INPUT TYPE=BUTTON class=control style='width:15px' VALUE='-' id='dyears'>";
        html += "<INPUT TYPE=text class=control1 VALUE=''                      id='years'>";
        html += "<INPUT TYPE=BUTTON class=control style='width:15px' VALUE='+' id='iyears'>";
        html += "<br><br><INPUT TYPE=BUTTON class=control style='width:30px' VALUE=' OK ' id='applay'></CENTER>";

        controls.rframe.innerHTML = html;

        controls.day      = controls.form.getElementsByTagName('table')[0];
        controls.month    = controls.form.month;  controls.month.onchange  = function() {set_date(null, this.selectedIndex, null);}
        controls.year     = controls.form.year;   controls.year.onchange   = function() {set_date(this.selectedIndex + 1900, null, null);}
        controls.pmonth   = controls.form.pmonth; controls.pmonth.onclick  = function() {add_months(-1);}
        controls.nmonth   = controls.form.nmonth; controls.nmonth.onclick  = function() {add_months(1);}
        controls.pyear    = controls.form.pyear;  controls.pyear.onclick   = function() {add_years(-1);}
        controls.nyear    = controls.form.nyear;  controls.nyear.onclick   = function() {add_years(1);}
        controls.today    = controls.form.today;  controls.today.onclick   = set_today;
        controls.ext      = controls.form.ext;    controls.ext.onclick     = extend;
        
        controls.counters = controls.rframe;
        controls.days     = controls.form.days;           
        controls.months   = controls.form.months;        
        controls.years    = controls.form.years;

        controls.ddays    = controls.form.ddays;   controls.ddays.onclick   = function() {add_days(-parseInt(controls.form.days.value));}
        controls.idays    = controls.form.idays;   controls.idays.onclick   = function() {add_days(parseInt(controls.form.days.value));}        
        
        controls.dmonths  = controls.form.dmonths; controls.dmonths.onclick = function() {add_months(-parseInt(controls.form.months.value));}
        controls.imonths  = controls.form.imonths; controls.imonths.onclick = function() {add_months(parseInt(controls.form.months.value));}

        controls.dyears   = controls.form.dyears;  controls.dyears.onclick  = function() {add_years(-parseInt(controls.form.years.value));}
        controls.iyears   = controls.form.iyears;  controls.iyears.onclick  = function() {add_years(parseInt(controls.form.years.value));}        
        
        controls.applay   = controls.form.applay;  controls.applay.onclick  = function() {self.Hide();}        
    }
        
    constr();
}

