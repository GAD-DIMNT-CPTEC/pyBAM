# fortran and fortran-to-python linker compiler
FC		:=	gfortran
F2PY	:=	f2py

# root directory for source code
# (relative to this one)
P       :=  $(shell pwd)
# @$(shell echo) $(P)
src	:=  $(WIM2D_PATH)/src
# @echo $(src)

# keep binaries here
bin := ../bin
lib := ../lib

# directory where objects are kept
# ODIR	:=	$(P)/objs
ODIR	:=	$(P)/objs

# directory where modules are put into
# MDIR	:=	$(P)/mods
MDIR	:=	$(P)/mods

# directory where include files are put into
# INCDIR	:=
INCDIR := $(SIGIOBAM)/include
LIBDIR := $(SIGIOBAM)/lib


# FCFLAGS=-O
# check for errors
FFLAGS := -fconvert=big-endian -I$(INCDIR)
LDFLAGS := $(LIBDIR) -lsigiobam

# include modules/headers from $(MDIR) or $(HDIR)
IFLAGS=-I$(MDIR) -I. -I$(INCDIR)

# Put modules in $(MDIR) when they are created
OFLAGS=-J$(MDIR)


## ============================================================================
## run in double precision
## - export WIM2D_TYPE=single to use single precision;
##   leave undefined or set to double (for example) to use double precision
#ifneq ($(WIM2D_TYPE),single)
#	FCFLAGS += -fdefault-real-8 -fdefault-double-8
#endif
# ============================================================================

# Flags for f2py
F2PY_FLAGS=--fcompiler=$(FC) --f77flags="$(FFLAGS)" --f90flags="$(FFLAGS)" -L$(LDFLAGS)

# fortran program teste
# - executable called by run_WIM2d.sh
#   (cd ../run; ./run_WIM2d.sh)
PROG_F := $(ODIR)/pythonBAM.o
TARG_F := pythonBAM.x

# fortran interface program
# - NB f2py needs the full path

PROG_PY := $(src)/pythonBAM.f90
SIGN_PY := pythonBAM.pyf
TARG_PY := pythonBAM$(shell python3-config --extension-suffix)

#
# Sources and objects
#
SRCS := \
	pythonBAM.f90    \

OBJS := \
	$(ODIR)/pythonBAM.o

# Create objects by compiling their respective .F and/or .f90 files
# (add dependency on header files also, so we recompile if headers change)
$(ODIR)/%.o:	%.f90
	@mkdir -p $(ODIR) $(MDIR)
	$(FC) -c -o $@ $< $(FCFLAGS) $(IFLAGS) $(OFLAGS)
$(ODIR)/%.o:	%.F
	@mkdir -p $(ODIR) $(MDIR)
	$(FC) -c -o $@ $< $(FCFLAGS) $(IFLAGS) $(OFLAGS)

# Link objects to make executable $(TARGET_F)
# (default)
all:	py
	
exec: $(PROG_F) $(OBJS)
	@echo " "
	@mkdir -p $(bin)
	$(FC) -o $(TARG_F) $^ $(FCFLAGS) $(IFLAGS)
	mv $(TARG_F) $(bin)
	@echo " "

# Link objects to make python module $(TARG_PY)
py: $(SRCS)
	@echo " "
	@mkdir -p $(lib)
	$(F2PY) -c $(SIGN_PY) $^ $(F2PY_FLAGS)
	mv $(TARG_PY) $(lib)
	@echo " "




# DEPENDENCIES
$(ODIR)/pythonBAM.o:	pythonBAM.f90

#
$(OBJ_MAIN):	$(OBJS)
$(PROG_PY):	$(OBJS)

.PHONY: clean vclean

# clean: keep executable, but delete modules and objects
clean:
	rm -fr $(ODIR)/*.o $(MDIR)/*.mod $(ODIR) $(MDIR)

# vclean: delete executable, and delete modules and objects
aclean:
	rm -fr $(ODIR)/*.o $(MDIR)/*.mod \
			 $(ODIR) $(MDIR)  \
			 $(bin) $(lib)    \
	   	 $(bin)/$(TARG_F) \
	   	 $(lib)/$(TARG_PY) 

# -I. include headers from "." directory;
# -L. include libraries from "." directory;
# $^ everything to the right of ":";
# $@ first on the left of ":";
# $< first on the right of ":";
# The .PHONY rule keeps make from doing something with a
# file named clean.

