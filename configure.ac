
# check for one particular file of the sources 
AC_INIT(ocaml-voaacenc, 0.1.0, savonet-users@lists.sourceforge.net)

VERSION=$PACKAGE_VERSION
AC_MSG_RESULT([configuring $PACKAGE_STRING])

# Add prefix to compilation variables
# if passed
if test "x$prefix" != "xNONE"; then
        CFLAGS="$CFLAGS -I$prefix/include"
        LDFLAGS="$LDFLAGS -L$prefix/lib"
        CPPFLAGS="$CPPFLAGS -I$prefix/include"
fi

AC_CHECK_OCAML_COMPILERS()

AC_PROG_CC()
AC_CHECK_TOOL([AR],[ar],no)
AC_SUBST(AR)
PKG_PROG_PKG_CONFIG()
#PKG_CHECK_MODULES(voaacenc, voaacenc, , [AC_MSG_ERROR(voaacenc not found.)])

AC_DEFUN([REQ_VERSION],[0.1.0])
AC_MSG_CHECKING([for libvoaacenc >= REQ_VERSION()])
# PKG_CHECK_MODULES loses when you need --libs-only-[lL]
if ! $PKG_CONFIG --exists vo-aacenc; then
        AC_MSG_ERROR([vo-aacenc not found])
fi
# We need at least version REQ_VERSION
if ! $PKG_CONFIG --atleast-version=[]REQ_VERSION vo-aacenc; then
       AC_DEFUN([FOUND_VERSION],[`pkg-config --modversion vo-aacenc`])
       AC_MSG_ERROR([requires version >= REQ_VERSION(), found FOUND_VERSION()])
fi
AC_MSG_RESULT([ok])
CFLAGS="$CFLAGS `$PKG_CONFIG --cflags vo-aacenc`"
LIBS="$LIBS `$PKG_CONFIG --libs-only-l vo-aacenc`"
LDFLAGS="$LDFLAGS `$PKG_CONFIG --libs-only-L vo-aacenc`"

# substitutions to perform
AC_SUBST(VERSION)
AC_SUBST(INC)
AC_SUBST(requires)

# Finally create the Makefile and samples
AC_CONFIG_FILES([Makefile],[chmod a-w Makefile])
AC_CONFIG_FILES([src/META])
AC_CONFIG_FILES([src/Makefile])
AC_OUTPUT
