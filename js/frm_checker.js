/*
    Содержит класс проверки формы. Допустипы проверки
    
    TheLenText         - длина значения поля не превышает max_size
    TheContTextIs      - значение текстового поля есть value
    TheContTextIsNot   - значение текстового поля не есть value
    TheSelectItemMore  - выбрано неменее указанного (selected) числа значений 
    TheFormatDate      - проверка формата (format) даты
    TheRangeDate       - проверка диапазона дат, левая граница не превышает правую
    TheCheckedItemMore - выбрано неменее указанного (checked) числа полей
*/


/*
   Пакет функций-правил, каждая из которых отвечает
   за единственную обработку единственного поля.
*/
function CheckFunctions()
{
    ////////////////////////////////////////////////////////////////
    // короткий текст
    ////////////////////////////////////////////////////////////////
    this.TheLenText = function(field, opt) 
    {
        return ((field.value+'').length <= opt.max_size);
    };

    ////////////////////////////////////////////////////////////////
    // короткий текст
    ////////////////////////////////////////////////////////////////
    this.TheTextIsNotEmpty = function(field, opt) 
    {
        return ((field.value+'').length > 0);
    };
    
    ////////////////////////////////////////////////////////////////
    // значение текстового поля не есть (одно из если массив, хеша или
    // скаляр)
    ////////////////////////////////////////////////////////////////
    this.TheContentIsNot = function(field, opt) 
    {
        return !(this.TheContentIs(field, opt));
    }
    
    ////////////////////////////////////////////////////////////////
    // значение текстового поля есть (одно из если массив, хеша или
    // скаляр)
    ////////////////////////////////////////////////////////////////
    this.TheContentIs = function(field, opt) 
    {
        var type = typeof(opt.value);
        
        if (type == 'undefined')
        {
            return false;
        }
        else if (type != 'object')
        {
            return (field.value == opt.value);
        }
        else if (opt.value.constructor == [].constructor)
        {
            for(var i = 0; i < opt.value.length; i++)
                if (this.TheContentIs(field, {value:opt.value[i], item:opt.item}))
                    return true;
        }
        else if (opt.value.constructor == {}.constructor)
        {
            if (typeof(opt.item) == 'undefined')
                return false            

            for(var i in opt.value)
            {
                if (!(i == opt.item || 'object' == typeof(opt.value[i])))
                    continue;                
                // совпало имя свойства или значение объект
                if (this.TheContentIs(field, {value:opt.value[i], item:opt.item}))
                    return true;
            }
        }
        
        return false;
    }

    ////////////////////////////////////////////////////////////////
    // значение поля есть
    ////////////////////////////////////////////////////////////////
    this.TheValueIs = function(field, opt) 
    {
        return (opt.ext ? opt.ext(field.value) : true);
    };

    ////////////////////////////////////////////////////////////////
    // выбрано не менее указанного числа значений
    ////////////////////////////////////////////////////////////////
    this.TheSelectItemMore=function(select, opt) 
    {
        var iCount = 0;

        for (var i = 0; i < select.options.length; i++)
        {
            iCount += (select.options[i].selected) ? 1 : 0;
            if (iCount == opt.selected) return true;
        }

        return false;
    }

    ////////////////////////////////////////////////////////////////
    // выбрано не более указанного числа значений в спискe
    ////////////////////////////////////////////////////////////////
    this.TheSelectItemNoMore=function(selects, opt) 
    {
        var iCount = 0;

        for (var i = 0; i < selects.options.length; i++)
        {
            iCount += (selects.options[i].selected) ? 1 : 0;
            if (iCount >= opt.selected) return false;
        }

        return true;
    }


    ////////////////////////////////////////////////////////////////
    // выбрано не менее указанного числа значений в нескольких списках
    ////////////////////////////////////////////////////////////////
    this.SelectsItemMore=function(selects, opt) 
    {
        var iCount = 0;

        for (var j = 0; j < selects.length; j++)
        {
            for (var i = 0; i < selects[j].options.length; i++)
            {
                iCount += (selects[j].options[i].selected) ? 1 : 0;
                if (iCount == opt.selected) return true;
            }
        }

        return false;
    }

    ////////////////////////////////////////////////////////////////
    // выбрано указанное число значений в нескольких списках
    ////////////////////////////////////////////////////////////////
    this.SelectsItemExactly=function(selects, opt) 
    {
        var iCount = 0;

        for (var j = 0; j < selects.length; j++)
        {
            for (var i = 0; i < selects[j].options.length; i++)
            {
                iCount += (selects[j].options[i].selected) ? 1 : 0;
            }
        }    

        return (iCount == opt.selected);
    }
    
    ////////////////////////////////////////////////////////////////
    // выбрано не менее указанного числа значений
    ////////////////////////////////////////////////////////////////
    this.TheCheckedItemMore=function(checked, opt) 
    {
        var iCount = 0;
        
        if (typeof(checked) == 'undefined')
        {
            iCount = 0;
        }
        else if (typeof(checked.length) == 'undefined')
        {
            iCount = (checked.checked ? 1 : 0);
        }
        else
        {
            for (var i = 0; i < checked.length; i++)
            {
                iCount += (checked[i].checked ? 1 : 0);
                if (iCount == opt.checked) break;
            }            
        }


        return (iCount == opt.checked);
    }

    ////////////////////////////////////////////////////////////////
    // выбрано не указанное числа значений
    ////////////////////////////////////////////////////////////////
    this.CheckedsItemExactly=function(checkeds, opt) 
    {
        var iCount = 0;

        for (var j = 0; j < checkeds.length; j++)
        {                   
            var checked = checkeds[j];

            if (typeof(checked) == 'undefined')
            {
                continue;
            }
            else if (typeof(checked.length) == 'undefined')
            {
                iCount += (checked.checked ? 1 : 0);
                continue;
            }
            for (var i = 0; i < checked.length; i++)
            {
                iCount += (checked[i].checked ? 1 : 0);
            }
        }

        return (iCount == opt.checked);
    }

    ////////////////////////////////////////////////////////////////
    // проверка формата даты
    ////////////////////////////////////////////////////////////////
    this.TheFormatDate=function(field, opt)
    {
        opt.format = (opt.format ||  /^(\d{1,2})\.(\d{1,2})\.(\d{4})$/);
        
        if (!(opt.format.test(field.value)))
        {
            return false;
        }        
        
        opt.format.exec(field.value);

        return new Date(RegExp["$3"], RegExp["$2"] - 1, RegExp["$1"], 0, 0, 0);;
    }

    ////////////////////////////////////////////////////////////////
    // проверка диапазона дат, левая граница не превышает правую
    ////////////////////////////////////////////////////////////////
    this.RangeDate=function(oLeftDate, opt)
    {
        var lDate, rDate, cDate;

        if (false == (lDate = this.TheFormatDate(oLeftDate, opt)))
        {
            return false;
        }

        if (false == (rDate = this.TheFormatDate(opt.oRightDate, opt)))
        {
            return false;
        }

        var cDate;
        cDate = new Date((new Date()).getYear(), (new Date()).getMonth(), (new Date()).getDate(), 0, 0, 0);
        
        return (opt.ext ? opt.ext(lDate, rDate, cDate) : true);
    }

}

/*
    конструктор контроллёра корректности ввода формы
*/
function FormChecker() 
{
    // скрытый массив "ссылок" на правила
    // Каждая "ссылка" будет иметь вид:
    // {       Rule: "Имя ПРАВИЛА, в экземляре комплекта правил",
    //   WorkObject: "Указатель на обрабатываемый объект-элемент формы",
    // ErrorMessage: "Сообщение об ошибке, если данное правило не выполняется"
    // }
    var Rules               = new Array();

    // определим сообщение об ошибке по умолчанию
    // (скрытое свойство)
    var DefaultErrorMessage = "Ошибка!";

    // ... и открытые методы его переопределения
    this.SetDefaultErrorMessage=function(NewErrorMessage) 
    {
        // если NewErrorMessage пуст или неопределён, то 
        // сообщение по умолчанию не менять
        DefaultErrorMessage = NewErrorMessage || DefaultErrorMessage;
    }

    this.GetDefaultErrorMessage=function() 
    {
        return DefaultErrorMessage;
    }
    
    // открытый метод добавления "ссылок" на правила
    this.AddRule            = function (Rule, WorkObject, Options, ErrorMessage) 
    {
        Rules[Rules.length] = 
        {
            'Rule'          :Rule,
            'WorkObject'    :WorkObject,
            'Options'       :Options, 
            // если сообщение не определено, то поставим вместо 
            // него системное сообщение
            'ErrorMessage'  :ErrorMessage || DefaultErrorMessage
        };
    }

    // открытый метод проверки выполнения всех условий корректности формы
    this.CheckIt            = function (CheckFunctionsSET) 
    {
        // по умолчанию форма введена корректно
        var Flag = true;
        
        // последовательно проверяем все заявленные правила на корректность.
        for (var i = 0; i < Rules.length; i++) 
        {
            // вызываем заявленное правило Rules[i].Rule для объекта Rules[i].WorkObject
            Flag = Flag && CheckFunctionsSET[Rules[i].Rule](Rules[i].WorkObject, Rules[i].Options);
            
            // Если возникла ошибка, сообщаем об этом пользователю и заканчиваем работу
            if (Flag==false) 
            {
                Message(Rules[i]);
                break;
            }
        }

        // возвращаем разрешение продолжить посыл формы
        return Flag;
    }
    
    // скрытый метод сообщения пользователю об ошибке
    function Message(Rule) 
    {
        alert(Rule.ErrorMessage);
        try
        {
            if (Rule.WorkObject.length || Rule.WorkObject.disabled) return;        
            Rule.WorkObject.select();
            Rule.WorkObject.focus();
        }
        catch(e)
        {
        }
    }
}