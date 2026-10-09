if {[file exists work]} { vdel -lib work -all }
vlib work
vlog -sv ../rtl/ALU.v ALU_tb.sv
vsim -voptargs=+acc work.tb_alu
add wave -radix hex /tb_alu/a /tb_alu/b /tb_alu/alu_op /tb_alu/result /tb_alu/zero
run -all
