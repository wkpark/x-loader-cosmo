#include <common.h>
#include <asm/io.h>

const struct ddr_regs ddr_regs_400_mhz = {
	.tim1		= 0x10eb065a,
	.tim2		= 0x20370dd2,
	.tim3		= 0x00b1c33f,
	.phy_ctrl_1	= 0x849FF408,
	.ref_ctrl	= 0x00000618,
	.config_init	= 0x80000eb1,
	.config_final	= 0x80001ab1,
	.zq_config	= 0x500b3215,
	.mr1		= 0x83,
	.mr2		= 0x4
};

#if 0
const struct ddr_regs ddr_regs_400_mhz_2cs = {
	
	.tim1		= 0x10eb0662,
	.tim2		= 0x20370dd2,
	.tim3		= 0x00b1c33f,
	.phy_ctrl_1	= 0x849FF408,
	.ref_ctrl	= 0x00000618,
	.config_init	= 0x80000eb9,
	.config_final	= 0x80001ab9,
	.zq_config	= 0xD00b3215,
	.mr1		= 0x83,
	.mr2		= 0x4
};
#else
const struct ddr_regs ddr_regs_400_mhz_2cs = {
    
     .tim1      = 0x10eb0661,
    .tim2       = 0x20370dd2,
    .tim3       = 0x00b1c33f,
    .phy_ctrl_1 = 0x849FF409,
    .ref_ctrl       = 0x00000618,
    .config_init    = 0x80000eb1,
    .config_final   = 0x80001ab1,
    .zq_config  = 0x500b3214,
    .mr1        = 0x83,
    .mr2        = 0x4
};
#endif

const struct ddr_regs ddr_regs_380_mhz = {
	.tim1		= 0x10cb061a,
	.tim2		= 0x20350d52,
	.tim3		= 0x00b1431f,
	.phy_ctrl_1	= 0x849FF408,
	.ref_ctrl	= 0x000005ca,
	.config_init	= 0x80000eb1,
	.config_final	= 0x80001ab1,
	.zq_config	= 0x500b3215,
	.mr1		= 0x83,
	.mr2		= 0x4
};

const struct ddr_regs ddr_regs_200_mhz = {
	.tim1		= 0x08648309,
	.tim2		= 0x101b06ca,
	.tim3		= 0x0048a19f,
	.phy_ctrl_1	= 0x849FF405,
	.ref_ctrl	= 0x0000030c,
	.config_init	= 0x80000eb1,
	.config_final	= 0x80000eb1,
	.zq_config	= 0x500b3215,
	.mr1		= 0x23,
	.mr2		= 0x1
};

const struct ddr_regs ddr_regs_200_mhz_2cs = {
#if 0	
	.tim1		= 0x08648309,
	.tim2		= 0x101b06ca,
	.tim3		= 0x0048a19f,
	.phy_ctrl_1	= 0x849FF405,
	.ref_ctrl	= 0x0000030c,
	.config_init	= 0x80000eb9,
	.config_final	= 0x80000eb9,
	.zq_config	= 0xD00b3215,
	.mr1		= 0x23,
	.mr2		= 0x1
#else    
	.tim1		= 0x10cb061a,
	.tim2		= 0x20350d52,
	.tim3		= 0x00b1431f,
	.phy_ctrl_1 	= 0x849FF408,
	.ref_ctrl	= 0x000005ca,
	.config_init	= 0x80000eb1,
	.config_final	= 0x80001ab1,
	.zq_config	= 0x500b3215,
	.mr1		= 0x83,
	.mr2		= 0x4
#endif
};

void __ddr_init(void)
{
	u32 rev;
	const struct ddr_regs *ddr_regs = 0;
	rev = omap_revision();
	if(rev == OMAP4430_ES1_0)
		ddr_regs = &ddr_regs_380_mhz;
	else if (rev == OMAP4430_ES2_0)
		ddr_regs = &ddr_regs_200_mhz_2cs;
	else if (rev >= OMAP4430_ES2_1)

		ddr_regs = &ddr_regs_400_mhz_2cs;

	__raw_writel(0x80540300, DMM_BASE + DMM_LISA_MAP_0);

	do_ddr_init(ddr_regs, ddr_regs);
}

void ddr_init(void)
	__attribute__((weak, alias("__ddr_init")));
