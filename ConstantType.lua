return {
	Token = {
		BEGIN = 0,
		NUMBER = 0x01,
		STRING = 0x02,
		KEYWORD = 0x03,
		NAME = 0x04,
		BINOPS = 0x05,
		UNIOPS = 0x06,
		OTHOPS = 0x07
	},
	Parser = {
		PROC = 0x00,
		EXP = 0x01,
		EXPLIST = 0x02,
		NUMBER = 0x03,
		STRING = 0x04,
		BLOCK = 0x05,
		WHILE = 0x06
	}
}
