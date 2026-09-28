# Changelog

All notable changes to this app. Versions follow [Semantic Versioning](https://semver.org/):
MAJOR for a change to the model or its notation, MINOR for new features
(a stage, a worked example, a figure), PATCH for fixes and wording.
Each release is tagged in git as `vX.Y.Z` and shown in the app footer.

## [1.0.7] - 2026-09-28

### App
- The notes under the figures are rewritten as short plain prose: no bold
  lead-in sentences, one point per paragraph.

## [1.0.6] - 2026-09-28

### App
- Card headers in the blue used for headings, not body grey.

## [1.0.5] - 2026-09-28

### App
- Cards have no border or header rule: figures, equations and stories sit
  on the page separated by whitespace alone.

## [1.0.4] - 2026-09-28

### App
- Cards, panels, tiles and buttons are square with no shadow: they organise
  the page rather than decorate it.

## [1.0.3] - 2026-09-28

### App
- The QR code returns to the foot of the sidebar, with the name and site
  address, alongside the small one in the title bar.

## [1.0.2] - 2026-09-28

### App
- No figure carries a title or subtitle inside the image; the card header
  and the caption under it name and explain the figure (CONVENTIONS.md 6).
- Figures are drawn on a white ground, so the image sits flat in its card
  instead of showing as a tinted tile.

## [1.0.1] - 2026-09-28

### App
- The In Words tab lays out its three columns at fixed widths, so an
  equation no longer collapses to one term per line beside its note.
- The preset card no longer doubles the word "Stage" in front of a stage
  name that already carries it.
- Stage names now read "Stage n: ..." like the other apps.

## [1.0.0] - 2026-09-28

First public release as a standalone repository.

### Model
- Diamond and Dybvig (1983) with three dates, an illiquid technology, a
  known share of impatient types and CRRA utility, following Romer (2019)
  ch. 10 and the ECON42550 Part 2 sample paper.
- Closed-form autarky, deposit contract, optimal contract and run threshold;
  best responses, the sequential-service queue and the two equilibria over
  a grid of the share withdrawing.
- Suspension of convertibility and deposit insurance as a cap on
  withdrawals at the impatient share.

### App
- Five stages (1 to 5) that add one layer of the model at a time.
- Nine worked examples, each with a story and a "what to try" prompt.
- Equations, Notation and In Words tabs that track the model at each stage.
- Readout tiles for expected utility, the contract, the optimum, the run
  threshold and whether a run is an equilibrium.
- Ghost curves showing the loaded worked example alongside the live sliders
  on the expected-utility and best-response figures.
- Warnings when the calibration admits no sensible contract.
