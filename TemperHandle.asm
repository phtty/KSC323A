L_Temper_Handle:
	jsr		L_RR_Multi_256
	jsr		L_RR_Div_RT
	jsr		L_Search_TemperTable
	rts

; 通过Qt查表确定当前温度
L_Search_TemperTable:
	ldx		#0
	lda		RR_Div_RT_L
	sec
	sbc		Temperature_Table,x
	bcs		L_Search_TemperTable
	stx		P_Temp
	txa
	sec
	sbc		#10
	bcs		L_Search_Over						; 大于0则为正数or0温度
	lda		#10									; 负数温度的处理
	sec
	sbc		P_Temp
	smb2	RFC_Flag							; 负数温度标志位
L_Search_Over:
	sta		R_Temperature
	rts

; 标准电阻左移8位除以热敏电阻，计算比值Qt，量程为-10~50度
L_RR_Div_RT:
	lda		#0
	sta		RR_Div_RT_H
	sta		RR_Div_RT_L
	lda		RFC_StanderCount_L					; 湿度计算也需要标准电阻，不能直接操作RFC_StanderCount
	sta		P_Temp
	lda		RFC_StanderCount_H
	sta		P_Temp+1
?Div_Juge:
	lda		P_Temp+1							; 比较标准电阻和热敏电阻的测量值高8位
	cmp		RFC_TempCount_H
	bcc		?Loop_Over							; 热敏电阻大于标准电阻时即为除完了
	lda		RFC_TempCount_H
	cmp		P_Temp+1
	bcc		?Div_Start							; 高8位RT<RR，则循环减除数

	lda		P_Temp								; 高8位相等的情况下，看低8位
	cmp		RFC_TempCount_L
	bcc		?Loop_Over							; 低8位RT<RR，则循环减除数
?Div_Start:
	sec
	lda		P_Temp								; RR循环减RT
	sbc		RFC_TempCount_L
	sta		P_Temp
	lda		P_Temp+1							; 直到RR<RT则除法结束
	sbc		RFC_TempCount_H
	sta		P_Temp+1

	inc		RR_Div_RT_L
	bne		?Loop_Over
	inc		RR_Div_RT_H							; 储存商
	bra		?Div_Juge
?Loop_Over:
	rts

; 标准电阻乘以256
L_RR_Multi_256:
	clc
	rol		RFC_StanderCount_L
	rol		RFC_StanderCount_H
	clc
	rol		RFC_StanderCount_L
	rol		RFC_StanderCount_H
	clc
	rol		RFC_StanderCount_L
	rol		RFC_StanderCount_H
	clc
	rol		RFC_StanderCount_L
	rol		RFC_StanderCount_H
	clc
	rol		RFC_StanderCount_L
	rol		RFC_StanderCount_H
	clc
	rol		RFC_StanderCount_L
	rol		RFC_StanderCount_H
	clc
	rol		RFC_StanderCount_L
	rol		RFC_StanderCount_H
	clc
	rol		RFC_StanderCount_L
	rol		RFC_StanderCount_H
	rts