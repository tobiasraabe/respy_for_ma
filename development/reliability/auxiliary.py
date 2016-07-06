from statsmodels.tools.eval_measures import rmse

import numpy as np

import socket
import shlex
import sys
import os

import respy

sys.path.insert(0, '../modules')
from clsMail import MailCls


def run(spec_dict, fname):
    """ Run a version of the Monte Carlo exercise.
    """
    dirname = fname.replace('.ini', '')
    os.mkdir(dirname), os.chdir(dirname)

    # Distribute details about specification
    optimizer_options = spec_dict['optimizer_options']
    optimizer_used = spec_dict['optimizer_used']
    num_draws_emax = spec_dict['num_draws_emax']
    num_draws_prob = spec_dict['num_draws_prob']
    num_agents = spec_dict['num_agents']
    scaling = spec_dict['scaling']
    maxfun = spec_dict['maxfun']

    # We first read in the first specification from the initial paper for our
    # baseline.
    respy_obj = respy.RespyCls('../' + fname)

    respy_obj.unlock()
    respy_obj.set_attr('file_est', '../correct/start/data.respy')
    respy_obj.set_attr('optimizer_options', optimizer_options)
    respy_obj.set_attr('optimizer_used', optimizer_used)
    respy_obj.set_attr('num_draws_emax', num_draws_emax)
    respy_obj.set_attr('num_draws_prob', num_draws_prob)
    respy_obj.set_attr('num_agents_est', num_agents)
    respy_obj.set_attr('num_agents_sim', num_agents)
    respy_obj.set_attr('scaling', scaling)
    respy_obj.set_attr('maxfun', maxfun)
    respy_obj.lock()

    # For debugging purposes
    if 'num_periods' in spec_dict.keys():
        respy_obj.unlock()
        respy_obj.set_attr('num_periods', spec_dict['num_periods'])
        respy_obj.lock()

    # Let us first simulate a baseline sample, store the results for future
    # reference, and start an estimation from the true values.
    os.mkdir('correct'), os.chdir('correct')
    respy_obj.write_out()

    simulate_specification(respy_obj, 'start', False)
    x, _ = respy.estimate(respy_obj)
    simulate_specification(respy_obj, 'stop', True, x)

    rmse_start, rmse_stop = get_rmse()

    os.chdir('../')

    record_results('Correct', rmse_start, rmse_stop)

    # Now we will estimate a misspecified model on this dataset assuming that
    # agents are myopic. This will serve as a form of well behaved starting
    # values for the real estimation to follow.
    respy_obj.unlock()
    respy_obj.set_attr('delta', 0.00)
    respy_obj.lock()

    os.mkdir('static'), os.chdir('static')
    respy_obj.write_out()

    simulate_specification(respy_obj, 'start', False)
    x, _ = respy.estimate(respy_obj)
    simulate_specification(respy_obj, 'stop', True, x)

    rmse_start, rmse_stop = get_rmse()

    os.chdir('../')

    record_results('Static', rmse_start, rmse_stop)

    # # Using the results from the misspecified model as starting values, we see
    # # whether we can obtain the initial values.
    respy_obj.unlock()
    respy_obj.set_attr('delta', 0.95)
    respy_obj.lock()

    os.mkdir('dynamic'), os.chdir('dynamic')
    respy_obj.write_out()

    simulate_specification(respy_obj, 'start', False)
    x, _ = respy.estimate(respy_obj)
    simulate_specification(respy_obj, 'stop', True, x)

    rmse_start, rmse_stop = get_rmse()

    os.chdir('../')

    record_results('Dynamic', rmse_start, rmse_stop)

    os.chdir('../')


def send_notification():
    """ Finishing up a run of the testing battery.
    """
    # Auxiliary objects.
    hostname = socket.gethostname()
    subject = ' RESPY: Monte Carlo Exercise '
    message = ' The Monte Carlo exercise is completed on @' + hostname + '.'

    mail_obj = MailCls()
    mail_obj.set_attr('subject', subject)
    mail_obj.set_attr('message', message)
    mail_obj.lock()

    mail_obj.send()


def get_choice_probabilities(fname, is_flatten=True):
    """ Get the choice probabilities.
    """

    # Initialize container.
    stats = np.tile(np.nan, (0, 4))

    with open(fname) as in_file:

        for line in in_file.readlines():

            # Split line
            list_ = shlex.split(line)

            # Skip empty lines
            if not list_:
                continue

            # If OUTCOMES is reached, then we are done for good.
            if list_[0] == 'Outcomes':
                break

            # Any lines that do not have an integer as their first element
            # are not of interest.
            try:
                int(list_[0])
            except ValueError:
                continue

            # All lines that make it down here are relevant.
            stats = np.vstack((stats, [float(x) for x in list_[1:]]))

    # Return all statistics as a flattened array.
    if is_flatten:
        stats = stats.flatten()

    # Finishing
    return stats


def record_results(label, rmse_start, rmse_stop):

    with open('monte_carlo.respy.info', 'a') as out_file:
        # Setting up
        if label == 'Correct':
            out_file.write('\n RMSE\n\n')
            fmt = '{:>15} {:>15} {:>15}\n\n'
            out_file.write(fmt.format(*['Setup', 'Start', 'Stop']))
        fmt = '{:>15} {:15.10f} {:15.10f}\n'
        out_file.write(fmt.format(*[label, rmse_start, rmse_stop]))


def get_rmse():

    fname = '../correct/start/data.respy.info'
    probs_true = get_choice_probabilities(fname, is_flatten=True)

    fname = 'start/data.respy.info'
    probs_start = get_choice_probabilities(fname, is_flatten=True)

    fname = 'stop/data.respy.info'
    probs_stop = get_choice_probabilities(fname, is_flatten=True)

    rmse_stop = rmse(probs_stop, probs_true)
    rmse_start = rmse(probs_start, probs_true)

    return rmse_start, rmse_stop


def simulate_specification(respy_obj, subdir, update, paras=None):
    """ Simulate results to assess the estimation performance.
    """
    os.mkdir(subdir), os.chdir(subdir)

    if update:
        assert (paras is not None)
        respy_obj.update_model_paras(paras)

    respy_obj.write_out()
    respy.simulate(respy_obj)
    os.chdir('../')