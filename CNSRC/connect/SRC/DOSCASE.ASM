CODE    SEGMENT BYTE PUBLIC
        public UpTable
        public LoTable
UpTable LABEL BYTE                    ;Maps international characters
                                        ;#128..#255
        db 080h,081h,082h,083h,084h,085h,086h,087h ; 8
        db 088h,089h,08Ah,08Bh,08Ch,08Dh,08Eh,08Fh
        db 090h,091h,092h,093h,094h,095h,096h,097h ; 9
        db 098h,099h,09Ah,09Bh,09Ch,09Dh,09Eh,09Fh
        db 080h,081h,082h,083h,084h,085h,086h,087h ; A
        db 088h,089h,08Ah,08Bh,08Ch,08Dh,08Eh,08Fh
        db 0B0h,0B1h,0B2h,0B3h,0B4h,0B5h,0B6h,0B7h ; B
        db 0B8h,0B9h,0BAh,0BBh,0BCh,0BDh,0BEh,0BFh
        db 0C0h,0C1h,0C2h,0C3h,0C4h,0C5h,0C6h,0C7h ; C
        db 0C8h,0C9h,0CAh,0CBh,0CCh,0CDh,0CEh,0CFh
        db 0D0h,0D1h,0D2h,0D3h,0D4h,0D5h,0D6h,0D7h ; D
        db 0D8h,0D9h,0DAh,0DBh,0DCh,0DDh,0DEh,0DFh
        db 090h,091h,092h,093h,094h,095h,096h,097h ; E
        db 098h,099h,09Ah,09Bh,09Ch,09Dh,09Eh,09Fh
        db 0F0h,0F0h,0F2h,0F3h,0F4h,0F5h,0F6h,0F7h ; F
        db 0F8h,0F9h,0FAh,0FBh,0FCh,0FDh,0FEh,0FFh

LoTable LABEL BYTE                    ;Maps international characters
                                        ;#128..#255
        db 0A0h,0A1h,0A2h,0A3h,0A4h,0A5h,0A6h,0A7h ; 8
        db 0A8h,0A9h,0AAh,0ABh,0ACh,0ADh,0AEh,0AFh
        db 0E0h,0E1h,0E2h,0E3h,0E4h,0E5h,0E6h,0E7h ; 9
        db 0E8h,0E9h,0EAh,0EBh,0ECh,0EDh,0EEh,0EFh
        db 0A0h,0A1h,0A2h,0A3h,0A4h,0A5h,0A6h,0A7h ; A
        db 0A8h,0A9h,0AAh,0ABh,0ACh,0ADh,0AEh,0AFh
        db 0B0h,0B1h,0B2h,0B3h,0B4h,0B5h,0B6h,0B7h ; B
        db 0B8h,0B9h,0BAh,0BBh,0BCh,0BDh,0BEh,0BFh
        db 0C0h,0C1h,0C2h,0C3h,0C4h,0C5h,0C6h,0C7h ; C
        db 0C8h,0C9h,0CAh,0CBh,0CCh,0CDh,0CEh,0CFh
        db 0D0h,0D1h,0D2h,0D3h,0D4h,0D5h,0D6h,0D7h ; D
        db 0D8h,0D9h,0DAh,0DBh,0DCh,0DDh,0DEh,0DFh
        db 0E0h,0E1h,0E2h,0E3h,0E4h,0E5h,0E6h,0E7h ; E
        db 0E8h,0E9h,0EAh,0EBh,0ECh,0EDh,0EEh,0EFh
        db 0F1h,0F1h,0F2h,0F3h,0F4h,0F5h,0F6h,0F7h ; F
        db 0F8h,0F9h,0FAh,0FBh,0FCh,0FDh,0FEh,0FFh

CODE    ends
end
