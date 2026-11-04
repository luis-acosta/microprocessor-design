-- ==========================================================
-- Testbench: Microprocesador EC-2
-- Verifica multiplicacion por sumas sucesivas (5 x 4 = 20)
-- ==========================================================
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY mp_tb IS
END mp_tb;

ARCHITECTURE test OF mp_tb IS

  COMPONENT mp PORT(
    clock, reset, enter : IN  STD_LOGIC;
    input               : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
    output              : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
  END COMPONENT;

  SIGNAL clk, rst, ent : STD_LOGIC := '0';
  SIGNAL data_in       : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
  SIGNAL data_out      : STD_LOGIC_VECTOR(7 DOWNTO 0);

  CONSTANT CLK_PERIOD : TIME := 20 ns;  -- 50 MHz

BEGIN

  -- Instancia del microprocesador
  UUT: mp PORT MAP(
    clock  => clk,
    reset  => rst,
    enter  => ent,
    input  => data_in,
    output => data_out
  );

  -- Generador de reloj
  clk_gen: PROCESS
  BEGIN
    clk <= '0'; WAIT FOR CLK_PERIOD / 2;
    clk <= '1'; WAIT FOR CLK_PERIOD / 2;
  END PROCESS;

  -- Estimulos de prueba
  stim: PROCESS
  BEGIN
    -- Reset inicial
    rst <= '1';
    ent <= '0';
    WAIT FOR CLK_PERIOD * 3;
    rst <= '0';

    -- Esperar a que el procesador llegue al primer IN (s_input)
    -- Cada instruccion toma ~3 ciclos (fetch, decode, execute)
    -- IN esta en la direccion 0, asi que llega rapido
    WAIT FOR CLK_PERIOD * 4;

    -- Ingresar primer numero: multiplicando = 5
    data_in <= "00000101";   -- 5 en binario
    WAIT FOR CLK_PERIOD * 2;
    ent <= '1';              -- Pulso de enter
    WAIT FOR CLK_PERIOD;
    ent <= '0';

    -- Esperar a que ejecute STORE 30 y llegue al segundo IN
    WAIT FOR CLK_PERIOD * 10;

    -- Ingresar segundo numero: multiplicador = 4
    data_in <= "00000100";   -- 4 en binario
    WAIT FOR CLK_PERIOD * 2;
    ent <= '1';              -- Pulso de enter
    WAIT FOR CLK_PERIOD;
    ent <= '0';

    -- Esperar a que el programa complete la multiplicacion
    -- 4 iteraciones del bucle, ~9 instrucciones por iteracion
    -- cada instruccion ~3 ciclos => ~4*9*3 = ~108 ciclos
    WAIT FOR CLK_PERIOD * 200;

    -- Verificar resultado: 5 x 4 = 20 = "00010100"
    REPORT "========================================";
    REPORT "Resultado de la multiplicacion:";
    REPORT "  5 x 4 = " & INTEGER'IMAGE(to_integer(unsigned(data_out)));
    REPORT "  Esperado: 20";
    IF data_out = "00010100" THEN
      REPORT "  PRUEBA EXITOSA!" SEVERITY NOTE;
    ELSE
      REPORT "  PRUEBA FALLIDA! Salida = " &
        INTEGER'IMAGE(to_integer(unsigned(data_out)))
        SEVERITY ERROR;
    END IF;
    REPORT "========================================";

    WAIT FOR CLK_PERIOD * 10;
    -- Fin de simulacion
    ASSERT FALSE REPORT "Simulacion completada." SEVERITY FAILURE;
    WAIT;
  END PROCESS;

END test;
