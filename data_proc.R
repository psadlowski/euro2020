setwd("C:\\Users\\sadlo\\Documents\\euro20")

library(magrittr)
library(ggplot2)
library(tidyr)
library(rstan)

############## 1. Preprocess ranking data #############

fifa16 <- read.csv("FIFA2016.csv")
fifa18 <- read.csv("FIFA2018.csv")
fifa20 <- read.csv("FIFA2021.csv")

fifa16$Year <- 2016
fifa18$Year <- 2018
fifa20$Year <- 2020

fifaRanking <- rbind(fifa16, fifa18, fifa20)
fifaRanking$Year <- as.factor(fifaRanking$Year)

head(fifaRanking)
# Standardize
fifaRanking$FIFA <- (fifaRanking$FIFA - mean(fifaRanking$FIFA)) / sd(fifaRanking$FIFA)

rm(fifa16, fifa18, fifa20)

############## 2. Preprocess match data ###################

euro16 <- read.csv("EURO16.csv", stringsAsFactors = F)
## Add the missing row
if (nrow(euro16) == 50) {
  euro16[51,] <- c("France", 2, "Romania", 1)
}
##euro16$HomeTeam <- as.factor(euro16$HomeTeam)
euro16$HomeGoals <- as.integer(euro16$HomeGoals)
##euro16$AwayTeam <- as.factor(euro16$AwayTeam)
euro16$AwayGoals <- as.integer(euro16$AwayGoals)
euro16$Year <- 2016

euro20 <- read.csv("EURO20.csv", stringsAsFactors = F)
euro20$Year <- 2020

wc18 <- read.csv("WC18.csv", stringsAsFactors = F)
wc18$Year <- 2018

matchData <- rbind(euro16, wc18, euro20)
matchData$HomeTeam <- as.factor(matchData$HomeTeam)
matchData$AwayTeam <- as.factor(matchData$AwayTeam)
matchData$Year <- as.factor(matchData$Year)

rm(euro16, wc18, euro20)

############# 3. Restructure match data ##################

matchData %>%
  merge(., fifaRanking, by.x = c("HomeTeam", "Year"), by.y = c("Country", "Year"), all.x = T, all.y = F) %>%
  merge(., fifaRanking, by.x = c("AwayTeam", "Year"), by.y = c("Country", "Year"), all.x = T, all.y = F,
        suffixes = c("", "_a")) %>%
  `colnames<-`(c(colnames(.)[1:5], "HomeRanking", "AwayRanking")) -> matchData

fixtures <- matchData[is.na(matchData$HomeGoals),]
matchData <- matchData[!is.na(matchData$HomeGoals),]

rm(fifaRanking)

matchData[,c("HomeGoals", "HomeRanking", "AwayRanking")] %>%
  `colnames<-`(c("Goals", "OwnRank", "OppRank")) -> X
matchData[,c("AwayGoals", "AwayRanking", "HomeRanking")] %>%
  `colnames<-`(c("Goals", "OwnRank", "OppRank")) %>%
  rbind(X) -> X

rm(matchData)

X$const <- 1

############ 4. Run the models ###################

options(mc.cores = parallel::detectCores())
rstan_options(auto_write = T)
Sys.setenv(LOCAL_CPPFLAGS = '-march=corei7 -mtune=corei7')

baselineData <- list(N = nrow(X),
                     X = X[,c("OwnRank", "OppRank", "const")],
                     y = X$Goals)
fit <- stan(file = "baseline.stan", data = baselineData)
pairs(fit, pars=c("beta"))
traceplot(fit, pars=c("beta"), inc_warmup = T)

fit_negbin <- stan(file = "negbin.stan", data = baselineData)

######### 5. Save model output for predictions ##########

samples <- extract(fit, pars = c("beta"))$beta
str(samples)

write.csv(samples, file = paste0("fits/fit_", Sys.Date(), ".csv"))

############## 6. Run predictions ##################

## Calculate lambdas
as.matrix(cbind(fixtures[,c("HomeRanking", "AwayRanking")], 1)) %*% t(samples) %>%
  exp() %>% rowSums() %>% `/`(4000) -> fixtures$HomeLambda
as.matrix(cbind(fixtures[,c("AwayRanking", "HomeRanking")], 1)) %*% t(samples) %>%
  exp() %>% rowSums() %>% `/`(4000) -> fixtures$AwayLambda

ix <- 1
teamnames <- sapply(fixtures[ix, c("HomeTeam", "AwayTeam")], as.character)
cbind(0:10,
      dpois(0:10, fixtures[ix, "HomeLambda"]),
      dpois(0:10, fixtures[ix, "AwayLambda"])) %>%
  data.frame() %>%
  `colnames<-`(c("Goals", teamnames)) %>%
  pivot_longer(cols = all_of(teamnames), names_to = "Team", values_to = "Prob") %>%
  ggplot() + geom_col(aes(x = Goals, y = Prob, fill = Team), position = "dodge") +
  scale_x_continuous(breaks = 0:10)





head(fixtures)

apply(samples, 2, mean)
  
dim(samples)

preds <- as.matrix(fixtures[,-1]) %*% t(samples)
colnames(preds) <- 1:ncol(preds)

str(fit)

gfit <- glm(Goals ~ const + OwnRank + OppRank, data = X, family = "poisson")
summary(gfit)
