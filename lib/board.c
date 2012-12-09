#include <common.h>
#include <part.h>
#include <fat.h>
#include <mmc.h>
#include <asm/io.h>

#include	"lge_fota_std.h"
#include	"oem_usd.h"

#ifdef CFG_PRINTF
int print_info(void)
{
	printf ("\n\nTexas Instruments X-Loader 1.41 ("
		__DATE__ " - " __TIME__ ")\n");
	return 0;
}
#endif
typedef int (init_fnc_t) (void);

init_fnc_t *init_sequence[] = {
	cpu_init,		
	board_init,		
#ifdef CFG_PRINTF
 	serial_init,		
	print_info,
#endif
   	
	NULL,
};

#ifdef CFG_CMD_FAT
extern char * strcpy(char * dest,const char *src);
#else
char * strcpy(char * dest,const char *src)
{
	 char *tmp = dest;

	 while ((*dest++ = *src++) != '\0')
	         ;
	 return tmp;
}
#endif

#ifdef CFG_CMD_MMC
extern block_dev_desc_t *mmc_get_dev(int dev);
int mmc_read_bootloader(int dev)
{
	unsigned char ret = 0;
	unsigned long offset = CFG_LOADADDR;

	ret = mmc_init(dev);
	if (ret != 0){
		printf("\n MMC init failed \n");
		return -1;
	}

#ifdef CFG_CMD_FAT
	long size;
	block_dev_desc_t *dev_desc = NULL;

	if (fat_boot()) {
		dev_desc = mmc_get_dev(dev);
		fat_register_device(dev_desc, 1);
		size = file_fat_read("u-boot.bin", (unsigned char *)offset, 0);
		if (size == -1)
			return -1;
	} else {
		sUpdateStatus	*mUSD;
		ua_u32			uiFOTAPartiAddr;
		ua_u32			uiPartitionAddr;
		ua_u32			uiPartitionSize;

		FOTALOG_PRINT("Load uBoot Image from eMMC....\n");

		OemFlash_Initialize(dev, CFG_LOADADDR);
		OemUSD_Init(CFG_LOADADDR);
		mUSD = (sUpdateStatus*)CFG_LOADADDR;
		OemUSD_Load(mUSD);
		OemFlash_Release();

		if ((mUSD->enUpdateState == FOTA_STATE_FIRMWARE_UPDATE) ||
			(mUSD->enUpdateState == FOTA_STATE_FILE_UPDATE))
		{
			if (OemFlash_GetPartitionInfo(FOTA_PARTITION, &uiPartitionAddr, &uiPartitionSize) == ua_false)
			{
				return -1;
			}

			uiFOTAPartiAddr = uiPartitionAddr;

			if (OemFlash_GetPartitionInfo(AP_1_PARTITION, &uiPartitionAddr, &uiPartitionSize) == ua_false)
			{
				return -1;
			}

			mmc_read(dev, uiFOTAPartiAddr/0x200, (unsigned char *)CFG_LOADADDR,
							uiPartitionSize);
		}
		else
		{

#if 1
			 ret = mmc_read(dev, EMMC_UBOOT_START/EMMC_BLOCK_SIZE, (unsigned char *)CFG_LOADADDR,
								(EMMC_UBOOT_END - EMMC_UBOOT_START));
#else
			 ret = mmc_read(dev, 0x400, (unsigned char *)CFG_LOADADDR,
								0x00060000);
#endif
			if (ret != 1)
				return -1;

		}
	}
#endif
	return 0;
}
#endif

extern int do_load_serial_bin(ulong offset, int baudrate);

#define __raw_readl(a)	(*(volatile unsigned int *)(a))

#if 1	
extern void configure_core_dpll_no_lock(void);
extern void lock_core_dpll_shadow(void);
#endif

void start_armboot (void)
{
  	init_fnc_t **init_fnc_ptr;
	uchar *buf;
	char boot_dev_name[8];
 
   	for (init_fnc_ptr = init_sequence; *init_fnc_ptr; ++init_fnc_ptr) {
		if ((*init_fnc_ptr)() != 0) {
			hang ();
		}
	}
#ifdef START_LOADB_DOWNLOAD
	strcpy(boot_dev_name, "UART");
	do_load_serial_bin (CFG_LOADADDR, 115200);
#else

	buf = (uchar *) CFG_LOADADDR;

	switch (get_boot_device()) {
	case 0x03:
		strcpy(boot_dev_name, "ONENAND");
#if defined(CFG_ONENAND)
		for (i = ONENAND_START_BLOCK; i < ONENAND_END_BLOCK; i++) {
			if (!onenand_read_block(buf, i))
				buf += ONENAND_BLOCK_SIZE;
			else
				goto error;
		}
#endif
		break;
	case 0x02:
	default:
		strcpy(boot_dev_name, "NAND");
#if defined(CFG_NAND)
		for (i = NAND_UBOOT_START; i < NAND_UBOOT_END;
				i+= NAND_BLOCK_SIZE) {
			if (!nand_read_block(buf, i))
				buf += NAND_BLOCK_SIZE; 
		}
#endif
		break;
	case 0x05:
		strcpy(boot_dev_name, "MMC/SD1");
#if defined(CONFIG_MMC)
		if (mmc_read_bootloader(0) != 0)
			goto error;
#endif
		break;
	case 0x06:
		strcpy(boot_dev_name, "EMMC");
#if defined(CONFIG_MMC)
		if (mmc_read_bootloader(1) != 0)
			goto error;
#endif
		break;
	};
#endif

#if 1	
	configure_core_dpll_no_lock();

	lock_core_dpll_shadow();

#if 1	
	
	__raw_writel(0x0, CM_DLL_CTRL);

	spin_delay(200);

	while(((__raw_readl(EMIF1_BASE + EMIF_STATUS) & 0x04) != 0x04)
		|| ((__raw_readl(EMIF2_BASE + EMIF_STATUS) & 0x04) != 0x04));

	sr32(CM_MEMIF_EMIF_1_CLKCTRL, 0, 32, 0x1);
        sr32(CM_MEMIF_EMIF_2_CLKCTRL, 0, 32, 0x1);

	__raw_writel(0x80000000, EMIF1_BASE + EMIF_PWR_MGMT_CTRL);
	__raw_writel(0x80000000, EMIF2_BASE + EMIF_PWR_MGMT_CTRL);
#endif

#endif

	printf("Starting OS Bootloader from %s ...\n", boot_dev_name);
 	((init_fnc_t *)CFG_LOADADDR)();

#if defined(CFG_ONENAND) || defined(CONFIG_MMC)
error:
#endif
	printf("Could not read bootloader!\n");
	hang();
}

void hang (void)
{
	
	board_hang();

	printf("X-Loader hangs\n");
	for (;;);
}
