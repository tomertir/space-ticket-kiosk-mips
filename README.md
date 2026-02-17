# Space Shuttle Ticket Kiosk 

A ticket vending machine simulation written in MIPS assembly, built as part of a Computer Architecture course at Ben-Gurion University.

## Overview

This project implements an interactive space travel ticket kiosk that accepts payment, validates bills, calculates change, manages seat inventory, and includes an administrative "Commander Mode" for updating availability.

## Features

### Part 1 - Basic Kiosk
-  Four space destinations with different prices
-  Bill validation (accepts 1, 5, 10, 20 credit bills)
-  Change calculation
-  Input validation with 3-attempt limit
-  Ticket dispensing with confirmation

### Part 2 - Enhanced Kiosk
All features from Part 1, plus:
-  **Real-time inventory tracking** — displays available seats for each destination
-  **Sold-out prevention** — blocks purchases when seats = 0
-  **Commander Mode** — PIN-protected admin panel (PIN: 2025)
-  **Inventory management** — update seat counts for all destinations
-  **Continuous operation** — loops back to menu after each transaction
-  **Exit option** — graceful shutdown

## Destinations & Prices

| Destination | Price (Credits) | Initial Seats |
|-------------|----------------|---------------|
|  Luna City | 75 | 5 |
|  Mars Dunes | 120 | 3 |
|  Europa Geysers | 90 | 4 |
|  Titan Lakes | 55 | 6 |

## MIPS Concepts Demonstrated

- **Stack Management** — proper push/pop of `$ra` and saved registers
- **Function Calls** — modular design with `jal`/`jr`
- **Arrays** — price and seat inventory stored in `.data` section
- **Control Flow** — branching, loops, validation logic
- **Input/Output** — syscalls for reading integers and printing strings
- **Register Convention** — proper use of `$s`, `$t`, `$a`, `$v` registers
- **Memory Access** — loading/storing words with calculated offsets

## How to Run

**Requirements:** MARS MIPS Simulator or QtSpim

### Using MARS
1. Open `Part1.asm` or `Part2.asm` in MARS
2. Assemble: `Run → Assemble`
3. Execute: `Run → Go`
4. Follow the on-screen prompts

### Example Session (Part 2)
```
=== Space Shuttle Ticket Kiosk ===
1) Luna City ......... 75 (Seats: 5)
2) Mars Dunes ........ 120 (Seats: 3)
3) Europa Geysers .... 90 (Seats: 4)
4) Titan Lakes ....... 55 (Seats: 6)
0) Commander Mode
9) Exit Kiosk
Enter choice:
2
Insert bill (1, 5, 10, 20):
20
Total inserted: 20 credits
Insert bill (1, 5, 10, 20):
100
Invalid bill. Attempts left: 2
...
```

## Code Structure

### Part 1 Functions
- `DisplayMenu` — prints destination list
- `HandleSelection` — validates user choice (1-4)
- `InsertCredits` — handles payment with validation
- `DispenseTicket` — prints ticket and calculates change

### Part 2 Functions (Additional)
- `PrintSeatHelper` — displays seat availability
- `CommanderMode` — PIN validation and admin access
- `UpdateSeatSingle` — updates inventory for one destination
- Enhanced `HandleSelection` — checks for options 0 and 9
- Enhanced `DispenseTicket` — decrements seat count

## Technologies

- MIPS Assembly (32-bit)
- MARS Simulator
- System calls for I/O operations

## Course

Computer Architecture — Ben-Gurion University of the Negev
