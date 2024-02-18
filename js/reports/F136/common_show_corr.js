/* 
    Содержит класс CTableCorr, управления таблицами коррекций
    Генерирует события:
        ON_BEFORE_SUBMIT -
        ON_ADD_INDEX
        ON_DEL_INDEX
        ON_ADD_FIELD
*/

$include('../js/', 'show_table_data.js');

function CTableCorr(tbl, prop)
{
    var self     = this;
    var hParam   = prop;
    var table    = tbl;

    self.parent  = {};
    this.fields  = {}; // поля таблицы с их параметрами
    this.keys    = []; // список ключей таблицы
    this.index   = {}; // строки таблицы
    
    this.status  = 
        {
            ST_LOAD:  // загружена
                {
                    color:'',
                    cmd:'cmdUnk',
                    note:'загружена'
                },
            ST_EDIT:  // значение в строке изменено
                {
                    color:'#6699FF',
                    cmd:'cmdUpd',
                    note:'значение в строке изменено'
                },
            ST_DELETE:  // строка помечена как удаленная
                {
                    color:'#FF3300',
                    cmd:'cmdDel',
                    note:'строка помечена как удаленная'
                },
            ST_ADD: // новая строка
                {
                    color:'#66FF00',
                    cmd:'cmdIns',
                    note:'новая строка'
                }
        };

    if (table.rows.length < 1) 
        throw Error(0, 'Error, bad format of table for TableCorr');        

    function constr()
    {
        // добавляем обработчик события инициализации строки
        prop.events = prop.events ? prop.events.AddListener('ON_INIT_ROW', OnInitRow) : new CEventsHandler({'ON_INIT_ROW':[OnInitRow]});        

        // наследование от базового класса CEventsHandler
        self.parent = CEventsHandler; // наследуем свойства и методы                
        self.parent(prop.events);     // вызов родительского конструктора
        
        var obj, field, aKey;

        // чтение описания полей таблицы
        for(var i = 0; i < table.rows(0).cells.length; i++)
        {                   
            obj   = table.rows(0).cells(i);
            self.fields[obj.name] = {}
            field            = self.fields[obj.name];

            field.key    = ('undefined' == typeof(obj.key) || obj.key != 1) ? 0 : 1;
            field.type   = ('undefined' == typeof(obj.type)) ? 'unk' : obj.type;
            field.change = ('undefined' == typeof(obj.change) || obj.change != 1) ? 0 : 1;
            field.button = ('undefined' == typeof(obj.button) || obj.button != 1) ? 0 : 1;
            field.index  = obj.cellIndex;

            // сохраняем позицию ключей
            if (field.key) self.keys[self.keys.length] = field.index;

            // позиция в списке ключей
            if (field.key) field.order = self.keys.length - 1;
            
            self.Dispatch('ON_ADD_FIELD', self, obj, field);
        }
        
        // наследование от базового класса CTableData
        self.parent = CTableData; // наследуем свойства и методы           
        self.parent(tbl, prop);   // вызов родительского конструктора

        for(var i in this)
            self.parent[i] = this[i]; // сохраняем оригинальные свойства и методы базового класса на случай переопределения                                        
    }
    
    function OnInitRow(from, row)
    {           
        if (self.keys.length <= 0) 
            return;
        
        var aKey = [];

        // вычисляем ключь строки
        for(var j = 0; j < self.keys.length; j++)
        {                    
            aKey.push(row.cells(self.keys[j]).innerText);
        }

        row.id = aKey.join(':');

        self.AddToIndex(row, 'ST_LOAD');
    }    

    this.AddToIndex = function(row, status)
    {        
        if (!self.index[row.id])
        {
            // выделяем память для элементов нового ключа
            self.index[row.id]      = {};
            self.index[row.id].list = [];
        }

        self.index[row.id].list.push(row);
        self.index[row.id].status = status;

        self.Dispatch('ON_ADD_INDEX', self, row, self.index[row.id]);
    }

    this.GetIndex = function()
    {
        return self.index;
    }

    this.GetFields = function()
    {
        return self.fields;
    }

    this.GetKeys = function()
    {
        return self.keys;
    }

    this.GetTable = function()
    {
        return table;
    }

    this.DelFromIndex = function(row)
    {
        if (!self.index[row.id])
            return;
        
        for (var i = 0; i < self.index[row.id].list.length; i++)
        {
            if (self.index[row.id].list[i] != row)
                continue;
            self.index[row.id].list.splice(i, 1);        
            self.Dispatch('ON_DEL_INDEX', self, row);
            if (0 == self.index[row.id].list.length)
                delete self.index[row.id];
            break;
        }
    }    

    // отображение диалога с параметрами строки
    this.OnShow = function(dlg, values, argv)
    {
        var top = argv[0], left = argv[1], row = argv[2];
    
        for (var field in self.fields)
        {
            values[field] = row.cells(self.fields[field].index).innerText;
        }

        dlg.row = row;
        
        // сохраняем выделение строки       
        if (self.srow && self.srow == row) 
            self.srow = null;        

        // ищим строки с текущим ID
        if (!self.index[row.id])
            alert("Error, can't find row ID: " + dlg.row.id);
    }
    
    this.canUnEdit = function(row)
    {
        return (self.index[row.id].status != 'ST_LOAD');
    }
    
    this.canDelete = function(row)
    {
        return (self.index[row.id].status != 'ST_ADD');                    
    }    
    
    // метод добавляет строку в таблицу
    this.AddRow     = function(dlg, from, values)
    {
        // таблица должна быть не пустой
        var row   = table.tBodies[0].rows(0).cloneNode(true);
                
        row.dummy = true;
        dlg.row   = row;

        // стоку в таблицу
        table.tBodies[0].insertBefore(row, table.tBodies[0].firstChild);

        // установка значений полей
        this.FillFields(row, values, 'ST_ADD');

        try
        {
            // вызов инициализации параметров строки 
            // метод базового класса генерирует событие ON_INIT_ROW
            self.ReInitRows();
            // проверяем уникальность заданных значений
            for(var field in self.fields)
                if (!self.IsUniq(field, values[field], dlg.row)) 
                    throw Error(0, "Внимание! Ошибка, значение '" + values[field] + "' не уникально.");            
        }
        catch(err)
        {
            del_row(dlg, from, values);
            throw err;
        }

        self.index[dlg.row.id].status = 'ST_ADD';
    }

    // метод удаляет строку из таблицы
    this.DelRow     = function(dlg, from, values)
    {
        if (dlg.row.dummy)
        {
            // для строки которая была создана клиентом
            // удаляем такие строки
            var tbody = table.tBodies[0];
            // удаляем строку из индекса
            self.DelFromIndex(dlg.row);            
            // удаляем строку из таблицы
            tbody.removeChild(dlg.row);
            // освобождаем память
            delete dlg.row;
            self.ReInitRows();
            return;
        }
        
        for (var i = 0; i < self.index[dlg.row.id].list.length; i++)
            this.FillFields(self.index[dlg.row.id].list[i], values, 'ST_DELETE');            
        self.index[dlg.row.id].status = 'ST_DELETE';            
    }
    
    this.EditRow    = function(dlg, from, values)
    {
        for (var i = 0; i < self.index[dlg.row.id].list.length; i++)
            this.FillFields(self.index[dlg.row.id].list[i], values, 'ST_EDIT');
        
        // для строк созданных клиентом сохраняем признак новой строки
        self.index[dlg.row.id].status = (dlg.row.dummy ? 'ST_ADD' : 'ST_EDIT');
    }    
    
    this.UnEditRow  = function(dlg, from, values)
    {
        if (dlg.row.dummy)        
            return this.DelRow(dlg, from, values);     
        
        for (var i = 0; i < self.index[dlg.row.id].list.length; i++)
            this.FillFields(self.index[dlg.row.id].list[i], values, 'ST_LOAD');
     
        // для строк созданных клиентом сохраняем признак новой строки
        self.index[dlg.row.id].status = 'ST_LOAD';     
    }
    
    this.FillFields = function(row, values, state)
    {
        for (var field in self.fields)
        {
            var cell = row.cells(self.fields[field].index);

            if (self.fields[field].button && row.dummy)
                cell.style.backgroundColor = self.status['ST_ADD'].color;
            else if (self.fields[field].button)
                cell.style.backgroundColor = self.status[state].color;

            // обновляем значения полей только когда:
            //  поле поддерживает изменение
            //  и не созданая клиентом
            if (!self.fields[field].change && !row.dummy)
                continue;

            // сохраняем значение на случай сброса редактирования 
            // только если имеем исходное значение
            if (!row.changed || row.changed != row) 
                cell.ovalue = (row.dummy) ? values[field] : cell.innerText;

            if ('undefined' == typeof(values[field]))
            {
            //    alert("Error, can't find field: " + field);
                continue;
            }
            // сброс редактирования
            // только при сбросе значений
            else if ('ST_LOAD' == state) 
            {
                cell.innerText = cell.ovalue;
            }
            else if ('ST_EDIT' == state || 'ST_ADD' == state) // редактирование или добавление
            {
                cell.innerText = values[field];
            }
            else if ('ST_DELETE' == state) // строка для удаления
            {
            }                         
        }

        // ставим метку о редактировании строки
        row.changed = row;
    }
    
    // 
    this.OnHide = function(dlg, from, values, bRedraw)
    {
        try
        {
            switch(from)
            {
                default:
                    break;

                case 'btnSkip':
                    this.UnEditRow(dlg, from, values);
                    break;

                case 'btnAdd':
                    this.AddRow(dlg, from, values);
                    break;
                                    
                case 'btnApply':
                    this.EditRow(dlg, from, values);
                    break;
                    
                case 'btnDelete':
                    this.DelRow(dlg, from, values);
                    break;                    
            }            

            if (bRedraw) self.ReDraw();
        }
        catch(err)
        {
            alert(err.message);
            return false;
        }

        return true;
    }  

    // добавление в форму строк, которые изменены (hidden) и отсылка её на сервер
    this.Submit = function(form)
    {
        var bRet    = false;
        var hSend   = {};
        var hStatus = {};
        
        // формируем список измененых строк для отправки на сервер
        for (var i in self.index)
        {
            if (self.index[i].status == 'ST_LOAD') 
                continue;
            
            hSend[i]       = document.createElement('<input name=' + (self.status[self.index[i].status].cmd) + '>');
            hSend[i].type  = 'hidden';
            hSend[i].value = '';

            hStatus[hSend[i].name] = ('undefined' == typeof(hStatus[hSend[i].name]) ? 1 : hStatus[hSend[i].name] + 1) ;
            hStatus['cmdAll']      = ('undefined' == typeof(hStatus['cmdAll'])      ? 1 : hStatus['cmdAll'] + 1) ;
            
            // цикл по полям для отсылки
            for (var field in self.fields)
            {
                // отсылаются только ключи и изменяемые значения
                if (1 != self.fields[field].key && 1 != self.fields[field].change)
                    continue;
                hSend[i].value += field + ':' + (self.index[i].list[0].cells(self.fields[field].index).innerText) + ';';
            }
        }
        
        if (hStatus['cmdAll'] && hStatus['cmdAll'] > 0)
        {
            if (confirm("Внимание, следующее число записей помечено как:\n" 
                    + (hStatus['cmdDel'] ? hStatus['cmdDel'] : 0)
                    + " - для удаления\n"
                    + (hStatus['cmdIns'] ? hStatus['cmdIns'] : 0)
                    + " - для добавления\n"
                    + (hStatus['cmdUpd'] ? hStatus['cmdUpd'] : 0)
                    + " - для обновления\n\n"
                    + "Продолжить?"))
            {            
                for (var obj in hSend)
                {
                    form.appendChild(hSend[obj]);
                }
                
                self.Dispatch('ON_BEFORE_SUBMIT', self);

                try
                {                
                    form.submit();
                    bRet = true;
                }
                catch(err)
                {
                    // востанавливаем исходный набор полей в форме, при ошибках
                    // возможных при использовании события onbeforeunload
                    // (порождает диалог подтверждения, если нажать в нем отмена то происходит ошибка)
                    for (var obj in hSend)
                    {
                        form.removeChild(hSend[obj]);
                    }                                
                }                
            }

            return bRet;
        }
        
        alert('Нет записей подлежащих модификации, укажите хотя бы одну запись\nи повторите операцию');     
        return bRet;
    }
    
    // 
    this.IsChange = function()
    {
        for (var i in self.index)
        {
            if (self.index[i].status != 'ST_LOAD') 
                return 1;
        }
        
        return 0;
    }

    constr();
}

function CTableCorrEx(tbl, prop)
{
    var self     = this;
    var hParam   = prop;
    var iExclude = null;
    var table    = tbl;

    self.parent    = {};
    this.sub_keys  = [];
    this.sub_index = {};
    
    // добавляем обработчики событий
    prop.events = prop.events || new CEventsHandler();
    prop.events.AddListener('ON_ADD_FIELD', OnAddField);
    prop.events.AddListener('ON_ADD_INDEX', OnAddIndex);
    prop.events.AddListener('ON_DEL_INDEX', OnDelIndex);
    this.parent = CTableCorr; // наследуем свойства и методы
    this.parent(tbl, prop);   // вызов родительского конструктора

    for(var i in this)
        self.parent[i] = this[i]; // сохраняем оригинальные свойства и методы базового класса на случай переопределения

    // обработчик события базового класса, новое поле  
    // с событием связаны элементы
    // ссылка на поле таблицы, второй ссылка на поле-описание
    function OnAddField(from, col, field)
    {
        if (field.key == 1 && hParam.sub_key.exclude != col.name) 
        {
            self.sub_keys[self.sub_keys.length] = field.index;
        }
        else if (hParam.sub_key.exclude == col.name)
        {
            iExclude = field.index;
        }
    }

    // обработчик события базового класса, новый индекс 
    // с событием связаны элементы
    // ссылка на строку, второй ссылка на описание индекса
    function OnAddIndex(from, row, pindex)
    {
        if (self.sub_keys.length <= 0)
            return;

        var aKey = [];            

        if (!row.sub_id)
        {
            // вычисляем ключь строки
            for(var j = 0; j < self.sub_keys.length; j++)
            {                    
                aKey.push(row.cells(self.sub_keys[j]).innerText);
            }

            row.sub_id = aKey.join(':');

            if (!self.sub_index[row.sub_id]) // выделяем память для элементов нового ключа                
                self.sub_index[row.sub_id] = {}; // строки с одинаковым значением sub_id
        }

        var exclude = row.cells[iExclude].innerText;

        if (!self.sub_index[row.sub_id].alredy) // выделяем память для элементов нового exclude
            self.sub_index[row.sub_id].alredy = {}; // строки с одинаковым значением sub_id и разным exclude

        if (!self.sub_index[row.sub_id].alredy[exclude])
            self.sub_index[row.sub_id].alredy[exclude] = [];
        
        // для строк с установленным признаком, сделано клиентом, жестко
        // проставлям состояние в ST_ADD
        if (row.dummy) 
            pindex.status = 'ST_ADD';        
            
        // доступ по sub_id и exclude
        self.sub_index[row.sub_id].alredy[exclude].push(row);
    }
    
    function OnDelIndex(from, row)
    {
        // значение исключаемого ключевого поля
        var exclude = row.cells[iExclude].innerText;
        
        if (!self.sub_index[row.sub_id] || !self.sub_index[row.sub_id].alredy[exclude])
            return;
        
        // cтрока была создана клиентом
        // удаляем такие строки из exclude
        for (var i = 0; i < self.sub_index[row.sub_id].alredy[exclude].length; i++)
            if (self.sub_index[row.sub_id].alredy[exclude][i] == row)
                self.sub_index[row.sub_id].alredy[exclude].splice(i, 1);
        
        if (0 == self.sub_index[row.sub_id].alredy[exclude].length)
            delete self.sub_index[row.sub_id].alredy[exclude];
    }

    // отображение диалога с параметрами строки
    this.OnShow = function(dlg, values, argv)
    {
        var top     = argv[0], left = argv[1], row = argv[2];        
        var link    = row.cells[self.parent.fields[hParam.sub_key.link].index].innerText;  // значение связанного поля
        var exclude = row.cells[iExclude].innerText; // текущее значение исключаемого ключевого поля
        var val     = hParam.sub_key.val[link];      // допустимые значения исключаемого ключевого поля
        var sub_id  = row.sub_id;                    // идентификатор текущей строки
        var obj     = dlg.GetObject(hParam.sub_key.exclude); // объект содержит допустимые значения для текущей строки, не представленные на странице

        self.parent.OnShow(dlg, values, argv);
        
        // сбрасываем список
        obj.options.length = 0;

        // первый элемент списка из текущей строки
        obj.options[0]     = new Option(exclude, exclude);

        // в цикле добавляем значения не представленные на странице
        for (var i = 0; i < val.length; i++)
        {
            if (self.sub_index[sub_id].alredy[val[i]]) continue;
            obj.options[obj.options.length] = new Option(val[i], val[i]);
        }        
    }
    
    this.DelRow    = function (dlg, from, values)
    {
        if (!dlg.row.dummy || !self.sub_index[dlg.row.sub_id])
            return self.parent.DelRow(dlg, from, values);
        
        var sub_id  = dlg.row.sub_id;
        // значение исключаемого ключевого поля
        var exclude = values[hParam.sub_key.exclude]; 

        while (self.sub_index[sub_id].alredy[exclude])
        {
            dlg.row = self.sub_index[sub_id].alredy[exclude][self.sub_index[sub_id].alredy[exclude].length - 1];
            self.parent.DelRow(dlg, from, values);
        }
    }
    
    this.EditRow   = function (dlg, from, values)
    {
        // значение исключаемого ключевого поля
        var exclude = values[hParam.sub_key.exclude]; 
        
        if (self.sub_index[dlg.row.sub_id].alredy[exclude])
            // если такое значение имеется на странице
            return self.parent.EditRow(dlg, from, values);
                
        // нужно создать новую запись (строку), на основе текущей
        var aKey   = []; // в массив собираем новый ключ
        var sub_id = dlg.row.sub_id;

        // собираем новый ключ
        for(var i = 0; i < self.parent.keys.length; i++)
            aKey.push(iExclude == self.parent.keys[i] ? exclude : dlg.row.cells(self.parent.keys[i]).innerText);

        // Новый ID
        var id    = aKey.join(':'); 
        // фиксируем размер массива, новые строки добавляются в конец массива
        var list  = self.parent.index[dlg.row.id].list;        
        var tbody = table.tBodies[0];
        
        // создаём новые записи, под новый exclude, для каждой строки с одинаковым id
        for (var i = 0; i < list.length; i++)
        {
            var new_row    = list[i].cloneNode(true);
            new_row.id     = id;   
            new_row.sub_id = sub_id;  
            new_row.dummy  = true;                // помечаем строку как созданую клиентом
            tbody.insertBefore(new_row, list[i]); // добаляем в таблицу
            
            this.FillFields(new_row, values, 'ST_ADD');
        }

        // вызов инициализации параметров строк         
        self.ReInitRows();
    }   
} 


function CTransferCorrections(tbl, prop)
{
    var self        = this;
    var hParam      = prop;
    var oMngTable   = tbl;
    var aKeys       = [];

    function constr()
    {        
        var fields = oMngTable.GetFields();

        for (var i=0; i < hParam.keys.length; i++)
        {
            if (fields[hParam.keys[i]] && fields[hParam.keys[i]].key)
                aKeys.push(fields[hParam.keys[i]].order);
        }

    }


    this.Apply = function ()
    {
        var index  = oMngTable.GetIndex();
        var fields = oMngTable.GetFields();
        var groups = {};
        var iCorr  = 0;

        // собираем коррекции по группам
        for (var i in index)
        {
            var t    = i.split(':');
            var aKey = [];
            var key  = '';

            // вычисляем ключ текущей коррекции
            for (var k = 0; k < aKeys.length; k++)
                aKey.push(t[aKeys[k]]);      

            key = aKey.join(':');

            if (!groups[key])
                groups[key] = {base:null, list:[]};

            // добавляе строки в группу текущей коррекции
            for (var l=0; l < index[i].list.length; l++)
            {
                var row = index[i].list[l];

                groups[key].list.push(row);

                // ищим коррекцию - образец
                if (row.src != hParam.correction.value)
                    continue;

                // допустима только одна коррекция
                if (groups[key].base)
                {
                    alert('Ошибка, невозможно выполнить перенос коррекций для текущего массива данных т.к. имеются дублирующие коррекции. Имеется [' + groups[key].base.id + '] добавляется [' + row.id + '].');
                    return;
                }                

                // найдена коррекция - образец
                groups[key].base = row;
            }

        }

        // переносим коррекции 
        for (var g in groups)
        {
            // должна быть базовая коррекция по которой корректируем все строки принадлежащие текущей группе
            if (!groups[g].base || groups[g].list.length < 1)
                continue;

            var hValues = {};

            // базовые значения
            for (var f in fields)
            {
                hValues[f] = groups[g].base.cells[fields[f].index].innerText;                
            }


            for (var l=0; l < groups[g].list.length; l++)
            {
                if (groups[g].list[l] == groups[g].base)
                    continue;
                var dlg = {row:groups[g].list[l]};
                oMngTable.EditRow(dlg, null, hValues);
                iCorr ++;
            }            

        }

        alert('Операция исполнена успешно, перенесено ' + iCorr + ' коррекций');

        return;
    }

    constr();

} 
