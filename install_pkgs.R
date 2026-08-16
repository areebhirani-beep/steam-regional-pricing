options(repos=c(CRAN="https://cloud.r-project.org"))
pk <- c("data.table","fixest","did","didimputation","bacondecomp","HonestDiD",
        "rdrobust","modelsummary","sandwich","lmtest","ggplot2","broom",
        "jsonlite","httr2","stringi","fst","kableExtra","tinytable","future.apply")
inst <- rownames(installed.packages())
for (p in pk) if (!(p %in% inst)) install.packages(p, quiet=TRUE)
cat("INSTALLED:\n"); print(sapply(pk, function(p) requireNamespace(p, quietly=TRUE)))
