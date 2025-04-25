; ��������
F_KeyHandler:
	bbs3	Timer_Flag,L_Key4Hz					; ��ӵ�����4Hzɨһ�Σ����ƿ��Ƶ��
	bbr1	Key_Flag,L_KeyScan					; �״ΰ�������
	rmb1	Key_Flag							; ��λ�״δ���
	jsr		L_KeyDelay
	lda		PA
	eor		#$1c								; �����Ƿ��߼��ģ���ָ���ļ�λ������ȡ��
	and		#$1c
	bne		L_KeyYes							; ����Ƿ��а�������
	jmp		L_KeyNoScanExit
L_KeyYes:
	rmb4	IER									; ����ȷ�������󣬹ر��жϱ����󴥷�
	sta		PA_IO_Backup
	bra		L_KeyHandle							; �״δ����������

L_Key4Hz:
	bbr5	Key_Flag,L_KeyScanExit
	rmb5	Key_Flag
L_KeyScan:										; ����������
	bbr0	Key_Flag,L_KeyNoScanExit			; û��ɨ����־��Ϊ�ް��������ˣ��ж��Ƿ�ȡ������RFC����

	jsr		F_QuikAdd_Scan						; ����ɨ�裬��Ҫ����IO��
	bbr4	Timer_Flag,L_KeyScanExit			; û��ʼ���ʱ����16Hzɨ��
	rmb4	Timer_Flag
	lda		PA
	eor		#$1c								; �����Ƿ��߼��ģ���ָ���ļ�λ������ȡ��
	and		#$1c
	cmp		PA_IO_Backup						; ����⵽�а�����״̬�仯���˳�����жϲ�����
	beq		L_4_16Hz_Count
	jsr		F_SpecialKey_Handle					; ������ֹʱ������һ�����ⰴ���Ĵ���
	bra		L_KeyExit
L_4_16Hz_Count:
	bbs3	Timer_Flag,Counter_NoAdd			; �ڿ�Ӵ������ټ������Ӽ���
	inc		QuickAdd_Counter					; ������������ᵼ�²�������������
Counter_NoAdd:
	lda		QuickAdd_Counter
	cmp		#32
	bcs		L_QuikAdd
	rts											; ������ʱ��������2S���п��
L_QuikAdd:
	bbs3	Timer_Flag,NoQuikAdd_Beep
	jsr		L_Key_Beep
NoQuikAdd_Beep:
	smb3	Timer_Flag
	rmb5	Key_Flag


L_KeyHandle:
	jsr		F_KeyMatrix_PC5Scan_Ready			; �ж�Down����Backlight��
	lda		PA
	eor		#$0c								; �����Ƿ��߼��ģ���ָ���ļ�λ������ȡ��
	and		#$0c
	cmp		#$04
	bne		No_KeyDTrigger						; ������תָ��Ѱַ���������⣬�������jmp������ת
	jmp		L_KeyDTrigger
No_KeyDTrigger:
	cmp		#$08
	bne		No_KeyBTrigger
	jmp		L_KeyBTrigger
No_KeyBTrigger:
	jsr		F_KeyMatrix_PC4Scan_Ready			; �ж�Mode����Alarm����Up��
	lda		PA
	eor		#$1c								; �����Ƿ��߼��ģ���ָ���ļ�λ������ȡ��
	and		#$1c
	cmp		#$04
	bne		No_KeyUTrigger
	jmp		L_KeyUTrigger
No_KeyUTrigger:
	cmp		#$08
	bne		No_KeyATrigger
	jmp		L_KeyATrigger
No_KeyATrigger:
	cmp		#$10
	bne		L_KeyExit
	jmp		L_KeyMTrigger						; M������

L_KeyExit:
	rmb1	TMRC								; �رտ�Ӽ�ʱ�Ķ�ʱ��
	rmb0	Key_Flag							; ����ر�־λ
	rmb3	Timer_Flag
	lda		#0									; ������ر���
	sta		QuickAdd_Counter
	sta		SpecialKey_Flag
	sta		Counter_DP
	jsr		F_KeyMatrix_Reset
	rmb4	IFR									; ��λ��־λ,�����жϿ���ʱֱ�ӽ����жϷ���
	smb4	IER									; ����������������¿���PA���ж�
L_KeyScanExit:
	rts

L_KeyNoScanExit:								; û��ɨ����������ǿ���״̬����ʱ�ж��Ƿ�ȡ������RFC����
	bbs4	Key_Flag,L_KeyScanExit				; ������������ģʽ�£���ȡ������
	bbs2	Clock_Flag,L_KeyScanExit
	rmb1	RFC_Flag							; ȡ������RFC����						
	rts


F_SpecialKey_Handle:							; ���ⰴ���Ĵ���
	lda		SpecialKey_Flag
	bne		SpecialKey_Handle
	rts
SpecialKey_Handle:
	bbs3	Timer_Flag,SpecialKey_NoBeep
	jsr		L_Key_Beep
SpecialKey_NoBeep:
	bbs0	SpecialKey_Flag,L_KeyA_ShortHandle	; �̰������⹦�ܴ���
	bbs1	SpecialKey_Flag,L_KeyB_ShortHandle
	bbs2	SpecialKey_Flag,L_KeyM_ShortHandle
	bbs3	SpecialKey_Flag,L_KeyU_ShortHandle
	bbs4	SpecialKey_Flag,L_KeyD_ShortHandle
L_KeyA_ShortHandle:
	lda		Sys_Status_Flag
	cmp		#1000B
	bne		No_SwitchState_AlarmSet				; ����ģʽ�л���������
	jsr		SwitchState_AlarmSet
	rts
No_SwitchState_AlarmSet:
	jsr		SwitchState_AlarmDis				; �л�������ʾ״̬
	rts

L_KeyB_ShortHandle:
	jsr		LightLevel_Change					; ���������л�
	rts

L_KeyM_ShortHandle:
	lda		Sys_Status_Flag
	cmp		#0100B
	bne		No_SwitchState_ClockSet
	jsr		SwitchState_ClockSet				; ʱ��ģʽ�л���������
	rts
No_SwitchState_ClockSet:
	jsr		SwitchState_ClockDis				; ��ʾģʽ���л�������ʾ��ʱ����ʾģʽ
	rts

L_KeyU_ShortHandle:
	lda		Sys_Status_Flag
	and		#0011B
	beq		KeyU_NoDisMode
	lda		#0001B
	sta		Sys_Status_Flag
	jsr		DM_SW_TimeMode						; ��ʾģʽ���л�12/24hģʽ
	rts
KeyU_NoDisMode:
	lda		Sys_Status_Flag
	cmp		#0100B
	bne		StatusCS_No_KeyU
	jsr		AddNum_CS							; ʱ��ģʽ����
	rts
StatusCS_No_KeyU:
	cmp		#1000B
	bne		KeyU_ShortHandle_Exit
	jsr		AddNum_AS							; ����ģʽ����
KeyU_ShortHandle_Exit:
	rts

L_KeyD_ShortHandle:
	lda		Sys_Status_Flag
	and		#0011B
	beq		KeyD_NoDisMode
	jsr		SwitchState_DisMode					; �л�����-����	
	rts
KeyD_NoDisMode:
	lda		Sys_Status_Flag
	cmp		#0100B
	bne		StatusCS_No_KeyD_Short
	jsr		SubNum_CS							; ʱ��ģʽ����
	rts
StatusCS_No_KeyD_Short:
	cmp		#1000B
	bne		KeyD_ShortHandle_Exit
	jsr		SubNum_AS							; ����ģʽ����
KeyD_ShortHandle_Exit:
	rts



; ������������������ÿ���������������Ӧ����
L_KeyATrigger:
	jsr		L_Universal_TriggerHandle			; ͨ�ð�������
	jsr		L_Key_NoSnoozeLoud					; ��������̰˯������

	lda		Sys_Status_Flag
	cmp		#0100B
	bne		StatusCS_No_KeyA
	jmp		L_KeyExit							; ʱ������ģʽA����Ч
StatusCS_No_KeyA:
	cmp		#1000B
	bne		StatusAS_No_KeyA
	bbr3	Timer_Flag,L_ASMode_KeyA_ShortTri
	jsr		L_Key_NoBeep
	jmp		L_KeyExit							; ��������ģʽA��������Ч
L_ASMode_KeyA_ShortTri:
	smb0	SpecialKey_Flag						; ����ģʽ�£�A��Ϊ���⹦�ܰ���
	rts
StatusAS_No_KeyA:
	bbs3	Timer_Flag,L_DisMode_KeyA_LongTri
	smb0	SpecialKey_Flag						; ��ʾģʽ�£�A��Ϊ���⹦�ܰ���
	rts
L_DisMode_KeyA_LongTri:
	jsr		SwitchState_AlarmSet				; ����ʾģʽ�л�����������ģʽ
	jmp		L_KeyExit							; ���ʱ�����ظ�ִ�й��ܺ���


L_KeyBTrigger:
	jsr		L_Universal_TriggerHandle			; ͨ�ð�������

	bbr2	Clock_Flag,StatusLM_No_KeyB
	jsr		Alarm_Snooze						; ����ʱ̰˯����
	jmp		L_KeyExit
StatusLM_No_KeyB:
	bbs3	Timer_Flag,L_DisMode_KeyB_LongTri
	smb1	SpecialKey_Flag
	rts
L_DisMode_KeyB_LongTri:
	jsr		TemperMode_Change					; �л�����-���϶�
	jmp		L_KeyExit							; ���ʱ�����ظ�ִ�й��ܺ���


L_KeyMTrigger:
	jsr		L_Universal_TriggerHandle			; ͨ�ð�������
	jsr		L_Key_NoSnoozeLoud					; ��������̰˯������

	lda		Sys_Status_Flag
	cmp		#0100B
	bne		StatusCS_No_KeyM
	bbr3	Timer_Flag,L_CSMode_KeyM_ShortTri
	jsr		L_Key_NoBeep
	jmp		L_KeyExit							; ʱ��ģʽM��������Ч
L_CSMode_KeyM_ShortTri:
	smb2	SpecialKey_Flag
	rts
StatusCS_No_KeyM:
	cmp		#1000B
	bne		StatusAS_No_KeyM
	jmp		L_KeyExit							; ����ģʽM����Ч
StatusAS_No_KeyM:
	bbs3	Timer_Flag,L_DisMode_KeyM_LongTri	; �ж���ʾģʽ�µ�M����
	lda		Sys_Status_Flag
	and		#0011B
	beq		StatusDM_No_KeyM
	smb2	SpecialKey_Flag						; ��ʾģʽ�£�M��Ϊ���⹦�ܰ���
StatusDM_No_KeyM:
	rts
L_DisMode_KeyM_LongTri:
	jsr		SwitchState_ClockSet				; ����ʾģʽ�л���ʱ������ģʽ
	jmp		L_KeyExit							; ���ʱ�����ظ�ִ�й��ܺ���


L_KeyUTrigger:
	jsr		L_Universal_TriggerHandle			; ͨ�ð�������
	jsr		L_Key_NoSnoozeLoud					; ��������̰˯������

	lda		Sys_Status_Flag
	and		#0011B
	beq		Status_NoDisMode_KeyU				; ʱ���Ժ�����U���л�12/24h
	bbr3	Timer_Flag,L_DMode_KeyU_ShortTri
	jsr		L_Key_NoBeep
	jmp		L_KeyExit							; ��ʾģʽU��������Ч
L_DMode_KeyU_ShortTri:
	smb3	SpecialKey_Flag
	rts
Status_NoDisMode_KeyU:
	bbr3	Timer_Flag,KeyU_NoQuikAdd
	rmb3	SpecialKey_Flag
	lda		Sys_Status_Flag
	cmp		#0100B
	bne		StatusCS_No_KeyU_Short
	jmp		AddNum_CS							; ʱ��ģʽ����
StatusCS_No_KeyU_Short:
	cmp		#1000B
	bne		L_KeyUTrigger_Exit
	jmp		AddNum_AS							; ����ģʽ����
KeyU_NoQuikAdd:
	smb3	SpecialKey_Flag
L_KeyUTrigger_Exit:
	rts


L_KeyDTrigger:
	jsr		L_Universal_TriggerHandle			; ͨ�ð�������
	jsr		L_Key_NoSnoozeLoud					; ��������̰˯������

	lda		Sys_Status_Flag
	and		#0011B
	beq		Status_NoDisMode_KeyD				; �ж��Ƿ�Ϊ��ʾģʽ
	bbr3	Timer_Flag,L_DMode_KeyD_ShortTri
	jsr		L_Key_NoBeep
	jmp		L_KeyExit							; ��ʾģʽD��������Ч
L_DMode_KeyD_ShortTri:
	smb4	SpecialKey_Flag
	rts
Status_NoDisMode_KeyD:
	bbr3	Timer_Flag,KeyD_NoQuikAdd
	rmb4	SpecialKey_Flag
	lda		Sys_Status_Flag
	cmp		#0100B
	bne		StatusCS_No_KeyD
	jmp		SubNum_CS							; ʱ��ģʽ����
StatusCS_No_KeyD:
	cmp		#1000B
	bne		L_KeyDTrigger_Exit
	jmp		SubNum_AS							; ����ģʽ����
KeyD_NoQuikAdd:
	smb4	SpecialKey_Flag
L_KeyDTrigger_Exit:
	rts


; �������̰˯������
L_Key_NoSnoozeLoud:
	lda		Clock_Flag
	and		#00001100B
	beq		?NoSnoozeLoud
	jsr		L_NoSnooze_CloseLoud				; ���̰˯������
	pla
	pla
	jmp		L_KeyExit
?NoSnoozeLoud:
	rts


; ��������ͨ�ù��ܣ�������������GPIO״̬���ã�������Ļ
; ͬʱ������Ƿ���ڻ����¼�
; ���ڴ��̰˯�����ֵĹ���B��û�У��ʲ��ڱ������ڴ���
L_Universal_TriggerHandle:
	jsr		F_KeyMatrix_Reset					; ���������GPIO״̬����
	lda		#0
	sta		Return_Counter						; ���÷���ʱ��ģʽ��ʱ

	bbs4	PD,WakeUp_Event						; ����ʱϨ���������ᵼ������
	bbs3	Timer_Flag,?Handle_Exit
	rmb1	Backlight_Flag
	lda		#0
	sta		Backlight_Counter
?Handle_Exit:
	rts
WakeUp_Event:
	rmb4	PD
	smb3	Key_Flag							; Ϩ��״̬�а������򴥷������¼�
	bbr0	Sys_Status_Flag,DP_2Mode_Reset
	bbr2	Key_Flag,DP_2Mode_Reset
	lda		#0
	sta		Sys_Status_Ordinal					; ʱ����ʾģʽ��Ϩ��������ص�ʱ��
DP_2Mode_Reset:
	jsr		L_Open_5020							; ��������LCD�ж�
	bbr2	Backlight_Flag,No_RFCMesure_KeyBeep	; �ֶ�Ϩ�����������ʪ��
	rmb2	Backlight_Flag
	jsr		F_RFC_MeasureStart					; �Զ�Ϩ�����Ѻ����̽���һ����ʪ�Ȳ���
No_RFCMesure_KeyBeep:
	pla
	pla
	jmp		L_KeyExit							; ���Ѵ������Ǵΰ�����û�а�������
WakeUp_Event_Exit:
	rts


L_Key_Beep:
	lda		#10B								; ���ð�����ʾ������������
	sta		Beep_Serial
	smb0	TMRC								; ��TIM0������ʱ��
	smb4	Key_Flag							; ��λ������ʾ����־
	rts

L_Key_NoBeep:
	lda		#0									; ���������ʾ������������
	sta		Beep_Serial
	rmb0	TMRC								; ��TIM0������ʱ��
	rmb4	Key_Flag							; ��λ������ʾ����־
	rts




; ʱ��ģʽ��ʱ�Ժ������л�
SwitchState_ClockDis:
	bbs0	Sys_Status_Flag,CD_ModeCHG
	lda		#0
	sta		Sys_Status_Ordinal					; �ӱ��ģʽ�л���ʱ��ʱ����Ҫ���һ����ģʽ
CD_ModeCHG:
	lda		Sys_Status_Ordinal					; �Ե�һλȡ������������ʾ��ʱ����ʾ֮���л�
	eor		#1
	sta		Sys_Status_Ordinal

	lda		#0001B
	sta		Sys_Status_Flag						; �л�ʱ����ʾ

	rmb6	Key_Flag							; ���DP��ʾ

	bbr0	Sys_Status_Ordinal,?SWState_ClockDis_Eixt
	lda		#5
	sta		Return_MaxTime						; ����ʾģʽ������ʱ����Ϊ5S
	jsr		F_Date_Display
	rts
?SWState_ClockDis_Eixt:
	jsr		L_TimeDot_Out
	rts




; �л�������ʾ-�̶���ʾ
SwitchState_DisMode:
	smb7	Key_Flag							; ����DP��ʾ1S��־
	smb6	Key_Flag							; ����DP��ʾ��־
	lda		#0
	sta		Counter_DP
	sta		Sys_Status_Ordinal
	lda		#0001B
	sta		Sys_Status_Flag						; �л��֡����ԻὫ��ǰ״̬����Ϊʱ��

	lda		Key_Flag
	eor		#100B
	sta		Key_Flag							; ȡ�����Ա�־λ

	jsr		F_Clock_Display
	rts




; �л���������ʾ״̬
SwitchState_AlarmDis:
	lda		#5
	sta		Return_MaxTime						; ��ʾģʽ��5S����ʱ��
	jsr		DP_Display_Over						; ���DPģʽ�ͼ�ʱ����ֹ��ȥ������ʾDP

	lda		Sys_Status_Flag
	cmp		#0010B
	beq		L_Change_Ordinal_AD					; �жϵ�ǰ״̬�Ƿ��Ѿ���������ʾ
	lda		#0010B
	sta		Sys_Status_Flag						; ��ǰ״̬���������л�������
	lda		#0
	sta		Sys_Status_Ordinal					; ������ģʽ���
	rts
L_Change_Ordinal_AD:
	inc		Sys_Status_Ordinal					; ��ǰ״̬Ϊ���ԣ��������ģʽ���
	lda		Sys_Status_Ordinal
	cmp		#3
	bcc		L_Ordinal_Exit_AD
	lda		#0
	sta		Sys_Status_Ordinal					; ��ģʽ��Ŵ���2ʱ��������ģʽ���
L_Ordinal_Exit_AD:
	rts




; �л���ʱ������ģʽ
SwitchState_ClockSet:
	lda		#15
	sta		Return_MaxTime						; ����ģʽ��15S����ʱ��
	jsr		DP_Display_Over						; ���DPģʽ�ͼ�ʱ����ֹ��ȥ������ʾDP

	lda		Sys_Status_Flag
	cmp		#0100B
	beq		L_Change_Ordinal_CS					; �жϵ�ǰ״̬�Ƿ��Ѿ���ʱ������
	lda		#0100B
	sta		Sys_Status_Flag						; ��ǰ״̬��ʱ�����л���ʱ��
	lda		#0
	sta		Sys_Status_Ordinal					; ������ģʽ���
	bra		L_Ordinal_Exit_CS
L_Change_Ordinal_CS:
	inc		Sys_Status_Ordinal					; ��ǰ״̬Ϊʱ�裬�������ģʽ���
	lda		Sys_Status_Ordinal
	cmp		#6
	bcc		L_Ordinal_Exit_CS
	lda		#0
	sta		Sys_Status_Ordinal					; ��ģʽ��Ŵ���5ʱ����ص�ʱ��ģʽ����������
	lda		#0001B
	sta		Sys_Status_Flag
L_Ordinal_Exit_CS:
	smb0	Timer_Flag							; �˳�����������һ����ʾ
	rmb1	Timer_Flag
	rts




; �л�����������ģʽ
SwitchState_AlarmSet:
	lda		#15
	sta		Return_MaxTime						; ����ģʽ��15S����ʱ��
	jsr		DP_Display_Over						; ���DPģʽ�ͼ�ʱ����ֹ��ȥ������ʾDP

	lda		Sys_Status_Flag
	cmp		#1000B
	beq		L_Change_Ordinal_AS					; �жϵ�ǰ״̬�Ƿ��Ѿ�����������
	bbr1	Sys_Status_Flag,No_AlarmDis2Set
	lda		#1000B
	sta		Sys_Status_Flag						; ��ǰ״̬���������л�������
	lda		Sys_Status_Ordinal					; ����ǰ��������״̬
	clc
	rol
	clc
	adc		Sys_Status_Ordinal					; ��Ե�ǰ��ʾ����������
	sta		Sys_Status_Ordinal
	bra		L_Ordinal_Exit_AS
No_AlarmDis2Set:
	lda		#0
	sta		Sys_Status_Ordinal					; ������ģʽ���
	lda		#1000B
	sta		Sys_Status_Flag						; ��ǰ״̬���������л�������
	bra		L_Ordinal_Exit_AS
L_Change_Ordinal_AS:
	inc		Sys_Status_Ordinal					; ��ǰ״̬Ϊ���裬�������ģʽ���
	lda		Sys_Status_Ordinal
	cmp		#9
	bcc		L_Ordinal_Exit_AS
	lda		#0
	sta		Sys_Status_Ordinal					; ��ģʽ��Ŵ���8ʱ����ص�ʱ��ģʽ����������
	lda		#0001B
	sta		Sys_Status_Flag
L_Ordinal_Exit_AS:
	smb0	Timer_Flag							; �˳�����������һ����ʾ
	rmb1	Timer_Flag
	rts




; �л��ƹ�����
; 0Ϩ����1����
LightLevel_Change:
	lda		Backlight_Level
	beq		Level0

	lda		#0
	sta		Backlight_Level
	rmb4	PD									; ����
	rmb0	PC
	rmb0	PC_IO_Backup

	rts

Level0:
	rmb0	PC
	jsr		L_Close_5020						; Ϩ����ر�LCD�ж�
	lda		#1
	sta		Backlight_Level
	smb4	PD									; ��һ�������Ǹ���
	smb0	PC_IO_Backup						; ���ü�������Ϊ�������´λ���Ϊ����
	rmb3	Key_Flag							; ������Ļ���ѱ�־
	rmb2	Backlight_Flag						; �ֶ�Ϩ�����������Ѳ�������ʪ�Ȳ���
	rts




; ����̰˯ģʽ
Alarm_Snooze:
	smb6	Clock_Flag							; ̰˯��������						
	smb3	Clock_Flag							; ����̰˯ģʽ
	rmb2	Clock_Flag							; �ر�����ģʽ

	lda		R_Snooze_Min						; ̰˯���ӵ�ʱ���5
	clc
	adc		#5
	cmp		#60
	bcs		L_Snooze_OverflowMin
	sta		R_Snooze_Min
	bra		L_Snooze_Exit
L_Snooze_OverflowMin:
	sec
	sbc		#60
	sta		R_Snooze_Min						; ����̰˯���ֵķ��ӽ�λ
	inc		R_Snooze_Hour
	lda		R_Snooze_Hour
	cmp		#24
	bcc		L_Snooze_Exit
	lda		#00									; ����̰˯Сʱ��λ
	sta		R_Snooze_Hour
L_Snooze_Exit:
	rts




; ʱ�������µ�12��24hģʽ�л�
ClockSet_SW_TimeMode:
	lda		Clock_Flag
	eor		#01									; ��ת12/24hģʽ��״̬
	sta		Clock_Flag

	jsr		L_Dis_xxHr
	rts

; ��ʾģʽ��12��24hģʽ�л�
DM_SW_TimeMode:
	lda		Clock_Flag
	eor		#01									; ��ת12/24hģʽ��״̬
	sta		Clock_Flag

	rmb6	Key_Flag							; ���DP��ʾ
	lda		#0
	sta		Sys_Status_Ordinal					; ���������ģʽ���л�Сʱ�ƻ�ص�ʱ��

	jsr		F_Display_Time
	rts




; �л��¶ȵ�λ
TemperMode_Change:
	lda		RFC_Flag							; ȡ����־λ���л����϶Ⱥ����϶�
	eor		#00010000B
	sta		RFC_Flag
	jsr		F_Display_Temper

	rts




; ʱ��ģʽ����
AddNum_CS:
	lda		Sys_Status_Ordinal
	bne		No_CS_TMSwitch
	jmp		ClockSet_SW_TimeMode
No_CS_TMSwitch:
	cmp		#1
	bne		No_CS_HourAdd
	jmp		L_TimeHour_Add
No_CS_HourAdd:
	cmp		#2
	bne		No_CS_MinAdd
	jmp		L_TimeMin_Add
No_CS_MinAdd:
	cmp		#3
	bne		No_CS_YearAdd
	jmp		L_DateYear_Add
No_CS_YearAdd:
	cmp		#4
	bne		No_CS_MonthAdd
	jmp		L_DateMonth_Add
No_CS_MonthAdd:
	jmp		L_DateDay_Add




; ����ģʽ����
AddNum_AS:
	lda		Sys_Status_Ordinal
	jsr		L_A_Div_3
	cmp		#0
	bne		No_AlarmSwitch_AddCHG
	lda		#1
	jsr		L_A_LeftShift_XBit
	jmp		L_Alarm_Switch
No_AlarmSwitch_AddCHG:
	cmp		#1
	bne		No_AlarmHourSet_Add
	jmp		L_AlarmHour_Add						; ����Сʱ����
No_AlarmHourSet_Add:
	jmp		L_AlarmMin_Add						; ���ӷ��Ӽ���




; ʱ��ģʽ����
SubNum_CS:
	lda		Sys_Status_Ordinal
	bne		No_CS_TMSwitch2
	jmp		ClockSet_SW_TimeMode
No_CS_TMSwitch2:
	cmp		#1
	bne		No_CS_HourSub
	jmp		L_TimeHour_Sub
No_CS_HourSub:
	cmp		#2
	bne		No_CS_MinSub
	jmp		L_TimeMin_Sub
No_CS_MinSub:
	cmp		#3
	bne		No_CS_YearSub
	jmp		L_DateYear_Sub
No_CS_YearSub:
	cmp		#4
	bne		No_CS_MonthSub
	jmp		L_DateMonth_Sub
No_CS_MonthSub:
	jmp		L_DateDay_Sub




; ����ģʽ����
SubNum_AS:
	lda		Sys_Status_Ordinal
	jsr		L_A_Div_3
	cmp		#0
	bne		No_AlarmSwitch_SubCHG
	lda		#1
	jsr		L_A_LeftShift_XBit
	jmp		L_Alarm_Switch
No_AlarmSwitch_SubCHG:
	cmp		#1
	bne		No_AlarmHourSet_Sub
	jmp		L_AlarmHour_Sub						; ����Сʱ����
No_AlarmHourSet_Sub:
	jmp		L_AlarmMin_Sub						; ���ӷ��Ӽ���




; ʱ����
L_TimeHour_Add:
	lda		R_Time_Hour
	cmp		#23
	bcs		TimeHour_AddOverflow
	inc		R_Time_Hour
	bra		TimeHour_Add_Exit
TimeHour_AddOverflow:
	lda		#0
	sta		R_Time_Hour
TimeHour_Add_Exit:
	jsr		L_LightLevel_WithKeyU
	jsr		F_Display_Time
	rts

; ʱ����
L_TimeHour_Sub:
	lda		R_Time_Hour
	beq		TimeHour_SubOverflow
	dec		R_Time_Hour
	bra		TimeHour_Sub_Exit
TimeHour_SubOverflow:
	lda		#23
	sta		R_Time_Hour
TimeHour_Sub_Exit:
	jsr		L_LightLevel_WithKeyD
	jsr		F_Display_Time
	rts




; ������
L_TimeMin_Add:
	lda		#0
	sta		R_Time_Sec							; �������ӻ������

	lda		R_Time_Min
	cmp		#59
	bcs		TimeMin_AddOverflow
	inc		R_Time_Min
	bra		TimeMin_Add_Exit
TimeMin_AddOverflow:
	lda		#0
	sta		R_Time_Min
TimeMin_Add_Exit:
	jsr		F_Display_Time
	rts

; �ּ���
L_TimeMin_Sub:
	lda		#0
	sta		R_Time_Sec							; �������ӻ������

	lda		R_Time_Min
	beq		TimeMin_SubOverflow
	dec		R_Time_Min
	bra		TimeMin_Sub_Exit
TimeMin_SubOverflow:
	lda		#59
	sta		R_Time_Min
TimeMin_Sub_Exit:
	jsr		F_Display_Time
	rts




; ������
L_DateYear_Add:
	lda		R_Date_Year
	cmp		#99
	bcs		DateYear_AddOverflow
	inc		R_Date_Year
	bra		DateYear_Add_Exit
DateYear_AddOverflow:
	lda		#0
	sta		R_Date_Year
DateYear_Add_Exit:
	jsr		L_DayOverflow_Juge					; ����ǰ���ڳ�����ǰ�·���������ֵ�������ڱ�Ϊ��ǰ���������
	jsr		F_Is_Leap_Year
	jsr		L_DisDate_Year
	rts

; �����
L_DateYear_Sub:
	lda		R_Date_Year
	beq		DateYear_SubOverflow
	dec		R_Date_Year
	bra		DateYear_Sub_Exit
DateYear_SubOverflow:
	lda		#99
	sta		R_Date_Year
DateYear_Sub_Exit:
	jsr		L_DayOverflow_Juge					; ����ǰ���ڳ�����ǰ�·���������ֵ�������ڱ�Ϊ��ǰ���������
	jsr		F_Is_Leap_Year
	jsr		L_DisDate_Year
	rts




; ������
L_DateMonth_Add:
	lda		R_Date_Month
	cmp		#12
	bcs		DateMonth_AddOverflow
	inc		R_Date_Month
	jsr		L_DayOverflow_Juge					; ����ǰ���ڳ�����ǰ�·���������ֵ�������ڱ�Ϊ��ǰ���������
	bra		DateMonth_Add_Exit
DateMonth_AddOverflow:
	lda		#1
	sta		R_Date_Month
DateMonth_Add_Exit:
	jsr		F_Date_Display
	rts

; �¼���
L_DateMonth_Sub:
	lda		R_Date_Month
	cmp		#1
	beq		DateMonth_SubOverflow
	dec		R_Date_Month
	jsr		L_DayOverflow_Juge					; ����ǰ���ڳ�����ǰ�·���������ֵ�������ڱ�Ϊ��ǰ���������
	bra		DateMonth_Sub_Exit
DateMonth_SubOverflow:
	lda		#12
	sta		R_Date_Month
DateMonth_Sub_Exit:
	jsr		F_Date_Display
	rts




; ������
L_DateDay_Add:
	inc		R_Date_Day
	jsr		L_DayOverflow_To_1					; ����ǰ���ڳ�����ǰ�·���������ֵ�������ڱ�Ϊ1��
	jsr		F_Date_Display
	rts

; �ռ���
L_DateDay_Sub:
	lda		R_Date_Day
	cmp		#1
	beq		DateDay_SubOverflow
	dec		R_Date_Day
	bra		DateDay_Sub_Exit
DateDay_SubOverflow:
	bbr0	Calendar_Flag,Common_Year_Get
	ldx		R_Date_Month
	dex
	lda		L_Table_Month_Leap,x
	sta		R_Date_Day
	bra		DateDay_Sub_Exit
Common_Year_Get:
	ldx		R_Date_Month
	dex
	lda		L_Table_Month_Common,x
	sta		R_Date_Day
DateDay_Sub_Exit:
	jsr		F_Date_Display
	rts





; ���ӿ���
; A�����飨��bit��
L_Alarm_Switch:
	eor		Alarm_Switch
	sta		Alarm_Switch
	smb0	Timer_Flag
	rmb1	Timer_Flag
	jsr		F_Alarm_SwitchStatue				; ˢ��һ�����ӿ�����ʾ
	rts


; ���ӷ�����
; X�����飬0~2
L_AlarmMin_Add:
	lda		Alarm_MinAddr,x
	cmp		#59
	bcs		AlarmMin_AddOverflow
	clc
	adc		#1
	sta		Alarm_MinAddr,x
	bra		AlarmMin_Add_Exit
AlarmMin_AddOverflow:
	lda		#0
	sta		Alarm_MinAddr,x
AlarmMin_Add_Exit:
	smb0	Timer_Flag
	rmb1	Timer_Flag
	jsr		F_AlarmMin_Set
	rts

; ���ӷּ���
; X�����飬0~2
L_AlarmMin_Sub:
	lda		Alarm_MinAddr,x
	beq		AlarmMin_SubOverflow
	sec
	sbc		#1
	sta		Alarm_MinAddr,x
	bra		AlarmMin_Sub_Exit
AlarmMin_SubOverflow:
	lda		#59
	sta		Alarm_MinAddr,x
AlarmMin_Sub_Exit:
	smb0	Timer_Flag
	rmb1	Timer_Flag
	jsr		F_AlarmMin_Set
	rts


; ����ʱ����
; X�����飬0~2
L_AlarmHour_Add:
	lda		Alarm_HourAddr,x
	cmp		#23
	bcs		AlarmHour_AddOverflow
	clc
	adc		#1
	sta		Alarm_HourAddr,x
	bra		AlarmHour_Add_Exit
AlarmHour_AddOverflow:
	lda		#0
	sta		Alarm_HourAddr,x
AlarmHour_Add_Exit:
	smb0	Timer_Flag
	rmb1	Timer_Flag
	jsr		F_AlarmHour_Set
	rts

; ����ʱ����
; X�����飬0~2
L_AlarmHour_Sub:
	lda		Alarm_HourAddr,x
	beq		AlarmHour_SubOverflow
	sec
	sbc		#1
	sta		Alarm_HourAddr,x
	bra		AlarmHour_Sub_Exit
AlarmHour_SubOverflow:
	lda		#23
	sta		Alarm_HourAddr,x
AlarmHour_Sub_Exit:
	smb0	Timer_Flag
	rmb1	Timer_Flag
	jsr		F_AlarmHour_Set
	rts




; �����Ƿ�������ж�
L_DayOverflow_Juge:
	jsr		F_Is_Leap_Year
	bbs0	Calendar_Flag,L_LeapYear_Handle		; ƽ������ı�ֿ���
	ldx		R_Date_Month						; ��ƽ��ÿ�·�������
	dex
	lda		L_Table_Month_Common,x
	sta		P_Temp
	bra		Day_Overflow_Juge
L_LeapYear_Handle:
	ldx		R_Date_Month						; ������ÿ�·�������
	dex
	lda		L_Table_Month_Leap,x
	sta		P_Temp
Day_Overflow_Juge:
	lda		P_Temp								; ��ǰ���ں�����������ڶԱ�
	cmp		R_Date_Day
	bcs		DateDay_NoOverflow
	lda		P_Temp
	sta		R_Date_Day
DateDay_NoOverflow:
	rts

; �����Ƿ�������ж�
L_DayOverflow_To_1:
	jsr		F_Is_Leap_Year
	bbs0	Calendar_Flag,L_LeapYear_Handle2	; ƽ������ı�ֿ���
	ldx		R_Date_Month						; ��ƽ��ÿ�·�������
	dex
	lda		L_Table_Month_Common,x
	sta		P_Temp
	bra		Day_Overflow_Juge2
L_LeapYear_Handle2:
	ldx		R_Date_Month						; ������ÿ�·�������
	dex
	lda		L_Table_Month_Leap,x
	sta		P_Temp
Day_Overflow_Juge2:
	lda		P_Temp								; ��ǰ���ں�����������ڶԱ�
	cmp		R_Date_Day
	bcs		DateDay_NoOverflow2
	lda		#1
	sta		R_Date_Day
DateDay_NoOverflow2:
	rts


L_KeyDelay:
	lda		#0
	sta		P_Temp
DelayLoop:
	inc		P_Temp
	lda		P_Temp
	cmp		#129
	bcc		DelayLoop
	
	rts
