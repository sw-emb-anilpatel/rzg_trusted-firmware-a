# Copyright (C) 2023 AVNET Embedded, MSC Technologies GmbH


DDR_SOURCES	+=	plat/renesas/rz/soc/g2ul/drivers/ddr/param_mc.c	\
				plat/renesas/rz/common/drivers/ddr/param_swizzle.c

DDR_PLL4	:= 1600
$(eval $(call add_define,DDR_PLL4))
