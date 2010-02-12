#   -*-makefile-*-
#   rpm.make
#
#   Makefile rules to build a RPM spec files and RPM packages
#
#   Copyright (C) 2001-2007 Free Software Foundation, Inc.
#
#   Author: Nicola Pero <n.pero@mi.flashnet.it>
#  
#   This file is part of the GNUstep Makefile Package.
#
#   This library is free software; you can redistribute it and/or
#   modify it under the terms of the GNU General Public License
#   as published by the Free Software Foundation; either version 3
#   of the License, or (at your option) any later version.
#   
#   You should have received a copy of the GNU General Public
#   License along with this library; see the file COPYING.
#   If not, write to the Free Software Foundation,
#   51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

#
# FIXME: Move all this documentation into the documentation
#

#
# FIXME/TODO: Update for GNUSTEP_BUILD_DIR
#

# rpm puts all tools, bundles, applications, subprojects, libraries,
# etc specified in the GNUmakefile into a single rpm. There aren't any
# provisions for putting separate apps/tools/etc in separate rpms
# (other than putting them in separate dirs).
# 
# Note: we don't make development packages separated from the standard
# ones.  Every package containing a library's object files will also
# contain the header files for the library <only the ones which were
# declared in the makefile of course>.
#
#
# When building a package, the make package generates automatically:
#
#  * the .tgz source file to be copied into where_you_build_rpms/SOURCES/
#    <generated by source-dist.make>
#
#  * the spec file to be copied into where_you_build_rpms/SPECS/
#    <generate by rpm.make>
#
# at this point, to build the rpm you just do
#  cd where_you_build_rpms/SPECS/
#  rpm -ba my_package.spec
#
# If you are *very* lazy, typing `make rpm' will do it all automatically 
# for you.  But in that case, you need to have set the shell environment 
# variable `RPM_TOPDIR' to the top dir of where you build rpms (eg, 
# /usr/src/redhat/).
#

# To build the spec file for a package, you need to do two things:

# [1] Add - after common.make - the following lines in your GNUmakefile:
#
# PACKAGE_NAME = Gomoku
# PACKAGE_VERSION = 1.1.1
# 
# (replace them with name, version of your software).  This is mainly
# needed so that when you build the .tgz and the spec file, they have
# names which are in sync.  Make sure to keep the library version and
# the package version in sync.
#
# The other important variable you may want to set in your makefiles is
#
# GNUSTEP_INSTALLATION_DOMAIN - Installation domain (defaults to LOCAL)
#
# Make sure that your filesystem layout matches the one of your target
# system else your files might end up in the wrong directory when
# installed.  In other words, use the same version of gnustep-make
# that will be used on the target system, and configured in the same
# way.

# [2] Provide a $(PACKAGE_NAME).spec.in file, which contains the RPM
# spec preamble.  Here is an example:

# Summary: A table board game
# Release: 1
# License: GPL
# Group: Amusements/Games
# Source: http://www.gnustep.it/nicola/Applications/Gomoku/%{gs_name}-%{gs_version}.tar.gz
#
# %description 
# Gomoku is an extended TicTacToe game for GNUstep. You win the game if
# you are able to put 5 of your pieces in a row, column or diagonal. You
# loose if the computer does it before you. You can play the game on
# boards of different size; the default size is 8 but 10 is also nice to
# play. The game has 6 different difficulty levels.

# Comments:
#  you must not include: `Name', `Version', `BuildRoot' and `Prefix'
# entries.  These are generated automatically; `Name' and `Version'
# from $(PACKAGE_NAME) and $(PACKAGE_VERSION), and so for BuildRoot
# and Prefix.  you might include all the other tags listed in the RPM
# doc if you want.
#  
#  You can use the following if you need:
#  %{gs_name}    expands to the value of the make variable PACKAGE_NAME
#  %{gs_version} expands to the value of the make variable PACKAGE_VERSION  
#  (make sure you use them in `Source:' as shown).
#

# A special note: if you need `./configure' to be run before
# compilation (usually only needed for GNUstep core libraries
# themselves), define the following make variable:
#
# PACKAGE_NEEDS_CONFIGURE = YES
#
# in your makefile.

#
# At this point, typing 
#  `make dist' will generate the .tgz (can be used outside rpm.make)
#  `make specfile' will generate the (matching) specfile.
#

#
# As said before, if you are very lazy, typing something like
#
# make distclean
# `RPM_TOPDIR=/usr/src/redhat' make rpm
#
# will do the whole job once you have written your '.spec.in' file,
# and set the PACKAGE_NAME and PACKAGE_VERSION variables in the makefile.
# The generated rpm will be in /usr/src/redhat/RPMS/.
#

#
# Internal targets
#

# If we have been called with something like
#
# make DESTDIR=/var/tmp/package-build filelist=yes install
#
# we are being called inside the rpm installation stage, and we need
# to produce the file list from the installed files.
#
GNUSTEP_FILE_LIST = $(GNUSTEP_OBJ_DIR)/file-list

ifeq ($(filelist),yes)

  # Build the file-list only at top level
#  ifeq ($(MAKELEVEL),0)

  # Remove the old file list before installing, and initialize the new one.
  before-install:: $(GNUSTEP_OBJ_DIR)
	$(ECHO_NOTHING)rm -f $(GNUSTEP_FILE_LIST)$(END_ECHO)
	$(ECHO_NOTHING)echo "%attr (-, root, root)" >> $(GNUSTEP_FILE_LIST)$(END_ECHO)

  # Get the list of files inside DESTDIR
  internal-after-install::
	$(ECHO_NOTHING)for file in `$(TAR) Pcf - $(DESTDIR) | $(TAR) t`; do \
	  if [ -d "$$file" ]; then                                \
	    echo "%dir $$file" > /dev/null;                       \
	  else                                                    \
	    echo "$$file" >> $(GNUSTEP_FILE_LIST);                \
	  fi;                                                     \
	done$(END_ECHO)                                                    
	$(ECHO_NOTHING)sed -e "s|^$(DESTDIR)||" $(GNUSTEP_FILE_LIST) > file-list.tmp$(END_ECHO)
	$(ECHO_NOTHING)mv file-list.tmp $(GNUSTEP_FILE_LIST)$(END_ECHO)

#  endif # MAKELEVEL

endif # filelist == yes

# NB: The filelist is automatically deleted when GNUSTEP_OBJ_DIR is
# deleted (that is, by make clean)

SPEC_FILE_NAME=$(PACKAGE_NAME).spec
SPEC_FILE=$(GNUSTEP_OBJ_DIR)/$(SPEC_FILE_NAME)
SPEC_RULES_TEMPLATE=$(GNUSTEP_MAKEFILES)/spec-rules.template
SPEC_IN=$(PACKAGE_NAME).spec.in
SPEC_SCRIPT_IN=$(PACKAGE_NAME).script.spec.in

.PHONY: specfile rpm check-RPM_TOPDIR

#
# The user will type `make specfile' to generate the specfile
#
specfile: $(SPEC_FILE)

#
# This is the real target - depends on having a correct .spec.in file
#
$(SPEC_FILE): $(SPEC_IN) $(GNUSTEP_OBJ_DIR)
	$(ECHO_NOTHING)echo "Generating the spec file..."$(END_ECHO)
	$(ECHO_NOTHING)rm -f $@$(END_ECHO)
	$(ECHO_NOTHING)echo "##" >> $@$(END_ECHO)
	$(ECHO_NOTHING)echo "## Generated automatically by GNUstep make - do not edit!" >> $@$(END_ECHO)
	$(ECHO_NOTHING)echo "## Edit the $(SPEC_IN) file instead" >> $@$(END_ECHO)
	$(ECHO_NOTHING)echo "##" >> $@$(END_ECHO)
	$(ECHO_NOTHING)echo " " >> $@$(END_ECHO)
	$(ECHO_NOTHING)echo "## Code dynamically generated" >> $@$(END_ECHO)
	$(ECHO_NOTHING)echo "%define gs_name         $(PACKAGE_NAME)" >> $@$(END_ECHO)
	$(ECHO_NOTHING)echo "%define gs_version      $(PACKAGE_VERSION)" >> $@$(END_ECHO)
	$(ECHO_NOTHING)echo "%define gs_install_domain $(GNUSTEP_INSTALLATION_DOMAIN)" >> $@$(END_ECHO)
	$(ECHO_NOTHING)echo "%define gs_makefiles    $(GNUSTEP_MAKEFILES)" >> $@$(END_ECHO)
	$(ECHO_NOTHING)echo "%define gs_file_list    $(GNUSTEP_FILE_LIST)" >> $@$(END_ECHO)
ifeq ($(PACKAGE_NEEDS_CONFIGURE),YES)
	$(ECHO_NOTHING)echo "%define gs_configure    YES" >> $@$(END_ECHO)
else
	$(ECHO_NOTHING)echo "%define gs_configure    NO" >> $@$(END_ECHO)
endif
	$(ECHO_NOTHING)echo " " >> $@$(END_ECHO)
	$(ECHO_NOTHING)echo "Name: %{gs_name}" >> $@$(END_ECHO)
	$(ECHO_NOTHING)echo "Version: %{gs_version}" >> $@$(END_ECHO)
	$(ECHO_NOTHING)echo "BuildRoot: /var/tmp/%{gs_name}-buildroot" >> $@$(END_ECHO)
	$(ECHO_NOTHING)echo "" >> $@$(END_ECHO)
	$(ECHO_NOTHING)echo "## Code from $(SPEC_IN)" >> $@$(END_ECHO)
	$(ECHO_NOTHING)cat $(SPEC_IN) >> $@$(END_ECHO)
	$(ECHO_NOTHING)echo "" >> $@$(END_ECHO)
	$(ECHO_NOTHING)echo "## Fixed rules from $(SPEC_RULES_TEMPLATE)" >> $@$(END_ECHO)
	$(ECHO_NOTHING)cat $(SPEC_RULES_TEMPLATE) >> $@$(END_ECHO)
	$(ECHO_NOTHING)if [ -f $(SPEC_SCRIPT_IN) ]; then                         \
	    echo "" >> $@;                                          \
	    echo "## Script rules from $(SPEC_SCRIPT_IN)" >> $@;    \
	    cat $(SPEC_SCRIPT_IN) >> $@;                            \
          fi$(END_ECHO)

check-RPM_TOPDIR:
	$(ECHO_NOTHING)if [ "$(RPM_TOPDIR)" = "" ]; then                                 \
	  echo "I can't build the RPM if you do not set your RPM_TOPDIR"; \
	  echo "shell variable";                                          \
	  exit 1; \
	fi;$(END_ECHO)

# In old RPM versions, building was done using 'rpm -ba'; in newer RPM
# versions, it can only be done using 'rpmbuild -ba'.  Try to support
# the old RPM versions by using 'rpm' instead of 'rpmbuild', if
# 'rpmbuild' is not available.  This hack can presumably be removed
# when all RPM versions on earth will have been updated to the new
# setup (it might take a while).

rpm: check-RPM_TOPDIR dist specfile
	$(ECHO_NOTHING)echo "Generating the rpm..."$(END_ECHO)
ifneq ($(RELEASE_DIR),)
	$(ECHO_NOTHING)cp $(RELEASE_DIR)/$(PACKAGE_NAME)-$(PACKAGE_VERSION).tar.gz \
	    $(RPM_TOPDIR)/SOURCES/$(END_ECHO)
else
	$(ECHO_NOTHING)cp ../$(PACKAGE_NAME)-$(PACKAGE_VERSION).tar.gz $(RPM_TOPDIR)/SOURCES/$(END_ECHO)
endif	
	$(ECHO_NOTHING)cp $(SPEC_FILE) $(RPM_TOPDIR)/SPECS/; \
	cd $(RPM_TOPDIR)/SPECS/; \
	if which rpmbuild > /dev/null 2>/dev/null; then \
	  rpmbuild="rpmbuild"; \
	else \
	  if which rpm > /dev/null 2>/dev/null; then \
	    rpmbuild="rpm"; \
	  else \
	    echo "Error: You don't have rpm installed!"; \
	    rpmbuild="rpmbuild"; \
	  fi; \
	fi; \
	$${rpmbuild} -ba $(SPEC_FILE_NAME)$(END_ECHO)
