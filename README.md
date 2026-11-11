# Fit a Continuous-Time Movement Model (ctmm)

MoveApps

GitHub repository: https://github.com/movestore/ctmm_modelselection

## Description
Fit continuous-time movement models to tracking data and select the best model
for each animal, using the function `ctmm.select()` from the **ctmm** package.

## Documentation
Based on the package `ctmm`, this App fits continuous-time movement models to
tracking data. These models describe the movement process of an animal,
accounting for the autocorrelation structure of the data. For each animal, an
initial model is guessed from the track properties. From this initial guess,
several models are then fit to the data, and the one with the lowest AICc is
selected as the best fit.

The selected models are provided in the output so they can be used in
subsequent Apps. The App produces several artefacts that contain summaries
of the models that were fit and their parameter estimates.

**ATTENTION**: This App can take a long time (potentially hours) to run.
Consider pinning this App for further Workflow runs so that the models do not
need to be recomputed. Subsequent Apps that use an interactive user interface
(e.g., *Autocorrelated Kernel Density Estimate (aKDE)* or
*Estimate Occurrence Distribution (Kriging)*)—which can only be accessed for
8 hours for each run of a Workflow—can then be regenerated without needing
to rerun the models.

You can pin an App by opening the App's menu at the top right corner of the App
and clicking *Pin to this App*.
This option is available once the first run of the App has completed.

### Application scope
#### Generality of App usability
This App was developed for any taxonomic group that displays range-resident
behavior.

#### Required data properties
This App is only applicable to data that reflect range-resident behavior. Use
the *Variogram* App to evaluate whether this property holds for your data.

### Input type
`ctmm::telemetry.list`

### Output type
`ctmm model with data`: a list with two elements:

1. A list containing the selected `ctmm` model for each animal.
2. The input data passed to the App (an object of type `telemetry.list`).

### Artefacts
`model_comparison.csv` contains the comparison results for each candidate model
for each animal, ranked by AICc. It contains the following columns:
  - `id`: the name of the animal.
  - `model`: the name of the candidate model. "OU" is the continuous-position
    model, "OUF" the continuous-velocity model, and "OUf" an OUF model whose two
    timescales (τ[position] and τ[velocity]) cannot be distinguished.
    "Anisotropic" models allow an elliptical rather than circular home range.
  - `dAICc`: the AICc difference between this model and the selected (best)
    model for this animal.
  - `dRMSPE_m`: the difference in root mean squared prediction error, in meters,
    between this model and the model with the lowest RMSPE. Note that models may
    be ranked differently by this metric than by AICc, but AICc is used to
    select the best model.
  - `DOF`: degrees of freedom for estimating the area under this model.

AICc and RMSPE differences are only comparable between models of the same
animal, not between animals.

`selected_model_summary.csv`: a brief summary of the selected model for each
animal. This summary contains for each animal (row) the following columns:
  - `id`: the name of the animal.
  - `DOF`: degrees of freedom for estimating the area. It represents the
    effective sample size for calculating the area, and also the number of times
    the animal crossed its range during the observation time (see
    `selected_model_estimates.csv`).
  - `DOF_diffusion`: degrees of freedom for estimating the diffusion (see
    `selected_model_estimates.csv`).
  - `DOF_speed`: degrees of freedom for estimating the speed (see
    `selected_model_estimates.csv`). This is 0 for models without velocity (e.g.
    OU), which give no speed estimate.
  - `model`: the selected model.

`selected_model_estimates.csv`: the parameter estimates of the selected model
for each animal. This table contains the following columns:
  - `id`: the name of the animal.
  - `unit`: the parameter name and its unit (see below).
  - The lower (`low`) and upper (`high`) 95% confidence interval of the
    estimated parameter (`est`).

The rows reported in `unit` are:
  - `area`: the estimated home-range area.
  - `τ[position]`: the time it takes the animal to cross its home range, and
    also the time lag at which locations become time-independent (i.e. when
    they stop being autocorrelated in time).
  - `τ[velocity]`: the time lag at which locations become velocity-independent
    (i.e. when they stop being autocorrelated in velocity). Useful for e.g.
    step-selection models.
  - `speed`: estimated speed throughout the observation period.
  - `diffusion`: estimated value of how much the animal moved during the
    observed period.

`models.rds`: the selected `ctmm` model of each animal, as returned by
`ctmm.select()`. This can be loaded by R and used locally for further analyses.

### Settings
none

### Changes in output data
This App passes an augmented version of the input data to the next App. The
data themselves are returned unchanged, but the selected model for each animal
is also provided. See **Output type** above.

### Errors and null handling
The App will fail or take **very** long if the variograms in
the previous step suggest that some of the tracked animals do not show
home-ranging behavior.

If an error occurs while fitting the models of any animal,
the App stops and no output is produced for any animal. Please open an issue in
the GitHub repository if you repeatedly encounter errors.

### Technical details
- For each animal separately, an initial model is guessed automatically with
  `ctmm::ctmm.guess()` and the best model is selected with
  `ctmm::ctmm.select()`. `ctmm.select()` uses its default settings, apart from
  returning all candidate models for the comparison. This means that the
  models are selected by AICc and that the candidate models are those nested
  in the initial guess (e.g. OUF, OU, isotropic or anisotropic). See the
  documentation of
  [`ctmm.select()`](https://ctmm-initiative.github.io/ctmm/reference/ctmm.fit.html).
- `model_comparison.csv` uses ctmm's `summary()` as applied to the list of
  candidate models for each animal.
- The run time increases with the number of animals and the number of locations
  per animal. The animals are fit one after the other.

Selecting between continuous-time movement models is described in Fleming,
C. H., Calabrese, J. M., Mueller, T., Olson, K. A., Leimgruber, P., & Fagan,
W. F. (2014). From fine-scale foraging to home ranges: A semivariance approach
to identifying movement modes across spatiotemporal scales. *The American
Naturalist*, 183(5), E154–E167. https://doi.org/10.1086/675504

The `ctmm` package is described in Calabrese, J. M., Fleming, C. H., &
Gurarie, E. (2016). ctmm: An R package for analyzing animal relocation data as
a continuous-time stochastic process. *Methods in Ecology and Evolution*,
7(9), 1124–1132. https://doi.org/10.1111/2041-210X.12559
