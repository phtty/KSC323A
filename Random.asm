F_RandomSeed0_Get:
	lda		R_Seed0
	adc		TMR0
	jsr		L_Mod_A_10
	sta		R_Seed0
	rts

F_RandomSeed1_Get:
	lda		R_Seed1
	sbc		TMR0
	jsr		L_Mod_A_10
	sta		R_Seed1
	rts

F_RandomSeed2_Get:
	lda		R_Seed2
	adc		CC0
	jsr		L_Mod_A_10
	sta		R_Seed2
	rts

F_RandomSeed3_Get:
	lda		R_Seed3
	sbc		CC0
	jsr		L_Mod_A_10
	sta		R_Seed3
	rts


F_Display_Random_Rolling:
	bbr0	Random_Flag,L_No_Rolling
	bbr1	Random_Flag,L_No_Rolling

	rmb1	Random_Flag

	lda		Frame_Serial
	cmp		#6
	bcs		L_No_Phase1
	jmp		L_Phase1
L_No_Phase1:
	cmp		#18
	bcs		L_No_Phase2
	jmp		L_Phase2
L_No_Phase2:
	cmp		#42
	bcs		L_No_Phase3
	jmp		L_Phase3
L_No_Phase3:
	cmp		#66
	bcs		L_No_Phase4
	jmp		L_Phase4
L_No_Phase4:
	cmp		#90
	bcs		L_No_Phase5
	jmp		L_Phase5
L_No_Phase5:
	cmp		#114
	bcs		L_No_Phase6
	jmp		L_Phase6
L_No_Phase6:
	lda		#0
	sta		Frame_Counter
	sta		Frame_Serial
	sta		Anim_Phase
	rmb0	Random_Flag							; 滚动显示停止
	rmb2	Random_Flag							; 重新开始采样随机数

L_No_Rolling:
	rts


L_Phase1:
	lda		#0
	sta		Anim_Phase
	jsr		L_Display_D0_InPhase
	jsr		L_Display_D1_InPhase
	jsr		L_Display_D2_InPhase
	jsr		L_Display_D3_InPhase
	inc		Frame_Serial
	rts
L_Phase2:
	lda		#1
	sta		Anim_Phase
	jsr		L_Display_D0_InPhase
	jsr		L_Display_D1_InPhase
	jsr		L_Display_D2_InPhase
	jsr		L_Display_D3_InPhase
	inc		Frame_Serial
	rts
L_Phase3:
	lda		#2
	sta		Anim_Phase
	jsr		L_Display_D0_InPhase
	jsr		L_Display_D1_InPhase
	jsr		L_Display_D2_InPhase
	jsr		L_Display_D3_InPhase
	inc		Frame_Serial
	rts
L_Phase4:
	lda		#3
	sta		Anim_Phase
	jsr		L_Display_D1_InPhase
	jsr		L_Display_D2_InPhase
	jsr		L_Display_D3_InPhase
	inc		Frame_Serial
	rts
L_Phase5:
	lda		#4
	sta		Anim_Phase
	jsr		L_Display_D2_InPhase
	jsr		L_Display_D3_InPhase
	inc		Frame_Serial
	rts
L_Phase6:
	lda		#5
	sta		Anim_Phase
	jsr		L_Display_D3_InPhase
	inc		Frame_Serial
	rts


L_Display_D0_InPhase:
	lda		Anim_Phase							; 根据动画阶段不同，处理frame serial
	cmp		#0
	beq		L_D0_Phase1
	cmp		#1
	beq		L_D0_Phase2
	cmp		#2
	beq		L_D0_Phase3
	cmp		#3
	bcs		L_Display_D0_InPhase_Exit

L_D0_Phase1:
	lda		Frame_Serial
	sta		Frame_Counter
	bra		Is_Seed0_BorrowOff
L_D0_Phase2:
	lda		Frame_Serial
	sec
	sbc		#6
	jsr		L_Div_A_2
	sta		Frame_Counter
	bra		Is_Seed0_BorrowOff
L_D0_Phase3:
	lda		Frame_Serial
	sec
	sbc		#18
	jsr		L_Div_A_4
	sta		Frame_Counter
	bra		Is_Seed0_BorrowOff

Is_Seed0_BorrowOff:								; 判断seed0是否退位
	lda		Frame_Counter
	cmp		#00
	bne		L_Dis_Start_D0						; 若上次Frame_Counter为5，这次为0，才增Seed
	lda		Frame_Counter_D0
	cmp		#05
	bne		L_Dis_Start_D0
	lda		R_Seed0
	cmp		#00
	bne		L_Seed0_NoBorrowOff					; 判断seed0是否溢出
	lda		#09
	sta		R_Seed0
	bra		L_Dis_Start_D0
L_Seed0_NoBorrowOff:
	dec		R_Seed0
L_Dis_Start_D0:
	lda		Frame_Counter
	sta		Frame_Counter_D0					; 同步
	ldx		#lcd_d0
	lda		R_Seed0
	jsr		F_Dis_Animation_Frame
L_Display_D0_InPhase_Exit:
	rts




L_Display_D1_InPhase:
	lda		Anim_Phase							; 根据动画阶段不同，处理frame serial
	cmp		#0
	beq		L_D1_Phase1
	cmp		#1
	beq		L_D1_Phase2
	cmp		#2
	beq		L_D1_Phase3
	cmp		#3
	beq		L_D1_Phase4
	cmp		#4
	bcs		L_Display_D1_InPhase_Exit

L_D1_Phase1:
	lda		Frame_Serial
	sta		Frame_Counter
	bra		Is_Seed1_BorrowOff
L_D1_Phase2:
	lda		Frame_Serial
	sec
	sbc		#6
	jsr		L_Mod_A_6
	sta		Frame_Counter
	bra		Is_Seed1_BorrowOff
L_D1_Phase3:
	lda		Frame_Serial
	sec
	sbc		#18
	jsr		L_Div_A_2
	jsr		L_Mod_A_6
	sta		Frame_Counter
	bra		Is_Seed1_BorrowOff
L_D1_Phase4:
	lda		Frame_Serial
	sec
	sbc		#42
	jsr		L_Div_A_4
	jsr		L_Mod_A_6
	sta		Frame_Counter
	bra		Is_Seed1_BorrowOff

Is_Seed1_BorrowOff:								; 判断seed1是否退位
	lda		Frame_Counter
	cmp		#00
	bne		L_Dis_Start_D1						; 若上次Frame_Counter也为0，则不增Seed
	lda		Frame_Counter_D1
	cmp		#00
	beq		L_Dis_Start_D1
	lda		R_Seed1
	cmp		#00	
	bne		L_Seed1_NoBorrowOff					; 判断seed1是否溢出
	lda		#09
	sta		R_Seed1
	bra		L_Dis_Start_D1
L_Seed1_NoBorrowOff:
	dec		R_Seed1
L_Dis_Start_D1:
	lda		Frame_Counter
	sta		Frame_Counter_D1					; 同步
	ldx		#lcd_d1
	lda		R_Seed1
	jsr		F_Dis_Animation_Frame
L_Display_D1_InPhase_Exit:
	rts





L_Display_D2_InPhase:
	lda		Anim_Phase							; 根据动画阶段不同，处理frame serial
	cmp		#0
	beq		L_D2_Phase1
	cmp		#1
	beq		L_D2_Phase2
	cmp		#2
	beq		L_D2_Phase3
	cmp		#3
	beq		L_D2_Phase4
	cmp		#4
	beq		L_D2_Phase5
	cmp		#5
	bcs		L_Display_D2_InPhase_Exit

L_D2_Phase1:
	lda		Frame_Serial
	sta		Frame_Counter
	bra		Is_Seed2_BorrowOff
L_D2_Phase2:
	lda		Frame_Serial
	sec
	sbc		#6
	jsr		L_Mod_A_6
	sta		Frame_Counter
	bra		Is_Seed2_BorrowOff
L_D2_Phase3:
	lda		Frame_Serial
	sec
	sbc		#18
	jsr		L_Mod_A_6
	sta		Frame_Counter
	bra		Is_Seed2_BorrowOff
L_D2_Phase4:
	lda		Frame_Serial
	sec
	sbc		#42
	jsr		L_Div_A_2
	jsr		L_Mod_A_6
	sta		Frame_Counter
	bra		Is_Seed2_BorrowOff
L_D2_Phase5:
	lda		Frame_Serial
	sec
	sbc		#66
	jsr		L_Div_A_4
	jsr		L_Mod_A_6
	sta		Frame_Counter
	bra		Is_Seed2_BorrowOff

Is_Seed2_BorrowOff:								; 判断seed2是否退位
	lda		Frame_Counter
	cmp		#00
	bne		L_Dis_Start_D2						; 若上次Frame_Counter也为0，则不增Seed
	lda		Frame_Counter_D2
	cmp		#00
	beq		L_Dis_Start_D2
	lda		R_Seed2
	cmp		#00	
	bne		L_Seed2_NoBorrowOff					; 判断seed2是否溢出
	lda		#09
	sta		R_Seed2
	bra		L_Dis_Start_D2
L_Seed2_NoBorrowOff:
	dec		R_Seed2
L_Dis_Start_D2:
	lda		Frame_Counter
	sta		Frame_Counter_D2					; 同步
	ldx		#lcd_d2
	lda		R_Seed2
	jsr		F_Dis_Animation_Frame
L_Display_D2_InPhase_Exit:
	rts





L_Display_D3_InPhase:
	lda		Anim_Phase							; 根据动画阶段不同，处理frame serial
	cmp		#0
	beq		L_D3_Phase1
	cmp		#1
	beq		L_D3_Phase2
	cmp		#2
	beq		L_D3_Phase3
	cmp		#3
	beq		L_D3_Phase4
	cmp		#4
	beq		L_D3_Phase5
	cmp		#5
	beq		L_D3_Phase6
	cmp		#6
	bcs		L_Display_D3_InPhase_Exit

L_D3_Phase1:
	lda		Frame_Serial
	sta		Frame_Counter
	bra		Is_Seed3_BorrowOff
L_D3_Phase2:
	lda		Frame_Serial
	sec
	sbc		#6
	jsr		L_Mod_A_6
	sta		Frame_Counter
	bra		Is_Seed3_BorrowOff
L_D3_Phase3:
	lda		Frame_Serial
	sec
	sbc		#18
	jsr		L_Mod_A_6
	sta		Frame_Counter
	bra		Is_Seed3_BorrowOff
L_D3_Phase4:
	lda		Frame_Serial
	sec
	sbc		#42
	jsr		L_Mod_A_6
	sta		Frame_Counter
	bra		Is_Seed3_BorrowOff
L_D3_Phase5:
	lda		Frame_Serial
	sec
	sbc		#66
	jsr		L_Div_A_2
	jsr		L_Mod_A_6
	sta		Frame_Counter
	bra		Is_Seed3_BorrowOff
L_D3_Phase6:
	lda		Frame_Serial
	sec
	sbc		#90
	jsr		L_Div_A_4
	jsr		L_Mod_A_6
	sta		Frame_Counter
	bra		Is_Seed3_BorrowOff

Is_Seed3_BorrowOff:								; 判断seed3是否退位
	lda		Frame_Counter
	cmp		#00
	bne		L_Dis_Start_D3						; 若上次Frame_Counter也为0，则不增Seed
	lda		Frame_Counter_D3
	cmp		#00
	beq		L_Dis_Start_D3
	lda		R_Seed3
	cmp		#00	
	bne		L_Seed3_NoBorrowOff					; 判断seed3是否溢出
	lda		#09
	sta		R_Seed3
	bra		L_Dis_Start_D3
L_Seed3_NoBorrowOff:
	dec		R_Seed3
L_Dis_Start_D3:
	lda		Frame_Counter
	sta		Frame_Counter_D3					; 同步
	ldx		#lcd_d3
	lda		R_Seed3
	jsr		F_Dis_Animation_Frame
L_Display_D3_InPhase_Exit:
	rts




L_Div_A_2:
	ldx		#0
L_Div_A_2_Start:
	cmp		#2
	bcc		L_Div_A_2_Over
	sec
	sbc		#2
	inx
	bra		L_Div_A_2_Start
L_Div_A_2_Over:
	txa
	rts

L_Div_A_4:
	ldx		#0
L_Div_A_4_Start:
	cmp		#4
	bcc		L_Div_A_4_Over
	sec
	sbc		#4
	inx
	bra		L_Div_A_4_Start
L_Div_A_4_Over:
	txa
	rts


L_Mod_A_6:
	cmp		#6
	bcc		L_Mod_A_6_Over
	sec
	sbc		#6
	bra		L_Mod_A_6
L_Mod_A_6_Over:
	rts


L_Mod_A_10:
	cmp		#10
	bcc		L_Mod_A_10_Over
	sec
	sbc		#10
	bra		L_Mod_A_10
L_Mod_A_10_Over:
	rts
