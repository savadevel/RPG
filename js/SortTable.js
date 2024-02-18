/*
    Содержит класс сортировки HTML таблиц.   
        CSortingOfTable(tbl, prop)
        где
            tbl  - таблица в стиле:
                <thead>
                    <tr>
                        <th type='int'>
                            <table><thead><tr>
                                <th id='sort_pic'><img src=''></th>
                            </tr></thead></table>
                        </th>
                     ...
            prop - хеш дополнительных параметров
    Генерирует события:
        ON_BEFORE_SORTING -
        ON_AFTER_SORTING  -                
*/

$include('../js/', 'stdtypes.js');
$include('../js/', 'utils.js');

function CSortingOfTable(tbl, prop)
{
    this.sensitive = 0;          // если значение отлично от нуля, то сортировка с учетом регистра
    this.title     = 'Нажмите на заголовок, чтобы отсортировать колонку';
    this.image     = {
                        unk:'../img/sort/asds.gif',
                        asc:'../img/sort/asc.gif',
                        desc:'../img/sort/desc.gif'
                     };    
    this.method    = 'quick';
     
    var hParam    = prop;
    var self      = this;
    var table     = tbl;
    var fnCompare = null; // метод сравнения данных при сортировки выбирается в соответствии с типом данных
    var fnMethod  = null; // метод сортировки
    var aElements = null;
    var last      = null; // колонка по которой была сортировка
    var compare   =       // поддерживаемые типы
        {
            int:compare_num,
            flt:compare_num,
            mny:compare_num,
            date:compare_date,
            time:compare_time,
            str:compare_str,
            chr:compare_str,
            bool:compare_num,
            txt:compare_str,
            acc:compare_str,
            unk:compare_str
        };
    var method    =
        {     // поддерживаемые методы сортировки
            insert:sort_insert,
            quick:sort_quick,
            unk:sort_quick
        };
                    
    function constr()
    {
        // наследование от базового класса CEventsHandler
        self.parent = CEventsHandler; // наследуем свойства и методы                
        self.parent(prop.events);     // вызов родительского конструктора           
        
        // чтение описания полей таблицы
        for(var i = 0; i < table.rows(0).cells.length; i++)
        {
            // получаем вложенную таблицу
            var tbl  = table.rows(0).cells(i).getElementsByTagName('table');
            var col  = table.rows(0).cells(i);
            
            col.title = self.title;
           
            // цикл по полям вложенной таблицы
            for (var j = 0; j < tbl[0].rows(0).cells.length; j++)
            {
                var cell = tbl[0].rows(0).cells(j);
                
                if (cell.id != 'sort_pic') continue;

                col.onclick = function() {sorting(this);};
                col.desc    = cell.firstChild; 

                col.desc.order = 'unk';
                col.desc.src   = self.image['unk'];
            }            
        }
    }
    
    function sorting(col)
    {
        self.Dispatch('ON_BEFORE_SORTING', self);
        
        // сбрасываем предыдущие результаты
        aElements = [];
        
        // цикл по строкам таблицы, пропускаем строку заголовка
        for (var i = 1; i < table.rows.length; i++)
        {
            aElements[i - 1] = table.rows(i).cells(col.cellIndex);
        } 
        
        if (last == col)
        {
            col.desc.order = (col.desc.order == 'asc' ? 'desc' : 'asc');
            col.desc.src   = self.image[col.desc.order];
        }
        else
        {
            if (last)
            {
                // сбрасываем предыдущую сортировку
                last.desc.order = 'unk';
                last.desc.src   = self.image['unk'];            
            }
            
            // сортировка по возрастанию
            last = col;
            col.desc.order = 'asc';
            col.desc.src   = self.image['asc'];            
        }

        fnCompare = (compare[col.type]?   compare[col.type]   : compare['unk']);
        fnMethod  = (method[self.method]? method[self.method] : method['unk']);

        if (0 >= aElements.length) return;        
        
        fnMethod(0, aElements.length - 1);
        
        if ('desc' == col.desc.order) aElements.reverse();

        var tbody = table.tBodies[0];
        
        for(var i = 0; i < aElements.length; i++)         
            tbody.appendChild(aElements[i].parentNode);
        
        self.Dispatch('ON_AFTER_SORTING', self);
    }

    /*  
        Cортировка вставками для малых массивов 
        Все элементы условно разделяются на готовую последовательность a1 ... ai-1 и входную ai ... an. 
    Hа каждом шаге, начиная с i=2 и увеличивая i на 1, берем i-й элемент входной последовательности и 
    вставляем его на нужное место в готовую.

    Пример:

      Hачальные ключи         44 \\ 55 12 42 94 18 06 67
               i = 2          44 55 \\ 12 42 94 18 06 67
               i = 3          12 44 55 \\ 42 94 18 06 67
               i = 4          12 42 44 55 \\ 94 18 06 67
               i = 5          12 42 44 55 94 \\ 18 06 67
               i = 6          12 18 42 44 55 94 \\ 06 67
               i = 7          06 12 18 42 44 55 94 \\ 67
               i = 8          06 12 18 42 44 55 67 94 \\

        При поиске подходящего места удобно 'просеивать' x, сравнивая его с очередным элементом ai и 
    либо вставляя его, либо пересылая ai направо и продвигаясь налево.
        Просеивание может кончиться при двух условиях:
    1. Hайден ai с ключом, меньшим x.
    2. Достигнут конец готовой последовательности.
        Метод хорош устойчивостью сортировки, удобством для реализации в списках и, самое главное, 
    естественностью поведения. То есть уже частично отсортированный массив будут досортирован им 
    гораздо быстрее чем многими 'продвинутыми' методами.

    */
    function sort_insert(lb, ub) 
    {
        var t;
        var i, j;

       /***********************
        * сортируем a[lb..ub] *
        ***********************/
        for (i = lb + 1; i <= ub; i++) 
        {
            t = aElements[i];

            /* Сдвигаем элементы вниз, пока */
            /*  не найдем место вставки.    */
            for (j = i-1; j >= lb && fnCompare(aElements[j], t); j--)
                aElements[j+1] = aElements[j];

            /* вставка */
            aElements[j+1] = t;
        }
    }

    /* 
        "Быстрая сортировка" 

        Выберем случайным образом какой-то элемент х и просмотрим массив, двигаясь слева направо, пока не 
    найдем аi больший x, а затем справа налево, пока не найдем аi меньший х. Поменяем их местами и 
    продолжим процесс просмотра с обменом, пока просмотры не встретятся где-то в середине массива.
        В результате массив разделится на две части: левую - с ключами, меньшими х и правую - с ключами, 
    большими х.
        Этот шаг называется разделением. Х - центром.
        К получившимся частям рекурсивно применяем ту же процедуру.
        В результате получается очень эффективная сортировка
    */
    function sort_quick(lb, ub) 
    {
        var m;

       /**************************
        *  сортируем  a[lb..ub]  *
        **************************/

        while (lb < ub) 
        {
            /* разделение пополам */

            if (ub - lb <= 12) 
            {
                sort_insert(lb, ub);
                return;
            }

            m = partition(lb, ub);

            /* Уменьшаем требования к памяти:    */
            /*  меньший сегмент сортируем первым */
            if (m - lb <= ub - m) {
                sort_quick(lb, m - 1);
                lb = m + 1;
            } else {
                sort_quick(m + 1, ub);
                ub = m - 1;
            }
        }
    }

    /*  разделение массива arr[lb..ub], для метода "быстрая сортировка"*/
    function partition(lb, ub) 
    {
        var t, pivot;
        var i, j, p;

        /* Выбираем центр - pivot */
        p           = lb + ((ub - lb)>>1);
        pivot       = aElements[p];
        aElements[p] = aElements[lb];

        /* сортируем lb+1..ub относительно центра */
        i = lb+1;
        j = ub;
        
        while (1) 
        {
            while (i < j  && fnCompare(pivot,       aElements[i])) i++;
            while (j >= i && fnCompare(aElements[j], pivot))       j--;
            if (i >= j) break;

            t           = aElements[i];
            aElements[i] = aElements[j];
            aElements[j] = t;
            j--; i++;
        }

        /* центр в a[j] */
        aElements[lb] = aElements[j];
        aElements[j]  = pivot;

        return j;
    }

    function compare_date(objA, objB)
    {
        return;
    }

    function compare_time(objA, objB)
    {
        return;
    }

    function compare_num(objA, objB)
    {
        var a = (objA.childNodes.length == 1 ? objA.childNodes.item(0).nodeValue : 0);
        var b = (objB.childNodes.length == 1 ? objB.childNodes.item(0).nodeValue : 0);

        return ((a * 1) > (b * 1));
    }

    function compare_str(objA, objB)
    {
        var a = objA.childNodes.length <= 0 ? '' : objA.childNodes.item(0).nodeValue;
        var b = objB.childNodes.length <= 0 ? '' : objB.childNodes.item(0).nodeValue;

        if (0 != self.sensitive) return (a > b);
        return (a.toLowerCase() > b.toLowerCase());
    }
    
    
    constr();
}
