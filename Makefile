# This Makefile is supposed to untar and create a GCC 4.x series cross compiler for MinGW.
# It currently fails while building GCC proper.
# It assumes that tarballs are available in a subdirectory of the current folder named "packages/"
# If you just do "make," it will untar those tarballs, name the folders appropriately, and try to
# ./configure; make in each one, in the proper order.

# Configuration variables.  Eventually, will have PREFIX and EPREFIX modified so that the cross-compiler gets
# installed as part of the main compiler, so you can just do "gcc -b i786-pc-mingw32 file.c" to compile.  For now,
# you need to do something like "/.../ebuild/bin/gcc file.c"
PREFIX=$(shell pwd)/build
EPREFIX=$(shell pwd)/ebuild
HOST=$(shell gcc -dumpmachine)
TARGET=i786-pc-mingw32

# VERSIONS:
VERSION_BINUTILS=2.18
VERSION_GCC=4.2.3
VERSION_W32API=3.11
VERSION_MINGW_RUNTIME=3.14

# TARBALLS - each of these tarballs represent necessary components
BINUTILS_TARBALL=packages/binutils-$(VERSION_BINUTILS).tar.bz2
GCC_CORE_TARBALL=packages/gcc-core-$(VERSION_GCC).tar.bz2
GCC_GPP_TARBALL=packages/gcc-g++-$(VERSION_GCC).tar.bz2
W32API_TARBALL=packages/w32api-$(VERSION_W32API)-src.tar.gz
MINGW_RUNTIME_TARBALL=packages/mingw-runtime-$(VERSION_MINGW_RUNTIME)-src.tar.gz

# Default target, "all". - builds compiler suite.
.PSEUDO : all
all : tarballs built/binutils built/gcc

# Clean-up target, "clean". - removes untarred source and all binaries
.PSEUDO : clean
clean : clean-src
	rm ebuild/$(TARGET)/sys-include
	rm -r -f gcc binutils ebuild build built

.PSEUDO : clean-src
clean-src : clean-src-gcc clean-src-binutils clean-src-w32api clean-src-mingw-runtime

.PSEUDO : clean-src-gcc
clean-src-gcc :
	-rm -r -f gcc

.PSUEDO : clean-src-binutils
clean-src-binutils :
	-rm -r -f binutils

.PSUEDO : clean-src-w32api
clean-src-w32api :
	-rm -r -f w32api

.PSUEDO : clean-src-mingw-runtime
clean-src-mingw-runtime	:
	-rm -r -f mingw-runtime

# Configure and build binutils.
built/binutils : built binutils
	echo `date` > built/binutils.start
	cd binutils ; ./configure --prefix=$(PREFIX) --exec-prefix=$(EPREFIX) --target=$(TARGET)
	make -C binutils
	make -C binutils install
	echo `date` > built/binutils

# Configure and build gcc.
built/gcc : built gcc w32api mingw-runtime $(EPREFIX)/$(TARGET)/sys-include
	echo `date` > built/gcc.start
	cd gcc ; ./configure --prefix=$(PREFIX) --exec-prefix=$(EPREFIX) --target=$(TARGET) --host=$(HOST)
	make -C gcc
	make -C gcc install
	echo gcc:`$(EPREFIX)/bin/($TARGET)-gcc -dumpmachine` `$(EPREFIX)/bin/($TARGET)-gcc -dumpversion`
	echo g++:`$(EPREFIX)/bin/($TARGET)-g++ -dumpmachine` `$(EPREFIX)/bin/($TARGET)-g++ -dumpversion`
	echo `date` > built/gcc

# Set up $(EPREFIX)/$(TARGET)/sys-include to be an include directory containing win32 and mingw-runtime headers.
$(EPREFIX)/$(TARGET)/sys-include : w32api mingw-runtime
	mkdir $(EPREFIX)/$(TARGET)/sys-include-tmp
	cp --recursive mingw-runtime/include/* $(EPREFIX)/$(TARGET)/sys-include-tmp
	cp --recursive w32api/include/* $(EPREFIX)/$(TARGET)/sys-include-tmp
	mv $(EPREFIX)/$(TARGET)/sys-include-tmp $(EPREFIX)/$(TARGET)/sys-include

built :
	mkdir built

# untar the binutils tarball, rename folder created to "./binutils/"
binutils : $(BINUTILS_TARBALL)
	tar -xjvf $(BINUTILS_TARBALL)
	mv binutils-$(VERSION_BINUTILS) binutils

# untar the gcc tarball, rename folder created to "./gcc/"
gcc : $(GCC_CORE_TARBALL) $(GCC_GPP_TARBALL)
	tar -xjvf $(GCC_CORE_TARBALL)
	tar -xjvf $(GCC_GPP_TARBALL)
	mv gcc-$(VERSION_GCC) gcc

# untar the w32api tarball, rename folder created to "./mingw/"
w32api : $(W32API_TARBALL)
	tar -xzvf $(W32API_TARBALL)
	mv w32api-$(VERSION_W32API) w32api

# untar the mingw-runtime tarball, rename folder created to "./mingw-runtime/"
mingw-runtime : $(MINGW_RUNTIME_TARBALL)
	tar -xzvf $(MINGW_RUNTIME_TARBALL)
	mv mingw-runtime-$(VERSION_MINGW_RUNTIME) mingw-runtime

.PHONY: tarballs
tarballs : $(BINUTILS_TARBALL) $(GCC_CORE_TARBALL) $(GCC_GPP_TARBALL) $(W32API_TARBALL) $(MINGW_RUNTIME_TARBALL) 

$(BINUTILS_TARBALL) : packages 
	if [ ! -f $@ ]; then \
		curl -L -o $@ http://ftp.gnu.org/gnu/binutils/$(notdir $(BINUTILS_TARBALL)) ; \
	fi

$(GCC_CORE_TARBALL) : packages
	if [ ! -f $@ ]; then \
		curl -L -o $@ http://ftp.gnu.org/gnu/gcc/gcc-$(VERSION_GCC)/$(notdir $(GCC_CORE_TARBALL)) ; \
	fi

$(GCC_GPP_TARBALL) : packages
	if [ ! -f $@ ]; then \
		curl -L -o $@ http://ftp.gnu.org/gnu/gcc/gcc-$(VERSION_GCC)/$(notdir $(GCC_GPP_TARBALL)) ; \
	fi

$(W32API_TARBALL) : packages
	if [ ! -f $@ ]; then \
		curl -L -o $@ http://sourceforge.net/projects/mingw/files/MinGW/Base/w32api/w32api-$(VERSION_W32API)/w32api-$(VERSION_W32API)-src.tar.gz/download ; \
	fi

$(MINGW_RUNTIME_TARBALL) : packages
	if [ ! -f $@ ]; then \
		curl -L -o $@ http://sourceforge.net/projects/mingw/files/MinGW/Base/mingw-rt/mingw-runtime-$(VERSION_MINGW_RUNTIME)/$(notdir $@)/download  ; \
	fi

packages :
	mkdir -p $@
