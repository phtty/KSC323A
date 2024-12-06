F_Test_Mode:
	jsr		F_ClearScreen

	ldx		#led_d0
	lda		#1
	jsr		L_Dis_7Bit_DigitDot

	ldx		#led_d1
	lda		#1
	jsr		L_Dis_7Bit_DigitDot

	ldx		#led_d2
	lda		#1
	jsr		L_Dis_7Bit_DigitDot

	ldx		#led_d3
	lda		#1
	jsr		L_Dis_7Bit_DigitDot


	rts