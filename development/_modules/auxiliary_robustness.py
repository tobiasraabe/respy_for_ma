import numpy as np
import os
from os.path import join, exists
from shutil import rmtree, copy
from time import time
from respy.python.shared.shared_auxiliary import print_init_dict
from respy.tests.codes.random_init import VERSION_CONSTRAINTS
from codes.random_init import generate_init
from respy import RespyCls, estimate
from datetime import timedelta, datetime
import traceback
# import random_init
# import estimate


def run_robustness_test(seed, is_investigation):
    """Run a single robustness test."""
    passed = True
    error_message = None
    np.random.seed(seed)
    old_dir = os.getcwd()
    t = str(time())[-6:]
    if is_investigation is True:
        new_dir = join(old_dir, str(seed))
        if exists(new_dir):
            rmtree(new_dir)
        os.mkdir(new_dir)
    else:
        new_dir = join(old_dir, str(seed) + '_' + t)
        os.mkdir(new_dir)
    for file in ['career_data.respy.dat', 'career_data.respy.pkl']:
        copy(join(old_dir, file), join(new_dir, file))
    os.chdir(new_dir)

    # We need to impose some constraints so that the random initialization file does meet the
    # structure of the empirical dataset. We need to be particularly careful with the
    # construction of the maximum level of schooling as we need to rule out that anyone in the
    # estimation sample has a value larger then the specified maximum value.
    version = np.random.choice(['PYTHON', 'FORTRAN'])
    max_periods = VERSION_CONSTRAINTS['max_periods'][version]
    num_periods = np.random.randint(1, max_periods)

    edu_start = np.random.choice(range(7, 12))
    edu_max = np.random.randint(edu_start + num_periods, 30)

    constr = dict()
    constr['file_est'] = join(new_dir, 'career_data.respy.dat')
    constr['agents'] = np.random.randint(500, 1372 + 1)
    constr['edu'] = (edu_start, edu_max)
    constr['flag_estimation'] = True
    constr['periods'] = num_periods
    constr['version'] = version

    generate_init(constr)

    try:
        respy_obj = RespyCls('test.respy.ini')
        estimate(respy_obj)
    except:
        tb = traceback.format_exc()
        passed = False
        error_message = str(tb)

    os.chdir(old_dir)
    if is_investigation is False:
        rmtree(new_dir)
    return passed, error_message


def run_for_hours_sequential(hours, initial_seed):
    np.random.seed(initial_seed)
    failed_dict = {}
    start = datetime.now()
    counter = 0
    timeout = timedelta(hours=hours)
    while timeout >= (datetime.now() - start):
        counter += 1
        seed = np.random.randint(1, 100000)
        passed, error_message = run_robustness_test(seed, is_investigation=False)
        if passed is False:
            failed_dict[seed] = error_message
    return failed_dict, counter


def run_for_hours_parallel(hours, num_procs, initial_seeds):
    raise NotImplementedError
    #return []
