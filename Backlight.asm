F_Backlight:
	bbr3	Key_Flag,L_Backlight_Exit
	bbr5	Timer_Flag,L_Backlight_Exit

	rmb5	Timer_Flag
	lda		Backlight_Counter
	cmp		#6
	bcs		L_Backlight_Stop
	inc		Backlight_Counter
	bra		L_Backlight_Exit
L_Backlight_Stop:
	lda		#0
	sta		Backlight_Counter
	rmb3	Key_Flag
	rmb2	PB
L_Backlight_Exit:
	rts
