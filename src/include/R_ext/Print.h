/*
 *  R : A Computer Language for Statistical Data Analysis
 *  Copyright (C) 1998-2010    The R Core Team
 *  Copyright (C) 2008-2014  Andrew R. Runnalls.
 *  Copyright (C) 2014 and onwards the CXXR Project Authors.
 *
 *  CXXR is not part of the R project, and bugs and other issues should
 *  not be reported via r-bugs or other R project channels; instead refer
 *  to the CXXR website.
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU Lesser General Public License as published by
 *  the Free Software Foundation; either version 2.1 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU Lesser General Public License for more details.
 *
 *  You should have received a copy of the GNU Lesser General Public License
 *  along with this program; if not, a copy is available at
 *  http://www.r-project.org/Licenses/
 */

/* Included by R.h: API */

#ifndef R_EXT_PRINT_H_
#define R_EXT_PRINT_H_

#ifdef  __cplusplus
/* If the vprintf interface is defined at all in C++ it may only be
   defined in namespace std. */
/* CXXR comment 2011-07-28: ISO14882:2003 specifies that vprintf() be
   included in cstdio. */
# ifdef R_USE_C99_IN_CXX
#  include <cstdarg>
#  ifdef __SUNPRO_CC
using _STLP_VENDOR_CSTD::va_list;
#  endif
# endif
extern "C" {
#else
# include <stdarg.h>
#endif

void Rprintf(const char *, ...);
void REprintf(const char *, ...);
void Rvprintf(const char *, va_list);
void REvprintf(const char *, va_list);

#ifdef  __cplusplus
}
#endif

#endif /* R_EXT_PRINT_H_ */
