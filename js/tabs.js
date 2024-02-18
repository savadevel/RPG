/*
    Содержит класс управления вкладками

    CTabs(name, param) - объект-набор вкладок

    где
        name  - название набора
        param - хешь параметров набора
            left   - отступ слева
            top    - отступ сверху
            parent - родительский элемент, по умолчанию body
            width  - общая ширина в %
            align  - выравнивание группы вкладок
*/


function CTabs(name, param)
{
    var div      = document.createElement("<div class='tabs'><div>");
    var table    = document.createElement("<table cellpadding='0' cellspacing='0'><tbody></tbody></table>");
    var self     = this;
    var selected = null;

    var hParam = {};
    
    hParam.parent   = param.parent || document.body;
    hParam.left     = param.left   || 0;
    hParam.top      = param.top    || 0;
    hParam.width    = param.width  || 100;
    hParam.align    = param.align  || 'left';
    hParam.name     = name;

    var hImgPath = 
    {
        first:['../img/tabs/first_off.gif', '../img/tabs/first_on.gif'],        
        last:['../img/tabs/last_off.gif', '../img/tabs/last_on.gif'],        
        middle:['../img/tabs/both_off.gif', '../img/tabs/right_on.gif', '../img/tabs/left_on.gif']        
    };

    var hImgObj  = {};

    var hStyle   =
    [
        'unselect', 'select'
    ]

    function constr()
    {
        div.appendChild(table);
        hParam.parent.appendChild(div);
        table.insertRow();
        
        table.style.width   = hParam.width + '%';
        
        div.style.top       = hParam.top  + 'px';
        div.style.left      = hParam.left + 'px';    
        div.style.textAlign = hParam.align;

        // загружаем все картинки сразу в кэш браузера
        for (var i in hImgPath)
        {
            hImgObj[i] = [];

            for(var j = 0; j < hImgPath[i].length; j++)
            {
                hImgObj[i][j]     = new Image();
                hImgObj[i][j].src = hImgPath[i][j];
            }
        }
    }

    this.GetHandle = function()
    {
        return div;
    }

    // Добавление новой вкладки
    // text  - заголовок
    // param - параметры вкладки
    //      select - вкладка выбрана
    //      id     - идентификатор вкладки
    //      exe    - функция вызываемая при выборе вкладки
    //      page   - страница ассоциированная с вкладкой 
    //      row    - 
    //      col    -
    //      width  -
    this.Add = function(text, param)
    {
        var row    = table.tBodies[0].firstChild;
        var cLast, cText;
        var imgLast, spnText;

        if (0 == row.cells.length)
        {
            // если добавляется первая вкладка
            var cFirst, imgFirst;
            imgFirst     = document.createElement('img');
            imgFirst.src = hImgObj.first[0].src;          // задание картинки, по умолчанию вкладка не выбрана
            cFirst       = row.insertCell();              // создаем ячейку для картинки
            cFirst.appendChild(imgFirst);
            imgFirst.height  = 20;
            imgFirst.width   = 1;
        }

        spnText = document.createElement('span');         // элемент содержит текст вкладки
        imgLast = document.createElement('img');          
        imgLast.src = hImgObj.last[0].src;                // по умолчанию вкладка не выбрана 
        
        cText  = row.insertCell(); 
        cText.appendChild(spnText);
        cText.page    = param.page || null;  // привязываем страницу к вкладке
        cText.onclick = function()           // привязываем событие, которое будет отработано при выборе вкладки
                        {                               
                            selected = cText; 
                            self.Refresh(); 
                            if (param.exe) 
                                param.exe(param.id);                            
                        };                                
        cLast  = row.insertCell(); 

        cLast.className  = 'picture';
        cText.className  = hStyle[0];  // по умолчанию вкладка не выбрана

        spnText.innerText = text;
        cLast.appendChild(imgLast);

        imgLast.height   = 20;
        imgLast.width    = 23;

        var num = row.cells.length;
        
        for (var i = 1; i < num; i+=2)
        {
            // корректируем ширину вкладок
            row.cells[i].width = (100 * 2/(num - 1)) + '%';
        }        

        // переопределяем текущую вкладку
        if (param.select == true)
            selected = cText;

        self.Refresh();
    }

    // обновление представления всех вкладок
    this.Refresh = function()
    {
        var row = table.tBodies[0].firstChild;
        var num = row.cells.length;
        var cFirst, cLast, cText, iSelect, iPrev;

        for (var i = 1; i < num; i+=2)
        {
            // цикл по всем вкладкам, обновляем их представление
            cFirst  = row.cells[i-1];
            cText   = row.cells[i];
            cLast   = row.cells[i+1];

            iSelect = (cText == selected) ? 1 : 0;
            
            cFirst.firstChild.src = (row.firstChild == cFirst ? hImgObj.first[iSelect].src : hImgObj.middle[(iPrev << 1) | (iSelect)].src);
            cLast.firstChild.src  = hImgObj.last[iSelect].cloneNode().src;
            cText.className = hStyle[iSelect];
            iPrev           = iSelect;

            try
            {
                
                if (cText.page) 
                    // показываем (скрываем) связанную страницу
                    cText.page.style.display = (iSelect) ?  'block': 'none';
            }
            catch(e)
            {                   
            }
        }                   
    }

    
    constr();
}

