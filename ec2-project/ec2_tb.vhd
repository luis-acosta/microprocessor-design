-- ==========================================================
-- Testbench: EC-2 Behavioral (FSMD)
-- Verifica GCD(12, 8) = 4 usando el modelo conductual
-- ==========================================================
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;

ENTITY ec2_tb IS
END ec2_tb;

ARCHITECTURE test OF ec2_tb IS

  COMPONENT ec2 PORT(
    clock, reset, enter : IN  STD_LOGIC;
    input               : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
    output              : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
  );
  END COMPONENT;

  SIGNAL clk, rst, ent : STD_LOGIC := '0';
  SIGNAL data_in       : STD_LOGIC_VECTOR(7 DOWNTO 0) := (OTHERS => '0');
  SIGNAL data_out      : STD_LOGIC_VECTOR(7 DOWNTO 0);

  CONSTANT CLK_PERIOD : TIME := 20 ns;

BEGIN

  UUT: ec2 PORT MAP(
    clock  => clk,
    reset  => rst,
    enter  => ent,
    input  => data_in,
    output => data_out
  );

  clk_gen: PROCESS
  BEGIN
    clk <= '0'; WAIT FOR CLK_PERIOD / 2;
    clk <= '1'; WAIT FOR CLK_PERIOD / 2;
  END PROCESS;

  stim: PROCESS
  BEGIN
    -- Reset inicial
    rst <= '1';
    ent <= '0';
    WAIT FOR CLK_PERIOD * 3;
    rst <= '0';

    -- Esperar primer IN (behavioral: start->fetch->decode->input = 3 ciclos)
    WAIT FOR CLK_PERIOD * 4;

    -- Ingresar a = 12
    data_in <= "00001100";
    WAIT FOR CLK_PERIOD * 2;
    ent <= '1';
    WAIT FOR CLK_PERIOD;
    ent <= '0';

    -- Esperar segundo IN
    WAIT FOR CLK_PERIOD * 10;

    -- Ingresar b = 8
    data_in <= "00001000";
    WAIT FOR CLK_PERIOD * 2;
    ent <= '1';
    WAIT FOR CLK_PERIOD;
    ent <= '0';

    -- Esperar GCD
    WAIT FOR CLK_PERIOD * 200;

    -- Verificar
    REPORT "========================================";
    REPORT "EC-2 Behavioral - GCD(12, 8):";
    REPORT "  Resultado = " & INTEGER'IMAGE(to_integer(unsigned(data_out)));
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
    ASSERT FALSE REPORT "Simulacion completada." SEVERITY FAILURE;
    WAIT;
  END PROCESS;

END test;
