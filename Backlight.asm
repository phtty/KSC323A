F_BacklightLevel_Manage:
	bbr0	Backlight_Flag,L_Backlight_Exit
	lda		Backlight_Level
	cmp		#1
	bcs		No_Level0
	lda		PD
	and		#$ef								; 熄屏
	sta		PD
No_Level0:
	cmp		#2
	bcs		No_Level1
	lda		PD
	ora		#$10								; 亮屏，低亮
	sta		PD
	rmb0	PC
No_Level1:
	cmp		#3
	bcs		L_Backlight_Exit
	lda		PD
	ora		#$10								; 亮屏，高亮
	sta		PD
	smb0	PC
L_Backlight_Exit:
	rts
