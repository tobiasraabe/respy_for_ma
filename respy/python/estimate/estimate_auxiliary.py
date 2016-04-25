""" This module contains auxiliary functions for the estimation.
"""
# standard library
import numpy as np
import scipy

# project library
from respy.python.shared.shared_auxiliary import check_model_parameters
from respy.python.shared.shared_auxiliary import check_dataset

''' Auxiliary functions
'''


def check_input(respy_obj, data_frame):
    """ Check input arguments.
    """
    # Check that class instance is locked.
    assert respy_obj.get_attr('is_locked')

    if respy_obj.get_attr('is_solved'):
        respy_obj.reset()

    # Check that dataset aligns with model specification.
    check_dataset(data_frame, respy_obj, 'est')

    # Finishing
    return True


def get_optim_paras(coeffs_a, coeffs_b, coeffs_edu, coeffs_home,
        shocks_cov, which, paras_fixed, is_debug):
    """ Get optimization parameters.
    """
    # Construct Cholesky decomposition
    if np.count_nonzero(shocks_cov) == 0:
        shocks_cholesky = np.zeros((4, 4))
    else:
        shocks_cholesky = np.linalg.cholesky(shocks_cov)

    # Checks
    if is_debug:
        args = (coeffs_a, coeffs_b, coeffs_edu, coeffs_home, shocks_cov,
                shocks_cholesky)
        assert check_model_parameters(*args)

    # Initialize container
    x = np.tile(np.nan, 26)

    # Occupation A
    x[0:6] = coeffs_a

    # Occupation B
    x[6:12] = coeffs_b

    # Education
    x[12:15] = coeffs_edu

    # Home
    x[15:16] = coeffs_home

    # Shocks
    x[16:17] = shocks_cholesky[0, :1]
    x[17:19] = shocks_cholesky[1, :2]
    x[19:22] = shocks_cholesky[2, :3]
    x[22:26] = shocks_cholesky[3, :4]

    # Checks
    if is_debug:
        check_optimization_parameters(x)

    # Select subset
    if which == 'free':
        x_free_curre = []
        for i in range(16):
            if not paras_fixed[i]:
                x_free_curre += [x[i]]

        # Special treatment fo SHOCKS_COV
        if not paras_fixed[16]:
            x_free_curre[16:17] = shocks_cholesky[0, :1]
            x_free_curre[17:19] = shocks_cholesky[1, :2]
            x_free_curre[19:22] = shocks_cholesky[2, :3]
            x_free_curre[22:26] = shocks_cholesky[3, :4]

        x = np.array(x_free_curre)

    # Finishing
    return x


def dist_optim_paras(x_all_curre, is_debug):
    """ Update parameter values. The np.array type is maintained.
    """
    # Checks
    if is_debug:
        check_optimization_parameters(x_all_curre)

    # Occupation A
    coeffs_a = x_all_curre[0:6]

    # Occupation B
    coeffs_b = x_all_curre[6:12]

    # Education
    coeffs_edu = x_all_curre[12:15]

    # Home
    coeffs_home = x_all_curre[15:16]

    # Cholesky
    shocks_cholesky = np.tile(0.0, (4, 4))
    shocks_cholesky[0, :1] = x_all_curre[16:17]
    shocks_cholesky[1, :2] = x_all_curre[17:19]
    shocks_cholesky[2, :3] = x_all_curre[19:22]
    shocks_cholesky[3, :4] = x_all_curre[22:26]

    # Shocks
    shocks_cov = np.matmul(shocks_cholesky, shocks_cholesky.T)

    # Checks
    if is_debug:
        args = (coeffs_a, coeffs_b, coeffs_edu, coeffs_home, shocks_cov,
               shocks_cholesky)
        assert check_model_parameters(*args)

    # Collect arguments
    args = (coeffs_a, coeffs_b, coeffs_edu, coeffs_home, shocks_cov)

    # Finishing
    return args


def check_optimization_parameters(x):
    """ Check optimization parameters.
    """
    # Perform checks
    assert (isinstance(x, np.ndarray))
    assert (x.dtype == np.float)
    assert (x.shape == (26,))
    assert (np.all(np.isfinite(x)))

    # Finishing
    return True
