############################################################################
# RCS INFORMATION:
#
# 	$RCSfile$
# 	$Author$	$Locker$		$State$
#	$Revision$	$Date$
#
############################################################################
# DESCRIPTION:
#
############################################################################
# REVISION HISTORY:
#
# $Log$
# Revision 2.3  1995-09-19 20:12:08  brunner
# conv-host not compiled to bin directory, fixed, and RCS header added
#
############################################################################

set CMK_CPP='/lib/cpp -P'
set CMK_LDRO='ld -r -o'
set CMK_CC='gcc'
set CMK_CXX='g++'
set CMK_CF77=''
set CMK_LD='gcc -s'
set CMK_LDXX='g++'
set CMK_LD77=''
set CMK_M4='m4'
set CMK_SUF='o'
set CMK_AR='ar q'
set CMK_RANLIB='true'
set CMK_LIBS=''
set CMK_SEQ_CC='gcc'
set CMK_SEQ_LD='gcc'
set CMK_NM='nm'
set CMK_NM_FILTER="grep '|extern|' | awk '{print "'$'"1;}'"
set CMK_EXTRAS='gcc -o ../bin/conv-host conv-host.c'
set CMK_CLEAN='rm -f conv-host'

