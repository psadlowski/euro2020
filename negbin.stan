//
// This Stan program defines a simple model, with a
// vector of values 'y' modeled as normally distributed
// with mean 'mu' and standard deviation 'sigma'.
//
// Learn more about model development with Stan at:
//
//    http://mc-stan.org/users/interfaces/rstan.html
//    https://github.com/stan-dev/rstan/wiki/RStan-Getting-Started
//

// The input data is a vector 'y' of length 'N'.
data {
  int<lower=0> N;
  matrix[N,3] X;
  int<lower=0> y[N];
}

// The parameters accepted by the model. Our model
// accepts two parameters 'mu' and 'sigma'.
parameters {
  vector[3] beta_k;
  vector[3] beta_theta;
}

transformed parameters {
  vector<lower=0>[N] k;
  vector<lower=0>[N] theta;
  k = exp(X * beta_k);
  theta = exp(X * beta_theta);
}

// The model to be estimated. We model the output
// 'y' to be normally distributed with mean 'mu'
// and standard deviation 'sigma'.
model {
  beta_k ~ normal(0, 1);
  beta_theta ~ normal(0, 1);
  y ~ neg_binomial(k, theta);
}

