/*
    Содержит класс CDate для работы с датой
    
    mm

*/

var FORMAT_OF_DATE = '%d.%m.%Y';

function SPosition(top, left)
{
    this.top  = top;
    this.left = left;
}

function CDate(value, format)
{
    this.format = FORMAT_OF_DATE;
    this.date   = null;    
    var self    = this;
    
    this.DateToStr = function(date, format)
    {
        var ret = null;
        
        format = format || self.format;
        date   = date   || self.date;

        var vDay       = date.getDate(); 
        var vMonth     = date.getMonth() + 1; 
        var vYearLong  = date.getFullYear(); 
        var vYearShort = date.getFullYear().toString().substring(3,4); 
        var vYear      = format.indexOf('%Y') >-1 ? vYearLong : vYearShort; 
        var vHour      = date.getHours(); 
        var vMinute    = date.getMinutes(); 
        var vSecond    = date.getSeconds();

        ret = format.replace(/%H/g, add_zero(vHour)).replace(/%M/g, add_zero(vMinute)).replace(/%S/g, add_zero(vSecond));         
        ret = ret.replace(/%d/g, add_zero(vDay)).replace(/%m/g, add_zero(vMonth)).replace(/%y/g, add_zero(vYear));

        return ret.replace(/%Y/g, vYear);
    }

    this.ToString = function()
    {
        return self.DateToStr(self.date, self.format);
    }

    this.GetSource = function()
    {
        return this.date;
    }     


    this.IsLeapYear = function() 
    {
        return is_leap_year(self.date.getFullYear());
    }

    this.DaysInMonth = function()  
    {
        return days_in_month(self.date.getMonth(), self.date.getFullYear());
    }

    function is_leap_year(year) 
    {

        if (((year%4) == 0) && ((year%100) != 0) || ((year%400)==0)) 
        {
            return (true);
        } 
        else 
        { 
            return (false); 
        }
    }

    function days_in_month(month, year)  
    {
        if      (month == 0 || month == 2 || month == 4 || month == 6 || month == 7 || month == 9 || month == 11)  
            return (31); 
        else if (month == 3 || month == 5 || month == 8 || month == 10) 
            return (30);
        else //if (month == 1)  
            return (is_leap_year(year) ? 29 : 28);
    }

    function add_months(month, add)
    {
        month = (month + add)%12;

        if (month < 0)
            return (month + 12);

        return month;
    }

    this.GetPrevMonth = function()
    {
        return add_months(self.date.getMonth(), -1);
    }

    this.GetNextMonth = function()
    {
        return add_months(self.date.getMonth(),  1);
    }

    this.AddDays = function(days)
    {
        var sec = self.date.valueOf() + 86400000 * days;
        
        return new CDate(new Date(sec)); 
    }
    
    this.AddMonths = function(months)
    {
        var month, year, day, days;
        
        day   = self.date.getDate();
        month = self.date.getMonth();
        year  = self.date.getFullYear() + Math.floor((month + months)/12);
        month = add_months(month, months);
        days  = days_in_month(month, year);

        if (day > days)
            day = days;

        return new CDate(new Date(year, month, day)); 
    }

    this.AddYears = function(years)
    {
        var month, year, day, days;
        
        day   = self.date.getDate();
        month = self.date.getMonth();
        year  = self.date.getFullYear() + years;
        days  = days_in_month(month, year);

        if (day > days)
            day = days;

        return new CDate(new Date(year, month, day)); 
    }

    this.GetFirstDayOfWeekInMonth = function()
    {
        return (new Date(self.GetYear(), self.GetMonth(), 1)).getDay();
    }

    this.GetDay = function()
    {
        return self.date.getDate();
    }

    this.GetDayOfWeek = function()
    {
        return self.date.getDay();
    }

    this.GetMonth = function()
    {
        return self.date.getMonth();
    }

    this.GetYear = function()
    {
        return self.date.getFullYear();
    }

    this.Now = function()
    {
        return (new CDate());
    }

    this.SetDate = function(year, month, day)
    {
        if ('undefined' == typeof(year) || null == year)
            year  = self.date.getFullYear();

        if ('undefined' == typeof(month) || null == month)
            month = self.date.getMonth();

        if ('undefined' == typeof(day) || null == day)
            day   = self.date.getDate();

        var days = days_in_month(month, year);

        if (day > days)
            day = days;

        self.date = new Date(year, month, day);
    }

    this.SetDay = function(date)
    {
        return self.date.setDate(date);
    }

    this.SetMonth = function(month)
    {
        return self.date.setMonth(month);
    }

    this.SetYear = function(year)
    {
        return self.date.setFullYear(year);
    }                                    

    this.StrToDate = function(str, format)
    {
        format = format || self.format;
        
        if (!str) return this.date;

        var pos = 0, fields = {}, num = 1;

        format = format.replace(/([\\\$\^\.\*\{\}\[\]\(\)\|\+\?\@])/g, '\\$1');

        while (1)
        {
            pos = format.indexOf('%', pos);
            
            if (pos < 0) break;          
        
            switch(format.substr(pos, 3))
            {
                case '%MM': case '%HH': case '%SS':
                    fields[format.substr(pos + 1, 2).toLowerCase()] = num++;
                    format = format.replace(format.substr(pos, 3), '(\\d{2})');
                    break;

                case '%mm': case '%hh': case '%ss':
                    fields[format.substr(pos + 1, 2).toLowerCase()] = num++;
                    format = format.replace(format.substr(pos, 3), '(\\d{1,2})');
                    break;

                default:                    
                    switch(format.substr(pos, 2))
                    {
                        case '%M': case '%D': case '%y':
                            fields[format.substr(pos + 1, 1).toLowerCase()] = num++;
                            format = format.replace(format.substr(pos, 2), '(\\d{2})');
                            break;

                        case '%m': case '%d':
                            fields[format.substr(pos + 1, 1).toLowerCase()] = num++;
                            format = format.replace(format.substr(pos, 2), '(\\d{1,2})');
                            break;                                            

                        case '%Y':
                            fields['y'] = num++;
                            format = format.replace('%Y', '(\\d{4})');
                            break;                            
                    }
            }
            
            pos++; 
        }
        
        var reg = new RegExp('^' + format + '$');
        var val = reg.exec(str);
        
       
        if (!val || !val.length) return null;
        
        for (var i in fields)
        {
            fields[i] = val[fields[i]];            
            
            switch (i)
            {
                case 'm':
                    fields[i] --;
                    break;
                
                case 'y':
                    fields[i] = (fields[i] > 1900 ? fields[i] : fields[i] * 1 + 1900); // формат 105
                    fields[i] = (fields[i] > 1970 ? fields[i] : fields[i] * 1 + 100);  // формат 05
                    break;
            }
        }
        
        return new Date(
                            fields['y']  || 1970,
                            fields['m']  || 0,
                            fields['d']  || 1,
                            fields['hh'] || 0,
                            fields['mm'] || 0,
                            fields['ss'] || 0,
                            0
                       );
    }

    function add_zero(num)
    { 
        return ((num < 10) ? '0' : '') + num;
    } 

    function constr()
    {
             if ('undefined' == typeof(value))            
        {
            
            self.date = new Date;
        }
        else if ('string' == typeof(value))
        {
            self.date = self.StrToDate(value, format) || new Date();
        }
        else if ('number' == typeof(value))
        {
            self.date = new Date(value);
        }
        else if (Date.prototype.isPrototypeOf(value))
        {
            self.date = value;
        }
        else if (CDate.prototype.isPrototypeOf(value))
        {
            self.date = value.GetSource();
        }
        else
        {
            alert('Error, type of value ' + value + ' unknown');
        }
    }

    constr();
}



