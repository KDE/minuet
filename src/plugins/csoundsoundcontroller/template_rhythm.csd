<CsoundSynthesizer>
<CsOptions>
; Select audio/midi flags here according to platform
;;;RT audio out, midi in, note=p4 and velocity=p5
--opcode-lib=/data/data/org.kde.minuet/qt-reserved-files/share/libfluidOpcodes.so
-odac 
;-+rtmidi=virtual -M0d --midi-key=4 --midi-velocity-amp=5
;-iadc    ;;;uncomment -iadc if RT audio input is needed too
; For Non-realtime ouput leave only the line below:
; -o cpsmidinn.wav -W ;;; for file output any platform
</CsOptions>
<CsInstruments>

sr = 44100
ksmps = 32
nchnls = 2
0dbfs = 1

massign 0, 1	;assign all midi to instr. 1

instr 1	;play virtual keyboard

inote = p4
icps  = cpsmidinn(inote)
asig pluck 0.5, inote, inote*0.81, 1, 3, .5
out asig
print icps
endin

</CsInstruments>
<CsScore>
</CsScore>
</CsoundSynthesizer>

