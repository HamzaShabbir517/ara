// Copyright 2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Matheus Cavalcante <matheusd@iis.ee.ethz.ch>
//         Basile Bougenot <bbougenot@student.ethz.ch>

#include "vector_macros.h"


void TEST_CASE1(void) {
  VSET(4,e8,m1);
  VLOAD_8(v1,1,2,3,4);
  VLOAD_8(v2,1,2,3,4);
  __asm__ volatile ("vaaddu.vv v3, v1, v2"::);
  VEC_CMP_8(1,v3,1,2,3,4);
}

void TEST_CASE2(void) {
  VSET(4,e8,m1);
  VLOAD_8(v1,1,2,3,4);
  VLOAD_8(v2,1,2,3,4);
  VLOAD_8(v0,0x0A,0x00,0x00,0x00);
  CLEAR(v3);
  __asm__ volatile ("vaaddu.vv v3, v1, v2, v0.t"::);
  VEC_CMP_8(2,v3,0,2,0,4);
}

void TEST_CASE3(void) {
  VSET(4,e32,m1);
  VLOAD_U32(v1,1,2,3,4);
  const uint32_t scalar = 5;
  __asm__ volatile ("vaaddu.vx v3, v1, %[A]"::[A] "r" (scalar));
  VEC_CMP_U32(3,v3,3,4,4,5);
}

//Dont use VCLEAR here, it results in a glitch where are values are off by 1
void TEST_CASE4(void) {
  VSET(4,e32,m1);
  VLOAD_U32(v1,1,2,3,4);
  const uint32_t scalar = 5;
  VLOAD_U32(v0,0xA,0x0,0x0,0x0);
  CLEAR(v3);
  __asm__ volatile ("vaaddu.vx v3, v1, %[A], v0.t"::[A] "r" (scalar));
  VEC_CMP_U32(4,v3,0,4,0,5);
}

int main(void){
  INIT_CHECK();
  enable_vec();
  TEST_CASE1();
  TEST_CASE2();
  TEST_CASE3();
  TEST_CASE4();
  EXIT_CHECK();
}
