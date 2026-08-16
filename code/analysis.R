#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# Steam / Turkey November 2023: end of Turkish Lira pricing
# Event study + triple difference on game x language x month review flow
# ---------------------------------------------------------------------------
suppressPackageStartupMessages({
  library(data.table); library(fixest); library(ggplot2); library(modelsummary)
})

setFixest_notes(FALSE)
ARGS  <- commandArgs(trailingOnly = TRUE)
INP   <- if (length(ARGS) > 0) ARGS[1] else "data/interim/panel_weekly.csv"
OUTD  <- "output"; dir.create(OUTD, showWarnings = FALSE)
dir.create(file.path(OUTD, "figures"), showWarnings = FALSE)
dir.create(file.path(OUTD, "tables"),  showWarnings = FALSE)

EVENT <- as.Date("2023-11-20")
W0    <- as.Date("2022-07-01")   # start of estimation window
W1    <- as.Date("2025-06-01")   # end of estimation window

p <- fread(INP)
p[, week := as.Date(week)]

## ---- keep only (game,language) cells whose retrieved coverage spans the window ----
cov <- p[, .(lo = min(week), hi = max(week)), by = .(appid, language)]
keep <- cov[lo <= W0 & hi >= W1, .(appid, language)]
d <- merge(p, keep, by = c("appid", "language"))
d <- d[week >= W0 & week <= W1]

## ---- collapse to month (weekly counts are noisy for small cells) ----
d[, month := as.Date(format(week, "%Y-%m-01"))]
m <- d[, .(n = sum(n),
           share_nonsteam = weighted.mean(share_nonsteam, n + 1, na.rm = TRUE),
           share_pos      = weighted.mean(share_pos,      n + 1, na.rm = TRUE),
           med_playtime   = median(med_playtime, na.rm = TRUE)),
       by = .(appid, name, language, month, is_free, us_price)]

m[, log_n   := log(n + 1)]
m[, turkish := as.integer(language == "turkish")]
m[, paid    := as.integer(is_free == FALSE)]
m[, post    := as.integer(month >= as.Date("2023-12-01"))]
m[, rel_m   := (as.integer(format(month, "%Y")) - 2023) * 12 +
                (as.integer(format(month, "%m")) - 11)]      # 0 = Nov 2023
m[, tr_paid := turkish * paid]

cat("cells:", uniqueN(m[, .(appid, language)]),
    "| games:", uniqueN(m$appid),
    "| languages:", uniqueN(m$language),
    "| obs:", nrow(m), "\n")
cat("games by type: paid =", uniqueN(m[paid == 1]$appid),
    ", free =", uniqueN(m[paid == 0]$appid), "\n\n")

## =========================================================================
## (1) HEADLINE DiD  — paid games only, Turkish vs other languages
##     game x month FE absorbs every global shock to the game (sales, patches,
##     DLC, seasonality). game x language FE absorbs persistent affinity.
##     Identification: within a game-month, Turkish relative to other languages.
## =========================================================================
mp <- m[paid == 1]
did1 <- feols(log_n ~ i(rel_m, turkish, ref = -1) | appid^month + appid^language,
              data = mp, cluster = ~ appid^language)

## static version
did1s <- feols(log_n ~ turkish:post | appid^month + appid^language,
               data = mp, cluster = ~ appid^language)

## =========================================================================
## (2) TRIPLE DIFFERENCE — adds free-to-play games as a within-Turkey control.
##     language x month FE now absorbs anything hitting Turkish players in a
##     month (lira, inflation, internet, holidays). Identified off paid-vs-free.
## =========================================================================
ddd <- feols(log_n ~ i(rel_m, tr_paid, ref = -1) |
               appid^month + language^month + appid^language,
             data = m, cluster = ~ appid^language)
ddds <- feols(log_n ~ tr_paid:post | appid^month + language^month + appid^language,
              data = m, cluster = ~ appid^language)

## =========================================================================
## (3) SUBSTITUTION MARGIN — non-Steam key activations (gray market)
## =========================================================================
gm <- feols(share_nonsteam ~ i(rel_m, turkish, ref = -1) | appid^month + appid^language,
            data = mp, cluster = ~ appid^language)
gms <- feols(share_nonsteam ~ turkish:post | appid^month + appid^language,
             data = mp, cluster = ~ appid^language)

cat("=========== (1) DiD, paid games, static ===========\n"); print(did1s)
cat("\n=========== (2) DDD (paid vs free), static ===========\n"); print(ddds)
cat("\n=========== (3) Gray-market share, static ===========\n"); print(gms)

## =========================================================================
## (4) RANDOMIZATION INFERENCE — treatment is assigned to ONE language, so
##     cluster-robust SEs on 'language' are not available. We instead permute
##     which language is labelled treated and compare the true estimate to the
##     placebo distribution.
## =========================================================================
langs <- sort(unique(m$language))
ri <- rbindlist(lapply(langs, function(L) {
  mm <- copy(mp); mm[, fake := as.integer(language == L)]
  f <- try(feols(log_n ~ fake:post | appid^month + appid^language, data = mm), silent = TRUE)
  if (inherits(f, "try-error")) return(NULL)
  data.table(language = L, est = coef(f)[["fake:post"]])
}))
ri[, is_true := language == "turkish"]
setorder(ri, est)
cat("\n=========== (4) Randomization inference across languages ===========\n")
print(ri)
truth <- ri[is_true == TRUE]$est
cat(sprintf("Turkish estimate = %.3f ; rank among %d languages = %d (1 = most negative)\n",
            truth, nrow(ri), which(ri$language == "turkish")))
cat(sprintf("one-sided RI p-value = %.3f\n", mean(ri$est <= truth)))

## =========================================================================
## FIGURE 1 — the event-study plot that carries the paper
## =========================================================================
ev <- function(model, lab) {
  ct <- as.data.table(broom::tidy(model, conf.int = TRUE))
  ct <- ct[grepl("rel_m::", term)]
  ct[, k := as.integer(sub(".*rel_m::(-?[0-9]+).*", "\\1", term))]
  ct[, spec := lab]
  rbind(ct[, .(k, estimate, conf.low, conf.high, spec)],
        data.table(k = -1, estimate = 0, conf.low = 0, conf.high = 0, spec = lab))
}
e1 <- ev(did1, "DiD: Turkish vs other languages (paid games)")
e2 <- ev(ddd,  "DDD: + free-to-play games as within-Turkey control")
E  <- rbind(e1, e2)
fwrite(E, file.path(OUTD, "tables", "event_study_coefs.csv"))

g <- ggplot(E[k >= -16 & k <= 18], aes(k, estimate)) +
  geom_hline(yintercept = 0, linewidth = .3, colour = "grey40") +
  geom_vline(xintercept = -0.5, linetype = "dashed", linewidth = .4, colour = "#b2182b") +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), alpha = .15, fill = "#2166ac") +
  geom_line(colour = "#2166ac", linewidth = .5) +
  geom_point(colour = "#2166ac", size = 1.1) +
  facet_wrap(~spec, ncol = 1) +
  labs(x = "Months relative to 20 November 2023 (Valve ends Turkish Lira pricing)",
       y = "Effect on log review flow",
       title = "Turkish demand for paid games collapses when regional pricing ends",
       subtitle = "Steam review flow, game x language x month. Ref. month = October 2023.") +
  theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(),
        plot.title = element_text(face = "bold"))
ggsave(file.path(OUTD, "figures", "fig1_event_study.pdf"), g, width = 7.2, height = 6.4)
ggsave(file.path(OUTD, "figures", "fig1_event_study.png"), g, width = 7.2, height = 6.4, dpi = 180)

modelsummary(list("DiD (paid)" = did1s, "DDD" = ddds, "Gray-market share" = gms),
             stars = TRUE, gof_map = c("nobs", "r.squared"),
             output = file.path(OUTD, "tables", "main_results.txt"))
cat("\nwrote:", file.path(OUTD, "figures", "fig1_event_study.pdf"), "\n")
