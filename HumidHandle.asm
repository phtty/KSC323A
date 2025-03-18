L_Humid_Handle:
	jsr		L_RR_Multi_512
	jsr		L_RR_Div_RH
	jsr		L_Search_HumidTable

	rts

L_Search_HumidTable:
	lda		R_Temperature
	bbr2	RFC_Flag,?Start						; 若温度为负数，则湿度不显示
	lda		#0
	sta		R_Humidity
	rts
?Start:
	cmp		#51
	bcc		L_Temper_NoOverFlow					; 若是温度大于50度，固定为50度
	lda		#50
L_Temper_NoOverFlow:
	jsr		L_A_Mod_5							; 将温度值除以5得到湿度表索引N，用于查找相应温度下的湿度值，以便进行后续的湿度计算
	stx		P_Temp
	cmp		#2
	bcs		N_GreaterThan1
	bra		Temper_GapSmall						; 余数为0和1时用索引N查表
N_GreaterThan1:
	cmp		#4
	bcs		N_GreaterThan3
	bra		Temper_GapMiddle					; 余数为2和3时用索引N和N+1查两次表，取二者的平均数
N_GreaterThan3:
	inc		P_Temp
	bra		Temper_GapLong						; 余数为4则用索引值为N+1查表

Temper_GapSmall:
	jsr		L_SearchTable_N						; 在温度的余数较小时，直接采用接近的湿度表查出湿度值
	rts
Temper_GapMiddle:
	lda		P_Temp
	sta		P_Temp+1							; 查表会改变索引值，暂存索引值
	jsr		L_SearchTable_N						; 余数较大时，采用两个湿度表计算出的平均值作为湿度值
	lda		R_Humidity
	sta		P_Temp+2
	lda		P_Temp+1
	sta		P_Temp
	inc		P_Temp								; 查索引值为N+1的湿度表
	jsr		L_SearchTable_N
	lda		R_Humidity
	clc
	adc		P_Temp+2							; 前后取得的湿度值相加然后除以2，获得平均值
	clc
	ror
	sta		R_Humidity							; 计算出的平均值为最终湿度值
	rts
Temper_GapLong:
	jsr		L_SearchTable_N						; 在温度的余数较大时，用下一阶的湿度表查出湿度值
	rts

; 用N作为索引，查湿度表得出当前湿度值
; P_Temp为湿度表索引N，Qh为L_RR_Div_RH
L_SearchTable_N:
	lda		P_Temp
	clc
	rol											; N值乘以2得到正确的偏移
	sta		P_Temp
	lda		#0
	sta		R_Humidity							; 湿度值
Loop_Start:
	bbs3	RFC_Flag,Loop_Over					; 如果在递减查表函数中减完，则退出循环
	lda		Humid_SearchLoop_Addr+1				; 入栈循环开始标签的地址
	pha											; 以便能在循环查表函数中
	lda		Humid_SearchLoop_Addr				; 能返回到该函数循环开始
	pha

	ldx		P_Temp
	lda		Temper_Humid_table+1,x
	pha											; 入栈对应的循环查表函数地址
	lda		Temper_Humid_table,x
	pha
	rts											; 跳转到对应循环查表函数
Loop_Over:
	rmb3	RFC_Flag							; 复位循环完成标志位
	lda		R_Humidity
	beq		Humid_LowerThan20
	clc
	ror											; 循环查表得到的值除以2加19(+20-1)
	clc
	adc		#19
	sta		R_Humidity							; 才是实际湿度值
	rts
Humid_LowerThan20:
	lda		#20
	sta		R_Humidity
	rts




Humid_SearchLoop_Addr:							; 子程序的地址表
	dw		Loop_Start-1
Temper_Humid_table:
	dw		L_0Degree_Humid-1
	dw		L_5Degree_Humid-1
	dw		L_10Degree_Humid-1
	dw		L_15Degree_Humid-1
	dw		L_20Degree_Humid-1
	dw		L_25Degree_Humid-1
	dw		L_30Degree_Humid-1
	dw		L_35Degree_Humid-1
	dw		L_40Degree_Humid-1
	dw		L_45Degree_Humid-1
	dw		L_50Degree_Humid-1

; 标准电阻左移9位除以湿度电阻，计算比值Qh
L_RR_Div_RH:
	lda		#0
	sta		RR_Div_RH_H
	sta		RR_Div_RH_L
?Div_Juge:
	lda		RFC_StanderCount_H					; 比较标准电阻和湿度电阻的测量值高8位
	cmp		RFC_HumiCount_H
	bcc		?Loop_Over							; 高8位RH>RR时即为除完了
	lda		RFC_HumiCount_H
	cmp		RFC_StanderCount_H
	bcc		?Div_Start	

	lda		RFC_StanderCount_M					; 比较标准电阻和湿度电阻的测量值中8位
	cmp		RFC_HumiCount_M
	bcc		?Loop_Over							; 中8位RH>RR时即为除完了
	lda		RFC_HumiCount_M
	cmp		RFC_StanderCount_M
	bcc		?Div_Start							; 中8位RR>RH，则还没除完

	lda		RFC_StanderCount_L					; 中8位相等的情况下，看低8位
	cmp		RFC_HumiCount_L
	bcc		?Loop_Over							; 低8位RH>RR，也是除完了
	beq		?Loop_Over							; 此时低8位RR==0，则不继续除，说明采样错误，直接返回
?Div_Start:
	sec
	lda		RFC_StanderCount_L					; RR循环减RH
	sbc		RFC_HumiCount_L
	sta		RFC_StanderCount_L
	lda		RFC_StanderCount_M
	sbc		RFC_HumiCount_M
	sta		RFC_StanderCount_M
	lda		RFC_StanderCount_H
	sbc		RFC_HumiCount_H
	sta		RFC_StanderCount_H

	lda		RR_Div_RH_L
	clc
	adc		#1
	sta		RR_Div_RH_L
	lda		RR_Div_RH_H
	adc		#0
	sta		RR_Div_RH_H							; 储存商
	bra		?Div_Juge
?Loop_Over:
	rts


L_0Degree_Humid:
	ldx		R_Humidity
	lda		Humid_0Degree_Table,x
	sec
	sbc		RR_Div_RH_L
	inx
	lda		Humid_0Degree_Table,x
	sbc		RR_Div_RH_H
	bcs		L_0Degree_Humid_BackLoop
	smb3	RFC_Flag							; 如果不够减，则说明循环完成
	dex
	rts
L_0Degree_Humid_BackLoop:
	inx
	stx		R_Humidity							; 更新湿度值
	txa
	cmp		#151
	bcc		L_0Degree_Humid_NoOverFlow
	smb3	RFC_Flag							; 若湿度值大于95，则达到最大量程，停止继续查表并退出
L_0Degree_Humid_NoOverFlow:
	rts

L_5Degree_Humid:
	ldx		R_Humidity
	lda		Humid_5Degree_Table,x
	sec
	sbc		RR_Div_RH_L
	inx
	lda		Humid_5Degree_Table,x
	sbc		RR_Div_RH_H
	bcs		L_5Degree_Humid_BackLoop
	smb3	RFC_Flag							; 如果不够减，则说明循环完成
	dex
	rts
L_5Degree_Humid_BackLoop:
	inx
	stx		R_Humidity							; 更新湿度值
	txa
	cmp		#151
	bcc		L_5Degree_Humid_NoOverFlow
	smb3	RFC_Flag							; 若湿度值大于95，则达到最大量程，停止继续查表并退出
L_5Degree_Humid_NoOverFlow:
	rts

L_10Degree_Humid:
	ldx		R_Humidity
	lda		Humid_10Degree_Table,x
	sec
	sbc		RR_Div_RH_L
	inx
	lda		Humid_10Degree_Table,x
	sbc		RR_Div_RH_H
	bcs		L_10Degree_Humid_BackLoop
	smb3	RFC_Flag							; 如果不够减，则说明循环完成
	dex
	rts
L_10Degree_Humid_BackLoop:
	inx
	stx		R_Humidity							; 更新湿度值
	txa
	cmp		#151
	bcc		L_10Degree_Humid_NoOverFlow
	smb3	RFC_Flag							; 若湿度值大于95，则达到最大量程，停止继续查表并退出
L_10Degree_Humid_NoOverFlow:
	rts

L_15Degree_Humid:
	ldx		R_Humidity
	lda		Humid_15Degree_Table,x
	sec
	sbc		RR_Div_RH_L
	inx
	lda		Humid_15Degree_Table,x
	sbc		RR_Div_RH_H
	bcs		L_15Degree_Humid_BackLoop
	smb3	RFC_Flag							; 如果不够减，则说明循环完成
	dex
	rts
L_15Degree_Humid_BackLoop:
	inx
	stx		R_Humidity							; 更新湿度值
	txa
	cmp		#151
	bcc		L_15Degree_Humid_NoOverFlow
	smb3	RFC_Flag							; 若湿度值大于95，则达到最大量程，停止继续查表并退出
L_15Degree_Humid_NoOverFlow:
	rts

L_20Degree_Humid:
	ldx		R_Humidity
	lda		Humid_20Degree_Table,x
	sec
	sbc		RR_Div_RH_L
	inx
	lda		Humid_20Degree_Table,x
	sbc		RR_Div_RH_H
	bcs		L_20Degree_Humid_BackLoop
	smb3	RFC_Flag							; 如果不够减，则说明循环完成
	dex
	rts
L_20Degree_Humid_BackLoop:
	inx
	stx		R_Humidity							; 更新湿度值
	txa
	cmp		#151
	bcc		L_20Degree_Humid_NoOverFlow
	smb3	RFC_Flag							; 若湿度值大于95，则达到最大量程，停止继续查表并退出
L_20Degree_Humid_NoOverFlow:
	rts

L_25Degree_Humid:
	ldx		R_Humidity
	lda		Humid_25Degree_Table,x
	sec
	sbc		RR_Div_RH_L
	inx
	lda		Humid_25Degree_Table,x
	sbc		RR_Div_RH_H
	bcs		L_25Degree_Humid_BackLoop
	smb3	RFC_Flag							; 如果不够减，则说明循环完成
	dex
	rts
L_25Degree_Humid_BackLoop:
	inx
	stx		R_Humidity							; 更新湿度值
	txa
	cmp		#151
	bcc		L_25Degree_Humid_NoOverFlow
	smb3	RFC_Flag							; 若湿度值大于95，则达到最大量程，停止继续查表并退出
L_25Degree_Humid_NoOverFlow:
	rts

L_30Degree_Humid:
	ldx		R_Humidity
	lda		Humid_30Degree_Table,x
	sec
	sbc		RR_Div_RH_L
	inx
	lda		Humid_30Degree_Table,x
	sbc		RR_Div_RH_H
	bcs		L_30Degree_Humid_BackLoop
	smb3	RFC_Flag							; 如果不够减，则说明循环完成
	dex
	rts
L_30Degree_Humid_BackLoop:
	inx
	stx		R_Humidity							; 更新湿度值
	txa
	cmp		#151
	bcc		L_30Degree_Humid_NoOverFlow
	smb3	RFC_Flag							; 若湿度值大于95，则达到最大量程，停止继续查表并退出
L_30Degree_Humid_NoOverFlow:
	rts

L_35Degree_Humid:
	ldx		R_Humidity
	lda		Humid_35Degree_Table,x
	sec
	sbc		RR_Div_RH_L
	inx
	lda		Humid_35Degree_Table,x
	sbc		RR_Div_RH_H
	bcs		L_35Degree_Humid_BackLoop
	smb3	RFC_Flag							; 如果不够减，则说明循环完成
	dex
	rts
L_35Degree_Humid_BackLoop:
	inx
	stx		R_Humidity							; 更新湿度值
	txa
	cmp		#151
	bcc		L_35Degree_Humid_NoOverFlow
	smb3	RFC_Flag							; 若湿度值大于95，则达到最大量程，停止继续查表并退出
L_35Degree_Humid_NoOverFlow:
	rts

L_40Degree_Humid:
	ldx		R_Humidity
	lda		Humid_40Degree_Table,x
	sec
	sbc		RR_Div_RH_L
	inx
	lda		Humid_40Degree_Table,x
	sbc		RR_Div_RH_H
	bcs		L_40Degree_Humid_BackLoop
	smb3	RFC_Flag							; 如果不够减，则说明循环完成
	dex
	rts
L_40Degree_Humid_BackLoop:
	inx
	stx		R_Humidity							; 更新湿度值
	txa
	cmp		#151
	bcc		L_40Degree_Humid_NoOverFlow
	smb3	RFC_Flag							; 若湿度值大于95，则达到最大量程，停止继续查表并退出
L_40Degree_Humid_NoOverFlow:
	rts

L_45Degree_Humid:
	ldx		R_Humidity
	lda		Humid_45Degree_Table,x
	sec
	sbc		RR_Div_RH_L
	inx
	lda		Humid_45Degree_Table,x
	sbc		RR_Div_RH_H
	bcs		L_45Degree_Humid_BackLoop
	smb3	RFC_Flag							; 如果不够减，则说明循环完成
	dex
	rts
L_45Degree_Humid_BackLoop:
	inx
	stx		R_Humidity							; 更新湿度值
	txa
	cmp		#151
	bcc		L_45Degree_Humid_NoOverFlow
	smb3	RFC_Flag							; 若湿度值大于95，则达到最大量程，停止继续查表并退出
L_45Degree_Humid_NoOverFlow:
	rts

L_50Degree_Humid:
	ldx		R_Humidity
	lda		Humid_50Degree_Table,x
	sec
	sbc		RR_Div_RH_L
	inx
	lda		Humid_50Degree_Table,x
	sbc		RR_Div_RH_H
	bcs		L_50Degree_Humid_BackLoop
	smb3	RFC_Flag							; 如果不够减，则说明循环完成
	dex
	rts
L_50Degree_Humid_BackLoop:
	inx
	stx		R_Humidity							; 更新湿度值
	txa
	cmp		#151
	bcc		L_50Degree_Humid_NoOverFlow
	smb3	RFC_Flag							; 若湿度值大于95，则达到最大量程，停止继续查表并退出
L_50Degree_Humid_NoOverFlow:
	rts


; 标准电阻采样值乘以512
L_RR_Multi_512:
	lda		#9
	sta		P_Temp
RR_Multi_512_Loop:
	clc
	rol		RFC_StanderCount_L
	rol		RFC_StanderCount_M
	rol		RFC_StanderCount_H
	dec		P_Temp
	bne		RR_Multi_512_Loop
	rts




; X存商，A为余数
L_A_Mod_5:
	ldx		#0
L_A_Mod_5_Start:
	cmp		#5
	bcc		L_A_Mod_5_Over
	sec
	sbc		#5
	inx
	bra		L_A_Mod_5_Start
L_A_Mod_5_Over:
	rts
