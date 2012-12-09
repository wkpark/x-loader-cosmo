#
# (C) Copyright 2004-2006, Texas Instruments, <www.ti.com>
# Jian Zhang <jzhang@ti.com>
#
# (C) Copyright 2000-2004
# Wolfgang Denk, DENX Software Engineering, wd@denx.de.
#
# See file CREDITS for list of people who contributed to this
# project.
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as
# published by the Free Software Foundation; either version 2 of
# the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place, Suite 330, Boston,
# MA 02111-1307 USA
#

HOSTARCH := $(shell uname -m | \
	sed -e s/i.86/i386/ \
	    -e s/sun4u/sparc64/ \
	    -e s/arm.*/arm/ \
	    -e s/sa110/arm/ \
	    -e s/powerpc/ppc/ \
	    -e s/macppc/ppc/)

HOSTOS := $(shell uname -s | tr A-Z a-z | \
	    sed -e 's/\(cygwin\).*/cygwin/')

export	HOSTARCH

# Deal with colliding definitions from tcsh etc.
VENDOR=

#########################################################################

TOPDIR_	:= $(shell if [ "$$PWD" != "" ]; then echo $$PWD; else pwd; fi)
TOPDIR	:= $(shell echo "$(TOPDIR_)"| sed -e "s/\:/\\\:/g")
export	TOPDIR

ifeq (include/config.mk,$(wildcard include/config.mk))
# load ARCH, BOARD, and CPU configuration
include include/config.mk
export	ARCH CPU BOARD VENDOR
# load other configuration
include $(TOPDIR)/config.mk

ifndef CROSS_COMPILE
CROSS_COMPILE = arm-none-linux-gnueabi-
#CROSS_COMPILE = arm-linux-
export	CROSS_COMPILE
endif

#########################################################################
# X-LOAD objects....order is important (i.e. start must be first)

OBJS  = cpu/$(CPU)/start.o
 

LIBS += board/$(BOARDDIR)/lib$(BOARD).a
LIBS += cpu/$(CPU)/lib$(CPU).a
LIBS += lib/lib$(ARCH).a
LIBS += fs/fat/libfat.a
LIBS += disk/libdisk.a
LIBS += drivers/libdrivers.a
LIBS += common/libcommon.a
.PHONY : $(LIBS)

# Add GCC lib
PLATFORM_LIBS += -L $(shell dirname `$(CC) $(CFLAGS) -print-libgcc-file-name`) -lgcc

SUBDIRS	=  
#########################################################################
#########################################################################

ALL = x-load.bin System.map

all:		$(ALL)

ift:	$(ALL) x-load.bin.ift

x-load.bin.ift: signGP System.map x-load.bin
	TEXT_BASE=`grep -w _start System.map|cut -d ' ' -f1`
	./signGP x-load.bin $(TEXT_BASE)
ifeq ($(CHIP_VER), GP)
	cp x-load.bin.ift MLO
	@echo OMAP4 GP version ...
else
	./generate_MLO $(CHIP_VER) x-load.bin
	@echo OMAP4 $(CHIP_VER) version ...
endif

 
x-load.bin:	x-load
		$(OBJCOPY) ${OBJCFLAGS} -O binary $< $@
 
x-load:	$(OBJS) $(LIBS) $(LDSCRIPT)
		UNDEF_SYM=`$(OBJDUMP) -x $(LIBS) |sed  -n -e 's/.*\(__u_boot_cmd_.*\)/-u\1/p'|sort|uniq`;\
 		$(LD) $(LDFLAGS) $$UNDEF_SYM $(OBJS) \
			--start-group $(LIBS) --end-group $(PLATFORM_LIBS) \
			-Map x-load.map -o x-load
 
$(LIBS):
		$(MAKE) -C `dirname $@`

  
System.map:	x-load
		@$(NM) $< | \
		grep -v '\(compiled\)\|\(\.o$$\)\|\( [aUw] \)\|\(\.\.ng$$\)\|\(LASH[RL]DI\)' | \
		sort > System.map

oneboot:	x-load.bin
		scripts/mkoneboot.sh

signGP:		scripts/signGP.c
		gcc -O3 -o signGP  $<

#########################################################################
else
all install x-load x-load.srec oneboot depend dep:
	@echo "System not configured - see README" >&2
	@ exit 1
endif

#########################################################################

unconfig:
	rm -f include/config.h include/config.mk

#========================================================================
# ARM
#========================================================================
#########################################################################
## OMAP4 (ARM-CortexA9) Systems
#########################################################################
cosmo_rev_b_config :    unconfig
	@./mkconfig $(@:_config=) arm omap4 cosmopolitan
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/cosmopolitan.h>" >>./include/config.h
	echo "#define CONFIG_COSMO_REV_B 1" >> ./include/config.h
	@[ -n "$(findstring _rev_b,$@)" ] || \
		{ echo "#define CONFIG_MPU_1000 1"	>>./include/config.h ; \
		  echo "MPU at 1GHz revision.." ; \
		}
	@[ -z "$(findstring _rev_b,$@)" ] || \
		{ echo "#define CONFIG_MPU_600 1"	>>./include/config.h ; \
		  echo "MPU at 600MHz revision.." ; \
		}

cosmo_rev_c_config :    unconfig
	@./mkconfig $(@:_config=) arm omap4 cosmopolitan
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/cosmopolitan.h>" >>./include/config.h
	echo "#define CONFIG_COSMO_REV_C 1" >> ./include/config.h
	@[ -n "$(findstring _rev_c,$@)" ] || \
		{ echo "#define CONFIG_MPU_1000 1"	>>./include/config.h ; \
		  echo "MPU at 1GHz revision.." ; \
		}
	@[ -z "$(findstring _rev_c,$@)" ] || \
		{ echo "#define CONFIG_MPU_600 1"	>>./include/config.h ; \
		  echo "MPU at 600MHz revision.." ; \
		}

cosmo_rev_d_config :    unconfig
	@./mkconfig $(@:_config=) arm omap4 cosmopolitan
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/cosmopolitan.h>" >>./include/config.h
	echo "#define CONFIG_COSMO_REV_D 1" >> ./include/config.h
	@[ -z "$(findstring _rev_d,$@)" ] || \
		{ echo "#define CONFIG_MPU_1000 1"	>>./include/config.h ; \
		  echo "MPU at 1GHz revision.." ; \
		}

cosmo_rev_e_config :    unconfig
	@./mkconfig $(@:_config=) arm omap4 cosmopolitan
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/cosmopolitan.h>" >>./include/config.h
	echo "#define CONFIG_COSMO_REV_E 1" >> ./include/config.h
	@[ -z "$(findstring _rev_e,$@)" ] || \
		{ echo "#define CONFIG_MPU_1000 1"	>>./include/config.h ; \
		  echo "MPU at 1GHz revision.." ; \
		}

cosmo_rev_1.0_config :    unconfig
	@./mkconfig $(@:_config=) arm omap4 cosmopolitan
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/cosmopolitan.h>" >>./include/config.h
	echo "#define CONFIG_COSMO_REV_10 1" >> ./include/config.h
	@[ -z "$(findstring _rev_1.0,$@)" ] || \
		{ echo "#define CONFIG_MPU_1000 1"	>>./include/config.h ; \
		  echo "MPU at 1GHz revision.." ; \
		}

cosmo_rev_1.1_config \
cosmo_rev_1.11_config :    unconfig
	@./mkconfig $(@:_config=) arm omap4 cosmopolitan
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/cosmopolitan.h>" >>./include/config.h
	echo "#define CONFIG_COSMO_REV_11 1" >> ./include/config.h
	@[ -z "$(findstring _rev_1.1,$@)" ] || \
		{ echo "#define CONFIG_MPU_1000 1"	>>./include/config.h ; \
		  echo "MPU at 1GHz revision.." ; \
		}

#LGE_CHANGE_DOMASTIC - start		
cosmo_su760_rev_a_config :    unconfig
	@./mkconfig $(@:_config=) arm omap4 cosmopolitan
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/cosmopolitan.h>" >>./include/config.h
	echo "#define CONFIG_COSMO_REV_C 1" >> ./include/config.h
	echo "#define CONFIG_COSMO_SU760 1" >> ./include/config.h
	@[ -z "$(findstring su760,$@)" ] || \
		{ echo "#define CONFIG_MPU_1000 1"	>>./include/config.h ; \
		  echo "MPU at 1GHz revision.." ; \
		}	
		
cosmo_su760_rev_b_config :    unconfig
	@./mkconfig $(@:_config=) arm omap4 cosmopolitan
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/cosmopolitan.h>" >>./include/config.h
	echo "#define CONFIG_COSMO_REV_D 1" >> ./include/config.h
	echo "#define CONFIG_COSMO_SU760 1" >> ./include/config.h
	@[ -z "$(findstring su760,$@)" ] || \
		{ echo "#define CONFIG_MPU_1000 1"	>>./include/config.h ; \
		  echo "MPU at 1GHz revision.." ; \
		}					
		
cosmo_su760_rev_d_config :    unconfig
	@./mkconfig $(@:_config=) arm omap4 cosmopolitan
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/cosmopolitan.h>" >>./include/config.h
	echo "#define CONFIG_COSMO_REV_11 1" >> ./include/config.h
	echo "#define CONFIG_COSMO_SU760 1" >> ./include/config.h
	@[ -z "$(findstring su760,$@)" ] || \
		{ echo "#define CONFIG_MPU_1000 1"	>>./include/config.h ; \
		  echo "MPU at 1GHz revision.." ; \
		}					
#LGE_CHANGE_DOMASTIC - end

cx2_evb_config \
cx2_evb_mipi_config :    unconfig
	@./mkconfig $(@:_config=) arm omap4 cx2
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/cx2.h>" >>./include/config.h
	echo "#define CONFIG_COSMO_EVB 1" >> ./include/config.h
	@[ -z "$(findstring cx2,$@)" ] || \
		{ echo "#define CONFIG_MPU_1000 1"	>>./include/config.h ; \
		  echo "MPU at 1GHz revision.." ; \
                }

cx2_rev_a_config \
cx2_rev_a_mipi_config :    unconfig
	@./mkconfig $(@:_config=) arm omap4 cx2
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/cx2.h>" >>./include/config.h
	echo "#define CONFIG_COSMO_REV_A 1" >> ./include/config.h
	@[ -z "$(findstring cx2,$@)" ] || \
		{ echo "#define CONFIG_MPU_1000 1"	>>./include/config.h ; \
		  echo "MPU at 1GHz revision.." ; \
                }

cx2_rev_b_config \
cx2_rev_b_mipi_config :    unconfig
	@./mkconfig $(@:_config=) arm omap4 cx2
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/cx2.h>" >>./include/config.h
	echo "#define CONFIG_COSMO_REV_B 1" >> ./include/config.h
	@[ -z "$(findstring cx2,$@)" ] || \
		{ echo "#define CONFIG_MPU_1000 1"	>>./include/config.h ; \
		  echo "MPU at 1GHz revision.." ; \
                }

cx2_rev_c_config \
cx2_rev_c_mipi_config :    unconfig
	@./mkconfig $(@:_config=) arm omap4 cx2
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/cx2.h>" >>./include/config.h
	echo "#define CONFIG_COSMO_REV_C 1" >> ./include/config.h
	@[ -z "$(findstring cx2,$@)" ] || \
		{ echo "#define CONFIG_MPU_1000 1"	>>./include/config.h ; \
		  echo "MPU at 1GHz revision.." ; \
                }

cx2_rev_d_config \
cx2_rev_d_mipi_config :    unconfig
	@./mkconfig $(@:_config=) arm omap4 cx2
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/cx2.h>" >>./include/config.h
	echo "#define CONFIG_COSMO_REV_D 1" >> ./include/config.h
	@[ -z "$(findstring cx2,$@)" ] || \
		{ echo "#define CONFIG_MPU_1000 1"	>>./include/config.h ; \
		  echo "MPU at 1GHz revision.." ; \
                }

cx2_rev_1.0_config \
cx2_rev_1.0_mipi_config :    unconfig
	@./mkconfig $(@:_config=) arm omap4 cx2
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/cx2.h>" >>./include/config.h
	echo "#define CONFIG_COSMO_REV_10 1" >> ./include/config.h
	@[ -z "$(findstring cx2,$@)" ] || \
		{ echo "#define CONFIG_MPU_1000 1"	>>./include/config.h ; \
		  echo "MPU at 1GHz revision.." ; \
                }

cx2_rev_1.1_config \
cx2_rev_1.11_config :    unconfig
	@./mkconfig $(@:_config=) arm omap4 cx2
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/cx2.h>" >>./include/config.h
	echo "#define CONFIG_COSMO_REV_11 1" >> ./include/config.h
	@[ -z "$(findstring cx2,$@)" ] || \
		{ echo "#define CONFIG_MPU_1000 1"	>>./include/config.h ; \
		  echo "MPU at 1GHz revision.." ; \
		}
		
cx2_su870_rev_a_config \
cx2_su870_rev_a_mipi_config :    unconfig
	@./mkconfig $(@:_config=) arm omap4 cx2
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/cx2.h>" >>./include/config.h
	echo "#define CONFIG_COSMO_REV_A 1" >> ./include/config.h
	echo "#define CONFIG_COSMO_SU870 1" >> ./include/config.h
	@[ -z "$(findstring cx2,$@)" ] || \
		{ echo "#define CONFIG_MPU_1000 1"	>>./include/config.h ; \
		  echo "MPU at 1GHz revision.." ; \
                }
cx2_su870_rev_b_config \
cx2_su870_rev_b_mipi_config : unconfig
	@./mkconfig $(@:_config=) arm omap4 cx2
	echo "/* Generarated file. Do not edit */" >./include/config.h
	echo "#include <configs/cx2.h>" >>./include/config.h
	echo "#define CONFIG_COSMO_REV_B 1" >> ./include/config.h;
	echo "#define CONFIG_COSMO_SU870 1" >> ./include/config.h
	@[ -z "$(findstring cx2,$@)" ] || \
		{ echo "#define CONFIG_MPU_1000 1"      >>./include/config.h ; \
	 	  echo "MPU at 1GHz revision.." ; \
		}
#########################################################################

clean:
	find . -type f \
		\( -name 'core' -o -name '*.bak' -o -name '*~' \
		-o -name '*.o'  -o -name '*.a'  \) -print \
		| xargs rm -f
 
clobber:	clean
	find . -type f \
		\( -name .depend -o -name '*.srec' -o -name '*.bin' \) \
		-print \
		| xargs rm -f
	rm -f $(OBJS) *.bak tags TAGS
	rm -fr *.*~
	rm -f x-load x-load.map $(ALL) x-load.bin.ift signGP MLO MLO.ch MLOb.ch MLOb MLOb_T32
	rm -f include/asm/proc include/asm/arch

mrproper \
distclean:	clobber unconfig

backup:
	F=`basename $(TOPDIR)` ; cd .. ; \
	gtar --force-local -zcvf `date "+$$F-%Y-%m-%d-%T.tar.gz"` $$F

#########################################################################
