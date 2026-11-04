-- ==========================================================
-- RAM con carga de programa desde archivo externo
-- Compatible con GHDL, ModelSim, Vivado (simulacion)
-- ==========================================================
-- Formato del archivo: un valor binario por linea,
-- una linea por direccion (0, 1, 2, ...).
-- Las lineas faltantes se rellenan con ceros.
--
-- Ejemplo de archivo (multiply.mem):
--   10000000
--   00111110
--   10000000
--   ...
--
-- Para Quartus/sintesis: usar el .mif con lpm_ram_dq
-- o con la directiva ram_init_file (ver README).
-- ==========================================================
LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
USE std.textio.ALL;

ENTITY ram_mif IS
  GENERIC(
    ADDR_WIDTH : INTEGER := 5;       -- 5 bits -> 32 posiciones
    DATA_WIDTH : INTEGER := 8;       -- 8 bits de ancho
    INIT_FILE  : STRING  := "multiply.mem"  -- Archivo con programa
  );
  PORT(
    clock   : IN  STD_LOGIC;
    we      : IN  STD_LOGIC;
    address : IN  STD_LOGIC_VECTOR(ADDR_WIDTH-1 DOWNTO 0);
    data    : IN  STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);
    q       : OUT STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0)
  );
END ram_mif;

ARCHITECTURE Behavioral OF ram_mif IS

  TYPE memory_array IS ARRAY(0 TO 2**ADDR_WIDTH - 1)
    OF STD_LOGIC_VECTOR(DATA_WIDTH-1 DOWNTO 0);

  -- ==========================================================
  -- Funcion: lee archivo de texto y retorna memoria inicializada
  -- Cada linea del archivo contiene un valor binario de DATA_WIDTH bits
  -- Ejemplo linea: "10000000"
  -- ==========================================================
  IMPURE FUNCTION load_mem_file(filename : STRING) RETURN memory_array IS
    FILE     mem_file : TEXT;
    VARIABLE mem      : memory_array := (OTHERS => (OTHERS => '0'));
    VARIABLE line_buf : LINE;
    VARIABLE bit_char : CHARACTER;
    VARIABLE addr     : INTEGER := 0;
    VARIABLE good     : BOOLEAN;
    VARIABLE file_ok  : FILE_OPEN_STATUS;
  BEGIN
    -- Intentar abrir el archivo
    FILE_OPEN(file_ok, mem_file, filename, READ_MODE);

    IF file_ok = OPEN_OK THEN
      WHILE NOT ENDFILE(mem_file) AND addr < 2**ADDR_WIDTH LOOP
        READLINE(mem_file, line_buf);

        -- Saltar lineas vacias o comentarios (que empiecen con --)
        IF line_buf'LENGTH >= DATA_WIDTH THEN
          -- Leer cada bit del valor binario
          FOR i IN DATA_WIDTH-1 DOWNTO 0 LOOP
            READ(line_buf, bit_char, good);
            IF good THEN
              IF bit_char = '1' THEN
                mem(addr)(i) := '1';
              ELSE
                mem(addr)(i) := '0';
              END IF;
            END IF;
          END LOOP;
          addr := addr + 1;
        END IF;
      END LOOP;

      FILE_CLOSE(mem_file);
    ELSE
      -- Si no se encuentra el archivo, reportar advertencia
      REPORT "RAM: No se pudo abrir el archivo '" & filename &
             "'. Memoria inicializada a ceros."
        SEVERITY WARNING;
    END IF;

    RETURN mem;
  END FUNCTION;

  -- Inicializar memoria desde archivo
  SIGNAL memory : memory_array := load_mem_file(INIT_FILE);

BEGIN

  -- Escritura sincrona
  PROCESS(clock)
  BEGIN
    IF clock'EVENT AND clock = '1' THEN
      IF we = '1' THEN
        memory(to_integer(unsigned(address))) <= data;
      END IF;
    END IF;
  END PROCESS;

  -- Lectura combinacional (asincrona)
  q <= memory(to_integer(unsigned(address)));

END Behavioral;
