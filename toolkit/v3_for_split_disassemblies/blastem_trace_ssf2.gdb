set pagination off
set logging file trace_banks.txt
set logging overwrite on
set logging enabled on

target remote localhost:1234

watch *(unsigned char*)0xA130F1
commands
  silent
  printf "0x%06X | SSF2_SRAM_CTRL | 0x%02X | SRAM/ROM Toggle\n", $pc, *(unsigned char*)0xA130F1
  continue
end

watch *(unsigned char*)0xA130F3
commands
  silent
  printf "0x%06X | SSF2_BANK_1    | 0x%02X | Slot 1 ($080000-$0FFFFF)\n", $pc, *(unsigned char*)0xA130F3
  continue
end

watch *(unsigned char*)0xA130F5
commands
  silent
  printf "0x%06X | SSF2_BANK_2    | 0x%02X | Slot 2 ($100000-$17FFFF)\n", $pc, *(unsigned char*)0xA130F5
  continue
end

watch *(unsigned char*)0xA130F7
commands
  silent
  printf "0x%06X | SSF2_BANK_3    | 0x%02X | Slot 3 ($180000-$1FFFFF)\n", $pc, *(unsigned char*)0xA130F7
  continue
end

watch *(unsigned char*)0xA130F9
commands
  silent
  printf "0x%06X | SSF2_BANK_4    | 0x%02X | Slot 4 ($200000-$27FFFF)\n", $pc, *(unsigned char*)0xA130F9
  continue
end

watch *(unsigned char*)0xA130FB
commands
  silent
  printf "0x%06X | SSF2_BANK_5    | 0x%02X | Slot 5 ($280000-$2FFFFF)\n", $pc, *(unsigned char*)0xA130FB
  continue
end

watch *(unsigned char*)0xA130FD
commands
  silent
  printf "0x%06X | SSF2_BANK_6    | 0x%02X | Slot 6 ($300000-$37FFFF)\n", $pc, *(unsigned char*)0xA130FD
  continue
end

watch *(unsigned char*)0xA130FF
commands
  silent
  printf "0x%06X | SSF2_BANK_7    | 0x%02X | Slot 7 ($380000-$3FFFFF)\n", $pc, *(unsigned char*)0xA130FF
  continue
end

continue
