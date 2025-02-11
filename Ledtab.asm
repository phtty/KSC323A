;--------COM------------
c0		EQU		0
c1		EQU		1
c2		EQU		2
c3		EQU		3
c4		EQU		4
c5		EQU		5
;;--------SEG------------
s44		EQU		44
s43		EQU		43
s42		EQU		42
s41		EQU		41
s40		EQU		40
s39		EQU		39
s38		EQU		38
s37		EQU		37
s36		EQU		36
s35		EQU		35
s34		EQU		34
s33		EQU		33
s32		EQU		32
s31		EQU		31
s30		EQU		30
s29		EQU		29
s28		EQU		28
s27		EQU		27
s26		EQU		26
s25		EQU		25
s24		EQU		24
s23		EQU		23
s22		EQU		22
s21		EQU		21
s20		EQU		20
s19		EQU		19
s18		EQU		18
s17		EQU		17
s16		EQU		16
s15		EQU		15
s14		EQU		14
s13		EQU		13
s12		EQU		12
s11		EQU		11
s10		EQU		10
s9		EQU		9
s8		EQU		8
s7		EQU		7
s6		EQU		6
s5		EQU		5
s4		EQU		4
s3		EQU		3
s2		EQU		2
s1		EQU		1
s0		EQU		0

; LED显示，每个COM占用4个byte
.MACRO	db_c_s	com,seg
		.byte	com*4+seg/8
.ENDMACRO

.MACRO	db_c_y	com,seg
		.byte	1.shl.(seg-seg/8*8)
.ENDMACRO

Led_byte:							;段码<==>SEG/COM表
led_table1:
led_d0	equ	$-led_table1
	db_c_s	c0,s27	; 0a
	db_c_s	c1,s26	; 0b
	db_c_s	c2,s26	; 0c
	db_c_s	c2,s27	; 0d
	db_c_s	c2,s28	; 0e
	db_c_s	c1,s28	; 0f
	db_c_s	c1,s27	; 0g

led_d1	equ	$-led_table1
	db_c_s	c0,s24	; 1a
	db_c_s	c1,s23	; 1b
	db_c_s	c2,s23	; 1c
	db_c_s	c2,s24	; 1d
	db_c_s	c2,s25	; 1e
	db_c_s	c1,s25	; 1f
	db_c_s	c1,s24	; 1g

led_d2	equ	$-led_table1
	db_c_s	c0,s20	; 2a
	db_c_s	c1,s19	; 2b
	db_c_s	c2,s19	; 2c
	db_c_s	c2,s20	; 2d
	db_c_s	c2,s21	; 2e
	db_c_s	c1,s21	; 2f
	db_c_s	c1,s20	; 2g

led_d3	equ	$-led_table1
	db_c_s	c0,s17	; 3a
	db_c_s	c1,s16	; 3b
	db_c_s	c2,s16	; 3c
	db_c_s	c2,s17	; 3d
	db_c_s	c2,s18	; 3e
	db_c_s	c1,s18	; 3f
	db_c_s	c1,s17	; 3g

led_d4	equ	$-led_table1
	db_c_s	c0,s15	; 4b
	db_c_s	c2,s15	; 4c
led_minus	equ	$-led_table1
	db_c_s	c1,s15	; 4g

led_d5	equ	$-led_table1
	db_c_s	c0,s13	; 5a
	db_c_s	c0,s12	; 5b
	db_c_s	c2,s13	; 5c
	db_c_s	c2,s14	; 5d
	db_c_s	c1,s14	; 5e
	db_c_s	c0,s14	; 5f
	db_c_s	c1,s13	; 5g

led_d6	equ	$-led_table1
	db_c_s	c0,s11	; 6a
	db_c_s	c1,s10	; 6b
	db_c_s	c2,s10	; 6c
	db_c_s	c2,s11	; 6d
	db_c_s	c2,s12	; 6e
	db_c_s	c1,s12	; 6f
	db_c_s	c1,s11	; 6g

led_d7	equ	$-led_table1
	db_c_s	c1,s7	; 7a
	db_c_s	c2,s7	; 7b
	db_c_s	c2,s8	; 7c
	db_c_s	c2,s9	; 7d
	db_c_s	c1,s9	; 7e
	db_c_s	c0,s9	; 7f
	db_c_s	c1,s8	; 7g

led_d8	equ	$-led_table1
	db_c_s	c0,s5	; 8a
	db_c_s	c0,s4	; 8b
	db_c_s	c2,s5	; 8c
	db_c_s	c2,s6	; 8d
	db_c_s	c1,s6	; 8e
	db_c_s	c0,s6	; 8f
	db_c_s	c1,s5	; 8g

led_d9	equ	$-led_table1
	db_c_s	c0,s3	; 9a
	db_c_s	c1,s2	; 9b
	db_c_s	c2,s2	; 9c
	db_c_s	c2,s3	; 9d
	db_c_s	c2,s4	; 9e
	db_c_s	c1,s4	; 9f
	db_c_s	c1,s3	; 9g

led_dot:
led_week1	equ	$-led_table1
led_SUN1	equ	$-led_table1
	db_c_s	c2,s31	; SUN1
led_MON1	equ	$-led_table1
	db_c_s	c0,s30	; MON1
led_TUE1	equ	$-led_table1
	db_c_s	c0,s28	; TUE1
led_WED1	equ	$-led_table1
	db_c_s	c0,s25	; WED1
led_THU1	equ	$-led_table1
	db_c_s	c0,s22	; THU1
led_FRI1	equ	$-led_table1
	db_c_s	c0,s19	; FRI1
led_SAT1	equ	$-led_table1
	db_c_s	c0,s16	; SAT1

led_week2	equ	$-led_table1
led_SUN2	equ	$-led_table1
	db_c_s	c0,s31	; SUN2
led_MON2	equ	$-led_table1
	db_c_s	c0,s29	; MON2
led_TUE2	equ	$-led_table1
	db_c_s	c0,s26	; TUE2
led_WED2	equ	$-led_table1
	db_c_s	c0,s23	; WED2
led_THU2	equ	$-led_table1
	db_c_s	c0,s21	; THU2
led_FRI2	equ	$-led_table1
	db_c_s	c0,s18	; FRI2
led_SAT2	equ	$-led_table1
	db_c_s	c1,s31	; SAT2


led_PM		equ	$-led_table1
	db_c_s	c1,s29	; PM
led_AL1		equ	$-led_table1
	db_c_s	c2,s29	; AL1
led_AL2		equ	$-led_table1
	db_c_s	c1,s30	; AL2
led_AL3		equ	$-led_table1
	db_c_s	c2,s30	; AL3
led_COL1	equ	$-led_table1
	db_c_s	c1,s22	; COL1
led_COL2	equ	$-led_table1
	db_c_s	c2,s22	; COL2
led_TMP		equ	$-led_table1
	db_c_s	c0,s10	; TEMP
led_Per1	equ	$-led_table1
	db_c_s	c1,s1	; Percent1
led_Per2	equ	$-led_table1
	db_c_s	c2,s1	; Percent2

;==========================================================
;==========================================================

Led_bit:
	db_c_y	c0,s27	; 0a
	db_c_y	c1,s26	; 0b
	db_c_y	c2,s26	; 0c
	db_c_y	c2,s27	; 0d
	db_c_y	c2,s28	; 0e
	db_c_y	c1,s28	; 0f
	db_c_y	c1,s27	; 0g

	db_c_y	c0,s24	; 1a
	db_c_y	c1,s23	; 1b
	db_c_y	c2,s23	; 1c
	db_c_y	c2,s24	; 1d
	db_c_y	c2,s25	; 1e
	db_c_y	c1,s25	; 1f
	db_c_y	c1,s24	; 1g

	db_c_y	c0,s20	; 2a
	db_c_y	c1,s19	; 2b
	db_c_y	c2,s19	; 2c
	db_c_y	c2,s20	; 2d
	db_c_y	c2,s21	; 2e
	db_c_y	c1,s21	; 2f
	db_c_y	c1,s20	; 2g

	db_c_y	c0,s17	; 3a
	db_c_y	c1,s16	; 3b
	db_c_y	c2,s16	; 3c
	db_c_y	c2,s17	; 3d
	db_c_y	c2,s18	; 3e
	db_c_y	c1,s18	; 3f
	db_c_y	c1,s17	; 3g

	db_c_y	c0,s15	; 4b
	db_c_y	c2,s15	; 4c
	db_c_y	c1,s15	; 4g

	db_c_y	c0,s13	; 5a
	db_c_y	c0,s12	; 5b
	db_c_y	c2,s13	; 5c
	db_c_y	c2,s14	; 5d
	db_c_y	c1,s14	; 5e
	db_c_y	c0,s14	; 5f
	db_c_y	c1,s13	; 5g

	db_c_y	c0,s11	; 6a
	db_c_y	c1,s10	; 6b
	db_c_y	c2,s10	; 6c
	db_c_y	c2,s11	; 6d
	db_c_y	c2,s12	; 6e
	db_c_y	c1,s12	; 6f
	db_c_y	c1,s11	; 6g

	db_c_y	c1,s7	; 7a
	db_c_y	c2,s7	; 7b
	db_c_y	c2,s8	; 7c
	db_c_y	c2,s9	; 7d
	db_c_y	c1,s9	; 7e
	db_c_y	c0,s9	; 7f
	db_c_y	c1,s8	; 7g

	db_c_y	c0,s5	; 8a
	db_c_y	c0,s4	; 8b
	db_c_y	c2,s5	; 8c
	db_c_y	c2,s6	; 8d
	db_c_y	c1,s6	; 8e
	db_c_y	c0,s6	; 8f
	db_c_y	c1,s5	; 8g

	db_c_y	c0,s3	; 9a
	db_c_y	c1,s2	; 9b
	db_c_y	c2,s2	; 9c
	db_c_y	c2,s3	; 9d
	db_c_y	c2,s4	; 9e
	db_c_y	c1,s4	; 9f
	db_c_y	c1,s3	; 9g

	db_c_y	c2,s31	; SUN1
	db_c_y	c0,s30	; MON1
	db_c_y	c0,s28	; TUE1
	db_c_y	c0,s25	; WED1
	db_c_y	c0,s22	; THU1
	db_c_y	c0,s19	; FRI1
	db_c_y	c0,s16	; SAT1

	db_c_y	c0,s31	; SUN2
	db_c_y	c0,s29	; MON2
	db_c_y	c0,s26	; TUE2
	db_c_y	c0,s23	; WED2
	db_c_y	c0,s21	; THU2
	db_c_y	c0,s18	; FRI2
	db_c_y	c1,s31	; SAT2


	db_c_y	c1,s29	; PM
	db_c_y	c2,s29	; AL1
	db_c_y	c1,s30	; AL2
	db_c_y	c2,s30	; AL3
	db_c_y	c1,s22	; COL1
	db_c_y	c2,s22	; COL2
	db_c_y	c0,s10	; TEMP
	db_c_y	c1,s1	; Percent1
	db_c_y	c2,s1	; Percent2
