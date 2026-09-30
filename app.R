################################################################################
## Project: ECON42550 Macroeconomics                                          ##
## Diamond and Dybvig Bank Runs: Interactive Shiny App                        ##
################################################################################

## Author:      Sam Deegan
## Affiliation: University College Dublin
## Email:       sam.deegan@ucdconnect.ie

## Usage:
##   Open app.R in RStudio and click Run App, or from this folder:
##     shiny::runApp()
##   Needs R 4.1 or later with shiny, bslib and ggplot2 installed. A hosted
##   copy runs in the browser at
##   https://sam-deegan.com/toy-models/diamond-dybvig/
##   The stage selector builds the model up one layer at a time:
##     1  autarky: no bank, and no insurance against being impatient
##     2  the deposit contract, and why depositors are better off
##     3  the optimal contract, and what the bank is really doing
##     4  the second equilibrium: the run
##     5  suspension of convertibility and deposit insurance
##   Defaults reproduce the worked example on the Part 2 sample paper:
##   theta = 1/4, R = 2, L = 1, U(c) = 1 - 1/c and 100 depositors, where the
##   contract c1 = 1.28 pays c2 = 1.813 and the bank runs dry after 78
##   withdrawals. All text (scenarios, prompts, equations, notation) lives
##   in B_03.
##
## Inputs:
##   R/model.R (the model) and R/toolkit.R (shared layout and helpers),
##   both sourced automatically by Shiny.
##
## Outputs:
##   None. The app is interactive only.
##
## Packages:
##   shiny, bslib, ggplot2.
##
## Version:
##   B_03_16_version_chr; history in CHANGELOG.md; git tag vX.Y.Z.
##
## References:
##   Diamond, D. W. and Dybvig, P. H. (1983). Bank runs, deposit insurance,
##     and liquidity. Journal of Political Economy 91(3).
##   Romer, D. (2019). Advanced Macroeconomics, 5th ed. Ch. 10.
##   ECON42550 Part 2 sample paper, for the worked example the defaults
##     reproduce.

#-------------------------------- Script Begin --------------------------------#

################################################################################
## A: Table of Contents ########################################################
################################################################################
# Note: Section C (the model) is R/model.R; section T (shared layout and
#   helpers) is R/toolkit.R.
#
#   B: Setup
#     B_01  Packages
#     B_02  Settings
#     B_03  Soft-coded objects
#     B_04  Paths (the QR code)
#   C: Model (R/model.R)
#   T: Toolkit (R/toolkit.R)
#   D: Plots
#     D_01  Consumption and expected utility
#     D_02  The run: best responses and the queue
#     D_03  Policies
#   E: User Interface
#   F: Server
#   G: Run

################################################################################
## B: Setup ####################################################################
################################################################################
# Note: Packages, options and every soft-coded value.

#### B_01: Packages ############################################################
# Note: Shiny, bslib for the layout, ggplot2 for the figures.

###### B_01_01: Load Packages ##################################################
# Note: All three run under shinylive.

library(shiny)
library(bslib)
library(ggplot2)

###### B_01_02: Load the Model #################################################
# Note: Shiny sources R/ itself; this covers sourcing app.R by hand.

if (!exists("C_01_05_optimal_fn")) {
  source(file.path("R", "model.R"))
}

###### B_01_03: Load the Toolkit ###############################################
# Note: Palette, plot theme, CSS and builders shared with the other apps.

if (!exists("T_01_01_palette_vec")) {
  source(file.path("R", "toolkit.R"))
}

#### B_02: Settings ############################################################
# Note: Standard options.

###### B_02_01: Global Options #################################################
# Note: No scientific notation; three digits in the console.

options(scipen = 999, digits = 3)

###### B_02_02: Seed ###########################################################
# Note: Nothing here is random; kept for consistency.

set.seed(42)

#### B_03: Soft-Coded Objects ##################################################
# Note: Calibration, stages, policies, scenarios, controls, equations, text.

###### B_03_01: Input Defaults #################################################
# Note: Starting value of every control; Reset returns here. The worked
#   example on the Part 2 sample paper: theta = 1/4, R = 2, L = 1, rho = 2
#   (U(c) = 1 - 1/c) and N = 100. Its c1 = 1.28 is the optimal contract at
#   this calibration to three figures (C_01_05), which stage 3 shows.

B_03_01_defaults_lst <- list(
  theta = 0.25,   # share of depositors who turn out to be impatient
  ret   = 2,      # R: one unit invested is worth this at date 2
  liq   = 1,      # L: what one unit fetches if liquidated at date 1
  rho   = 2,      # risk aversion; 2 gives U(c) = 1 - 1/c
  c1    = 1.28,   # the date-1 payment the bank promises
  n_dep = 100,    # number of depositors, for the queue
  f_run = 1       # share of depositors who withdraw at date 1
)

###### B_03_02: Stages #########################################################
# Note: One layer of the model each, all within lecture 1.5. The preset card
#   supplies the word "Stage", so the names carry only the number and topic.

B_03_02_stages_vec <- c(
  "Stage 1: Autarky, No Bank"     = "1",
  "Stage 2: The Deposit Contract" = "2",
  "Stage 3: The Optimal Contract" = "3",
  "Stage 4: The Run Equilibrium"  = "4",
  "Stage 5: Policies That Stop Runs" = "5"
)

###### B_03_03: Policy Choices #################################################
# Note: No policy, and the two fixes that cap the queue. A radio rather than
#   a slider, so it is not in the controls list.

B_03_03_policies_vec <- c(
  "None"                        = "none",
  "Suspension of Convertibility" = "suspend",
  "Deposit Insurance"           = "insure"
)

###### B_03_04: Policy Explanations ############################################
# Note: What each fix does, and what it costs. Shown under the stage 5 figure.

B_03_04_policy_lst <- list(
  none = paste(
    "With no policy, waiting while everyone else withdraws pays nothing, so",
    "joining the queue is a best response and the belief that others will",
    "run makes itself true."
  ),
  suspend = paste(
    "Under suspension of convertibility the bank announces in advance that",
    "it will pay only the share it knows to be impatient and then close its",
    "doors. The queue stops before it reaches a patient depositor, so",
    "waiting dominates and the run equilibrium disappears. If the impatient",
    "share were genuinely uncertain, suspension would turn away people who",
    "needed their money."
  ),
  insure = paste(
    "Deposit insurance has the government guarantee the date-2 payment.",
    "Waiting is then safe whatever anyone else does, nobody runs, and the",
    "guarantee is never paid. It turns nobody away, which is why it was the",
    "policy adopted, at the cost of moral hazard: a bank whose depositors",
    "cannot run can take more risk. A lender of last resort does the same",
    "job from the other side, lending against the investment so it is never",
    "liquidated and L stops mattering. Set the liquidation value to 1 to see",
    "the model with that already in place."
  )
)

###### B_03_05: Scenarios ######################################################
# Note: Worked examples. Each sets a stage and overrides some defaults;
#   unlisted controls return to B_03_01 and "policy" is set apart from the
#   numeric controls. Story order and wording follow CONVENTIONS.md 3 to 5.

B_03_05_scenarios_lst <- list(
  autarky = list(
    label  = "Alone, With No Bank",
    stage  = "1",
    values = list(),
    story  = paste(
      "There is no bank, so nothing insures a depositor against turning out",
      "to be impatient. Each invests one unit and takes whatever their type",
      "delivers: the share who are impatient (θ) break the investment",
      "and collect the liquidation value (L), while the patient share",
      "(1 − θ) wait and collect the long return (R). The consumption",
      "figure therefore shows the two types on its horizontal axis and one low",
      "bar against one high one on the vertical, and the utility figure",
      "carries only the dashed autarky line, because there is as yet no",
      "contract (c<sub>1</sub>) on its horizontal axis to choose. How wide the",
      "gap is depends on R against L; how much that gap costs depends on risk",
      "aversion (ρ), since a concave utility function makes the spread",
      "itself expensive."
    ),
    prompt = paste(
      "Raise the long return R and watch expected utility rise, but only for",
      "the patient. Raise risk aversion instead: how much worse is the",
      "gamble when you dislike risk more? That gap is what the bank sells."
    )
  ),
  paper = list(
    label  = "The Sample Paper's Contract",
    stage  = "2",
    values = list(c1 = 1.28),
    story  = paste(
      "A bank opens and offers to pay 1.28 on demand at date 1",
      "(c<sub>1</sub> = 1.28), more than the 1 a depositor could raise alone",
      "by liquidating (L), so it is buying insurance for the impatient out of",
      "what the patient would otherwise collect. Funding it means liquidating",
      "θc<sub>1</sub>/L = 32 per cent of the investment, so on the",
      "consumption figure the impatient bar rises to 1.28 while the patient",
      "bar falls from R = 2 to c<sub>2</sub> = 1.813: the two move in",
      "opposite directions, and that transfer is the whole product. On the",
      "utility figure the contract sits on the rising part of the curve, at",
      "c<sub>1</sub> = 1.28 on the horizontal axis and expected utility (EU)",
      "of 0.391 on the vertical, above the dashed autarky line at 0.375. How",
      "large that gain is depends on risk aversion (ρ) and on how much is",
      "destroyed by breaking the investment early, the gap between R and L."
    ),
    prompt = paste(
      "Check the two numbers against the sample paper: c2 = 1.813 and",
      "EU = 0.391. Now raise c1 towards 2: the impatient do better and the",
      "patient worse. Where does expected utility stop rising?"
    )
  ),
  greedy = list(
    label  = "A Contract That Promises Too Much",
    stage  = "2",
    values = list(c1 = 3),
    story  = paste(
      "The bank now promises three units on demand (c<sub>1</sub> = 3), far",
      "more insurance than the technology can pay for, because every unit",
      "handed over at date 1 costs c<sub>1</sub>/L units of investment that",
      "would each have returned R. On the consumption figure the impatient",
      "bar rises with c<sub>1</sub> while the patient bar (c<sub>2</sub>)",
      "collapses towards zero: the vertical axis pulls apart far faster than",
      "the promise itself rises. On the utility figure the contract has moved",
      "past the peak, so further movement right along the c<sub>1</sub> axis",
      "now buys lower expected utility on the vertical one, and EU drops",
      "below the dashed autarky line. The liquidation value (L) sets how",
      "expensive the early payment is and risk aversion (ρ) sets how",
      "heavily the collapse in c<sub>2</sub> is punished."
    ),
    prompt = paste(
      "Expected utility is now below autarky. Bring c1 down until the curve",
      "peaks. What is special about the point where it does?"
    )
  ),
  optimal = list(
    label  = "The Contract the Bank Would Choose",
    stage  = "3",
    values = list(c1 = 1.28),
    story  = paste(
      "The contract is no longer handed to the bank: it chooses",
      "c<sub>1</sub> to maximise expected utility, raising it until a unit",
      "moved to date 1 is worth exactly the R units it costs at date 2,",
      "U′(c<sub>1</sub>) = R U′(c<sub>2</sub>). For this utility",
      "function that fixes the ratio c<sub>2</sub>/c<sub>1</sub> =",
      "R<sup>1/ρ</sup> and gives c<sub>1</sub>* = 1.2815 here — a",
      "genuine maximiser, unlike the thresholds starred later. On the utility",
      "figure the marked optimum is the point on the horizontal",
      "c<sub>1</sub> axis at which expected utility on the vertical axis",
      "stops rising, and on the consumption figure the diamonds sit inside",
      "the autarky bars: above L for the impatient, below R for the patient.",
      "Risk aversion (ρ) decides how far c<sub>1</sub>* is pushed, and",
      "because it is always above L the optimal contract is also the thing",
      "that makes a run possible at the next stage."
    ),
    prompt = paste(
      "Raise risk aversion and watch the optimal c1 rise: a more risk-averse",
      "depositor wants more insurance. Then set ρ close to 0. What contract",
      "does a risk-neutral depositor want, and why?"
    )
  ),
  run = list(
    label  = "Everybody Runs",
    stage  = "4",
    values = list(f_run = 1),
    story  = paste(
      "Every depositor tries to withdraw at date 1 (f = 1), not because",
      "anything has gone wrong with the bank's assets but because each",
      "expects the others to withdraw. Liquidating everything raises only L",
      "per unit, so the bank can pay c<sub>1</sub> to the share f* =",
      "L/c<sub>1</sub> and no further: at this contract that is 78 of the",
      "N = 100 depositors. The queue figure puts position in the queue on the",
      "horizontal axis and the payoff on the vertical and is a cliff —",
      "c<sub>1</sub> up to place 78, nothing after it — while on the",
      "best-response figure the payoff to waiting falls to zero once f passes",
      "f*, so joining the queue pays more than waiting and running is a best",
      "response. The bank is illiquid at fundamental value, not insolvent:",
      "held to date 2 the same assets would pay everyone. f* is a threshold,",
      "not an optimum, and it falls as c<sub>1</sub> rises or L falls."
    ),
    prompt = paste(
      "Read the queue figure. If you believed 90 others were withdrawing,",
      "what would you do? That is the whole model: the belief is what makes",
      "it true."
    )
  ),
  partial = list(
    label  = "A Partial Run",
    stage  = "4",
    values = list(f_run = 0.7),
    story  = paste(
      "Seventy of the hundred withdraw (f = 0.7): more than the impatient",
      "share (θ), but still short of the threshold f* = L/c<sub>1</sub>,",
      "so the bank reaches everyone who comes. On the queue figure every",
      "position up to 70 is paid c<sub>1</sub> in full and the cliff is never",
      "reached. Paying them means liquidating fc<sub>1</sub>/L of the",
      "investment, though, so on the best-response figure the payoff to",
      "waiting on the vertical axis has already fallen a long way as f moved",
      "right along the horizontal axis, and the patient collect far less than",
      "the c<sub>2</sub> the contract promised. Where the two lines cross is",
      "the largest f at which waiting still beats joining the queue;",
      "everything to its right is a run."
    ),
    prompt = paste(
      "Slide the share withdrawing up from 0.25. Find the point where",
      "waiting stops being the better choice. Everything above it is a run."
    )
  ),
  firesale = list(
    label  = "Costly Liquidation",
    stage  = "4",
    values = list(liq = 0.7, f_run = 0.7),
    story  = paste(
      "Breaking the investment early now raises only 0.7 rather than 1",
      "(L = 0.7), the fire-sale case: neither the contract (c<sub>1</sub>)",
      "nor the long return (R) has changed, only what the assets fetch when",
      "they are sold in a hurry. The run threshold f* = L/c<sub>1</sub> moves",
      "left with L, so on the best-response figure the payoff to waiting on",
      "the vertical axis hits zero at a much smaller f on the horizontal one,",
      "and the crossing point at which running becomes a best response moves",
      "left with it. On the queue figure fewer positions are paid",
      "c<sub>1</sub> and the cliff arrives earlier, so a much smaller crowd",
      "is enough to exhaust the bank. Fragility here is the ratio",
      "L/c<sub>1</sub> alone: push L below θc<sub>1</sub> and even the",
      "impatient on their own leave nothing for anyone who waits."
    ),
    prompt = paste(
      "Watch the run threshold fall as L falls. At what liquidation value",
      "does the bank become so fragile that even the impatient alone",
      "exhaust it?"
    )
  ),
  suspend = list(
    label  = "Suspension of Convertibility",
    stage  = "5",
    values = list(f_run = 1),
    policy = "suspend",
    story  = paste(
      "The contract is untouched and everybody still tries to withdraw",
      "(f = 1), but the bank has announced in advance that it will pay only",
      "the impatient share (θ) and then close its doors. That caps the",
      "queue: on the queue figure the paid positions stop at θN, and on",
      "the best-response figure anyone the bank turns away is simply paid at",
      "date 2 instead, so the payoff to waiting no longer collapses as f runs",
      "right along the horizontal axis and sits above the payoff to joining",
      "the queue at every f. The policy figure shows the same reversal as a",
      "pair of bars, waiting above running, so a run is no longer an",
      "equilibrium and only the good one survives. It works because θ is",
      "known exactly; make the impatient share uncertain and the cap turns",
      "away depositors who genuinely needed the money."
    ),
    prompt = paste(
      "Compare the two bars. Then ask the harder question: this works",
      "because we assumed exactly a quarter are impatient. What breaks if",
      "that share is uncertain?"
    )
  ),
  insure = list(
    label  = "Deposit Insurance",
    stage  = "5",
    values = list(f_run = 1),
    policy = "insure",
    story  = paste(
      "Again the contract is untouched and everybody still tries to withdraw",
      "(f = 1), but the government now guarantees the date-2 payment",
      "(c<sub>2</sub>), so a depositor who waits is paid in full whatever",
      "anyone else does. On the best-response figure the payoff to waiting is",
      "then flat in f along the horizontal axis instead of falling to zero",
      "past f* = L/c<sub>1</sub>, and because c<sub>2</sub> exceeds",
      "c<sub>1</sub> the waiting line lies above the queue line everywhere on",
      "the vertical axis. The policy figure shows the same reversal as",
      "suspension, but nobody is turned away, which is why this is the fix",
      "that was adopted. The guarantee removes the belief that sustains the",
      "run and so is never called on; its cost is moral hazard, since a bank",
      "whose depositors cannot run faces less discipline."
    ),
    prompt = paste(
      "The payoffs look the same as under suspension, but nobody is turned",
      "away. What does the bank do differently once its depositors cannot",
      "discipline it by running?"
    )
  )
)

###### B_03_06: Controls #######################################################
# Note: One entry per numeric control: label, range, step and the stage
#   from which it appears.

B_03_06_controls_lst <- list(
  theta = list(label = "Share Who Are Impatient (θ)",
               min = 0.05, max = 0.6, step = 0.05, from = 1),
  ret   = list(label = "Return if Held to Date 2 (R)",
               min = 1, max = 4, step = 0.1, from = 1),
  liq   = list(label = "Value if Liquidated at Date 1 (L)",
               min = 0.4, max = 1, step = 0.05, from = 1),
  rho   = list(label = "Risk Aversion (ρ)",
               min = 0.5, max = 5, step = 0.25, from = 1),
  c1    = list(label = "Promised at Date 1 (c<sub>1</sub>)",
               min = 0.8, max = 3, step = 0.01, from = 2),
  n_dep = list(label = "Number of Depositors (N)",
               min = 20, max = 200, step = 10, from = 4),
  f_run = list(label = "Share Who Withdraw at Date 1 (f)",
               min = 0, max = 1, step = 0.05, from = 4)
)

###### B_03_07: Parameter Explanations #########################################
# Note: Tooltip text: what each control is and what raising it does.

B_03_07_help_lst <- list(
  theta = paste(
    "The probability that any one depositor turns out to need their money",
    "early. Nobody knows their own type at date 0, which is the risk the",
    "bank insures."
  ),
  ret = paste(
    "The long technology's payoff. The higher it is, the more is lost by",
    "liquidating early, and the more there is for the bank to share out."
  ),
  liq = paste(
    "What a unit fetches if it is sold at date 1. Below one it is a fire",
    "sale: the bank's assets are worth less exactly when it needs them, so",
    "it breaks sooner."
  ),
  rho = paste(
    "How much depositors dislike risk. At ρ = 2 utility is 1 − 1/c, the",
    "function on the sample paper. Higher ρ means more insurance is wanted,",
    "so the optimal date-1 payment rises."
  ),
  c1 = paste(
    "The amount the bank promises to anyone who withdraws at date 1. Above",
    "the liquidation value L it is insurance; the higher it is, the more",
    "fragile the bank."
  ),
  n_dep = "How many depositors are in the queue. Only changes the arithmetic.",
  f_run = paste(
    "How many of them actually withdraw at date 1. At θ only the impatient",
    "do, which is the good equilibrium; at 1 everybody does, which is the",
    "run."
  )
)

###### B_03_08: Prompts ########################################################
# Note: One "what to try" prompt per stage, shown above the figures.

B_03_08_prompts_lst <- list(
  "1" = paste(
    "You do not know yet which type you are. Raise risk aversion and watch",
    "expected utility fall: the gamble is between getting 1 and getting 2,",
    "and nothing here insures you against losing it."
  ),
  "2" = paste(
    "Set c1 to 1.28 and check the sample paper's numbers: the patient get",
    "1.813 and expected utility is 0.391, against 0.375 in autarky. Then",
    "move c1 and find where the curve peaks."
  ),
  "3" = paste(
    "The optimal contract sets c2/c1 = R^(1/ρ). Move risk aversion and",
    "watch the optimum move with it. Notice that c1 is always above L and",
    "c2 always below R: the bank is moving consumption from the lucky to",
    "the unlucky."
  ),
  "4" = paste(
    "Slide the share withdrawing from 0.25 up to 1. Find the point where",
    "waiting stops paying better than joining the queue: above it, running",
    "is a best response, and the run is the second equilibrium."
  ),
  "5" = paste(
    "Switch between the three policies with the run set to everybody. Both",
    "fixes remove the run, but only one of them turns depositors away.",
    "Which cost would you rather bear?"
  )
)

###### B_03_09: The Model, Stage by Stage ######################################
# Note: The equations panel. "versions" maps the stage a form first applies
#   to its LaTeX; "notes" says what that version adds. The model is Diamond
#   and Dybvig (1983) as set out in Romer (2019) ch. 10: three dates, an
#   illiquid technology (R if held, L if liquidated), a known share theta of
#   impatient types, CRRA utility, and a demand-deposit contract paid under
#   sequential service. The run threshold f* = L / c1 and the suspension
#   rule "pay at most theta" follow the Part 2 sample paper.

B_03_09_equations_lst <- list(

  # --- The model's equations --------------------------------------------------
  list(
    group = "model", label = "Technology",
    versions = list("1" = paste0("1 \\text{ at } T=0 \\;\\to\\; R",
                                 " \\text{ at } T=2,\\quad L \\text{ if",
                                 " liquidated at } T=1")),
    notes = list(
      "1" = paste("Investment is productive but illiquid: breaking it early",
                  "destroys value, which is the only friction in the model.")
    )
  ),
  list(
    group = "model", label = "Types",
    versions = list("1" = paste0("\\theta \\text{ impatient (consume at }",
                                 "T=1),\\; 1-\\theta \\text{ patient}")),
    notes = list(
      "1" = paste("Nobody knows their type at date 0. That is the risk, and",
                  "it is uninsurable on your own.")
    )
  ),
  list(
    group = "model", label = "Utility",
    versions = list("1" = "U(c) = \\frac{c^{1-\\rho} - 1}{1 - \\rho}"),
    notes = list(
      "1" = paste("At ρ = 2 this is 1 − 1/c, the function on the sample",
                  "paper. Concave, so depositors would pay to smooth.")
    )
  ),
  list(
    group = "model", label = "Deposit Contract",
    versions = list("2" = paste("c_1 \\text{ on demand at } T=1,\\quad",
                                "c_2 \\text{ to whoever waits}")),
    notes = list(
      "2" = paste("A demand deposit: the bank promises a fixed amount to",
                  "anyone who asks at date 1, and shares what is left.")
    )
  ),
  list(
    group = "model", label = "Date-2 Payment",
    versions = list(
      "2" = "c_2 = \\frac{(1 - \\theta c_1 / L)\\,R}{1 - \\theta}",
      "4" = "c_2(f) = \\frac{(1 - f c_1 / L)\\,R}{1 - f}"
    ),
    notes = list(
      "2" = paste("What the patient get when only the impatient withdraw.",
                  "Paying c1 early costs c1/L units of investment."),
      "4" = paste("The same expression with f withdrawing instead of θ. It",
                  "falls as f rises, and hits zero at the run threshold.")
    )
  ),

  # --- Assumptions ------------------------------------------------------------
  list(
    group = "assumption", label = "No Aggregate Uncertainty",
    versions = list("1" = "\\text{exactly } \\theta \\text{ are impatient}"),
    notes = list(
      "1" = paste("The share is known even though each individual's type is",
                  "not. This is what makes suspension work so cleanly, and",
                  "is the assumption to attack.")
    )
  ),
  list(
    group = "assumption", label = "Private Information",
    versions = list("2" = "\\text{type is not observable}"),
    notes = list(
      "2" = paste("The bank cannot pay only the genuinely impatient, so it",
                  "must offer the same contract to anyone who asks. Without",
                  "this there is no run.")
    )
  ),
  list(
    group = "assumption", label = "The Bank Breaks Even",
    versions = list("2" = "\\text{zero profit; depositors own the bank}"),
    notes = list(
      "2" = paste("The bank is a mutual arrangement between depositors, not",
                  "a profit-maximiser.")
    )
  ),
  list(
    group = "assumption", label = "Sequential Service",
    versions = list("4" = "\\text{first come, first served}"),
    notes = list(
      "4" = paste("The bank pays in the order people arrive, and cannot",
                  "wait to see how many will come. This is what makes the",
                  "queue a race.")
    )
  ),

  # --- Solved forms -----------------------------------------------------------
  list(
    group = "solved", label = "Autarky",
    versions = list("1" = "EU^{aut} = \\theta U(L) + (1-\\theta) U(R)"),
    notes = list(
      "1" = paste("At the sample paper's numbers this is 0.375. Nothing",
                  "smooths between the two outcomes.")
    )
  ),
  list(
    group = "solved", label = "Expected Utility",
    versions = list("2" = "EU = \\theta U(c_1) + (1-\\theta) U(c_2)"),
    notes = list(
      "2" = paste("With c1 = 1.28 this is 0.391, above autarky. The bank",
                  "has made everyone better off before anyone knows their",
                  "type.")
    )
  ),
  list(
    group = "solved", label = "Optimality",
    versions = list("3" = "U'(c_1) = R\\,U'(c_2)"),
    notes = list(
      "3" = paste("A euro moved to date 1 costs R euro at date 2. At the",
                  "optimum the bank is indifferent.")
    )
  ),
  list(
    group = "solved", label = "Optimal Ratio",
    versions = list("3" = "\\frac{c_2}{c_1} = R^{1/\\rho}"),
    notes = list(
      "3" = paste("For CRRA utility the optimality condition collapses to",
                  "this. At R = 2 and ρ = 2 the ratio is √2.")
    )
  ),
  list(
    group = "solved", label = "Optimal Contract",
    versions = list("3" = paste0("c_1^* = \\frac{R}{R^{1/\\rho}(1-\\theta)",
                                 " + \\theta R / L}")),
    notes = list(
      "3" = paste("At the sample paper's calibration this is 1.2815. The",
                  "1.28 in the question is the optimum, not an arbitrary",
                  "number.")
    )
  ),
  list(
    group = "solved", label = "Run Threshold",
    versions = list("4" = "f^* = \\frac{L}{c_1}"),
    notes = list(
      "4" = paste("Liquidating everything raises L per unit, so the bank can",
                  "pay c1 to this share and no more. With L = 1 and",
                  "c1 = 1.28 it is 78 of 100 depositors.")
    )
  ),
  list(
    group = "solved", label = "Under Suspension",
    versions = list("5" = "\\text{pay at most } \\theta,\\ \\text{then close}"),
    notes = list(
      "5" = paste("The queue stops at θ, so a patient depositor who joins it",
                  "gains nothing and waiting always pays c2.")
    )
  ),

  # --- Descriptors ------------------------------------------------------------
  list(
    group = "descriptor", label = "Insurance",
    versions = list("3" = "L < c_1 \\quad\\text{and}\\quad c_2 < R"),
    notes = list(
      "3" = paste("The bank pays the unlucky more than they could get alone",
                  "and the lucky less. That transfer is the whole product.")
    )
  ),
  list(
    group = "descriptor", label = "The Good Equilibrium",
    versions = list("4" = "f = \\theta:\\quad c_2 > c_1"),
    notes = list(
      "4" = paste("Only the impatient withdraw, and waiting pays more than",
                  "withdrawing, so the patient are happy to wait.")
    )
  ),
  list(
    group = "descriptor", label = "The Run Equilibrium",
    versions = list("4" = "f = 1:\\quad c_2(1) = 0 < c_1"),
    notes = list(
      "4" = paste("If everyone else withdraws, waiting pays nothing, so",
                  "withdrawing is a best response. Both are equilibria; the",
                  "model does not say which happens.")
    )
  ),
  list(
    group = "descriptor", label = "Why Runs Happen",
    versions = list("4" = "\\text{self-fulfilling beliefs}"),
    notes = list(
      "4" = paste("Nothing is wrong with the bank's assets. The run is",
                  "caused by the expectation of a run, which is why it can",
                  "hit a solvent bank.")
    )
  )
)

###### B_03_10: Equation Group Titles ##########################################
# Note: Group headings for the equations tabs.

B_03_10_groups_vec <- c(
  model      = "Model Equations",
  assumption = "Assumptions",
  solved     = "Solved Forms",
  descriptor = "Descriptors"
)

###### B_03_11: Notation Key ###################################################
# Note: Notation tab. Groups: var, par, flw (thresholds and solved values),
#   each with the stage it first appears in.

B_03_11_notation_lst <- list(
  list(grp = "var", sym = "T = 0, 1, 2", txt = "the three dates", from = 1),
  list(grp = "var", sym = "c_1", txt = "consumption at date 1", from = 1),
  list(grp = "var", sym = "c_2", txt = "consumption at date 2", from = 1),
  list(grp = "var", sym = "EU", txt = "expected utility before types are known",
       from = 1),
  list(grp = "par", sym = "\\theta", txt = "share who are impatient", from = 1),
  list(grp = "par", sym = "R", txt = "return if held to date 2", from = 1),
  list(grp = "par", sym = "L", txt = "value if liquidated at date 1", from = 1),
  list(grp = "par", sym = "\\rho", txt = "risk aversion", from = 1),
  list(grp = "par", sym = "N", txt = "number of depositors", from = 1),
  list(grp = "flw", sym = "c_1^*", txt = "the optimal date-1 payment",
       from = 3),
  list(grp = "flw", sym = "c_2^*", txt = "what the patient receive under it",
       from = 3),
  list(grp = "var", sym = "f", txt = "share who withdraw at date 1", from = 4),
  list(grp = "flw", sym = "f^*",
       txt = "share the bank can pay before its assets are gone", from = 4),
  list(grp = "flw", sym = "c_2(f)", txt = "what waiting pays when f withdraw",
       from = 4)
)

###### B_03_12: Notation Columns ###############################################
# Note: How the notation tab is split into columns.

B_03_12_nota_cols_lst <- list(
  "Variables"   = "var",
  "Parameters"  = "par",
  "Thresholds"  = "flw"
)

###### B_03_13: Tall Figure Height #############################################
# Note: Height of each main figure in the browser.

B_03_13_tall_chr <- "420px"

###### B_03_14: Short Figure Height ############################################
# Note: Height of the queue strip.

B_03_14_short_chr <- "260px"

###### B_03_15: Recalculation Delay ############################################
# Note: Milliseconds to wait before recalculating after a change.

B_03_15_debounce_ms_int <- 250L

###### B_03_16: Version ########################################################
# Note: Semantic version, shown in the footer; CHANGELOG.md has the history.

B_03_16_version_chr <- "1.0.8"

###### B_03_17: Source Repository ##############################################
# Note: The GitHub repo, linked from the footer.

B_03_17_repo_chr <- paste0("https://github.com/Sam-Deegan/",
                        "Interactive-Model-Diamond-Dybvig")

#### B_04: Paths ###############################################################
# Note: The QR code only.

###### B_04_01: QR Code Source #################################################
# Note: From the toolkit: www/ first, then the shared folder.

B_04_01_qr_src_chr <- T_07_04_qr_fn()

################################################################################
## D: Plots ####################################################################
################################################################################
# Note: Builders only; each returns a ggplot for the server to draw.

#### D_01: Consumption and Expected Utility ####################################
# Note: What the bank does for depositors, before any run is mentioned.

###### D_01_01: The Consumption Bundle #########################################
# Note: What each type consumes under each plan. Stages 1 to 3 set the bank
#   against autarky; stages 4 and 5 set the good equilibrium against the run.
#   No ghost (CONVENTIONS.md 8).

D_01_01_bundle_fn <- function(par, stage) {
  aut <- C_01_02_autarky_fn(par)
  con <- C_01_03_contract_fn(par, par$c1)
  opt <- C_01_05_optimal_fn(par)
  pol_lab <- c(none = "No Policy", suspend = "With Suspension",
               insure = "With Deposit Insurance")[[par$policy]]

  lvls <- c("Autarky", "With the Bank", "If Everybody Runs", pol_lab)
  rows <- list()

  if (stage < 5) {
    rows <- c(rows, list(
      data.frame(who = "Impatient (date 1)", plan = "Autarky", value = aut$c1),
      data.frame(who = "Patient (date 2)", plan = "Autarky", value = aut$c2)
    ))
  }
  if (stage >= 2) {
    rows <- c(rows, list(
      data.frame(who = "Impatient (date 1)", plan = "With the Bank",
                 value = con$c1),
      data.frame(who = "Patient (date 2)", plan = "With the Bank",
                 value = max(con$c2, 0))
    ))
  }
  if (stage >= 4) {
    # In a full run either type expects share * c1
    run_v <- C_01_07_run_fn(par, par$c1)$share * par$c1
    rows <- c(rows, list(
      data.frame(who = "Impatient (date 1)", plan = "If Everybody Runs",
                 value = run_v),
      data.frame(who = "Patient (date 2)", plan = "If Everybody Runs",
                 value = run_v)
    ))
  }
  if (stage >= 5 && par$policy != "none") {
    # The cap at theta pays the impatient in full; the patient get the rest
    rows <- c(rows, list(
      data.frame(who = "Impatient (date 1)", plan = pol_lab, value = con$c1),
      data.frame(who = "Patient (date 2)", plan = pol_lab,
                 value = max(C_01_08_wait_fn(par, par$c1, par$theta,
                                             par$theta), 0))
    ))
  }

  df <- do.call(rbind, rows)
  df$plan <- factor(df$plan, levels = lvls)
  df$plan <- droplevels(df$plan)

  # Reference levels on the right-hand axis: L, and from stage 3 c1* and c2*
  mark_at  <- par$liq
  mark_lab <- expression(L)
  if (stage >= 3) {
    mark_at  <- c(par$liq, opt$c1, opt$c2)
    mark_lab <- expression(L, c[1]^"*", c[2]^"*")
  }
  y_hi <- max(c(df$value, mark_at), na.rm = TRUE) * 1.18

  p <- ggplot(df, aes(x = who, y = value, fill = plan)) +
    T_02_02_zero_fn(h = TRUE, v = FALSE) +
    T_02_02_rest_fn(h = mark_at) +
    geom_col(position = position_dodge(width = 0.7), width = 0.62) +
    geom_text(aes(label = T_02_05_num_fn(value)),
              position = position_dodge(width = 0.7), vjust = -0.45,
              size = 4, colour = T_01_01_palette_vec[["navy"]]) +
    scale_fill_manual(values = stats::setNames(
      c(T_01_02_series_vec[["compare"]], T_01_02_series_vec[["main"]],
        T_01_01_palette_vec[["muted"]], T_01_02_series_vec[["third"]]),
      lvls
    ), drop = TRUE) +
    T_02_02_mark_y_fn(mark_at, mark_lab) +
    coord_cartesian(ylim = c(0, y_hi)) +
    labs(
      title = if (stage >= 5 && par$policy != "none") {
        "The Consumption Bundle Under the Policy"
      } else if (stage >= 4) {
        "The Consumption Bundle in Both Equilibria"
      } else if (stage >= 2) {
        "The Consumption Bundle: Autarky and the Bank"
      } else {
        "The Consumption Bundle Under Autarky"
      },
      x = NULL, y = expression(bold("Consumption (" * c * ")")),
      caption = if (stage >= 5 && par$policy != "none") {
        paste0("Nothing about the contract has changed. The policy rules out ",
               "the run equilibrium, so the promised payments are what ",
               "depositors actually get. Set the policy to None to put the ",
               "grey bars back.")
      } else if (stage >= 4) {
        paste0("The grey bars are the same contract in its other ",
               "equilibrium: the bank can serve only ",
               T_02_06_pct_fn(C_01_07_run_fn(par, par$c1)$share),
               " of the queue, so everybody expects that share of c1 and ",
               "the patient depositor who waits gets nothing.")
      } else if (stage >= 2) {
        paste0("The bank liquidates ",
               T_02_06_pct_fn(C_01_03_contract_fn(par, par$c1)$liquidated),
               " of its investment to pay the impatient.")
      } else {
        "An impatient consumer must break the investment and take L."
      }
    ) +
    T_02_01_theme_fn()

  p
}

###### D_01_02: Expected Utility Across Contracts ##############################
# Note: Expected utility over the range of contracts. Autarky is the dotted
#   reference, the optimum is marked, the contract in force is the open point,
#   and a ghost repeats all three at the reference settings.

D_01_02_curve_fn <- function(par, stage, ref = NULL) {
  crv <- C_01_06_curve_fn(par)
  crv <- crv[is.finite(crv$eu), ]
  aut <- C_01_02_autarky_fn(par)
  opt <- C_01_05_optimal_fn(par)
  now <- C_01_04_eu_fn(par, par$c1)

  # Window set around the gain the bank delivers; the curve is clipped to it
  span <- max(opt$eu - aut$eu, abs(aut$eu) * 0.05, 1e-6)
  y_lo <- aut$eu - 5 * span
  y_hi <- opt$eu + 1.5 * span
  crv  <- crv[crv$eu >= y_lo, , drop = FALSE]

  # Autarky and the maximum named on the right-hand axis; c1* along the top
  mark_y_at  <- aut$eu
  mark_y_lab <- expression(EU^aut)
  if (stage >= 3) {
    mark_y_at  <- c(aut$eu, opt$eu)
    mark_y_lab <- expression(EU^aut, EU(c[1]^"*"))
  }

  # Ghost clipped to the live window so the panel does not jump
  ghost_lyr <- if (T_02_03b_ghost_off_fn(par, ref)) NULL else {
    g_crv <- C_01_06_curve_fn(ref)
    g_crv <- g_crv[is.finite(g_crv$eu) & g_crv$eu >= y_lo, , drop = FALSE]
    g_opt <- C_01_05_optimal_fn(ref)
    g_now <- C_01_04_eu_fn(ref, ref$c1)
    c(
      if (nrow(g_crv) > 0) {
        list(T_02_03a_ghost_line_fn(g_crv, aes(x = c1, y = eu),
                                    colour = T_01_02_series_vec[["main"]],
                                    linewidth = 1.1))
      },
      if (stage >= 3 && is.finite(g_opt$eu)) {
        list(annotate("point", x = g_opt$c1, y = g_opt$eu, size = 3.2,
                      colour = T_01_01_palette_vec[["blue"]],
                      alpha = T_01_04_ghost_alpha_num))
      },
      if (stage >= 2 && is.finite(g_now)) {
        list(T_02_03a_ghost_point_fn(ref$c1, g_now))
      }
    )
  }

  p <- ggplot(crv, aes(x = c1, y = eu)) +
    T_02_02_zero_fn(h = TRUE, v = FALSE) +
    T_02_02_rest_fn(h = mark_y_at, v = if (stage >= 3) opt$c1) +
    ghost_lyr +
    geom_line(colour = T_01_02_series_vec[["main"]], linewidth = 1.1) +
    T_02_02_mark_y_fn(mark_y_at, mark_y_lab) +
    coord_cartesian(ylim = c(y_lo, y_hi)) +
    labs(
      title = "Expected Utility of the Deposit Contract",
      x = expression(bold("Date-1 payment (" * c[1] * ")")),
      y = expression(bold("Expected utility (" * EU * ")")),
      caption = paste0(
        "Ex ante, before anyone knows their type. Anything above the autarky",
        " level beats going it alone."
      )
    ) +
    T_02_01_theme_fn()

  if (stage >= 3) {
    p <- p +
      T_02_02_mark_x_fn(opt$c1, expression(c[1]^"*")) +
      annotate("point", x = opt$c1, y = opt$eu, size = 3.2,
               colour = T_01_01_palette_vec[["blue"]])
  }
  if (stage >= 2 && is.finite(now)) {
    p <- p + T_02_03_point_fn(par$c1, now)
  }
  p
}

#### D_02: The Run #############################################################
# Note: Best responses, and the queue that makes running rational.

###### D_02_01: Waiting Against Running ########################################
# Note: A patient depositor's payoff from waiting and from joining the queue,
#   against the share withdrawing. Where the two cross the good equilibrium
#   ends.

D_02_01_best_fn <- function(par, cap = NULL, ref = NULL, ref_cap = NULL) {
  grid <- seq(0, 0.999, length.out = 400)
  br   <- C_01_09_best_fn(par, par$c1, grid, cap)

  # Ghost: both payoffs at the reference settings, with the reference's cap
  ghost_lyr <- if (T_02_03b_ghost_off_fn(par, ref)) NULL else {
    g <- C_01_09_best_fn(ref, ref$c1, grid, ref_cap)
    list(
      T_02_03a_ghost_line_fn(data.frame(f = g$f, value = g$wait),
                             aes(x = f, y = value),
                             colour = T_01_02_series_vec[["main"]],
                             linewidth = 1.1),
      T_02_03a_ghost_line_fn(data.frame(f = g$f, value = g$run),
                             aes(x = f, y = value),
                             colour = T_01_02_series_vec[["compare"]],
                             linewidth = 1.1)
    )
  }

  long <- rbind(
    data.frame(f = br$f, value = br$wait, line = "Wait until Date 2"),
    data.frame(f = br$f, value = br$run,  line = "Join the Queue Now")
  )
  long$line <- factor(long$line,
                      levels = c("Wait until Date 2", "Join the Queue Now"))

  run_share <- C_01_07_run_fn(par, par$c1)$share
  y_hi  <- max(long$value[is.finite(long$value)], par$c1) * 1.12
  x_lim <- c(0, 1)
  y_lim <- c(0, y_hi)

  # theta and f* named along the top; c1 on the right
  if (is.null(cap) && run_share < 1 && abs(run_share - par$theta) > 5e-3) {
    rest_v   <- c(par$theta, run_share)
    rest_lab <- expression(theta, f^"*")
  } else {
    rest_v   <- par$theta
    rest_lab <- expression(theta)
  }

  # Name the flat payoff at the end of its flat stretch: running pays c1 with
  # no cap, waiting pays c2(theta) under one. See CONVENTIONS.md 6
  # The inset keeps the name off the dotted f* vertical
  if (is.null(cap)) {
    lab_x   <- min(max(run_share, 0.30), 1) - 0.015
    lab_y   <- par$c1
    lab_txt <- "'Run  '*c[1]"
  } else {
    lab_x   <- 1 - 0.015
    lab_y   <- C_01_08_wait_fn(par, par$c1, cap, cap)
    lab_txt <- "'Wait  '*c[2](theta)"
  }

  ggplot(long, aes(x = f, y = value, colour = line)) +
    T_02_02_zero_fn(h = TRUE, v = FALSE) +
    T_02_02_rest_fn(v = rest_v) +
    ghost_lyr +
    geom_line(linewidth = 1.1) +
    scale_colour_manual(values = c(
      "Wait until Date 2"  = T_01_02_series_vec[["main"]],
      "Join the Queue Now" = T_01_02_series_vec[["compare"]]
    )) +
    T_02_02_mark_x_fn(rest_v, rest_lab) +
    T_02_02_mark_y_fn(par$c1, expression(c[1])) +
    coord_cartesian(xlim = x_lim, ylim = y_lim, expand = FALSE) +
    annotate("text", x = lab_x, y = lab_y,
             label = lab_txt, parse = TRUE, size = 3.2,
             hjust = 1, vjust = -1.15,
             colour = T_01_01_palette_vec[["muted"]]) +
    labs(
      # Folded at 30 so the title fits the narrow slide export
      title = T_02_01b_fold_fn(
        "Best Response of a Patient Depositor: Wait or Run", 30),
      x = expression(bold("Share withdrawing at date 1 (" * f * ")")),
      y = expression(bold("Payoff (" * c * ")")),
      caption = if (is.null(cap)) {
        paste0("Waiting pays nothing once more than ",
               T_02_06_pct_fn(run_share),
               " withdraw: past there the bank has liquidated everything.")
      } else {
        paste0("With the queue capped at ", T_02_06_pct_fn(cap),
               ", waiting always pays more than joining it.")
      }
    ) +
    T_02_01_theme_fn(grid = "none")
}

###### D_02_02: The Queue ######################################################
# Note: Payoff by position in the queue: c1 up to the cliff, nothing after
#   it. The cliff is named on the axis as f*N. No ghost (CONVENTIONS.md 8).

D_02_02_queue_fn <- function(par, cap = NULL) {
  q <- C_01_10_queue_fn(par, par$c1, par$f_run, cap)
  q <- q[!is.na(q$payoff), , drop = FALSE]
  if (nrow(q) == 0) {
    return(T_02_02_placeholder_fn(
      "Nobody withdraws at date 1.\nMove the share withdrawing above zero."))
  }
  # A turned-away bar has no height, so its key says what it is worth
  q$status <- ifelse(q$paid, "Paid in Full", "Turned Away, Paid Nothing")

  # The cliff is f* of N depositors, named along the top; c1 on the right
  cliff <- C_01_07_run_fn(par, par$c1)$depositors

  p <- ggplot(q, aes(x = place, y = payoff, fill = status)) +
    T_02_02_zero_fn(h = TRUE, v = FALSE) +
    T_02_02_rest_fn(h = par$c1, v = if (cliff < par$n_dep) cliff) +
    geom_col(width = 1) +
    scale_fill_manual(values = c(
      "Paid in Full"              = T_01_02_series_vec[["main"]],
      "Turned Away, Paid Nothing" = T_01_02_series_vec[["reference"]]
    )) +
    T_02_02_mark_y_fn(par$c1, expression(c[1])) +
    coord_cartesian(ylim = c(0, par$c1 * 1.18)) +
    labs(
      title = "Sequential Service: Payoff by Position in the Queue",
      x = expression(bold("Position in the queue (1 to " * N * ")")),
      y = expression(bold("Payoff (" * c[1] * ")")),
      caption = paste0(
        "The bank can pay ", T_02_05_num_fn(par$c1), " to ",
        C_01_07_run_fn(par, par$c1)$last_paid, " of its ", par$n_dep,
        " depositors. Everyone after that gets nothing, and so does anyone",
        " who waited."
      )
    ) +
    T_02_01_theme_fn()

  if (cliff < par$n_dep) {
    p <- p + T_02_02_mark_x_fn(cliff, expression(f^"*" * N))
  }
  p
}

#### D_03: Policies ############################################################
# Note: What each fix does to the run equilibrium.

###### D_03_01: Policy Comparison ##############################################
# Note: The payoff from waiting and from running when everybody runs, under
#   each policy. A run is an equilibrium only where the right bar is taller.
#   No ghost (CONVENTIONS.md 8).

D_03_01_policy_fn <- function(par) {
  rows <- lapply(names(B_03_03_policies_vec), function(pol) {
    eq <- C_01_12_policy_fn(par, par$c1, B_03_03_policies_vec[[pol]])$equilibria
    data.frame(
      policy = pol,
      wait   = eq$run_wait,
      run    = eq$run_payoff,
      exists = eq$run_exists,
      stringsAsFactors = FALSE
    )
  })
  df <- do.call(rbind, rows)
  df$policy <- factor(df$policy, levels = names(B_03_03_policies_vec))

  long <- rbind(
    data.frame(policy = df$policy, value = df$wait,
               choice = "Wait until Date 2"),
    data.frame(policy = df$policy, value = df$run,
               choice = "Join the Queue Now")
  )
  long$choice <- factor(long$choice,
                        levels = c("Wait until Date 2", "Join the Queue Now"))

  labels <- data.frame(
    policy = df$policy,
    y      = pmax(df$wait, df$run),
    text   = ifelse(df$exists, "A run is an equilibrium",
                    "No run equilibrium")
  )

  # c1 is the dotted level every bar is read against
  y_hi <- max(c(long$value, par$c1), na.rm = TRUE) * 1.22

  ggplot(long, aes(x = policy, y = value, fill = choice)) +
    T_02_02_zero_fn(h = TRUE, v = FALSE) +
    T_02_02_rest_fn(h = par$c1) +
    geom_col(position = position_dodge(width = 0.72), width = 0.62) +
    geom_text(data = labels, aes(x = policy, y = y, label = text),
              inherit.aes = FALSE, vjust = -1.1, size = 3.9,
              fontface = "bold", colour = T_01_01_palette_vec[["navy"]]) +
    scale_fill_manual(values = c(
      "Wait until Date 2"  = T_01_02_series_vec[["main"]],
      "Join the Queue Now" = T_01_02_series_vec[["compare"]]
    )) +
    T_02_02_mark_y_fn(par$c1, expression(c[1])) +
    coord_cartesian(ylim = c(0, y_hi)) +
    labs(
      title = "Payoffs in the Run Equilibrium Under Each Policy",
      x = NULL, y = expression(bold("Payoff (" * c * ")")),
      caption = paste(
        "A run survives only where joining the queue pays more than waiting.",
        "Both fixes reverse that; only one of them turns depositors away."
      )
    ) +
    T_02_01_theme_fn()
}

################################################################################
## E: User Interface ###########################################################
################################################################################
# Note: bslib page: controls in a sidebar, figures in cards.

#### E_01: Sidebar #############################################################
# Note: Stage selector, then the controls. The sidebar chooses the model;
#   the main window chooses what to run in it (CONVENTIONS.md 1).

###### E_01_01: Control Shorthand ##############################################
# Note: Toolkit control builder with this app's three lists filled in.

E_01_01_ctl_fn <- function(id) {
  T_03_01_control_fn(id, B_03_06_controls_lst, B_03_07_help_lst,
                     B_03_01_defaults_lst)
}

###### E_01_02: Sidebar ########################################################
# Note: conditionalPanel reveals controls as the stages add layers.

E_01_02_sidebar_lst <- sidebar(
  width = 380,
  radioButtons("stage", "Stage of the Model",
               choices = B_03_02_stages_vec, selected = "1"),
  T_03_05_note_fn(paste(
    "Each stage adds one piece to the model and leaves the rest",
    "alone. Start at the top; the equations panel marks what is new.")),
  accordion(
    open = c("The Bank", "The Run"),
    accordion_panel(
      "The Bank",
      conditionalPanel("parseFloat(input.stage) >= 2",
                       E_01_01_ctl_fn("c1")),
      conditionalPanel("parseFloat(input.stage) < 2",
                       tags$p(class = "stat-caption",
                              paste("There is no bank yet. Move to stage 2",
                                    "to set a deposit contract.")))
    ),
    accordion_panel(
      "The Run",
      conditionalPanel(
        "parseFloat(input.stage) >= 4",
        E_01_01_ctl_fn("f_run"),
        E_01_01_ctl_fn("n_dep")
      ),
      conditionalPanel(
        "parseFloat(input.stage) >= 5",
        radioButtons("policy", "Policy", choices = B_03_03_policies_vec,
                     selected = "none")
      ),
      conditionalPanel("parseFloat(input.stage) < 4",
                       tags$p(class = "stat-caption",
                              "The run appears at stage 4."))
    ),
    accordion_panel(
      "Depositors and Technology",
      E_01_01_ctl_fn("theta"),
      E_01_01_ctl_fn("rho"),
      tags$h6("The Investment"),
      E_01_01_ctl_fn("ret"),
      E_01_01_ctl_fn("liq")
    )
  ),
  actionButton("reset", "Reset Everything",
               class = "btn-outline-secondary btn-sm w-100"),
  T_07_10b_sidebarqr_fn(B_04_01_qr_src_chr)
)

#### E_02: Main Panel ##########################################################
# Note: Equations card, presets, prompt, readouts, then the figures.

###### E_02_01: Worked-Example Presets #########################################
# Note: Preset card for the main window, from the toolkit (T_05_04 to
#   T_05_07). Only the current stage's presets show.

E_02_01_presets_lst <- T_05_04_presets_fn(
  B_03_05_scenarios_lst, B_03_02_stages_vec, stage_word = "Stage"
)

###### E_02_02: Page ###########################################################
# Note: The UI passed to shinyApp().

E_02_02_app_ui_lst <- tagList(
  T_07_08b_nav_fn(),
  page_sidebar(
  title        = T_07_09_title_fn("Diamond and Dybvig: Bank Runs",
                                  B_04_01_qr_src_chr),
  window_title = paste("Diamond and Dybvig ·", T_07_01_author_chr),
  fillable     = FALSE,
  theme        = T_07_05_theme_fn(),
  sidebar      = E_01_02_sidebar_lst,
  T_07_08_head_fn(),
  tags$head(
    tags$style(HTML(T_05_07_preset_css_chr)),
    tags$script(HTML(T_05_05_preset_js_chr))
  ),
  navset_card_tab(
    title = textOutput("eq_title", inline = TRUE),
    nav_panel("Equations", uiOutput("eq_model")),
    nav_panel("Notation", uiOutput("eq_notation")),
    nav_panel("In Words", uiOutput("eq_explain"))
  ),
  E_02_01_presets_lst,
  uiOutput("prompt"),
  uiOutput("problems"),
  tags$div(class = "stat-caption",
           "Readouts. Defaults reproduce the worked example on the Part 2",
           "sample paper."),
  uiOutput("tiles"),
  layout_columns(
    col_widths = breakpoints(sm = 12, xl = c(5, 7)),
    T_07_07c_figcard_fn("bundle", "What Each Type Consumes",
                          B_03_13_tall_chr),
    T_07_07c_figcard_fn("curve", "Expected Utility Across Contracts",
                          B_03_13_tall_chr)
  ),
  conditionalPanel(
    "parseFloat(input.stage) >= 4",
    layout_columns(
      col_widths = breakpoints(sm = 12, xl = c(6, 6)),
      T_07_07c_figcard_fn("best", "Wait, or Join the Queue?",
                          B_03_13_tall_chr),
      card(
        card_header("The Queue, One Depositor at a Time"),
        plotOutput("queue", height = B_03_14_short_chr),
        uiOutput("queue_note")
      )
    )
  ),
  conditionalPanel(
    "parseFloat(input.stage) >= 5",
    card(
      card_header("What Each Policy Does to the Run"),
      plotOutput("policy_plot", height = B_03_13_tall_chr),
      uiOutput("policy_note")
    )
  ),
  T_07_11_footer_fn(paste0("Model and notation follow Diamond and Dybvig ",
                           "(1983) and Romer, chapter 10. Version ",
                           B_03_16_version_chr, "."), repo = B_03_17_repo_chr),
))

################################################################################
## F: Server ###################################################################
################################################################################
# Note: Assembles the stage's parameters, solves the model, draws.

#### F_01: Server Function #####################################################
# Note: Everything reactive lives here.

###### F_01_01: Server #########################################################
# Note: Local objects are plain snake_case.

F_01_01_app_server_fn <- function(input, output, session) {

  # --- Figure captions --------------------------------------------------------
  # Captions are printed under the figure, not drawn in the panel
  T_07_07d_cap_fn(output)

  # --- Stage as a number ------------------------------------------------------
  stage_num <- reactive(as.numeric(input$stage))

  # --- Controls ---------------------------------------------------------------
  val <- function(id) T_03_04_val_fn(input, id)
  T_03_02_sync_fn(input, session, B_03_06_controls_lst)

  set_control <- function(id, value) {
    T_03_03_set_fn(session, B_03_06_controls_lst, id, value)
  }

  # --- Worked-example presets -------------------------------------------------
  # Buttons exist for every stage's scenarios; conditionalPanel shows them
  scenario <- reactiveVal(names(B_03_05_scenarios_lst)[1])

  # Guarded lookup of the loaded scenario
  scn_now <- reactive({
    k <- scenario()
    if (is.null(k) || !k %in% names(B_03_05_scenarios_lst)) NULL
    else B_03_05_scenarios_lst[[k]]
  })

  set_scenario_fn <- function(key) {
    scenario(if (is.null(key)) "custom" else key)
    session$sendCustomMessage("dgPreset", if (is.null(key)) "" else key)
    invisible(NULL)
  }

  # The policy radio is not a numeric control, so it is set separately
  load_preset_fn <- function(key) {
    if (is.null(key) || !key %in% names(B_03_05_scenarios_lst)) {
      return(invisible(NULL))
    }
    scn <- B_03_05_scenarios_lst[[key]]
    set_scenario_fn(key)
    for (id in names(B_03_06_controls_lst)) {
      set_control(id, if (!is.null(scn$values[[id]])) scn$values[[id]]
                  else B_03_01_defaults_lst[[id]])
    }
    updateRadioButtons(session, "policy",
                       selected = if (!is.null(scn$policy)) scn$policy
                                  else "none")
    invisible(NULL)
  }

  lapply(names(B_03_05_scenarios_lst), function(key) {
    observeEvent(input[[paste0("preset_", key)]],
                 load_preset_fn(key), ignoreInit = TRUE)
  })

  # First scenario of a stage, or NULL
  first_preset_fn <- function(stage) {
    hits <- names(B_03_05_scenarios_lst)[vapply(
      B_03_05_scenarios_lst, function(x) identical(x$stage, stage), TRUE)]
    if (length(hits) == 0L) NULL else hits[[1L]]
  }

  # Every stage opens on its own first worked example
  observeEvent(input$stage, {
    first <- first_preset_fn(input$stage)
    if (!is.null(first)) load_preset_fn(first) else set_scenario_fn(NULL)
  })

  output$preset_title <- renderUI({
    T_05_06_preset_title_fn(scn_now(), input$stage, B_03_02_stages_vec,
                            stage_word = "Stage")
  })

  # --- Reset ------------------------------------------------------------------
  observeEvent(input$reset, {
    set_scenario_fn(NULL)
    updateRadioButtons(session, "policy", selected = "none")
    for (id in names(B_03_06_controls_lst)) {
      set_control(id, B_03_01_defaults_lst[[id]])
    }
  })

  # --- Parameters in force at this stage --------------------------------------
  # Before stage 2 there is no bank, so c1 = L; before stage 4 nobody runs
  # A pure function of the values and the stage, so the ghost uses it too
  assemble_fn <- function(v, s) {
    list(
      theta  = v$theta,
      ret    = v$ret,
      liq    = v$liq,
      rho    = v$rho,
      c1     = if (s >= 2) v$c1 else v$liq,
      n_dep  = round(v$n_dep),
      f_run  = if (s >= 4) v$f_run else v$theta,
      policy = if (s >= 5 && !is.null(v$policy)) v$policy else "none"
    )
  }

  # The cap a policy puts on the queue, for the live figures and the ghosts
  cap_fn <- function(p) {
    if (!is.null(p) && p$policy %in% c("suspend", "insure")) p$theta else NULL
  }

  par_raw <- reactive({
    req(!is.null(input$theta))
    vals <- stats::setNames(lapply(names(B_03_06_controls_lst), val),
                            names(B_03_06_controls_lst))
    vals$policy <- if (is.null(input$policy)) "none" else input$policy
    # Guards the instant before the first flush
    req(all(vapply(vals[names(B_03_06_controls_lst)],
                   function(x) length(x) == 1L && is.finite(x), TRUE)))
    assemble_fn(vals, stage_num())
  })

  par_now  <- debounce(par_raw, B_03_15_debounce_ms_int)
  diag_now <- reactive(C_01_13_diagnostics_fn(par_now()))
  ok_now   <- reactive(length(diag_now()$problems) == 0)
  cap_now  <- reactive(cap_fn(par_now()))

  # --- The ghost: this figure at the worked example's own settings ------------
  # Reference: the loaded example's values, else the defaults. See
  # CONVENTIONS.md 8
  ref_vals <- reactive({
    base <- c(B_03_01_defaults_lst, list(policy = "none"))
    scn  <- scn_now()
    if (is.null(scn)) return(base)
    v <- utils::modifyList(base, scn$values)
    v$policy <- if (is.null(scn$policy)) "none" else scn$policy
    v
  })

  ref_par <- reactive(assemble_fn(ref_vals(), stage_num()))

  # NULL when the reference matches the sliders or cannot be solved
  ghost_par <- reactive({
    ref <- ref_par()
    if (T_02_03b_ghost_off_fn(par_now(), ref)) return(NULL)
    if (length(C_01_14_problems_fn(ref)) > 0) return(NULL)
    ref
  })

  ghost_cap <- reactive(cap_fn(ghost_par()))

  # --- Scenario story ---------------------------------------------------------
  output$scenario_story <- renderUI({
    T_05_02_story_fn(scn_now(), B_03_06_controls_lst, B_03_07_help_lst)
  })

  # --- The model so far -------------------------------------------------------
  output$eq_title <- renderText({
    T_05_04_stage_name_fn(B_03_02_stages_vec, input$stage)
  })

  eq_items <- reactive(T_06_03_items_fn(B_03_09_equations_lst, stage_num()))

  output$eq_model <- renderUI({
    T_06_04_model_fn(eq_items(), B_03_10_groups_vec,
                     "These appear as the later stages add to the model.")
  })

  output$eq_notation <- renderUI({
    T_06_05_notation_fn(B_03_11_notation_lst, stage_num(),
                        B_03_12_nota_cols_lst, first_stage = 1)
  })

  output$eq_explain <- renderUI({
    T_06_06_explain_fn(eq_items(), B_03_10_groups_vec)
  })

  # --- Prompt and problems ----------------------------------------------------
  output$prompt <- renderUI({
    T_07_12_prompt_fn(scn_now(), input$stage, B_03_08_prompts_lst)
  })

  output$problems <- renderUI(T_07_13_problems_fn(diag_now()$problems))

  # --- Readouts ---------------------------------------------------------------
  output$tiles <- renderUI({
    d <- diag_now()
    s <- stage_num()
    T_04_03_row_fn(
      T_04_01_tile_fn(
        "Expected utility", T_02_05_num_fn(d$eu, 3),
        if (s >= 2) {
          paste0("Autarky: ", T_02_05_num_fn(d$aut_eu, 3))
        } else {
          "Nothing insures you here"
        },
        class = if (s >= 2 && d$gain > 0) "good" else ""
      ),
      if (s >= 2) {
        T_04_01_tile_fn(
          "Paid at date 1, c<sub>1</sub>", T_02_05_num_fn(d$c1),
          paste0("Alone you would get ", T_02_05_num_fn(d$aut_c1)),
          class = if (d$insured) "good" else ""
        )
      },
      if (s >= 2) {
        T_04_01_tile_fn(
          "Paid at date 2, c<sub>2</sub>", T_02_05_num_fn(d$c2),
          paste0("Alone you would get ", T_02_05_num_fn(d$aut_c2))
        )
      },
      if (s >= 3) {
        T_04_01_tile_fn(
          "Optimal contract, c<sub>1</sub>*", T_02_05_num_fn(d$opt_c1),
          if (d$is_optimal) "You are at the optimum" else
            "Move c<sub>1</sub> here to maximise",
          class = if (d$is_optimal) "good" else ""
        )
      },
      if (s >= 4) {
        T_04_01_tile_fn(
          "The bank can pay", paste0(d$last_paid, " of ", par_now()$n_dep),
          paste0("Run threshold f* = ", T_02_06_pct_fn(d$run_share))
        )
      },
      if (s >= 4) {
        T_04_01_tile_fn(
          "Is a run an equilibrium?",
          if (s >= 5 && d$run_after) "Yes" else
            if (s >= 5) "No" else if (d$run_exists) "Yes" else "No",
          if (s >= 5) "Under the policy chosen" else "With nothing to stop it",
          class = if ((s >= 5 && d$run_after) ||
                      (s < 5 && d$run_exists)) "bad" else "good"
        )
      }
    )
  })

  # --- Figures ----------------------------------------------------------------
  output$bundle <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now())
    D_01_01_bundle_fn(par_now(), stage_num())
  }) })

  output$curve <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now())
    D_01_02_curve_fn(par_now(), stage_num(), ref = ghost_par())
  }) })

  output$best <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now(), stage_num() >= 4)
    D_02_01_best_fn(par_now(), cap_now(),
                    ref = ghost_par(), ref_cap = ghost_cap())
  }) })

  output$queue <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now(), stage_num() >= 4)
    D_02_02_queue_fn(par_now(), cap_now())
  }) })

  output$queue_note <- renderUI({
    req(stage_num() >= 4)
    d <- diag_now()
    tags$div(
      class = "stat-caption",
      if (d$run_exists) {
        HTML(paste(
          "Nothing is wrong with this bank's assets. Held to date 2 they",
          "would pay everyone. The run destroys the value, and the belief",
          "that it will happen is what makes it happen."
        ))
      } else {
        HTML(paste(
          "At this contract a run is not an equilibrium: waiting pays more",
          "than joining the queue even if everyone else joins it."
        ))
      }
    )
  })

  output$policy_plot <- renderPlot({ T_02_01c_draw_fn({
    req(ok_now(), stage_num() >= 5)
    D_03_01_policy_fn(par_now())
  }) })

  output$policy_note <- renderUI({
    req(stage_num() >= 5)
    tags$div(
      class = "narrative",
      tags$div(class = "nar-head", "The Three Fixes"),
      lapply(names(B_03_04_policy_lst), function(k) {
        tags$p(HTML(B_03_04_policy_lst[[k]]))
      })
    )
  })
}

################################################################################
## G: Run ######################################################################
################################################################################
# Note: Launch.

#### G_01: Launch ##############################################################
# Note: Returns the app object.

###### G_01_01: Build App ######################################################
# Note: UI from E, server from F.

G_01_01_app_lst <- shinyApp(E_02_02_app_ui_lst, F_01_01_app_server_fn)

G_01_01_app_lst
