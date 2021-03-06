% Generated by roxygen2 (4.1.0): do not edit by hand
% Please edit documentation in R/fastr-translator.R
\name{FastrTranslate}
\alias{FastrTranslate}
\title{Translate Test Cases to FastR style

This function is respinsible generating Java testcases for FastR.
If there is a folder with already existing test cases translated from TestR to FastR, then the function will append test cases to proper files in that folder.
Uses unility function for extraction of test case information. Idea is that to instead of running a test when calling test function, it collects test information and converts it to FastR test}
\usage{
FastrTranslate(r.test.folder, fastr.test.folder = "tests/")
}
\arguments{
\item{fastr.test.folder}{folder with FastR test cases in Java}

\item{r.test.root}{folder with R testcases}
}
\description{
Translate Test Cases to FastR style

This function is respinsible generating Java testcases for FastR.
If there is a folder with already existing test cases translated from TestR to FastR, then the function will append test cases to proper files in that folder.
Uses unility function for extraction of test case information. Idea is that to instead of running a test when calling test function, it collects test information and converts it to FastR test
}

