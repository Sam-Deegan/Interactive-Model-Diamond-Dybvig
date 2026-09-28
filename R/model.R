################################################################################
## Project: ECON42550 Macroeconomics                                          ##
## Diamond and Dybvig Bank Runs: Model                                        ##
################################################################################

## Author:      Sam Deegan
## Affiliation: University College Dublin
## Email:       sam.deegan@ucdconnect.ie

## Usage:
##   Sourced automatically by app.R. Can be sourced alone from a lecture
##   .qmd so slide figures come from the same model:
##     source("R/model.R")
##
## Inputs:
##   None. Every function is a pure function of a parameter list "par"
##   built by the app.
##
## Outputs:
##   C_01_* functions: utility, autarky, the contract, the optimum, the run
##   threshold, best responses, the queue, equilibria, policies, readouts.
##
## Packages:
##   None beyond base R.
##
## Version:
##   Shown in the app footer (B_03_16_version_chr); history in CHANGELOG.md.
##
## References:
##   Diamond, D. W. and Dybvig, P. H. (1983). Bank runs, deposit insurance,
##     and liquidity. Journal of Political Economy 91(3).
##   Romer, D. (2019). Advanced Macroeconomics, 5th ed. Ch. 10.
##   ECON42550 Part 2 sample paper, for the worked example the defaults
##     reproduce.
##
## The model (Diamond and Dybvig, 1983):
##   Three dates, T = 0, 1, 2. N consumers, each with 1 unit at T = 0.
##   One unit invested at T = 0 is worth R at T = 2, but only L if it is
##   liquidated at T = 1, with L <= 1 < R.
##   A consumer learns at T = 1 whether they are impatient (consume at T = 1)
##   with probability theta, or patient (consume at T = 2).
##   Utility is CRRA:  U(c) = (c^(1-rho) - 1) / (1 - rho), which is
##   1 - 1/c at rho = 2 and log(c) at rho = 1.
##
##   Autarky:   an impatient consumer liquidates and gets L; a patient one
##              waits and gets R.
##   The bank:  offers c1 to anyone withdrawing at T = 1. If only the
##              impatient withdraw it liquidates theta * c1 / L of the
##              investment, so the patient receive
##                  c2 = (1 - theta c1 / L) R / (1 - theta).
##   Optimal:   U'(c1) = R U'(c2), which for CRRA means c2 = c1 R^(1/rho),
##              so  c1* = R / [ R^(1/rho) (1 - theta) + theta R / L ].
##   Runs:      if a fraction f withdraws at T = 1 the bank can serve only
##              f* = L / c1 of depositors before its assets run out.
##
## Parameter list (par) elements:
##   theta, ret (R), liq (L), rho, c1, n_dep (N), f_run (f), policy

#-------------------------------- Script Begin --------------------------------#

################################################################################
## A: Table of Contents ########################################################
################################################################################
# Note: C_01 holds the model; app.R holds sections B, D, E, F and G.
#
#   C: Model
#     C_01_01  Utility
#     C_01_02  Autarky
#     C_01_03  The deposit contract
#     C_01_04  Expected utility of a contract
#     C_01_05  The optimal contract
#     C_01_06  Expected utility curve
#     C_01_07  The run threshold
#     C_01_08  Payoff from waiting
#     C_01_09  Best response
#     C_01_10  The queue
#     C_01_11  The two equilibria
#     C_01_12  Policies
#     C_01_13  Readouts
#     C_01_14  Problems with the calibration

################################################################################
## C: Model ####################################################################
################################################################################
# Note: Closed-form expressions throughout; nothing here touches Shiny.

#### C_01: Contracts, Utility and Runs #########################################
# Note: Autarky, the deposit contract, the optimum, and the run equilibrium.

###### C_01_01: Utility ########################################################
# Note: CRRA. At rho = 2 this is the 1 - 1/c on the sample paper, so the app
#   reproduces its numbers. Consumption of zero gives minus infinity.

C_01_01_util_fn <- function(c, rho) {
  c <- pmax(c, 0)
  if (abs(rho - 1) < 1e-9) {
    ifelse(c > 0, log(c), -Inf)
  } else {
    ifelse(c > 0, (c^(1 - rho) - 1) / (1 - rho), -Inf)
  }
}

###### C_01_02: Autarky ########################################################
# Note: No bank. The impatient liquidate and get L; the patient wait for R.
#   Nobody is insured against turning out to be impatient.

C_01_02_autarky_fn <- function(par) {
  eu <- par$theta * C_01_01_util_fn(par$liq, par$rho) +
    (1 - par$theta) * C_01_01_util_fn(par$ret, par$rho)
  list(c1 = par$liq, c2 = par$ret, eu = eu)
}

###### C_01_03: The Deposit Contract ###########################################
# Note: What the patient receive at T = 2 when only the impatient withdraw.
#   Negative means the promise at T = 1 cannot be kept at all.

C_01_03_contract_fn <- function(par, c1) {
  liquidated <- par$theta * c1 / par$liq
  c2 <- (1 - liquidated) * par$ret / (1 - par$theta)
  list(c1 = c1, c2 = c2, liquidated = liquidated, feasible = c2 >= 0)
}

###### C_01_04: Expected Utility of a Contract #################################
# Note: Ex ante, before anyone knows their type: what the bank maximises
#   and what is compared with autarky.

C_01_04_eu_fn <- function(par, c1) {
  con <- C_01_03_contract_fn(par, c1)
  par$theta * C_01_01_util_fn(con$c1, par$rho) +
    (1 - par$theta) * C_01_01_util_fn(con$c2, par$rho)
}

###### C_01_05: The Optimal Contract ###########################################
# Note: The first-order condition U'(c1) = R U'(c2) of Diamond and Dybvig
#   (1983), as in Romer (2019) ch. 10. For CRRA the ratio c2 / c1 is
#   R^(1/rho), which with the budget constraint of C_01_03 gives c1 in
#   closed form. With R = 2, rho = 2, theta = 1/4 and L = 1 this returns
#   1.2815: the 1.28 on the sample paper is the optimum.

C_01_05_optimal_fn <- function(par) {
  denom <- par$ret^(1 / par$rho) * (1 - par$theta) +
    par$theta * par$ret / par$liq
  c1 <- par$ret / denom
  con <- C_01_03_contract_fn(par, c1)
  list(c1 = c1, c2 = con$c2, eu = C_01_04_eu_fn(par, c1),
       ratio = par$ret^(1 / par$rho))
}

###### C_01_06: Expected Utility Curve #########################################
# Note: Expected utility across the range of contracts the bank could offer,
#   for the figure.

C_01_06_curve_fn <- function(par, n = 241) {
  c1_max <- par$liq / par$theta            # beyond this c2 would be negative
  grid   <- seq(par$liq * 0.6, c1_max * 0.995, length.out = n)
  data.frame(
    c1 = grid,
    c2 = vapply(grid, function(x) C_01_03_contract_fn(par, x)$c2, 0),
    eu = vapply(grid, function(x) C_01_04_eu_fn(par, x), 0)
  )
}

###### C_01_07: The Run Threshold ##############################################
# Note: Liquidating everything raises L per unit, so the bank can pay c1 to
#   the share L / c1 and no more. At the defaults that is 78.1 of 100
#   depositors, the number on the sample paper.

C_01_07_run_fn <- function(par, c1) {
  share <- min(par$liq / c1, 1)
  list(share = share, depositors = share * par$n_dep,
       last_paid = floor(share * par$n_dep))
}

###### C_01_08: Payoff from Waiting ############################################
# Note: What a patient depositor gets at T = 2 when a share f withdraws at
#   T = 1: zero past the run threshold. With a cap the bank serves at most
#   that share, so the payoff never falls below its value at the cap.

C_01_08_wait_fn <- function(par, c1, f, cap = NULL) {
  if (!is.null(cap)) f <- pmin(f, cap)
  broke <- f > par$liq / c1 + 1e-12
  out   <- (1 - f * c1 / par$liq) * par$ret / pmax(1 - f, 1e-9)
  ifelse(broke | f >= 1, 0, pmax(out, 0))
}

###### C_01_09: Best Response ##################################################
# Note: A patient depositor compares waiting with joining the queue. With
#   no cap, joining pays c1 if the bank's money reaches you and nothing if
#   it does not. Under suspension or deposit insurance (Diamond and Dybvig
#   1983, as on the sample paper) the bank stops at the cap instead of
#   going bust, so anyone it does not reach is paid at date 2 like those who
#   waited; since c2 > c1, waiting then always wins.

C_01_09_best_fn <- function(par, c1, f, cap = NULL) {
  wait <- C_01_08_wait_fn(par, c1, f, cap)
  if (is.null(cap)) {
    served <- pmin(1, par$liq / (c1 * pmax(f, 1e-9)))
    run    <- served * c1
  } else {
    served <- pmin(1, cap / pmax(f, 1e-9))
    run    <- served * c1 + (1 - served) * wait
  }
  data.frame(f = f, wait = wait, run = run, served = served)
}

###### C_01_10: The Queue ######################################################
# Note: Sequential service. Payoff by position in the queue when a share f
#   withdraws: c1 until the bank's assets run out, then nothing.

C_01_10_queue_fn <- function(par, c1, f, cap = NULL) {
  run   <- C_01_07_run_fn(par, c1)
  n     <- par$n_dep
  place <- seq_len(n)
  withdrawing <- if (!is.null(cap)) min(f, cap) * n else f * n
  paid  <- place <= pmin(run$depositors, withdrawing)

  data.frame(
    place  = place,
    payoff = ifelse(place > withdrawing, NA_real_, ifelse(paid, c1, 0)),
    paid   = paid
  )
}

###### C_01_11: The Two Equilibria #############################################
# Note: The good equilibrium has only the impatient withdrawing; the run has
#   everybody. A run is an equilibrium when waiting pays less than joining.

C_01_11_equilibria_fn <- function(par, c1, cap = NULL) {
  good <- C_01_09_best_fn(par, c1, par$theta, cap)
  run  <- C_01_09_best_fn(par, c1, 1, cap)
  list(
    good_wait  = good$wait,
    good_run   = good$run,
    run_wait   = run$wait,
    run_payoff = run$run,
    run_exists = run$run > run$wait + 1e-12,
    good_holds = good$wait > good$run - 1e-12
  )
}

###### C_01_12: Policies #######################################################
# Note: Suspension caps withdrawals at theta; deposit insurance guarantees
#   the date-2 payment, the same cap on the payoffs with nobody turned away.

C_01_12_policy_fn <- function(par, c1, policy) {
  cap <- if (policy %in% c("suspend", "insure")) par$theta else NULL
  eq  <- C_01_11_equilibria_fn(par, c1, cap)
  list(cap = cap, equilibria = eq, policy = policy)
}

###### C_01_13: Readouts #######################################################
# Note: The numbers shown in the tiles above the figures.

C_01_13_diagnostics_fn <- function(par) {
  aut  <- C_01_02_autarky_fn(par)
  con  <- C_01_03_contract_fn(par, par$c1)
  opt  <- C_01_05_optimal_fn(par)
  run  <- C_01_07_run_fn(par, par$c1)
  eq   <- C_01_11_equilibria_fn(par, par$c1)
  cap  <- if (par$policy %in% c("suspend", "insure")) par$theta else NULL
  eqp  <- C_01_11_equilibria_fn(par, par$c1, cap)

  list(
    aut_c1     = aut$c1,
    aut_c2     = aut$c2,
    aut_eu     = aut$eu,
    c1         = con$c1,
    c2         = con$c2,
    eu         = C_01_04_eu_fn(par, par$c1),
    gain       = C_01_04_eu_fn(par, par$c1) - aut$eu,
    opt_c1     = opt$c1,
    opt_c2     = opt$c2,
    opt_eu     = opt$eu,
    is_optimal = abs(par$c1 - opt$c1) < 5e-3,
    insured    = con$c1 > par$liq,
    run_share  = run$share,
    run_dep    = run$depositors,
    last_paid  = run$last_paid,
    run_exists = eq$run_exists,
    run_after  = eqp$run_exists,
    liquidated = con$liquidated,
    problems   = C_01_14_problems_fn(par)
  )
}

###### C_01_14: Problems with the Calibration ##################################
# Note: Warnings shown above the figures for calibrations with no sensible
#   contract.

C_01_14_problems_fn <- function(par) {
  out <- character(0)

  if (par$ret <= par$liq) {
    out <- c(out, paste(
      "Waiting pays no more than liquidating (R is not above L), so there is",
      "nothing for the bank to do. Raise the long return R."
    ))
  }
  if (C_01_03_contract_fn(par, par$c1)$c2 < 0) {
    out <- c(out, paste(
      "The contract promises more at date 1 than the bank's whole investment",
      "can cover, so the patient depositors would receive a negative amount.",
      "Lower the date-1 payment c1."
    ))
  }
  if (par$c1 < par$liq) {
    out <- c(out, paste(
      "The bank is offering less than a depositor could get by liquidating",
      "alone, so nobody would deposit. Raise c1 above the liquidation",
      "value L."
    ))
  }
  out
}
