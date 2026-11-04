-- ==========================================================
-- EC-2 Microprocesador — Modelo Conductual (FSMD)
-- Estilo: Behavioral completo (un solo proceso con reloj)
-- Incluye: enter para instrucción IN, programa GCD inicializado
-- Compatible con: GHDL, ModelSim, Vivado (simulación)
-- ==========================================================
-- Diferencias con la versión estructural (mp.vhd + cu.vhd + dp.vhd):
--   - Un solo archivo vs múltiples componentes
--   - 3 ciclos/instrucción (fetch→decode→execute) vs 4 (start→fetch→decode→execute)
--   - Apos: A(7)='0' AND A/="0" (estricto >0) vs NOT A(7) (≥0)
--   - Ambas versiones producen los mismos resultados para programas
--     que usen JZ antes de JPOS (como multiply y GCD).
-- ==========================================================
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY ec2 IS PORT(
  clock  : IN  STD_LOGIC;
  reset  : IN  STD_LOGIC;
  enter  : IN  STD_LOGIC;                          -- Confirmación para instrucción IN
  input  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
  output : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
);
END ec2;

ARCHITECTURE fsmd OF ec2 IS
  -- 11 estados: inicio, fetch/decode, y uno por cada instrucción
  TYPE state_type IS (
    s_start, s_fetch, s_decode,
    s_load, s_store, s_add, s_sub,
    s_input, s_jz, s_jpos, s_halt
  );
  SIGNAL state : state_type;

  -- Registros internos del procesador
  SIGNAL PC : STD_LOGIC_VECTOR(4 DOWNTO 0);  -- Contador de programa (5 bits → 32 dir.)
  SIGNAL IR : STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Registro de instrucción (opcode + operando)
  SIGNAL A  : STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Acumulador (único registro de datos)

  -- RAM: memoria unificada de programa y datos (32×8 bits)
  TYPE ram_type IS ARRAY(0 TO 31) OF STD_LOGIC_VECTOR(7 DOWNTO 0);

  -- =====================================================
  -- PROGRAMA: Máximo Común Divisor (GCD)
  -- Algoritmo de Euclides por restas sucesivas
  -- Modifica este arreglo para cargar tu propio programa.
  -- =====================================================
  SIGNAL RAM : ram_type := (
    -- Dir  Binario       Instrucción       Descripción
    0  => "10000000",   -- IN                ; A ← entrada (primer número)
    1  => "00111100",   -- STORE 28          ; M[28] ← a
    2  => "10000000",   -- IN                ; A ← entrada (segundo número)
    3  => "00111101",   -- STORE 29          ; M[29] ← b
    4  => "00011100",   -- LOAD 28           ; A ← a              [LOOP]
    5  => "01111101",   -- SUB 29            ; A ← a - b
    6  => "10101110",   -- JZ 14             ; si a==b → DONE
    7  => "11001100",   -- JPOS 12           ; si a>b  → A_GT_B
    8  => "00011101",   -- LOAD 29           ; A ← b              [B_GT_A]
    9  => "01111100",   -- SUB 28            ; A ← b - a
    10 => "00111101",   -- STORE 29          ; M[29] ← nuevo b
    11 => "11000100",   -- JPOS 4            ; → LOOP
    12 => "00111100",   -- STORE 28          ; M[28] ← a-b        [A_GT_B]
    13 => "11000100",   -- JPOS 4            ; → LOOP
    14 => "00011100",   -- LOAD 28           ; A ← GCD            [DONE]
    15 => "11100000",   -- HALT              ; Fin del programa
    OTHERS => "00000000"   -- Datos (M[28]=a, M[29]=b)
  );

BEGIN
  -- Asignación concurrente: output siempre refleja el acumulador
  output <= A;

  PROCESS(clock, reset)
  BEGIN
    IF reset = '1' THEN
      state <= s_start;
      PC    <= (OTHERS => '0');
      IR    <= (OTHERS => '0');
      A     <= (OTHERS => '0');
    ELSIF clock'EVENT AND clock = '1' THEN
      CASE state IS
        WHEN s_start =>
          state <= s_fetch;

        WHEN s_fetch =>                          -- FETCH: leer instrucción de RAM
          IR    <= RAM(to_integer(unsigned(PC))); -- IR ← RAM[PC]
          state <= s_decode;

        WHEN s_decode =>                         -- DECODE: decodificar y avanzar PC
          PC <= std_logic_vector(unsigned(PC) + 1); -- PC ← PC + 1
          CASE IR(7 DOWNTO 5) IS                 -- Decodificar opcode (3 bits superiores)
            WHEN "000" => state <= s_load;
            WHEN "001" => state <= s_store;
            WHEN "010" => state <= s_add;
            WHEN "011" => state <= s_sub;
            WHEN "100" => state <= s_input;
            WHEN "101" => state <= s_jz;
            WHEN "110" => state <= s_jpos;
            WHEN OTHERS => state <= s_halt;
          END CASE;

        WHEN s_load =>                           -- A ← M[dir]
          A     <= RAM(to_integer(unsigned(IR(4 DOWNTO 0))));
          state <= s_start;

        WHEN s_store =>                          -- M[dir] ← A
          RAM(to_integer(unsigned(IR(4 DOWNTO 0)))) <= A;
          state <= s_start;

        WHEN s_add =>                            -- A ← A + M[dir]
          A     <= std_logic_vector(unsigned(A) +
                   unsigned(RAM(to_integer(unsigned(IR(4 DOWNTO 0))))));
          state <= s_start;

        WHEN s_sub =>                            -- A ← A - M[dir]
          A     <= std_logic_vector(unsigned(A) -
                   unsigned(RAM(to_integer(unsigned(IR(4 DOWNTO 0))))));
          state <= s_start;

        WHEN s_input =>                          -- A ← entrada (espera enter)
          IF enter = '1' THEN
            A     <= input;
            state <= s_start;
          ELSE
            state <= s_input;                    -- Esperar confirmación
          END IF;

        WHEN s_jz =>                             -- Saltar si A = 0
          IF A = "00000000" THEN
            PC <= IR(4 DOWNTO 0);
          END IF;
          state <= s_start;

        WHEN s_jpos =>                           -- Saltar si A > 0 (estrictamente positivo)
          IF A(7) = '0' AND A /= "00000000" THEN
            PC <= IR(4 DOWNTO 0);
          END IF;
          state <= s_start;

        WHEN s_halt =>
          state <= s_halt;                       -- Permanecer detenido
      END CASE;
    END IF;
  END PROCESS;
END fsmd;
