#
#   framework.make
#
#   Makefile rules to build GNUstep-based frameworks.
#
#   Copyright (C) 2000 Free Software Foundation, Inc.
#
#   Author: Mirko Viviani <mirko.viviani@rccr.cremona.it>
#
#   This file is part of the GNUstep Makefile Package.
#
#   This library is free software; you can redistribute it and/or
#   modify it under the terms of the GNU General Public License
#   as published by the Free Software Foundation; either version 2
#   of the License, or (at your option) any later version.
#   
#   You should have received a copy of the GNU General Public
#   License along with this library; see the file COPYING.LIB.
#   If not, write to the Free Software Foundation,
#   59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

# prevent multiple inclusions
ifeq ($(FRAMEWORK_MAKE_LOADED),)
FRAMEWORK_MAKE_LOADED=yes

#
# Include in the common makefile rules
#
include $(GNUSTEP_MAKEFILES)/rules.make

# The name of the bundle is in the FRAMEWORK_NAME variable.
# The list of framework resource files are in xxx_RESOURCE_FILES
# The list of framework web server resource files are in
#    xxx_WEBSERVER_RESOURCE_FILES
# The list of localized framework resource files is in
#    xxx_LOCALIZED_RESOURCE_FILES
# The list of localized framework web server resource files is in
#    xxx_LOCALIZED_WEBSERVER_RESOURCE_FILES
# The list of framework GSWeb components are in xxx_COMPONENTS
# The list of languages the framework supports is in xxx_LANGUAGES
# The list of framework resource directories are in xxx_RESOURCE_DIRS
# The list of framework subprojects directories are in xxx_SUBPROJECTS
# The list of framework tools directories are in xxx_TOOLS
# The name of the principal class is xxx_PRINCIPAL_CLASS
# The header files are in xxx_HEADER_FILES
# The list of framework web server resource directories are in
#    xxx_WEBSERVER_RESOURCE_DIRS
# The list of localized framework web server GSWeb components are in
#    xxx_LOCALIZED_WEBSERVER_RESOURCE_DIRS
# xxx_CURRENT_VERSION_NAME is the compiled version name (default "A")
# xxx_DEPLOY_WITH_CURRENT_VERSION deploy with current version or not (default
#     "yes")
#
# where xxx is the framework name
#

DERIVED_SOURCES = derived_src
ADDITIONAL_INCLUDE_DIRS += -I$(DERIVED_SOURCES)


ifeq ($(INTERNAL_framework_NAME),)
# This part is included the first time make is invoked.

internal-all:: $(FRAMEWORK_NAME:=.all.framework.variables)

internal-install:: all $(FRAMEWORK_NAME:=.install.framework.variables)

internal-uninstall:: $(FRAMEWORK_NAME:=.uninstall.framework.variables)

internal-clean:: $(FRAMEWORK_NAME:=.clean.framework.variables)

internal-distclean:: $(FRAMEWORK_NAME:=.distclean.framework.variables)

$(FRAMEWORK_NAME):
	@$(MAKE) -f $(MAKEFILE_NAME) --no-print-directory --no-keep-going \
		$@.all.framework.variables

else
# This part gets included the second time make is invoked.

ALL_FRAMEWORK_LIBS = $(FRAMEWORK_LIBS)

ALL_FRAMEWORK_LIBS := \
    $(shell $(WHICH_LIB_SCRIPT) $(LIB_DIRS_NO_SYSTEM) $(ALL_FRAMEWORK_LIBS) \
	debug=$(debug) profile=$(profile) shared=$(shared) libext=$(LIBEXT) \
	shared_libext=$(SHARED_LIBEXT))


DUMMY_FRAMEWORK = NSFramework_$(INTERNAL_framework_NAME)
DUMMY_FRAMEWORK_FILE = $(DERIVED_SOURCES)/$(DUMMY_FRAMEWORK).m
DUMMY_FRAMEWORK_OBJ_FILE = $(addprefix $(GNUSTEP_OBJ_DIR)/,$(DUMMY_FRAMEWORK).o)

FRAMEWORK_HEADER_FILES := $(patsubst %.h,$(FRAMEWORK_VERSION_DIR_NAME)/Headers/%.h,$(HEADER_FILES))


ifneq ($(BUILD_DLL),yes)

FRAMEWORK_CURRENT_DIR_NAME := $(FRAMEWORK_DIR_NAME)/Versions/Current
FRAMEWORK_LIBRARY_DIR_NAME := $(FRAMEWORK_VERSION_DIR_NAME)/$(GNUSTEP_TARGET_LDIR)
FRAMEWORK_CURRENT_LIBRARY_DIR_NAME := $(FRAMEWORK_CURRENT_DIR_NAME)/$(GNUSTEP_TARGET_LDIR)

FRAMEWORK_LIBRARY_FILE = lib$(INTERNAL_framework_NAME)$(SHARED_LIBEXT)
FRAMEWORK_LIBRARY_FILE_EXT     = $(SHARED_LIBEXT)
VERSION_FRAMEWORK_LIBRARY_FILE = $(FRAMEWORK_LIBRARY_FILE).$(VERSION)
SOVERSION             = $(word 1,$(subst ., ,$(VERSION)))
SONAME_FRAMEWORK_FILE = $(FRAMEWORK_LIBRARY_FILE).$(SOVERSION)

FRAMEWORK_FILE := $(FRAMEWORK_LIBRARY_DIR_NAME)/$(VERSION_FRAMEWORK_LIBRARY_FILE)

else # BUILD_DLL

FRAMEWORK_FILE     = $(INTERNAL_framework_NAME)$(FRAMEWORK_NAME_SUFFIX)$(DLL_LIBEXT)
FRAMEWORK_FILE_EXT = $(DLL_LIBEXT)
DLL_NAME         = $(shell echo $(LIBRARY_FILE)|cut -b 4-)
DLL_EXP_LIB      = $(INTERNAL_framework_NAME)$(FRAMEWORK_NAME_SUFFIX)$(SHARED_LIBEXT)
DLL_EXP_DEF      = $(INTERNAL_framework_NAME)$(FRAMEWORK_NAME_SUFFIX).def

ifeq ($(DLL_INSTALLATION_DIR),)
  DLL_INSTALLATION_DIR = \
    $(GNUSTEP_TOOLS)/$(GNUSTEP_TARGET_LDIR)
endif

endif # BUILD_DLL

ifeq ($(WITH_DLL),yes)
TTMP_LIBS := $(ALL_FRAMEWORK_LIBS)
TTMP_LIBS := $(filter -l%, $(TTMP_LIBS))
# filter all non-static libs (static libs are those ending in _ds, _s, _ps..)
TTMP_LIBS := $(filter-out -l%_ds, $(TTMP_LIBS))
TTMP_LIBS := $(filter-out -l%_s,  $(TTMP_LIBS))
TTMP_LIBS := $(filter-out -l%_dps,$(TTMP_LIBS))
TTMP_LIBS := $(filter-out -l%_ps, $(TTMP_LIBS))
# strip away -l, _p and _d ..
TTMP_LIBS := $(TTMP_LIBS:-l%=%)
TTMP_LIBS := $(TTMP_LIBS:%_d=%)
TTMP_LIBS := $(TTMP_LIBS:%_p=%)
TTMP_LIBS := $(TTMP_LIBS:%_dp=%)
TTMP_LIBS := $(shell echo $(TTMP_LIBS)|tr '-' '_')
TTMP_LIBS := $(TTMP_LIBS:%=-Dlib%_ISDLL=1)
ALL_CPPFLAGS += $(TTMP_LIBS)
FRAMEWORK_OBJ_EXT = $(DLL_LIBEXT)
endif # WITH_DLL

internal-framework-all:: before-$(TARGET)-all $(GNUSTEP_OBJ_DIR) \
		build-framework-dir build-framework \
		after-$(TARGET)-all

before-$(TARGET)-all:: $(FRAMEWORK_HEADER_FILES)

after-$(TARGET)-all::

FRAMEWORK_RESOURCE_DIRS = $(foreach d, $(RESOURCE_DIRS), $(FRAMEWORK_VERSION_DIR_NAME)/Resources/$(d))
FRAMEWORK_WEBSERVER_RESOURCE_DIRS =  $(foreach d, $(WEBSERVER_RESOURCE_DIRS), $(FRAMEWORK_VERSION_DIR_NAME)/WebServerResources/$(d))

ifeq ($(strip $(COMPONENTS)),)
  override COMPONENTS=""
endif
ifeq ($(strip $(RESOURCE_FILES)),)
  override RESOURCE_FILES=""
endif
ifeq ($(strip $(WEBSERVER_RESOURCE_FILES)),)
  override WEBSERVER_RESOURCE_FILES=""
endif
ifeq ($(strip $(LOCALIZED_RESOURCE_FILES)),)
  override LOCALIZED_RESOURCE_FILES=""
endif
ifeq ($(strip $(LOCALIZED_WEBSERVER_RESOURCE_FILES)),)
  override LOCALIZED_WEBSERVER_RESOURCE_FILES=""
endif
ifeq ($(strip $(LANGUAGES)),)
  override LANGUAGES="English"
endif
ifeq ($(FRAMEWORK_INSTALL_DIR),)
  FRAMEWORK_INSTALL_DIR := $(GNUSTEP_FRAMEWORKS)
endif


build-framework-dir::
	@$(MKDIRS) \
		$(FRAMEWORK_LIBRARY_DIR_NAME) \
		$(FRAMEWORK_VERSION_DIR_NAME)/Resources \
		$(FRAMEWORK_RESOURCE_DIRS)
	@(if [ "$(DEPLOY_WITH_CURRENT_VERSION)" = "yes" ]; then \
	  rm -f $(FRAMEWORK_DIR_NAME)/Versions/Current; \
	fi;)
	@(cd $(FRAMEWORK_DIR_NAME)/Versions; \
	if test ! -L "Current"; then \
	  $(LN_S) $(CURRENT_VERSION_NAME) Current; \
	fi;)
	@(cd $(FRAMEWORK_DIR_NAME); \
	if test ! -L "Resources"; then \
	  $(LN_S) Versions/Current/Resources .; \
	fi;)

build-framework-headers:: build-framework-dir $(DERIVED_SOURCES) $(FRAMEWORK_HEADER_FILES)

$(FRAMEWORK_HEADER_FILES):: $(HEADER_FILES) 
	if [ "$(HEADER_FILES)" != "" ]; then \
	  $(MKDIRS) $(FRAMEWORK_VERSION_DIR_NAME)/Headers; \
	  if test ! -L "$(DERIVED_SOURCES)/$(INTERNAL_framework_NAME)"; then \
	    $(LN_S) ../$(FRAMEWORK_DIR_NAME)/Headers \
	    $(DERIVED_SOURCES)/$(INTERNAL_framework_NAME); \
	  fi; \
	  if test ! -L "$(FRAMEWORK_DIR_NAME)/Headers"; then \
	    $(LN_S) Versions/Current/Headers $(FRAMEWORK_DIR_NAME); \
	  fi; \
	  for file in $(HEADER_FILES) __done; do \
	    if [ $$file != __done ]; then \
	      $(INSTALL_DATA) ./$$file \
	      $(FRAMEWORK_VERSION_DIR_NAME)/Headers/$$file ; \
	    fi; \
	  done; \
	fi;

$(DERIVED_SOURCES) :
	$(MKDIRS) $@

$(DUMMY_FRAMEWORK_FILE): $(DERIVED_SOURCES) $(C_OBJ_FILES) $(OBJC_OBJ_FILES) $(SUBPROJECT_OBJ_FILES) $(OBJ_FILES) GNUmakefile
	@(if [ "$(OBJC_OBJ_FILES)" != "" ]; then objcfiles="$(OBJC_OBJ_FILES)"; \
	fi; \
	if [ "$(SUBPROJECT_OBJ_FILES)" != "" ]; then objcfiles="$$objcfiles $(SUBPROJECT_OBJ_FILES)"; \
	fi; \
	if [ "$$objcfiles" = "" ]; then objcfiles="__dummy__"; \
	fi;\
	classes=""; \
	if [ "$$objcfiles" != "__dummy__" ]; then \
	  for f in $$objcfiles; do \
	    sym=`nm -Pg $$f | awk '/__objc_class_name_/ {if($$2 == "$(OBJC_CLASS_SECTION)") print $$1}' | sed 's/__objc_class_name_//'`; \
	    classes="$$classes $$sym"; \
	  done; \
	fi; \
	first="yes"; \
	if [ "$$classes" = "" ]; then classes="__dummy__"; \
	fi;\
	if [ "$$classes" != "__dummy__" ]; then \
	  for f in $$classes; do \
	    if [ "$$first" = "yes" ]; then \
	      classlist="@\"$$f\""; \
	      first="no"; \
	    else \
	      classlist="$$classlist, @\"$$f\""; \
	    fi; \
	  done; \
	  if [ "$$classlist" = "" ]; then \
	    classlist="NULL"; \
	  else \
	    classlist="$$classlist, NULL"; \
	else \
	  classlist="NULL"; \
	fi; \
	if [ "`echo $(FRAMEWORK_INSTALL_DIR) | sed 's/^$(subst /,\/,$(GNUSTEP_USER_ROOT))//'`" != "$(FRAMEWORK_INSTALL_DIR)" ]; then \
	  fw_env="@\"GNUSTEP_USER_ROOT\""; \
	elif [ "`echo $(FRAMEWORK_INSTALL_DIR) | sed 's/^$(subst /,\/,$(GNUSTEP_LOCAL_ROOT))//'`" != "$(FRAMEWORK_INSTALL_DIR)" ]; then \
	  fw_env="@\"GNUSTEP_LOCAL_ROOT\""; \
	elif [ "`echo $(FRAMEWORK_INSTALL_DIR) | sed 's/^$(subst /,\/,$(GNUSTEP_SYSTEM_ROOT))//'`" != "$(FRAMEWORK_INSTALL_DIR)" ]; then \
	  fw_env="@\"GNUSTEP_SYSTEM_ROOT\""; \
	else \
	  fw_env="nil"; \
	fi; \
	fw_path=`echo $(FRAMEWORK_INSTALL_DIR) | sed 's/^$(subst /,\/,$(GNUSTEP_FRAMEWORKS))//'`; \
	if [ "$$fw_path" = "$(FRAMEWORK_INSTALL_DIR)" ]; then \
	  fw_path="nil"; \
	elif [ "$$fw_path" = "" ]; then \
	  fw_path="nil"; \
	else \
	  fw_path="@\"$$fw_path\""; \
	fi; \
	echo "Creating $(DUMMY_FRAMEWORK_FILE)"; \
	echo "#include <Foundation/NSString.h>" > $@; \
	echo "@interface $(DUMMY_FRAMEWORK)" >> $@; \
	echo "+ (NSString *)frameworkEnv;" >> $@; \
	echo "+ (NSString *)frameworkPath;" >> $@; \
	echo "+ (NSString *)frameworkVersion;" >> $@; \
	echo "+ (NSString **)frameworkClasses;" >> $@; \
	echo "@end" >> $@; \
	echo "@implementation $(DUMMY_FRAMEWORK)" >> $@; \
	echo "+ (NSString *)frameworkEnv { return $$fw_env; }" >> $@; \
	echo "+ (NSString *)frameworkPath { return $$fw_path; }" >> $@; \
	echo "+ (NSString *)frameworkVersion { return @\"$(CURRENT_VERSION_NAME)\"; }" >> $@; \
	echo "static NSString *allClasses[] = {$$classlist};" >> $@; \
	echo "+ (NSString **)frameworkClasses { return allClasses; }" >> $@; \
	echo "@end" >> $@;)

$(DUMMY_FRAMEWORK_OBJ_FILE): $(DUMMY_FRAMEWORK_FILE)
	$(CC) $< -c $(ALL_CPPFLAGS) $(ALL_OBJCFLAGS) -o $@

build-framework:: $(FRAMEWORK_FILE) framework-components framework-resource-files localized-framework-resource-files framework-localized-webresource-files framework-webresource-files

ifeq ($(WITH_DLL),yes)

$(FRAMEWORK_FILE) : $(DUMMY_FRAMEWORK_OBJ_FILE) $(C_OBJ_FILES) $(OBJC_OBJ_FILES) $(SUBPROJECT_OBJ_FILES) $(OBJ_FILES)
	$(DLLWRAP) --driver-name $(CC) \
		-o $(LDOUT)$(FRAMEWORK_FILE) \
		$(C_OBJ_FILES) $(OBJC_OBJ_FILES) $(SUBPROJECT_OBJ_FILES) $(OBJ_FILES) \
		$(ALL_LIB_DIRS) $(ALL_FRAMEWORK_LIBS)

else # WITH_DLL

$(FRAMEWORK_FILE) : $(DUMMY_FRAMEWORK_OBJ_FILE) $(C_OBJ_FILES) $(OBJC_OBJ_FILES) $(SUBPROJECT_OBJ_FILES) $(OBJ_FILES)
	$(FRAMEWORK_LINK_CMD)
	@(cd $(FRAMEWORK_LIBRARY_DIR_NAME); \
	  rm -f $(INTERNAL_framework_NAME); \
	  $(LN_S) $(VERSION_FRAMEWORK_LIBRARY_FILE) $(INTERNAL_framework_NAME))

endif # WITH_DLL

framework-components::
	@(if [ "$(COMPONENTS)" != "" ]; then \
	  echo "Copying components into the framework wrapper..."; \
	  cd $(FRAMEWORK_VERSION_DIR_NAME)/Resources; \
	  for component in $(COMPONENTS); do \
	    if [ -d ../../../../$$component ]; then \
	      cp -r ../../../../$$component ./; \
	    fi; \
	  done; \
	  echo "Copying localized components into the framework wrapper..."; \
	  for l in $(LANGUAGES); do \
	    if [ ! -f $$l.lproj ]; then \
	      $(MKDIRS) $$l.lproj; \
	    fi; \
	    cd $$l.lproj; \
	    for f in $(COMPONENTS); do \
	      if [ -d ../../../../../$$l.lproj/$$f ]; then \
		cp -r ../../../../../$$l.lproj/$$f .;\
	      fi; \
	    done;\
	    cd ..; \
	  done;\
	fi;)

framework-resource-files:: $(FRAMEWORK_VERSION_DIR_NAME)/Resources/Info.plist $(FRAMEWORK_VERSION_DIR_NAME)/Resources/Info-gnustep.plist
	@(if [ "$(RESOURCE_FILES)" != "" ]; then \
	  echo "Copying resources into the framework wrapper..."; \
	  for f in "$(RESOURCE_FILES)"; do \
	    cp -r $$f $(FRAMEWORK_VERSION_DIR_NAME)/Resources; \
	  done; \
	fi;)

localized-framework-resource-files:: $(FRAMEWORK_VERSION_DIR_NAME)/Resources/Info-gnustep.plist
	@(if [ "$(LOCALIZED_RESOURCE_FILES)" != "" ]; then \
	  echo "Copying localized resources into the framework wrapper..."; \
	  for l in $(LANGUAGES); do \
	    if [ ! -f $$l.lproj ]; then \
	      $(MKDIRS) $(FRAMEWORK_VERSION_DIR_NAME)/Resources/$$l.lproj; \
	    fi; \
	    for f in $(LOCALIZED_RESOURCE_FILES); do \
	      if [ -f $$l.lproj/$$f ]; then \
	        cp -r $$l.lproj/$$f $(FRAMEWORK_VERSION_DIR_NAME)/Resources/$$l.lproj; \
	      fi; \
	    done; \
	  done; \
	fi)

framework-webresource-dir::
	@(if [ "$(WEBSERVER_RESOURCE_FILES)" != "" ] || [ "$(FRAMEWORK_WEBSERVER_RESOURCE_DIRS)" != "" ]; then \
	  $(MKDIRS) $(FRAMEWORK_VERSION_DIR_NAME)/WebServerResources; \
	  $(MKDIRS) $(FRAMEWORK_WEBSERVER_RESOURCE_DIRS); \
	  if test ! -L "$(FRAMEWORK_DIR_NAME)/WebServerResources"; then \
	    $(LN_S) Versions/Current/WebServerResources $(FRAMEWORK_DIR_NAME);\
	  fi; \
	fi;)

framework-webresource-files:: framework-webresource-dir
	@(if [ "$(WEBSERVER_RESOURCE_FILES)" != "" ]; then \
	  echo "Copying webserver resources into the framework wrapper..."; \
	  cd $(FRAMEWORK_VERSION_DIR_NAME)/WebServerResources; \
	  for ff in $(WEBSERVER_RESOURCE_FILES); do \
	    if [ -f ../../../../WebServerResources/$$ff ]; then \
	      cp -r ../../../../WebServerResources/$$ff .; \
	    fi; \
	  done; \
	fi;)

framework-localized-webresource-files:: framework-webresource-dir
	@(if [ "$(LOCALIZED_WEBSERVER_RESOURCE_FILES)" != "" ]; then \
	  echo "Copying localized webserver resources into the framework wrapper..."; \
	  cd $(FRAMEWORK_VERSION_DIR_NAME)/WebServerResources; \
	  for l in $(LANGUAGES); do \
	    if [ ! -f $$l.lproj ]; then \
	      $(MKDIRS) $$l.lproj; \
	    fi; \
	    cd $$l.lproj; \
	    for f in $(LOCALIZED_WEBSERVER_RESOURCE_FILES); do \
	      if [ -f ../../../../../WebServerResources/$$l.lproj/$$f ]; then \
		if [ ! -r $$f ]; then \
		  cp -r ../../../../../WebServerResources/$$l.lproj/$$f $$f;\
		fi;\
	      fi;\
	    done;\
	    cd ..; \
	  done;\
	fi;)

ifeq ($(PRINCIPAL_CLASS),)
override PRINCIPAL_CLASS = $(INTERNAL_framework_NAME)
endif

# MacOSX-S frameworks
$(FRAMEWORK_VERSION_DIR_NAME)/Resources/Info.plist: $(FRAMEWORK_VERSION_DIR_NAME)/Resources
	@(echo "{"; echo '  NOTE = "Automatically generated, do not edit!";'; \
	  echo "  NSExecutable = \"$(GNUSTEP_TARGET_LDIR)/$(FRAMEWORK_NAME)${FRAMEWORK_OBJ_EXT}\";"; \
	  if [ "$(MAIN_MODEL_FILE)" = "" ]; then \
	    echo "  NSMainNibFile = \"\";"; \
	  else \
	    echo "  NSMainNibFile = \"`echo $(MAIN_MODEL_FILE) | sed 's/.gmodel//'`\";"; \
	  fi; \
	  echo "  NSPrincipalClass = \"$(PRINCIPAL_CLASS)\";"; \
	  echo "}") >$@

# GNUstep frameworks
$(FRAMEWORK_VERSION_DIR_NAME)/Resources/Info-gnustep.plist: $(FRAMEWORK_VERSION_DIR_NAME)/Resources
	@(echo "{"; echo '  NOTE = "Automatically generated, do not edit!";'; \
	  echo "  NSExecutable = \"$(INTERNAL_framework_NAME)${FRAMEWORK_OBJ_EXT}\";"; \
	  if [ "$(MAIN_MODEL_FILE)" = "" ]; then \
	    echo "  NSMainNibFile = \"\";"; \
	  else \
	    echo "  NSMainNibFile = \"`echo $(MAIN_MODEL_FILE) | sed 's/.gmodel//'`\";"; \
	  fi; \
	  echo "  NSPrincipalClass = \"$(PRINCIPAL_CLASS)\";"; \
	  echo "}") >$@

internal-framework-install:: $(FRAMEWORK_INSTALL_DIR) $(GNUSTEP_FRAMEWORKS_LIBRARIES) $(GNUSTEP_FRAMEWORKS_HEADERS)
	rm -rf $(FRAMEWORK_INSTALL_DIR)/$(FRAMEWORK_DIR_NAME)
	$(TAR) cf - $(FRAMEWORK_DIR_NAME) | (cd $(FRAMEWORK_INSTALL_DIR); $(TAR) xf -)
	@(cd $(GNUSTEP_FRAMEWORKS_HEADERS); \
	if [ "$(HEADER_FILES)" != "" ]; then \
	  if test -L "$(INTERNAL_framework_NAME)"; then \
	    rm -f $(INTERNAL_framework_NAME); \
	  fi; \
	  $(LN_S) $(FRAMEWORK_INSTALL_DIR)/$(FRAMEWORK_DIR_NAME)/Headers $(INTERNAL_framework_NAME); \
	fi;)
	@(cd $(GNUSTEP_FRAMEWORKS_LIBRARIES); \
	if test -f "$(FRAMEWORK_LIBRARY_FILE)"; then \
	  rm -f $(FRAMEWORK_LIBRARY_FILE); \
	fi; \
	if test -f "$(SONAME_FRAMEWORK_FILE)"; then \
	  rm -f $(SONAME_FRAMEWORK_FILE); \
	fi; \
	if test -f "$(VERSION_FRAMEWORK_LIBRARY_FILE)"; then \
	  rm -f $(VERSION_FRAMEWORK_LIBRARY_FILE); \
	fi; \
	$(LN_S) $(FRAMEWORK_INSTALL_DIR)/$(FRAMEWORK_CURRENT_LIBRARY_DIR_NAME)/$(FRAMEWORK_LIBRARY_FILE) $(FRAMEWORK_LIBRARY_FILE); \
	if test -f "$(FRAMEWORK_INSTALL_DIR)/$(FRAMEWORK_CURRENT_LIBRARY_DIR_NAME)/$(SONAME_FRAMEWORK_FILE)"; then \
	  $(LN_S) $(FRAMEWORK_INSTALL_DIR)/$(FRAMEWORK_CURRENT_LIBRARY_DIR_NAME)/$(SONAME_FRAMEWORK_FILE) $(SONAME_FRAMEWORK_FILE); \
	fi; \
	$(LN_S) $(FRAMEWORK_INSTALL_DIR)/$(FRAMEWORK_CURRENT_LIBRARY_DIR_NAME)/$(VERSION_FRAMEWORK_LIBRARY_FILE) $(VERSION_FRAMEWORK_LIBRARY_FILE);)

$(FRAMEWORK_DIR_NAME)/Resources $(FRAMEWORK_INSTALL_DIR)::
	@$(MKDIRS) $@

$(GNUSTEP_FRAMEWORKS_LIBRARIES) :
	$(MKDIRS) $@

$(GNUSTEP_FRAMEWORKS_HEADERS) :
	$(MKDIRS) $@

internal-framework-uninstall::
	if [ "$(HEADER_FILES)" != "" ]; then \
	  for file in $(HEADER_FILES) __done; do \
	    if [ $$file != __done ]; then \
	      rm -rf $(GNUSTEP_HEADERS)$(HEADER_FILES_INSTALL_DIR)/$$file ; \
	    fi; \
	  done; \
	fi; \
	rm -rf $(FRAMEWORK_INSTALL_DIR)/$(FRAMEWORK_DIR_NAME)

#
# Cleaning targets
#
internal-framework-clean::
	rm -rf $(GNUSTEP_OBJ_DIR) $(FRAMEWORK_DIR_NAME) $(DERIVED_SOURCES)

internal-framework-distclean::
	rm -rf shared_obj static_obj shared_debug_obj shared_profile_obj \
	  static_debug_obj static_profile_obj shared_profile_debug_obj \
	  static_profile_debug_obj $(DERIVED_SOURCES)

endif

endif
# framework.make loaded

## Local variables:
## mode: makefile
## End:
