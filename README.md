# Interactive Model: Diamond and Dybvig Bank Runs

A Shiny app for teaching the Diamond and Dybvig (1983) model of banks as
liquidity insurers and of bank runs as self-fulfilling equilibria. Built by
[Sam Deegan](https://sam-deegan.com) for ECON42550 Macroeconomics,
University College Dublin.

**Try it in the browser (nothing to install):**
https://sam-deegan.com/toy-models/diamond-dybvig/

Current version: **1.0.0** (see [CHANGELOG.md](CHANGELOG.md)). The version
is shown in the app footer; releases are tagged `vX.Y.Z`.

## What it does

The stage selector builds the model up one layer at a time:

| Stage | What is added |
|---|---|
| 1 | Autarky: no bank, and no insurance against turning out to be impatient |
| 2 | The deposit contract, and why depositors are better off with it |
| 3 | The optimal contract, and what the bank is really doing |
| 4 | The second equilibrium: the run, the best-response figure and the queue |
| 5 | Policies that stop runs: suspension of convertibility and deposit insurance |

Each stage opens on a worked example (autarky, the sample paper's contract,
a contract that promises too much, the contract the bank would choose, a
full run, a partial run, costly liquidation, suspension, deposit insurance).
Every slider has a box beside it for an exact value, and every figure draws a
faded copy of itself at the worked example's settings once a slider moves.
The Equations, Notation and In Words tabs show the model as it stands at the
chosen stage and flag what that stage changed.

The defaults reproduce the worked example on the ECON42550 Part 2 sample
paper: θ = 1/4, R = 2, L = 1, U(c) = 1 − 1/c and 100 depositors, where the
contract c₁ = 1.28 pays c₂ = 1.813, gives expected utility 0.391 against
0.375 in autarky, and the bank runs dry after 78 withdrawals.

## Run it locally

1. Install [R](https://cran.r-project.org/) (4.1 or later) and, ideally,
   [RStudio](https://posit.co/download/rstudio-desktop/).
2. Install the three packages once:

   ```r
   install.packages(c("shiny", "bslib", "ggplot2"))
   ```

3. Open `app.R` in RStudio and click **Run App**, or from R in this folder:

   ```r
   shiny::runApp()
   ```

Equations are typeset with MathJax from a CDN, so they need an internet
connection; everything else runs offline.

## Files

```
app.R          the app: settings and text (section B), figures (D),
               interface (E), server (F)
R/model.R      the model: utility, autarky, the contract, the optimum, the
               run threshold, best responses, the queue, equilibria and
               policies. Sources on its own, so slides can reuse it.
R/toolkit.R    layout and helpers shared with the other toy-model apps
README.md      this file
CHANGELOG.md   version history
CONVENTIONS.md how the figures and worked examples are laid out
LICENSE        CC BY-NC-ND 4.0
```

All text on screen (worked examples, prompts, equations, notation) is in
section `B_03` of `app.R`, so it can be edited without touching the rest.

## The model

Diamond and Dybvig (1983) is the canonical model of what a bank does and why
it is fragile. Depositors want liquidity insurance against a shock to when
they need to consume; a bank provides it by pooling an illiquid investment
and offering a demand deposit; but the same contract that insures them
admits a second equilibrium in which everyone withdraws at once and the bank
fails although its assets are sound. It is the model set out in Romer's
*Advanced Macroeconomics* (2019, chapter 10) and is the basis of the
textbook case for deposit insurance.

There are three dates, T = 0, 1, 2, and N depositors, each with one unit at
T = 0. Investment is productive but illiquid; a depositor learns their type
at T = 1; utility is CRRA, which at ρ = 2 is the 1 − 1/c of the sample paper.

```
Technology:  1 at T = 0  →  R at T = 2,  or L if liquidated at T = 1,  L ≤ 1 < R
Types:       θ impatient (consume at T = 1),  1 − θ patient (consume at T = 2)
Utility:     U(c) = (c^(1−ρ) − 1) / (1 − ρ)

Autarky:     EU^aut = θ U(L) + (1 − θ) U(R)
Contract:    c₁ on demand at T = 1;  c₂ = (1 − θ c₁ / L) R / (1 − θ) to whoever waits
Expected:    EU = θ U(c₁) + (1 − θ) U(c₂)
Optimum:     U′(c₁) = R U′(c₂)   ⇒   c₂ / c₁ = R^(1/ρ)
             c₁* = R / [ R^(1/ρ) (1 − θ) + θ R / L ]
Run:         c₂(f) = (1 − f c₁ / L) R / (1 − f);   f* = L / c₁
```

**The technology** pays R per unit held to date 2 but only L if broken at
date 1. Breaking it early destroys value, which is the only friction in the
model.

**Types** are private information and are learned only at date 1. Nobody
knows at date 0 whether they will be impatient, so on their own each
depositor faces a gamble between L and R: that is autarky, and the concave
utility function makes the spread itself costly.

**The deposit contract** promises a fixed c₁ to anyone who withdraws at date
1 and shares what is left, c₂, among those who wait. Paying the impatient
share θ costs θc₁/L units of investment, so c₂ falls as c₁ rises. With
c₁ > L the bank is buying insurance for the impatient out of what the
patient would otherwise collect: it moves consumption from the lucky to the
unlucky, and expected utility rises above autarky.

**The optimal contract** raises c₁ until a unit moved to date 1 is worth
exactly the R units it costs at date 2. For CRRA utility that fixes the
ratio c₂/c₁ = R^(1/ρ) and gives c₁* in closed form; at the sample paper's
calibration it is 1.2815, so the 1.28 in the question is the optimum, not an
arbitrary number. Risk aversion ρ decides how far c₁* is pushed above L.

**The run** is the second equilibrium of the same contract. Under sequential
service the bank pays c₁ in the order depositors arrive, and liquidating
everything raises only L per unit, so it can pay the share f* = L/c₁ and no
more. If every depositor expects the others to withdraw, waiting pays
nothing and joining the queue is a best response: the belief makes itself
true, and a bank that is illiquid but solvent fails. The model does not say
which equilibrium happens.

The model is solved in closed form throughout (`R/model.R`): the contract,
the optimum and the run threshold are single expressions, and the
best-response and queue figures evaluate them over a grid of f and over the
N positions in the queue.

**What the five stages show with it**

- *1* Autarky. The two types on the horizontal axis, one low bar against one
  high one, and expected utility as the dashed reference that everything
  after is measured against.
- *2* The deposit contract. Raising c₁ above L lifts the impatient bar and
  lowers the patient one; expected utility rises above autarky, then peaks
  and falls as the promise grows, and a contract that promises too much does
  worse than no bank at all.
- *3* The optimal contract. The marked optimum on the utility curve, and
  c₁* and c₂* as levels on the consumption figure: above L for the
  impatient, below R for the patient. Because c₁* > L, the optimal contract
  is the thing that makes a run possible.
- *4* The run equilibrium. The best-response figure sets the payoff to
  waiting against the payoff to joining the queue as f rises; the queue
  figure is a cliff, c₁ up to place f*N and nothing after. Costly
  liquidation moves the cliff left.
- *5* Policies. Suspension of convertibility caps the queue at θ, so a
  patient depositor who joins it gains nothing; deposit insurance guarantees
  c₂, so waiting is safe whatever anyone else does. Both remove the run;
  only one turns depositors away.

**Where it departs from the textbook.** The app follows the sample paper's
discrete version of the model with a fixed share θ known with certainty, so
there is no aggregate uncertainty and suspension works exactly. Suspension
and deposit insurance are both implemented as a cap on withdrawals at θ,
which gives the same payoffs; the difference between them, that insurance
turns nobody away, is stated in the text rather than modelled. The lender of
last resort is discussed but not coded: setting L = 1 is the version of the
model where it has already worked. There is no sunspot or signal that
selects between the two equilibria, no bank capital, no risky asset and no
moral hazard, so the cost of deposit insurance is described but not shown.

## References

- Diamond, D. W. and Dybvig, P. H. (1983). Bank runs, deposit insurance,
  and liquidity. *Journal of Political Economy* 91(3).
- Romer, D. (2019). *Advanced Macroeconomics*, 5th ed. Chapter 10.
- ECON42550 Part 2 sample paper, University College Dublin, for the worked
  example the defaults reproduce.

## Licence

© Sam Deegan. Released under
[CC BY-NC-ND 4.0](https://creativecommons.org/licenses/by-nc-nd/4.0/):
free to use and share for teaching with attribution; not for commercial use
or redistribution in modified form.
