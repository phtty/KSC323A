;--------COM------------
c0		.equ	0
c1		.equ	1
c2		.equ	2
c3		.equ	3
c4		.equ	4
c5		.equ	5
;;--------SEG------------
s44		.equ	44
s43		.equ	43
s42		.equ	42
s41		.equ	41
s40		.equ	40
s39		.equ	39
s38		.equ	38
s37		.equ	37
s36		.equ	36
s35		.equ	35
s34		.equ	34
s33		.equ	33
s32		.equ	32
s15		.equ	15
s14		.equ	14
s13		.equ	13
s12		.equ	12
s11		.equ	11
s10		.equ	10
s9		.equ	9
s8		.equ	8
s7		.equ	7
s6		.equ	6
s5		.equ	5
s4		.equ	4
s3		.equ	3
s2		.equ	2
s1		.equ	1
s0		.equ	0


.MACRO  db_c_s	com,seg
          .BYTE com*6+seg/8
.ENDMACRO

.MACRO  db_c_y	com,seg
	      .BYTE 1.shl.(seg-seg/8*8)
.ENDMACRO

Lcd_byte:							;段码<==>SEG/COM表
lcd_table1:
lcd_d0	equ	$-lcd_table1
	db_c_s	c1,s2	; A1
	db_c_s	c1,s3	; A2
	db_c_s	c1,s5	; A3
	db_c_s	c2,s2	; A4
	db_c_s	c1,s4	; A5
	db_c_s	c1,s6	; A6
	db_c_s	c3,s2	; A7
	db_c_s	c2,s5	; A8
	db_c_s	c2,s6	; A9
	db_c_s	c2,s3	; A10
	db_c_s	c2,s4	; A11
	db_c_s	c3,s6	; A12
	db_c_s	c3,s3	; A13
	db_c_s	c3,s4	; A14
	db_c_s	c3,s5	; A15

lcd_d1	equ	$-lcd_table1
	db_c_s	c1,s7	; B1
	db_c_s	c1,s8	; B2
	db_c_s	c1,s9	; B3
	db_c_s	c2,s7	; B4
	db_c_s	c2,s8	; B5
	db_c_s	c1,s10	; B6
	db_c_s	c3,s7	; B7
	db_c_s	c2,s9	; B8
	db_c_s	c1,s11	; B9
	db_c_s	c3,s8	; B10
	db_c_s	c2,s10	; B11
	db_c_s	c2,s11	; B12
	db_c_s	c3,s9	; B13
	db_c_s	c3,s10	; B14
	db_c_s	c3,s11	; B15

lcd_d2	equ	$-lcd_table1
	db_c_s	c0,s12	; C1
	db_c_s	c0,s13	; C2
	db_c_s	c0,s14	; C3
	db_c_s	c1,s12	; C4
	db_c_s	c1,s13	; C5
	db_c_s	c0,s15	; C6
	db_c_s	c2,s12	; C7
	db_c_s	c1,s14	; C8
	db_c_s	c1,s15	; C9
	db_c_s	c2,s13	; C10
	db_c_s	c2,s14	; C11
	db_c_s	c2,s15	; C12
	db_c_s	c3,s13	; C13
	db_c_s	c3,s14	; C14
	db_c_s	c3,s15	; C15

lcd_d3	equ	$-lcd_table1
	db_c_s	c0,s41	; D1
	db_c_s	c0,s42	; D2
	db_c_s	c0,s43	; D3
	db_c_s	c0,s40	; D4
	db_c_s	c1,s42	; D5
	db_c_s	c1,s43	; D6
	db_c_s	c1,s40	; D7
	db_c_s	c1,s41	; D8
	db_c_s	c2,s43	; D9
	db_c_s	c2,s40	; D10
	db_c_s	c2,s41	; D11
	db_c_s	c2,s42	; D12
	db_c_s	c3,s40	; D13
	db_c_s	c3,s41	; D14
	db_c_s	c3,s42	; D15

lcd_dot:
lcd_week	equ	$-lcd_table1
lcd_SUN		equ	$-lcd_table1
	db_c_s	c0,s4	; SUN
lcd_MON		equ	$-lcd_table1
	db_c_s	c0,s5	; MON
lcd_TUE		equ	$-lcd_table1
	db_c_s	c0,s6	; TUE
lcd_WED		equ	$-lcd_table1
	db_c_s	c0,s7	; WED
lcd_THU		equ	$-lcd_table1
	db_c_s	c0,s8	; THU
lcd_FRI		equ	$-lcd_table1
	db_c_s	c0,s9	; FRI
lcd_SAT		equ	$-lcd_table1
	db_c_s	c0,s10	; SAT
lcd_D		equ	$-lcd_table1
	db_c_s	c0,s3	; D
lcd_PM		equ	$-lcd_table1
	db_c_s	c0,s2	; PM
lcd_DM		equ	$-lcd_table1
	db_c_s	c0,s11	; DM
lcd_COL		equ	$-lcd_table1
	db_c_s	c3,s12	; COL
lcd_Y		equ	$-lcd_table1
	db_c_s	c3,s43	; Y

;==========================================================
;==========================================================

Lcd_bit:
	db_c_y	c1,s2	; A1
	db_c_y	c1,s3	; A2
	db_c_y	c1,s5	; A3
	db_c_y	c2,s2	; A4
	db_c_y	c1,s4	; A5
	db_c_y	c1,s6	; A6
	db_c_y	c3,s2	; A7
	db_c_y	c2,s5	; A8
	db_c_y	c2,s6	; A9
	db_c_y	c2,s3	; A10
	db_c_y	c2,s4	; A11
	db_c_y	c3,s6	; A12
	db_c_y	c3,s3	; A13
	db_c_y	c3,s4	; A14
	db_c_y	c3,s5	; A15

	db_c_y	c1,s7	; B1
	db_c_y	c1,s8	; B2
	db_c_y	c1,s9	; B3
	db_c_y	c2,s7	; B4
	db_c_y	c2,s8	; B5
	db_c_y	c1,s10	; B6
	db_c_y	c3,s7	; B7
	db_c_y	c2,s9	; B8
	db_c_y	c1,s11	; B9
	db_c_y	c3,s8	; B10
	db_c_y	c2,s10	; B11
	db_c_y	c2,s11	; B12
	db_c_y	c3,s9	; B13
	db_c_y	c3,s10	; B14
	db_c_y	c3,s11	; B15

	db_c_y	c0,s12	; C1
	db_c_y	c0,s13	; C2
	db_c_y	c0,s14	; C3
	db_c_y	c1,s12	; C4
	db_c_y	c1,s13	; C5
	db_c_y	c0,s15	; C6
	db_c_y	c2,s12	; C7
	db_c_y	c1,s14	; C8
	db_c_y	c1,s15	; C9
	db_c_y	c2,s13	; C10
	db_c_y	c2,s14	; C11
	db_c_y	c2,s15	; C12
	db_c_y	c3,s13	; C13
	db_c_y	c3,s14	; C14
	db_c_y	c3,s15	; C15

	db_c_y	c0,s41	; D1
	db_c_y	c0,s42	; D2
	db_c_y	c0,s43	; D3
	db_c_y	c0,s40	; D4
	db_c_y	c1,s42	; D5
	db_c_y	c1,s43	; D6
	db_c_y	c1,s40	; D7
	db_c_y	c1,s41	; D8
	db_c_y	c2,s43	; D9
	db_c_y	c2,s40	; D10
	db_c_y	c2,s41	; D11
	db_c_y	c2,s42	; D12
	db_c_y	c3,s40	; D13
	db_c_y	c3,s41	; D14
	db_c_y	c3,s42	; D15

	db_c_y	c0,s4	; SUN
	db_c_y	c0,s5	; MON
	db_c_y	c0,s6	; TUE
	db_c_y	c0,s7	; WED
	db_c_y	c0,s8	; THU
	db_c_y	c0,s9	; FRI
	db_c_y	c0,s10	; SAT
	db_c_y	c0,s3	; D
	db_c_y	c0,s2	; PM
	db_c_y	c0,s11	; DM
	db_c_y	c3,s12	; COL
	db_c_y	c3,s43	; Y