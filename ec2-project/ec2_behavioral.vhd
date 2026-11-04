LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY ec2 IS PORT(
  clock  : IN  STD_LOGIC;
  reset  : IN  STD_LOGIC;
  input  : IN  STD_LOGIC_VECTOR(7 DOWNTO 0);
  output : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
);
END ec2;

ARCHITECTURE fsmd OF ec2 IS
  -- 11 estados: inicio, fetch/decode, y uno por cada instrucción
  TYPE state_type IS (
    s_start, s_fetch, s_decode,
    s_load, s_store, s_add, s_sub,
    s_in, s_jz, s_jpos, s_halt
  );
  SIGNAL state : state_type;

  -- Registros internos del procesador
  SIGNAL PC : STD_LOGIC_VECTOR(4 DOWNTO 0);  -- Contador de programa (5 bits → 32 dir.)
  SIGNAL IR : STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Registro de instrucción (opcode + operando)
  SIGNAL A  : STD_LOGIC_VECTOR(7 DOWNTO 0);  -- Acumulador (único registro de datos)

  -- RAM: memoria unificada de programa y datos (32×8 bits)
  -- En el modelo conductual, se modela como un arreglo de señales
  TYPE ram_type IS ARRAY(0 TO 31) OF STD_LOGIC_VECTOR(7 DOWNTO 0);
  SIGNAL RAM : ram_type;
BEGIN
  PROCESS(clock, reset)
  BEGIN
    IF reset = '1' THEN
      state  <= s_start;
      PC     <= (OTHERS => '0');
      IR     <= (OTHERS => '0');
      A      <= (OTHERS => '0');
      output <= (OTHERS => '0');
    ELSIF clock'EVENT AND clock = '1' THEN
      CASE state IS
        WHEN s_start =>
          state <= s_fetch;

        WHEN s_fetch =>                          -- FETCH: leer instrucción de RAM
          IR    <= RAM(CONV_INTEGER(PC));    -- IR ← RAM[PC]
          state <= s_decode;

        WHEN s_decode =>                         -- DECODE: decodificar y avanzar PC
          PC <= PC + 1;                          -- PC ← PC + 1 (siguiente instrucción)
          CASE IR(7 DOWNTO 5) IS                -- Decodificar opcode (3 bits superiores)
            WHEN "000" => state <= s_load;
            WHEN "001" => state <= s_store;
            WHEN "010" => state <= s_add;
            WHEN "011" => state <= s_sub;
            WHEN "100" => state <= s_in;
            WHEN "101" => state <= s_jz;
            WHEN "110" => state <= s_jpos;
            WHEN OTHERS => state <= s_halt;
          END CASE;

        WHEN s_load =>                        -- A ← M[dir]
          A     <= RAM(CONV_INTEGER(IR(4 DOWNTO 0)));
          state <= s_fetch;

        WHEN s_store =>                       -- M[dir] ← A
          RAM(CONV_INTEGER(IR(4 DOWNTO 0))) <= A;
          state <= s_fetch;

        WHEN s_add =>                         -- A ← A + M[dir]
          A     <= A + RAM(CONV_INTEGER(IR(4 DOWNTO 0)));
          state <= s_fetch;

        WHEN s_sub =>                         -- A ← A - M[dir]
          A     <= A - RAM(CONV_INTEGER(IR(4 DOWNTO 0)));
          state <= s_fetch;

        WHEN s_in =>                          -- A ← entrada
          A     <= input;
          state <= s_fetch;

        WHEN s_jz =>                          -- Saltar si A = 0
          IF A = "00000000" THEN
            PC <= IR(4 DOWNTO 0);
          END IF;
          state <= s_fetch;

        WHEN s_jpos =>                        -- Saltar si A > 0
          IF A(7) = '0' AND A /= "00000000" THEN
            PC <= IR(4 DOWNTO 0);
          END IF;
          state <= s_fetch;

        WHEN s_halt =>
          state <= s_halt;                  -- Permanecer detenido
      END CASE;
    END IF;
  END PROCESS;
END fsmd;
