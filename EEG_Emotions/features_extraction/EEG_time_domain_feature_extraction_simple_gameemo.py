#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
## Version history:

2018:
    Original script by Dr. Luis Manso [lmanso], Aston University
    
2019, June:
    Revised, commented and updated by Dr. Felipe Campelo [fcampelo], Aston University
    (f.campelo@aston.ac.uk / fcampelo@gmail.com)
"""

# Commented since not used. [fcampelo]
# import sys
#from scipy.spatial.distance import euclidean

import numpy as np
import scipy
import scipy.signal

def matrix_from_csv_file(file_path):
    """
    Returns the data matrix given the path of a CSV file.
    
    Parameters:
        file_path (str): path for the CSV file with a time stamp in the first column
            and the signals in the subsequent ones.
            Time stamps are in seconds, with millisecond precision

    Returns:
        numpy.ndarray: 2D matrix containing the data read from the CSV
    
    Author: 
        Original: [lmanso] 
        Revision and documentation: [fcampelo]
    
    """
    
    csv_data = np.genfromtxt(file_path, delimiter = ',')

    full_matrix = csv_data[1:]

    headers = np.genfromtxt(file_path, delimiter = ',', dtype=str, max_rows=1)

    return full_matrix, headers


def get_time_slice(full_matrix, start = 0., period = 1.):
    """
    Returns a slice of the given matrix, where start is the offset and period is 
    used to specify the length of the signal.
    
    Parameters:
        full_matrix (numpy.ndarray): matrix returned by matrix_from_csv()
        start (float): start point (in seconds after the beginning of records) 
        period (float): duration of the slice to be extracted (in seconds)

    Returns:
        numpy.ndarray: 2D matrix with the desired slice of the matrix
        float: actual length of the resulting time slice
        
    Author:
        Original: [lmanso]
        Reimplemented: [fcampelo]
    """
    
    # Changed for greater efficiency [fcampelo]
    rstart  = full_matrix[0, 0] + start
    index_0 = np.max(np.where(full_matrix[:, 0] <= rstart))
    index_1 = np.max(np.where(full_matrix[:, 0] <= rstart + period))
    
    duration = full_matrix[index_1, 0] - full_matrix[index_0, 0]
    return full_matrix[index_0:index_1, :], duration



"""
Returns a number of feature vectors from a labeled CSV file, and a CSV header 
corresponding to the features generated.
full_file_path: The path of the file to be read
samples: size of the resampled vector
period: period of the time used to compute feature vectors
state: label for the feature vector
"""
def generate_feature_vectors_from_samples(file_path, nsamples, period, state): 
    # Read the matrix from file
    matrix, headers = matrix_from_csv_file(file_path)
    headers = np.append(headers,"Label")

    # get rid of the timestamp column
    headers = headers[1:]

    print("headers:")
    print(headers)
    
    # We will start at the very begining of the file
    t = 0.
    
    # No previous vector is available at the start
    previous_vector = None
    
    # Initialise empty return object
    ret = None
    
    # Until an exception is raised or a stop condition is met
    for i in range(matrix.shape[0]):
        row = matrix[i]

        feature_vector = np.hstack((row, state))

        # get rid of the timestamp column
        feature_vector = feature_vector[1:]
        
        if ret is None:
            ret = feature_vector
        else:
            ret = np.vstack([ret, feature_vector])

    # Return
    return ret, headers 



# ========================================================================
