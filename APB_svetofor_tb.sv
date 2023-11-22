// модуль ТЕСТБЕНЧ
`include "APB_master.sv"       // подключаем файл МАСТЕРА
`include "Svetofor.sv"         // подключаем файл СЛЕЙВА


module APB_svetofor_tb
#(
    parameter CONTROL_REG_ADDR = 4'h0,    // адрес контрольного регистра
    parameter CURRENT_STATE_ADDR = 4'h4   // адрес регистра текущего состояния
);


reg PCLK = 0;                  // сигнал синхронизации
reg PWRITE_MASTER = 0;         // сигнал, выбирающий режим записи или чтения (1 - запись, 0 - чтение)
wire PSEL;                     // сигнал выбора переферии
reg [31:0] PADDR_MASTER = 0;   // адрес регистра
reg [31:0] PWDATA_MASTER = 0;  // данные для записи в регистр
wire [31:0] PRDATA_MASTER;     // данные, прочитанные из слейва
wire PENABLE;                  // сигнал разрешения, формирующийся в мастер APB
reg PRESET = 0;                // сигнал сброса
wire PREADY;                   // сигнал готовности (флаг того, что всё сделано успешно)
wire [31:0] PADDR;             // адрес, который мы будем передавать в слейв
wire [31:0] PWDATA;            // данные, которые будут передаваться в слейв
wire [31:0] PRDATA ;           // данные, прочтитанные со слейва
wire PWRITE;                   // сигнал записи или чтения на вход слейва

// создание экземпляра мастера
APB_master APB_master_1 (
    .PCLK(PCLK),
    .PWRITE_MASTER(PWRITE_MASTER),
    .PSEL(PSEL),
    .PADDR_MASTER(PADDR_MASTER),
    .PWDATA_MASTER(PWDATA_MASTER),
    .PRDATA_MASTER(PRDATA_MASTER),
    .PENABLE(PENABLE),
    .PRESET(PRESET),
    .PREADY(PREADY),
    .PADDR(PADDR),
    .PWDATA(PWDATA),
    .PRDATA(PRDATA),
    .PWRITE(PWRITE)
);

// создание экземпляра слейва
svetofor svetofor_1 (
    .PWRITE(PWRITE),
    .PSEL(PSEL),
    .PADDR(PADDR),
    .PWDATA(PWDATA),
    .PRDATA(PRDATA),
    .PENABLE(PENABLE),
    .PREADY(PREADY),
    .PCLK(PCLK)
);

// генерация входного сигнала PCLK
always #200 PCLK = ~PCLK;

// Объявление задачи для записи данных в регистр
task write_data;
  input reg [31:0] DATA;  // данные для записи
  input reg[31:0] ADDR;   // адрес регистра
  begin

    // Непосредственно операция записи
    PWRITE_MASTER = 1;              // выбираем запись
    PWDATA_MASTER = DATA;           // устанавливаем данные для работы с управляющим регистром. Ставим его в высокое положение
    PADDR_MASTER = ADDR;            // выбираем адрес контрольного регистра
  end
endtask

// объявление задачи для чтения данных из регистра
task read_data;
  input reg[31:0] ADDR;
  begin

    // Непосредственно операция чтения
    PWRITE_MASTER = 0;              // выбираем чтение
    PADDR_MASTER = ADDR;            // выбираем адрес регистра текущего состояния
  end
endtask


initial begin
PCLK = 0;                           // устанавливаем начальное значение тактового сигнала
// сброс output регистров
PRESET = 0;
@(posedge PCLK);
PRESET = 1;
@(posedge PCLK);
@(posedge PCLK);
@(posedge PCLK);
@(posedge PCLK);
@(posedge PCLK);
@(posedge PCLK);

// принудительное переключение состояния светофора
write_data(1, CONTROL_REG_ADDR);
@(posedge PCLK);
read_data(CURRENT_STATE_ADDR);

// пропускаем 20 тактов
repeat (20) begin
    @(posedge PCLK);
end

// снова ставим в высокое положение значение управляющего регистра. Работаем с управляющим регистром
// принудительное переключение состояния светофора
write_data(1, CONTROL_REG_ADDR);
@(posedge PCLK);
read_data(CURRENT_STATE_ADDR);

// Заканчиваем симуляцию
#50000 $finish;
end

// создание файла .vcd и вывести значения переменных волны для отображения в визуализаторе волн
initial begin
$dumpfile("APB_svetofor.vcd");    // создание файла для сохранения результатов симуляции
$dumpvars(0, APB_svetofor_tb);    // установка переменных для сохранения в файле
$dumpvars;
end


endmodule