import pandas as pd

from respy.python.shared.shared_auxiliary import replace_missing_values
from respy.python.shared.shared_auxiliary import dist_class_attributes
from respy.python.simulate.simulate_auxiliary import write_info
from respy.python.simulate.simulate_auxiliary import write_out
from respy.python.shared.shared_auxiliary import check_dataset
from respy.fortran.interface import resfort_interface
from respy.python.interface import respy_interface


def simulate(respy_obj):
    """ Simulate dataset of synthetic agent following the model specified in
    the initialization file.
    """
    # Distribute class attributes
    is_debug, version, num_agents_sim, seed_sim, store = \
        dist_class_attributes(respy_obj, 'is_debug', 'version',
                'num_agents_sim', 'seed_sim', 'is_store')

    # Select appropriate interface
    if version in ['PYTHON']:
        _, data_array = respy_interface(respy_obj, 'simulate')
    elif version in ['FORTRAN']:
        _, data_array = resfort_interface(respy_obj, 'simulate')
    else:
        raise NotImplementedError

    # Create pandas data frame with missing values.
    data_frame = pd.DataFrame(replace_missing_values(data_array))

    # Wrapping up by running some checks on the dataset and then writing out
    # the file and some basic information.
    if is_debug:
        check_dataset(data_frame, respy_obj, 'sim')

    write_out(respy_obj, data_frame)

    write_info(respy_obj, data_frame)

    # Finishing
    return respy_obj


