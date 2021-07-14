
#### This script is related to A guide to state-space modeling of ecological time series, Auger-Méthé et al., (2021)
# https://arxiv.org/pdf/2002.02001.pdf

#### Load libraries
rm(list = ls())
graphics.off()

library(data.table)
library(bayesplot)
library(cmdstanr)

options(max.print = 500)

###############################################################?
######## 		FIRST PART: With complete dataset 		########
###############################################################?

#### Tool function
## Initiate Y_gen with reasonable value (by default, stan would generate them between 0 and 2---constraint Y_gen > 0)
init_fun = function(...)
{
	providedArgs = list(...)
	requiredArgs = c("Y")
	if (!all(requiredArgs %in% names(providedArgs)))
		stop("You must provide Y")
	
	Y = providedArgs[["Y"]]

	Z = rnorm(length(Y), Y, 1)

	return(list(Z = Z))
}

#### Create data
## Common variables
nb_data = 80 # Number of data

## Parameters
processError = 0.1
observationError = 0.1

alpha = 1.1 # Model does not converge with alpha too far from 1 and with too many data. I guess because of exponential!

## States
data = data.table(time = 0:nb_data, Z = numeric(length = nb_data + 1), Y = numeric(length = nb_data + 1))
data[1, Z:= 0]

set.seed(553)
for (i in 1:nb_data)
	data[i + 1, Z := rnorm(1, alpha*data[i, Z], processError)]

data[2:.N, Y := rnorm(nb_data, Z, observationError)]

plot(data[, time], data[, Z], pch = 19, cex = 0.7, col="red", ty = "o", xlab = "t", ylab = expression(Y[t], Z[t]),
	ylim = c(min(data[, .(Y, Z)]) - abs(min(data[, .(Y, Z)]))/10, max(data[, .(Y, Z)] + max(data[, .(Y, Z)]/10))), las = 1)
points(data[, time], data[, Y], pch = 3, cex = 0.8, col = "blue", ty = "o", lty = 3)

legend("top", legend = c("Obs.", "True states"), pch = c(3, 19),
	col = c("blue", "red"), lty = c(3, 1), horiz=TRUE, bty="n", cex=0.9)

#### Stan model
## Define stan variables
# Common variables
maxIter = 2e3
n_chains = 4

# Data to provide
stanData = list(
	nb_data = nb_data, # Number of data without initial state
	z0 = 0,
	Y = data[, Y]
)

initVal_Z = lapply(1:n_chains, init_fun, Y = data[, Y])

model = cmdstan_model("augerMethe.stan")

## Run model
start = proc.time()

results = model$sample(data = stanData, parallel_chains = n_chains, refresh = floor(maxIter/4), chains = n_chains,
	iter_warmup = maxIter/2, iter_sampling = maxIter/2, init = initVal_Z, max_treedepth = 12, adapt_delta = 0.95)

proc.time() - start

results
results$cmdstan_diagnose()

rhat_vec = rhat(results)
range(rhat_vec)
if (max(rhat_vec) > 1.1)
{
	names(rhat_vec[rhat_vec > 1.1])
}

plot_title = ggplot2::ggtitle("Posterior distributions", "with medians and 80% intervals")
mcmc_areas(results$draws("alpha"), prob = 0.8) + plot_title

plot_title = ggplot2::ggtitle("Traces for intercept")
mcmc_trace(results$draws("alpha")) + plot_title

############################################################?
######## 		SECOND PART: With missing data 	 	########
############################################################?

#### Create data
## Common variables
nb_data = 200 # Number of data
nb_data_kept = 100 # Make sure to keep enough

## Parameters
processError = 0.1
observationError = 0.1

alpha = 1

## States
data = data.table(time = 0:nb_data, Z = numeric(length = nb_data + 1), Y = numeric(length = nb_data + 1))
data[1, Z:= 0]

set.seed(553)
for (i in 1:nb_data)
	data[i + 1, Z := rnorm(1, alpha*data[i, Z], processError)]

data[2:.N, Y := rnorm(nb_data, Z, observationError)]

## Select rows to keep
kept_rows = sort(sample(x = 2:(nb_data + 1), size = nb_data_kept, replace = FALSE))

Y = c(data[1, Y], data[kept_rows, Y])

## Plot
plot(data[, time], data[, Z], pch = 19, cex = 0.7, col="red", ty = "o", xlab = "t", ylab = expression(Y[t], Z[t]),
	ylim = c(min(data[, .(Y, Z)]) - abs(min(data[, .(Y, Z)]))/10, max(data[, .(Y, Z)] + max(data[, .(Y, Z)]/10))), las = 1)
points(data[kept_rows, time], data[kept_rows, Y], pch = 3, cex = 0.8, col = "blue", ty = "o", lty = 3)

legend("top", legend = c("Obs.", "True states"), pch = c(3, 19),
	col = c("blue", "red"), lty = c(3, 1), horiz=TRUE, bty="n", cex=0.9)

#### Stan model
## Define stan variables
# Common variables
maxIter = 8e3
n_chains = 4

# Data to provide
stanData = list(
	nb_data = nb_data_kept, # Number of data without initial state
	nb_states = nb_data,
	z0 = 0,
	indices = c(1, kept_rows),
	Y = Y
)

model = cmdstan_model("augerMethe_missingData.stan")

## Run model
start = proc.time()

results = model$sample(data = stanData, parallel_chains = n_chains, refresh = 0, chains = n_chains,
	iter_warmup = maxIter/2, iter_sampling = maxIter/2, max_treedepth = 10)

proc.time() - start

results
results$cmdstan_diagnose()

range(rhat(results))

plot_title = ggplot2::ggtitle("Posterior distributions", "with medians and 80% intervals")
mcmc_areas(results$draws("observationError"), prob = 0.8) + plot_title

plot_title = ggplot2::ggtitle("Traces for observationError")
mcmc_trace(results$draws("observationError")) + plot_title
