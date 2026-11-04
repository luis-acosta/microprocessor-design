-- ==========================================================
-- Testbench: Microprocesador EC-2
-- Verifica Máximo Común Divisor: GCD(12, 8) = 4
-- ==========================================================
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY gcd_tb IS
END gcd_tb;

ARCHITECTURE test OF gcd_tb IS

  COMPONENT mp
  GENERIC(
    INIT_FILE : STRING := "multiply.mem"
  );
  PORT(
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
  UUT: mp GENERIC MAP(INIT_FILE => "gcd.mem") PORT MAP(
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

  -- Estímulos de prueba
  stim: PROCESS
  BEGIN
    -- ========================================
    -- Reset inicial
    -- ========================================
    rst <= '1';
    ent <= '0';
    WAIT FOR CLK_PERIOD * 3;
    rst <= '0';

    -- Esperar a que el procesador llegue al primer IN (dirección 0)
    -- s_start → s_fetch → s_decode → s_input = 3 ciclos
    WAIT FOR CLK_PERIOD * 4;

    -- ========================================
    -- Ingresar primer número: a = 12
    -- ========================================
    data_in <= "00001100";   -- 12 en binario
    WAIT FOR CLK_PERIOD * 2;
    ent <= '1';              -- Pulso de enter
    WAIT FOR CLK_PERIOD;
    ent <= '0';

    -- Esperar a que ejecute STORE 28 y llegue al segundo IN
    -- s_start → s_fetch → s_decode → s_store → s_start →
    -- s_fetch → s_decode → s_input = 7 ciclos
    WAIT FOR CLK_PERIOD * 10;

    -- ========================================
    -- Ingresar segundo número: b = 8
    -- ========================================
    data_in <= "00001000";   -- 8 en binario
    WAIT FOR CLK_PERIOD * 2;
    ent <= '1';              -- Pulso de enter
    WAIT FOR CLK_PERIOD;
    ent <= '0';

    -- ========================================
    -- Esperar a que el programa complete el GCD
    -- ========================================
    -- 3 iteraciones del bucle principal
    -- Iteración 1 (a>b): ~6 instrucciones
    -- Iteración 2 (b>a): ~8 instrucciones
    -- Iteración 3 (a==b): ~3 instrucciones + LOAD + HALT
    -- Cada instrucción ~3-4 ciclos
    WAIT FOR CLK_PERIOD * 200;

    -- ========================================
    -- Verificar resultado: GCD(12, 8) = 4
    -- ========================================
    REPORT "========================================";
    REPORT "Resultado del GCD:";
    REPORT "  GCD(12, 8) = " & INTEGER'IMAGE(to_integer(unsigned(data_out)));
    REPORT "  Esperado: 4";
    IF data_out = "00000100" THEN
      REPORT "  PRUEBA EXITOSA!" SEVERITY NOTE;
    ELSE
      REPORT "  PRUEBA FALLIDA! Salida = " &
        INTEGER'IMAGE(to_integer(unsigned(data_out)))
        SEVERITY ERROR;
    END IF;
    REPORT "========================================";

    WAIT FOR CLK_PERIOD * 10;
    -- Fin de simulación
    ASSERT FALSE REPORT "Simulacion completada." SEVERITY FAILURE;
    WAIT;
  END PROCESS;

END test;
