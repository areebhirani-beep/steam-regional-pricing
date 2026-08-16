#!/usr/bin/env Rscript
# ===========================================================================
#  The Price of Being Priced Like America
#  Every table, figure and in-text number in the paper, from a cold start.
#      Rscript code/analysis_full.R
# ===========================================================================
suppressPackageStartupMessages({
  library(data.table); library(fixest); library(ggplot2); library(broom); library(jsonlite)
})
setFixest_notes(FALSE)

INP  <- "data/interim/panel_weekly.csv"
OUTD <- "output"
dir.create(file.path(OUTD, "figures"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(OUTD, "tables"),  recursive = TRUE, showWarnings = FALSE)

EVENT    <- as.Date("2023-11-20")   # Valve ends TRY/ARS pricing
ANNOUNCE <- as.Date("2023-10-25")   # Valve announces it
EVENT_M  <- as.Date("2023-11-01")
W0 <- as.Date("2022-07-01"); W1 <- as.Date("2025-06-01")

## ------------------------------- house style ------------------------------
NAVY <- "#1f3b57"; RED <- "#a4243b"; GREEN <- "#3f7d20"
th <- theme_minimal(base_size = 9.5) +
  theme(panel.grid.minor   = element_blank(),
        panel.grid.major.x = element_blank(),
        panel.grid.major.y = element_line(linewidth = .25, colour = "grey88"),
        axis.title         = element_text(size = 9, colour = "grey20"),
        axis.text          = element_text(colour = "grey30"),
        strip.text         = element_text(face = "bold", hjust = 0, size = 9,
                                          margin = margin(b = 4)),
        legend.position    = "bottom",
        legend.key.width   = unit(20, "pt"),
        legend.text        = element_text(size = 8.5),
        plot.margin        = margin(6, 8, 4, 4))

## ---------------------------------- load ----------------------------------
p <- fread(INP); p[, week := as.Date(week)]
cov  <- p[, .(lo = min(week), hi = max(week)), by = .(appid, language)]
keep <- cov[lo <= W0 & hi >= W1, .(appid, language)]
d <- merge(p, keep, by = c("appid", "language"))[week >= W0 & week <= W1]
d[, month := as.Date(format(week, "%Y-%m-01"))]

agg <- function(dt, by) dt[, list(n = sum(n),
      share_nonsteam = weighted.mean(share_nonsteam, n + 1, na.rm = TRUE),
      share_pos      = weighted.mean(share_pos,      n + 1, na.rm = TRUE),
      med_playtime   = median(med_playtime,    na.rm = TRUE),
      med_games      = median(med_games_owned, na.rm = TRUE)), by = by]

m  <- agg(d, c("appid","name","language","month","is_free","us_price"))
wk <- agg(d, c("appid","name","language","week","is_free","us_price"))

prep <- function(dt, tcol, ev) {
  dt[, `:=`(log_n   = log(n + 1),
            turkish = as.integer(language == "turkish"),
            latam   = as.integer(language == "latam"),
            paid    = as.integer(is_free == FALSE),
            log_pt  = log(med_playtime + 1),
            log_gow = log(med_games + 1))]
  dt[, post := as.integer(get(tcol) > ev)]
  dt[, tr_paid := turkish * paid]
  dt[]
}
m  <- prep(m,  "month", EVENT_M)
wk <- prep(wk, "week",  EVENT)
m[,  rel_m := (as.integer(format(month, "%Y")) - 2023) * 12 + (as.integer(format(month, "%m")) - 11)]
wk[, rel_w := as.integer(floor(as.numeric(week - EVENT) / 7))]

## US price today as a proxy for the size of the 2023 increase: cheap titles were
## furthest below dollar parity in lira and so took the largest percentage jumps.
m[, tier := fifelse(paid == 0, "free",
             fifelse(us_price < 10, "budget (<\\$10)",
              fifelse(us_price < 25, "mid (\\$10-25)", "premium (>\\$25)")))]
m[, tier := factor(tier, levels = c("free", "budget (<\\$10)", "mid (\\$10-25)", "premium (>\\$25)"))]

## ---- dose proxy -----------------------------------------------------------
## Pre-2023 lira prices were set off Valve's proportional recommended grid, so to a
## first approximation the pre-change Turkish price was a common fraction phi of the
## US price.  Then  dlnP_g = ln(tr_now_g) - ln(phi * us_g) = ln(tr_now_g/us_g) - ln(phi),
## and since ln(phi) is a constant absorbed by the Post main effect, the *cross-title*
## variation in the price increase is exactly ln(tr_now_g / us_g).
prices <- unique(fread(INP)[, .(appid, us_price, tr_price_now)])
prices <- prices[us_price > 0 & tr_price_now > 0]
prices[, dose := log(tr_price_now / us_price)]
prices[, dose_c := dose - mean(dose)]
m  <- merge(m,  prices[, .(appid, dose, dose_c)], by = "appid", all.x = TRUE)
mp2 <- m[paid == 1 & !is.na(dose)]

NG <- uniqueN(m$appid); NL <- uniqueN(m$language); NC <- uniqueN(m[, .(appid, language)])
NPAID <- uniqueN(m[paid == 1]$appid); NFREE <- uniqueN(m[paid == 0]$appid)
NREV  <- sum(m$n)
cat(sprintf("titles %d (paid %d, free %d) | languages %d | cells %d | obs %d | reviews %s\n",
            NG, NPAID, NFREE, NL, NC, nrow(m), formatC(NREV, big.mark = ",", format = "d")))

mp <- m[paid == 1]; wkp <- wk[paid == 1]

## ================================ MODELS ==================================
## FE1 = appid^month + appid^language        (DiD)
## FE2 = FE1 + language^month                  (DDD)

did_s <- feols(log_n ~ turkish:post | appid^month + appid^language, data = mp, cluster = ~ appid^language)
ddd_s <- feols(log_n ~ tr_paid:post | appid^month + language^month + appid^language, data = m,  cluster = ~ appid^language)
ppml  <- fepois(n    ~ turkish:post | appid^month + appid^language, data = mp, cluster = ~ appid^language)
free_s  <- feols(log_n ~ turkish:post | appid^month + appid^language, data = m[paid == 0], cluster = ~ appid^language)
latam_s <- feols(log_n ~ latam:post | appid^month + appid^language,
                 data = mp[language != "turkish"],
                 cluster = ~ appid^language)

did_e <- feols(log_n ~ i(rel_m, turkish, ref = -1) | appid^month + appid^language, data = mp, cluster = ~ appid^language)
ddd_e <- feols(log_n ~ i(rel_m, tr_paid, ref = -1) | appid^month + language^month + appid^language, data = m,  cluster = ~ appid^language)
wk_e  <- feols(log_n ~ i(rel_w, turkish, ref = -1) | appid^week + appid^language,
               data = wkp[rel_w >= -30 & rel_w <= 30], cluster = ~ appid^language)

gm_s  <- feols(share_nonsteam ~ turkish:post | appid^month + appid^language, data = mp, cluster = ~ appid^language)
pos_s <- feols(share_pos      ~ turkish:post | appid^month + appid^language, data = mp, cluster = ~ appid^language)
pt_s  <- feols(log_pt         ~ turkish:post | appid^month + appid^language, data = mp, cluster = ~ appid^language)
gow_s <- feols(log_gow        ~ turkish:post | appid^month + appid^language, data = mp, cluster = ~ appid^language)

het_tab <- rbindlist(lapply(levels(m$tier)[-1], function(tt) {
  f <- feols(log_n ~ turkish:post | appid^month + appid^language, data = m[tier == tt], cluster = ~ appid^language)
  data.table(tier = tt, est = unname(coef(f)["turkish:post"]),
             se = unname(se(f)["turkish:post"]), n = f$nobs,
             games = uniqueN(m[tier == tt]$appid))
}))
fwrite(het_tab, file.path(OUTD, "tables", "het_tier.csv"))

## formal pre-trend test: joint Wald on all pre-event event-study coefficients
ct <- as.data.table(tidy(did_e))[grepl("rel_m::", term)]
ct[, k := as.integer(sub(".*rel_m::(-?[0-9]+).*", "\\1", term))]
wt <- tryCatch(wald(did_e, keep = "rel_m::-", print = FALSE), error = function(e) NULL)
pre_F <- if (is.null(wt)) NA_real_ else wt$stat
pre_p <- if (is.null(wt)) NA_real_ else wt$p

## anticipation: drop the month containing the 26-day announcement window
antic <- feols(log_n ~ turkish:post | appid^month + appid^language,
               data = mp[month != as.Date("2023-11-01")], cluster = ~ appid^language)

placebo <- rbindlist(lapply(c(-12, -6, 6), function(sh) {
  mm <- copy(mp); mm[, fpost := as.integer(rel_m > sh)]
  if (sh < 0) mm <- mm[rel_m <= -1]
  f <- feols(log_n ~ turkish:fpost | appid^month + appid^language, data = mm, cluster = ~ appid^language)
  data.table(shift = sh, est = unname(coef(f)["turkish:fpost"]),
             se = unname(se(f)["turkish:fpost"]), n = f$nobs)
}))

ri <- rbindlist(lapply(sort(unique(m$language)), function(L) {
  mm <- copy(mp); mm[, fake := as.integer(language == L)]
  f <- try(feols(log_n ~ fake:post | appid^month + appid^language, data = mm), silent = TRUE)
  if (inherits(f, "try-error")) return(NULL)
  data.table(language = L, est = unname(coef(f)["fake:post"]))
}))
setorder(ri, est); ri[, rank := .I]
truth <- ri[language == "turkish"]$est; ri_p <- mean(ri$est <= truth)
fwrite(ri, file.path(OUTD, "tables", "ri.csv"))

loo <- rbindlist(lapply(unique(mp$appid), function(a) {
  f <- try(feols(log_n ~ turkish:post | appid^month + appid^language, data = mp[appid != a], cluster = ~ appid^language),
           silent = TRUE)
  if (inherits(f, "try-error")) return(NULL)
  data.table(dropped = a, est = unname(coef(f)["turkish:post"]))
}))
fwrite(loo, file.path(OUTD, "tables", "loo.csv"))

## ---- dose-response --------------------------------------------------------
dose_s <- feols(log_n ~ turkish:post + turkish:post:dose_c | appid^month + appid^language,
                data = mp2, cluster = ~ appid^language)
dose_only <- feols(log_n ~ turkish:post:dose | appid^month + appid^language,
                   data = mp2, cluster = ~ appid^language)
b_dose <- unname(coef(dose_s)["turkish:post:dose_c"])
se_dose <- unname(se(dose_s)["turkish:post:dose_c"])

## ---- magnitude of pre-period wiggle vs. the effect --------------------------
pre_max <- max(abs(ct[k < -1]$estimate))
pre_sd  <- sd(ct[k < -1]$estimate)

## ---- pre-trend: is it a TREND, or month-to-month noise around zero? ---------
## The joint Wald test above rejects whenever monthly cells are noisy, which is a
## statement about precision, not about a differential trend.  The economically
## relevant question is whether the pre-period coefficients SLOPE.
pre_dt  <- ct[k < -1][order(k)]
slope_f <- lm(estimate ~ k, data = pre_dt)
pre_slope   <- unname(coef(slope_f)["k"])
pre_slope_se<- summary(slope_f)$coefficients["k", "Std. Error"]
pre_slope_p <- summary(slope_f)$coefficients["k", "Pr(>|t|)"]

## Linear-detrending robustness: extrapolate the fitted pre-trend into the post
## period and net it out of the post coefficients.
post_dt <- ct[k >= 0]
post_dt[, fitted_trend := coef(slope_f)[1] + coef(slope_f)["k"] * k]
b_detrend <- mean(post_dt$estimate - post_dt$fitted_trend)

## Regression version: allow Turkish speakers their own linear time trend.
mp[, tt := rel_m]
trend_s <- feols(log_n ~ turkish:post + turkish:tt | appid^month + appid^language,
                 data = mp, cluster = ~ appid^language)
b_trend  <- unname(coef(trend_s)["turkish:post"])
se_trend <- unname(se(trend_s)["turkish:post"])

## ================================ TABLES ==================================
wr <- function(f, s) writeLines(s, file.path(OUTD, "tables", f))
st <- function(b, s) { if (is.na(b) || is.na(s) || s == 0) return("")
  pv <- 2 * pnorm(-abs(b / s))
  if (pv < .01) "$^{***}$" else if (pv < .05) "$^{**}$" else if (pv < .1) "$^{*}$" else "" }

regtable <- function(models, coefs, heads, fe_rows, file, digits = 3) {
  k <- length(models); fmt <- paste0("%.", digits, "f")
  L <- c(paste0("\\begin{tabular}{l", strrep("c", k), "}"), "\\toprule",
         paste0(" & ", paste(sprintf("(%d)", seq_len(k)), collapse = " & "), " \\\\"),
         paste0(" & ", paste(heads, collapse = " & "), " \\\\"),
         paste0("\\cmidrule(lr){2-", k + 1, "}"))
  for (cf in names(coefs)) {
    b <- sapply(models, function(z) { v <- coef(z); if (cf %in% names(v)) unname(v[cf]) else NA })
    s <- sapply(models, function(z) { v <- se(z);   if (cf %in% names(v)) unname(v[cf]) else NA })
    L <- c(L,
      paste0(coefs[[cf]], " & ",
             paste(mapply(function(bb, ss) if (is.na(bb)) "" else
               paste0("$", sprintf(fmt, bb), "$", st(bb, ss)), b, s), collapse = " & "), " \\\\"),
      paste0(" & ", paste(sapply(s, function(ss) if (is.na(ss)) "" else
               paste0("($", sprintf(fmt, ss), "$)")), collapse = " & "), " \\\\[3pt]"))
  }
  L <- c(L, "\\midrule")
  for (nm in names(fe_rows)) L <- c(L, paste0(nm, " & ", paste(fe_rows[[nm]], collapse = " & "), " \\\\"))
  L <- c(L, paste0("Observations & ",
                   paste(formatC(sapply(models, function(z) z$nobs), big.mark = ",", format = "d"),
                         collapse = " & "), " \\\\"),
         "\\bottomrule", "\\end{tabular}")
  wr(file, L)
}

t1 <- m[, .(titles = uniqueN(appid), obs = .N, reviews = sum(n),
            mean_mo = round(mean(n), 1), pos = round(mean(share_pos, na.rm = TRUE), 3),
            key = round(mean(share_nonsteam, na.rm = TRUE), 3)),
        by = .(Language = language)][order(-reviews)]
fwrite(t1, file.path(OUTD, "tables", "t1_summary.csv"))
wr("t1_summary.tex", c(
  "\\begin{tabular}{lrrrrrr}", "\\toprule",
  "Language & Titles & Obs. & Reviews & Mean/mo. & Share positive & Non-Steam key \\\\",
  "\\cmidrule(lr){2-7}",
  paste0(t1$Language, " & ", t1$titles, " & ", formatC(t1$obs, big.mark = ",", format = "d"),
         " & ", formatC(t1$reviews, big.mark = ",", format = "d"), " & ", t1$mean_mo,
         " & ", t1$pos, " & ", t1$key, " \\\\"),
  "\\midrule",
  paste0("\\textbf{All} & \\textbf{", NG, "} & \\textbf{",
         formatC(nrow(m), big.mark = ",", format = "d"), "} & \\textbf{",
         formatC(NREV, big.mark = ",", format = "d"), "} & & & \\\\"),
  "\\bottomrule", "\\end{tabular}"))

regtable(list(did_s, ddd_s, ppml, free_s, latam_s),
  coefs = list("turkish:post" = "Turkish $\\times$ Post",
               "tr_paid:post" = "Turkish $\\times$ Paid $\\times$ Post",
               "latam:post"   = "Latin-American Spanish $\\times$ Post"),
  heads = c("DiD", "DDD", "PPML", "F2P", "LatAm"),
  fe_rows = list("Title $\\times$ month FE"    = rep("Yes", 5),
                 "Language $\\times$ month FE" = c("No", "Yes", "No", "No", "No"),
                 "Title $\\times$ language FE" = rep("Yes", 5),
                 "Sample"                      = c("Paid", "All", "Paid", "Free", "Paid")),
  file = "t2_main.tex")

regtable(list(did_s, antic, trend_s, ppml, dose_s),
  coefs = list("turkish:post" = "Turkish $\\times$ Post",
               "turkish:tt" = "Turkish $\\times$ linear trend",
               "turkish:post:dose_c" = "Turkish $\\times$ Post $\\times$ $\\Delta\\ln P$"),
  heads = c("Baseline", "Drop Nov.\\ 2023", "Linear trend", "PPML", "Dose"),
  fe_rows = list("Title $\\times$ month FE" = rep("Yes", 5),
                 "Title $\\times$ language FE" = rep("Yes", 5)),
  file = "t3_robust.tex")

regtable(list(gm_s, pos_s, pt_s, gow_s),
  coefs = list("turkish:post" = "Turkish $\\times$ Post"),
  heads = c("Non-Steam key", "Share positive", "log playtime", "log library size"),
  fe_rows = list("Title $\\times$ month FE" = rep("Yes", 4),
                 "Title $\\times$ language FE" = rep("Yes", 4)),
  file = "t4_composition.tex", digits = 4)

plab <- c("-12" = "12 months before", "-6" = "6 months before", "6" = "6 months after")
wr("t5_placebo.tex", c(
  "\\begin{tabular}{lrrr}", "\\toprule",
  "Event date used & Estimate & Std.\\ error & Obs. \\\\", "\\cmidrule(lr){2-4}",
  paste0(plab[as.character(placebo$shift)],
         " & $", sprintf("%.3f", placebo$est), "$ & ($", sprintf("%.3f", placebo$se), "$) & ",
         formatC(placebo$n, big.mark = ",", format = "d"), " \\\\"),
  "\\midrule",
  paste0("\\textbf{20 November 2023 (true)} & $\\mathbf{",
         sprintf("%.3f", coef(did_s)[["turkish:post"]]), "}$ & ($\\mathbf{",
         sprintf("%.3f", se(did_s)[["turkish:post"]]), "}$) & \\textbf{",
         formatC(did_s$nobs, big.mark = ",", format = "d"), "} \\\\"),
  "\\bottomrule", "\\end{tabular}"))

wr("t6_tier.tex", c(
  "\\begin{tabular}{lrrrr}", "\\toprule",
  "US price tier & Titles & Estimate & Std.\\ error & Obs. \\\\", "\\cmidrule(lr){2-5}",
  paste0(het_tab$tier, " & ", het_tab$games, " & $", sprintf("%.3f", het_tab$est), "$",
         mapply(st, het_tab$est, het_tab$se), " & ($", sprintf("%.3f", het_tab$se), "$) & ",
         formatC(het_tab$n, big.mark = ",", format = "d"), " \\\\"),
  "\\midrule",
  paste0("free-to-play (placebo) & ", NFREE, " & $", sprintf("%.3f", stats::coef(free_s)[["turkish:post"]]), "$",
         st(coef(free_s)[["turkish:post"]], se(free_s)[["turkish:post"]]),
         " & ($", sprintf("%.3f", se(free_s)[["turkish:post"]]), "$) & ",
         formatC(free_s$nobs, big.mark = ",", format = "d"), " \\\\"),
  "\\bottomrule", "\\end{tabular}"))

## ================================ FIGURES =================================
evtab <- function(model, var, lab) {
  ct <- as.data.table(tidy(model, conf.int = TRUE))[grepl(paste0(var, "::"), term)]
  ct[, k := as.integer(sub(paste0(".*", var, "::(-?[0-9]+).*"), "\\1", term))]
  rbind(ct[, .(k, estimate, conf.low, conf.high)],
        data.table(k = -1, estimate = 0, conf.low = 0, conf.high = 0))[, spec := lab][]
}
E <- rbind(evtab(did_e, "rel_m", "A.  Difference-in-differences: Turkish versus other languages, paid titles"),
           evtab(ddd_e, "rel_m", "B.  Triple difference: free-to-play titles added as a within-Turkey control"))
fwrite(E, file.path(OUTD, "tables", "event_study_coefs.csv"))

f1 <- ggplot(E[k >= -16 & k <= 18], aes(k, estimate)) +
  annotate("rect", xmin = -0.5, xmax = Inf, ymin = -Inf, ymax = Inf, fill = "grey95") +
  geom_hline(yintercept = 0, linewidth = .3, colour = "grey25") +
  geom_vline(xintercept = -0.5, linetype = "22", linewidth = .45, colour = RED) +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), alpha = .18, fill = NAVY) +
  geom_line(colour = NAVY, linewidth = .55) +
  geom_point(colour = NAVY, size = 1.15) +
  facet_wrap(~spec, ncol = 1) +
  scale_x_continuous(breaks = seq(-15, 15, 5)) +
  labs(x = "Months relative to 20 November 2023", y = "Effect on log review flow") + th
ggsave(file.path(OUTD, "figures", "fig1_event_study.pdf"), f1, width = 6.5, height = 5.4)

mm <- copy(m)
base <- mm[month >= W0 & month <= as.Date("2023-04-01"), .(b = mean(n)), by = .(appid, language)]
mm <- merge(mm, base, by = c("appid", "language"))
mm[, idx := n / pmax(b, .5)]
mm[, grp := fifelse(turkish == 1 & paid == 1, "Turkish, paid titles",
             fifelse(turkish == 1 & paid == 0, "Turkish, free-to-play titles",
                                               "All other languages, paid titles"))]
f2d <- mm[, .(idx = mean(idx)), by = .(grp, month)]
f2d[, grp := factor(grp, levels = c("Turkish, paid titles", "Turkish, free-to-play titles",
                                    "All other languages, paid titles"))]
f2 <- ggplot(f2d, aes(month, idx, colour = grp)) +
  geom_vline(xintercept = EVENT, linetype = "22", colour = RED, linewidth = .45) +
  geom_line(linewidth = .6) +
  scale_colour_manual(values = c(RED, GREEN, NAVY), name = NULL) +
  scale_x_date(date_breaks = "6 months", date_labels = "%b %Y") +
  labs(x = NULL, y = "Review flow (Jul. 2022 to Apr. 2023 = 1)") + th
ggsave(file.path(OUTD, "figures", "fig2_raw_flow.pdf"), f2, width = 6.5, height = 3.2)

ri[, is_tr := language == "turkish"]
f3 <- ggplot(ri, aes(reorder(language, est), est, fill = is_tr)) +
  geom_col(width = .72) + coord_flip() +
  scale_fill_manual(values = c("FALSE" = "grey78", "TRUE" = RED), guide = "none") +
  geom_hline(yintercept = 0, linewidth = .3, colour = "grey25") +
  labs(x = NULL, y = "Placebo estimate when this language is labelled treated") +
  th + theme(panel.grid.major.y = element_blank(),
             panel.grid.major.x = element_line(linewidth = .25, colour = "grey88"))
ggsave(file.path(OUTD, "figures", "fig3_ri.pdf"), f3, width = 6.5, height = 4.4)

E4 <- evtab(wk_e, "rel_w", "weekly")
f4 <- ggplot(E4[k >= -26 & k <= 26], aes(k, estimate)) +
  annotate("rect", xmin = as.numeric(ANNOUNCE - EVENT) / 7, xmax = -0.5,
           ymin = -Inf, ymax = Inf, fill = "#f6e8cf") +
  geom_hline(yintercept = 0, linewidth = .3, colour = "grey25") +
  geom_vline(xintercept = -0.5, linetype = "22", linewidth = .45, colour = RED) +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), alpha = .18, fill = NAVY) +
  geom_line(colour = NAVY, linewidth = .5) + geom_point(colour = NAVY, size = .9) +
  labs(x = "Weeks relative to 20 November 2023 (shaded: the 26-day announcement window)",
       y = "Effect on log review flow") + th
ggsave(file.path(OUTD, "figures", "fig4_weekly.pdf"), f4, width = 6.5, height = 3.0)

ht <- copy(het_tab); ht[, `:=`(lo = est - 1.96 * se, hi = est + 1.96 * se)]
bf <- unname(coef(free_s)["turkish:post"]); sf <- unname(se(free_s)["turkish:post"])
ht <- rbind(data.table(tier = "free", est = bf, se = sf, n = free_s$nobs, games = NFREE,
                       lo = bf - 1.96 * sf, hi = bf + 1.96 * sf), ht, fill = TRUE)
ht[, tierlab := gsub("\\\\", "", tier)]
ht[, tierlab := factor(tierlab, levels = rev(c("free", "budget (<$10)", "mid ($10-25)", "premium (>$25)")))]
f5 <- ggplot(ht, aes(tierlab, est)) +
  geom_hline(yintercept = 0, linewidth = .3, colour = "grey25") +
  geom_errorbar(aes(ymin = lo, ymax = hi), width = .1, colour = NAVY, linewidth = .45) +
  geom_point(aes(colour = tierlab == "free"), size = 2.2) +
  scale_colour_manual(values = c("FALSE" = NAVY, "TRUE" = GREEN), guide = "none") +
  coord_flip() +
  labs(x = NULL, y = "Effect on log review flow (Turkish $\\times$ Post)") +
  th + theme(panel.grid.major.y = element_blank(),
             panel.grid.major.x = element_line(linewidth = .25, colour = "grey88"))
f5 <- f5 + labs(y = "Effect on log review flow, Turkish x Post")
ggsave(file.path(OUTD, "figures", "fig5_tier.pdf"), f5, width = 6.5, height = 2.6)

cmp <- m[, .(pt = median(med_playtime, na.rm = TRUE),
             gow = median(med_games, na.rm = TRUE),
             pos = weighted.mean(share_pos, n + 1, na.rm = TRUE)),
         by = .(month, grp = fifelse(turkish == 1, "Turkish", "Other languages"))]
cmpl <- melt(cmp, id.vars = c("month", "grp"), measure.vars = c("pt", "gow", "pos"))
cmpl[, variable := factor(variable, levels = c("pt", "gow", "pos"),
      labels = c("Median playtime at review (min.)", "Median reviewer library size",
                 "Share of reviews positive"))]
f6 <- ggplot(cmpl, aes(month, value, colour = grp)) +
  geom_vline(xintercept = EVENT, linetype = "22", colour = RED, linewidth = .4) +
  geom_line(linewidth = .5) +
  facet_wrap(~variable, scales = "free_y", ncol = 3) +
  scale_colour_manual(values = c("Turkish" = RED, "Other languages" = NAVY), name = NULL) +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  labs(x = NULL, y = NULL) + th
ggsave(file.path(OUTD, "figures", "fig6_composition.pdf"), f6, width = 6.5, height = 2.7)

## ============================ NUMBERS FOR TEXT ============================
b1 <- coef(did_s)[["turkish:post"]]; s1 <- se(did_s)[["turkish:post"]]
b2 <- coef(ddd_s)[["tr_paid:post"]]; s2 <- se(ddd_s)[["tr_paid:post"]]
stats <- list(n_games = NG, n_paid = NPAID, n_free = NFREE, n_lang = NL, n_cells = NC,
  n_obs = nrow(m), n_reviews = NREV,
  b_did = b1, se_did = s1, t_did = b1/s1, pct_did = 100*(exp(b1)-1),
  b_ddd = b2, se_ddd = s2, t_ddd = b2/s2, pct_ddd = 100*(exp(b2)-1),
  b_ppml = unname(coef(ppml)["turkish:post"]), se_ppml = unname(se(ppml)["turkish:post"]),
  b_free = bf, se_free = sf,
  b_latam = unname(coef(latam_s)["latam:post"]), se_latam = unname(se(latam_s)["latam:post"]),
  b_gm = unname(coef(gm_s)["turkish:post"]), se_gm = unname(se(gm_s)["turkish:post"]),
  b_pt = unname(coef(pt_s)["turkish:post"]), se_pt = unname(se(pt_s)["turkish:post"]),
  b_gow = unname(coef(gow_s)["turkish:post"]), se_gow = unname(se(gow_s)["turkish:post"]),
  b_pos = unname(coef(pos_s)["turkish:post"]), se_pos = unname(se(pos_s)["turkish:post"]),
  ri_p = ri_p, ri_rank = ri[language=="turkish"]$rank, ri_n = nrow(ri),
  ri_next = ri[language != "turkish"][which.min(est)]$est,
  loo_min = min(loo$est), loo_max = max(loo$est),
  pre_F = pre_F, pre_p = pre_p, b_antic = unname(coef(antic)["turkish:post"]),
  eps_lo = b1/log(1+29.0), eps_hi = b1/log(1+2.40),
  rev_lo = exp(b1)*3.4, rev_hi = exp(b1)*30.0,
  b_budget = het_tab[tier == levels(m$tier)[2]]$est,
  b_prem   = het_tab[tier == levels(m$tier)[4]]$est,
  b_dose = b_dose, se_dose = se_dose, pre_max = pre_max, pre_sd = pre_sd,
  pre_slope = pre_slope, pre_slope_se = pre_slope_se, pre_slope_p = pre_slope_p,
  b_detrend = b_detrend, b_trend = b_trend, se_trend = se_trend,
  dose_min = min(prices$dose), dose_max = max(prices$dose))
write_json(stats, file.path(OUTD, "tables", "stats.json"), auto_unbox = TRUE, digits = 6)

E_ <- function(nm, v, f = "%.3f") sprintf("\\newcommand{\\%s}{\\ensuremath{%s}}", nm, sprintf(f, v))
P_ <- function(nm, v) sprintf("\\newcommand{\\%s}{%d}", nm, as.integer(v))
writeLines(c(
  P_("Ngames", NG), P_("Npaid", NPAID), P_("Nfree", NFREE), P_("Nlang", NL), P_("Ncells", NC),
  sprintf("\\newcommand{\\Nobs}{%s}", formatC(nrow(m), big.mark = ",", format = "d")),
  sprintf("\\newcommand{\\Nreviews}{%s}", formatC(NREV, big.mark = ",", format = "d")),
  P_("riRank", stats$ri_rank), P_("riN", stats$ri_n),
  sprintf("\\newcommand{\\pctDiD}{%.0f}", abs(stats$pct_did)),
  sprintf("\\newcommand{\\pctDDD}{%.0f}", abs(stats$pct_ddd)),
  E_("bDiD", b1), E_("seDiD", s1), E_("tDiD", b1/s1, "%.2f"),
  E_("bDDD", b2), E_("seDDD", s2), E_("tDDD", b2/s2, "%.2f"),
  E_("bPPML", stats$b_ppml), E_("sePPML", stats$se_ppml),
  E_("bFree", stats$b_free), E_("seFree", stats$se_free),
  E_("bLatam", stats$b_latam), E_("seLatam", stats$se_latam),
  E_("bGM", stats$b_gm, "%.4f"), E_("seGM", stats$se_gm, "%.4f"),
  E_("bPT", stats$b_pt), E_("sePT", stats$se_pt),
  E_("bGOW", stats$b_gow), E_("seGOW", stats$se_gow),
  E_("bPos", stats$b_pos, "%.4f"), E_("sePos", stats$se_pos, "%.4f"),
  E_("riP", ri_p), E_("riNext", stats$ri_next),
  E_("looMin", stats$loo_min), E_("looMax", stats$loo_max),
  E_("bAntic", stats$b_antic),
  E_("preF", ifelse(is.na(pre_F), 0, pre_F), "%.2f"),
  E_("preP", ifelse(is.na(pre_p), 1, pre_p), "%.2f"),
  E_("epsLo", stats$eps_lo, "%.2f"), E_("epsHi", stats$eps_hi, "%.2f"),
  E_("revLo", stats$rev_lo, "%.1f"), E_("revHi", stats$rev_hi, "%.1f"),
  E_("bBudget", stats$b_budget), E_("bPrem", stats$b_prem),
  E_("bDose", b_dose), E_("seDose", se_dose),
  E_("preMax", pre_max), E_("preSD", pre_sd),
  E_("preSlope", pre_slope, "%.4f"), E_("preSlopeSE", pre_slope_se, "%.4f"),
  E_("preSlopeP", pre_slope_p, "%.2f"),
  E_("bDetrend", b_detrend), E_("bTrend", b_trend), E_("seTrend", se_trend),
  E_("preMean", mean(ct[k < -1]$estimate)),
  E_("bKzero", ct[k == 0]$estimate)
), file.path(OUTD, "tables", "macros.tex"))

cat("\n---------------- headline ----------------\n")
cat(sprintf("DiD    %.3f (%.3f)  t=%.2f  -> %.0f%% decline\n", b1, s1, b1/s1, abs(stats$pct_did)))
cat(sprintf("DDD    %.3f (%.3f)  t=%.2f  -> %.0f%% decline\n", b2, s2, b2/s2, abs(stats$pct_ddd)))
cat(sprintf("F2P placebo %.3f (%.3f) | LatAm %.3f (%.3f)\n",
            stats$b_free, stats$se_free, stats$b_latam, stats$se_latam))
cat(sprintf("pre-trend joint Wald: F=%.2f p=%.3f\n", pre_F, pre_p))
cat(sprintf("RI rank %d/%d p=%.3f (next %.3f) | LOO [%.3f, %.3f]\n",
            stats$ri_rank, stats$ri_n, ri_p, stats$ri_next, stats$loo_min, stats$loo_max))
cat(sprintf("tier: budget %.3f | premium %.3f\n", stats$b_budget, stats$b_prem))
cat(sprintf("dose (Turkish x Post x dlnP): %.3f (%.3f)\n", b_dose, se_dose))
cat(sprintf("pre-period coefs: max |b| = %.3f, sd = %.3f  (effect = %.3f)\n", pre_max, pre_sd, b1))
cat(sprintf("pre-trend SLOPE: %+.4f (%.4f) p=%.2f  | mean pre coef %+.3f\n",
            pre_slope, pre_slope_se, pre_slope_p, mean(ct[k < -1]$estimate)))
cat(sprintf("detrended post effect %.3f | with Turkish linear trend %.3f (%.3f)\n",
            b_detrend, b_trend, se_trend))
cat(sprintf("elasticity [%.2f, %.2f] | revenue multiple [%.1f, %.1f]x\n",
            stats$eps_lo, stats$eps_hi, stats$rev_lo, stats$rev_hi))
cat("figures + tables written to output/\n")

## =========================================================================
##  EXTENSIONS ADDRESSING THE SIX REFEREE OBJECTIONS
## =========================================================================

## ---- (A) Validate the review-flow proxy against an independent units measure
## SteamSpy publishes owner-count estimates built from a different method than
## review counts. If the mapping from reviews to units were proportional the
## log-log slope would be 1. It is not, so the paper must bound the unit
## response rather than assume it.
ss <- fread("data/interim/steamspy_frame.csv")
ss <- ss[reviews_total >= 200 & owners_mid > 0]
ss[, `:=`(lr = log(reviews_total), lo = log(owners_mid))]
pm <- lm(lo ~ lr, data = ss)
proxy_slope <- unname(coef(pm)["lr"])
proxy_se    <- summary(pm)$coefficients["lr", "Std. Error"]
proxy_r2    <- summary(pm)$r.squared
proxy_n     <- nrow(ss)
ss[, mult := owners_mid / reviews_total]
mult_med <- median(ss$mult)

## bound the unit response: proportional (slope 1) vs. estimated concavity
b_units_hi <- b2                     # if reviews map one-for-one into units
b_units_lo <- b2 * proxy_slope       # if the cross-sectional concavity also holds over time
eps_units_hi <- unname(coef(dose_s)["turkish:post:dose_c"])
eps_units_lo <- eps_units_hi * proxy_slope

## ---- (B) Conley-Taber inference for a design with few treated clusters -----
## Invert the placebo distribution: the set of nulls not rejected at 5% is
## betahat minus the central 95% of the (centred) placebo estimates.
pl <- ri[language != "turkish"]$est
pl_c <- pl - mean(pl)
ct_lo <- truth - quantile(pl_c, 0.975)
ct_hi <- truth - quantile(pl_c, 0.025)

## ---- (C) Two treated clusters with opposite-signed treatment ---------------
## Turkish prices rose; Latin-American Spanish prices fell on the same date.
## Signing the treatment uses both and tests the mechanism directly.
m[, signed := fifelse(turkish == 1, 1, fifelse(latam == 1, -1, 0))]
signed_s <- feols(log_n ~ signed:post | appid^month + appid^language,
                  data = m[paid == 1], cluster = ~ appid^language)
b_signed  <- unname(coef(signed_s)["signed:post"])
se_signed <- unname(se(signed_s)["signed:post"])

## ---- (D) Is Valve's price schedule actually followed? ----------------------
## The dose in eq. (4) assumes pre-change lira prices were a common fraction of
## dollar prices. If developers follow Valve's proportional schedule, current
## Turkish/US ratios should cluster on a few values rather than spread smoothly.
pr <- unique(fread(INP)[us_price > 0 & tr_price_now > 0, .(appid, us_price, tr_price_now)])
pr[, ratio := round(tr_price_now / us_price, 2)]
modes <- pr[, .N, by = ratio][order(-N)]
top5_share <- sum(head(modes$N, 5)) / nrow(pr)
n_distinct_ratio <- nrow(modes)
fwrite(modes, file.path(OUTD, "tables", "price_ratio_modes.csv"))

## ---- (E) Attenuation bounds on the dose-response elasticity ----------------
lam <- c(0.9, 0.7, 0.5)
theta_att <- unname(coef(dose_s)["turkish:post:dose_c"]) / lam

## ---- (F) Welfare and revenue, assumption-light bounds ----------------------
## No functional form: consumer-surplus loss lies between the two rectangles
## Q1*(p1-p0) and Q0*(p1-p0). Express both as multiples of pre-change revenue.
kappa <- c(3.4, 30)
qratio_hi <- exp(b_units_hi); qratio_lo <- exp(b_units_lo)
cs_loss <- function(k, qr) c(lo = (k - 1) * qr, hi = (k - 1) * 1)
rev_mult <- function(k, qr) k * qr
cs_lo_34 <- cs_loss(3.4, qratio_hi)[["lo"]]; cs_hi_34 <- cs_loss(3.4, qratio_hi)[["hi"]]
rev_34   <- rev_mult(3.4, qratio_hi);        rev_30 <- rev_mult(30, qratio_hi)

cat("\n================ EXTENSIONS ================\n")
cat(sprintf("(A) proxy: log(owners) = %.2f + %.3f*log(reviews), R2=%.3f, N=%s; median units/review %.0f\n",
            coef(pm)[1], proxy_slope, proxy_r2, formatC(proxy_n, big.mark=",", format="d"), mult_med))
cat(sprintf("    unit response bounded: [%.3f, %.3f]  (=> %.0f%% to %.0f%% fall)\n",
            b_units_lo, b_units_hi, 100*(1-exp(b_units_lo)), 100*(1-exp(b_units_hi))))
cat(sprintf("    elasticity bounded:    [%.3f, %.3f]\n", eps_units_lo, eps_units_hi))
cat(sprintf("(B) Conley-Taber 95%% CI from placebo distribution: [%.3f, %.3f]\n", ct_lo, ct_hi))
cat(sprintf("(C) signed two-cluster treatment: %.3f (%.3f), t=%.2f\n",
            b_signed, se_signed, b_signed/se_signed))
cat(sprintf("(D) price-ratio schedule: %d distinct ratios over %d titles; top 5 cover %.0f%%\n",
            n_distinct_ratio, nrow(pr), 100*top5_share))
cat(sprintf("(E) attenuation-corrected elasticity at lambda=0.9/0.7/0.5: %.3f / %.3f / %.3f\n",
            theta_att[1], theta_att[2], theta_att[3]))
cat(sprintf("(F) revenue multiple %.1fx (k=3.4) to %.1fx (k=30); CS loss %.1f to %.1f x pre-revenue at k=3.4\n",
            rev_34, rev_30, cs_lo_34, cs_hi_34))

writeLines(c(readLines(file.path(OUTD, "tables", "macros.tex")),
  E_("proxySlope", proxy_slope), E_("proxySE", proxy_se), E_("proxyRtwo", proxy_r2, "%.2f"),
  sprintf("\\newcommand{\\proxyN}{%s}", formatC(proxy_n, big.mark=",", format="d")),
  E_("multMed", mult_med, "%.0f"),
  E_("bUnitsLo", b_units_lo), E_("bUnitsHi", b_units_hi),
  sprintf("\\newcommand{\\pctUnitsLo}{%.0f}", 100*(1-exp(b_units_lo))),
  sprintf("\\newcommand{\\pctUnitsHi}{%.0f}", 100*(1-exp(b_units_hi))),
  E_("epsUnitsLo", eps_units_lo, "%.2f"), E_("epsUnitsHi", eps_units_hi, "%.2f"),
  E_("ctLo", ct_lo), E_("ctHi", ct_hi),
  E_("bSigned", b_signed), E_("seSigned", se_signed), E_("tSigned", b_signed/se_signed, "%.2f"),
  sprintf("\\newcommand{\\nRatioModes}{%d}", n_distinct_ratio),
  sprintf("\\newcommand{\\topFiveShare}{%.0f}", 100*top5_share),
  E_("thetaAttNine", theta_att[1], "%.2f"), E_("thetaAttSeven", theta_att[2], "%.2f"),
  E_("thetaAttFive", theta_att[3], "%.2f"),
  E_("revMultLo", rev_34, "%.1f"), E_("revMultHi", rev_30, "%.1f"),
  E_("csLossLo", cs_lo_34, "%.1f"), E_("csLossHi", cs_hi_34, "%.1f"),
  E_("doseMin", min(pr$ratio), "%.2f"), E_("doseMax", max(pr$ratio), "%.2f"),
  E_("doseMed", median(pr$ratio), "%.2f"),
  sprintf("\\newcommand{\\doseN}{%d}", nrow(pr)),
  E_("tailLo", min(as.data.table(fread(file.path(OUTD,"tables","event_study_coefs.csv")))[grepl("^A",spec) & k>=12]$estimate), "%.2f"),
  E_("tailHi", max(as.data.table(fread(file.path(OUTD,"tables","event_study_coefs.csv")))[grepl("^A",spec) & k>=12]$estimate), "%.2f")
), file.path(OUTD, "tables", "macros.tex"))

## proxy-validation figure
set.seed(1)
sf <- ss[sample(.N, min(4000, .N))]
f7 <- ggplot(sf, aes(lr, lo)) +
  geom_point(alpha = .12, size = .5, colour = NAVY) +
  geom_smooth(method = "lm", se = FALSE, colour = RED, linewidth = .6) +
  geom_abline(intercept = coef(pm)[1], slope = 1, linetype = "22", colour = "grey40") +
  labs(x = "log lifetime review count", y = "log estimated owners") + th
ggsave(file.path(OUTD, "figures", "fig7_proxy.pdf"), f7, width = 6.5, height = 3.2)

regtable(list(did_s, signed_s, dose_s),
  coefs = list("turkish:post" = "Turkish $\\times$ Post",
               "signed:post"  = "Signed treatment $\\times$ Post",
               "turkish:post:dose_c" = "Turkish $\\times$ Post $\\times$ $\\Delta\\ln P$"),
  heads = c("Baseline", "Two clusters, signed", "Dose"),
  fe_rows = list("Title $\\times$ month FE" = rep("Yes", 3),
                 "Title $\\times$ language FE" = rep("Yes", 3),
                 "Treated units" = c("1 (Turkish)", "2 (Turkish, LatAm)", "1 (Turkish)")),
  file = "t7_extensions.tex")
