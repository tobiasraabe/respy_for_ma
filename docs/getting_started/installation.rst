Installation
============

The ``respy`` package can be conveniently installed from the `Python Package Index
<https://pypi.org/>`_ (PyPI) or directly from its source files. We currently support
only Python 3.6+. We develop the package mainly on Linux systems, but the test battery
ensures compatibility with Windows and MacOS.

Python Package Index
--------------------

You can install the stable version of the package the usual way.

.. code-block:: bash

    $ pip install respy

We provide a pure Python implementation as our baseline. However, to address performance
constraints, we also maintain scalar and parallel Fortran implementations. If additional
requirements are met, both are installed automatically.

... adding Fortran
^^^^^^^^^^^^^^^^^^

Linux
"""""

Please make sure that the ``gfortran`` compiler is available on your path and it knows
where to find the `Linear Algebra PACKage (LAPACK) <http://www.netlib.org/lapack/>`_
library.

On Ubuntu systems, both can be achieved by the following commands:

.. code-block:: bash

    $ sudo apt-get install gfortran
    $ sudo apt-get install libblas-dev liblapack-dev

Windows
"""""""

For Windows users, the installation is more complicated. Install the 32-bit or 64-bit
version of `MSYS2 <https://www.msys2.org/>`_. Start the MSYS2 MinGW terminal and type
the following command to update the package list and packages.

.. code-block:: bash

    $ pacman -Syu

After that, we install the gfortran compiler and lapack and blas. Choose the first
command if you installed the 64-bit version, the second otherwise.

.. code-block:: bash

    $ pacman -S mingw64/mingw-w64-x86_64-gcc-fortran /      # for 64-bit
                mingw64/mingw-w64-x86_64-lapack /
                mingw64/mingw-w64-x86_64-liblas

    $ pacman -S mingw64/mingw-w64-i686-gcc-fortran /        # for 32-bit
                mingw64/mingw-w64-i686-lapack /
                mingw64/mingw-w64-i686-liblas

At last, make sure that ``C:\msys64\mingw64\bin`` and ``C:\msys64\usr\bin`` is on your
``PATH``. Again, exchange 64 with 32 depending on your installer.

If so, just call a slightly modified version of the installation command.

.. code-block:: bash

   $ pip install --no-binary respy respy

The *--no-binary* flag is required for now to avoid the use of Python Wheels and ensure
a compilation of the Fortran source code during the build.

... adding Parallelism
^^^^^^^^^^^^^^^^^^^^^^

Linux
"""""

We use the `Message Passing Interface (MPI) <https://www.mpi-forum.org/>`_ library. This
requires a recent version of its `MPICH <https://www.mpich.org/>`_ implementation
available on your compiler's search path which was build with shared/dynamic libraries.
Install it with

.. code-block:: bash

    sudo apt-get install libmpich-dev

Windows
"""""""

Install the latest SDK and the Setup of `MSMPI
<https://github.com/Microsoft/Microsoft-MPI/releases>`_ and make sure that
``/Microsoft MPI/bin/`` is on the ``PATH``.


Source Files
------------

You can download the sources directly from our `GitHub repository
<https://github.com/OpenSourceEconomics/respy>`_.

.. code-block:: bash

   $ git clone https://github.com/OpenSourceEconomics/respy.git

Once you obtained a copy of the source files, installing the package in editable mode is
straightforward.

.. code-block:: bash

   $ pip install -e .

Test Suite
----------

Please make sure that the package is working properly by running our test suite using
``pytest``.

.. code-block:: bash

  $ python -c "import respy; respy.test()"
