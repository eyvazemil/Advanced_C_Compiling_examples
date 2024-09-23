CC = gcc
CXX = g++
SRC_DIR = src
BUILD_DIR = Build

# Tool for dumping contents of the binary.
# Can be used to analyze object files/target binary.
OBJDUMP = objdump

# Tool for printing out the needed type of symbols in a given binary.
NM = nm

# Tool for reading segments/sections of ELF file.
READELF = readelf

# Archiver for bunling multiple object files into one static library.
STATIC_LIB_ARCHIVER = ar

# Flag that is passed to `gcc` to indicate that whatever flag comes after 
# `-Wl,` flag is passed directly to the linker, i.e. it will be a linker flag.
# Example: `-Wl,--whole-archive`, flag `--whole-archive` will be passed directly
# to the linker.
LINKER_FLAG = -Wl,

all: create_build_directory preprocessor_expansion_build elf_format_build \
	 static_library_build dynamic_library_building_build dynamic_linking_build dynamic_library_versioning_build

create_build_directory:
	@if [ ! -e $(BUILD_DIR) ]; then \
		mkdir $(BUILD_DIR); \
	fi

clean:
	rm -rf $(BUILD_DIR)

# ------------------------------------------------------------------------------------------
# -- Preprocessor expansion --
# ------------------------------------------------------------------------------------------
PREPROCESSOR_EXPANSION_DIR = $(SRC_DIR)/Preprocessor_Expansion
PREPROCESSOR_EXPANSION_BUILD_DIR = $(BUILD_DIR)/Preprocessor_Expansion

create_preprocessor_expansion_build_directory: create_build_directory
	@if [ ! -e $(PREPROCESSOR_EXPANSION_BUILD_DIR) ]; then \
		mkdir $(PREPROCESSOR_EXPANSION_BUILD_DIR); \
	fi

preprocessor_expansion_build: create_preprocessor_expansion_build_directory
	$(CC) -c $(PREPROCESSOR_EXPANSION_DIR)/preprocessor_expansion.c -o $(PREPROCESSOR_EXPANSION_BUILD_DIR)/preprocessor_expansion.o
	$(CC) -c $(PREPROCESSOR_EXPANSION_DIR)/main.c -o $(PREPROCESSOR_EXPANSION_BUILD_DIR)/main.o
	$(CC) $(PREPROCESSOR_EXPANSION_BUILD_DIR)/preprocessor_expansion.o $(PREPROCESSOR_EXPANSION_BUILD_DIR)/main.o -o \
		$(PREPROCESSOR_EXPANSION_BUILD_DIR)/preprocessor_expansion.out

# Creates a file that shows the code with evaluated macros and #ifdef statements.
# Option <-P> makes the output more readable, i.e. there is no overbloaded header.
test_preprocessor:
	$(CC) -E -P $(PREPROCESSOR_EXPANSION_DIR)/preprocessor_expansion.c -o $(PREPROCESSOR_EXPANSION_BUILD_DIR)/preprocessor_expansion.i

# Creates a file that contains an ASCII text version of the future assembly that this file will turn into.
# Has 2 formats (defined by <-masm> option): AT&T (-masm=att) and Intel (-masm=intel), the choice of which 
# is left to the programmer, as it is just a visual que.
test_assembling:
	$(CC) -S -masm=intel $(PREPROCESSOR_EXPANSION_DIR)/preprocessor_expansion.c -o $(PREPROCESSOR_EXPANSION_BUILD_DIR)/preprocessor_expansion.s

# Creates an object file, then dumps it via `objdump` tool.
test_create_object_and_dump:
	$(OBJDUMP) -D $(PREPROCESSOR_EXPANSION_BUILD_DIR)/preprocessor_expansion.o

# Object dumps exactly one section of the code, e.g. .bss .
# Symbols and their addresses can be found in `SYMBOL TABLE` part (close to the end of the output of `objdump`)
# which will contain `global_variable_zero` that got to the executable, when `preprocessor_expansion.o` got linked 
# into the target executable.
test_object_dump_section_bss:
	$(OBJDUMP) -x -j .bss $(PREPROCESSOR_EXPANSION_BUILD_DIR)/preprocessor_expansion.out

# Object dumps only the .data section. In this case, as `global_variable_negative` was initialized to the non-zero
# value, e.g. -1, it is located in .data section, instead of being located in .bss section.
test_object_dump_section_data:
	$(OBJDUMP) -x -j .data $(PREPROCESSOR_EXPANSION_BUILD_DIR)/preprocessor_expansion.out

test_symbols:
	$(NM) $(PREPROCESSOR_EXPANSION_BUILD_DIR)/preprocessor_expansion.out


# ------------------------------------------------------------------------------------------
# -- ELF format --
# ------------------------------------------------------------------------------------------
ELF_FORMAT_DIR = $(SRC_DIR)/ELF_Format
ELF_FORMAT_BUILD_DIR = $(BUILD_DIR)/ELF_Format

create_elf_format_build_directory: create_build_directory
	@if [ ! -e $(ELF_FORMAT_BUILD_DIR) ]; then \
		mkdir $(ELF_FORMAT_BUILD_DIR); \
	fi

# Create binary target with static linking.
elf_format_build: create_elf_format_build_directory
	$(CC) -c $(ELF_FORMAT_DIR)/main.c -o $(ELF_FORMAT_BUILD_DIR)/main.o
	$(CC) -static $(ELF_FORMAT_BUILD_DIR)/main.o -o $(ELF_FORMAT_BUILD_DIR)/elf_format.out

# Read the target binary file as an ELF file to find its entry point.
# If we dump the object text section of the target binary, we will see that there is a `_start`
# function in the object dump of the binary in the address that is indicates as an entry point 
# in the output of `readelf` tool.
# Entry address of the ELF binary can also be found via `readelf -h <binary-file>.out`, 
# which will output the header of the ELF file, which will include the entry point address. 
test_read_elf:
	$(READELF) --segments $(ELF_FORMAT_BUILD_DIR)/elf_format.out > $(ELF_FORMAT_BUILD_DIR)/readelf_segments_output.txt
	$(READELF) -h $(ELF_FORMAT_BUILD_DIR)/elf_format.out > $(ELF_FORMAT_BUILD_DIR)/readelf_header_output.txt
	$(OBJDUMP) -d -j .text $(ELF_FORMAT_BUILD_DIR)/elf_format.out > $(ELF_FORMAT_BUILD_DIR)/objdump_text_output.txt


# ------------------------------------------------------------------------------------------
# -- Static library --
# ------------------------------------------------------------------------------------------
STATIC_LIBRARY_DIR = $(SRC_DIR)/Static_Library
STATIC_LIBRARY_BUILD_DIR = $(BUILD_DIR)/Static_Library

create_static_library_build_directory: create_build_directory
	@if [ ! -e $(STATIC_LIBRARY_BUILD_DIR) ]; then \
		mkdir $(STATIC_LIBRARY_BUILD_DIR); \
	fi

static_library_build: create_static_library_build_directory
	$(CC) -c $(STATIC_LIBRARY_DIR)/first_file.c -o $(STATIC_LIBRARY_BUILD_DIR)/first_file.o
	$(CC) -c $(STATIC_LIBRARY_DIR)/second_file.c -o $(STATIC_LIBRARY_BUILD_DIR)/second_file.o
	$(CXX) -c $(STATIC_LIBRARY_DIR)/third_file.cpp -o $(STATIC_LIBRARY_BUILD_DIR)/third_file.o

# Archives the object files via `ar` into the static library. Static libraries, by convention,
# should have prefix `lib` and an extension `.a`.
# Flag <r> forces the passed object files to replace the previous ones if archive already existed.
# Flag <c> forces the creation of archive if it didn't exist before.
# Flag <s> adds indexing/sorting to the archive, so that functions could be accessed faster.
test_static_archive:
	$(STATIC_LIB_ARCHIVER) rcs $(STATIC_LIBRARY_BUILD_DIR)/libstaticlib.a $(STATIC_LIBRARY_BUILD_DIR)/first_file.o \
		$(STATIC_LIBRARY_BUILD_DIR)/second_file.o $(STATIC_LIBRARY_BUILD_DIR)/third_file.o

# Links static library with `main.c` file to build the target binary.
test_link_static_library: test_static_archive
	$(CC) $(STATIC_LIBRARY_DIR)/main.c $(STATIC_LIBRARY_BUILD_DIR)/libstaticlib.a -o $(STATIC_LIBRARY_BUILD_DIR)/static_library.out
	./$(STATIC_LIBRARY_BUILD_DIR)/static_library.out

# Link the whole static library with the target binary. We do this, as some object files that have no referenced 
# symbols by the target binary, won't be included to the target binary by default, thus we have to manually 
# pass flag to the linker that we want all object files from the given static library to be included into the 
# target binary.
# This is done via the linker flag `-Wl,--whole-archive <static-library-name>.a`. We follow this flag with 
# `-Wl,--no-whole-archive` to basically undo the linking of the whole archive for the next static libraries 
# that are listed, as these linker flags are sticky. 
# Linker flags that we pass to `gcc` start with `-Wl,`.
#
# The reason why we would want to link the whole archive could consist in a scenario, when one of the files in the 
# archive just creates a static global variable, that internally in the file, does something (e.g. in C++, calls a constructor 
# of the object that does something important internally) and none of the symbols from that file is used in target binary.
# In that case, without this flag, that file won't be linked against the target binary, as none of its symbols is used. 
# Nevertheless, that file could have been doing something important, but internally, through the initialization of that 
# global static variable. Thus, we have to use that flag, to include all the object files from the archive, regardless of the 
# usage of their symbols. This article nicely explains this situation:
# http://litaotju.github.io/c++/2020/07/24/Whole-Archive-in-static-lib/
test_link_whole_archive: test_static_archive
	$(CC) $(STATIC_LIBRARY_DIR)/main.c $(LINKER_FLAG)--whole-archive $(STATIC_LIBRARY_BUILD_DIR)/libstaticlib.a \
		$(LINKER_FLAG)--no-whole-archive -o $(STATIC_LIBRARY_BUILD_DIR)/static_library.out

	./$(STATIC_LIBRARY_BUILD_DIR)/static_library.out

# Another reason to link the whole archive is to create a shared library that links static library, during its building.
# If we link our target executable with the shared library `libsharedlib.so`, then we will be able to call all functions 
# that are exposed by all 3 object files inside static library `libstaticlib.a`.
# In case if we want to link the static library into the shared library on 64-bit Linux, we have to initially build that 
# static library with -fPIC flag, as we need it to kickstart the usage of 64-bit registers, instead of 32-bit ones, 
# when building that static library.
test_link_static_library_into_shared_library:
	$(CC) -fPIC -c $(STATIC_LIBRARY_DIR)/first_file.c -o $(STATIC_LIBRARY_BUILD_DIR)/first_file_fpic.o
	$(CC) -fPIC -c $(STATIC_LIBRARY_DIR)/second_file.c -o $(STATIC_LIBRARY_BUILD_DIR)/second_file_fpic.o
	$(CXX) -fPIC -c $(STATIC_LIBRARY_DIR)/third_file.cpp -o $(STATIC_LIBRARY_BUILD_DIR)/third_file_fpic.o

	$(STATIC_LIB_ARCHIVER) rcs $(STATIC_LIBRARY_BUILD_DIR)/libstaticlib_fpic.a $(STATIC_LIBRARY_BUILD_DIR)/first_file_fpic.o \
		$(STATIC_LIBRARY_BUILD_DIR)/second_file_fpic.o $(STATIC_LIBRARY_BUILD_DIR)/third_file_fpic.o

	$(CC) -shared $(LINKER_FLAG)--whole-archive $(STATIC_LIBRARY_BUILD_DIR)/libstaticlib_fpic.a \
		$(LINKER_FLAG)--no-whole-archive -o $(STATIC_LIBRARY_BUILD_DIR)/libsharedlib.so


# ------------------------------------------------------------------------------------------
# -- Dynamic library building --
# ------------------------------------------------------------------------------------------
DYNAMIC_LIBRARY_BUILDING_DIR = $(SRC_DIR)/Dynamic_Library_Building
DYNAMIC_LIBRARY_BUILDING_BUILD_DIR = $(BUILD_DIR)/Dynamic_Library_Building

create_dynamic_library_building_build_directory: create_build_directory
	@if [ ! -e $(DYNAMIC_LIBRARY_BUILDING_BUILD_DIR) ]; then \
		mkdir $(DYNAMIC_LIBRARY_BUILDING_BUILD_DIR); \
	fi

# We have to create object files with `-fPIC` flag if we want to create a 
# static/shared library out of those object files.
# By Linux convention the dynamic libraries are starting with prefix `lib`
# and have an extension `.so`. 
# `-fPIC`: is a compiler flag that tells the compiler to use Position Independent Code.
# `-shared`: is a linker flag, which tells the linker to create a shared library out of
# 			 the provided object files.
#
# `first_file.o` will have a file with the symbol of its `first_file_func()` without
# any name mangling, whereas `second_file.o`, due to not declaring a function prototype
# inside `extern "C" {}` block, will have a linker produced name mangled symbol.
dynamic_library_building_build: create_dynamic_library_building_build_directory \
				 $(DYNAMIC_LIBRARY_BUILDING_DIR)/first_file.h \
				 $(DYNAMIC_LIBRARY_BUILDING_DIR)/first_file.cpp \
				 $(DYNAMIC_LIBRARY_BUILDING_DIR)/second_file.h \
				 $(DYNAMIC_LIBRARY_BUILDING_DIR)/second_file.cpp
	$(CXX) -fPIC -c $(DYNAMIC_LIBRARY_BUILDING_DIR)/first_file.cpp -o $(DYNAMIC_LIBRARY_BUILDING_BUILD_DIR)/first_file.o
	$(CXX) -fPIC -c $(DYNAMIC_LIBRARY_BUILDING_DIR)/second_file.cpp -o $(DYNAMIC_LIBRARY_BUILDING_BUILD_DIR)/second_file.o
	$(CXX) -shared $(DYNAMIC_LIBRARY_BUILDING_BUILD_DIR)/first_file.o $(DYNAMIC_LIBRARY_BUILDING_BUILD_DIR)/second_file.o \
		-o $(DYNAMIC_LIBRARY_BUILDING_BUILD_DIR)/libsharedlib.so
	
#   Running `nm` with this flag below will show all symbols of this library and it will become 
# 	apparent that `first_file_func` will have no name mangled symbol done by the linker, although
#	`second_file_func` will have name mangled symbol done by the linker, 
#	e.g. its symbols may look like `_ZN9DynamicLibraryBuilding16second_file_funcEi` (also has namespace `DynamicLibraryBuilding` information).
	$(NM) --no-demangle $(DYNAMIC_LIBRARY_BUILDING_BUILD_DIR)/libsharedlib.so > $(DYNAMIC_LIBRARY_BUILDING_BUILD_DIR)/nm_name_mangling_result.txt

# By default, on Linux, all symbols of the given library are visible.
# We can set hidden visibility to all the symbols of the library via `-fvisibility=hidden` compiler flag or
# set `__attribute__ ((visibility("<default | hidden>")))` to the given symbol(s), where `default` makes that 
# symbol visible and `hidden` hides it.
test_symbols_visibility: dynamic_library_building_build
#	This `nm` command with `--extern-only` flag shows only the exported symbols, i.e. those that are defined with 
#	`__attribute__ ((visibility("default")))`. As we can see in `first_file.o`, there is `first_file_hidden_func()`, 
#	which has `hidden` visibility, thus that function's symbol won't be shown in the file generated by the command
# 	below, although you can find that function's symbols in the file produced by the `nm` command in the Makefile 
#	target `dynamic_library_building_build`.
#	Comman `nm` produces the name of the symbols, as long as its type, as you can see in the file produced by 
#	`nm` command in Makefile target `dynamic_library_building_build`, we have the type of the `first_file_func` being a capital
#	`T`, which means that that symbol is in the `.text` section and is exported, but the type of `first_file_hidden_func`
#	is `t`, which means that that symbols is in also in the `.text` section, but it is hidden. The types of the exported 
#	symbols are declared with capital letters, although the types of the hidden symbols are declared with non-capital letters.
	$(NM) --no-demangle --extern-only $(DYNAMIC_LIBRARY_BUILDING_BUILD_DIR)/libsharedlib.so > \
		$(DYNAMIC_LIBRARY_BUILDING_BUILD_DIR)/nm_symbols_visibility_result.txt

# Runs the `main()` function that loads the library, its symbols, references them, and closes that library.
# This is used to test the controller library loaded, when we control, when that library is loaded/unloaded,
# when and how its symbols are resolved and referenced.
test_controller_library_loading: dynamic_library_building_build \
								 $(DYNAMIC_LIBRARY_BUILDING_DIR)/dynamic_library_loader.h \
								 $(DYNAMIC_LIBRARY_BUILDING_DIR)/dynamic_library_loader.cpp \
								 $(DYNAMIC_LIBRARY_BUILDING_DIR)/main.cpp
	$(CXX) -c $(DYNAMIC_LIBRARY_BUILDING_DIR)/dynamic_library_loader.cpp -o $(DYNAMIC_LIBRARY_BUILDING_BUILD_DIR)/dynamic_library_loader.o

#	Due to the fact that `main.cpp` loads the library via `dlopen()` function, we don't have to supply the linker
#	a path to the library via `-L` flag and a library name via `-l` flag.
	$(CXX) $(DYNAMIC_LIBRARY_BUILDING_DIR)/main.cpp $(DYNAMIC_LIBRARY_BUILDING_BUILD_DIR)/dynamic_library_loader.o -o \
		$(DYNAMIC_LIBRARY_BUILDING_BUILD_DIR)/out
	
#	Run the target executable with the provided absolute path of the library.
	./$(DYNAMIC_LIBRARY_BUILDING_BUILD_DIR)/out $(DYNAMIC_LIBRARY_BUILDING_BUILD_DIR)/libsharedlib.so


# ------------------------------------------------------------------------------------------
# -- Dynamic library linking against target executable --
# ------------------------------------------------------------------------------------------
DYNAMIC_LINKING_DIR = $(SRC_DIR)/Dynamic_Linking
DYNAMIC_LINKING_BUILD_DIR = $(BUILD_DIR)/Dynamic_Linking
DYNAMIC_LINKING_DEPLOY_DIR = $(DYNAMIC_LINKING_BUILD_DIR)/Deploy
DYNAMIC_LINKING_LIBNAME = sharedlib

create_dynamic_linking_build_directory: create_build_directory
	@if [ ! -e $(DYNAMIC_LINKING_BUILD_DIR) ]; then \
		mkdir $(DYNAMIC_LINKING_BUILD_DIR); \
	fi; \
	\
	if [ ! -e $(DYNAMIC_LINKING_DEPLOY_DIR) ]; then \
		mkdir $(DYNAMIC_LINKING_DEPLOY_DIR); \
	fi

dynamic_linking_build: create_dynamic_linking_build_directory \
				 $(DYNAMIC_LINKING_DIR)/lib_file.h \
				 $(DYNAMIC_LINKING_DIR)/lib_file.cpp \
				 $(DYNAMIC_LINKING_DIR)/main.cpp
#	We can supply the "soname" of the library, i.e. the `lib<lib-name>.so.<major-version>`,
#	via linker flag `-soname`, as it is a linker flag, we have to precede it with `-Wl,`.
	$(CXX) -fPIC -c $(DYNAMIC_LINKING_DIR)/lib_file.cpp -o $(DYNAMIC_LINKING_BUILD_DIR)/lib_file.o
	$(CXX) -shared $(DYNAMIC_LINKING_BUILD_DIR)/lib_file.o $(LINKER_FLAG)-soname lib$(DYNAMIC_LINKING_LIBNAME).so.1 \
		-o $(DYNAMIC_LINKING_BUILD_DIR)/lib$(DYNAMIC_LINKING_LIBNAME).so.1.0.0

#	We can get the information about this library's soname via `readelf` command.
	$(READELF) -d $(DYNAMIC_LINKING_BUILD_DIR)/lib$(DYNAMIC_LINKING_LIBNAME).so.1.0.0 > \
		$(DYNAMIC_LINKING_BUILD_DIR)/readelf_library_soname_result.txt

#	Create the same library without any versioning and soname, as we will deal with 
#	library versioning in Dynamic Library Versioning.
	$(CXX) -fPIC -c $(DYNAMIC_LINKING_DIR)/lib_file.cpp -o $(DYNAMIC_LINKING_BUILD_DIR)/lib_file.o
	$(CXX) -shared $(DYNAMIC_LINKING_BUILD_DIR)/lib_file.o -o $(DYNAMIC_LINKING_BUILD_DIR)/lib$(DYNAMIC_LINKING_LIBNAME).so

#	There are linker flags for linking the dynamic library against the target binary, i.e. 
#	during the link time, and during the run time of the target binary:
#	* Linking the library against the target binary happens via providing path to the
#	  directory, where that library is located with `-L` linker flag and the name of the library 
#	  without preceeding `lib` and file extension `.so` with the version information, i.e. just the 
#	  library name itself, with `-l` linker flag. It is important to note that the name of the library
#	  that we pass via `-l` flag should not contain any path to it, as the value that we supply to the
#	  linker via `-l` flag will reside in the binary of the target binary itself.
#	* Linking the dynamic library in the run time of the target binary with `-R` linker flag.
#	  This way, we separate the directory, where the library is located, during the link
#	  time of it against the target binary via `-L` flag and the location of the library during
#	  the run time of the target binary via `-R` flag.
#	  Supplying the linker with `-R` flags forces the linker to create another field in the
#	  ELF binary format, which is `DT_RPATH`. This, so called, `rpath` is a path to the directory,
#	  where the library is located, during the run time of the target binary. `DT_RPATH` field is 
#	  quite outdated, thus another field also exists, which is `DT_RUNPATH`, which is prioritized above 
#	  the `DT_RPATH`. If we want to write the same path to both `DT_RUNPATH` and `DT_RPATH`,
#	  after supplying the `-R` flag, we also have to supply the `--enable-new-dtags` linker flag.
#	  The main difference between the `DT_RPATH` and `DT_RUNPATH` fields is that, when we supply
#	  only the `DT_RPATH` flag, i.e. we don't supply `--enable-new-dtags` linker flag,
#	  another way of indicating the library path via `LD_LIBRARY_PATH` environment variable
#	  is overlooked and not taken into account, whereas, when `DT_RUNPATH` field is set,
#	  it makes `DT_RPATH` field to be disregarded, i.e. its value isn't used, and it gives 
#	  priority to `LD_LIBRARY_PATH` environment variable, thus if the variable that we are linking
#	  is listed in `LD_LIBRARY_PATH` environment variable, then it will be taken from there and 
#	  only if it is not listed there, the path to that variable given via `DT_RUNPATH` field in ELF
#	  of the binary will be taken as the library path. Thus, `DT_RUNPATH` kills the tyranny of 
#	  `DT_RPATH` field and allows the path to be set via `LD_LIBRARY_PATH` environment variable.
#	  We can also path our ELF's `DT_RUNPATH` field after it has already been built via 
#	  `patchelf --set-rpath <one-or-more-colon-separated-paths> <executable>` command.
	$(CXX) $(DYNAMIC_LINKING_DIR)/main.cpp $(LINKER_FLAG)-L $(DYNAMIC_LINKING_BUILD_DIR) \
		$(LINKER_FLAG)-l $(DYNAMIC_LINKING_LIBNAME) $(LINKER_FLAG)-R $(DYNAMIC_LINKING_DEPLOY_DIR) \
		$(LINKER_FLAG)--enable-new-dtags -o $(DYNAMIC_LINKING_BUILD_DIR)/out
	
#	Move the shared library in the deployment directory, as our binary 
#	will look for the shared library there, due to that directory being 
#	passed as `-R` flag to the linker.
	@cp $(DYNAMIC_LINKING_BUILD_DIR)/lib$(DYNAMIC_LINKING_LIBNAME).so $(DYNAMIC_LINKING_DEPLOY_DIR)

	./$(DYNAMIC_LINKING_BUILD_DIR)/out

#	Read the ELF header of the target binary to see the values of `DT_RPATH` and `DT_RUNPATH` fields
#	via `readelf -d` command. We can see the runpath in the `(RUNPATH)` field in the resulting text file.
	$(READELF) -d $(DYNAMIC_LINKING_BUILD_DIR)/out > $(DYNAMIC_LINKING_BUILD_DIR)/readelf_runpath_results.txt


# ------------------------------------------------------------------------------------------
# -- Dynamic library versioning --
# ------------------------------------------------------------------------------------------
DYNAMIC_LIBRARY_VERSIONING_DIR = $(SRC_DIR)/Dynamic_Library_Versioning
DYNAMIC_LIBRARY_VERSIONING_BUILD_DIR = $(BUILD_DIR)/Dynamic_Library_Versioning
DYNAMIC_LIBRARY_VERSIONING_DEPLOY_DIR = $(DYNAMIC_LIBRARY_VERSIONING_BUILD_DIR)/Deploy
DYNAMIC_LIBRARY_VERSIONING_LIBNAME = sharedlib

# Soname based versioning variables.
DYNAMIC_LIBRARY_VERSIONING_SONAME_DIR = $(DYNAMIC_LIBRARY_VERSIONING_DIR)/Lib_Soname_Versioning
DYNAMIC_LIBRARY_VERSIONING_SONAME_BUILD_DIR = $(BUILD_DIR)/Dynamic_Library_Versioning/Soname
DYNAMIC_LIBRARY_VERSIONING_SONAME_DEPLOY_DIR = $(DYNAMIC_LIBRARY_VERSIONING_BUILD_DIR)/Deploy/Soname

# Version script based versioning variables.
DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_DIR = $(DYNAMIC_LIBRARY_VERSIONING_DIR)/Lib_Version_Script_Versioning

DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_BUILD_DIR = $(BUILD_DIR)/Dynamic_Library_Versioning/Version_Script
DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_BUILD_DIR = $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_BUILD_DIR)/Version_1
DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_BUILD_DIR = $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_BUILD_DIR)/Version_2

DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_DEPLOY_DIR = $(DYNAMIC_LIBRARY_VERSIONING_BUILD_DIR)/Deploy/Version_Script
DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_DEPLOY_DIR = $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_DEPLOY_DIR)/Version_1
DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_DEPLOY_DIR = $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_DEPLOY_DIR)/Version_2

create_dynamic_library_versioning_build_directory: create_build_directory
	@if [ ! -e $(DYNAMIC_LIBRARY_VERSIONING_BUILD_DIR) ]; then \
		mkdir $(DYNAMIC_LIBRARY_VERSIONING_BUILD_DIR); \
	fi; \
	\
	if [ ! -e $(DYNAMIC_LIBRARY_VERSIONING_DEPLOY_DIR) ]; then \
		mkdir $(DYNAMIC_LIBRARY_VERSIONING_DEPLOY_DIR); \
	fi; \
	\
	if [ ! -e $(DYNAMIC_LIBRARY_VERSIONING_SONAME_BUILD_DIR) ]; then \
		mkdir $(DYNAMIC_LIBRARY_VERSIONING_SONAME_BUILD_DIR); \
	fi; \
	\
	if [ ! -e $(DYNAMIC_LIBRARY_VERSIONING_SONAME_DEPLOY_DIR) ]; then \
		mkdir $(DYNAMIC_LIBRARY_VERSIONING_SONAME_DEPLOY_DIR); \
	fi; \
	\
	if [ ! -e $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_BUILD_DIR) ]; then \
		mkdir $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_BUILD_DIR); \
	fi; \
	\
	if [ ! -e $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_BUILD_DIR) ]; then \
		mkdir $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_BUILD_DIR); \
	fi; \
	\
	if [ ! -e $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_BUILD_DIR) ]; then \
		mkdir $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_BUILD_DIR); \
	fi; \
	\
	if [ ! -e $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_DEPLOY_DIR) ]; then \
		mkdir $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_DEPLOY_DIR); \
	fi; \
	\
	if [ ! -e $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_DEPLOY_DIR) ]; then \
		mkdir $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_DEPLOY_DIR); \
	fi; \
	\
	if [ ! -e $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_DEPLOY_DIR) ]; then \
		mkdir $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_DEPLOY_DIR); \
	fi


dynamic_library_versioning_build: create_dynamic_library_versioning_build_directory \
				 $(DYNAMIC_LIBRARY_VERSIONING_SONAME_DIR)/lib_file.h \
				 $(DYNAMIC_LIBRARY_VERSIONING_SONAME_DIR)/lib_file.cpp \
				 $(DYNAMIC_LIBRARY_VERSIONING_SONAME_DIR)/main.cpp
#	We can supply the "soname" of the library, i.e. the `lib<lib-name>.so.<major-version>`,
#	via linker flag `-soname`, as it is a linker flag, we have to precede it with `-Wl,`.
	$(CXX) -fPIC -c $(DYNAMIC_LIBRARY_VERSIONING_SONAME_DIR)/lib_file.cpp -o $(DYNAMIC_LIBRARY_VERSIONING_SONAME_BUILD_DIR)/lib_file.o
	$(CXX) -shared $(DYNAMIC_LIBRARY_VERSIONING_SONAME_BUILD_DIR)/lib_file.o $(LINKER_FLAG)-soname lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so.1 \
		-o $(DYNAMIC_LIBRARY_VERSIONING_SONAME_BUILD_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so.1.0.0

#	We can get the information about this library's soname via `readelf` command.
#	The soname will be written in the `(SONAME)` field of the ELF file format of the library.
	$(READELF) -d $(DYNAMIC_LIBRARY_VERSIONING_SONAME_BUILD_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so.1.0.0 > \
		$(DYNAMIC_LIBRARY_VERSIONING_SONAME_BUILD_DIR)/readelf_library_soname_result.txt

#	Due to the fact, that, when linking the library against the target binary, we have to provide 
#	the name of the library without the prefix `lib` and `.so` extension along with the version number,
#	we should create a 2 symbolic links:
#	1) Symbolic link with the name of the library along with only the major version, which points
#	   to the exact version of the library that we are using.
#	2) Symbolic link with only the name of the library without any version information, which
#	   points to the symbolic link with the major version in its name, i.e. to the link from 1).
#	Thus, we have to create these 2 symbolic links.
# 	With the softlinks, we don't have to rebuild the binary every time the minor changes or patches are made.
#	The paths that softlinks are pointing to are given as absolute paths.
	@ln -s -f $$(eval pwd)/$(DYNAMIC_LIBRARY_VERSIONING_SONAME_BUILD_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so.1.0.0 \
		$(DYNAMIC_LIBRARY_VERSIONING_SONAME_BUILD_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so.1; \
	\
	ln -s -f $$(eval pwd)/$(DYNAMIC_LIBRARY_VERSIONING_SONAME_BUILD_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so.1 \
		$(DYNAMIC_LIBRARY_VERSIONING_SONAME_BUILD_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so

	$(CXX) $(DYNAMIC_LIBRARY_VERSIONING_SONAME_DIR)/main.cpp $(LINKER_FLAG)-L $(DYNAMIC_LIBRARY_VERSIONING_SONAME_BUILD_DIR) \
		$(LINKER_FLAG)-l $(DYNAMIC_LIBRARY_VERSIONING_LIBNAME) $(LINKER_FLAG)-R $(DYNAMIC_LIBRARY_VERSIONING_SONAME_DEPLOY_DIR) \
		$(LINKER_FLAG)--enable-new-dtags -o $(DYNAMIC_LIBRARY_VERSIONING_SONAME_BUILD_DIR)/out

#	When the given library is linked against the target binary with `-soname` linker flag, 
#	the linker embeds the soname of that library into the ELF format of that target binary
#	under `(NEEDED)` field.	
#	We can get the soname of the library that this target binary requires via `readelf` command.
	$(READELF) -d $(DYNAMIC_LIBRARY_VERSIONING_SONAME_BUILD_DIR)/out > \
		$(DYNAMIC_LIBRARY_VERSIONING_SONAME_BUILD_DIR)/readelf_binary_linked_library_soname_result.txt
	
#	Due to the fact that we have provided a deployment directory with `-R` linker flag,
#	we have to have our library there, but, as we provided a soname of our library and 
#	it now resides in the ELF header of our target binary, we have to create a symbolic
#	link in the deployment directory that would point to the symbolic link with the soname 
#	in the build directory. We don't do it with the second symbolic link (the one without
#	any versioning information), as it is only needed to find the library during linking of
#	the library with our target binary in build time.
#	Thus, we first copy the library to its runtime location, then we create a soname symbolic link to it.
	@cp $(DYNAMIC_LIBRARY_VERSIONING_SONAME_BUILD_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so.1.0.0 $(DYNAMIC_LIBRARY_VERSIONING_SONAME_DEPLOY_DIR); \
	\
	cp $(DYNAMIC_LIBRARY_VERSIONING_SONAME_BUILD_DIR)/out $(DYNAMIC_LIBRARY_VERSIONING_SONAME_DEPLOY_DIR); \
	\
	ln -s -f $$(eval pwd)/$(DYNAMIC_LIBRARY_VERSIONING_SONAME_DEPLOY_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so.1.0.0 \
		$(DYNAMIC_LIBRARY_VERSIONING_SONAME_DEPLOY_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so.1

	./$(DYNAMIC_LIBRARY_VERSIONING_SONAME_DEPLOY_DIR)/out


# Aside from versioning of the library based on the soname, we can also use the so-called 
# "version script" along with `.symver` directive in the library code to provide information
# on which symbol should be used by the target binary that was linked against a given version
# of this library.
# In this case, we will have 2 different copies of the library in its 2 different versions alongside
# with binaries that will be linked against a particular version.
test_symbols_versioning_first_version: create_dynamic_library_versioning_build_directory \
						 $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_DIR)/Version_1/lib_file.h \
						 $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_DIR)/Version_1/lib_file.cpp \
						 $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_DIR)/Version_1/main.cpp
#	---------------------
#	--- First version ---
#	---------------------
#
#	* Linux Version Script:
#		We have a version script `version_script.map`, which exports `lib_file_func_1()`
#		and `lib_file_func_2()` functions, as those are declared in `global` and makes 
#		`lib_file_func_3()` hidden, as it is declared in `local`.
#		This way, we don't even have to write `__attribute__((visibility("default" | "hidden")))
#		due to the fact that version script already has this information.
#		The library is declared using capital letters with its full name, in our case `LIBSHAREDLIB_1.0.0`.
#		This is just a convention, as names of the libraries don't play much of a role in the version script,
#		as an important information is when a given symbol was added to the version script, which was used to build
#		that dynamic library.
#		Version script is passed to the library, when it is being built via `--version-script` linker flag.
#
#	* `.symver` directive:
#		Defines which exact function should be used for the given symbol, depending on the library version defined 
#		in the version script.
#		Defined as `__asm__(".symver <exact-function-to-defer-to>, <symbol-name>@<library-name-from-version-script>");` 
#		right before the function definition in the source file (not in the header file). If we have two `@@` it means,
#		that the function `exact-function-to-defer-to` is going to be a default function that will be executed, when 
#		a target binary, that was linked with the library version indicated in `library-name-from-version-script`, references
#		the symbol `symbol-name`.
#		In case if we have more of the functions to defer to based of the library version for the given symbol, we should use 
#		one `@` instead of two `@@` in `.symver` directive.
#
#		In case if you are not sure which of the symbol versions is the default one, try building the library with only 
#		version script and no `.symver` directive and check via `readelf --symbols` what is indicated as a default version
#		of the symbols. In the example below, the default version is indicated as `@@LIBSHAREDLIB_1.0.0`, i.e. with two `@@`.
#
#		In this case, we have functions `lib_file_func_1()` and `lib_file_func_2()` the symbols of which defer to themselves,
#		as this is the first version of the library, thus there is no different implementation of this function in any other version.
	$(CXX) -fPIC -c $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_DIR)/Version_1/lib_file.cpp -o \
		$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_BUILD_DIR)/lib_file.o
	
	$(CXX) -shared $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_BUILD_DIR)/lib_file.o $(LINKER_FLAG)--version-script \
		$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_DIR)/Version_1/version_script.map -o \
		$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_BUILD_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so.1.0.0

#	Copy the library into the deployment directory.
	@cp $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_BUILD_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so.1.0.0 \
		$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_DEPLOY_DIR)

#	We can now find these symbols via `readelf --symbols` command.
#	Symbols of `lib_file_func_1()` and `lib_file_func_2()` are exported, as those are declared in the
#	`global` section of the version script, whereas `lib_file_func_3()` doesn't get exported, as it is
#	declared in the `local` section of the version script.
	$(READELF) --symbols $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_BUILD_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so.1.0.0 > \
		$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_BUILD_DIR)/readelf_symbols.txt

#	We can see the symbols and their versions that our library requires and exports by itself via
#	`readelf -V` command. Required symbols are in `.gnu.version_r` section and exported symbols
#	are in `.gnu.version_d` section.
	$(READELF) -V $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_BUILD_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so.1.0.0 > \
		$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_BUILD_DIR)/readelf_required_and_exported_symbols.txt

#	Create a symbolic link to the library, so that we could supply it to the linker via `-l` flag.
	@ln -s -f $$(eval pwd)/$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_BUILD_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so.1.0.0 \
		$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_BUILD_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so

#	Build target binary, based on the current version of the library.
#	We supply the include directory via `-I` flag.
	$(CXX) -c $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_DIR)/Version_1/main.cpp -I \
		$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_DIR)/Version_1/ -o \
		$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_BUILD_DIR)/main.o

	$(CXX) $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_BUILD_DIR)/main.o $(LINKER_FLAG)-L \
		$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_BUILD_DIR) $(LINKER_FLAG)-l $(DYNAMIC_LIBRARY_VERSIONING_LIBNAME) \
		$(LINKER_FLAG)-R $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_DEPLOY_DIR) $(LINKER_FLAG)--enable-new-dtags \
		-o $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_BUILD_DIR)/out

#	Copy the target binary into the deployment directory and create a symbolic link to it,
#	so that the target binary could load the library.
	@ln -s -f $$(eval pwd)/$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_DEPLOY_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so.1.0.0 \
		$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_DEPLOY_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so; \
	\
	cp $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_BUILD_DIR)/out $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_DEPLOY_DIR)

	./$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_DEPLOY_DIR)/out


test_symbols_versioning_second_version: test_symbols_versioning_first_version \
						 $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_DIR)/Version_2/lib_file.h \
						 $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_DIR)/Version_2/lib_file.cpp \
						 $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_DIR)/Version_2/main.cpp
#	----------------------
#	--- Second version ---
#	----------------------
#
#	* Linux Version Script:
#		We add another major version of the library, which has symbol `LIBSHAREDLIB_2.0.0`.
#		For this version, we export the `lib_file_func_1`, thus `lib_file_func_2` will be used
#		from the previous version of the library, i.e. from `LIBSHAREDLIB_1.0.0`.
#
#	* `.symver` directive:
#		New version of the library changed the signature and implementation of `lib_file_func_1` function.
#		Thus, now the new signature is the default one, thus defined with two `@@` in the `.symver` directive
#		and the old signature, which is used in the target binary that was linked against the old version of
#		this library, is defined with one `@` in the `.symver` directive.
	$(CXX) -fPIC -c $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_DIR)/Version_2/lib_file.cpp -o \
		$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_BUILD_DIR)/lib_file.o
	
	$(CXX) -shared $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_BUILD_DIR)/lib_file.o $(LINKER_FLAG)--version-script \
		$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_DIR)/Version_2/version_script.map -o \
		$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_BUILD_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so.2.0.0

#	Copy the library into the deployment directory.
	@cp $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_BUILD_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so.2.0.0 \
		$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_DEPLOY_DIR)

#	Read the symbols of this library via `readelf --symbols` command.
#	It shows that now, we have 2 versions of `lib_file_func_1`: one that is default defined with 
#	`@@LIBSHAREDLIB_2.0.0` and another one defined for the target binaries that use the older version 
#	of this library, defined with `@LIBSHAREDLIB_1.0.0`.
	$(READELF) --symbols $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_BUILD_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so.2.0.0 > \
		$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_BUILD_DIR)/readelf_symbols.txt

#	Create a symbolic link to the library, so that we could supply it to the linker via `-l` flag.
	@ln -s -f $$(eval pwd)/$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_BUILD_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so.2.0.0 \
		$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_BUILD_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so

#	Build target binary, based on the current version of the library.
#	We supply the include directory via `-I` flag. In order to use the right signature of `lib_file_func_1()`
#	library function, we define `LIBSHAREDLIB_MAJOR_VERSION_2` macro in build time.
	$(CXX) -c -D LIBSHAREDLIB_MAJOR_VERSION_2 $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_DIR)/Version_2/main.cpp -I \
		$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_DIR)/Version_2/ -o \
		$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_BUILD_DIR)/main.o

	$(CXX) $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_BUILD_DIR)/main.o $(LINKER_FLAG)-L \
		$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_BUILD_DIR) $(LINKER_FLAG)-l $(DYNAMIC_LIBRARY_VERSIONING_LIBNAME) \
		$(LINKER_FLAG)-R $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_DEPLOY_DIR) $(LINKER_FLAG)--enable-new-dtags \
		-o $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_BUILD_DIR)/out

#	Copy the target binary into the deployment directory and create a symbolic link to it,
#	so that the target binary could load the library.
	@ln -s -f $$(eval pwd)/$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_DEPLOY_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so.2.0.0 \
		$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_DEPLOY_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so; \
	\
	cp $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_BUILD_DIR)/out $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_DEPLOY_DIR)

# 	By running the target binary that uses the first library version and a target binary that uses
#	the new library version, we can see that both produce different results based on the actual function
#	that is being called, when referencing the same symbol.
#	But, first, in order to test that, we have to substitute the old library, in the deployment directory
#	of the first target binary, with the new one. Thus, we copy the new library there and set a symbolic link
#	to point to it.
	@cp $(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_BUILD_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so.2.0.0 \
		$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_DEPLOY_DIR); \
	\
	ln -s -f $$(eval pwd)/$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_DEPLOY_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so.2.0.0 \
		$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_DEPLOY_DIR)/lib$(DYNAMIC_LIBRARY_VERSIONING_LIBNAME).so

#	As we can see, now, the first target binary that used the first version of the library, now uses the second
#	version of this library, but the results are the same as in the first version of the library, due to the 
#	correct symbols versioning.
	./$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_1_DEPLOY_DIR)/out
	./$(DYNAMIC_LIBRARY_VERSIONING_VERSION_SCRIPT_2_DEPLOY_DIR)/out

