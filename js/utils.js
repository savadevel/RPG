/*
    Содержит общие методы, должен быть загружен первым, т.к. задает единый интерфейс
*/

// функция динамически подгружает связанные модули
function $include(path, module)
{
    var scripts = document.getElementsByTagName("script");
    var script  = path + module;
    
    for (var i=0; i<scripts.length; i++)
    {
        if (scripts[i].src.match(script))
            return;
    }

    document.write("<" + "script src=\"" + path + module + "\"></" + "script>");
/*
    var i, base, scripts = document.getElementsByTagName("script");
    for (i=0; i<scripts.length; i++){if (scripts[i].src.match(src)){base = scripts[i].src.replace(src, ""); break; }}
    module = base + module;
    for (i=0; i<scripts.length; i++){if (scripts[i].src.match(module)){return;}}
    document.write("<" + "script src=\"" + module + "\"></" + "script>");
*/
}

// метод (добавляется в класс String) форматированного представления целых чисел
function formatInt(len)
{
    // значение должно быть числом
    if (!/^[-+]?\d+$/.test(this)) return null;

    var val  = this * 1;
    var sign = (val < 0 ? '-' : '');

    // преобразуем к числу, а затем в строку       
    var str = ((this * 1) + '');

    while(str.length < len)
    {
        str = '0' + str;
    }
    
    return (sign + str);
}

function CEventsHandler(events)
{
    var listeners = {};    
    var self      = this;
    
    this.AddListener = function(event, listener)
    {
        // если событие не зарегистрированно регистриуем его
        if (!listeners[event])
            listeners[event] = [];
        listeners[event].push(listener);
        return self;
    }    
    
    this.Dispatch = function(event, from, argFirst, argSecond)
    {
        // проверяем регистрацию события
        if (!listeners[event])
            return;

        // рассылка сообщения 
        for(var i = 0; i < listeners[event].length; i++)
            listeners[event][i](from, argFirst, argSecond);
    }
    
    this.GetListeners = function()
    {
        return listeners;
    }
    
    this.AddListeners = function(events)
    {       
        if ('object' != typeof(events))
            return;

        if (events.constructor == CEventsHandler)
            events = events.GetListeners();
            
        for(var event in events)
            for (var i = 0; i < events[event].length; i++)
                self.AddListener(event, events[event][i]);                     
    }
    
    this.AddListeners(events);    
}

String.prototype.formatInt = formatInt;
//document.progress          = new CPogressImg(); дает сбой в IE8

function CPogressImg()
{
    var img  = new Image();
    var self = this;

    img.src            = '../img/progress.gif';
    img.style.position = 'absolute';
    img.style.display  = 'none';
    img.style.zIndex   = 1000;    
    img.width          = 246;
    img.height         = 86;

    img.onload = function() 
    {
        if (img.parentNode || !document.body) return; 
        document.body.appendChild(img);         
    }
    
    this.Show = function (top, left)
    {
        if (!img.complete) return;
    
        top  = top  || (Math.round(document.body.clientHeight/2 - img.height/2) + document.body.scrollTop); 
        top  = (top  > 0 ? top  : 1);
        left = left || (Math.round(document.body.clientWidth/2  - img.width/2) + document.body.scrollLeft);  
        left = (left > 0 ? left : 1);    
    
        img.style.top      = top;
        img.style.left     = left;
        img.style.display  = 'block';                   
    }
   
    this.Hide = function ()
    {
        img.style.display  = 'none';
    }    
}


function CWaitServerRespond()
{
    var hParam = {};
    var self   = this;

    hParam.hRequests = {};
    
    function Request(objForm, fnCallback)
    {
        this.key      = 'ID_' + (new Date()).getTime() + '_' + Math.round(Math.random() * 100000000);
        this.callback = fnCallback;
        this.form     = objForm;
        this.object   = document.createElement("<input type='hidden' name='the_request_wait'>");
        this.object.value = this.key;
    }
    
    function constr()
    {
    }    

    this.start = function(objForm, fnCallback)
    {    
        var request = new Request(objForm, fnCallback);
        
        hParam.hRequests[request.key] = request;
        
        objForm.appendChild(request.object);            
        objForm.submit();
        window.setTimeout(wait, 1000);
        
        return request.key;
    }

    // ожидание ответа сервера 
    function wait()
    {
        var aCookie = (typeof(document) != 'object' ? [] : document.cookie.split("; "));

        for (var i = 0; i < aCookie.length; i++)
        {    
            var aCrumb = aCookie[i].split("=");
            if (hParam.hRequests[aCrumb[0]])
            {
                if (hParam.hRequests[aCrumb[0]].callback)
                    hParam.hRequests[aCrumb[0]].callback(aCrumb[0], aCrumb[1]);
                document.cookie = aCrumb[0] + "=1; expires=Fri, 31 Dec 1999 23:59:59 GMT;";                
                hParam.hRequests[aCrumb[0]].form.removeChild(hParam.hRequests[aCrumb[0]].object);
                delete hParam.hRequests[aCrumb[0]];
            }
        }

        for (var req in hParam.hRequests)
        {
            window.setTimeout(wait, 1000);
            return;
        }
    }
    
    constr();
}

