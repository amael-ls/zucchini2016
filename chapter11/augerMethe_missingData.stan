
data {
	int<lower = 1> nb_data; // Number of data without initial state
	int<lower = nb_data> nb_states; // Number of states without initial state
	real z0; // Initial state
	int<lower = 1, upper = nb_states + 1> indices[nb_data + 1];
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

	// print(processError);

	target += normal_lpdf(Z[1] | alpha*z0, processError);
	// Forward algo
	for (i in 1:nb_states)
		target += normal_lpdf(Z[i + 1] | alpha*Z[i], processError);

	// print("1/--------------");
	// print("Z = ", num_elements(Z));
	// print("indices = ", num_elements(indices));
	// print("Y = ", num_elements(Y));
	// print("2/--------------");
	target += normal_lpdf(Y | Z[indices], observationError);
}