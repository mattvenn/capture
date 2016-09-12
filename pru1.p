// -*- mode: asm -*-
/*

Modified by Matt Venn for Arcola Energy 2016

Based on Prudaq: https://github.com/google/prudaq	

Copyright 2015 Google Inc. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or
implied.  See the License for the specific language governing
permissions and limitations under the License.
*/

.origin 0
.entrypoint TOP

#define DDR_START     r10
#define DDR_END       r11
#define DDR_SIZE      r12
#define WRITE_POINTER r13
#define SHARED_RAM    r14
#define SAMPLE        r15
#define BYTES_WRITTEN r16

/*
200mhz, so 1 instruction takes 5ns
reading 2 lots of 12bit data at 2mhz, so once every 250ns
*/
.macro NOP //5 instructions at 200mhz = 25 ns
MOV r1, r1
MOV r1, r1
MOV r1, r1
MOV r1, r1
MOV r1, r1
.endm


#include "shared_header.h"

TOP:
  // Enable OCP master ports in SYSCFG register
  lbco r0, C4, 4, 4
  clr  r0, r0, 4
  sbco r0, C4, 4, 4

  mov SHARED_RAM, SHARED_RAM_ADDRESS

  // From shared RAM, grab the address of the shared DDR segment
  lbbo DDR_START, SHARED_RAM, OFFSET(Params.physical_addr), SIZE(Params.physical_addr)
  // And the size of the segment
  lbbo DDR_SIZE, SHARED_RAM, OFFSET(Params.ddr_len), SIZE(Params.ddr_len)

  add DDR_END, DDR_START, DDR_SIZE

  // Write out the initial values of bytes_written and shared_ptr before we
  // enter the loop and have to wait for the first rising clock edge.
  mov BYTES_WRITTEN, 0
  sbbo BYTES_WRITTEN, SHARED_RAM, OFFSET(Params.bytes_written), SIZE(Params.bytes_written)
  mov WRITE_POINTER, DDR_START
  sbbo WRITE_POINTER, SHARED_RAM, OFFSET(Params.shared_ptr), SIZE(Params.shared_ptr)

  // First sample will be invalid (always 0) due to the way the loops are laid out.
  mov SAMPLE, 0
  
MAIN_LOOP:
  // Wait for rising clock edge
  wbs r31, 12
  NOP

  // Read channel 0 into the lower half of the sample register
  mov SAMPLE.w0, r31.w0

  // Wait for falling clock edge
  wbc r31, 12
  NOP

  // Read channel 1 into the upper half of the sample register
  mov SAMPLE.w2, r31.w0

  // we write the pair of samples from the previous high/low cycle to DDR
  // before reading in the data for the rising edge we just detected.
  // sbbo generally takes (1 + word count) cycles, so 2 in this case,
  // but can also take longer in the case of bus collisions.
  sbbo SAMPLE, WRITE_POINTER, 0, 4

  sbbo WRITE_POINTER, SHARED_RAM, OFFSET(Params.shared_ptr), SIZE(Params.shared_ptr)

  // Now we use our delay downtime to manage the counters
  add WRITE_POINTER, WRITE_POINTER, 4
  add BYTES_WRITTEN, BYTES_WRITTEN, 4
  sbbo BYTES_WRITTEN, SHARED_RAM, OFFSET(Params.bytes_written), SIZE(Params.bytes_written)

  // If we wrapped, reset the pointer to the start of the buffer.
  qblt MAIN_LOOP, DDR_END, WRITE_POINTER
  mov WRITE_POINTER, DDR_START

  qba MAIN_LOOP

// We loop forever, but I always end with halt so that I never forget.
halt
