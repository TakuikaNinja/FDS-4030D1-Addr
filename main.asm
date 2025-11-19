; Main program code
;
; Formatting:
; - Width: 132 Columns
; - Tab Size: 4, using tab
; - Comments: Column 57

NOPSLIDE_SIZE = $1000
NOPSlide:
		.res NOPSLIDE_SIZE, $ea
		jmp NOPSlide

; duplicate the BIOS VINTWait routine so we can execute the NOP slide while waiting for NMI
VBlankWait:
		pha
		lda NMI_FLAG
		pha
		lda #$00
		sta NMI_FLAG									; use BIOS VINTWait handler
		lda #%11000000									; point IRQs to our own handler so we know if they occur
		sta IRQ_FLAG
		bit PPU_STATUS
		lda PPU_CTRL_MIRROR
		ora #$80										; enable NMIs
		sta PPU_CTRL_MIRROR
		sta PPU_CTRL
		lda #%10000010
		tay
		iny
;		jsr Delay131									; guarantee a reload?
		cli
		sta FDS_IO_ENABLE								; toggle $4023.D0
		sty FDS_IO_ENABLE								; to reset watchdog
		jmp NOPSlide

; "NMI" routine which is entered to bypass the BIOS check
Bypass:
		lda #$00										; disable NMIs since we don't need them anymore
		sta PPU_CTRL
		lda #$35										; tell the FDS that the BIOS "did its job"
		sta RST_FLAG
		lda #$ac
		sta RST_TYPE
		jmp ($fffc)										; jump to reset FDS

; Reset handler
Reset:
;		sei												; we don't want the BIOS to ack IRQs here
		lda #$00
		tax
@clrmem:
		sta $00,x
		cpx #4
		bcc :+
		sta $0100,x										; preserve stack variables
:
		dex
		bne @clrmem
		
		jsr InitNametables
		
		lda #%10010000									; enable NMIs & change background pattern map access
		sta PPU_CTRL_MIRROR
		sta PPU_CTRL
		
; Initialise background
BGInit:
		jsr CallVINTWait
		jsr DisPFObj
		jsr VRAMStructWrite
	.addr Palettes
		jsr CallVINTWait
		jsr EnPF
		jsr SetScroll

; execute delay routine in DRAM
		jsr VBlankWait
		cli												; VINTWait handler preserves I flag state from NMI...
		jsr PrintAddresses
		
		lda #$00
		tax
		tay

Forever:
		jsr Delay
		jsr Delayms
		jmp Forever

; duplicate of BIOS Delayms routine
Delay:
		ldx $00
		ldx #$fe
:
		nop
		dex
		bne :-
		cmp $00
		dey
		bne Delay
		rts

CallVINTWait:
		jsr VINTWait
		cli												; VINTWait usage preserves I flag state from NMI...
		rts

; If this IRQ handler is ever called, 
; Print the return address
InterruptRequest:
		pha
		txa
		pha
		tya
		pha
		
		lda PPU_MASK_MIRROR
		tax
		inx												; enable grayscale for raster display
		stx PPU_MASK
		bit FDS_STATUS									; ack IRQs
		jsr Delay131									; call the associated BIOS delay routine
		sta PPU_MASK
		ldy IRQ_Count
		cpy #$02
		bcs :+
		jsr FetchAddress
:
		pla
		tay
		pla
		tax
		pla
		rti

; Y = IRQ count
FetchAddress:
		tsx
		lda NMI_FLAG+8,x
		sta AddressesLo,y
		lda NMI_FLAG+7,x
		sta AddressesHi,y
		inc IRQ_Count
		rts

PrintAddresses:
		lda AddressesLo+0
		ora AddressesHi+0
		beq :+
		lda AddressesLo+0
		jsr NumToChars
		sta ReturnAddr1+0
		sty ReturnAddr1+1
		lda AddressesHi+0
		jsr NumToChars
		stx ReturnAddr1+2
		sty ReturnAddr1+3
:
		lda AddressesLo+1
		ora AddressesHi+1
		beq :+
		lda AddressesLo+1
		jsr NumToChars
		stx ReturnAddr2+0
		sty ReturnAddr2+1
		lda AddressesHi+1
		jsr NumToChars
		stx ReturnAddr2+2
		sty ReturnAddr2+3
:
;		jsr CallVINTWait
		jsr VRAMStructWrite
	.addr BGData
		jmp SetScroll

NumToChars:												; splits A into X/Y
		pha
		and #$0f
		tay
		pla
		lsr
		lsr
		lsr
		lsr
		tax
		rts

InitNametables:
		lda #$20										; top-left
		jsr InitNametable
		lda #$28										; bottom-left

InitNametable:
		ldx #$24										; clear nametable & attributes for high address held in A
		ldy #$00
		jmp VRAMFill

; VRAM transfer structures
BGData:
	vram_addr $2000, 14, 14
	encode_length INC1, COPY, 4
ReturnAddr1:
	.res 4, $21 ; 'X'
	
	vram_addr $2000, 14, 15
	encode_length INC1, COPY, 4
ReturnAddr2:
	.res 4, $21 ; 'X'
	encode_terminator

; Just write to all 16 entries so PPUADDR safely leaves the palette RAM region
; PPUADDR ends at $3F20 before the next write (avoids rare palette corruption)
; (palette entries will never be changed anyway, so we might as well set them all)
Palettes:
	.dbyt $3f00
	encode_length INC1, COPY, PaletteDataSize

.proc PaletteData
	.repeat 8
	.byte $0f, $30, $10, $0f
	.endrepeat
.endproc
PaletteDataSize = .sizeof(PaletteData)
	encode_terminator

