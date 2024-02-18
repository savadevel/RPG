/* 
    Содержит класс CTableEdit, управления таблицами коррекций.
    Генерирует события:
        ON_BEFORE_SUBMIT -
        ON_ADD_INDEX
        ON_DEL_INDEX
        ON_ADD_FIELD
*/

$include('../js/', 'show_table_data.js');

function CTableEdit(tbl, prop)
{
    var self     = this;
    var hParam   = prop;
    var iExclude = null;
    var table    = tbl;    
        
    self.parent  = {};
    this.fields  = {}; // поля таблицы с их параметрами
    this.keys    = []; // список ключей таблицы
    this.index   = {}; // строки таблицы
    this.access  = prop.access || false; // права на изменения
    
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
            field.uniq   = ('undefined' == typeof(obj.uniq) || obj.uniq != 1) ? 0 : 1;
            field.type   = ('undefined' == typeof(obj.type)) ? 'unk' : obj.type;
            field.change = ('undefined' == typeof(obj.change) || obj.change != 1) ? 0 : 1;
            field.button = ('undefined' == typeof(obj.button) || obj.button != 1) ? 0 : 1;
            field.index  = obj.cellIndex;

            // сохраняем позицию ключей
            if (field.key) 
                self.keys[self.keys.length] = field.index;
                
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
        // проверяем уникальность key
        if (self.index[row.id]) 
            throw Error(0, "Внимание! Ошибка, идентификатор строки '" + row.id + "' не уникален.");

        // выделяем память для элементов нового ключа
        self.index[row.id]      = {};
        self.index[row.id].list = [];

        self.index[row.id].list.push(row);
        self.index[row.id].status = status;

        self.Dispatch('ON_ADD_INDEX', [row, self.index[row.id]]);
    }

    this.DelFromIndex = function(row)
    {
        if (!self.index[row.id] || self.index[row.id].list[0] != row)
            return;
        delete self.index[row.id];
        self.Dispatch('ON_DEL_INDEX', row);        
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

    this.IsUniq = function(field, value, row)
    {
        if (!self.fields[field])      return -1;
        if (!self.fields[field].uniq) return -1;

        var pos = self.fields[field].index;

        // цикл по строкам таблицы, проверяем уникальность значения
        for(var i = 1; i < table.rows.length; i++)
        {                
           if (table.rows(i).cells(pos).innerText == value && (!row || i != row.rowIndex)) return 0;
        }

        return 1;
    }
    
    this.canUnEdit = function(row)
    {
        return (self.index[row.id].status != 'ST_LOAD');
    }
    
    this.canDelete = function(row)
    {
        return (self.index[row.id].status != 'ST_ADD');                    
    }

    // закрытый метод добавления строки в таблицу
    this.AddRow = function (dlg, from, values)
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
            this.DelRow(dlg, from, values);
            throw err;
        }

        self.index[dlg.row.id].status = 'ST_ADD';
    }

    // закрытый метод удаления строки из таблицы
    this.DelRow = function (dlg, from, values)
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
        
        this.FillFields(dlg.row, values, 'ST_DELETE');
        self.index[dlg.row.id].status = 'ST_DELETE';        
    }

    this.EditRow = function (dlg, from, values)
    {
        // проверяем уникальность заданных значений
        for(var field in self.fields)
            if (!self.IsUniq(field, values[field], dlg.row)) 
                throw Error(0, "Внимание! Ошибка, значение '" + values[field] + "' не уникально.");            

        this.FillFields(dlg.row, values, 'ST_EDIT');
        
        // для строк созданных клиентом сохраняем признак новой строки
        self.index[dlg.row.id].status = (dlg.row.dummy ? 'ST_ADD' : 'ST_EDIT');
    }

    this.UnEditRow  = function(dlg, from, values)
    {
        // проверяем уникальность заданных значений
        for(var field in self.fields)
            if (!self.IsUniq(field, dlg.row.cells[self.fields[field].index].ovalue, dlg.row)) 
                throw Error(0, "Внимание! Ошибка, значение '" + dlg.row.cells[self.fields[field].index].ovalue + "' не уникально.");            

        if (dlg.row.dummy)        
            return del_row(dlg, from, values);
        
        this.FillFields(dlg.row, values, 'ST_LOAD');
        
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
            //  не создано клиентом
            if (!self.fields[field].change && !row.dummy)
                continue;

            // сохраняем значение на случай сброса редактирования 
            // только если имеем исходное значение
            if (!row.changed || row.changed != row) 
                cell.ovalue = (row.dummy) ? values[field] : cell.innerText;

            if ('undefined' == typeof(values[field]))
            {
                alert("Error, can't find field: " + field);
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

