# Set the reference directory for source file relative paths (by default the value is script directory path)
set origin_dir "."

# Set the project name
set _xil_proj_name_ "PRMEMC_Test"

# Create project
create_project ${_xil_proj_name_} ./${_xil_proj_name_} -part xcvu7p-flvb2104-1-e

# Set the directory path for the new project
set proj_dir [get_property directory [current_project]]

# Create 'sources_1' fileset (if not found)
if {[string equal [get_filesets -quiet sources_1] ""]} {
  create_fileset -srcset sources_1
}

# Set IP repository paths
set obj [get_filesets sources_1]
set_property "ip_repo_paths" "{[file normalize "$origin_dir/../../project/match_calc/solution1/impl/"], [file normalize "$origin_dir/../../project/matchengine/solution1/impl/"], [file normalize "$origin_dir/../../project/projrouter/solution1/impl/"]}" $obj 
#set_property "ip_repo_paths" "[file normalize "$origin_dir/../../project/matchengine/solution1/impl/"]" $obj 
#set_property "ip_repo_paths" "[file normalize "$origin_dir/../../project/projrouter/solution1/impl/"]" $obj


# Rebuild user ip_repo's index before adding any source files
update_ip_catalog -rebuild

# Set 'sources_1' fileset object
set obj [get_filesets sources_1]
set files [list \
 [file normalize "${origin_dir}/../../TrackletAlgorithm/Memory.v"] \
 [file normalize "${origin_dir}/../../TrackletAlgorithm/MemoryBinned.v"] \
 [file normalize "${origin_dir}/sourceFiles/SectorProcessor.v"] \
]
add_files -norecurse -fileset $obj $files

# Create 'sim_1' fileset (if not found)
if {[string equal [get_filesets -quiet sim_1] ""]} {
  create_fileset -simset sim_1
}

# Set 'sim_1' fileset object
set obj [get_filesets sim_1]
set files [list \
	       [file normalize "${origin_dir}/sourceFiles/SectorProcessor_test.v"] \
	       [file normalize "${origin_dir}/Waveforms/CurrentWaveform.wcfg"] \
	       [file normalize "${origin_dir}/emData/AS_L3PHICn4.dat"] \
	       [file normalize "${origin_dir}/emData/TrackletProjections_TPROJ_L1L2F_L3PHIC_04MOD.dat"] \
	       [file normalize "${origin_dir}/emData/TrackletProjections_TPROJ_L1L2G_L3PHIC_04MOD.dat"] \
	       [file normalize "${origin_dir}/emData/TrackletProjections_TPROJ_L1L2H_L3PHIC_04MOD.dat"] \
	       [file normalize "${origin_dir}/emData/TrackletProjections_TPROJ_L1L2I_L3PHIC_04MOD.dat"] \
	       [file normalize "${origin_dir}/emData/TrackletProjections_TPROJ_L1L2J_L3PHIC_04MOD.dat"] \
	       [file normalize "${origin_dir}/emData/TrackletProjections_TPROJ_L5L6B_L3PHIC_04MOD.dat"] \
	       [file normalize "${origin_dir}/emData/TrackletProjections_TPROJ_L5L6C_L3PHIC_04MOD.dat"] \
	       [file normalize "${origin_dir}/emData/TrackletProjections_TPROJ_L5L6D_L3PHIC_04MOD.dat"] \
	       [file normalize "${origin_dir}/emData/VMStubs_VMSME_L3PHIC17n1_04MOD.dat"] \
	       [file normalize "${origin_dir}/emData/VMStubs_VMSME_L3PHIC18n1_04MOD.dat"] \
	       [file normalize "${origin_dir}/emData/VMStubs_VMSME_L3PHIC19n1_04MOD.dat"] \
	       [file normalize "${origin_dir}/emData/VMStubs_VMSME_L3PHIC20n1_04MOD.dat"] \
	       [file normalize "${origin_dir}/emData/VMStubs_VMSME_L3PHIC21n1_04MOD.dat"] \
	       [file normalize "${origin_dir}/emData/VMStubs_VMSME_L3PHIC22n1_04MOD.dat"] \
	       [file normalize "${origin_dir}/emData/VMStubs_VMSME_L3PHIC23n1_04MOD.dat"] \
	       [file normalize "${origin_dir}/emData/VMStubs_VMSME_L3PHIC24n1_04MOD.dat"] \

]
add_files -norecurse -fileset $obj $files

# Create .xci file
create_ip -name MatchCalculatorTop -vendor xilinx.com -library hls -version 1.0 -module_name MatchCalculatorTop_0

# Set 'sim_1' fileset properties
set obj [get_filesets sim_1]
set_property -name "top" -value "SectorProcessor_test" -objects $obj
set_property -name "xsim.simulate.runtime" -value "3000ns" -objects $obj

puts "INFO: Project created:${_xil_proj_name_}"

# Launch Simulation
launch_simulation
