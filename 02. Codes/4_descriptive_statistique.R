##Clearing the environment
rm(list=ls())


#Libraries packages usful for the analysis
library("haven")
library("tidyverse")
library("igraph")
library(hrbrthemes) ## theme(s) I like
library(stargazer)
library("Hmisc")

#Seting the environment for the analisis
Paths <- c("C:/Users/richm/Dropbox/Projet d'économétrie",
           "C:/Users/frans/Dropbox/Projet d'économétrie",
           "C:/Users/richa/Dropbox/Projet d'économétrie",
           "/Users/rgnikiea/Dropbox/Projet d'économétrie")


names(Paths) <- c("richm", "frans","richa", "rgnikiea")
setwd(Paths[Sys.info()[["user"]]])
Sys.info()[["user"]]

data <- read_dta("02. Data/Cleaned data/FinalDatabase.dta")

names(data)


cor_mat <- na.omit(data %>% select(remitofgdp, IV2, vectorlang, prob_remit))
cor_mat <- data.frame(cor_mat)

`Transferts des migrants (% PIB)` <- cor_mat$remitofgdp
Instrument <- cor_mat$IV2
Centralite <- cor_mat$vectorlang
Probabilité <- cor_mat$prob_remit

mcor <- rcorr(cbind(`Transferts des migrants (% PIB)`,
                    Instrument, Centralite, Probabilité), type = "pearson")

corre <- mcor[["r"]]
signi <- as.matrix(mcor[["P"]])

stargazer(corre, summary = F , out = "04. Results/Tables/corre_mat.html")
stargazer(corre, summary = F , out = "04. Results/Tables/corre_mat.tex")

ggplot(data) + geom_line(aes(x = remit_cons, y = invest))
ggplot(data) + geom_smooth(aes(x = remit_cons, y = invest)) + facet_grid(~incomegroup)

vf <- data[data$year == 2019, ]$remit_year[1]
vi <- data[data$year == 1990, ]$remit_year[1]
coef_remit <- vf / vi
taux <- (coef_remit -1)*100

coef_moyen <- coef_remit^(1/(2019-1990))
taux_moyen <- (coef_moyen -1)*100
df <- data %>% select(invest, inf, trade, remitofgdp,fdi,gdpgrowthannual,credit_priv,ka_open,fd, gov_stab, corup)
names(df) <- c("Investissement privé (% PIB)", "Inflation", "Ouverture commerciale" ,"Transfert des migrants", "Investissement direct étranger",
               "Croissance du PIB", "Crédit privé (% PIB)", "Ouverture financière", "Developpement financier" , "Stabilité politique", "Contrôle de corruption")
df <- data.frame(df)
stargazer(df, out = "04. Results/Tables/stat_desc.html")
stargazer(df, out = "04. Results/Tables/stat_desc.tex")

df <- matrix(data$country %>% unique(), ncol = 4)
df <- data.frame(df)
stargazer(df, summary = F, out = "04. Results/Tables/countries.html")
stargazer(df, summary = F, out = "04. Results/Tables/countries.tex")

mean_prob <- mean(data$prob_remit, na.rm = TRUE)
prob_below <- ifelse(data$prob_remit <= mean_prob, 0, 1)

df <- data %>% select(remitofgdp, invest, year) %>% mutate(prob_below = prob_below)
head(df)

df <- df %>% group_by(prob_below, year) %>% summarise(remitofgdp = mean(remitofgdp, na.rm = T),
                                                      invest = mean(invest, na.rm = T),
                                                      .groups = 'drop')

df <- df %>% gather(variables, value, -year, -prob_below )
head(df)
df$prob_below <- as.character(df$prob_below)
df <- na.omit(df)
ggplot(df) + geom_line(aes(x = year, y = value, group = prob_below, col = prob_below)) + facet_grid(~variables)
