#' Testing for balanced covariates: equality of means with t-test
#' 
#' Tests equality of means by a t-test for each covariate, between the two full groups or around the discontinuity threshold 
#' 
#' @param object object of class RDDdata
#' @param bw a bandwidth
#' @param paired Argument of the \code{\link{t.test}} function: logical indicating whether you want paired t-tests.
#' @param var.equal Argument of the \code{\link{t.test}} function:  logical variable indicating whether to treat the two variances as being equal
#' @param p.adjust Whether to adjust the p-values for multiple testing. Uses the \code{\link{p.adjust}} function
#' @param \ldots currently not used
#' @return A data frame with, for each covariate, the mean on each size, the difference, t-stat and ts p-value. 
#' @author Matthieu Stigler <\email{Matthieu.Stigler@@gmail.com}>
#' @seealso \code{\link{covarTest_dis}} for the Kolmogorov-Smirnov test of equality of distribution
#' @examples
#' data(Lee2008)
#' 
#' ## Add randomly generated covariates
#' set.seed(123)
#' n_Lee <- nrow(Lee2008)
#' Z <- data.frame(z1 = rnorm(n_Lee, sd=2), 
#'                 z2 = rnorm(n_Lee, mean = ifelse(Lee2008<0, 5, 8)), 
#'                 z3 = sample(letters, size = n_Lee, replace = TRUE))
#' Lee2008_rdd_Z <- RDDdata(y = Lee2008$y, x = Lee2008$x, covar = Z, cutpoint = 0)
#' 
#' ## test for equality of means around cutoff:
#' covarTest_mean(Lee2008_rdd_Z, bw=0.3)
#' 
#' ## Can also use function covarTest_dis() for Kolmogorov-Smirnov test:
#' covarTest_dis(Lee2008_rdd_Z, bw=0.3)
#' 
#' ## covarTest_mean works also on regression outputs (bw will be taken from the model)
#' reg_nonpara <- RDDreg_np(RDDobject=Lee2008_rdd_Z)
#' covarTest_mean(reg_nonpara)





#' @export
covarTest_mean <- function(object, bw=NULL, paired = FALSE, var.equal = FALSE, p.adjust=c("none", "holm", "BH", "BY","hochberg", "hommel", "bonferroni")) 
  UseMethod("covarTest_mean")

#' @rdname covarTest_mean
#' @method covarTest_mean RDDdata
#' @S3method covarTest_mean RDDdata
covarTest_mean.RDDdata <- function(object, bw=NULL, paired = FALSE, var.equal = FALSE, p.adjust=c("none", "holm", "BH", "BY","hochberg", "hommel", "bonferroni")) {

  cutpoint <- getCutpoint(object)
  covar <- getCovar(object)
  cutvar <- object$x

  covarTest_mean_low(covar=covar,cutvar=cutvar,cutpoint=cutpoint, bw=bw, paired = paired, var.equal = var.equal, p.adjust=p.adjust)

}


#' @rdname covarTest_mean
#' @method covarTest_mean RDDreg
#' @S3method covarTest_mean RDDreg
covarTest_mean.RDDreg <- function(object, bw=NULL, paired = FALSE, var.equal = FALSE, p.adjust=c("none", "holm", "BH", "BY","hochberg", "hommel", "bonferroni")) {
  
  cutpoint <- getCutpoint(object)
  dat <- object$RDDslot$RDDdata
  covar <- getCovar(dat)
  cutvar <- dat$x
  if(is.null(bw)) bw <- getBW(object)
  
  covarTest_mean_low(covar=covar,cutvar=cutvar,cutpoint=cutpoint, bw=bw, paired = paired, var.equal = var.equal, p.adjust=p.adjust)
  
}


covarTest_mean_low <- function(covar,cutvar, cutpoint, bw=NULL, paired = FALSE, var.equal = FALSE, p.adjust=c("none", "holm", "BH", "BY","hochberg", "hommel", "bonferroni")) {

  p.adjust <- match.arg(p.adjust)

## subset
  if(!is.null(bw)){
    isInH <- cutvar >= cutpoint -bw & cutvar <= cutpoint +bw
    covar <- covar[isInH,]
    cutvar <- cutvar[isInH]
  }
  regime <- cutvar < cutpoint

## Split data
  covar_num <- sapply(covar, as.numeric)

  tests <-apply(covar_num, 2, function(x) t.test(x[regime], x[!regime], paired=paired, var.equal=var.equal))
  tests_vals <- sapply(tests, function(x) c(x[["estimate"]], diff(x[["estimate"]]),x[c("statistic", "p.value")]))

## Adjust p values if required:
  if(p.adjust!="none") tests_vals["p.value",] <- p.adjust(tests_vals["p.value",], method=p.adjust)

## Print results
  res <- t(tests_vals)
  colnames(res)[3] <- "Difference"
  res


}




#' Testing for balanced covariates: equality of distribution
#' 
#' Tests equality of distribution with a Kolmogorov-Smirnov for each covariates, between the two full groups or around the discontinuity threshold 
#' 
#' @param object object of class RDDdata
#' @param bw a bandwidth
#' @param exact Argument of the \code{\link{ks.test}} function: NULL or a logical indicating whether an exact p-value should be computed.
#' @param p.adjust Whether to adjust the p-values for multiple testing. Uses the \code{\link{p.adjust}} function
#' @param \ldots currently not used
#' @return A data frame  with, for each covariate, the K-S statistic and its p-value. 
#' @author Matthieu Stigler <\email{Matthieu.Stigler@@gmail.com}>
#' @seealso \code{\link{covarTest_mean}} for the t-test of equality of means
#' @examples
#' data(Lee2008)
#' 
#' ## Add randomly generated covariates
#' set.seed(123)
#' n_Lee <- nrow(Lee2008)
#' Z <- data.frame(z1 = rnorm(n_Lee, sd=2), 
#'                 z2 = rnorm(n_Lee, mean = ifelse(Lee2008<0, 5, 8)), 
#'                 z3 = sample(letters, size = n_Lee, replace = TRUE))
#' Lee2008_rdd_Z <- RDDdata(y = Lee2008$y, x = Lee2008$x, covar = Z, cutpoint = 0)
#' 
#' ## Kolmogorov-Smirnov test of equality in distribution:
#' covarTest_dis(Lee2008_rdd_Z, bw=0.3)
#' 
#' ## Can also use function covarTest_dis() for a t-test for equality of means around cutoff:
#' covarTest_mean(Lee2008_rdd_Z, bw=0.3)
#' ## covarTest_dis works also on regression outputs (bw will be taken from the model)
#' reg_nonpara <- RDDreg_np(RDDobject=Lee2008_rdd_Z)
#' covarTest_dis(reg_nonpara)

#' @export
covarTest_dis <- function(object, bw,  exact=NULL, p.adjust=c("none", "holm", "BH", "BY","hochberg", "hommel", "bonferroni"))
  UseMethod("covarTest_dis")

#' @rdname covarTest_dis
#' @method covarTest_dis RDDdata
#' @S3method covarTest_dis RDDdata
covarTest_dis.RDDdata <- function(object, bw=NULL, exact = FALSE,  p.adjust=c("none", "holm", "BH", "BY","hochberg", "hommel", "bonferroni")) {

  cutpoint <- getCutpoint(object)
  covar <- getCovar(object)
  cutvar <- object$x

  covarTest_dis_low(covar=covar,cutvar=cutvar,cutpoint=cutpoint, bw=bw, exact= exact, p.adjust=p.adjust)

}

#' @rdname covarTest_dis
#' @method covarTest_dis RDDreg
#' @S3method covarTest_dis RDDreg
covarTest_dis.RDDreg <- function(object, bw=NULL, exact = FALSE,  p.adjust=c("none", "holm", "BH", "BY","hochberg", "hommel", "bonferroni")) {
  
  cutpoint <- getCutpoint(object)
  dat <- object$RDDslot$RDDdata
  covar <- getCovar(dat)
  cutvar <- dat$x
  if(is.null(bw)) bw <- getBW(object)
  
  covarTest_dis_low(covar=covar,cutvar=cutvar,cutpoint=cutpoint, bw=bw, exact= exact, p.adjust=p.adjust)
  
}

covarTest_dis_low <- function(covar,cutvar, cutpoint, bw=NULL, exact=NULL, p.adjust=c("none", "holm", "BH", "BY","hochberg", "hommel", "bonferroni")) {

  p.adjust <- match.arg(p.adjust)

## subset
  if(!is.null(bw)){
    isInH <- cutvar >= cutpoint -bw & cutvar <= cutpoint +bw
    covar <- covar[isInH,]
    cutvar <- cutvar[isInH]
  }
  regime <- cutvar < cutpoint



## Split data
  covar_num <- sapply(covar, as.numeric)

  tests <-apply(covar_num, 2, function(x) ks.test(x[regime], x[!regime], exact=exact))
  tests_vals <- sapply(tests, function(x) x[c("statistic", "p.value")])

## Adjust p values if required:
  if(p.adjust!="none") tests_vals["p.value",] <- p.adjust(tests_vals["p.value",], method=p.adjust)

## Print results
  res <- t(tests_vals)
  res


}


##########################################
###### TODO
##########################################
## -mean: can use t.test for factors? What else? Count test? Warn for character/factors!
## -mean: add multivariate hotelling
## -ks: ok for factors?
## -do qqplot?
## -add methods for regs? Once converted to other objects...
## -add example and bettet output documentation
##
##
##

##########################################
###### TESTS
##########################################

if(FALSE){
library(Hotelling)
library(mvtnorm)

data <- rmvnorm(n=200, mean=c(1,2))
spli <- sample(c(TRUE, FALSE), size=200, replace=TRUE)

a<-hotel.stat(data[spli,],data[!spli,])
a

b<-hotel.test(data[spli,],data[!spli,])
b
b$stats

}




if(FALSE){
library(RDDtools)
data(Lee2008)

Z <- data.frame(z_con=runif(nrow(Lee2008)), z_dic=factor(sample(letters[1:3], size=nrow(Lee2008), replace=TRUE)))
Lee2008_rdd <- RDDdata(y=Lee2008$y, x=Lee2008$x, covar=Z, cutpoint=0)


covarTest_mean(object=Lee2008_rdd)
covarTest_dis(object=Lee2008_rdd)



}
