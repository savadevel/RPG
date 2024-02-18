/* 
    Содержит класс CTableData, через который производится управление представлением таблицы
    Генерирует события:
        ON_INIT_ROW -    
*/

$include('../js/', 'stdtypes.js');
$include('../js/', 'utils.js');

function CTableData(tbl, prop)
{
    var hParam  = prop;
    var table   = tbl; // объект таблица
    var self    = this;

    this.frow   = 'undefined' == typeof(hParam.frow) ?  1 : hParam.frow; // первая строка в таблице
    this.srow   = null; // ссылка на текущую строку
    this.colors = 
        {
            sline:'#ffffcc',             // цвет выбранной строки
            line:['#E8EFF5', '#FFFFFF']  // цвет строки
        };

    if (table.rows.length < 1) 
        throw Error(0, 'Error, bad format of table for TableData');        
        
    function constr()
    {        
        // наследование от базового класса CEventsHandler
        self.parent = CEventsHandler; // наследуем свойства и методы                
        self.parent(prop.events);     // вызов родительского конструктора           
        self.ReInitRows();
    }

    this.ReInitRows = function ()
    {
        // цикл по строкам таблицы, форматируем передставление
        for(var i = self.frow; i < table.rows.length; i++)
        {
            InitRow (table.rows(i));

            if (self.srow && self.srow == table.rows(i))
                continue;                    
        }
    }
    
    this.ReDraw = function ()
    {            
        // цикл по строкам таблицы, форматируем передставление
        for(var i = self.frow; i < table.rows.length; i++)
        {
            if (self.srow && self.srow == table.rows(i))
                continue;        
            table.rows(i).style.backgroundColor = self.colors.line[i%2];            
        }
    }

    function InitRow (row)
    {
        row.style.backgroundColor = self.colors.line[row.rowIndex%2];

        if (row.initialized && row.initialized == row) 
            return false;        

        row.initialized           = row;         
        // клик по строке выделяет её
        row.onclick               = 
            function()
            {
                if (self.srow)
                {
                    self.srow.style.backgroundColor = self.colors.line[self.srow.rowIndex%2];
                    
                    if (self.srow == this)
                    {
                        self.srow = null;
                        return;
                    }
                }
                
                this.style.backgroundColor = self.colors.sline
                self.srow = this;
            }; 
        
        self.Dispatch('ON_INIT_ROW', self, row);

        return true;
    }

    constr();
}
