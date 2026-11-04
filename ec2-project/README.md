# Microprocesador EC-2 — Proyecto VHDL Completo

Implementación completa del microprocesador EC-2 en VHDL, versión portable (sin dependencias de bibliotecas propietarias Altera/LPM).

## Arquitectura

- **8 instrucciones** con formato de 8 bits (3-bit opcode + 5-bit operando)
- **PC de 5 bits** → direcciona hasta 32 posiciones de memoria
- **RAM de 32×8** con programa precargado
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
| `dp.vhd` | Structural | Datapath — instancia todos los componentes |
| `reg.vhd` | Behavioral | Registro de 8 bits con enable y clear |
| `increment.vhd` | Dataflow | Incrementador de 5 bits (PC + 1) |
| `mux2.vhd` | Dataflow | Multiplexor 2-a-1 de 8 bits |
| `mux4.vhd` | Dataflow | Multiplexor 4-a-1 de 5 bits (selección de PC) |
| `addsub.vhd` | Dataflow | Sumador/restador de 8 bits |
| `ram.vhd` | Behavioral | RAM genérica 32×8 con programa precargado |

### Programa de Prueba
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
- **Behavioral** (procesos `PROCESS` con sensibilidad al reloj): para circuitos **secuenciales** — reg, ram, cu
- **Structural** (instanciación de componentes `PORT MAP`): para la integración — dp, mp

## Cómo Usar

### Simulación con GHDL (open source)

```bash
# Analizar todos los componentes (orden importa por dependencias)
ghdl -a reg.vhd
ghdl -a increment.vhd
ghdl -a mux2.vhd
ghdl -a mux4.vhd
ghdl -a addsub.vhd
ghdl -a ram.vhd
ghdl -a cu.vhd
ghdl -a dp.vhd
ghdl -a mp.vhd

# Elaborar el top-level
ghdl -e mp

# Ejecutar simulación
ghdl -r mp --stop-time=1000ns --vcd=mp.vcd
```

### Intel Quartus Prime

1. Crear nuevo proyecto y agregar todos los archivos `.vhd`
2. Establecer `mp.vhd` como top-level entity
3. Cargar `program.mif` en la RAM (o usar la versión con constante `INIT`)
4. Compilar y simular

## Referencia

Basado en el Capítulo 12 de:
> Hwang, E.O. *Digital Logic and Microprocessor Design with VHDL*. Thomson, 2005.

## Autor

Luis Acosta — PDI Advanced
