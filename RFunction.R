library(ctmm)
library(purrr)
library(dplyr)

rFunction <- function(data) {
  # Time since `since`, for the log, e.g. "3.4 secs" or "2.1 mins"
  elapsed <- function(since) format(round(Sys.time() - since, 1))
  start <- Sys.time()
  n <- length(data)

  logger.info(paste0(
    "Fitting movement models for ", n, " animal(s). This can take a long ",
    "time (potentially hours) for many animals or long tracks."
  ))

  # Fit the animals one after the other and log the progress of each. Return
  # all fitted models for each animal (`verbose = TRUE`) so we can provide a
  # comparison output.
  candidates <- map(
    seq_len(n),
    function(i) {
      id <- names(data)[i]
      logger.info(paste0("Fitting models for animal ", i, " of ", n, " (", id, ")"))
      animal_start <- Sys.time()
      
      guess <- ctmm.guess(data[[i]], interactive = FALSE)
      cands <- ctmm.select(data[[i]], guess, verbose = TRUE)
      
      logger.info(paste0(id, ": selected ", names(cands)[1], " after ", elapsed(animal_start)))
      cands
    }
  )
  names(candidates) <- names(data)
  logger.info(paste0("All models fitted after ", elapsed(start)))

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
        dRMSPE = tab[, 2],
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

  # List elements need names for the MoveApps output analyzer, which reads
  # `model` and `data`. Later Apps read the elements by position.
  list(model = models, data = data)
}
