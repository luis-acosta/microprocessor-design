# Microprocesador EC-2 — Proyecto VHDL Completo

Implementación completa del microprocesador EC-2 en VHDL, versión portable (sin dependencias de bibliotecas propietarias Altera/LPM).

## Arquitectura

- **8 instrucciones** con formato de 8 bits (3-bit opcode + 5-bit operando)
- **PC de 5 bits** → direcciona hasta 32 posiciones de memoria
- **RAM de 32×8** con programa precargado o desde archivo externo
- **8 señales de control**, 2 señales de estado (zero, positive)
- **Diseño FSM+D**: Unidad de Control (FSM) + Datapath (Structural)

### Set de Instrucciones

| Opcode | Instrucción | Descripción |
|--------|-------------|-------------|
| 000    | `LOAD d`    | Carga RAM[d] en el acumulador |
| 001    | `STORE d`   | Almacena acumulador en RAM[d] |
| 010    | `ADD d`     | Acumulador = Acumulador + RAM[d] |
| 011    | `SUB d`     | Acumulador = Acumulador - RAM[d] |
| 100    | `IN d`      | Lee entrada y almacena en RAM[d] |
| 101    | `JZ d`      | Salta a d si zero = 1 |
| 110    | `JPOS d`    | Salta a d si positive = 1 |
| 111    | `HALT`      | Detiene la ejecución |

## Archivos del Proyecto

### Top-Level
| Archivo | Descripción |
|---------|-------------|
| `mp.vhd` | Top-level structural — conecta CU + Datapath |

### Unidad de Control
| Archivo | Descripción |
|---------|-------------|
| `cu.vhd` | Control Unit — FSM con 8 estados (behavioral) |

### Datapath y Componentes
| Archivo | Estilo | Descripción |
|---------|--------|-------------|
| `dp.vhd` | Structural | Datapath con RAM interna (programa en constante INIT) |
| `dp_file.vhd` | Structural | Datapath con `ram_mif` — carga programa desde archivo `.mem` |
| `reg.vhd` | Behavioral | Registro genérico de N bits con enable y clear |
| `increment.vhd` | Dataflow | Incrementador genérico de N bits (PC + 1) |
| `mux2.vhd` | Dataflow | Multiplexor 2:1 genérico |
| `mux4.vhd` | Dataflow | Multiplexor 4:1 genérico (selección entrada acumulador) |
| `addsub.vhd` | Dataflow | Sumador/restador genérico de N bits |
| `ram.vhd` | Behavioral | RAM genérica 32×8 con programa precargado como constante |
| `ram_mif.vhd` | Behavioral | RAM genérica con carga desde archivo usando TEXTIO |

### Programa de Multiplicación (sumas sucesivas)
| Archivo | Descripción |
|---------|-------------|
| `multiply.mem` | Programa en binario (un valor de 8 bits por línea) — para `ram_mif.vhd` |
| `multiply.mif` | Memory Initialization File en formato Altera/Quartus |
| `multiply.txt` | Listado en ensamblador con comentarios detallados |

### Testbench
| Archivo | Descripción |
|---------|-------------|
| `mp_tb.vhd` | Testbench — verifica multiplicación 5 × 4 = 20 ✓ |

### Programa de Prueba Original
| Archivo | Descripción |
|---------|-------------|
| `programa.txt` | Programa de prueba en ensamblador EC-2 |
| `program.mif` | Memory Initialization File (para Quartus) |

### Versión Alternativa
| Archivo | Descripción |
|---------|-------------|
| `ec2_behavioral.vhd` | EC-2 completo en estilo behavioral (un solo archivo) |

## Estilos de Diseño VHDL Utilizados

- **Dataflow** (asignaciones concurrentes `WHEN-ELSE`, `WITH-SELECT`): para circuitos **combinacionales** — mux2, mux4, increment, addsub
- **Behavioral** (procesos `PROCESS` con sensibilidad al reloj): para circuitos **secuenciales** — reg, ram, ram_mif, cu
- **Structural** (instanciación de componentes `PORT MAP`): para la integración — dp, dp_file, mp

## Cómo Usar

### Opción A: RAM con programa interno (`dp.vhd`)

Usa `dp.vhd` — el programa está definido como constante `INIT` dentro de `ram.vhd`.

```bash
ghdl -a reg.vhd increment.vhd mux2.vhd mux4.vhd addsub.vhd ram.vhd
ghdl -a cu.vhd dp.vhd mp.vhd
ghdl -e mp
ghdl -r mp --stop-time=1000ns --vcd=mp.vcd
```

### Opción B: RAM con programa desde archivo (`dp_file.vhd`)

Usa `dp_file.vhd` + `ram_mif.vhd` — el programa se lee de `multiply.mem` (o cualquier `.mem`).

```bash
# Analizar componentes (usar dp_file.vhd en lugar de dp.vhd)
ghdl -a reg.vhd increment.vhd mux2.vhd mux4.vhd addsub.vhd ram_mif.vhd
ghdl -a cu.vhd dp_file.vhd mp.vhd

# Testbench de multiplicación (5 × 4 = 20)
ghdl -a mp_tb.vhd
ghdl -e mp_tb
ghdl -r mp_tb --vcd=mp_tb.vcd
```

Para cambiar el programa, editar `multiply.mem` o crear un nuevo archivo `.mem` y actualizar el generic `INIT_FILE` en `dp_file.vhd`.

### Formato del archivo `.mem`

Un valor binario de 8 bits por línea, 32 líneas en total (direcciones 0–31):

```
10000000    -- Dirección 0: IN
00111110    -- Dirección 1: STORE 30
...
```

### Intel Quartus Prime

1. Crear nuevo proyecto y agregar todos los archivos `.vhd`
2. Establecer `mp.vhd` como top-level entity
3. Cargar `program.mif` o `multiply.mif` en la RAM
4. Compilar y simular

## Algoritmo de Multiplicación por Sumas Sucesivas

```
Entrada: A (multiplicando), B (multiplicador)
resultado = 0
contador = B
MIENTRAS contador > 0:
    resultado = resultado + A
    contador = contador - 1
Salida: resultado = A × B
```

**Ejemplo verificado**: 5 × 4 = 5 + 5 + 5 + 5 = 20 ✓

## Referencia

Basado en el Capítulo 12 de:
> Hwang, E.O. *Digital Logic and Microprocessor Design with VHDL*. Thomson, 2005.

## Autor

Luis Acosta — PDI Advanced
