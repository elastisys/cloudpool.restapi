cloudpool.restapi
=================

This project hosts the documentation for the 
[elastisys](http://elastisys.com) cloud pool
REST API.

The HTML rendering of the documentation can be built as follows:

  1. Create and activate a new virtual environment to create an 
     isolated development environment (that contains the required 
     dependencies and nothing else):

       `make virtualenv`

       `. virtualenv.restapi/bin/activate`

  2. Install the required dependencies in this virtual environment:

       `make init`

  3. Build the documentation:

       `make docs`

After building, the documentation is available under the `docs/_build` directory.

Online documentation
====================
The latest documentation can also be found online at http://cloudpoolrestapi.readthedocs.org/en/latest.
