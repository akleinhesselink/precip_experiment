// NULL model for growth 
data{
  int<lower=0> N; // observations
  int<lower=0> npreds;
  int<lower=0> Yrs; // years
  int<lower=0> yid[N]; // year id
  int<lower=0> G; // groups
  int<lower=0> gid[N]; // group id
  int<lower=0> gid_out[npreds]; // group id holdout
  vector[N] Y; // observation vector
  vector[npreds] y_holdout;
  vector[N] X; // size vector
  vector[npreds] Xhold;
}
parameters{
  real a_mu;
  vector[Yrs] a;
  real b1_mu;
  vector[Yrs] b1;
  real gint[G];
  real tau;
  real tauSize;
  real<lower=0> sig_a;
  real<lower=0> sig_b1;
  real<lower=0> sig_G;
}
transformed parameters{
  vector[N] mu;
  real<lower=0> sigma[N];
  for(n in 1:N){
    mu[n] <- a[yid[n]] + gint[gid[n]] + b1[yid[n]]*X[n];
    sigma[n] <- sqrt((fmax(tau*exp(tauSize*mu[n]), 0.0000001)));  
  }
}
model{
  // Priors
  a_mu ~ normal(0,100);
  b1_mu ~ normal(0,100);
  tau ~ normal(0,100);
  tauSize ~ normal(0,100);
  sig_a ~ cauchy(0,2);
  sig_b1 ~ cauchy(0,2);
  sig_G ~ cauchy(0,2);
  for(g in 1:G)
    gint[g] ~ normal(0, sig_G);
  for(y in 1:Yrs){
    a[y] ~ normal(a_mu, sig_a);
    b1[y] ~ normal(b1_mu, sig_b1);
  }

  // Likelihood
  Y ~ normal(mu, sigma);
}
generated quantities {

  // Section for calculating log_lik of fitted data 
  
  vector[N] log_lik; 
  
  for(n in 1:N){
    log_lik[n] <- normal_log(Y[n], mu[n] , sigma[n]); 
  }
  
}

