;M1002 set_flag extrude_cali_flag=1
;M1002 set_flag g29_before_print_flag=1
;M1002 set_flag auto_cali_toolhead_offset_flag=1
;M1002 set_flag build_plate_detect_flag=1

;======== P2S start gcode - Fast PLA profile ==========
;===== 2026/02/26 =====
; Optimized for PLA only -- do NOT use with PETG, ABS, ASA, PC or any
; material requiring conservative acceleration. Use start_gcode_P2S_fixed.gcode
; for all other filaments.
; Changes vs standard profile:
;   - M204 S20000 : acceleration raised from 10000 to 20000 mm/s2
;   - M982.2 S1 moved after M975 S1 for immediate noise reduction
;   - Unconditional G28 after bed leveling removed
  
  M140 S[bed_temperature_initial_layer_single] ; heat heatbed first
  M993 A0 B0 C0 ; nozzle cam detection not allowed.
  M400

;=====printer start sound ===================
M17
M400 S1
M1006 S1
M1006 A53 B9 L50 C53 D9 M50 E53 F9 N50 
M1006 A56 B9 L50 C56 D9 M50 E56 F9 N50 
M1006 A61 B9 L50 C61 D9 M50 E61 F9 N50 
M1006 A53 B9 L50 C53 D9 M50 E53 F9 N50 
M1006 A56 B9 L50 C56 D9 M50 E56 F9 N50 
M1006 A61 B18 L50 C61 D18 M50 E61 F18 N50 
M1006 W
;=====printer start sound ===================

  M620 M ;enable remap
  G389

;===== avoid end stop =================
  G91
  G380 S2 Z22 F1200
  G380 S2 Z-12 F1200
  G90
;===== avoid end stop =================

;===== reset machine status =================
  M204 S20000 ; Fast PLA: raised from stock 10000
  M630 S0 P1
  G90
  M17 D ; reset motor current to default
  M960 S5 P1 ; turn on logo lamp
  G90
  M220 S100 ;Reset Feedrate
  M1002 set_gcode_claim_speed_level: 5
  M221 S100 ;Reset Flowrate
  M73.2   R1.0 ;Reset left time magnitude
  G29.1 Z{+0.0} ; clear z-trim value first
  M983.1 M1
  M975 S1 ; enable input shaping immediately so M982.2 is effective
  M982.2 S1 ; turn on cog noise reduction
  M983.4 S0
;===== reset machine status =================

;==== set airduct mode ==== 
;==== if Chamber Cooling is necessary ====
{if (overall_chamber_temperature >= 40)}
M145 P1 ; set airduct mode to heating mode for heating
M106 P2 S255 ; turn on filter fan
M622.1 S0
M1002 judge_flag ventobox_replace_aux1_fan_flag
M622 J0
M106 P10 S0 ; turn off left aux fan
M623
{else}
{if (min_vitrification_temperature <= 50)}
M145 P0 ; set airduct mode to cooling mode for cooling
M106 P2 S255 ; turn on auxiliary fan for cooling
M106 P3 S127 ; turn on chamber fan for cooling
M1002 gcode_claim_action : 29
M191 S0 ; wait for chamber temp
M106 P2 S102 ; turn on chamber cooling fan
M622.1 S0
M1002 judge_flag ventobox_replace_aux1_fan_flag
M622 J0
M106 P10 S0 ; turn off left aux fan
M623
M142 P6 R30 S40 U0.3 V0.8 ; set PETG exhaust chamber autocooling
{else}
M145 P1 ; set airduct mode to heating mode for heating
M106 P2 S127 ; turn on 50% filter fan
M142 P6 R30 S40 U0.3 V0.8 ; set PLA/TPU exhaust chamber autocooling
{endif}
{endif}
;==== set airduct mode ==== 

;===== start to heat heatbed & hotend==========
  M1002 gcode_claim_action : 2
  M1002 set_filament_type:{filament_type[initial_no_support_extruder]}
  M104 S140 A        

  G29.2 S0 ; avoid invalid abl data

;===== first homing start =====
  M1002 gcode_claim_action : 13
  G28 X T300
  G150.1 F8000 ; wipe mouth to avoid filament stick to heatbed
  G150.3
  M972 S24 P0
  M972 S26 P0 C0
  M972 S42 P0 T5000
  G150.1 F8000 ; wipe mouth to avoid filament stick to heatbed
  G90
  G1 X128 Y128 F30000
  G28 Z P0 T400
  M400
;===== first homing end =====

;===== detection start =====
  M1002 gcode_claim_action : 11
  M104 S{nozzle_temperature_initial_layer[initial_no_support_extruder]-80} A ; rise temp in advance
  M972 S19 P0 T5000 ;plate type detection
  
  {if max_print_z >= 145}
    M1002 gcode_claim_action : 75 ;  Detect obstacles at the botton of the heated bed
    G150.3
    M104 S{nozzle_temperature_initial_layer[initial_no_support_extruder]} ; rise temp in advance
    G3811 Z{max_print_z}  ; Detect obstacles at the bottom of the heated bed
  {endif}
;===== detection end =====

;===== prepare print temperature and material ==========
  M400
  M211 X0 Y0 Z0 ;turn off soft endstop
  M975 S1 ; turn on input shaping
  
  G29.2 S0 ; avoid invalid abl data
  G150.3
{if ((filament_type[initial_no_support_extruder] == "PLA") || (filament_type[initial_no_support_extruder] == "PLA-CF") || (filament_type[initial_no_support_extruder] == "PETG")) && (nozzle_diameter[initial_no_support_extruder] == 0.2)}
M620.10 A0 F74.8347 H{nozzle_diameter[initial_no_support_extruder]} T{flush_temperatures[initial_no_support_extruder]} P{nozzle_temperature_initial_layer[initial_no_support_extruder]} S1
M620.10 A1 F74.8347 H{nozzle_diameter[initial_no_support_extruder]} T{flush_temperatures[initial_no_support_extruder]} P{nozzle_temperature_initial_layer[initial_no_support_extruder]} S1
{else}
M620.10 A0 F{flush_volumetric_speeds[initial_no_support_extruder]/2.4053*60} H{nozzle_diameter[initial_no_support_extruder]} T{flush_temperatures[initial_no_support_extruder]} P{nozzle_temperature_initial_layer[initial_no_support_extruder]} S1
M620.10 A1 F{flush_volumetric_speeds[initial_no_support_extruder]/2.4053*60} H{nozzle_diameter[initial_no_support_extruder]} T{flush_temperatures[initial_no_support_extruder]} P{nozzle_temperature_initial_layer[initial_no_support_extruder]} S1
{endif}
  
 M620.11 P0 L0 I[initial_no_support_extruder] E0
 M620.11 K0 I[initial_no_support_extruder] R0
  
  M620 S[initial_no_support_extruder]A   ; switch material if AMS exist
  M1002 gcode_claim_action : 4
  M1002 set_filament_type:UNKNOWN
  M400
  T[initial_no_support_extruder]
  M400
  M628 S0
  M629
  M400
  M1002 set_filament_type:{filament_type[initial_no_support_extruder]}
  M621 S[initial_no_support_extruder]A
  M104 S{nozzle_temperature_initial_layer[initial_no_support_extruder]}
  M400
  M106 P1 S0
  M400
  G29.2 S1
;===== prepare print temperature and material ==========


;===== auto extrude cali start =========================
  M975 S1
  M1002 judge_flag extrude_cali_flag
  M622 J0
    M983.3 F{filament_max_volumetric_speed[initial_no_support_extruder]/2.4} A0.4 ; cali dynamic extrusion compensation
  M623

  M622 J1
    M1002 set_filament_type:{filament_type[initial_no_support_extruder]}
    M1002 gcode_claim_action : 8
    M109 S{nozzle_temperature[initial_no_support_extruder]}
    G90
    M83
    M983.3 F{filament_max_volumetric_speed[initial_no_support_extruder]/2.4} A0.4 ; cali dynamic extrusion compensation
    M400
    M106 P1 S255
    M400 S5
    M106 P1 S0
    G150.3
  M623

  M622 J2
    M1002 set_filament_type:{filament_type[initial_no_support_extruder]}
    M1002 gcode_claim_action : 8
    M109 S{nozzle_temperature[initial_no_support_extruder]}
    G90
    M83
    M983.3 F{filament_max_volumetric_speed[initial_no_support_extruder]/2.4} A0.4 ; cali dynamic extrusion compensation
    M400
    M106 P1 S255
    M400 S5
    M106 P1 S0
    G150.3
  M623
;===== auto extrude cali end =========================

  {if hold_chamber_temp_for_flat_print}
    M1002 gcode_claim_action : 58
    M104 S{first_layer_temperature[initial_no_support_extruder]}
    {if bed_temperature_initial_layer_single > 89}
        M1030 S1800      
        SYNC R0 T1800
    {else}
        M1030 S300
        SYNC R0 T300
    {endif}
    M1030 C
  {endif}
  
  {if filament_type[current_extruder] == "TPU" || filament_type[current_extruder] == "PVA"}
  {else}
    M83
    G1 E-3 F1800
    M400 P500
  {endif}
  G150.2
  G150.1 F8000
  G150.2
  G150.1 F8000

  G91
  G1 Y-16 F12000 ; move away from the trash bin
  G90
  M400

  M104 S{nozzle_temperature_initial_layer[initial_no_support_extruder]-80} A

;===== wipe right nozzle start =====
  M1002 gcode_claim_action : 14
  G150 T{nozzle_temperature_initial_layer[initial_no_support_extruder]}
  M400
  
{if filament_type[current_extruder] == "PC"}
  M109 S170 A
{else}
  M109 S140 A
{endif}
  G91
  G1 Z5 F1200
  G90
  M400
  G150.1
;===== wipe left nozzle end =====


;===== mech mode sweep start =====
  M1002 gcode_claim_action : 3
  G90
  G1 X128 Y128 F20000
  G1 Z5 F1200
  M400 P200
  M970.3 Q1 A5 K0 O1
  M970.2 Q1 K1 W74 Z0.01
  M974 Q1 S2 P0
  M970.3 Q0 A7 K0 O1
  M970.2 Q0 K1 W74 Z0.01
  M974 Q0 S2 P0
  M975 S1
  M400
;===== mech mode sweep end =====

;===== bed leveling ==================================
  M1002 gcode_claim_action : 54
  M190 S[bed_temperature_initial_layer_single]; ensure bed temp
  M109 S140 A
  M106 S0 ; turn off fan , too noisy
  M1002 judge_flag g29_before_print_flag
  M622 J1
    M1002 gcode_claim_action : 1
    {if hold_chamber_temp_for_flat_print}
      G29 H
    {else}
      G29 A1 X{first_layer_print_min[0]} Y{first_layer_print_min[1]} I{first_layer_print_size[0]} J{first_layer_print_size[1]}
    {endif}
    M400
    M500 ; save cali data
  M623
    
  M622 J2
    M1002 gcode_claim_action : 1
    {if hold_chamber_temp_for_flat_print}
      G29 H
    {else}
      G29 A2 X{first_layer_print_min[0]} Y{first_layer_print_min[1]} I{first_layer_print_size[0]} J{first_layer_print_size[1]}
    {endif}
    M400
    M500 ; save cali data
  M623

  M622 J0
    ; skip to homing
  M623
  G29.2 S1
  G28 ; home after leveling block (or after skipping it)
;===== bed leveling end ================================

  M985.1 U0 E2
  M985.1 U1 E2

  M104 S[nozzle_temperature_initial_layer] A
  G150.3 ; move to garbage can to wait for temp

;===== wait temperature reaching the reference value =======
  M190 S[bed_temperature_initial_layer_single] 

  ;========turn off light and fans =============
  M960 S1 P0 ; turn off laser
  M960 S2 P0 ; turn off laser
  M106 S0 ; turn off cooling fan
  
;===== wait temperature reaching the reference value =======

  M1002 gcode_claim_action : 255
  M400
  M975 S1 ; turn on mech mode supression

;============switch again==================
  M211 X0 Y0 Z0 ;turn off soft endstop
  G91
  G1 Z6 F1200
  G90
  M1002 set_filament_type:{filament_type[initial_no_support_extruder]}
  M620 S[initial_no_support_extruder]A
  M400
  T[initial_no_support_extruder]
  M400
  M628 S0
  M629
  M400
  M621 S[initial_no_support_extruder]A
;============switch again==================

;===== for Textured PEI Plate , lower the nozzle as the nozzle was touching topmost of the texture when homing ==
  {if bed_temperature_initial_layer_single > 89}
    {if curr_bed_type=="Textured PEI Plate"}
      G29.1 Z{-0.02} ; for Textured PEI Plate
    {else}
      G29.1 Z{0.0}
    {endif}
  {else}
    {if curr_bed_type=="Textured PEI Plate"}
      G29.1 Z{0.01} ; for Textured PEI Plate
    {else}
      G29.1 Z{0.03}
    {endif}
  {endif}

  M500

;===== nozzle load line ===============================
M1002 gcode_claim_action : 51
  G29.2 S1 ; ensure z comp turn on
  G90
  M83
  M109 S{nozzle_temperature_initial_layer[initial_no_support_extruder]}
  G0 X100 Y0 F24000
  M400
  G130 O0 X100 Y-0.2 Z0.6 F{filament_max_volumetric_speed[initial_no_support_extruder]/2/2.4053} L40 E12 D4
  G90
  M83
  G1 Z0.5
  M400
;===== nozzle load line end ===========================
M1002 gcode_claim_action : 0
  G29.99

{if (filament_type[initial_no_support_extruder] == "TPU") || 
(filament_type[initial_no_support_extruder] == "PLA") ||  (filament_type[initial_no_support_extruder] == "PETG")}
M1015.3 S1 H[nozzle_diameter];enable tpu, pla and petg clog detect
{else}
M1015.3 S0;disable clog detect
{endif}

{if (filament_type[initial_no_support_extruder] == "PLA") ||  (filament_type[initial_no_support_extruder] == "PETG")
 ||  (filament_type[initial_no_support_extruder] == "PLA-CF")  ||  (filament_type[initial_no_support_extruder] == "PETG-CF")}
M1015.4 S1 K1 H[nozzle_diameter] ;enable E air printing detect
{else}
M1015.4 S0 K0 H[nozzle_diameter] ;disable E air printing detect
{endif}

M620.6 I[initial_no_support_extruder] W1 ;enable ams air printing detect

M1010 Q0 B0.023 S0.01
M1010 Q1 B0.005 S0.01
M1010.1 S1
