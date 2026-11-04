-- ==========================================================
-- RAM Genérica 32×8 — Reemplazo portable de lpm_ram_dq
-- Sintetizable en cualquier FPGA (Xilinx, Lattice, Intel, etc.)
-- Lectura combinacional, escritura síncrona.
-- El programa se inicializa mediante una constante INIT.
-- ==========================================================
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY ram IS
  GENERIC(
    ADDR_WIDTH : INTEGER := 5;   -- 5 bits → 32 posiciones
    DATA_WIDTH : INTEGER := 8    -- 8 bits de ancho de palabra
  );
  PORT(
    clock   : IN  STD_LOGIC;                                     -- Reloj (escritura síncrona)
    we      : IN  STD_LOGIC;                                     -- Write Enable
    address : IN  STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);     -- Dirección
    data    : IN  STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);     -- Datos de escritura
    q       : OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0)      -- Datos leídos
  );
END ram;

ARCHITECTURE Behavioral OF ram IS

  -- Tipo para el arreglo de memoria
  TYPE memory_array IS ARRAY(0 TO 2**ADDR_WIDTH-1) OF
    STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);

  -- =====================================================
  -- PROGRAMA: Máximo Común Divisor (GCD)
  -- Modifica este arreglo para cargar tu propio programa.
  -- Direcciones 0-N: instrucciones del programa
  -- Direcciones restantes: datos (inicializados a "00000000")
  -- =====================================================
  CONSTANT INIT : memory_array := (
    -- Dir  Instrucción      Descripción
    0  => "10000000",   -- IN   A              ; A ← entrada del usuario (primer número)
    1  => "00111110",   -- STORE M[30]         ; M[30] ← A (guardar X)
    2  => "10000000",   -- IN   A              ; A ← entrada del usuario (segundo número)
    3  => "00111111",   -- STORE M[31]         ; M[31] ← A (guardar Y)
    4  => "11001011",   -- JZERO 11            ; si A=0, saltar a 11 (fin)
    5  => "01011111",   -- SUB  M[31]          ; A ← A - Y
    6  => "11101011",   -- JPOS 11             ; si A>0, saltar a 11 (X>Y resuelto)
    7  => "00011111",   -- LOAD M[31]          ; A ← Y
    8  => "01011110",   -- SUB  M[30]          ; A ← Y - X
    9  => "00111111",   -- STORE M[31]         ; M[31] ← nuevo Y
    10 => "00011110",   -- LOAD M[30]          ; A ← X
    11 => "11000100",   -- JZERO 4             ; volver al loop
    12 => "00011110",   -- LOAD M[30]          ; A ← resultado (GCD)
    13 => "11100000",   -- JPOS 0              ; saltar a 0 (reiniciar) — o HALT
    OTHERS => "00000000"    -- Resto de la memoria inicializada a 0 (datos)
  );

  -- Señal interna de la memoria (inicializada con INIT)
  SIGNAL memory : memory_array := INIT;

BEGIN
  -- Proceso de escritura síncrona
  -- Solo escribe en el flanco ascendente del reloj cuando we='1'
  PROCESS(clock)
  BEGIN
    IF clock'EVENT AND clock = '1' THEN
      IF we = '1' THEN
        memory(to_integer(unsigned(address))) <= data;
      END IF;
    END IF;
  END PROCESS;

  -- Lectura combinacional (asíncrona)
  -- Equivalente a lpm_outdata => "UNREGISTERED"
  q <= memory(to_integer(unsigned(address)));

END Behavioral;
