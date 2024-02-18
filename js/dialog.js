/*
    Содержит класс диалог

    MyDialog(name, param) - объект диалог, строится на основе form

    где
        name  - название диалога (формы), обязательный параметр
        param - хешь параметров диалога
            owner  - родительский объект
            height - высота диалога (default is '200')
            width  - ширина диалога (default is '350')
            desc   - title диалога (default is '')
            target - для form (default is '')
            action - для form (default is 'document.URL')
            method - для form (default is 'post')

    Генерирует события:
        ON_DLG_SHOW        -
        ON_DLG_HIDE        -
        ON_DLG_AFTER_HIDE  -
            
*/

$include('../js/calendar/', 'calendar.js');
$include('../js/', 'stdtypes.js');
$include('../js/', 'utils.js');

function CCheckList(id, param)
{
    var div   = document.createElement('DIV');
    var table = document.createElement('TABLE');
    var self  = this;

    var hParam = {};
    
    hParam.height   = param.height || 100;
    hParam.width    = param.width  || 50;
    hParam.id       = id;
    hParam.multiple = param.multiple || false;
    hParam.title    = param.title  || '';

    function constr()
    {
        div.title = hParam.title;
                
        div.style.height   = hParam.height + 'px';
        div.style.width    = hParam.width + 'px';
        div.style.position = 'absolute';
        
        div.style.backgroundColor = '#FFFFFF';
        div.style.borderStyle     = 'inset';
        div.style.borderWidth     = '2px';
        div.style.borderColor     = 'activeborder';
        div.style.overflow        = 'auto';
        
        table.width  = '100%';
        //table.height = '100%';
        table.style.cursor = 'default';
        
        div.appendChild(table);

        self.SetValues(param.val);        
    }
        
    // values =  [checked:true, name:'описание', id:'ID строки'}, ...]
    this.SetValues = function(values)
    {
        self.ClearAll();

        for (var i = 0; i < values.length; i++)
        {
            self.AddLine(values[i], i);
        }         
    }
    
    // value =  {checked:true, name:'описание', id:'ID строки'}
    this.AddLine = function(value, index)
    {
        index = index || table.rows.length;    
    
        var tr  = table.insertRow(index);
        var chk = document.createElement('<INPUT type=checkbox id="' + hParam.id + '" name="' + value.id + '" ' + ((value.checked || false) ? 'checked' : '') + '>');

        tr.select = false;
        
        tr.insertCell();
        tr.insertCell();
        
        chk.style.width  = 22 + 'px';
        chk.style.height = 22 + 'px';

        tr.firstChild.width = '30px';
        tr.firstChild.style.textAlign = 'center';
        
        tr.lastChild.style.textAlign = 'left';
                
        tr.firstChild.appendChild(chk);
        tr.lastChild.innerText = value.name;       
        tr.lastChild.onclick = function() {self.SetSelect(tr.rowIndex);};
        
        tr.lastChild.style.fontFamily = 'Courier New';
    }

    this.DelLine = function(index)
    {
        if (index < 0 || table.rows.length == 0) return;
        table.deleteRow(index);
    }    
    
    this.ClearAll = function()
    {
        while(table.lastChild)
        {
            table.removeChild(table.lastChild);
        }
    }

    this.GetHandle = function()
    {
        return div;
    }
    
    this.SetSelect = function(index)
    {
        for (var i = 0; i < table.rows.length; i++)
        {
            if (hParam.multiple && i != index) continue;
        
            table.rows(i).select = (i != index ? false : !table.rows(i).select);

            if (table.rows(i).select)
            {
                table.rows(i).style.backgroundColor = 'highlight';
                table.rows(i).lastChild.style.color = '#FFFFFF';            
            }
            else
            {
                table.rows(i).style.backgroundColor = '#FFFFFF';
                table.rows(i).lastChild.style.color = '#000000';            
            }
        }
    }

    this.GetSelect = function()
    {
        for (var i = 0; i < table.rows.length; i++)
        {
            if (table.rows(i).select) return i;
        }
        
        return -1;
    }
    
    this.GetValue = function(index)
    {
        var tr  = table.rows(index);
        var chk = tr.firstChild.firstChild;        
        var ret = {};
        
        ret.name    = tr.lastChild.innerText;
        ret.checked = chk.checked;
        ret.id      = chk.name;

        return ret;
    }
    
    this.Swap = function(posUp, posDown)
    {
        // IE сбрасывает значения checkbox, так что сохраняем
        var bUp = table.rows(posUp).firstChild.firstChild.checked,
            bDown = table.rows(posDown).firstChild.firstChild.checked;
        
        table.rows(posUp).swapNode(table.rows(posDown));
        
        table.rows(posDown).firstChild.firstChild.checked   = bUp;
        table.rows(posUp).firstChild.firstChild.checked = bDown;
    }
    
    this.GetLength = function()
    {
        return table.rows.length;
    }
    
    constr();
}

function DlgObject()
{
    var store = {};
    var self  = this;
    
    // добавление нового объекта в коллекцию
    this.AddObject = function(name, object)
    {
        if (typeof(name) == 'undefined') return;        
        store[name] = object;
        return this.GetObject(name);
    }

    // доступ к элементу коллекции
    this.GetObject = function(name)
    {
        return store[name];
    }

    // удаление элемента из коллекции
    this.DelObject = function(name)
    {
        var ret = store[name];
        store[name] = undefined;
        return ret;
    }

    // функция возвращает значения элементов в store
    this.GetValuesOfObjects = function()
    {
        var ret = {};

        for (var name in store)
        {
            var obj = store[name];           

            switch(obj.object)
            {
                case 'edit':
                case 'text':
                case 'hidden':
                    ret[name] = obj.value;
                    break;               
                    
                case 'date':
                    ret[name] = obj.text.value;
                    break;
                    
               case 'checkbox':
                    ret[name] = (obj.checked ? 1 : 0);
                    break;
                    
                case 'list':
                    if (obj.selectedIndex < 0) break;
                    ret[name] = obj.options[obj.selectedIndex].value;
                    break;
                    
                case 'blist':
                    var msk = '';
                    
                    for (var i = 0; i < obj.options.length; i++)
                    {
                        msk = (obj.options[i].selected ? '1' : '0') + msk;
                    }            
                    
                    ret[name] = parseInt(msk, 2);        
                    break;                    
            }
            
        }

        return ret;
    }    
    
    // установка значения элементов в store
    this.SetValuesOfObjects = function(values)
    {
        for (var id in values)
        {
            var obj = store[id];            
            
            if (typeof(obj) == 'undefined') continue;
            
            switch(obj.object)
            {
                case 'edit':
                case 'text':
                case 'hidden':
                    obj.value = values[id];
                    break;               

               case 'checkbox':
                    obj.checked = (values[id] == true) ? 1 : 0;
                    break;
                    
                case 'label':
                    obj.innerHTML = values[id];
                    break;
                    
                case 'date':
                    obj.text.value = values[id];
                    break;
                
                case 'button':
                    obj.disabled = values[id];
                    break;
                    
                case 'list':
                    obj.selectedIndex = obj.reference[values[id]];
                    break;
                    
                case 'blist':
                    var msk = self.int2bit(values[id]);

                    for (var i = 0; i < obj.options.length; i++)
                    {
                        obj.options[i].selected = (msk.charAt(i) == '1' ? true : false);
                    }
                    break;                    
            }
        }
    }
    
    /*****************************************************************/
    //
    // Генрация различных объектов коллекции
    //
    /*****************************************************************/

    // args: id, val:[{checked:true, name:'описание', id:'ID строки'} ..], top, left, height, width, readonly
    // 
    this.clist = function(owner, args)
    {
        var object = new CCheckList(args.id, args);
        
        AllocObject(owner, object.GetHandle(), args);
        
        return object;
    }   
    
    // args: id, val, top, left, height, width, readonly
    this.date = function(owner, args)
    {
        var object = document.createElement('DIV');
        var input  = document.createElement('<INPUT name="' + args.id + '">');
        var button = document.createElement('BUTTON');
        
        object.title    = args.title || '';
        object.id       = args.id;
        object.object   = 'date';
        
        if (!owner.calendar)
            owner.calendar = new CCalendar(args.id + 'Calendar', {});

        object.style.width    = (args.width  || 100) + 'px';
        object.style.height   = (args.height || 22)  + 'px';
        object.style.zIndex   = 500;
        object.text = input;

        object.appendChild(input);
        object.appendChild(button);
                
        if (args.readonly == true)
        {
            input.style.backgroundColor = '#CCCCCC';
            input.readOnly              = true;
            button.disabled             = true;  
        }
        
        input.value           = args.val || GetCurrDate();
        input.style.textAlign = 'center';
        input.style.padding   = '0 22px 0 2px';
        input.style.height    = '100%';
        input.style.width     = '100%';
        
        input.onselectstart   = function () {event.returnValue = true; return true;};
        
        button.style.position = 'absolute';
        button.value          = ':::';
        button.style.top      = 3;
        button.style.left     = (object.style.pixelWidth - 22) + 'px';
        button.style.height   = (object.style.pixelHeight - 4) + 'px';
        button.style.width    = (22  - 1) + 'px';
        button.style.align    = 'center';
        
        AllocObject(owner, object, args);        

        input.ondblclick      = function () 
        {
            if (input.readOnly == true)
                return;                
            else if (owner.calendar.IsShow(object))
                owner.calendar.Hide(object);
            else 
                owner.calendar.Show(object, new SPosition(object.offsetHeight, 0), {value:input, dtop:-2, dleft:0});
            return;
        };
        button.onclick        = function () 
        {
            if (owner.calendar.IsShow(object))
                owner.calendar.Hide(object);
            else 
                owner.calendar.Show(object, new SPosition(object.offsetHeight, 0), {value:input, dtop:-2, dleft:0});
            return;
        };        
        
        return object;
    }
    
    // args: id, val, exe, top, left, height, width, readonly
    this.button = function(owner, args, dlg)
    {
        var object  = document.createElement('<BUTTON name="' + args.id + '"></BUTTON>');

        object.title  = args.title || '';        
        object.id     = args.id;
        object.object = 'button';
        object.value  = args.val || 'Выполнить';        

        object.style.width  = (args.width  || 100) + 'px';
        object.style.height = (args.height || 22)  + 'px';                
        object.disabled     = args.readonly;
        object.onclick      = args.exe || object.onclick;
        
        AllocObject(owner, object, args);        
       
        return object;
    }  

    // args: id, val, top, left, height, width, readonly
    this.text = function(owner, args)
    {
        var object = document.createElement('<TEXTAREA name="' + args.id + '"></TEXTAREA>');

        object.title  = args.title || '';        
        object.id     = args.id;
        object.value  = args.val || '';
        object.object = 'text';
        
        if (args.readonly == true)
        {
            object.style.backgroundColor = '#CCCCCC';
            object.readOnly              = true;
        }

        object.style.width    = (args.width  || 100) + 'px';
        object.style.height   = (args.height || 22)  + 'px';
        
        object.style.textAlign = 'left';
        object.style.padding   = '0 2px 0 2px';

        object.onselectstart  = function () {event.returnValue = true; return true;};        
        
        AllocObject(owner, object, args);        
       
        return object;
    }
    
    // args: id, val, top, left, height, width, readonly
    this.edit = function(owner, args)
    {
        var object = document.createElement('<INPUT name="' + args.id + '">');

        object.title  = args.title || '';        
        object.id     = args.id;
        object.value  = args.val || '';
        object.object = 'edit';
        object.type   = 'text';
       
        if (args.readonly == true)
        {
            object.style.backgroundColor = '#CCCCCC';
            object.readOnly              = true;
        }                

        object.style.width    = (args.width  || 100) + 'px';
        object.style.height   = (args.height || 22)  + 'px';
        
        object.style.textAlign = args.align || 'right';
        object.style.padding   = '0 2px 0 2px';
        
        object.onselectstart  = function () {event.returnValue = true; return true;};
        
        AllocObject(owner, object, args);        
       
        return object;
    }

    // args: id, val, checked, top, left, height, width, readonly
    this.checkbox = function(owner, args)
    {
        var object = document.createElement('<INPUT name="' + args.id + '" ' + ((args.checked || false) ? 'checked' : '') + '>');

        object.title   = args.title || '';        
        object.id      = args.id;
        object.value   = args.val || '';
        object.object  = 'checkbox';
        object.type    = 'checkbox';        
       
        if (args.readonly == true)
        {
            object.style.backgroundColor = '#CCCCCC';
            object.disabled              = true;
        }                

        object.style.width    = (args.width  || 22) + 'px';
        object.style.height   = (args.height || 22)  + 'px';
        
        object.onselectstart  = function () {event.returnValue = true; return true;};
        
        AllocObject(owner, object, args);        
       
        return object;
    }
    
    // args: name, val, id
    this.hidden = function(owner, args)
    {
        var object = document.createElement('<INPUT name="' + args.id + '">');

        object.id     = args.id;
        object.value  = args.val || '';
        object.object = 'hidden';
        object.type   = 'hidden';
        
        AllocObject(owner, object, args);        
       
        return object;
    }    

    
    // args: id, val:[{id, name, selected}], top, left, height, width, readonly, size, multiple
    this.list = function(owner, args)
    {
        var object = document.createElement('<SELECT size=' + (args.size || 1) + ' name="'+ args.id +'"></SELECT>');

        object.title  = args.title || '';        
        object.id     = args.id;
        object.object = 'list';
       
        if (args.readonly == true)
        {
            object.disabled = true;
        }                

        object.multiple         = args.multiple || false; 
        object.style.width      = (args.width   || 100) + 'px';
        object.style.fontFamily = 'Courier New';
        object.reference        = {};

        if (typeof(args.val) != 'undefined')
        {
            for (var i = 0; i < args.val.length; i++)
            {            
                object.options[i]                          = new Option(args.val[i].name, args.val[i].id);                                               
                object.options[object.length - 1].selected = args.val[i].selected || false;                
                object.reference[args.val[i].id]           = i; 
            }
        }        
        
        AllocObject(owner, object, args);                
               
        return object;
    }

    // args: id, val:[{id, name, selected}], top, left, height, width, readonly, size, multiple
    this.blist = function(owner, args)
    {
        var object = document.createElement('<SELECT ' + (args.multiple ? 'multiple' : '')  + ' size=' + (args.size || 1) + ' name="'+ args.id +'"></SELECT>');

        object.title  = args.title || '';        
        object.id     = args.id;
        object.object = 'blist';
       
        if (args.readonly == true)
        {
            object.disabled = true;
        }                
        
        object.size             = args.size     || 1;
//      object.multiple         = args.multiple || false; 
        object.style.width      = (args.width   || 100) + 'px';
        object.style.fontFamily = 'Courier New';
        
        if (typeof(args.val) != 'undefined')
        {
            for (var i = 0; i < args.val.length; i++)
            {
                object.options[args.val[i].id]          = new Option(args.val[i].name, args.val[i].id);
                object.options[args.val[i].id].selected = args.val[i].selected || false;                
            }
        }
        
        AllocObject(owner, object, args);        
       
        return object;
    }       
    
    // args: id, val, top, left, height, width
    this.label = function (owner, args)
    {
        var object = document.createElement('SPAN');
        
        object.title     = args.title || '';
        object.innerHTML = args.val || '';
        object.object    = 'label';
            
        object.style.width    = (args.width  || 100) + 'px';
        object.style.height   = (args.height || 22)  + 'px';
        
        object.style.textAlign = args.align || 'left';
        
        AllocObject(owner, object, args);
       
        return object;
    }
    
    this.int2bit = function (iVal)
    {
        var ret = '';

        while (iVal >= 1)
        {   
            ret  += (iVal & 0x01 ? 1 : 0);
            iVal  = Math.floor(iVal/2);
        }
        return ret;
    }
    
    
    function AllocObject(owner, object, args)
    {
        owner.appendChild(object);
        
        if (object.object == 'hidden')
            return;
         
        var top = 5, left = 3;

        for (var i = owner.childNodes.length - 1; i > 0; i--)
        {

            if (owner.childNodes[i - 1].object == 'hidden') 
                continue;
            top  = owner.childNodes[i - 1].style.pixelTop + owner.childNodes[i - 1].style.pixelHeight + 3;
            left = owner.childNodes[i - 1].style.pixelLeft;
            break;
        }
        
        object.style.position = 'absolute';               
        object.style.top      = (args.top  || top)  + 'px';
        object.style.left     = (args.left || left) + 'px';    
    }
}

function MyDialog(name, param)
{
    var sName    = name         || alert('Error, not set name dialoga');
    var dlg      = undefined;
    var objects  = new DlgObject();
    var hParam   = param;
    var owner    = param.owner || document.body;
    var self     = this;    

    hParam.height = param.height || 200;
    hParam.width  = param.width  || 350; 
    hParam.desc   = param.desc   || ''; 
    
    hParam.target = param.target || ''; 
    hParam.action = param.action || document.URL;
    hParam.method = param.method || 'post';

    var title  = {hndl:undefined, desc:undefined, button:undefined, height:24};
    var body   = {hndl:undefined};

    this.GetWidth=function() { return hParam.width; }
    this.SetWidth=function(NewValue) { hParam.width=NewValue || hParam.width; dlg.style.width = hParam.width + 'px'; DoResize();}

    this.GetDesc=function() { return hParam.desc; }
    this.SetDesc=function(NewValue) {self.ShowTitleBar(NewValue);}

    this.GetHeight=function() { return hParam.height; }
    this.SetHeight=function(NewValue) { hParam.height=NewValue || hParam.height; dlg.style.height = hParam.height + 'px'; DoResize();}

    this.GetTop=function() {return dlg.style.pixelTop;}
    this.GetLeft=function() {return dlg.style.pixelLeft;}

    this.ShowTitleBar=function(text)
    {
        hParam.desc              = text || hParam.desc;
        title.hndl.style.display = 'block';    
        title.desc.innerHTML     = hParam.desc;
        DoResize();
    }

    this.HideTitleBar=function()
    {
        title.hndl.style.display = 'none';    
        DoResize();
    }
    
    function DoResize()
    {
        // изменение размера titlebar'a
        title.hndl.style.width  = (hParam.width - 1 - 1 - 2 * parseInt(dlg.style.borderWidth)) + 'px';
        title.hndl.style.height = title.height;
        title.desc.style.width  = (title.hndl.style.pixelWidth - 22) + 'px';

        // изменение размера раздела элементов диалога
        body.hndl.style.top      = (title.hndl.style.display == 'none'? 0 : title.height) + 'px';
        body.hndl.style.height   = (hParam.height - (2 * parseInt(dlg.style.borderWidth) + (title.hndl.style.display == 'none'? 0 : title.height))) + 'px';
        body.hndl.style.width    = (hParam.width - 1 - 1 - 2 * parseInt(dlg.style.borderWidth)) + 'px';

    }    

    function CreateTitleBar()
    {
        title.hndl   = document.createElement('DIV');
        title.desc   = document.createElement('SPAN');
        title.button = document.createElement('SPAN');

        title.hndl.appendChild(title.desc);
        title.hndl.appendChild(title.button);

        dlg.appendChild(title.hndl);        
        
        // параметры корневого элемента (title bar)
        title.hndl.style.top      = 0;
        title.hndl.style.left     = 0;
        title.hndl.style.width    = (hParam.width - 1 - 1 - 2 * parseInt(dlg.style.borderWidth)) + 'px';
        title.hndl.style.height   = title.height;
        title.hndl.style.position = 'absolute';
        title.hndl.style.display  = 'block';
       
        title.hndl.style.backgroundColor = '#000066';

        title.hndl.align = 'left';
        
        // параметры текста 
        title.desc.innerHTML        = hParam.desc;
        title.desc.style.padding    = '0 2px 0 2px';
        title.desc.style.width      = (title.hndl.style.pixelWidth - 22) + 'px';
        title.desc.style.color      = '#FFFFFF';        
        title.desc.style.fontWeight = 'bold';
        title.desc.style.textAlign  = 'left';
        title.desc.style.cursor     = 'default';

        title.desc.onmousedown = function () 
        {
            var onmousemove = dlg.parentNode.onmousemove;
            var onmouseup   = dlg.parentNode.onmouseup;
            var cursor      = title.desc.style.cursor;
            var dy          = parseInt(dlg.style.top)  - window.event.clientY;
            var dx          = parseInt(dlg.style.left) - window.event.clientX;
            
            dlg.parentNode.onmousemove = function () 
            {
                dlg.style.top  = window.event.clientY + dy;
                dlg.style.left = window.event.clientX + dx;
                title.desc.style.cursor = 'move';
            }

            dlg.parentNode.onmouseup = function () 
            {
                dlg.parentNode.onmousemove  = onmousemove;
                dlg.parentNode.onmouseup    = onmouseup;
                title.desc.style.cursor    = cursor;
            }
        }            
               
//        title.desc.style.border = 'solid red';
//        title.desc.style.borderWidth = 1;
        
        // параметры кнопки управления
        title.button.style.margin          = '2px 1px 2px 4px';
        title.button.style.width           = 16 + 'px';
        title.button.style.height          = 16 + 'px';
        title.button.style.backgroundColor = 'buttonface';
        title.button.style.fontWeight      = 'bold';
        title.button.style.textAlign       = 'center';
        title.button.style.position        = 'absolute';        
        title.button.style.cursor          = 'hand';

        title.button.style.borderStyle     = 'ridge';
        title.button.style.borderWidth     = '1px';
        title.button.style.borderColor     = 'activeborder';


        title.button.innerHTML      = 'X';
        title.button.onmousedown    = function () {self.Hide();};         
        title.button.title          = 'Закрыть';
    }
    
    function CreateBody()
    {
        body.hndl = document.createElement('<form name="' + sName + '"></form>');

        body.hndl.target = hParam.target;
        body.hndl.action = hParam.action;
        body.hndl.method = hParam.method;

        dlg.appendChild(body.hndl); 

        body.hndl.style.left     = 0;
        body.hndl.style.top      = 0;
        
        body.hndl.style.width    = (hParam.width - 1 - 1 - 2 * parseInt(dlg.style.borderWidth)) + 'px';;
        body.hndl.style.height   = (hParam.height - (2 * parseInt(dlg.style.borderWidth) + (title.hndl.style.display == 'none'? 0 : title.height))) + 'px';
        body.hndl.style.position = 'absolute';
//        body.hndl.style.overflow = 'auto';

//        body.hndl.style.border = 'solid red';
//        body.hndl.style.borderWidth = 1;        
    }
         
    this.Show=function(values, top, left, from)
    {
        top  = top  || (Math.round(document.body.clientHeight/2 - dlg.style.pixelHeight/2) + document.body.scrollTop); 
        top  = (top  > 0 ? top  : 1);
        left = left || (Math.round(document.body.clientWidth/2  - dlg.style.pixelWidth/2) + document.body.scrollLeft);  
        left = (left > 0 ? left : 1);

        self.Dispatch('ON_DLG_SHOW', self, values, [top, left, from]);        

        objects.SetValuesOfObjects(values);    

        dlg.style.top      = top;
        dlg.style.left     = left;
        dlg.style.display  = 'block';
    }

    this.Hide=function(from)
    {
        var values = objects.GetValuesOfObjects();
        
        self.Dispatch('ON_DLG_HIDE', self, from, values);        
        dlg.style.display  = 'none';
        self.Dispatch('ON_DLG_AFTER_HIDE', self, from, values);        
    }
    
    this.IsShow=function()
    {
        return (dlg.style.display != 'none');
    }
    
    this.AddObject=function(type, args)
    {   
        var ret = objects[type](body.hndl, args, this);
        objects.AddObject(ret.id, ret);        
        return ret;
    }
    
    this.GetValuesOfObjects = function()
    {
        return objects.GetValuesOfObjects();
    }

    // доступ к элементу коллекции
    this.GetObject = function(name)
    {
        return objects.GetObject(name);
    }
    
    function Create()
    {
        // наследование от базового класса CEventsHandler
        self.parent = CEventsHandler; // наследуем свойства и методы                
        self.parent(hParam.events);     // вызов родительского конструктора           
        
        dlg  = document.createElement('div');
        
        dlg.style.height   = hParam.height + 'px';
        dlg.style.width    = hParam.width + 'px';
        dlg.style.position = 'absolute';
        dlg.style.top      = '1'; 
        dlg.style.left     = '1'; 
        dlg.style.zIndex   = 100;
        dlg.style.display  = 'none'; 

        dlg.style.backgroundColor = 'buttonface';
        dlg.style.borderStyle     = 'outset';
        dlg.style.borderWidth     = '2px';
        dlg.style.borderColor     = 'activeborder';
        
        dlg.onselectstart  = function () {return (event.returnValue == true);};

        CreateTitleBar(); 
        CreateBody(); 
        DoResize();

        owner.appendChild(dlg);        
    }

    Create();
}
