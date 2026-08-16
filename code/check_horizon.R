#!/usr/bin/env Rscript
# How far can the estimation window extend before the balanced sample thins out?
suppressPackageStartupMessages(library(data.table))
p <- fread("data/interim/panel_weekly.csv"); p[, week := as.Date(week)]
cov <- p[, .(lo = min(week), hi = max(week)), by = .(appid, language)]
for (end in as.Date(c("2025-06-01", "2025-12-01", "2026-06-01", "2026-07-01"))) {
  k <- cov[lo <= as.Date("2022-07-01") & hi >= end]
  cat(sprintf("window ends %s: %5d cells, %3d titles, %2d languages, %4.0f months post-event\n",
      format(as.Date(end)), nrow(k), uniqueN(k$appid), uniqueN(k$language),
      as.numeric(difftime(as.Date(end), as.Date("2023-11-20"), units = "days")) / 30.4))
}
