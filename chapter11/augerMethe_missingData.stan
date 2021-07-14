
data {
	int<lower = 1> nb_data; // Number of data without initial state
	int<lower = nb_data> nb_states; // Number of states without initial state
	
	real z0; // Initial state
	int<lower = 1, upper = nb_states + 1> indices[nb_data + 1];
	
	real realStates[nb_states + 1]; // The real values of the states
	real Y[nb_data + 1];
}

parameters {
	real alpha;

	real<lower = 0.0001> processError;
	real<lower = 0.0001> observationError;

	real Z[nb_states + 1];
}

model {
	target += normal_lpdf(alpha | 0, 1000);
	target += gamma_lpdf(processError | 0.01, 0.01);
	target += gamma_lpdf(observationError | 0.01, 0.01);

	target += normal_lpdf(Z[1] | alpha*z0, processError);
	// Forward algo
	for (i in 1:nb_states)
		target += normal_lpdf(Z[i + 1] | alpha*Z[i], processError);

	target += normal_lpdf(Y | Z[indices], observationError);
}

generated quantities {
	real errorSates[nb_states + 1]; // recording dynamics of processError
	real errorObs[nb_data + 1]; // recording dynamics of observationError
	
	for (i in 1:(nb_states + 1))
		errorSates[i] = Z[i] - realStates[i];
	
	for (i in 1:(nb_data + 1))
		errorObs[i] = Z[indices[i]] - Y[i];
}
