library(ctmm)
library(purrr)
library(dplyr)

rFunction <- function(data) {
  g <- lapply(data, \(x) ctmm.guess(x, interactive = FALSE))

  # Return all fitted models for each animal (`verbose = TRUE`) so we can
  # provide a comparison output
  candidates <- map2(data, g, ~ ctmm.select(.x, .y, verbose = TRUE))

  # Selected model for each animal
  models <- map(candidates, 1)
  saveRDS(models, file = appArtifactPath("models.rds"))

  # Compare fitted models within each animal. AICc and RMSPE are only
  # comparable within an animal. units = FALSE reports RMSPE in meters for
  # every animal.
  comparison <- imap_dfr(
    candidates,
    function(cands, id) {
      tab <- summary(cands, units = FALSE)
      data.frame(
        id = id,
        model = rownames(tab),
        dAICc = tab[, 1],
        dRMSPE_m = tab[, 2],
        DOF = tab[, 3]
      )
    }
  )

  write.csv(comparison, file = appArtifactPath("model_comparison.csv"), row.names = FALSE)

  # Summary of the selected model for each animal. units = FALSE reports every
  # estimate in SI units (e.g. square meters, seconds) so that each parameter
  # has the same unit for every animal.
  m_summary <- map(models, ~ summary(.x, units = FALSE))

  out1 <- data.frame(
    id = names(models),
    DOF = sapply(m_summary, function(x) x$DOF["area"]),
    DOF_diffusion = sapply(m_summary, function(x) x$DOF["diffusion"]),
    DOF_speed = sapply(m_summary, function(x) x$DOF["speed"]),
    model = sapply(m_summary, function(x) x$name)
  )

  write.csv(out1, file = appArtifactPath("selected_model_summary.csv"), row.names = FALSE)

  # Parameter estimates and confidence intervals for each selected model
  xx <- map(m_summary, ~ .x$CI)
  lens <- map_int(xx, nrow)
  xx <- do.call(rbind, xx)

  xx |>
    as_tibble() |>
    mutate(id = rep(names(models), lens), parameter = rownames(xx)) |>
    select(id, parameter, low, est, high) |>
    write.csv(appArtifactPath("selected_model_estimates.csv"), row.names = FALSE)

  return(list(models, data))
}
