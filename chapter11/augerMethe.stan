
data {
	int<lower = 1> nb_data; // Number of data without initial state

	real z0; // Initial state
	
	real realStates[nb_data + 1]; // The real values of the states
	real Y[nb_data + 1];
}

parameters {
	real alpha;

	real<lower = 0> processError;
	real<lower = 0> observationError;

	real Z[nb_data + 1];
}

model {
	target += normal_lpdf(alpha | 0, 1000);
	target += gamma_lpdf(processError | 0.01, 0.01);
	target += gamma_lpdf(observationError | 0.01, 0.01);

	target += normal_lpdf(Z[1] | alpha*z0, processError);
	// Forward algo
	for (i in 1:nb_data)
	{
		target += normal_lpdf(Z[i + 1] | alpha*Z[i], processError);
		target += normal_lpdf(Y[i] | Z[i], observationError);
	}

	target += normal_lpdf(Y[nb_data + 1] | Z[nb_data + 1], observationError); // The forgotten!
}

generated quantities {
	real errorSates[nb_data + 1]; // recording dynamics of processError
	real errorObs[nb_data + 1]; // recording dynamics of observationError
	
	for (i in 1:(nb_data + 1))
		errorSates[i] = Z[i] - realStates[i];
	
	for (i in 1:(nb_data + 1))
		errorObs[i] = Z[i] - Y[i];
}
