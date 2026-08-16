#!/usr/bin/env Rscript
# ---------------------------------------------------------------------------
# Full analysis: every table and figure in the paper, regenerated from scratch.
#   Rscript code/analysis_full.R
# Writes LaTeX fragments to output/tables/*.tex and figures to output/figures/*.pdf
# ---------------------------------------------------------------------------
suppressPackageStartupMessages({
  library(data.table); library(fixest); library(ggplot2)
  library(modelsummary); library(broom)
})
setFixest_notes(FALSE)


INP  <- "data/interim/panel_weekly.csv"
OUTD <- "output"
dir.create(file.path(OUTD, "figures"), recursive = TRUE, showWarnings = FALSE)
dir.create(file.path(OUTD, "tables"),  recursive = TRUE, showWarnings = FALSE)

EVENT_M <- as.Date("2023-11-01")
W0 <- as.Date("2022-07-01"); W1 <- as.Date("2025-06-01")

## ------------------------------------------------------------------ load ----
p <- fread(INP); p[, week := as.Date(week)]
cov  <- p[, .(lo = min(week), hi = max(week)), by = .(appid, language)]
keep <- cov[lo <= W0 & hi >= W1, .(appid, language)]
d <- merge(p, keep, by = c("appid", "language"))[week >= W0 & week <= W1]
d[, month := as.Date(format(week, "%Y-%m-01"))]

m <- d[, .(n = sum(n),
           share_nonsteam = weighted.mean(share_nonsteam, n + 1, na.rm = TRUE),
           share_pos      = weighted.mean(share_pos,      n + 1, na.rm = TRUE),
           med_playtime   = median(med_playtime,    na.rm = TRUE),
           med_games      = median(med_games_owned, na.rm = TRUE)),
       by = .(appid, name, language, month, is_free, us_price)]
m[, `:=`(log_n = log(n + 1),
         turkish = as.integer(language == "turkish"),
         paid    = as.integer(is_free == FALSE),
         post    = as.integer(month > EVENT_M))]
m[, rel_m := (as.integer(format(month, "%Y")) - 2023) * 12 +
             (as.integer(format(month, "%m")) - 11)]
m[, tr_paid := turkish * paid]
m[, log_pt  := log(med_playtime + 1)]

NG <- uniqueN(m$appid); NL <- uniqueN(m$language); NC <- uniqueN(m[, .(appid, language)])
cat(sprintf("games %d | languages %d | cells %d | obs %d | paid %d | free %d\n",
            NG, NL, NC, nrow(m), uniqueN(m[paid == 1]$appid), uniqueN(m[paid == 0]$appid)))

mp <- m[paid == 1]

## -------------------------------------------------------------- models ------
did_s  <- feols(log_n ~ turkish:post | appid^month + appid^language,
                data = mp, cluster = ~ appid^language)
ddd_s  <- feols(log_n ~ tr_paid:post | appid^month + language^month + appid^language,
                data = m,  cluster = ~ appid^language)
did_e  <- feols(log_n ~ i(rel_m, turkish, ref = -1) | appid^month + appid^language,
                data = mp, cluster = ~ appid^language)
ddd_e  <- feols(log_n ~ i(rel_m, tr_paid, ref = -1) |
                  appid^month + language^month + appid^language,
                data = m, cluster = ~ appid^language)
ppml   <- fepois(n ~ turkish:post | appid^month + appid^language,
                 data = mp, cluster = ~ appid^language)

## substitution / composition
gm_s   <- feols(share_nonsteam ~ turkish:post | appid^month + appid^language,
                data = mp, cluster = ~ appid^language)
pos_s  <- feols(share_pos ~ turkish:post | appid^month + appid^language,
                data = mp, cluster = ~ appid^language)
pt_s   <- feols(log_pt ~ turkish:post | appid^month + appid^language,
                data = mp, cluster = ~ appid^language)
gow_s  <- feols(log(med_games + 1) ~ turkish:post | appid^month + appid^language,
                data = mp, cluster = ~ appid^language)
free_s <- feols(log_n ~ turkish:post | appid^month + appid^language,
                data = m[paid == 0], cluster = ~ appid^language)

## ------------------------------------------------------- placebo dates ------
placebo <- rbindlist(lapply(c(-12, -6, 6), function(sh) {
  mm <- copy(mp)
  mm[, fpost := as.integer(rel_m > sh)]
  if (sh < 0) mm <- mm[rel_m <= -1]      # pre-event only, so the true event cannot leak in
  f <- feols(log_n ~ turkish:fpost | appid^month + appid^language,
             data = mm, cluster = ~ appid^language)
  data.table(shift = sh,
             est = unname(coef(f)["turkish:fpost"]),
             se  = unname(se(f)["turkish:fpost"]),
             n   = f$nobs)
}))

## --------------------------------------------- randomization inference ------
langs <- sort(unique(m$language))
ri <- rbindlist(lapply(langs, function(L) {
  mm <- copy(mp); mm[, fake := as.integer(language == L)]
  f <- try(feols(log_n ~ fake:post | appid^month + appid^language, data = mm), silent = TRUE)
  if (inherits(f, "try-error")) return(NULL)
  data.table(language = L, est = unname(coef(f)["fake:post"]))
}))
setorder(ri, est)
ri[, rank := .I]
truth  <- ri[language == "turkish"]$est
ri_p   <- mean(ri$est <= truth)
fwrite(ri, file.path(OUTD, "tables", "ri.csv"))

## ------------------------------------------------- leave-one-out (games) ----
loo <- rbindlist(lapply(unique(mp$appid), function(a) {
  f <- try(feols(log_n ~ turkish:post | appid^month + appid^language,
                 data = mp[appid != a], cluster = ~ appid^language), silent = TRUE)
  if (inherits(f, "try-error")) return(NULL)
  data.table(dropped = a, est = unname(coef(f)["turkish:post"]))
}))
fwrite(loo, file.path(OUTD, "tables", "loo.csv"))

## ================================ TABLES ====================================
## T1 summary statistics
t1 <- m[, .(`Game-months` = .N,
            `Mean reviews/month` = round(mean(n), 1),
            `Median reviews/month` = round(median(n), 1),
            `Share positive` = round(mean(share_pos, na.rm = TRUE), 3),
            `Share non-Steam key` = round(mean(share_nonsteam, na.rm = TRUE), 3)),
        by = .(Language = language)][order(-`Mean reviews/month`)]
fwrite(t1, file.path(OUTD, "tables", "t1_summary.csv"))

esc <- function(x) gsub("_", "\\\\_", x)
w <- function(f, s) writeLines(s, file.path(OUTD, "tables", f))

w("t1_summary.tex", c(
  "\\begin{tabular}{lrrrrr}", "\\toprule",
  "Language & Game-months & Mean rev./mo & Median & Share pos. & Non-Steam key \\\\", "\\midrule",
  paste0(esc(t1$Language), " & ", t1$`Game-months`, " & ", t1$`Mean reviews/month`, " & ",
         t1$`Median reviews/month`, " & ", t1$`Share positive`, " & ",
         t1$`Share non-Steam key`, " \\\\"),
  "\\bottomrule", "\\end{tabular}"))

## ---- hand-rolled LaTeX regression table (no kableExtra dependency) ---------
stars <- function(b, s) {
  if (is.na(b) || is.na(s) || s == 0) return("")
  p <- 2 * pnorm(-abs(b / s))
  if (p < .01) "$^{***}$" else if (p < .05) "$^{**}$" else if (p < .1) "$^{*}$" else ""
}
regtable <- function(models, coefs, colnames_, fe_rows, notes_cols, file, digits = 3) {
  k <- length(models)
  fmt <- paste0("%.", digits, "f")
  lines <- c(paste0("\\begin{tabular}{l", strrep("c", k), "}"), "\\toprule",
             paste0(" & ", paste(sprintf("(%d)", seq_len(k)), collapse = " & "), " \\\\"),
             paste0(" & ", paste(colnames_, collapse = " & "), " \\\\"),
             "\\midrule")
  for (cf in names(coefs)) {
    b <- sapply(models, function(mm) { v <- coef(mm); if (cf %in% names(v)) unname(v[cf]) else NA })
    s <- sapply(models, function(mm) { v <- se(mm);   if (cf %in% names(v)) unname(v[cf]) else NA })
    est <- mapply(function(bb, ss) if (is.na(bb)) "" else
                    paste0("$", sprintf(fmt, bb), "$", stars(bb, ss)), b, s)
    ses <- sapply(s, function(ss) if (is.na(ss)) "" else paste0("($", sprintf(fmt, ss), "$)"))
    lines <- c(lines,
               paste0(coefs[[cf]], " & ", paste(est, collapse = " & "), " \\\\"),
               paste0(" & ", paste(ses, collapse = " & "), " \\\\[2pt]"))
  }
  lines <- c(lines, "\\midrule")
  for (nm in names(fe_rows)) lines <- c(lines, paste0(nm, " & ", paste(fe_rows[[nm]], collapse = " & "), " \\\\"))
  lines <- c(lines,
             paste0("Observations & ", paste(formatC(sapply(models, function(mm) mm$nobs),
                                                     big.mark = ",", format = "d"), collapse = " & "), " \\\\"),
             "\\bottomrule", "\\end{tabular}")
  writeLines(lines, file)
}

regtable(list(did_s, ddd_s, ppml, free_s),
         coefs = list("turkish:post" = "Turkish $\\times$ Post",
                      "tr_paid:post" = "Turkish $\\times$ Paid $\\times$ Post"),
         colnames_ = c("DiD", "DDD", "PPML", "F2P only"),
         fe_rows = list("Game $\\times$ month FE" = rep("Yes", 4),
                        "Language $\\times$ month FE" = c("No", "Yes", "No", "No"),
                        "Game $\\times$ language FE" = rep("Yes", 4),
                        "Sample" = c("Paid", "All", "Paid", "Free")),
         file = file.path(OUTD, "tables", "t2_main.tex"))

regtable(list(gm_s, pos_s, pt_s, gow_s),
         coefs = list("turkish:post" = "Turkish $\\times$ Post"),
         colnames_ = c("Non-Steam key", "Share positive", "log playtime", "log games owned"),
         fe_rows = list("Game $\\times$ month FE" = rep("Yes", 4),
                        "Game $\\times$ language FE" = rep("Yes", 4)),
         file = file.path(OUTD, "tables", "t4_composition.tex"), digits = 4)

## T3 placebo
w("t3_placebo.tex", c(
  "\\begin{tabular}{lrrr}", "\\toprule",
  "Fake event (months from true) & Estimate & Std. error & Obs. \\\\", "\\midrule",
  paste0("$", placebo$shift, "$ & $", sprintf("%.3f", placebo$est), "$ & ($",
         sprintf("%.3f", placebo$se), "$) & ", placebo$n, " \\\\"),
  "\\midrule",
  paste0("\\textbf{True event (0)} & $\\mathbf{", sprintf("%.3f", coef(did_s)[["turkish:post"]]),
         "}$ & ($\\mathbf{", sprintf("%.3f", se(did_s)[["turkish:post"]]), "}$) & \\textbf{",
         did_s$nobs, "} \\\\"),
  "\\bottomrule", "\\end{tabular}"))

## ================================ FIGURES ===================================
evtab <- function(model, lab) {
  ct <- as.data.table(tidy(model, conf.int = TRUE))[grepl("rel_m::", term)]
  ct[, k := as.integer(sub(".*rel_m::(-?[0-9]+).*", "\\1", term))]
  rbind(ct[, .(k, estimate, conf.low, conf.high)],
        data.table(k = -1, estimate = 0, conf.low = 0, conf.high = 0))[, spec := lab][]
}
E <- rbind(evtab(did_e, "Panel A. DiD: Turkish vs. other languages, paid titles"),
           evtab(ddd_e, "Panel B. DDD: adding free-to-play titles as a within-Turkey control"))
fwrite(E, file.path(OUTD, "tables", "event_study_coefs.csv"))

th <- theme_minimal(base_size = 10) +
  theme(panel.grid.minor = element_blank(),
        strip.text = element_text(face = "bold", hjust = 0),
        plot.title = element_text(face = "bold"))

f1 <- ggplot(E[k >= -16 & k <= 18], aes(k, estimate)) +
  geom_hline(yintercept = 0, linewidth = .3, colour = "grey35") +
  geom_vline(xintercept = -0.5, linetype = "dashed", linewidth = .4, colour = "#b2182b") +
  geom_ribbon(aes(ymin = conf.low, ymax = conf.high), alpha = .16, fill = "#2166ac") +
  geom_line(colour = "#2166ac", linewidth = .5) +
  geom_point(colour = "#2166ac", size = 1.1) +
  facet_wrap(~spec, ncol = 1) +
  labs(x = "Months relative to 20 November 2023",
       y = "Effect on log review flow") + th
ggsave(file.path(OUTD, "figures", "fig1_event_study.pdf"), f1, width = 6.6, height = 6.0)

## F2 raw indexed flow
mm <- copy(m)
base <- mm[month >= W0 & month <= as.Date("2023-04-01"),
           .(b = mean(n)), by = .(appid, language)]
mm <- merge(mm, base, by = c("appid", "language"))
mm[, idx := n / pmax(b, .5)]
mm[, grp := fifelse(turkish == 1 & paid == 1, "Turkish, paid titles",
             fifelse(turkish == 1 & paid == 0, "Turkish, free-to-play",
                                               "Other languages, paid titles"))]
f2dat <- mm[, .(idx = mean(idx)), by = .(grp, month)]
f2 <- ggplot(f2dat, aes(month, idx, colour = grp)) +
  geom_vline(xintercept = as.numeric(as.Date("2023-11-20")), linetype = "dashed",
             colour = "#b2182b", linewidth = .4) +
  geom_line(linewidth = .6) +
  scale_colour_manual(values = c("Turkish, paid titles" = "#b2182b",
                                 "Turkish, free-to-play" = "#1a9850",
                                 "Other languages, paid titles" = "#2166ac")) +
  labs(x = NULL, y = "Review flow, indexed to Jul 2022 - Apr 2023 = 1", colour = NULL) +
  th + theme(legend.position = "bottom")
ggsave(file.path(OUTD, "figures", "fig2_raw_flow.pdf"), f2, width = 6.6, height = 3.6)

## F3 randomization inference
ri[, is_tr := language == "turkish"]
f3 <- ggplot(ri, aes(reorder(language, est), est, fill = is_tr)) +
  geom_col(width = .7) + coord_flip() +
  scale_fill_manual(values = c("FALSE" = "grey72", "TRUE" = "#b2182b"), guide = "none") +
  geom_hline(yintercept = 0, linewidth = .3) +
  labs(x = NULL, y = expression(paste("Placebo estimate of ", beta, " when this language is labelled treated"))) +
  th
ggsave(file.path(OUTD, "figures", "fig3_ri.pdf"), f3, width = 6.6, height = 4.4)

## ------------------------------------------------------- numbers for text ---
b_did <- coef(did_s)[["turkish:post"]]; s_did <- se(did_s)[["turkish:post"]]
b_ddd <- coef(ddd_s)[["tr_paid:post"]]; s_ddd <- se(ddd_s)[["tr_paid:post"]]
stats <- list(
  n_games = NG, n_lang = NL, n_cells = NC, n_obs = nrow(m),
  n_paid = uniqueN(m[paid == 1]$appid), n_free = uniqueN(m[paid == 0]$appid),
  b_did = b_did, se_did = s_did, t_did = b_did / s_did,
  pct_did = 100 * (exp(b_did) - 1),
  b_ddd = b_ddd, se_ddd = s_ddd, t_ddd = b_ddd / s_ddd,
  pct_ddd = 100 * (exp(b_ddd) - 1),
  b_ppml = unname(coef(ppml)["turkish:post"]),
  b_free = unname(coef(free_s)["turkish:post"]),
  se_free = unname(se(free_s)["turkish:post"]),
  b_gm = unname(coef(gm_s)["turkish:post"]), se_gm = unname(se(gm_s)["turkish:post"]),
  ri_p = ri_p, ri_rank = ri[language == "turkish"]$rank, ri_n = nrow(ri),
  ri_next = ri[language != "turkish"][which.min(est)]$est,
  loo_min = min(loo$est), loo_max = max(loo$est),
  eps_lo = b_did / log(1 + 29.0),      # if price rose 2900%
  eps_hi = b_did / log(1 + 2.40)       # if price rose 240%
)
jsonlite::write_json(stats, file.path(OUTD, "tables", "stats.json"),
                     auto_unbox = TRUE, digits = 6)

## LaTeX \newcommand macros so the paper never hard-codes a number
fmtm <- function(name, val, fmt = "%.3f") sprintf("\\newcommand{\\%s}{\\ensuremath{%s}}", name, sprintf(fmt, val))
mac <- c(
  sprintf("\\newcommand{\\Ngames}{%d}", NG),
  sprintf("\\newcommand{\\Nlang}{%d}", NL),
  sprintf("\\newcommand{\\Ncells}{%d}", NC),
  sprintf("\\newcommand{\\Nobs}{%s}", formatC(nrow(m), big.mark = ",", format = "d")),
  sprintf("\\newcommand{\\Npaid}{%d}", stats$n_paid),
  sprintf("\\newcommand{\\Nfree}{%d}", stats$n_free),
  sprintf("\\newcommand{\\riRank}{%d}", stats$ri_rank),
  sprintf("\\newcommand{\\riN}{%d}", stats$ri_n),
  sprintf("\\newcommand{\\pctDiD}{%.0f}", abs(stats$pct_did)),
  sprintf("\\newcommand{\\pctDDD}{%.0f}", abs(stats$pct_ddd)),
  fmtm("bDiD", b_did), fmtm("seDiD", s_did), fmtm("tDiD", b_did/s_did, "%.2f"),
  fmtm("bDDD", b_ddd), fmtm("seDDD", s_ddd), fmtm("tDDD", b_ddd/s_ddd, "%.2f"),
  fmtm("bFree", stats$b_free), fmtm("seFree", stats$se_free),
  fmtm("bGM", stats$b_gm, "%.4f"), fmtm("seGM", stats$se_gm, "%.4f"),
  fmtm("riP", ri_p), fmtm("riNext", stats$ri_next),
  fmtm("looMin", stats$loo_min), fmtm("looMax", stats$loo_max),
  fmtm("epsLo", stats$eps_lo, "%.2f"), fmtm("epsHi", stats$eps_hi, "%.2f"),
  fmtm("bPPML", stats$b_ppml)
)
writeLines(mac, file.path(OUTD, "tables", "macros.tex"))

cat("\n---- headline ----\n")
cat(sprintf("DiD  %.3f (%.3f)  t=%.2f  => %.0f%% decline\n", b_did, s_did, b_did/s_did, abs(stats$pct_did)))
cat(sprintf("DDD  %.3f (%.3f)  t=%.2f  => %.0f%% decline\n", b_ddd, s_ddd, b_ddd/s_ddd, abs(stats$pct_ddd)))
cat(sprintf("F2P placebo %.3f (%.3f)\n", stats$b_free, stats$se_free))
cat(sprintf("RI: rank %d of %d, p=%.3f, next-most-negative %.3f\n",
            stats$ri_rank, stats$ri_n, ri_p, stats$ri_next))
cat(sprintf("LOO range [%.3f, %.3f]\n", stats$loo_min, stats$loo_max))
cat(sprintf("implied elasticity range [%.2f, %.2f]\n", stats$eps_lo, stats$eps_hi))
cat("wrote tables + figures to output/\n")
