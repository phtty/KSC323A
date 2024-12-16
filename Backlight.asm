F_BacklightLevel_Manage:
	lda		Backlight_Level
	cmp		#1
	bcs		No_Level0
	smb4	PD
	rts
No_Level0:
	cmp		#2
	bcs		No_Level1
	rmb4	PD
	rmb0	PC
	rts
No_Level1:
	cmp		#3
	bcs		L_Backlight_Exit
	rmb4	PD
	smb0	PC
	rts
