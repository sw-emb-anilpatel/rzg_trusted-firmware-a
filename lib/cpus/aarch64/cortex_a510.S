/*
 * Copyright (c) 2023, Arm Limited. All rights reserved.
 *
 * SPDX-License-Identifier: BSD-3-Clause
 */

#include <arch.h>
#include <asm_macros.S>
#include <common/bl_common.h>
#include <cortex_a510.h>
#include <cpu_macros.S>
#include <plat_macros.S>

/* Hardware handled coherency */
#if HW_ASSISTED_COHERENCY == 0
#error "Cortex-A510 must be compiled with HW_ASSISTED_COHERENCY enabled"
#endif

/* 64-bit only core */
#if CTX_INCLUDE_AARCH32_REGS == 1
#error "Cortex-A510 supports only AArch64. Compile with CTX_INCLUDE_AARCH32_REGS=0"
#endif

	/* --------------------------------------------------
	 * Errata Workaround for Cortex-A510 Errata #1922240.
	 * This applies only to revision r0p0 (fixed in r0p1)
	 * x0: variant[4:7] and revision[0:3] of current cpu.
	 * Shall clobber: x0, x1, x17
	 * --------------------------------------------------
	 */
func errata_cortex_a510_1922240_wa
	/* Check workaround compatibility. */
	mov	x17, x30
	bl	check_errata_1922240
	cbz	x0, 1f

	/* Apply the workaround by setting IMP_CMPXACTLR_EL1[11:10] = 0b11. */
	mrs	x0, CORTEX_A510_CMPXACTLR_EL1
	mov	x1, #3
	bfi	x0, x1, #10, #2
	msr	CORTEX_A510_CMPXACTLR_EL1, x0

1:
	ret	x17
endfunc errata_cortex_a510_1922240_wa

func check_errata_1922240
	/* Applies to r0p0 only */
	mov	x1, #0x00
	b	cpu_rev_var_ls
endfunc check_errata_1922240

	/* --------------------------------------------------
	 * Errata Workaround for Cortex-A510 Errata #2288014.
	 * This applies only to revisions r0p0, r0p1, r0p2,
	 * r0p3 and r1p0. (fixed in r1p1)
	 * x0: variant[4:7] and revision[0:3] of current cpu.
	 * Shall clobber: x0, x1, x17
	 * --------------------------------------------------
	 */
func errata_cortex_a510_2288014_wa
	/* Check workaround compatibility. */
	mov	x17, x30
	bl	check_errata_2288014
	cbz	x0, 1f

	/* Apply the workaround by setting IMP_CPUACTLR_EL1[18] = 0b1. */
	mrs	x0, CORTEX_A510_CPUACTLR_EL1
	mov	x1, #1
	bfi	x0, x1, #18, #1
	msr	CORTEX_A510_CPUACTLR_EL1, x0

1:
	ret	x17
endfunc errata_cortex_a510_2288014_wa

func check_errata_2288014
	/* Applies to r1p0 and below */
	mov	x1, #0x10
	b	cpu_rev_var_ls
endfunc check_errata_2288014

	/* --------------------------------------------------
	 * Errata Workaround for Cortex-A510 Errata #2042739.
	 * This applies only to revisions r0p0, r0p1 and r0p2.
	 * (fixed in r0p3)
	 * x0: variant[4:7] and revision[0:3] of current cpu.
	 * Shall clobber: x0, x1, x17
	 * --------------------------------------------------
	 */
func errata_cortex_a510_2042739_wa
	/* Check workaround compatibility. */
	mov	x17, x30
	bl	check_errata_2042739
	cbz	x0, 1f

	/* Apply the workaround by disabling ReadPreferUnique. */
	mrs	x0, CORTEX_A510_CPUECTLR_EL1
	mov	x1, #CORTEX_A510_CPUECTLR_EL1_READPREFERUNIQUE_DISABLE
	bfi	x0, x1, #CORTEX_A510_CPUECTLR_EL1_READPREFERUNIQUE_SHIFT, #1
	msr	CORTEX_A510_CPUECTLR_EL1, x0

1:
	ret	x17
endfunc errata_cortex_a510_2042739_wa

func check_errata_2042739
	/* Applies to revisions r0p0 - r0p2 */
	mov	x1, #0x02
	b	cpu_rev_var_ls
endfunc check_errata_2042739

	/* --------------------------------------------------
	 * Errata Workaround for Cortex-A510 Errata #2041909.
	 * This applies only to revision r0p2 and it is fixed in
	 * r0p3. The issue is also present in r0p0 and r0p1 but
	 * there is no workaround in those revisions.
	 * x0: variant[4:7] and revision[0:3] of current cpu.
	 * Shall clobber: x0, x1, x2, x17
	 * --------------------------------------------------
	 */
func errata_cortex_a510_2041909_wa
	/* Check workaround compatibility. */
	mov	x17, x30
	bl	check_errata_2041909
	cbz	x0, 1f

	/* Apply workaround */
	mov	x0, xzr
	msr	S3_6_C15_C4_0, x0
	isb

	mov	x0, #0x8500000
	msr	S3_6_C15_C4_2, x0

	mov	x0, #0x1F700000
	movk	x0, #0x8, lsl #32
	msr	S3_6_C15_C4_3, x0

	mov	x0, #0x3F1
	movk	x0, #0x110, lsl #16
	msr	S3_6_C15_C4_1, x0
	isb

1:
	ret	x17
endfunc errata_cortex_a510_2041909_wa

func check_errata_2041909
	/* Applies only to revision r0p2 */
	mov	x1, #0x02
	mov	x2, #0x02
	b	cpu_rev_var_range
endfunc check_errata_2041909

	/* --------------------------------------------------
	 * Errata Workaround for Cortex-A510 Errata #2250311.
	 * This applies only to revisions r0p0, r0p1, r0p2,
	 * r0p3 and r1p0, and is fixed in r1p1.
	 * This workaround is not a typical errata fix. MPMM
	 * is disabled here, but this conflicts with the BL31
	 * MPMM support. So in addition to simply disabling
	 * the feature, a flag is set in the MPMM library
	 * indicating that it should not be enabled even if
	 * ENABLE_MPMM=1.
	 * x0: variant[4:7] and revision[0:3] of current cpu.
	 * Shall clobber: x0, x1, x17
	 * --------------------------------------------------
	 */
func errata_cortex_a510_2250311_wa
	/* Check workaround compatibility. */
	mov	x17, x30
	bl	check_errata_2250311
	cbz	x0, 1f

	/* Disable MPMM */
	mrs	x0, CPUMPMMCR_EL3
	bfm	x0, xzr, #0, #0 /* bfc instruction does not work in GCC */
	msr	CPUMPMMCR_EL3, x0

#if ENABLE_MPMM && IMAGE_BL31
	/* If ENABLE_MPMM is set, tell the runtime lib to skip enabling it. */
	bl mpmm_errata_disable
#endif

1:
	ret x17
endfunc errata_cortex_a510_2250311_wa

func check_errata_2250311
	/* Applies to r1p0 and lower */
	mov	x1, #0x10
	b	cpu_rev_var_ls
endfunc check_errata_2250311

	/* --------------------------------------------------
	 * Errata Workaround for Cortex-A510 Errata #2218950.
	 * This applies only to revisions r0p0, r0p1, r0p2,
	 * r0p3 and r1p0, and is fixed in r1p1.
	 * x0: variant[4:7] and revision[0:3] of current cpu.
	 * Shall clobber: x0, x1, x17
	 * --------------------------------------------------
	 */
func errata_cortex_a510_2218950_wa
	/* Check workaround compatibility. */
	mov	x17, x30
	bl	check_errata_2218950
	cbz	x0, 1f

	/* Source register for BFI */
	mov	x1, #1

	/* Set bit 18 in CPUACTLR_EL1 */
	mrs	x0, CORTEX_A510_CPUACTLR_EL1
	bfi	x0, x1, #18, #1
	msr	CORTEX_A510_CPUACTLR_EL1, x0

	/* Set bit 25 in CMPXACTLR_EL1 */
	mrs	x0, CORTEX_A510_CMPXACTLR_EL1
	bfi	x0, x1, #25, #1
	msr	CORTEX_A510_CMPXACTLR_EL1, x0

1:
	ret x17
endfunc errata_cortex_a510_2218950_wa

func check_errata_2218950
	/* Applies to r1p0 and lower */
	mov	x1, #0x10
	b	cpu_rev_var_ls
endfunc check_errata_2218950

	/* --------------------------------------------------
	 * Errata Workaround for Cortex-A510 Errata #2172148.
	 * This applies only to revisions r0p0, r0p1, r0p2,
	 * r0p3 and r1p0, and is fixed in r1p1.
	 * x0: variant[4:7] and revision[0:3] of current cpu.
	 * Shall clobber: x0, x1, x17
	 * --------------------------------------------------
	 */
func errata_cortex_a510_2172148_wa
	/* Check workaround compatibility. */
	mov	x17, x30
	bl	check_errata_2172148
	cbz	x0, 1f

	/*
	 * Force L2 allocation of transient lines by setting
	 * CPUECTLR_EL1.RSCTL=0b01 and CPUECTLR_EL1.NTCTL=0b01.
	 */
	mrs	x0, CORTEX_A510_CPUECTLR_EL1
	mov	x1, #1
	bfi	x0, x1, #CORTEX_A510_CPUECTLR_EL1_RSCTL_SHIFT, #2
	bfi	x0, x1, #CORTEX_A510_CPUECTLR_EL1_NTCTL_SHIFT, #2
	msr	CORTEX_A510_CPUECTLR_EL1, x0

1:
	ret x17
endfunc errata_cortex_a510_2172148_wa

func check_errata_2172148
	/* Applies to r1p0 and lower */
	mov	x1, #0x10
	b	cpu_rev_var_ls
endfunc check_errata_2172148

	/* ----------------------------------------------------
	 * Errata Workaround for Cortex-A510 Errata #2347730.
	 * This applies to revisions r0p0 - r0p3, r1p0, r1p1.
	 * It is fixed in r1p2.
	 * Inputs:
	 * x0: variant[4:7] and revision[0:3] of current cpu.
	 * Shall clobber: x0-x1, x17
	 * ----------------------------------------------------
	 */
func errata_cortex_a510_2347730_wa
	mov	x17, x30
	bl	check_errata_2347730
	cbz	x0, 1f

	/*
	 * Set CPUACTLR_EL1[17] to 1'b1, which disables
	 * specific microarchitectural clock gating
	 * behaviour.
	 */
	mrs	x1, CORTEX_A510_CPUACTLR_EL1
	orr	x1, x1, CORTEX_A510_CPUACTLR_EL1_BIT_17
	msr	CORTEX_A510_CPUACTLR_EL1, x1
1:
	ret x17
endfunc errata_cortex_a510_2347730_wa

func check_errata_2347730
	/* Applies to revisions r1p1 and lower. */
	mov	x1, #0x11
	b	cpu_rev_var_ls
endfunc check_errata_2347730

	/*---------------------------------------------------
	 * Errata Workaround for Cortex-A510 Errata #2371937.
	 * This applies to revisions r1p1 and lower, and is
	 * fixed in r1p2.
	 * Inputs:
	 * x0: variant[4:7] and revision[0:3] of current cpu.
	 * Shall clobber: x0, x1, x17
	 *---------------------------------------------------
	 */
func errata_cortex_a510_2371937_wa
	mov	x17, x30
	bl	check_errata_2371937
	cbz	x0, 1f

	/*
	 * Cacheable atomic operations can be forced
	 * to be executed near by setting
	 * IMP_CPUECTLR_EL1.ATOM=0b010. ATOM is found
	 * in [40:38] of CPUECTLR_EL1.
	 */
	mrs 	x0, CORTEX_A510_CPUECTLR_EL1
	mov 	x1, CORTEX_A510_CPUECTLR_EL1_ATOM_EXECALLINSTRNEAR
	bfi 	x0, x1, CORTEX_A510_CPUECTLR_EL1_ATOM, #3
	msr 	CORTEX_A510_CPUECTLR_EL1, x0
1:
	ret 	x17
endfunc errata_cortex_a510_2371937_wa

func check_errata_2371937
	/* Applies to r1p1 and lower */
	mov 	x1, #0x11
	b	cpu_rev_var_ls
endfunc check_errata_2371937

	/* ------------------------------------------------------
	 * Errata Workaround for Cortex-A510 Errata #2666669
	 * This applies to revisions r1p1 and lower, and is fixed
	 * in r1p2.
	 * Inputs:
	 * x0: variant[4:7] and revision[0:3] of current cpu.
	 * Shall clobber: x0, x1, x17
	 * ------------------------------------------------------
	 */
func errata_cortex_a510_2666669_wa
	mov	x17, x30
	bl	check_errata_2666669
	cbz	x0, 1f

	/*
	 * Workaround will set IMP_CPUACTLR_EL1[38]
	 * to 0b1.
	 */
	mrs	x1, CORTEX_A510_CPUACTLR_EL1
	orr	x1, x1, CORTEX_A510_CPUACTLR_EL1_BIT_38
	msr	CORTEX_A510_CPUACTLR_EL1, x1
1:
	ret	x17
endfunc errata_cortex_a510_2666669_wa

func check_errata_2666669
	/* Applies to r1p1 and lower */
	mov	x1, #0x11
	b	cpu_rev_var_ls
endfunc check_errata_2666669

/* ------------------------------------------------------
 * Errata Workaround for Cortex-A510 Erratum 2684597.
 * This erratum applies to revision r0p0, r0p1, r0p2,
 * r0p3, r1p0, r1p1 and r1p2 of the Cortex-A510 cpu and
 * is fixed in r1p3.
 * Shall clobber: x0-x17
 * ------------------------------------------------------
 */
	.globl	errata_cortex_a510_2684597_wa
func errata_cortex_a510_2684597_wa
	mov	x17, x30
	/* Ensure this errata is only applied to Cortex-A510 cores */
	jump_if_cpu_midr	CORTEX_A510_MIDR,	1f
	b	2f

1:
	/* Check workaround compatibility. */
	mov	x0, x18
	bl	check_errata_2684597
	cbz	x0, 2f

	/*
	 * Many assemblers do not yet understand the "tsb csync" mnemonic,
	 * so use the equivalent hint instruction.
	 */
	hint	#18			/* tsb csync */
2:
	ret	x17
endfunc errata_cortex_a510_2684597_wa
/* ------------------------------------------------------
 * Errata Workaround for Cortex-A510 Erratum 2684597.
 * This erratum applies to revision r0p0, r0p1, r0p2,
 * r0p3, r1p0, r1p1 and r1p2 of the Cortex-A510 cpu and
 * is fixed in r1p3.
 * Shall clobber: x0-x17
 * ------------------------------------------------------
 */
func check_errata_2684597
	/* Applies to revision < r1p3 */
	mov	x1, #0x12
	b	cpu_rev_var_ls
endfunc check_errata_2684597

	/* ----------------------------------------------------
	 * HW will do the cache maintenance while powering down
	 * ----------------------------------------------------
	 */
func cortex_a510_core_pwr_dwn
	/* ---------------------------------------------------
	 * Enable CPU power down bit in power control register
	 * ---------------------------------------------------
	 */
	mrs	x0, CORTEX_A510_CPUPWRCTLR_EL1
	orr	x0, x0, #CORTEX_A510_CPUPWRCTLR_EL1_CORE_PWRDN_BIT
	msr	CORTEX_A510_CPUPWRCTLR_EL1, x0
	isb
	ret
endfunc cortex_a510_core_pwr_dwn

	/*
	 * Errata printing function for Cortex-A510. Must follow AAPCS.
	 */
#if REPORT_ERRATA
func cortex_a510_errata_report
	stp	x8, x30, [sp, #-16]!

	bl	cpu_get_rev_var
	mov	x8, x0

	/*
	 * Report all errata. The revision-variant information is passed to
	 * checking functions of each errata.
	 */
	report_errata ERRATA_A510_1922240, cortex_a510, 1922240
	report_errata ERRATA_A510_2041909, cortex_a510, 2041909
	report_errata ERRATA_A510_2042739, cortex_a510, 2042739
	report_errata ERRATA_A510_2172148, cortex_a510, 2172148
	report_errata ERRATA_A510_2218950, cortex_a510, 2218950
	report_errata ERRATA_A510_2250311, cortex_a510, 2250311
	report_errata ERRATA_A510_2288014, cortex_a510, 2288014
	report_errata ERRATA_A510_2347730, cortex_a510, 2347730
	report_errata ERRATA_A510_2371937, cortex_a510, 2371937
	report_errata ERRATA_A510_2666669, cortex_a510, 2666669
	report_errata ERRATA_A510_2684597, cortex_a510, 2684597
	report_errata ERRATA_DSU_2313941, cortex_a510, dsu_2313941

	ldp	x8, x30, [sp], #16
	ret
endfunc cortex_a510_errata_report
#endif

func cortex_a510_reset_func
	mov	x19, x30

	/* Disable speculative loads */
	msr	SSBS, xzr

	/* Get the CPU revision and stash it in x18. */
	bl	cpu_get_rev_var
	mov	x18, x0

#if ERRATA_DSU_2313941
	bl	errata_dsu_2313941_wa
#endif

#if ERRATA_A510_1922240
	mov	x0, x18
	bl	errata_cortex_a510_1922240_wa
#endif

#if ERRATA_A510_2288014
	mov	x0, x18
	bl	errata_cortex_a510_2288014_wa
#endif

#if ERRATA_A510_2042739
	mov	x0, x18
	bl	errata_cortex_a510_2042739_wa
#endif

#if ERRATA_A510_2041909
	mov	x0, x18
	bl	errata_cortex_a510_2041909_wa
#endif

#if ERRATA_A510_2250311
	mov	x0, x18
	bl	errata_cortex_a510_2250311_wa
#endif

#if ERRATA_A510_2218950
	mov	x0, x18
	bl	errata_cortex_a510_2218950_wa
#endif

#if ERRATA_A510_2371937
	mov 	x0, x18
	bl	errata_cortex_a510_2371937_wa
#endif

#if ERRATA_A510_2172148
	mov	x0, x18
	bl	errata_cortex_a510_2172148_wa
#endif

#if ERRATA_A510_2347730
	mov	x0, x18
	bl	errata_cortex_a510_2347730_wa
#endif

#if ERRATA_A510_2666669
	mov	x0, x18
	bl	errata_cortex_a510_2666669_wa
#endif

	isb
	ret	x19
endfunc cortex_a510_reset_func

	/* ---------------------------------------------
	 * This function provides Cortex-A510 specific
	 * register information for crash reporting.
	 * It needs to return with x6 pointing to
	 * a list of register names in ascii and
	 * x8 - x15 having values of registers to be
	 * reported.
	 * ---------------------------------------------
	 */
.section .rodata.cortex_a510_regs, "aS"
cortex_a510_regs:  /* The ascii list of register names to be reported */
	.asciz	"cpuectlr_el1", ""

func cortex_a510_cpu_reg_dump
	adr	x6, cortex_a510_regs
	mrs	x8, CORTEX_A510_CPUECTLR_EL1
	ret
endfunc cortex_a510_cpu_reg_dump

declare_cpu_ops cortex_a510, CORTEX_A510_MIDR, \
	cortex_a510_reset_func, \
	cortex_a510_core_pwr_dwn
