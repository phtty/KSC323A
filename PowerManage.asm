F_PowerManage:
	bbs0	Backlight_Flag,No_FrameUpdate		; 处于常亮模式不需要反复打开SWLed
	lda		PD
	ora		#$10								; PD4 SWLed口输出高，打开5020
	sta		PD
	smb0	Backlight_Flag						; 标志位设置为常亮模式
	bbs2	Backlight_Flag,No_FrameUpdate
No_FrameUpdate:
	smb2	Backlight_Flag						; 更新PY口上一次的状态
	rts
L_4V5Power_Mode:
	bbr4	PD,L_PowerManage_Exit				; 已经熄屏后不需要继续计数
	lda		Backlight_Counter
	cmp		#15
	bcs		L_ShutDown_Display					; 计满15S则断开5020供电，熄屏等待按键唤醒
	inc		Backlight_Counter
	bra		L_PowerManage_Exit
L_ShutDown_Display:
	lda		#$00
	sta		Backlight_Counter
	lda		PD
	and		#$ef								; PD4 SWLed口输出低，关闭5020
	sta		PD
L_PowerManage_Exit:
	rmb2	Backlight_Flag						; 更新PY口上一次的状态
	rts