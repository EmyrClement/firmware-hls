--! Standard library
library ieee;
--! Standard package
use ieee.std_logic_1164.all;

--! Xilinx library
library unisim;
--! Xilinx package
use unisim.vcomponents.all;

--! User packages
use work.mytypes_pkg.all;


entity top_tf is
  port(
    clk     : in std_logic;
    reset   : in std_logic;
    en_proc : in std_logic;
    bx_in_ProjectionRouter : in std_logic_vector(2 downto 0);
    -- For TrackletProjections memories
    TPROJ_L3PHIC_dataarray_data_V_wea       : in t_myarray8_1b;
    TPROJ_L3PHIC_dataarray_data_V_writeaddr : in t_myarray8_8b;
    TPROJ_L3PHIC_dataarray_data_V_din       : in t_myarray8_60b;
    TPROJ_L3PHIC_nentries_V_we  : in t_myarray2_8_1b;
    TPROJ_L3PHIC_nentries_V_din : in t_myarray2_8_8b;
    -- For VMStubME memories
    VMSME_L3PHIC17to24n1_dataarray_data_V_wea       : in t_myarray8_1b;
    VMSME_L3PHIC17to24n1_dataarray_data_V_writeaddr : in t_myarray8_9b;
-- todo: VMSME_L3PHIC17to24n1_dataarray_data_V_writeaddr --: t_myarray8_10b
    VMSME_L3PHIC17to24n1_dataarray_data_V_din       : in t_myarray8_14b;
    VMSME_L3PHIC17to24n1_nentries_V_we  : in t_myarray8_8_8_1b;
    VMSME_L3PHIC17to24n1_nentries_V_din : in t_myarray8_8_8_4b;
    -- For AllStubs memories
    AS_L3PHICn4_dataarray_data_V_wea       : in std_logic;
    AS_L3PHICn4_dataarray_data_V_writeaddr : in std_logic_vector(9 downto 0);
    AS_L3PHICn4_dataarray_data_V_din       : in std_logic_vector(35 downto 0);
    AS_L3PHICn4_nentries_V_we  : in t_myarray8_1b;
    AS_L3PHICn4_nentries_V_din : in t_myarray8_8b;
    -- FullMatches output
    FM_L1L2XX_L3PHIC_dataarray_data_V_enb      : in std_logic; 
    FM_L1L2XX_L3PHIC_dataarray_data_V_readaddr : in std_logic_vector(7 downto 0);
    FM_L1L2XX_L3PHIC_dataarray_data_V_dout     : out std_logic_vector(44 downto 0);
    FM_L1L2XX_L3PHIC_nentries_V_dout : out t_myarray2_8b;
    FM_L5L6XX_L3PHIC_dataarray_data_V_enb      : in std_logic;
    FM_L5L6XX_L3PHIC_dataarray_data_V_readaddr : in std_logic_vector(7 downto 0);
    FM_L5L6XX_L3PHIC_dataarray_data_V_dout     : out std_logic_vector(44 downto 0);
    FM_L5L6XX_L3PHIC_nentries_V_dout : out t_myarray2_8b;
    -- MatchCalculator outputs
    bx_out_MatchCalculator     : out std_logic_vector(2 downto 0);
    bx_out_MatchCalculator_vld : out std_logic;
    MatchCalculator_done       : out std_logic
    );

end top_tf;

architecture rtl of top_tf is 

-- KH implmenting clogb2 for addressing
function clogb2 (bit_depth : integer) return integer is
  variable depth : integer := bit_depth;
  variable count : integer := 1;
begin
  for clogb2 in 1 to bit_depth loop     -- Works for up to 32 bit integers
    if (bit_depth <= 2) then
      count := 1;
    else
      if(depth <= 1) then
        count := count;
      else
        depth := depth / 2;
        count := count + 1;
      end if;
    end if;
  end loop;
  return(count-1);
end;

COMPONENT myMemory
GENERIC (
  RAM_WIDTH       : integer := 18;                  -- Specify RAM data width
  RAM_DEPTH       : integer := 1024;                -- Specify RAM depth (number of entries)
  INIT_FILE       : string  := "";                  -- Specify name/location of RAM initialization file if using one (leave blank if not)
  RAM_PERFORMANCE : string  := "HIGH_PERFORMANCE";  -- Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
  HEX             : integer := 1 
  );
PORT (
  addra    : in std_logic_vector(clogb2(RAM_DEPTH) - 1 downto 0);  -- Write address bus, width determined from RAM_DEPTH
  addrb    : in std_logic_vector(clogb2(RAM_DEPTH) - 1 downto 0);  -- Read address bus, width determined from RAM_DEPTH
  dina     : in std_logic_vector(RAM_WIDTH - 1 downto 0);          -- RAM input data
  clka     : in std_logic;                                         -- Write clock
  clkb     : in std_logic;                                         -- Read clock
  wea      : in std_logic;                                         -- Write enable
  enb      : in std_logic;                                         -- Read Enable, for additional power savings, disable when not in use
  rstb     : in std_logic;                                         -- Output reset (does not affect memory contents)
  regceb   : in std_logic;                                         -- Output register enable
  nent_i0  : in std_logic_vector(7 downto 0);                      -- Num entries received
  nent_we0 : in std_logic;                                         -- Write enable
  nent_o0  : out std_logic_vector(7 downto 0);                     -- Num entries per page [4 bits each]
  nent_i1  : in std_logic_vector(7 downto 0);                      -- Num entries received
  nent_we1 : in std_logic;                                         -- Write enable
  nent_o1  : out std_logic_vector(7 downto 0);                     -- Num entries per page [4 bits each]
  nent_i2  : in std_logic_vector(7 downto 0);                      -- Num entries received
  nent_we2 : in std_logic;                                         -- Write enable
  nent_o2  : out std_logic_vector(7 downto 0);                     -- Num entries per page [4 bits each]
  nent_i3  : in std_logic_vector(7 downto 0);                      -- Num entries received
  nent_we3 : in std_logic;                                         -- Write enable
  nent_o3  : out std_logic_vector(7 downto 0);                     -- Num entries per page [4 bits each]
  nent_i4  : in std_logic_vector(7 downto 0);                      -- Num entries received
  nent_we4 : in std_logic;                                         -- Write enable
  nent_o4  : out std_logic_vector(7 downto 0);                     -- Num entries per page [4 bits each]
  nent_i5  : in std_logic_vector(7 downto 0);                      -- Num entries received
  nent_we5 : in std_logic;                                         -- Write enable
  nent_o5  : out std_logic_vector(7 downto 0);                     -- Num entries per page [4 bits each]
  nent_i6  : in std_logic_vector(7 downto 0);                      -- Num entries received
  nent_we6 : in std_logic;                                         -- Write enable
  nent_o6  : out std_logic_vector(7 downto 0);                     -- Num entries per page [4 bits each]
  nent_i7  : in std_logic_vector(7 downto 0);                      -- Num entries received
  nent_we7 : in std_logic;                                         -- Write enable
  nent_o7  : out std_logic_vector(7 downto 0);                     -- Num entries per page [4 bits each]
  doutb    : out std_logic_vector(RAM_WIDTH-1 downto 0)            -- RAM output data
  );
END COMPONENT;

COMPONENT myMemoryBinned
GENERIC (
  RAM_WIDTH       : integer := 14;                  -- Specify RAM data width, VM Stub: 14 for Barral LPS, 15 for Barral L2S/DISK
  RAM_DEPTH       : integer := 512;                 -- Specify RAM depth (number of entries) 512 is for 4 pages
  INIT_FILE       : string  := "";                  -- Specify name/location of RAM initialization file if using one (leave blank if not)
  RAM_PERFORMANCE : string  := "HIGH_PERFORMANCE";  -- Select "HIGH_PERFORMANCE" or "LOW_LATENCY"
  HEX             : integer := 1 
  );
PORT (
  addra      : in std_logic_vector(clogb2(RAM_DEPTH) - 1 downto 0);  -- Write address bus, width determined from RAM_DEPTH
  addrb      : in std_logic_vector(clogb2(RAM_DEPTH) - 1 downto 0);  -- Read address bus, width determined from RAM_DEPTH
  dina       : in std_logic_vector(RAM_WIDTH - 1 downto 0);          -- RAM input data
  clka       : in std_logic;                                         -- Write clock
  clkb       : in std_logic;                                         -- Read clock
  wea        : in std_logic;                                         -- Write enable
  enb        : in std_logic;                                         -- Read Enable, for additional power savings, disable when not in use
  rstb       : in std_logic;                                         -- Output reset (does not affect memory contents)
  regceb     : in std_logic;                                         -- Output register enable
  nent_0_i0  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_0_we0 : in std_logic;                                         -- Write enable
  nent_0_o0  : out std_logic_vector(3 downto 0);                     -- Num entries for page 0 [4 bits each]
  nent_0_i1  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_0_we1 : in std_logic;                                         -- Write enable
  nent_0_o1  : out std_logic_vector(3 downto 0);                     -- Num entries for page 0 [4 bits each]
  nent_0_i2  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_0_we2 : in std_logic;                                         -- Write enable
  nent_0_o2  : out std_logic_vector(3 downto 0);                     -- Num entries for page 0 [4 bits each]
  nent_0_i3  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_0_we3 : in std_logic;                                         -- Write enable
  nent_0_o3  : out std_logic_vector(3 downto 0);                     -- Num entries for page 0 [4 bits each]
  nent_0_i4  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_0_we4 : in std_logic;                                         -- Write enable
  nent_0_o4  : out std_logic_vector(3 downto 0);                     -- Num entries for page 0 [4 bits each]
  nent_0_i5  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_0_we5 : in std_logic;                                         -- Write enable
  nent_0_o5  : out std_logic_vector(3 downto 0);                     -- Num entries for page 0 [4 bits each]
  nent_0_i6  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_0_we6 : in std_logic;                                         -- Write enable
  nent_0_o6  : out std_logic_vector(3 downto 0);                     -- Num entries for page 0 [4 bits each]
  nent_0_i7  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_0_we7 : in std_logic;                                         -- Write enable
  nent_0_o7  : out std_logic_vector(3 downto 0);                     -- Num entries for page 0 [4 bits each]
  nent_1_i0  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_1_we0 : in std_logic;                                         -- Write enable
  nent_1_o0  : out std_logic_vector(3 downto 0);                     -- Num entries for page 1 [4 bits each]
  nent_1_i1  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_1_we1 : in std_logic;                                         -- Write enable
  nent_1_o1  : out std_logic_vector(3 downto 0);                     -- Num entries for page 1 [4 bits each]
  nent_1_i2  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_1_we2 : in std_logic;                                         -- Write enable
  nent_1_o2  : out std_logic_vector(3 downto 0);                     -- Num entries for page 1 [4 bits each]
  nent_1_i3  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_1_we3 : in std_logic;                                         -- Write enable
  nent_1_o3  : out std_logic_vector(3 downto 0);                     -- Num entries for page 1 [4 bits each]
  nent_1_i4  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_1_we4 : in std_logic;                                         -- Write enable
  nent_1_o4  : out std_logic_vector(3 downto 0);                     -- Num entries for page 1 [4 bits each]
  nent_1_i5  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_1_we5 : in std_logic;                                         -- Write enable
  nent_1_o5  : out std_logic_vector(3 downto 0);                     -- Num entries for page 1 [4 bits each]
  nent_1_i6  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_1_we6 : in std_logic;                                         -- Write enable
  nent_1_o6  : out std_logic_vector(3 downto 0);                     -- Num entries for page 1 [4 bits each]
  nent_1_i7  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_1_we7 : in std_logic;                                         -- Write enable
  nent_1_o7  : out std_logic_vector(3 downto 0);                     -- Num entries for page 1 [4 bits each]
  nent_2_i0  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_2_we0 : in std_logic;                                         -- Write enable
  nent_2_o0  : out std_logic_vector(3 downto 0);                     -- Num entries for page 2 [4 bits each]
  nent_2_i1  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_2_we1 : in std_logic;                                         -- Write enable
  nent_2_o1  : out std_logic_vector(3 downto 0);                     -- Num entries for page 2 [4 bits each]
  nent_2_i2  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_2_we2 : in std_logic;                                         -- Write enable
  nent_2_o2  : out std_logic_vector(3 downto 0);                     -- Num entries for page 2 [4 bits each]
  nent_2_i3  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_2_we3 : in std_logic;                                         -- Write enable
  nent_2_o3  : out std_logic_vector(3 downto 0);                     -- Num entries for page 2 [4 bits each]
  nent_2_i4  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_2_we4 : in std_logic;                                         -- Write enable
  nent_2_o4  : out std_logic_vector(3 downto 0);                     -- Num entries for page 2 [4 bits each]
  nent_2_i5  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_2_we5 : in std_logic;                                         -- Write enable
  nent_2_o5  : out std_logic_vector(3 downto 0);                     -- Num entries for page 2 [4 bits each]
  nent_2_i6  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_2_we6 : in std_logic;                                         -- Write enable
  nent_2_o6  : out std_logic_vector(3 downto 0);                     -- Num entries for page 2 [4 bits each]
  nent_2_i7  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_2_we7 : in std_logic;                                         -- Write enable
  nent_2_o7  : out std_logic_vector(3 downto 0);                     -- Num entries for page 2 [4 bits each]
  nent_3_i0  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_3_we0 : in std_logic;                                         -- Write enable
  nent_3_o0  : out std_logic_vector(3 downto 0);                     -- Num entries for page 3 [4 bits each]
  nent_3_i1  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_3_we1 : in std_logic;                                         -- Write enable
  nent_3_o1  : out std_logic_vector(3 downto 0);                     -- Num entries for page 3 [4 bits each]
  nent_3_i2  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_3_we2 : in std_logic;                                         -- Write enable
  nent_3_o2  : out std_logic_vector(3 downto 0);                     -- Num entries for page 3 [4 bits each]
  nent_3_i3  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_3_we3 : in std_logic;                                         -- Write enable
  nent_3_o3  : out std_logic_vector(3 downto 0);                     -- Num entries for page 3 [4 bits each]
  nent_3_i4  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_3_we4 : in std_logic;                                         -- Write enable
  nent_3_o4  : out std_logic_vector(3 downto 0);                     -- Num entries for page 3 [4 bits each]
  nent_3_i5  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_3_we5 : in std_logic;                                         -- Write enable
  nent_3_o5  : out std_logic_vector(3 downto 0);                     -- Num entries for page 3 [4 bits each]
  nent_3_i6  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_3_we6 : in std_logic;                                         -- Write enable
  nent_3_o6  : out std_logic_vector(3 downto 0);                     -- Num entries for page 3 [4 bits each]
  nent_3_i7  : in std_logic_vector(3 downto 0);                      -- Num entries received
  nent_3_we7 : in std_logic;                                         -- Write enable
  nent_3_o7  : out std_logic_vector(3 downto 0);                     -- Num entries for page 3 [4 bits each]
  doutb      : out std_logic_vector(RAM_WIDTH-1 downto 0)            -- RAM output data
  );
END COMPONENT;

  -- connecting TrackletProjections memories to ProjectionRouter input
  -- (0-7) -> (L1L2F-L1L2J, L5L6B-L5L6D)
  signal TPROJ_L3PHIC_dataarray_data_V_enb      : t_myarray8_1b;
  signal TPROJ_L3PHIC_dataarray_data_V_readaddr : t_myarray8_8b;
  signal TPROJ_L3PHIC_dataarray_data_V_dout     : t_myarray8_60b;
  signal TPROJ_L3PHIC_nentries_V_dout : t_myarray2_8_8b;
  
  -- ProjectionRouter signals
  signal ProjectionRouter_done       : std_logic := '0';
  signal bx_out_ProjectionRouter     : std_logic_vector(2 downto 0);
  signal bx_out_ProjectionRouter_vld : std_logic;
  
  -- connecting ProjectionRouter output to AllProjection memories
  signal AP_L3PHIC_dataarray_data_V_wea       : std_logic;
  signal AP_L3PHIC_dataarray_data_V_writeaddr : std_logic_vector(9 downto 0);
  signal AP_L3PHIC_dataarray_data_V_din       : std_logic_vector(59 downto 0);
  signal AP_L3PHIC_nentries_V_we  : t_myarray8_1b;
  signal AP_L3PHIC_nentries_V_din : t_myarray8_8b;
  
  -- connecting ProjectionRouter output to VMProjection memories
  signal VMPROJ_L3PHIC17to24_dataarray_data_V_wea       : t_myarray8_1b;
  signal VMPROJ_L3PHIC17to24_dataarray_data_V_writeaddr : t_myarray8_8b;
  signal VMPROJ_L3PHIC17to24_dataarray_data_V_din       : t_myarray8_21b;
  signal VMPROJ_L3PHIC17to24_nentries_V_we  : t_myarray2_8_1b;
  signal VMPROJ_L3PHIC17to24_nentries_V_din : t_myarray2_8_8b;
  
  -- connecting VMProjections memories to MatchEngine input
  signal VMPROJ_L3PHIC17to24_dataarray_data_V_enb      : t_myarray8_1b;
  signal VMPROJ_L3PHIC17to24_dataarray_data_V_readaddr : t_myarray8_8b;
  signal VMPROJ_L3PHIC17to24_dataarray_data_V_dout     : t_myarray8_21b;
  signal VMPROJ_L3PHIC17to24_nentries_V_dout : t_myarray2_8_8b;
  
  -- connecting VMStubME memories to MatchEngine input
  signal VMSME_L3PHIC17to24n1_dataarray_data_V_enb      : t_myarray8_1b;
  signal VMSME_L3PHIC17to24n1_dataarray_data_V_readaddr : t_myarray8_9b;
  signal VMSME_L3PHIC17to24n1_dataarray_data_V_dout     : t_myarray8_14b;
  signal VMSME_L3PHIC17to24n1_nentries_V_dout : t_myarray8_8_8_5b;
  
  -- Note: myMemoryBinned class allocates 4-bits for nentries in each bin, while
  -- MatchEngine ports are expecting 5-bits. Leaving the 5th bit unconnected seems
  -- to cause Vivado to trim away logic and messes up some LUT logic in the ME
  -- module. Assign 'dont_touch' attribute to the nentries signal to prevent this.
  attribute dont_touch : string;
  attribute dont_touch of VMSME_L3PHIC17to24n1_nentries_V_dout : signal is "true";
  
  -- MatchEngine signals
  signal MatchEngine_start : std_logic := '0';
  signal bx_out_MatchEngine     : t_myarray8_3b;
  signal bx_out_MatchEngine_vld : t_myarray8_1b;
  signal MatchEngine_done    : std_logic; 
  signal MatchEngine_Alldone : std_logic := '0';
  
  -- connecting MatchEngine output to CandidateMatches memories 
  signal CM_L3PHIC17to24_dataarray_data_V_wea       : t_myarray8_1b;
  signal CM_L3PHIC17to24_dataarray_data_V_writeaddr : t_myarray8_8b;
  signal CM_L3PHIC17to24_dataarray_data_V_din       : t_myarray8_14b;
  signal CM_L3PHIC17to24_nentries_V_we  : t_myarray2_8_1b;
  signal CM_L3PHIC17to24_nentries_V_din : t_myarray2_8_8b;
  
  -- connecting AllStubs memory to MatchCalculator input
  signal AS_L3PHICn4_dataarray_data_V_enb      : std_logic;
  signal AS_L3PHICn4_dataarray_data_V_readaddr : std_logic_vector(9 downto 0);
  signal AS_L3PHICn4_dataarray_data_V_dout     : std_logic_vector(35 downto 0);
  signal AS_L3PHICn4_nentries_V_dout : t_myarray8_8b;
  
  -- connecting AllProjections memory to MatchCalculator input
  signal AP_L3PHIC_dataarray_data_V_enb      : std_logic;
  signal AP_L3PHIC_dataarray_data_V_readaddr : std_logic_vector(9 downto 0);
  signal AP_L3PHIC_dataarray_data_V_dout     : std_logic_vector(59 downto 0);
  signal AP_L3PHIC_nentries_V_dout : t_myarray8_8b;
  
  -- connecting CandidateMatches memories to MatchCalculator input
  signal CM_L3PHIC17to24_dataarray_data_V_enb      : t_myarray8_1b;
  signal CM_L3PHIC17to24_dataarray_data_V_readaddr : t_myarray8_8b;
  signal CM_L3PHIC17to24_dataarray_data_V_dout     : t_myarray8_14b;
  signal CM_L3PHIC17to24_nentries_V_dout : t_myarray2_8_8b;

  -- MatchCalculator signals
  signal MatchCalculator_start : std_logic := '0';

  -- connecting MatchCalculator output to FullMatches memories
  signal FM_L1L2XX_L3PHIC_dataarray_data_V_wea       : std_logic; 
  signal FM_L1L2XX_L3PHIC_dataarray_data_V_writeaddr : std_logic_vector(7 downto 0);
  signal FM_L1L2XX_L3PHIC_dataarray_data_V_din       : std_logic_vector(44 downto 0);
  signal FM_L1L2XX_L3PHIC_nentries_V_we  : t_myarray2_1b;
  signal FM_L1L2XX_L3PHIC_nentries_V_din : t_myarray2_8b;
  signal FM_L5L6XX_L3PHIC_dataarray_data_V_wea       : std_logic;
  signal FM_L5L6XX_L3PHIC_dataarray_data_V_writeaddr : std_logic_vector(7 downto 0);
  signal FM_L5L6XX_L3PHIC_dataarray_data_V_din       : std_logic_vector(44 downto 0);
  signal FM_L5L6XX_L3PHIC_nentries_V_we  : t_myarray2_1b;
  signal FM_L5L6XX_L3PHIC_nentries_V_din : t_myarray2_8b;
    
begin

  process(ProjectionRouter_done)
  begin
    if ProjectionRouter_done = '1' then MatchEngine_start <= '1'; end if;
  end process;
  
  MatchEngine_Alldone <= MatchEngine_done;
  
  process(MatchEngine_Alldone)
  begin
    if MatchEngine_Alldone = '1' then MatchCalculator_start <= '1'; end if;
  end process;                       


  --------------------------------------------------------------
  -- TrackletProjection memories
  --------------------------------------------------------------
  gen_TPROJ_L3PHIC : for tpidx in 7 downto 0 generate
  begin
    TPROJ_L3PHIC : myMemory
      generic map (
        RAM_WIDTH       => 60,
        RAM_DEPTH       => 256,
        INIT_FILE       => "",
        RAM_PERFORMANCE => "HIGH_PERFORMANCE",
        HEX             => 1
        )
      port map (        
        clka     => clk,
        wea      => TPROJ_L3PHIC_dataarray_data_V_wea(tpidx),
        addra    => TPROJ_L3PHIC_dataarray_data_V_writeaddr(tpidx),
        dina     => TPROJ_L3PHIC_dataarray_data_V_din(tpidx),
        nent_we0 => TPROJ_L3PHIC_nentries_V_we(0)(tpidx),
        nent_i0  => TPROJ_L3PHIC_nentries_V_din(0)(tpidx),
        nent_we1 => TPROJ_L3PHIC_nentries_V_we(1)(tpidx),
        nent_i1  => TPROJ_L3PHIC_nentries_V_din(1)(tpidx),
        nent_we2 => '0',
        nent_i2  => (others=>'0'),
        nent_we3 => '0',
        nent_i3  => (others=>'0'),
        nent_we4 => '0',
        nent_i4  => (others=>'0'),
        nent_we5 => '0',
        nent_i5  => (others=>'0'),
        nent_we6 => '0',
        nent_i6  => (others=>'0'),
        nent_we7 => '0',
        nent_i7  => (others=>'0'),
        clkb     => clk,
        rstb     => '0',
        regceb   => '1',
        enb      => TPROJ_L3PHIC_dataarray_data_V_enb(tpidx),
        addrb    => TPROJ_L3PHIC_dataarray_data_V_readaddr(tpidx),
        doutb    => TPROJ_L3PHIC_dataarray_data_V_dout(tpidx),
        nent_o0  => TPROJ_L3PHIC_nentries_V_dout(0)(tpidx),
        nent_o1  => TPROJ_L3PHIC_nentries_V_dout(1)(tpidx),
        nent_o2  => open,
        nent_o3  => open,
        nent_o4  => open,
        nent_o5  => open,
        nent_o6  => open,
        nent_o7  => open
        );
        
  end generate gen_TPROJ_L3PHIC;

  
  --------------------------------------------------------------
  -- ProjectionRouter
  --------------------------------------------------------------
  PR_L3PHIC : entity work.PR_L3PHIC
    port map (  
      ap_clk   => clk,
      ap_rst   => reset,
      ap_start => en_proc,
      ap_done  => ProjectionRouter_done,
      ap_idle  => open,
      ap_ready => open,
      bx_V     => bx_in_ProjectionRouter,
      proj1in_dataarray_data_V_address0 => TPROJ_L3PHIC_dataarray_data_V_readaddr(0),
      proj1in_dataarray_data_V_ce0      => TPROJ_L3PHIC_dataarray_data_V_enb(0),
      proj1in_dataarray_data_V_q0       => TPROJ_L3PHIC_dataarray_data_V_dout(0),
      proj1in_nentries_0_V              => TPROJ_L3PHIC_nentries_V_dout(0)(0),
      proj1in_nentries_1_V              => TPROJ_L3PHIC_nentries_V_dout(1)(0),
      proj2in_dataarray_data_V_address0 => TPROJ_L3PHIC_dataarray_data_V_readaddr(1),
      proj2in_dataarray_data_V_ce0      => TPROJ_L3PHIC_dataarray_data_V_enb(1),
      proj2in_dataarray_data_V_q0       => TPROJ_L3PHIC_dataarray_data_V_dout(1),
      proj2in_nentries_0_V              => TPROJ_L3PHIC_nentries_V_dout(0)(1),
      proj2in_nentries_1_V              => TPROJ_L3PHIC_nentries_V_dout(1)(1),
      proj3in_dataarray_data_V_address0 => TPROJ_L3PHIC_dataarray_data_V_readaddr(2),
      proj3in_dataarray_data_V_ce0      => TPROJ_L3PHIC_dataarray_data_V_enb(2),
      proj3in_dataarray_data_V_q0       => TPROJ_L3PHIC_dataarray_data_V_dout(2),
      proj3in_nentries_0_V              => TPROJ_L3PHIC_nentries_V_dout(0)(2),
      proj3in_nentries_1_V              => TPROJ_L3PHIC_nentries_V_dout(1)(2),
      proj4in_dataarray_data_V_address0 => TPROJ_L3PHIC_dataarray_data_V_readaddr(3),
      proj4in_dataarray_data_V_ce0      => TPROJ_L3PHIC_dataarray_data_V_enb(3),
      proj4in_dataarray_data_V_q0       => TPROJ_L3PHIC_dataarray_data_V_dout(3),
      proj4in_nentries_0_V              => TPROJ_L3PHIC_nentries_V_dout(0)(3),
      proj4in_nentries_1_V              => TPROJ_L3PHIC_nentries_V_dout(1)(3),
      proj5in_dataarray_data_V_address0 => TPROJ_L3PHIC_dataarray_data_V_readaddr(4),
      proj5in_dataarray_data_V_ce0      => TPROJ_L3PHIC_dataarray_data_V_enb(4),
      proj5in_dataarray_data_V_q0       => TPROJ_L3PHIC_dataarray_data_V_dout(4),
      proj5in_nentries_0_V              => TPROJ_L3PHIC_nentries_V_dout(0)(4),
      proj5in_nentries_1_V              => TPROJ_L3PHIC_nentries_V_dout(1)(4),
      proj6in_dataarray_data_V_address0 => TPROJ_L3PHIC_dataarray_data_V_readaddr(5),
      proj6in_dataarray_data_V_ce0      => TPROJ_L3PHIC_dataarray_data_V_enb(5),
      proj6in_dataarray_data_V_q0       => TPROJ_L3PHIC_dataarray_data_V_dout(5),
      proj6in_nentries_0_V              => TPROJ_L3PHIC_nentries_V_dout(0)(5),
      proj6in_nentries_1_V              => TPROJ_L3PHIC_nentries_V_dout(1)(5),
      proj7in_dataarray_data_V_address0 => TPROJ_L3PHIC_dataarray_data_V_readaddr(6),
      proj7in_dataarray_data_V_ce0      => TPROJ_L3PHIC_dataarray_data_V_enb(6),
      proj7in_dataarray_data_V_q0       => TPROJ_L3PHIC_dataarray_data_V_dout(6),
      proj7in_nentries_0_V              => TPROJ_L3PHIC_nentries_V_dout(0)(6),
      proj7in_nentries_1_V              => TPROJ_L3PHIC_nentries_V_dout(1)(6),
      proj8in_dataarray_data_V_address0 => TPROJ_L3PHIC_dataarray_data_V_readaddr(7),
      proj8in_dataarray_data_V_ce0      => TPROJ_L3PHIC_dataarray_data_V_enb(7),
      proj8in_dataarray_data_V_q0       => TPROJ_L3PHIC_dataarray_data_V_dout(7),
      proj8in_nentries_0_V              => TPROJ_L3PHIC_nentries_V_dout(0)(7),
      proj8in_nentries_1_V              => TPROJ_L3PHIC_nentries_V_dout(1)(7),
      bx_o_V        => bx_out_ProjectionRouter,
      bx_o_V_ap_vld => bx_out_ProjectionRouter_vld,
      allprojout_dataarray_data_V_address0 => AP_L3PHIC_dataarray_data_V_writeaddr,
      allprojout_dataarray_data_V_ce0      => open,
      allprojout_dataarray_data_V_we0      => AP_L3PHIC_dataarray_data_V_wea,
      allprojout_dataarray_data_V_d0       => AP_L3PHIC_dataarray_data_V_din,
      allprojout_nentries_0_V        => AP_L3PHIC_nentries_V_din(0),
      allprojout_nentries_0_V_ap_vld =>  AP_L3PHIC_nentries_V_we(0),
      allprojout_nentries_1_V        => AP_L3PHIC_nentries_V_din(1),
      allprojout_nentries_1_V_ap_vld =>  AP_L3PHIC_nentries_V_we(1),
      allprojout_nentries_2_V        => AP_L3PHIC_nentries_V_din(2),
      allprojout_nentries_2_V_ap_vld =>  AP_L3PHIC_nentries_V_we(2),
      allprojout_nentries_3_V        => AP_L3PHIC_nentries_V_din(3),
      allprojout_nentries_3_V_ap_vld =>  AP_L3PHIC_nentries_V_we(3),
      allprojout_nentries_4_V        => AP_L3PHIC_nentries_V_din(4),
      allprojout_nentries_4_V_ap_vld =>  AP_L3PHIC_nentries_V_we(4),
      allprojout_nentries_5_V        => AP_L3PHIC_nentries_V_din(5),
      allprojout_nentries_5_V_ap_vld =>  AP_L3PHIC_nentries_V_we(5),
      allprojout_nentries_6_V        => AP_L3PHIC_nentries_V_din(6),
      allprojout_nentries_6_V_ap_vld =>  AP_L3PHIC_nentries_V_we(6),
      allprojout_nentries_7_V        => AP_L3PHIC_nentries_V_din(7),
      allprojout_nentries_7_V_ap_vld =>  AP_L3PHIC_nentries_V_we(7),
      vmprojout1_dataarray_data_V_address0 => VMPROJ_L3PHIC17to24_dataarray_data_V_writeaddr(0),
      vmprojout1_dataarray_data_V_ce0      => open,
      vmprojout1_dataarray_data_V_we0      => VMPROJ_L3PHIC17to24_dataarray_data_V_wea(0),
      vmprojout1_dataarray_data_V_d0       => VMPROJ_L3PHIC17to24_dataarray_data_V_din(0),
      vmprojout1_nentries_0_V              => VMPROJ_L3PHIC17to24_nentries_V_din(0)(0),
      vmprojout1_nentries_0_V_ap_vld       =>  VMPROJ_L3PHIC17to24_nentries_V_we(0)(0),
      vmprojout1_nentries_1_V              => VMPROJ_L3PHIC17to24_nentries_V_din(1)(0),
      vmprojout1_nentries_1_V_ap_vld       =>  VMPROJ_L3PHIC17to24_nentries_V_we(1)(0),
      vmprojout2_dataarray_data_V_address0 => VMPROJ_L3PHIC17to24_dataarray_data_V_writeaddr(1),
      vmprojout2_dataarray_data_V_ce0      => open,
      vmprojout2_dataarray_data_V_we0      => VMPROJ_L3PHIC17to24_dataarray_data_V_wea(1),
      vmprojout2_dataarray_data_V_d0       => VMPROJ_L3PHIC17to24_dataarray_data_V_din(1),
      vmprojout2_nentries_0_V              => VMPROJ_L3PHIC17to24_nentries_V_din(0)(1),
      vmprojout2_nentries_0_V_ap_vld       =>  VMPROJ_L3PHIC17to24_nentries_V_we(0)(1),
      vmprojout2_nentries_1_V              => VMPROJ_L3PHIC17to24_nentries_V_din(1)(1),
      vmprojout2_nentries_1_V_ap_vld       =>  VMPROJ_L3PHIC17to24_nentries_V_we(1)(1),
      vmprojout3_dataarray_data_V_address0 => VMPROJ_L3PHIC17to24_dataarray_data_V_writeaddr(2),
      vmprojout3_dataarray_data_V_ce0      => open,
      vmprojout3_dataarray_data_V_we0      => VMPROJ_L3PHIC17to24_dataarray_data_V_wea(2),
      vmprojout3_dataarray_data_V_d0       => VMPROJ_L3PHIC17to24_dataarray_data_V_din(2),
      vmprojout3_nentries_0_V              => VMPROJ_L3PHIC17to24_nentries_V_din(0)(2),
      vmprojout3_nentries_0_V_ap_vld       =>  VMPROJ_L3PHIC17to24_nentries_V_we(0)(2),
      vmprojout3_nentries_1_V              => VMPROJ_L3PHIC17to24_nentries_V_din(1)(2),
      vmprojout3_nentries_1_V_ap_vld       =>  VMPROJ_L3PHIC17to24_nentries_V_we(1)(2),
      vmprojout4_dataarray_data_V_address0 => VMPROJ_L3PHIC17to24_dataarray_data_V_writeaddr(3),
      vmprojout4_dataarray_data_V_ce0      => open,
      vmprojout4_dataarray_data_V_we0      => VMPROJ_L3PHIC17to24_dataarray_data_V_wea(3),
      vmprojout4_dataarray_data_V_d0       => VMPROJ_L3PHIC17to24_dataarray_data_V_din(3),
      vmprojout4_nentries_0_V              => VMPROJ_L3PHIC17to24_nentries_V_din(0)(3),
      vmprojout4_nentries_0_V_ap_vld       =>  VMPROJ_L3PHIC17to24_nentries_V_we(0)(3),
      vmprojout4_nentries_1_V              => VMPROJ_L3PHIC17to24_nentries_V_din(1)(3),
      vmprojout4_nentries_1_V_ap_vld       =>  VMPROJ_L3PHIC17to24_nentries_V_we(1)(3),
      vmprojout5_dataarray_data_V_address0 => VMPROJ_L3PHIC17to24_dataarray_data_V_writeaddr(4),
      vmprojout5_dataarray_data_V_ce0      => open,
      vmprojout5_dataarray_data_V_we0      => VMPROJ_L3PHIC17to24_dataarray_data_V_wea(4),
      vmprojout5_dataarray_data_V_d0       => VMPROJ_L3PHIC17to24_dataarray_data_V_din(4),
      vmprojout5_nentries_0_V              => VMPROJ_L3PHIC17to24_nentries_V_din(0)(4),
      vmprojout5_nentries_0_V_ap_vld       =>  VMPROJ_L3PHIC17to24_nentries_V_we(0)(4),
      vmprojout5_nentries_1_V              => VMPROJ_L3PHIC17to24_nentries_V_din(1)(4),
      vmprojout5_nentries_1_V_ap_vld       =>  VMPROJ_L3PHIC17to24_nentries_V_we(1)(4),
      vmprojout6_dataarray_data_V_address0 => VMPROJ_L3PHIC17to24_dataarray_data_V_writeaddr(5),
      vmprojout6_dataarray_data_V_ce0      => open,
      vmprojout6_dataarray_data_V_we0      => VMPROJ_L3PHIC17to24_dataarray_data_V_wea(5),
      vmprojout6_dataarray_data_V_d0       => VMPROJ_L3PHIC17to24_dataarray_data_V_din(5),
      vmprojout6_nentries_0_V              => VMPROJ_L3PHIC17to24_nentries_V_din(0)(5),
      vmprojout6_nentries_0_V_ap_vld       =>  VMPROJ_L3PHIC17to24_nentries_V_we(0)(5),
      vmprojout6_nentries_1_V              => VMPROJ_L3PHIC17to24_nentries_V_din(1)(5),
      vmprojout6_nentries_1_V_ap_vld       =>  VMPROJ_L3PHIC17to24_nentries_V_we(1)(5),
      vmprojout7_dataarray_data_V_address0 => VMPROJ_L3PHIC17to24_dataarray_data_V_writeaddr(6),
      vmprojout7_dataarray_data_V_ce0      => open,
      vmprojout7_dataarray_data_V_we0      => VMPROJ_L3PHIC17to24_dataarray_data_V_wea(6),
      vmprojout7_dataarray_data_V_d0       => VMPROJ_L3PHIC17to24_dataarray_data_V_din(6),
      vmprojout7_nentries_0_V              => VMPROJ_L3PHIC17to24_nentries_V_din(0)(6),
      vmprojout7_nentries_0_V_ap_vld       =>  VMPROJ_L3PHIC17to24_nentries_V_we(0)(6),
      vmprojout7_nentries_1_V              => VMPROJ_L3PHIC17to24_nentries_V_din(1)(6),
      vmprojout7_nentries_1_V_ap_vld       =>  VMPROJ_L3PHIC17to24_nentries_V_we(1)(6),
      vmprojout8_dataarray_data_V_address0 => VMPROJ_L3PHIC17to24_dataarray_data_V_writeaddr(7),
      vmprojout8_dataarray_data_V_ce0      => open,
      vmprojout8_dataarray_data_V_we0      => VMPROJ_L3PHIC17to24_dataarray_data_V_wea(7),
      vmprojout8_dataarray_data_V_d0       => VMPROJ_L3PHIC17to24_dataarray_data_V_din(7),
      vmprojout8_nentries_0_V              => VMPROJ_L3PHIC17to24_nentries_V_din(0)(7),
      vmprojout8_nentries_0_V_ap_vld       =>  VMPROJ_L3PHIC17to24_nentries_V_we(0)(7),
      vmprojout8_nentries_1_V              => VMPROJ_L3PHIC17to24_nentries_V_din(1)(7),
      vmprojout8_nentries_1_V_ap_vld       =>  VMPROJ_L3PHIC17to24_nentries_V_we(1)(7)
      );


  --------------------------------------------------------------
  -- AllProjection memory
  --------------------------------------------------------------
  AP_L3PHIC : myMemory
    generic map (
      RAM_WIDTH       => 60,
      RAM_DEPTH       => 1024,
      INIT_FILE       => "",
      RAM_PERFORMANCE => "HIGH_PERFORMANCE",
      HEX             => 1       
      )
    port map (        
      clka     => clk,
      wea      => AP_L3PHIC_dataarray_data_V_wea,
      addra    => AP_L3PHIC_dataarray_data_V_writeaddr,
      dina     => AP_L3PHIC_dataarray_data_V_din,
      nent_we0 =>  AP_L3PHIC_nentries_V_we(0),
      nent_i0  => AP_L3PHIC_nentries_V_din(0),
      nent_we1 =>  AP_L3PHIC_nentries_V_we(1),
      nent_i1  => AP_L3PHIC_nentries_V_din(1),
      nent_we2 =>  AP_L3PHIC_nentries_V_we(2),
      nent_i2  => AP_L3PHIC_nentries_V_din(2),
      nent_we3 =>  AP_L3PHIC_nentries_V_we(3),
      nent_i3  => AP_L3PHIC_nentries_V_din(3),
      nent_we4 =>  AP_L3PHIC_nentries_V_we(4),
      nent_i4  => AP_L3PHIC_nentries_V_din(4),
      nent_we5 =>  AP_L3PHIC_nentries_V_we(5),
      nent_i5  => AP_L3PHIC_nentries_V_din(5),
      nent_we6 =>  AP_L3PHIC_nentries_V_we(6),
      nent_i6  => AP_L3PHIC_nentries_V_din(6),
      nent_we7 =>  AP_L3PHIC_nentries_V_we(7),
      nent_i7  => AP_L3PHIC_nentries_V_din(7),
      clkb     => clk,
      rstb     => '0',
      regceb   => '1',
      enb      => AP_L3PHIC_dataarray_data_V_enb,
      addrb    => AP_L3PHIC_dataarray_data_V_readaddr,
      doutb    => AP_L3PHIC_dataarray_data_V_dout,
      nent_o0  => AP_L3PHIC_nentries_V_dout(0),
      nent_o1  => AP_L3PHIC_nentries_V_dout(1),
      nent_o2  => AP_L3PHIC_nentries_V_dout(2),
      nent_o3  => AP_L3PHIC_nentries_V_dout(3),
      nent_o4  => AP_L3PHIC_nentries_V_dout(4),
      nent_o5  => AP_L3PHIC_nentries_V_dout(5),
      nent_o6  => AP_L3PHIC_nentries_V_dout(6),
      nent_o7  => AP_L3PHIC_nentries_V_dout(7)
      );

  
  --------------------------------------------------------------
  -- VMProjection memories
  --------------------------------------------------------------
  gen_VMPROJ_L3PHIC17to24 : for vmpidx in 7 downto 0 generate
  begin
    VMPROJ_L3PHIC17to24 : myMemory
      generic map (
        RAM_WIDTH       => 21,
        RAM_DEPTH       => 256,
        INIT_FILE       => "",
        RAM_PERFORMANCE => "LOW_LATENCY",
        HEX             => 0       
        )
      port map (        
        clka     => clk,
        wea      => VMPROJ_L3PHIC17to24_dataarray_data_V_wea(vmpidx),
        addra    => VMPROJ_L3PHIC17to24_dataarray_data_V_writeaddr(vmpidx),
        dina     => VMPROJ_L3PHIC17to24_dataarray_data_V_din(vmpidx),
        nent_we0 =>  VMPROJ_L3PHIC17to24_nentries_V_we(0)(vmpidx),
        nent_i0  => VMPROJ_L3PHIC17to24_nentries_V_din(0)(vmpidx),
        nent_we1 =>  VMPROJ_L3PHIC17to24_nentries_V_we(1)(vmpidx),
        nent_i1  => VMPROJ_L3PHIC17to24_nentries_V_din(1)(vmpidx),
        nent_we2 => '0',
        nent_i2  => (others=>'0'),
        nent_we3 => '0',
        nent_i3  => (others=>'0'),
        nent_we4 => '0',
        nent_i4  => (others=>'0'),
        nent_we5 => '0',
        nent_i5  => (others=>'0'),
        nent_we6 => '0',
        nent_i6  => (others=>'0'),
        nent_we7 => '0',
        nent_i7  => (others=>'0'),
        clkb     => clk,
        rstb     => '0',
        regceb   => '1',
        enb      => VMPROJ_L3PHIC17to24_dataarray_data_V_enb(vmpidx),
        addrb    => VMPROJ_L3PHIC17to24_dataarray_data_V_readaddr(vmpidx),  
        doutb    => VMPROJ_L3PHIC17to24_dataarray_data_V_dout(vmpidx),
        nent_o0  => VMPROJ_L3PHIC17to24_nentries_V_dout(0)(vmpidx),
        nent_o1  => VMPROJ_L3PHIC17to24_nentries_V_dout(1)(vmpidx),
        nent_o2  => open,
        nent_o3  => open,
        nent_o4  => open,
        nent_o5  => open,
        nent_o6  => open,
        nent_o7  => open
        );
        
  end generate gen_VMPROJ_L3PHIC17to24;


  --------------------------------------------------------------
  -- VMStubME memories
  --------------------------------------------------------------
  gen_VMSME_L3PHIC17to24n1 : for vmsidx in 7 downto 0 generate
  begin
    VMSME_L3PHIC17to24n1 : myMemoryBinned
      generic map (
        RAM_WIDTH       => 14,
        RAM_DEPTH       => 512,
        INIT_FILE       => "",
        RAM_PERFORMANCE => "LOW_LATENCY",
        HEX             => 0       
        )
      port map (        
        clka       => clk,
        wea        => VMSME_L3PHIC17to24n1_dataarray_data_V_wea(vmsidx),
        addra      => VMSME_L3PHIC17to24n1_dataarray_data_V_writeaddr(vmsidx),
        dina       => VMSME_L3PHIC17to24n1_dataarray_data_V_din(vmsidx),
        nent_0_we0 =>  VMSME_L3PHIC17to24n1_nentries_V_we(0)(0)(vmsidx),
        nent_0_i0  => VMSME_L3PHIC17to24n1_nentries_V_din(0)(0)(vmsidx),
        nent_0_we1 =>  VMSME_L3PHIC17to24n1_nentries_V_we(0)(1)(vmsidx),
        nent_0_i1  => VMSME_L3PHIC17to24n1_nentries_V_din(0)(1)(vmsidx),
        nent_0_we2 =>  VMSME_L3PHIC17to24n1_nentries_V_we(0)(2)(vmsidx),
        nent_0_i2  => VMSME_L3PHIC17to24n1_nentries_V_din(0)(2)(vmsidx),
        nent_0_we3 =>  VMSME_L3PHIC17to24n1_nentries_V_we(0)(3)(vmsidx),
        nent_0_i3  => VMSME_L3PHIC17to24n1_nentries_V_din(0)(3)(vmsidx),
        nent_0_we4 =>  VMSME_L3PHIC17to24n1_nentries_V_we(0)(4)(vmsidx),
        nent_0_i4  => VMSME_L3PHIC17to24n1_nentries_V_din(0)(4)(vmsidx),
        nent_0_we5 =>  VMSME_L3PHIC17to24n1_nentries_V_we(0)(5)(vmsidx),
        nent_0_i5  => VMSME_L3PHIC17to24n1_nentries_V_din(0)(5)(vmsidx),
        nent_0_we6 =>  VMSME_L3PHIC17to24n1_nentries_V_we(0)(6)(vmsidx),
        nent_0_i6  => VMSME_L3PHIC17to24n1_nentries_V_din(0)(6)(vmsidx),
        nent_0_we7 =>  VMSME_L3PHIC17to24n1_nentries_V_we(0)(7)(vmsidx),
        nent_0_i7  => VMSME_L3PHIC17to24n1_nentries_V_din(0)(7)(vmsidx),
        nent_1_we0 =>  VMSME_L3PHIC17to24n1_nentries_V_we(1)(0)(vmsidx),
        nent_1_i0  => VMSME_L3PHIC17to24n1_nentries_V_din(1)(0)(vmsidx),
        nent_1_we1 =>  VMSME_L3PHIC17to24n1_nentries_V_we(1)(1)(vmsidx),
        nent_1_i1  => VMSME_L3PHIC17to24n1_nentries_V_din(1)(1)(vmsidx),
        nent_1_we2 =>  VMSME_L3PHIC17to24n1_nentries_V_we(1)(2)(vmsidx),
        nent_1_i2  => VMSME_L3PHIC17to24n1_nentries_V_din(1)(2)(vmsidx),
        nent_1_we3 =>  VMSME_L3PHIC17to24n1_nentries_V_we(1)(3)(vmsidx),
        nent_1_i3  => VMSME_L3PHIC17to24n1_nentries_V_din(1)(3)(vmsidx),
        nent_1_we4 =>  VMSME_L3PHIC17to24n1_nentries_V_we(1)(4)(vmsidx),
        nent_1_i4  => VMSME_L3PHIC17to24n1_nentries_V_din(1)(4)(vmsidx),
        nent_1_we5 =>  VMSME_L3PHIC17to24n1_nentries_V_we(1)(5)(vmsidx),
        nent_1_i5  => VMSME_L3PHIC17to24n1_nentries_V_din(1)(5)(vmsidx),
        nent_1_we6 =>  VMSME_L3PHIC17to24n1_nentries_V_we(1)(6)(vmsidx),
        nent_1_i6  => VMSME_L3PHIC17to24n1_nentries_V_din(1)(6)(vmsidx),
        nent_1_we7 =>  VMSME_L3PHIC17to24n1_nentries_V_we(1)(7)(vmsidx),
        nent_1_i7  => VMSME_L3PHIC17to24n1_nentries_V_din(1)(7)(vmsidx),
        nent_2_we0 =>  VMSME_L3PHIC17to24n1_nentries_V_we(2)(0)(vmsidx),
        nent_2_i0  => VMSME_L3PHIC17to24n1_nentries_V_din(2)(0)(vmsidx),
        nent_2_we1 =>  VMSME_L3PHIC17to24n1_nentries_V_we(2)(1)(vmsidx),
        nent_2_i1  => VMSME_L3PHIC17to24n1_nentries_V_din(2)(1)(vmsidx),
        nent_2_we2 =>  VMSME_L3PHIC17to24n1_nentries_V_we(2)(2)(vmsidx),
        nent_2_i2  => VMSME_L3PHIC17to24n1_nentries_V_din(2)(2)(vmsidx),
        nent_2_we3 =>  VMSME_L3PHIC17to24n1_nentries_V_we(2)(3)(vmsidx),
        nent_2_i3  => VMSME_L3PHIC17to24n1_nentries_V_din(2)(3)(vmsidx),
        nent_2_we4 =>  VMSME_L3PHIC17to24n1_nentries_V_we(2)(4)(vmsidx),
        nent_2_i4  => VMSME_L3PHIC17to24n1_nentries_V_din(2)(4)(vmsidx),
        nent_2_we5 =>  VMSME_L3PHIC17to24n1_nentries_V_we(2)(5)(vmsidx),
        nent_2_i5  => VMSME_L3PHIC17to24n1_nentries_V_din(2)(5)(vmsidx),
        nent_2_we6 =>  VMSME_L3PHIC17to24n1_nentries_V_we(2)(6)(vmsidx),
        nent_2_i6  => VMSME_L3PHIC17to24n1_nentries_V_din(2)(6)(vmsidx),
        nent_2_we7 =>  VMSME_L3PHIC17to24n1_nentries_V_we(2)(7)(vmsidx),
        nent_2_i7  => VMSME_L3PHIC17to24n1_nentries_V_din(2)(7)(vmsidx),
        nent_3_we0 =>  VMSME_L3PHIC17to24n1_nentries_V_we(3)(0)(vmsidx),
        nent_3_i0  => VMSME_L3PHIC17to24n1_nentries_V_din(3)(0)(vmsidx),
        nent_3_we1 =>  VMSME_L3PHIC17to24n1_nentries_V_we(3)(1)(vmsidx),
        nent_3_i1  => VMSME_L3PHIC17to24n1_nentries_V_din(3)(1)(vmsidx),
        nent_3_we2 =>  VMSME_L3PHIC17to24n1_nentries_V_we(3)(2)(vmsidx),
        nent_3_i2  => VMSME_L3PHIC17to24n1_nentries_V_din(3)(2)(vmsidx),
        nent_3_we3 =>  VMSME_L3PHIC17to24n1_nentries_V_we(3)(3)(vmsidx),
        nent_3_i3  => VMSME_L3PHIC17to24n1_nentries_V_din(3)(3)(vmsidx),
        nent_3_we4 =>  VMSME_L3PHIC17to24n1_nentries_V_we(3)(4)(vmsidx),
        nent_3_i4  => VMSME_L3PHIC17to24n1_nentries_V_din(3)(4)(vmsidx),
        nent_3_we5 =>  VMSME_L3PHIC17to24n1_nentries_V_we(3)(5)(vmsidx),
        nent_3_i5  => VMSME_L3PHIC17to24n1_nentries_V_din(3)(5)(vmsidx),
        nent_3_we6 =>  VMSME_L3PHIC17to24n1_nentries_V_we(3)(6)(vmsidx),
        nent_3_i6  => VMSME_L3PHIC17to24n1_nentries_V_din(3)(6)(vmsidx),
        nent_3_we7 =>  VMSME_L3PHIC17to24n1_nentries_V_we(3)(7)(vmsidx),
        nent_3_i7  => VMSME_L3PHIC17to24n1_nentries_V_din(3)(7)(vmsidx),
        clkb       => clk,
        rstb       => '0',
        regceb     => '1',
        enb        => VMSME_L3PHIC17to24n1_dataarray_data_V_enb(vmsidx),
        addrb      => VMSME_L3PHIC17to24n1_dataarray_data_V_readaddr(vmsidx),
        doutb      => VMSME_L3PHIC17to24n1_dataarray_data_V_dout(vmsidx),
        nent_0_o0  => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(0)(vmsidx)(3 downto 0),
        nent_0_o1  => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(1)(vmsidx)(3 downto 0),
        nent_0_o2  => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(2)(vmsidx)(3 downto 0),
        nent_0_o3  => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(3)(vmsidx)(3 downto 0),
        nent_0_o4  => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(4)(vmsidx)(3 downto 0),
        nent_0_o5  => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(5)(vmsidx)(3 downto 0),
        nent_0_o6  => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(6)(vmsidx)(3 downto 0),
        nent_0_o7  => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(7)(vmsidx)(3 downto 0),
        nent_1_o0  => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(0)(vmsidx)(3 downto 0),
        nent_1_o1  => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(1)(vmsidx)(3 downto 0),
        nent_1_o2  => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(2)(vmsidx)(3 downto 0),
        nent_1_o3  => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(3)(vmsidx)(3 downto 0),
        nent_1_o4  => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(4)(vmsidx)(3 downto 0),
        nent_1_o5  => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(5)(vmsidx)(3 downto 0),
        nent_1_o6  => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(6)(vmsidx)(3 downto 0),
        nent_1_o7  => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(7)(vmsidx)(3 downto 0),
        nent_2_o0  => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(0)(vmsidx)(3 downto 0),
        nent_2_o1  => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(1)(vmsidx)(3 downto 0),
        nent_2_o2  => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(2)(vmsidx)(3 downto 0),
        nent_2_o3  => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(3)(vmsidx)(3 downto 0),
        nent_2_o4  => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(4)(vmsidx)(3 downto 0),
        nent_2_o5  => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(5)(vmsidx)(3 downto 0),
        nent_2_o6  => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(6)(vmsidx)(3 downto 0),
        nent_2_o7  => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(7)(vmsidx)(3 downto 0),
        nent_3_o0  => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(0)(vmsidx)(3 downto 0),
        nent_3_o1  => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(1)(vmsidx)(3 downto 0),
        nent_3_o2  => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(2)(vmsidx)(3 downto 0),
        nent_3_o3  => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(3)(vmsidx)(3 downto 0),
        nent_3_o4  => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(4)(vmsidx)(3 downto 0),
        nent_3_o5  => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(5)(vmsidx)(3 downto 0),
        nent_3_o6  => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(6)(vmsidx)(3 downto 0),
        nent_3_o7  => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(7)(vmsidx)(3 downto 0)
        );

  end generate gen_VMSME_L3PHIC17to24n1;
 

  --------------------------------------------------------------
  -- MatchEngine
  --------------------------------------------------------------
  me_i : entity work.SuperMatchEngineTop
      port map (
        ap_clk   => clk,
        ap_rst   => reset,
        ap_start => MatchEngine_start,
        ap_done  => MatchEngine_done,
        ap_idle  => open,
        ap_ready => open,
        bxset_0_V => bx_out_ProjectionRouter,
        bxset_1_V => bx_out_ProjectionRouter,
        bxset_2_V => bx_out_ProjectionRouter,
        bxset_3_V => bx_out_ProjectionRouter,
        bxset_4_V => bx_out_ProjectionRouter,
        bxset_5_V => bx_out_ProjectionRouter,
        bxset_6_V => bx_out_ProjectionRouter,
        bxset_7_V => bx_out_ProjectionRouter,
        bx_oset_0_V        =>     bx_out_MatchEngine(0),
        bx_oset_0_V_ap_vld => bx_out_MatchEngine_vld(0),
        bx_oset_1_V        =>     bx_out_MatchEngine(1),
        bx_oset_1_V_ap_vld => bx_out_MatchEngine_vld(1),
        bx_oset_2_V        =>     bx_out_MatchEngine(2),
        bx_oset_2_V_ap_vld => bx_out_MatchEngine_vld(2),
        bx_oset_3_V        =>     bx_out_MatchEngine(3),
        bx_oset_3_V_ap_vld => bx_out_MatchEngine_vld(3),
        bx_oset_4_V        =>     bx_out_MatchEngine(4),
        bx_oset_4_V_ap_vld => bx_out_MatchEngine_vld(4),
        bx_oset_5_V        =>     bx_out_MatchEngine(5),
        bx_oset_5_V_ap_vld => bx_out_MatchEngine_vld(5),
        bx_oset_6_V        =>     bx_out_MatchEngine(6),
        bx_oset_6_V_ap_vld => bx_out_MatchEngine_vld(6),
        bx_oset_7_V        =>     bx_out_MatchEngine(7),
        bx_oset_7_V_ap_vld => bx_out_MatchEngine_vld(7),
        inputStubDataset_0_dataarray_data_V_address0 => VMSME_L3PHIC17to24n1_dataarray_data_V_readaddr(0),
        inputStubDataset_0_dataarray_data_V_ce0      =>      VMSME_L3PHIC17to24n1_dataarray_data_V_enb(0),
        inputStubDataset_0_dataarray_data_V_q0       =>     VMSME_L3PHIC17to24n1_dataarray_data_V_dout(0)(12 downto 0),
        inputStubDataset_1_dataarray_data_V_address0 => VMSME_L3PHIC17to24n1_dataarray_data_V_readaddr(1),
        inputStubDataset_1_dataarray_data_V_ce0      =>      VMSME_L3PHIC17to24n1_dataarray_data_V_enb(1),
        inputStubDataset_1_dataarray_data_V_q0       =>     VMSME_L3PHIC17to24n1_dataarray_data_V_dout(1)(12 downto 0),
        inputStubDataset_2_dataarray_data_V_address0 => VMSME_L3PHIC17to24n1_dataarray_data_V_readaddr(2),
        inputStubDataset_2_dataarray_data_V_ce0      =>      VMSME_L3PHIC17to24n1_dataarray_data_V_enb(2),
        inputStubDataset_2_dataarray_data_V_q0       =>     VMSME_L3PHIC17to24n1_dataarray_data_V_dout(2)(12 downto 0),
        inputStubDataset_3_dataarray_data_V_address0 => VMSME_L3PHIC17to24n1_dataarray_data_V_readaddr(3),
        inputStubDataset_3_dataarray_data_V_ce0      =>      VMSME_L3PHIC17to24n1_dataarray_data_V_enb(3),
        inputStubDataset_3_dataarray_data_V_q0       =>     VMSME_L3PHIC17to24n1_dataarray_data_V_dout(3)(12 downto 0),
        inputStubDataset_4_dataarray_data_V_address0 => VMSME_L3PHIC17to24n1_dataarray_data_V_readaddr(4),
        inputStubDataset_4_dataarray_data_V_ce0      =>      VMSME_L3PHIC17to24n1_dataarray_data_V_enb(4),
        inputStubDataset_4_dataarray_data_V_q0       =>     VMSME_L3PHIC17to24n1_dataarray_data_V_dout(4)(12 downto 0),
        inputStubDataset_5_dataarray_data_V_address0 => VMSME_L3PHIC17to24n1_dataarray_data_V_readaddr(5),
        inputStubDataset_5_dataarray_data_V_ce0      =>      VMSME_L3PHIC17to24n1_dataarray_data_V_enb(5),
        inputStubDataset_5_dataarray_data_V_q0       =>     VMSME_L3PHIC17to24n1_dataarray_data_V_dout(5)(12 downto 0),
        inputStubDataset_6_dataarray_data_V_address0 => VMSME_L3PHIC17to24n1_dataarray_data_V_readaddr(6),
        inputStubDataset_6_dataarray_data_V_ce0      =>      VMSME_L3PHIC17to24n1_dataarray_data_V_enb(6),
        inputStubDataset_6_dataarray_data_V_q0       =>     VMSME_L3PHIC17to24n1_dataarray_data_V_dout(6)(12 downto 0),
        inputStubDataset_7_dataarray_data_V_address0 => VMSME_L3PHIC17to24n1_dataarray_data_V_readaddr(7),
        inputStubDataset_7_dataarray_data_V_ce0      =>      VMSME_L3PHIC17to24n1_dataarray_data_V_enb(7),
        inputStubDataset_7_dataarray_data_V_q0       =>     VMSME_L3PHIC17to24n1_dataarray_data_V_dout(7)(12 downto 0),
        inputStubDataset_0_nentries_0_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(0)(0),
        inputStubDataset_0_nentries_0_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(1)(0),
        inputStubDataset_0_nentries_0_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(2)(0),
        inputStubDataset_0_nentries_0_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(3)(0),
        inputStubDataset_0_nentries_0_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(4)(0),
        inputStubDataset_0_nentries_0_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(5)(0),
        inputStubDataset_0_nentries_0_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(6)(0),
        inputStubDataset_0_nentries_0_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(7)(0),
        inputStubDataset_0_nentries_1_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(0)(0),
        inputStubDataset_0_nentries_1_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(1)(0),
        inputStubDataset_0_nentries_1_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(2)(0),
        inputStubDataset_0_nentries_1_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(3)(0),
        inputStubDataset_0_nentries_1_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(4)(0),
        inputStubDataset_0_nentries_1_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(5)(0),
        inputStubDataset_0_nentries_1_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(6)(0),
        inputStubDataset_0_nentries_1_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(7)(0),
        inputStubDataset_0_nentries_2_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(0)(0),
        inputStubDataset_0_nentries_2_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(1)(0),
        inputStubDataset_0_nentries_2_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(2)(0),
        inputStubDataset_0_nentries_2_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(3)(0),
        inputStubDataset_0_nentries_2_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(4)(0),
        inputStubDataset_0_nentries_2_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(5)(0),
        inputStubDataset_0_nentries_2_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(6)(0),
        inputStubDataset_0_nentries_2_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(7)(0),
        inputStubDataset_0_nentries_3_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(0)(0),
        inputStubDataset_0_nentries_3_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(1)(0),
        inputStubDataset_0_nentries_3_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(2)(0),
        inputStubDataset_0_nentries_3_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(3)(0),
        inputStubDataset_0_nentries_3_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(4)(0),
        inputStubDataset_0_nentries_3_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(5)(0),
        inputStubDataset_0_nentries_3_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(6)(0),
        inputStubDataset_0_nentries_3_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(7)(0),
        inputStubDataset_1_nentries_0_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(0)(1),
        inputStubDataset_1_nentries_0_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(1)(1),
        inputStubDataset_1_nentries_0_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(2)(1),
        inputStubDataset_1_nentries_0_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(3)(1),
        inputStubDataset_1_nentries_0_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(4)(1),
        inputStubDataset_1_nentries_0_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(5)(1),
        inputStubDataset_1_nentries_0_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(6)(1),
        inputStubDataset_1_nentries_0_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(7)(1),
        inputStubDataset_1_nentries_1_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(0)(1),
        inputStubDataset_1_nentries_1_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(1)(1),
        inputStubDataset_1_nentries_1_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(2)(1),
        inputStubDataset_1_nentries_1_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(3)(1),
        inputStubDataset_1_nentries_1_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(4)(1),
        inputStubDataset_1_nentries_1_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(5)(1),
        inputStubDataset_1_nentries_1_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(6)(1),
        inputStubDataset_1_nentries_1_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(7)(1),
        inputStubDataset_1_nentries_2_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(0)(1),
        inputStubDataset_1_nentries_2_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(1)(1),
        inputStubDataset_1_nentries_2_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(2)(1),
        inputStubDataset_1_nentries_2_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(3)(1),
        inputStubDataset_1_nentries_2_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(4)(1),
        inputStubDataset_1_nentries_2_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(5)(1),
        inputStubDataset_1_nentries_2_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(6)(1),
        inputStubDataset_1_nentries_2_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(7)(1),
        inputStubDataset_1_nentries_3_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(0)(1),
        inputStubDataset_1_nentries_3_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(1)(1),
        inputStubDataset_1_nentries_3_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(2)(1),
        inputStubDataset_1_nentries_3_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(3)(1),
        inputStubDataset_1_nentries_3_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(4)(1),
        inputStubDataset_1_nentries_3_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(5)(1),
        inputStubDataset_1_nentries_3_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(6)(1),
        inputStubDataset_1_nentries_3_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(7)(1),
        inputStubDataset_2_nentries_0_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(0)(2),
        inputStubDataset_2_nentries_0_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(1)(2),
        inputStubDataset_2_nentries_0_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(2)(2),
        inputStubDataset_2_nentries_0_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(3)(2),
        inputStubDataset_2_nentries_0_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(4)(2),
        inputStubDataset_2_nentries_0_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(5)(2),
        inputStubDataset_2_nentries_0_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(6)(2),
        inputStubDataset_2_nentries_0_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(7)(2),
        inputStubDataset_2_nentries_1_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(0)(2),
        inputStubDataset_2_nentries_1_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(1)(2),
        inputStubDataset_2_nentries_1_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(2)(2),
        inputStubDataset_2_nentries_1_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(3)(2),
        inputStubDataset_2_nentries_1_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(4)(2),
        inputStubDataset_2_nentries_1_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(5)(2),
        inputStubDataset_2_nentries_1_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(6)(2),
        inputStubDataset_2_nentries_1_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(7)(2),
        inputStubDataset_2_nentries_2_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(0)(2),
        inputStubDataset_2_nentries_2_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(1)(2),
        inputStubDataset_2_nentries_2_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(2)(2),
        inputStubDataset_2_nentries_2_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(3)(2),
        inputStubDataset_2_nentries_2_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(4)(2),
        inputStubDataset_2_nentries_2_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(5)(2),
        inputStubDataset_2_nentries_2_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(6)(2),
        inputStubDataset_2_nentries_2_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(7)(2),
        inputStubDataset_2_nentries_3_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(0)(2),
        inputStubDataset_2_nentries_3_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(1)(2),
        inputStubDataset_2_nentries_3_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(2)(2),
        inputStubDataset_2_nentries_3_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(3)(2),
        inputStubDataset_2_nentries_3_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(4)(2),
        inputStubDataset_2_nentries_3_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(5)(2),
        inputStubDataset_2_nentries_3_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(6)(2),
        inputStubDataset_2_nentries_3_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(7)(2),
        inputStubDataset_3_nentries_0_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(0)(3),
        inputStubDataset_3_nentries_0_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(1)(3),
        inputStubDataset_3_nentries_0_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(2)(3),
        inputStubDataset_3_nentries_0_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(3)(3),
        inputStubDataset_3_nentries_0_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(4)(3),
        inputStubDataset_3_nentries_0_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(5)(3),
        inputStubDataset_3_nentries_0_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(6)(3),
        inputStubDataset_3_nentries_0_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(7)(3),
        inputStubDataset_3_nentries_1_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(0)(3),
        inputStubDataset_3_nentries_1_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(1)(3),
        inputStubDataset_3_nentries_1_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(2)(3),
        inputStubDataset_3_nentries_1_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(3)(3),
        inputStubDataset_3_nentries_1_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(4)(3),
        inputStubDataset_3_nentries_1_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(5)(3),
        inputStubDataset_3_nentries_1_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(6)(3),
        inputStubDataset_3_nentries_1_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(7)(3),
        inputStubDataset_3_nentries_2_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(0)(3),
        inputStubDataset_3_nentries_2_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(1)(3),
        inputStubDataset_3_nentries_2_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(2)(3),
        inputStubDataset_3_nentries_2_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(3)(3),
        inputStubDataset_3_nentries_2_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(4)(3),
        inputStubDataset_3_nentries_2_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(5)(3),
        inputStubDataset_3_nentries_2_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(6)(3),
        inputStubDataset_3_nentries_2_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(7)(3),
        inputStubDataset_3_nentries_3_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(0)(3),
        inputStubDataset_3_nentries_3_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(1)(3),
        inputStubDataset_3_nentries_3_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(2)(3),
        inputStubDataset_3_nentries_3_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(3)(3),
        inputStubDataset_3_nentries_3_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(4)(3),
        inputStubDataset_3_nentries_3_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(5)(3),
        inputStubDataset_3_nentries_3_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(6)(3),
        inputStubDataset_3_nentries_3_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(7)(3),
        inputStubDataset_4_nentries_0_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(0)(4),
        inputStubDataset_4_nentries_0_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(1)(4),
        inputStubDataset_4_nentries_0_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(2)(4),
        inputStubDataset_4_nentries_0_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(3)(4),
        inputStubDataset_4_nentries_0_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(4)(4),
        inputStubDataset_4_nentries_0_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(5)(4),
        inputStubDataset_4_nentries_0_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(6)(4),
        inputStubDataset_4_nentries_0_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(7)(4),
        inputStubDataset_4_nentries_1_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(0)(4),
        inputStubDataset_4_nentries_1_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(1)(4),
        inputStubDataset_4_nentries_1_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(2)(4),
        inputStubDataset_4_nentries_1_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(3)(4),
        inputStubDataset_4_nentries_1_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(4)(4),
        inputStubDataset_4_nentries_1_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(5)(4),
        inputStubDataset_4_nentries_1_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(6)(4),
        inputStubDataset_4_nentries_1_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(7)(4),
        inputStubDataset_4_nentries_2_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(0)(4),
        inputStubDataset_4_nentries_2_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(1)(4),
        inputStubDataset_4_nentries_2_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(2)(4),
        inputStubDataset_4_nentries_2_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(3)(4),
        inputStubDataset_4_nentries_2_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(4)(4),
        inputStubDataset_4_nentries_2_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(5)(4),
        inputStubDataset_4_nentries_2_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(6)(4),
        inputStubDataset_4_nentries_2_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(7)(4),
        inputStubDataset_4_nentries_3_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(0)(4),
        inputStubDataset_4_nentries_3_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(1)(4),
        inputStubDataset_4_nentries_3_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(2)(4),
        inputStubDataset_4_nentries_3_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(3)(4),
        inputStubDataset_4_nentries_3_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(4)(4),
        inputStubDataset_4_nentries_3_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(5)(4),
        inputStubDataset_4_nentries_3_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(6)(4),
        inputStubDataset_4_nentries_3_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(7)(4),
        inputStubDataset_5_nentries_0_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(0)(5),
        inputStubDataset_5_nentries_0_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(1)(5),
        inputStubDataset_5_nentries_0_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(2)(5),
        inputStubDataset_5_nentries_0_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(3)(5),
        inputStubDataset_5_nentries_0_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(4)(5),
        inputStubDataset_5_nentries_0_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(5)(5),
        inputStubDataset_5_nentries_0_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(6)(5),
        inputStubDataset_5_nentries_0_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(7)(5),
        inputStubDataset_5_nentries_1_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(0)(5),
        inputStubDataset_5_nentries_1_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(1)(5),
        inputStubDataset_5_nentries_1_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(2)(5),
        inputStubDataset_5_nentries_1_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(3)(5),
        inputStubDataset_5_nentries_1_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(4)(5),
        inputStubDataset_5_nentries_1_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(5)(5),
        inputStubDataset_5_nentries_1_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(6)(5),
        inputStubDataset_5_nentries_1_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(7)(5),
        inputStubDataset_5_nentries_2_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(0)(5),
        inputStubDataset_5_nentries_2_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(1)(5),
        inputStubDataset_5_nentries_2_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(2)(5),
        inputStubDataset_5_nentries_2_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(3)(5),
        inputStubDataset_5_nentries_2_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(4)(5),
        inputStubDataset_5_nentries_2_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(5)(5),
        inputStubDataset_5_nentries_2_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(6)(5),
        inputStubDataset_5_nentries_2_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(7)(5),
        inputStubDataset_5_nentries_3_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(0)(5),
        inputStubDataset_5_nentries_3_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(1)(5),
        inputStubDataset_5_nentries_3_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(2)(5),
        inputStubDataset_5_nentries_3_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(3)(5),
        inputStubDataset_5_nentries_3_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(4)(5),
        inputStubDataset_5_nentries_3_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(5)(5),
        inputStubDataset_5_nentries_3_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(6)(5),
        inputStubDataset_5_nentries_3_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(7)(5),
        inputStubDataset_6_nentries_0_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(0)(6),
        inputStubDataset_6_nentries_0_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(1)(6),
        inputStubDataset_6_nentries_0_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(2)(6),
        inputStubDataset_6_nentries_0_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(3)(6),
        inputStubDataset_6_nentries_0_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(4)(6),
        inputStubDataset_6_nentries_0_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(5)(6),
        inputStubDataset_6_nentries_0_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(6)(6),
        inputStubDataset_6_nentries_0_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(7)(6),
        inputStubDataset_6_nentries_1_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(0)(6),
        inputStubDataset_6_nentries_1_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(1)(6),
        inputStubDataset_6_nentries_1_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(2)(6),
        inputStubDataset_6_nentries_1_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(3)(6),
        inputStubDataset_6_nentries_1_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(4)(6),
        inputStubDataset_6_nentries_1_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(5)(6),
        inputStubDataset_6_nentries_1_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(6)(6),
        inputStubDataset_6_nentries_1_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(7)(6),
        inputStubDataset_6_nentries_2_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(0)(6),
        inputStubDataset_6_nentries_2_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(1)(6),
        inputStubDataset_6_nentries_2_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(2)(6),
        inputStubDataset_6_nentries_2_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(3)(6),
        inputStubDataset_6_nentries_2_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(4)(6),
        inputStubDataset_6_nentries_2_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(5)(6),
        inputStubDataset_6_nentries_2_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(6)(6),
        inputStubDataset_6_nentries_2_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(7)(6),
        inputStubDataset_6_nentries_3_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(0)(6),
        inputStubDataset_6_nentries_3_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(1)(6),
        inputStubDataset_6_nentries_3_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(2)(6),
        inputStubDataset_6_nentries_3_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(3)(6),
        inputStubDataset_6_nentries_3_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(4)(6),
        inputStubDataset_6_nentries_3_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(5)(6),
        inputStubDataset_6_nentries_3_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(6)(6),
        inputStubDataset_6_nentries_3_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(7)(6),
        inputStubDataset_7_nentries_0_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(0)(7),
        inputStubDataset_7_nentries_0_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(1)(7),
        inputStubDataset_7_nentries_0_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(2)(7),
        inputStubDataset_7_nentries_0_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(3)(7),
        inputStubDataset_7_nentries_0_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(4)(7),
        inputStubDataset_7_nentries_0_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(5)(7),
        inputStubDataset_7_nentries_0_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(6)(7),
        inputStubDataset_7_nentries_0_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(0)(7)(7),
        inputStubDataset_7_nentries_1_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(0)(7),
        inputStubDataset_7_nentries_1_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(1)(7),
        inputStubDataset_7_nentries_1_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(2)(7),
        inputStubDataset_7_nentries_1_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(3)(7),
        inputStubDataset_7_nentries_1_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(4)(7),
        inputStubDataset_7_nentries_1_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(5)(7),
        inputStubDataset_7_nentries_1_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(6)(7),
        inputStubDataset_7_nentries_1_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(1)(7)(7),
        inputStubDataset_7_nentries_2_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(0)(7),
        inputStubDataset_7_nentries_2_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(1)(7),
        inputStubDataset_7_nentries_2_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(2)(7),
        inputStubDataset_7_nentries_2_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(3)(7),
        inputStubDataset_7_nentries_2_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(4)(7),
        inputStubDataset_7_nentries_2_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(5)(7),
        inputStubDataset_7_nentries_2_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(6)(7),
        inputStubDataset_7_nentries_2_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(2)(7)(7),
        inputStubDataset_7_nentries_3_V_0 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(0)(7),
        inputStubDataset_7_nentries_3_V_1 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(1)(7),
        inputStubDataset_7_nentries_3_V_2 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(2)(7),
        inputStubDataset_7_nentries_3_V_3 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(3)(7),
        inputStubDataset_7_nentries_3_V_4 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(4)(7),
        inputStubDataset_7_nentries_3_V_5 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(5)(7),
        inputStubDataset_7_nentries_3_V_6 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(6)(7),
        inputStubDataset_7_nentries_3_V_7 => VMSME_L3PHIC17to24n1_nentries_V_dout(3)(7)(7),
        inputProjectionDataset_0_dataarray_data_V_address0 => VMPROJ_L3PHIC17to24_dataarray_data_V_readaddr(0),
        inputProjectionDataset_0_dataarray_data_V_ce0      =>      VMPROJ_L3PHIC17to24_dataarray_data_V_enb(0),
        inputProjectionDataset_0_dataarray_data_V_q0       =>     VMPROJ_L3PHIC17to24_dataarray_data_V_dout(0),
        inputProjectionDataset_0_nentries_0_V              =>        VMPROJ_L3PHIC17to24_nentries_V_dout(0)(0),
        inputProjectionDataset_0_nentries_1_V              =>        VMPROJ_L3PHIC17to24_nentries_V_dout(1)(0),
        inputProjectionDataset_1_dataarray_data_V_address0 => VMPROJ_L3PHIC17to24_dataarray_data_V_readaddr(1),
        inputProjectionDataset_1_dataarray_data_V_ce0      =>      VMPROJ_L3PHIC17to24_dataarray_data_V_enb(1),
        inputProjectionDataset_1_dataarray_data_V_q0       =>     VMPROJ_L3PHIC17to24_dataarray_data_V_dout(1),
        inputProjectionDataset_1_nentries_0_V              =>        VMPROJ_L3PHIC17to24_nentries_V_dout(0)(1),
        inputProjectionDataset_1_nentries_1_V              =>        VMPROJ_L3PHIC17to24_nentries_V_dout(1)(1),
        inputProjectionDataset_2_dataarray_data_V_address0 => VMPROJ_L3PHIC17to24_dataarray_data_V_readaddr(2),
        inputProjectionDataset_2_dataarray_data_V_ce0      =>      VMPROJ_L3PHIC17to24_dataarray_data_V_enb(2),
        inputProjectionDataset_2_dataarray_data_V_q0       =>     VMPROJ_L3PHIC17to24_dataarray_data_V_dout(2),
        inputProjectionDataset_2_nentries_0_V              =>        VMPROJ_L3PHIC17to24_nentries_V_dout(0)(2),
        inputProjectionDataset_2_nentries_1_V              =>        VMPROJ_L3PHIC17to24_nentries_V_dout(1)(2),
        inputProjectionDataset_3_dataarray_data_V_address0 => VMPROJ_L3PHIC17to24_dataarray_data_V_readaddr(3),
        inputProjectionDataset_3_dataarray_data_V_ce0      =>      VMPROJ_L3PHIC17to24_dataarray_data_V_enb(3),
        inputProjectionDataset_3_dataarray_data_V_q0       =>     VMPROJ_L3PHIC17to24_dataarray_data_V_dout(3),
        inputProjectionDataset_3_nentries_0_V              =>        VMPROJ_L3PHIC17to24_nentries_V_dout(0)(3),
        inputProjectionDataset_3_nentries_1_V              =>        VMPROJ_L3PHIC17to24_nentries_V_dout(1)(3),
        inputProjectionDataset_4_dataarray_data_V_address0 => VMPROJ_L3PHIC17to24_dataarray_data_V_readaddr(4),
        inputProjectionDataset_4_dataarray_data_V_ce0      =>      VMPROJ_L3PHIC17to24_dataarray_data_V_enb(4),
        inputProjectionDataset_4_dataarray_data_V_q0       =>     VMPROJ_L3PHIC17to24_dataarray_data_V_dout(4),
        inputProjectionDataset_4_nentries_0_V              =>        VMPROJ_L3PHIC17to24_nentries_V_dout(0)(4),
        inputProjectionDataset_4_nentries_1_V              =>        VMPROJ_L3PHIC17to24_nentries_V_dout(1)(4),
        inputProjectionDataset_5_dataarray_data_V_address0 => VMPROJ_L3PHIC17to24_dataarray_data_V_readaddr(5),
        inputProjectionDataset_5_dataarray_data_V_ce0      =>      VMPROJ_L3PHIC17to24_dataarray_data_V_enb(5),
        inputProjectionDataset_5_dataarray_data_V_q0       =>     VMPROJ_L3PHIC17to24_dataarray_data_V_dout(5),
        inputProjectionDataset_5_nentries_0_V              =>        VMPROJ_L3PHIC17to24_nentries_V_dout(0)(5),
        inputProjectionDataset_5_nentries_1_V              =>        VMPROJ_L3PHIC17to24_nentries_V_dout(1)(5),
        inputProjectionDataset_6_dataarray_data_V_address0 => VMPROJ_L3PHIC17to24_dataarray_data_V_readaddr(6),
        inputProjectionDataset_6_dataarray_data_V_ce0      =>      VMPROJ_L3PHIC17to24_dataarray_data_V_enb(6),
        inputProjectionDataset_6_dataarray_data_V_q0       =>     VMPROJ_L3PHIC17to24_dataarray_data_V_dout(6),
        inputProjectionDataset_6_nentries_0_V              =>        VMPROJ_L3PHIC17to24_nentries_V_dout(0)(6),
        inputProjectionDataset_6_nentries_1_V              =>        VMPROJ_L3PHIC17to24_nentries_V_dout(1)(6),
        inputProjectionDataset_7_dataarray_data_V_address0 => VMPROJ_L3PHIC17to24_dataarray_data_V_readaddr(7),
        inputProjectionDataset_7_dataarray_data_V_ce0      =>      VMPROJ_L3PHIC17to24_dataarray_data_V_enb(7),
        inputProjectionDataset_7_dataarray_data_V_q0       =>     VMPROJ_L3PHIC17to24_dataarray_data_V_dout(7),
        inputProjectionDataset_7_nentries_0_V              =>        VMPROJ_L3PHIC17to24_nentries_V_dout(0)(7),
        inputProjectionDataset_7_nentries_1_V              =>        VMPROJ_L3PHIC17to24_nentries_V_dout(1)(7),
        outputCandidateMatchset_0_dataarray_data_V_address0 => CM_L3PHIC17to24_dataarray_data_V_writeaddr(0),
        outputCandidateMatchset_0_dataarray_data_V_ce0      => open,
        outputCandidateMatchset_0_dataarray_data_V_we0      =>       CM_L3PHIC17to24_dataarray_data_V_wea(0),
        outputCandidateMatchset_0_dataarray_data_V_d0       =>       CM_L3PHIC17to24_dataarray_data_V_din(0),
        outputCandidateMatchset_0_nentries_0_V              =>          CM_L3PHIC17to24_nentries_V_din(0)(0),
        outputCandidateMatchset_0_nentries_0_V_ap_vld       =>           CM_L3PHIC17to24_nentries_V_we(0)(0),
        outputCandidateMatchset_0_nentries_1_V              =>          CM_L3PHIC17to24_nentries_V_din(1)(0),
        outputCandidateMatchset_0_nentries_1_V_ap_vld       =>           CM_L3PHIC17to24_nentries_V_we(1)(0),
        outputCandidateMatchset_1_dataarray_data_V_address0 => CM_L3PHIC17to24_dataarray_data_V_writeaddr(1),
        outputCandidateMatchset_1_dataarray_data_V_ce0      => open,
        outputCandidateMatchset_1_dataarray_data_V_we0      =>       CM_L3PHIC17to24_dataarray_data_V_wea(1),
        outputCandidateMatchset_1_dataarray_data_V_d0       =>       CM_L3PHIC17to24_dataarray_data_V_din(1),
        outputCandidateMatchset_1_nentries_0_V              =>          CM_L3PHIC17to24_nentries_V_din(0)(1),
        outputCandidateMatchset_1_nentries_0_V_ap_vld       =>           CM_L3PHIC17to24_nentries_V_we(0)(1),
        outputCandidateMatchset_1_nentries_1_V              =>          CM_L3PHIC17to24_nentries_V_din(1)(1),
        outputCandidateMatchset_1_nentries_1_V_ap_vld       =>           CM_L3PHIC17to24_nentries_V_we(1)(1),
        outputCandidateMatchset_2_dataarray_data_V_address0 => CM_L3PHIC17to24_dataarray_data_V_writeaddr(2),
        outputCandidateMatchset_2_dataarray_data_V_ce0      => open,
        outputCandidateMatchset_2_dataarray_data_V_we0      =>       CM_L3PHIC17to24_dataarray_data_V_wea(2),
        outputCandidateMatchset_2_dataarray_data_V_d0       =>       CM_L3PHIC17to24_dataarray_data_V_din(2),
        outputCandidateMatchset_2_nentries_0_V              =>          CM_L3PHIC17to24_nentries_V_din(0)(2),
        outputCandidateMatchset_2_nentries_0_V_ap_vld       =>           CM_L3PHIC17to24_nentries_V_we(0)(2),
        outputCandidateMatchset_2_nentries_1_V              =>          CM_L3PHIC17to24_nentries_V_din(1)(2),
        outputCandidateMatchset_2_nentries_1_V_ap_vld       =>           CM_L3PHIC17to24_nentries_V_we(1)(2),
        outputCandidateMatchset_3_dataarray_data_V_address0 => CM_L3PHIC17to24_dataarray_data_V_writeaddr(3),
        outputCandidateMatchset_3_dataarray_data_V_ce0      => open,
        outputCandidateMatchset_3_dataarray_data_V_we0      =>       CM_L3PHIC17to24_dataarray_data_V_wea(3),
        outputCandidateMatchset_3_dataarray_data_V_d0       =>       CM_L3PHIC17to24_dataarray_data_V_din(3),
        outputCandidateMatchset_3_nentries_0_V              =>          CM_L3PHIC17to24_nentries_V_din(0)(3),
        outputCandidateMatchset_3_nentries_0_V_ap_vld       =>           CM_L3PHIC17to24_nentries_V_we(0)(3),
        outputCandidateMatchset_3_nentries_1_V              =>          CM_L3PHIC17to24_nentries_V_din(1)(3),
        outputCandidateMatchset_3_nentries_1_V_ap_vld       =>           CM_L3PHIC17to24_nentries_V_we(1)(3),
        outputCandidateMatchset_4_dataarray_data_V_address0 => CM_L3PHIC17to24_dataarray_data_V_writeaddr(4),
        outputCandidateMatchset_4_dataarray_data_V_ce0      => open,
        outputCandidateMatchset_4_dataarray_data_V_we0      =>       CM_L3PHIC17to24_dataarray_data_V_wea(4),
        outputCandidateMatchset_4_dataarray_data_V_d0       =>       CM_L3PHIC17to24_dataarray_data_V_din(4),
        outputCandidateMatchset_4_nentries_0_V              =>          CM_L3PHIC17to24_nentries_V_din(0)(4),
        outputCandidateMatchset_4_nentries_0_V_ap_vld       =>           CM_L3PHIC17to24_nentries_V_we(0)(4),
        outputCandidateMatchset_4_nentries_1_V              =>          CM_L3PHIC17to24_nentries_V_din(1)(4),
        outputCandidateMatchset_4_nentries_1_V_ap_vld       =>           CM_L3PHIC17to24_nentries_V_we(1)(4),
        outputCandidateMatchset_5_dataarray_data_V_address0 => CM_L3PHIC17to24_dataarray_data_V_writeaddr(5),
        outputCandidateMatchset_5_dataarray_data_V_ce0      => open,
        outputCandidateMatchset_5_dataarray_data_V_we0      =>       CM_L3PHIC17to24_dataarray_data_V_wea(5),
        outputCandidateMatchset_5_dataarray_data_V_d0       =>       CM_L3PHIC17to24_dataarray_data_V_din(5),
        outputCandidateMatchset_5_nentries_0_V              =>          CM_L3PHIC17to24_nentries_V_din(0)(5),
        outputCandidateMatchset_5_nentries_0_V_ap_vld       =>           CM_L3PHIC17to24_nentries_V_we(0)(5),
        outputCandidateMatchset_5_nentries_1_V              =>          CM_L3PHIC17to24_nentries_V_din(1)(5),
        outputCandidateMatchset_5_nentries_1_V_ap_vld       =>           CM_L3PHIC17to24_nentries_V_we(1)(5),
        outputCandidateMatchset_6_dataarray_data_V_address0 => CM_L3PHIC17to24_dataarray_data_V_writeaddr(6),
        outputCandidateMatchset_6_dataarray_data_V_ce0      => open,
        outputCandidateMatchset_6_dataarray_data_V_we0      =>       CM_L3PHIC17to24_dataarray_data_V_wea(6),
        outputCandidateMatchset_6_dataarray_data_V_d0       =>       CM_L3PHIC17to24_dataarray_data_V_din(6),
        outputCandidateMatchset_6_nentries_0_V              =>          CM_L3PHIC17to24_nentries_V_din(0)(6),
        outputCandidateMatchset_6_nentries_0_V_ap_vld       =>           CM_L3PHIC17to24_nentries_V_we(0)(6),
        outputCandidateMatchset_6_nentries_1_V              =>          CM_L3PHIC17to24_nentries_V_din(1)(6),
        outputCandidateMatchset_6_nentries_1_V_ap_vld       =>           CM_L3PHIC17to24_nentries_V_we(1)(6),
        outputCandidateMatchset_7_dataarray_data_V_address0 => CM_L3PHIC17to24_dataarray_data_V_writeaddr(7),
        outputCandidateMatchset_7_dataarray_data_V_ce0      => open,
        outputCandidateMatchset_7_dataarray_data_V_we0      =>       CM_L3PHIC17to24_dataarray_data_V_wea(7),
        outputCandidateMatchset_7_dataarray_data_V_d0       =>       CM_L3PHIC17to24_dataarray_data_V_din(7),
        outputCandidateMatchset_7_nentries_0_V              =>          CM_L3PHIC17to24_nentries_V_din(0)(7),
        outputCandidateMatchset_7_nentries_0_V_ap_vld       =>           CM_L3PHIC17to24_nentries_V_we(0)(7),
        outputCandidateMatchset_7_nentries_1_V              =>          CM_L3PHIC17to24_nentries_V_din(1)(7),
        outputCandidateMatchset_7_nentries_1_V_ap_vld       =>           CM_L3PHIC17to24_nentries_V_we(1)(7)   );


  --------------------------------------------------------------
  -- AllStubs memory
  --------------------------------------------------------------
  AS_L3PHICn4 : myMemory
    generic map (
      RAM_WIDTH       => 36,
      RAM_DEPTH       => 1024,
      INIT_FILE       => "",
      RAM_PERFORMANCE => "HIGH_PERFORMANCE",
      HEX             => 0
      )
    port map (        
      clka     => clk,
      wea      => AS_L3PHICn4_dataarray_data_V_wea,
      addra    => AS_L3PHICn4_dataarray_data_V_writeaddr,
      dina     => AS_L3PHICn4_dataarray_data_V_din,
      nent_we0 =>  AS_L3PHICn4_nentries_V_we(0),
      nent_i0  => AS_L3PHICn4_nentries_V_din(0),
      nent_we1 =>  AS_L3PHICn4_nentries_V_we(1),
      nent_i1  => AS_L3PHICn4_nentries_V_din(1),
      nent_we2 =>  AS_L3PHICn4_nentries_V_we(2),
      nent_i2  => AS_L3PHICn4_nentries_V_din(2),
      nent_we3 =>  AS_L3PHICn4_nentries_V_we(3),
      nent_i3  => AS_L3PHICn4_nentries_V_din(3),
      nent_we4 =>  AS_L3PHICn4_nentries_V_we(4),
      nent_i4  => AS_L3PHICn4_nentries_V_din(4),
      nent_we5 =>  AS_L3PHICn4_nentries_V_we(5),
      nent_i5  => AS_L3PHICn4_nentries_V_din(5),
      nent_we6 =>  AS_L3PHICn4_nentries_V_we(6),
      nent_i6  => AS_L3PHICn4_nentries_V_din(6),
      nent_we7 =>  AS_L3PHICn4_nentries_V_we(7),
      nent_i7  => AS_L3PHICn4_nentries_V_din(7),
      clkb     => clk,
      rstb     => '0',
      regceb   => '1',
      enb      => AS_L3PHICn4_dataarray_data_V_enb,
      addrb    => AS_L3PHICn4_dataarray_data_V_readaddr,
      doutb    => AS_L3PHICn4_dataarray_data_V_dout,
      nent_o0  => AS_L3PHICn4_nentries_V_dout(0),
      nent_o1  => AS_L3PHICn4_nentries_V_dout(1),
      nent_o2  => AS_L3PHICn4_nentries_V_dout(2),
      nent_o3  => AS_L3PHICn4_nentries_V_dout(3),
      nent_o4  => AS_L3PHICn4_nentries_V_dout(4),
      nent_o5  => AS_L3PHICn4_nentries_V_dout(5),
      nent_o6  => AS_L3PHICn4_nentries_V_dout(6),
      nent_o7  => AS_L3PHICn4_nentries_V_dout(7)
      );  


  --------------------------------------------------------------
  -- CandidateMatches memories
  --------------------------------------------------------------
  gen_CM_L3PHIC17to24 : for cmidx in 7 downto 0 generate
  begin
    CM_L3PHIC17to24 : myMemory
      generic map (
        RAM_WIDTH       => 14,
        RAM_DEPTH       => 256,
        INIT_FILE       => "",
        RAM_PERFORMANCE => "HIGH_PERFORMANCE",
        HEX             => 1       
        )
      port map (        
        clka     => clk,
        wea      => CM_L3PHIC17to24_dataarray_data_V_wea(cmidx),
        addra    => CM_L3PHIC17to24_dataarray_data_V_writeaddr(cmidx),
        dina     => CM_L3PHIC17to24_dataarray_data_V_din(cmidx),
        nent_we0 =>  CM_L3PHIC17to24_nentries_V_we(0)(cmidx),
        nent_i0  => CM_L3PHIC17to24_nentries_V_din(0)(cmidx),
        nent_we1 =>  CM_L3PHIC17to24_nentries_V_we(1)(cmidx),
        nent_i1  => CM_L3PHIC17to24_nentries_V_din(1)(cmidx),
        nent_we2 => '0',
        nent_i2  => (others=>'0'),
        nent_we3 => '0',
        nent_i3  => (others=>'0'),
        nent_we4 => '0',
        nent_i4  => (others=>'0'),
        nent_we5 => '0',
        nent_i5  => (others=>'0'),
        nent_we6 => '0',
        nent_i6  => (others=>'0'),
        nent_we7 => '0',
        nent_i7  => (others=>'0'),
        clkb     => clk,
        rstb     => '0',
        regceb   => '1',
        enb      => CM_L3PHIC17to24_dataarray_data_V_enb(cmidx),
        addrb    => CM_L3PHIC17to24_dataarray_data_V_readaddr(cmidx),  
        doutb    => CM_L3PHIC17to24_dataarray_data_V_dout(cmidx),
        nent_o0  => CM_L3PHIC17to24_nentries_V_dout(0)(cmidx),
        nent_o1  => CM_L3PHIC17to24_nentries_V_dout(1)(cmidx),
        nent_o2  => open,
        nent_o3  => open,
        nent_o4  => open,
        nent_o5  => open,
        nent_o6  => open,
        nent_o7  => open
        );
        
  end generate gen_CM_L3PHIC17to24;  
  
  
  --------------------------------------------------------------
  -- MatchCalculator
  --------------------------------------------------------------
  MC_L3PHIC : entity work.MC_L3PHIC
    port map (
      ap_clk   => clk,
      ap_rst   => reset,
      ap_start => MatchCalculator_start,
      ap_done  => MatchCalculator_done,
      ap_idle  => open,
      ap_ready => open,
      bx_V     => bx_out_MatchEngine(0),
      match1_dataarray_data_V_address0 => CM_L3PHIC17to24_dataarray_data_V_readaddr(0),
      match1_dataarray_data_V_ce0      => CM_L3PHIC17to24_dataarray_data_V_enb(0),
      match1_dataarray_data_V_q0       => CM_L3PHIC17to24_dataarray_data_V_dout(0),
      match1_nentries_0_V              => CM_L3PHIC17to24_nentries_V_dout(0)(0),
      match1_nentries_1_V              => CM_L3PHIC17to24_nentries_V_dout(1)(0),
      match2_dataarray_data_V_address0 => CM_L3PHIC17to24_dataarray_data_V_readaddr(1),
      match2_dataarray_data_V_ce0      => CM_L3PHIC17to24_dataarray_data_V_enb(1),
      match2_dataarray_data_V_q0       => CM_L3PHIC17to24_dataarray_data_V_dout(1),
      match2_nentries_0_V              => CM_L3PHIC17to24_nentries_V_dout(0)(1),
      match2_nentries_1_V              => CM_L3PHIC17to24_nentries_V_dout(1)(1),
      match3_dataarray_data_V_address0 => CM_L3PHIC17to24_dataarray_data_V_readaddr(2),
      match3_dataarray_data_V_ce0      => CM_L3PHIC17to24_dataarray_data_V_enb(2),
      match3_dataarray_data_V_q0       => CM_L3PHIC17to24_dataarray_data_V_dout(2),
      match3_nentries_0_V              => CM_L3PHIC17to24_nentries_V_dout(0)(2),
      match3_nentries_1_V              => CM_L3PHIC17to24_nentries_V_dout(1)(2),
      match4_dataarray_data_V_address0 => CM_L3PHIC17to24_dataarray_data_V_readaddr(3),
      match4_dataarray_data_V_ce0      => CM_L3PHIC17to24_dataarray_data_V_enb(3),
      match4_dataarray_data_V_q0       => CM_L3PHIC17to24_dataarray_data_V_dout(3),
      match4_nentries_0_V              => CM_L3PHIC17to24_nentries_V_dout(0)(3),
      match4_nentries_1_V              => CM_L3PHIC17to24_nentries_V_dout(1)(3),
      match5_dataarray_data_V_address0 => CM_L3PHIC17to24_dataarray_data_V_readaddr(4),
      match5_dataarray_data_V_ce0      => CM_L3PHIC17to24_dataarray_data_V_enb(4),
      match5_dataarray_data_V_q0       => CM_L3PHIC17to24_dataarray_data_V_dout(4),
      match5_nentries_0_V              => CM_L3PHIC17to24_nentries_V_dout(0)(4),
      match5_nentries_1_V              => CM_L3PHIC17to24_nentries_V_dout(1)(4),
      match6_dataarray_data_V_address0 => CM_L3PHIC17to24_dataarray_data_V_readaddr(5),
      match6_dataarray_data_V_ce0      => CM_L3PHIC17to24_dataarray_data_V_enb(5),
      match6_dataarray_data_V_q0       => CM_L3PHIC17to24_dataarray_data_V_dout(5),
      match6_nentries_0_V              => CM_L3PHIC17to24_nentries_V_dout(0)(5),
      match6_nentries_1_V              => CM_L3PHIC17to24_nentries_V_dout(1)(5),
      match7_dataarray_data_V_address0 => CM_L3PHIC17to24_dataarray_data_V_readaddr(6),
      match7_dataarray_data_V_ce0      => CM_L3PHIC17to24_dataarray_data_V_enb(6),
      match7_dataarray_data_V_q0       => CM_L3PHIC17to24_dataarray_data_V_dout(6),
      match7_nentries_0_V              => CM_L3PHIC17to24_nentries_V_dout(0)(6),
      match7_nentries_1_V              => CM_L3PHIC17to24_nentries_V_dout(1)(6),
      match8_dataarray_data_V_address0 => CM_L3PHIC17to24_dataarray_data_V_readaddr(7),
      match8_dataarray_data_V_ce0      => CM_L3PHIC17to24_dataarray_data_V_enb(7),
      match8_dataarray_data_V_q0       => CM_L3PHIC17to24_dataarray_data_V_dout(7),
      match8_nentries_0_V              => CM_L3PHIC17to24_nentries_V_dout(0)(7),
      match8_nentries_1_V              => CM_L3PHIC17to24_nentries_V_dout(1)(7),
      allstub_dataarray_data_V_address0 => AS_L3PHICn4_dataarray_data_V_readaddr,
      allstub_dataarray_data_V_ce0      => AS_L3PHICn4_dataarray_data_V_enb,
      allstub_dataarray_data_V_q0       => AS_L3PHICn4_dataarray_data_V_dout,
      --allstub_nentries_0_V => AS_L3PHICn4_nentries_V_dout(0),
      --allstub_nentries_1_V => AS_L3PHICn4_nentries_V_dout(1),
      --allstub_nentries_2_V => (others=>'0'),
      --allstub_nentries_3_V => (others=>'0'),
      --allstub_nentries_4_V => (others=>'0'),
      --allstub_nentries_5_V => (others=>'0'),
      --allstub_nentries_6_V => (others=>'0'),
      --allstub_nentries_7_V => (others=>'0'),
      allproj_dataarray_data_V_address0 => AP_L3PHIC_dataarray_data_V_readaddr,
      allproj_dataarray_data_V_ce0      => AP_L3PHIC_dataarray_data_V_enb,
      allproj_dataarray_data_V_q0       => AP_L3PHIC_dataarray_data_V_dout,
      --allproj_nentries_0_V => AP_L3PHIC_nentries_0_V_dout,
      --allproj_nentries_1_V => AP_L3PHIC_nentries_1_V_dout,
      --allproj_nentries_2_V => (others=>'0'),
      --allproj_nentries_3_V => (others=>'0'),
      --allproj_nentries_4_V => (others=>'0'),
      --allproj_nentries_5_V => (others=>'0'),
      --allproj_nentries_6_V => (others=>'0'),
      --allproj_nentries_7_V => (others=>'0'),
      bx_o_V        => bx_out_MatchCalculator,
      bx_o_V_ap_vld => bx_out_MatchCalculator_vld,
      fullmatch1_dataarray_data_V_address0 => FM_L1L2XX_L3PHIC_dataarray_data_V_writeaddr,
      fullmatch1_dataarray_data_V_ce0      => open,
      fullmatch1_dataarray_data_V_we0      => FM_L1L2XX_L3PHIC_dataarray_data_V_wea,
      fullmatch1_dataarray_data_V_d0       => FM_L1L2XX_L3PHIC_dataarray_data_V_din,
      fullmatch1_nentries_0_V              => FM_L1L2XX_L3PHIC_nentries_V_din(0),
      fullmatch1_nentries_0_V_ap_vld       => FM_L1L2XX_L3PHIC_nentries_V_we(0),
      fullmatch1_nentries_1_V              => FM_L1L2XX_L3PHIC_nentries_V_din(1),
      fullmatch1_nentries_1_V_ap_vld       => FM_L1L2XX_L3PHIC_nentries_V_we(1),
      fullmatch2_dataarray_data_V_address0 => open,
      fullmatch2_dataarray_data_V_ce0      => open,
      fullmatch2_dataarray_data_V_we0      => open,
      fullmatch2_dataarray_data_V_d0       => open,
      fullmatch2_nentries_0_V              => open,
      fullmatch2_nentries_0_V_ap_vld       => open,
      fullmatch2_nentries_1_V              => open,
      fullmatch2_nentries_1_V_ap_vld       => open,
      fullmatch3_dataarray_data_V_address0 => FM_L5L6XX_L3PHIC_dataarray_data_V_writeaddr,
      fullmatch3_dataarray_data_V_ce0      => open,
      fullmatch3_dataarray_data_V_we0      => FM_L5L6XX_L3PHIC_dataarray_data_V_wea,
      fullmatch3_dataarray_data_V_d0       => FM_L5L6XX_L3PHIC_dataarray_data_V_din,
      fullmatch3_nentries_0_V              => FM_L5L6XX_L3PHIC_nentries_V_din(0),
      fullmatch3_nentries_0_V_ap_vld       => FM_L5L6XX_L3PHIC_nentries_V_we(0),
      fullmatch3_nentries_1_V              => FM_L5L6XX_L3PHIC_nentries_V_din(1),
      fullmatch3_nentries_1_V_ap_vld       => FM_L5L6XX_L3PHIC_nentries_V_we(1),
      fullmatch4_dataarray_data_V_address0 => open,
      fullmatch4_dataarray_data_V_ce0      => open,
      fullmatch4_dataarray_data_V_we0      => open,
      fullmatch4_dataarray_data_V_d0       => open,
      fullmatch4_nentries_0_V              => open,
      fullmatch4_nentries_0_V_ap_vld       => open,
      fullmatch4_nentries_1_V              => open,
      fullmatch4_nentries_1_V_ap_vld       => open,
      fullmatch5_dataarray_data_V_address0 => open,
      fullmatch5_dataarray_data_V_ce0      => open,
      fullmatch5_dataarray_data_V_we0      => open,
      fullmatch5_dataarray_data_V_d0       => open,
      fullmatch5_nentries_0_V              => open,
      fullmatch5_nentries_0_V_ap_vld       => open,
      fullmatch5_nentries_1_V              => open,
      fullmatch5_nentries_1_V_ap_vld       => open,
      fullmatch6_dataarray_data_V_address0 => open,
      fullmatch6_dataarray_data_V_ce0      => open,
      fullmatch6_dataarray_data_V_we0      => open,
      fullmatch6_dataarray_data_V_d0       => open,
      fullmatch6_nentries_0_V              => open,
      fullmatch6_nentries_0_V_ap_vld       => open,
      fullmatch6_nentries_1_V              => open,
      fullmatch6_nentries_1_V_ap_vld       => open,
      fullmatch7_dataarray_data_V_address0 => open,
      fullmatch7_dataarray_data_V_ce0      => open,
      fullmatch7_dataarray_data_V_we0      => open,
      fullmatch7_dataarray_data_V_d0       => open,
      fullmatch7_nentries_0_V              => open,
      fullmatch7_nentries_0_V_ap_vld       => open,
      fullmatch7_nentries_1_V              => open,
      fullmatch7_nentries_1_V_ap_vld       => open      
      );


  --------------------------------------------------------------
  -- FullMatches memories
  --------------------------------------------------------------
  FM_L1L2XX_L3PHIC : myMemory
    generic map (
      RAM_WIDTH       => 45,
      RAM_DEPTH       => 256,
      INIT_FILE       => "",
      RAM_PERFORMANCE => "HIGH_PERFORMANCE",
      HEX             => 0
      )
    port map (        
      clka     => clk,
      wea      => FM_L1L2XX_L3PHIC_dataarray_data_V_wea,
      addra    => FM_L1L2XX_L3PHIC_dataarray_data_V_writeaddr,
      dina     => FM_L1L2XX_L3PHIC_dataarray_data_V_din,
      nent_we0 => FM_L1L2XX_L3PHIC_nentries_V_we(0),
      nent_i0  => FM_L1L2XX_L3PHIC_nentries_V_din(0),
      nent_we1 => FM_L1L2XX_L3PHIC_nentries_V_we(1),
      nent_i1  => FM_L1L2XX_L3PHIC_nentries_V_din(1),
      nent_we2 => '0',
      nent_i2  => (others=>'0'),
      nent_we3 => '0',
      nent_i3  => (others=>'0'),
      nent_we4 => '0',
      nent_i4  => (others=>'0'),
      nent_we5 => '0',
      nent_i5  => (others=>'0'),
      nent_we6 => '0',
      nent_i6  => (others=>'0'),
      nent_we7 => '0',
      nent_i7  => (others=>'0'),
      clkb     => clk,
      rstb     => '0',
      regceb   => '1',
      enb      => FM_L1L2XX_L3PHIC_dataarray_data_V_enb,
      addrb    => FM_L1L2XX_L3PHIC_dataarray_data_V_readaddr,
      doutb    => FM_L1L2XX_L3PHIC_dataarray_data_V_dout,
      nent_o0  => FM_L1L2XX_L3PHIC_nentries_V_dout(0),
      nent_o1  => FM_L1L2XX_L3PHIC_nentries_V_dout(1),
      nent_o2  => open,
      nent_o3  => open,
      nent_o4  => open,
      nent_o5  => open,
      nent_o6  => open,
      nent_o7  => open
      );
  
  FM_L5L6XX_L3PHIC : myMemory
    generic map (
      RAM_WIDTH       => 45,
      RAM_DEPTH       => 256,
      INIT_FILE       => "",
      RAM_PERFORMANCE => "HIGH_PERFORMANCE",
      HEX             => 0
      )
    port map (        
      clka     => clk,
      wea      => FM_L5L6XX_L3PHIC_dataarray_data_V_wea,
      addra    => FM_L5L6XX_L3PHIC_dataarray_data_V_writeaddr,
      dina     => FM_L5L6XX_L3PHIC_dataarray_data_V_din,
      nent_we0 => FM_L5L6XX_L3PHIC_nentries_V_we(0),
      nent_i0  => FM_L5L6XX_L3PHIC_nentries_V_din(0),
      nent_we1 => FM_L5L6XX_L3PHIC_nentries_V_we(1),
      nent_i1  => FM_L5L6XX_L3PHIC_nentries_V_din(1),
      nent_we2 => '0',
      nent_i2  => (others=>'0'),
      nent_we3 => '0',
      nent_i3  => (others=>'0'),
      nent_we4 => '0',
      nent_i4  => (others=>'0'),
      nent_we5 => '0',
      nent_i5  => (others=>'0'),
      nent_we6 => '0',
      nent_i6  => (others=>'0'),
      nent_we7 => '0',
      nent_i7  => (others=>'0'),
      clkb     => clk,
      rstb     => '0',
      regceb   => '1',
      enb      => FM_L5L6XX_L3PHIC_dataarray_data_V_enb,
      addrb    => FM_L5L6XX_L3PHIC_dataarray_data_V_readaddr,
      doutb    => FM_L5L6XX_L3PHIC_dataarray_data_V_dout,
      nent_o0  => FM_L5L6XX_L3PHIC_nentries_V_dout(0),
      nent_o1  => FM_L5L6XX_L3PHIC_nentries_V_dout(1),
      nent_o2  => open,
      nent_o3  => open,
      nent_o4  => open,
      nent_o5  => open,
      nent_o6  => open,
      nent_o7  => open
      );

end rtl;
