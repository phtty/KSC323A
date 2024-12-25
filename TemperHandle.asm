L_Temper_Handle:
	jsr		L_RT_Multi_256
	jsr		L_RT_Div_RR
	jsr		L_Search_TemperTable
	rts

; 通过Qt查表确定当前温度
L_Search_TemperTable:
	rmb2	RFC_Flag							; 清除负数温度标志位
	ldx		#255								; 初始值为255，进入循环后会+1溢出变为0
L_Sub_Temper:
	inx
	txa
	cmp		#50
	bcs		L_Temper_Overflow					; 大于等于50度则退出循环
	lda		RT_Div_RR_L
	sec
	sbc		Temperature_Table,x
	sta		RT_Div_RR_L
	lda		RT_Div_RR_H
	sbc		#0
	sta		RT_Div_RR_H
	bcs		L_Sub_Temper

L_Temper_Overflow:
	txa
	beq		Temper_LowerThan_M10				; -10度以下不在表中不需要递减1度
	dex
Temper_LowerThan_M10:
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

; 热敏电阻左移8位除以标准电阻，计算比值Qt，量程为-10~50度
L_RT_Div_RR:
	lda		#0
	sta		RT_Div_RR_H
	sta		RT_Div_RR_L
?Div_Juge:
	lda		RFC_TempCount_H						; 若热敏电阻高8位不为0，则一定没除完
	bne		?Div_Start
	lda		RFC_TempCount_M						; 比较热敏电阻中8位和标准电阻的测量值高8位
	cmp		RFC_StanderCount_M
	bcc		?Loop_Over							; 标准电阻大于热敏电阻时即为除完了
	lda		RFC_StanderCount_M
	cmp		RFC_TempCount_M
	bcc		?Div_Start							; RT<RR，则一定没除完

	lda		RFC_TempCount_L						; 高8位相等的情况下，看低8位
	cmp		RFC_StanderCount_L
	bcc		?Loop_Over							; 低8位RR<RT，则循环减除数
	beq		?Loop_Over							; 此时低8位RT==0，则不继续除，说明采样错误，直接返回
?Div_Start:
	sec
	lda		RFC_TempCount_L						; RT循环减RR
	sbc		RFC_StanderCount_L
	sta		RFC_TempCount_L
	lda		RFC_TempCount_M
	sbc		RFC_StanderCount_M
	sta		RFC_TempCount_M
	lda		RFC_TempCount_H
	sbc		#0
	sta		RFC_TempCount_H

	lda		RT_Div_RR_L
	clc
	adc		#1
	sta		RT_Div_RR_L
	lda		RT_Div_RR_H
	adc		#0
	sta		RT_Div_RR_H							; 储存商
	bra		?Div_Juge
?Loop_Over:
	rts

; 热敏电阻乘以256
L_RT_Multi_256:
	clc
	rol		RFC_TempCount_L
	rol		RFC_TempCount_M
	rol		RFC_TempCount_H
	clc
	rol		RFC_TempCount_L
	rol		RFC_TempCount_M
	rol		RFC_TempCount_H
	clc
	rol		RFC_TempCount_L
	rol		RFC_TempCount_M
	rol		RFC_TempCount_H
	clc
	rol		RFC_TempCount_L
	rol		RFC_TempCount_M
	rol		RFC_TempCount_H
	clc
	rol		RFC_TempCount_L
	rol		RFC_TempCount_M
	rol		RFC_TempCount_H
	clc
	rol		RFC_TempCount_L
	rol		RFC_TempCount_M
	rol		RFC_TempCount_H
	clc
	rol		RFC_TempCount_L
	rol		RFC_TempCount_M
	rol		RFC_TempCount_H
	clc
	rol		RFC_TempCount_L
	rol		RFC_TempCount_M
	rol		RFC_TempCount_H
	rts