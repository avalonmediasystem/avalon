import React from 'react';

const LoadingSpinner = ({ isLoading }) =>
  isLoading ? <div className="loading-spinner" /> : null;

export default LoadingSpinner;
