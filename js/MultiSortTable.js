/*
    Содержит класс многоуровневой сортировки   
        CMultiSortingOfTable(table, name, prop)
        где
            tbl  - таблица в стиле:
                <thead>
                    <tr>
                        <th name='cln_desc'>
                            <table><thead><tr>
                                <th id='sort_desc'>Описание</th>
                            </tr></thead></table>
                        </th>
                     ...
            name - имя формы сортировки
            prop - хеш дополнительных параметров 
                name - имя параметра в форме передаваемой на сервер, который будет содержать
                       указания по сортировке
                form - ссылка на форму в которую будут добавлен параметр strOrder указывающий 
                       порядок сортировки
    Генерирует события:
        ON_MSORT_BEFORE_SORTING -    
                
*/

$include('../js/', 'utils.js');
$include('../js/', 'dialog.js');

function CMultiSortingOfTable(tbl, name, prop)
{
    this.name        = prop.name || 'strOrder';
    this.form        = prop.form;

    var hParam       = prop;
    var dlgMultiSort = new MyDialog('_' + name, {desc:'Многоуровневая сортировка:', width:420, height:220});
    var table        = tbl;
    var aFields      = [];
    var self         = this;
    var oFields      = null;
    var oSorting     = null;
    var oButton      = null;
    
    function constr()
    {
        // наследование от базового класса CEventsHandler
        self.parent = CEventsHandler; // наследуем свойства и методы                
        self.parent(hParam.events);     // вызов родительского конструктора           
        
        // список параметров колонок, 
        var cols = table.getElementsByTagName('COL');

        // чтение описания полей таблицы
        for(var i = 0; i < table.rows(0).cells.length; i++)
        {
            // если колонка не отображается, пропускаем её
            if(i < cols.length && cols[i].style.display == 'none')
                continue;

            // получаем вложенную таблицу
            var tbl  = table.rows(0).cells(i).getElementsByTagName('table');
            var name = table.rows(0).cells(i).name;
           
            // цикл по полям вложенной таблицы
            for (var j = 0; j < tbl[0].rows(0).cells.length; j++)
            {
                var cell = tbl[0].rows(0).cells(j);
                
                if (cell.id != 'sort_desc') continue;
                
                aFields[aFields.length] = {id:name, name:cell.innerText};                
            }            
        }
        
        // создание элементов диалога
        dlgMultiSort.AddObject('label', {val:'поля:',  width:170, top:5});
        oFields = dlgMultiSort.AddObject('list',  {id:'lstFields', val:aFields,  width:170, size:7, top:25});
        
        dlgMultiSort.AddObject('button', {id:'btnAdd',   title:'Добавить в список сортируемых полей', val:'&gt;',  height: 20, width:20, top:50, left:180, exe:function(){add()}});
        dlgMultiSort.AddObject('button', {id:'btnDel',   title:'Удалить из списока сортируемых полей', val:'&lt;',  height: 20, width:20, top:80, left:180, exe:function(){del()}});
        
        dlgMultiSort.AddObject('label', {val:'сортировка:',  width:170, top:5, left:210});
        oSorting = dlgMultiSort.AddObject('clist',  {id:'lstSortOrder', val:[],  width:170, height:117, top:25, left:210});

        dlgMultiSort.AddObject('button', {id:'btnUp',     val:'+', title:'Переместить поле выше (очередность сортировки)', height: 20, width:20, top:50, left:385, exe:function(){up()}});
        dlgMultiSort.AddObject('button', {id:'btnDown',   val:'-', title:'Переместить поле ниже (очередность сортировки)', height: 20, width:20, top:80, left:385, exe:function(){down()}});
        
        dlgMultiSort.AddObject('checkbox', {id:'chkAsc',  left:205, top:152, readonly:true});
        dlgMultiSort.AddObject('label',    {val:'прямая', width:60, top:157, left:227});

        dlgMultiSort.AddObject('checkbox', {id:'chkDesc',    left:287, top:152, readonly:true, checked:true});
        dlgMultiSort.AddObject('label',    {val:'обратная', width:60, top:157, left:310});        
        
        oButton = dlgMultiSort.AddObject('button', {id:'btnApply',  val:'Сортировать',  height: 25, width:100, top:155, left:5,
                                          exe:function() {submit();}
                                         }); 
        dlgMultiSort.AddObject('button', {id:'btnCancel', val:'Отмена',      height: 25, width:80,  top:155, left:110,
                                          exe:function() {dlgMultiSort.Hide()}
                                         }); 
        if (!self.form)                                         
        {               
            self.form = document.createElement('FORM')
            self.form.method = 'post';
            self.form.target = '';
            document.body.appendChild(self.form);
        }
    }
    
    this.Show = function()
    {
        dlgMultiSort.Show({});
    }    

    this.IsShow = function()
    {
        return dlgMultiSort.IsShow();
    }

    function up()
    {
        var posUp = oSorting.GetSelect();
        
        if (posUp < 0) return;
        
        var posDown = ((posUp - 1) < 0 ? oSorting.GetLength() - 1 : posUp - 1);

        oSorting.Swap(posUp, posDown);        
    }    

    function down()
    {
        var posDown = oSorting.GetSelect();
        
        if (posDown < 0) return;
        
        var posUp = (posDown + 1)%(oSorting.GetLength());

        oSorting.Swap(posDown, posUp);        
    }    

    function add()
    {
        if (oFields.selectedIndex < 0) return;
        
        var value = {};
        
        value.name    = oFields.options[oFields.selectedIndex].innerText;
        value.id      = oFields.options[oFields.selectedIndex].value;
        value.checked = false;
        
        oFields.removeChild(oFields.options[oFields.selectedIndex]);

        oSorting.AddLine(value);
    }    

    function del()
    {
        var index = oSorting.GetSelect();
        
        if (index < 0) return;
        
        var value = oSorting.GetValue(index);
        
        oFields.options[oFields.options.length] = new Option(value.name, value.id);
        oSorting.DelLine(index);        
    }    
    
    function submit()
    {
        var len = oSorting.GetLength();

        if (len <= 0)
        {
            alert('Ошибка, нужно выбрать хотя бы одно поле!');
            return;
        }
        
        var objOrder = self.form.item(self.name);

        if (!objOrder)
        {
            self.form.appendChild(document.createElement('<input type=hidden name="' + self.name + '">'));
            objOrder = self.form.lastChild;            
        }

        objOrder.value = '';

        for (var i = 0; i < len; i++)
        {
            var value = oSorting.GetValue(i);
            objOrder.value += '[' + value.id + '] ' + (value.checked ? 'desc' : 'asc') + '&';
        }
        
        self.Dispatch('ON_MSORT_BEFORE_SORTING', self);            
       
        try
        {    
            self.form.submit();
            oButton.disabled = true;
        }
        catch (e)
        {
            // востанавливаем исходный набор полей в форме, при ошибках
            // возможных при использовании события onbeforeunload
            // (порождает диалог подтверждения, если нажать в нем отмена то происходит ошибка)
            self.form.removeChild(objOrder);        
        }
    }
    
    constr();
}    
