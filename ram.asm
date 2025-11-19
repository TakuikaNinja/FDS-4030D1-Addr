; RAM

; zeropage
.segment "ZEROPAGE"
	temp: .res 16 ; temp memory, also used by FDS BIOS
;	FDS_STATUS_MIRROR: .res 1
	IRQ_Count: .res 1
	AddressesLo: .res 2
	AddressesHi: .res 2

; BIOS zeropage variables
.segment "BIOSZP": zeropage

; controller states
	ExpTransitions: .res 4 ; up->down transitions for Pad1, Pad2, Exp1, Exp2 (used by ReadDownExpPads)
	Buttons: .res 4 ; Usage depends on polling routine

; FDS BIOS register mirrors
	FDS_EXT_MIRROR: .res 1
	FDS_CTRL_MIRROR: .res 1
	JOY1_MIRROR: .res 1
	PPU_Y_SCROLL_MIRROR: .res 1
	PPU_X_SCROLL_MIRROR: .res 1
	PPU_MASK_MIRROR: .res 1
	PPU_CTRL_MIRROR: .res 1

; stack
; FDS BIOS vector flags
.segment "STACK"
	NMI_FLAG: .res 1 ; (bits 6 & 7)
	IRQ_FLAG: .res 1 ; (bits 6 & 7)
	RST_FLAG: .res 1 ; $35 = skip BIOS
	RST_TYPE: .res 1 ; $ac = first boot, $53 = soft-reset

