F_Test_Mode:
	jsr		F_FillScreen
	lda		#00
	sta		P_Temp

L_Test_Loop:
	bbr0	Timer_Flag,L_No_Test_2Hz
	rmb0	Timer_Flag
	inc		P_Temp
L_No_Test_2Hz:
	lda		P_Temp
	cmp		#4
	bcs		L_Test_Over
	bra		L_Test_Loop
L_Test_Over:
	jsr		F_Display_Time
	jsr		F_DisDate_Week

	rts