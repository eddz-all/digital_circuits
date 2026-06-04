onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib verify_RAM_opt

do {wave.do}

view wave
view structure
view signals

do {verify_RAM.udo}

run -all

quit -force
