% File src/library/base/man/which.Rd
% Part of the R package, http://www.R-project.org
% Copyright 1995-2013 R Core Team
% Distributed under GPL 2 or later

\name{which}
\alias{which}
\alias{arrayInd}
\title{Which indices are TRUE?}
\description{
  Give the \code{TRUE} indices of a logical object, allowing for array
  indices.
}
\usage{
which(x, arr.ind = FALSE, useNames = TRUE)
arrayInd(ind, .dim, .dimnames = NULL, useNames = FALSE)
}
\arguments{
 \item{x}{a \code{\link{logical}} vector or array.  \code{\link{NA}}s
   are allowed and omitted (treated as if \code{FALSE}).}
 \item{arr.ind}{logical; should \bold{arr}ay \bold{ind}ices be returned
   when \code{x} is an array?}

 \item{ind}{integer-valued index vector, as resulting from
   \code{which(x)}.}
 \item{.dim}{\code{\link{dim}(.)} integer vector}
 \item{.dimnames}{optional list of character \code{\link{dimnames}(.)},
   of which only \code{.dimnames[[1]]} is used.}
 \item{useNames}{logical indicating if the value of \code{arrayInd()}
   should have (non-null) dimnames at all.}
}
\value{
  If \code{arr.ind == FALSE} (the default), an integer vector with
  \code{length} equal to \code{sum(x)}, i.e., to the number of
  \code{TRUE}s in \code{x}; Basically, the result is
  \code{(1:length(x))[x]}.

  If \code{arr.ind == TRUE} and \code{x} is an \code{\link{array}} (has
  a \code{\link{dim}} attribute), the result is
  \code{arrayInd(which(x), dim(x), dimnames(x))}, namely a matrix
  whose rows each are the indices of one element of \code{x}; see
  Examples below.
}
\author{Werner Stahel and Peter Holzer (ETH Zurich) proposed the
  \code{arr.ind} option.}
\seealso{\code{\link{Logic}}, \code{\link{which.min}} for the index of
  the minimum or maximum, and \code{\link{match}} for the first index of
  an element in a vector, i.e., for a scalar \code{a}, \code{match(a, x)}
  is equivalent to  \code{min(which(x == a))} but much more efficient.}
\examples{
which(LETTERS == "R")
which(ll <- c(TRUE, FALSE, TRUE, NA, FALSE, FALSE, TRUE)) #> 1 3 7
names(ll) <- letters[seq(ll)]
which(ll)
which((1:12)\%\%2 == 0) # which are even?
which(1:10 > 3, arr.ind = TRUE)

( m <- matrix(1:12, 3, 4) )
div.3 <- m \%\% 3 == 0
which(div.3)
which(div.3, arr.ind = TRUE)
rownames(m) <- paste("Case", 1:3, sep = "_")
which(m \%\% 5 == 0, arr.ind = TRUE)

dim(m) <- c(2, 2, 3); m
which(div.3, arr.ind = FALSE)
which(div.3, arr.ind = TRUE)

vm <- c(m)
dim(vm) <- length(vm) #-- funny thing with  length(dim(...)) == 1
which(vm \%\% 3 == 0, arr.ind = TRUE)
}
\keyword{logic}
\keyword{attribute}
