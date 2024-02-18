use RPG_BD

go
    if object_id('rpg_develop.fn_range2tbl_int') is not null
    begin
        drop function rpg_develop.fn_range2tbl_int
    end
go

/***************************************************************************************/
-- функция формирует список целых чисел, из указанного диапазона
-- таблицу вида (id, val)
/***************************************************************************************/
create function rpg_develop.fn_range2tbl_int 
(
    @iLen    int,          -- число записей
    @iLeft   int,          -- левая граница диапазона  
    @iRight  int,          -- правая граница диапазона 
    @bIsRand bit = 0,      -- случайное значение из диапазона
    @bIsUniq bit = 0       -- значения должны быть уникальны
)
returns 
    @tbl table (id  int identity(1, 1) not null, 
                val int not null) 
as
begin    
    
    if @iLen > (@iRight - @iLeft + 1)
        return

    declare @i     as int
    declare @iVal  as int    
    declare @iUniq as int

    set @i     = 0
    set @iUniq = @iLeft

    while @i < @iLen -- создаём массив целых чисел
    begin            
        if @bIsRand = 1 and @bIsUniq = 1
        begin                        
            set @iVal = dbo.fn_rand(@iLeft, @iRight)

            while (exists(select 1 from @tbl where val = @iVal))
            begin
                if (@iRight - @iLeft) >= (@iLen * 2)
                    -- если диапазон генерации больше в 2 раза, то генерируем
                    -- случайный набор
                    set @iVal = dbo.fn_rand(@iLeft, @iRight)                
                else if @i >= (@iLen * 0.7)  
                begin
                    -- т.к. диапазон очень узкий то при заполнении
                    -- на 70% генерируем последовательно                    
                    set @iVal  = @iUniq 
                    set @iUniq = @iUniq + 1
                end
                else
                    set @iVal = dbo.fn_rand(@iLeft, @iRight)                
            end            
        end
        else if @bIsRand = 1
            set @iVal = dbo.fn_rand(@iLeft, @iRight)
        else
            set @iVal = @iLeft + @i                
        
        insert into @tbl (val) values (@iVal)        
        set @i = @i + 1
    end

    return
end
go
