	component clock is
		port (
			clk_clk        : in  std_logic := 'X'; -- clk
			clk_25m_clk    : out std_logic;        -- clk
			clk_116800_clk : out std_logic;        -- clk
			clk_12m_clk    : out std_logic;        -- clk
			reset_reset_n  : in  std_logic := 'X'  -- reset_n
		);
	end component clock;

	u0 : component clock
		port map (
			clk_clk        => CONNECTED_TO_clk_clk,        --        clk.clk
			clk_25m_clk    => CONNECTED_TO_clk_25m_clk,    --    clk_25m.clk
			clk_116800_clk => CONNECTED_TO_clk_116800_clk, -- clk_116800.clk
			clk_12m_clk    => CONNECTED_TO_clk_12m_clk,    --    clk_12m.clk
			reset_reset_n  => CONNECTED_TO_reset_reset_n   --      reset.reset_n
		);

