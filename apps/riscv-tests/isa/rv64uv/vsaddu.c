// Copyright 2021 ETH Zurich and University of Bologna.
// Solderpad Hardware License, Version 0.51, see LICENSE for details.
// SPDX-License-Identifier: SHL-0.51
//
// Author: Matheus Cavalcante <matheusd@iis.ee.ethz.ch>
//         Basile Bougenot <bbougenot@student.ethz.ch>

#include "vector_macros.h"


void TEST_CASE1(void) {
  VSET(4,e8,m1);
  VLOAD_8(v1,133,2,220,4);
  VLOAD_8(v2,133,2,50,4);
  __asm__ volatile ("vsaddu.vv v3, v1, v2"::);
  VEC_CMP_8(1,v3,255,4,255,8);
}

void TEST_CASE2(void) {
  VSET(4,e8,m1);
  VLOAD_8(v1,1,2,3,154);
  VLOAD_8(v2,1,2,3,124);
  VLOAD_8(v0,0xA,0x0,0x0,0x0);
  CLEAR(v3);
  __asm__ volatile ("vsaddu.vv v3, v1, v2, v0.t"::);
  VEC_CMP_8(2,v3,0,4,0,255);
}

void TEST_CASE3(void) {
  VSET(4,e32,m1);
  VLOAD_U32(v1,1,0xFFFFFFFB,3,4);
  __asm__ volatile ("vsaddu.vi v3, v1, 5"::);
  VEC_CMP_U32(3,v3,6,0xFFFFFFFF,8,9);
}

//Dont use VCLEAR here, it results in a glitch where are values are off by 1
void TEST_CASE4(void) {
  VSET(4,e32,m1);
  VLOAD_U32(v1,1,2,0xFFFFFFFD,0xFFFFFFFC);
  VLOAD_32(v0,0xA,0x0,0x0,0x0);
  CLEAR(v3);
  __asm__ volatile ("vsaddu.vi v3, v1, 5, v0.t"::);
  VEC_CMP_U32(4,v3,0,7,0,0xFFFFFFFF);
}

void TEST_CASE5(void) {
  VSET(4,e32,m1);
  VLOAD_32(v1,0xFFFFFFFD,2,3,4);
  const uint32_t scalar = 5;
  __asm__ volatile ("vsaddu.vx v3, v1, %[A]"::[A] "r" (scalar));
  VEC_CMP_32(5,v3,0xFFFFFFFF,7,8,9);
}

//Dont use VCLEAR here, it results in a glitch where are values are off by 1
void TEST_CASE6(void) {
  VSET(4,e32,m1);
  VLOAD_U32(v1,1,0xfffffffC,3,4);
  const uint32_t scalar = 5;
  VLOAD_U32(v0,0xA,0x0,0x0,0x0);
  CLEAR(v3);
  __asm__ volatile ("vsaddu.vx v3, v1, %[A], v0.t"::[A] "r" (scalar));
  VEC_CMP_U32(6,v3,0,0xFFFFFFFF,0,9);

}



int main(void){
  INIT_CHECK();
  enable_vec();
  enable_fp();
  TEST_CASE1();
  TEST_CASE2();
  TEST_CASE3();
  TEST_CASE4();
  TEST_CASE5();
  TEST_CASE6();
  EXIT_CHECK();
}
