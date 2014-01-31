.. elastisys:scale cloud adapter REST API documentation master file, created by
   sphinx-quickstart on Thu Jan 30 14:51:57 2014.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

elastisys:scale cloud adapter REST API
======================================

All `elastisys:scale <http://elastisys.com/scale>`_ cloud adapters 
are required to publish the REST API described below. 

The REST API should be made available over secure HTTP (HTTPS) and all
API methods are assumed to be synchronous. That is, when they return to the 
caller, their actions have completed (taken effect).


Operations
----------

``GET /pool``
*************

  - Description: retrieves the current machine pool members

  - Input: None

  - Output: 

    - On success: HTTP response code 200 with a :ref:`machine_pool_message`

    - On error: HTTP response code 500 with an :ref:`error_response_message`

``POST /pool``
**************

  - Description: requests a resize of the machine pool
  
  - Input: The desired number of machine instances in the pool as a machine pool :ref:`resize_request_message`.

  - Output:
  
    - On success: HTTP response code 200 without message content.
  
    - On error: 
      
      - on illegal input: code 400 with an :ref:`error_response_message`
    
      - otherwise: HTTP response code 500 with an :ref:`error_response_message`


Messages
--------

.. _resize_request_message:

Resize request message
**********************

+--------------+----------------------------------------------------+
| Description  | a message used to request that the machine pool be |
|              | resized to a desired number of machine instances.  |
+--------------+----------------------------------------------------+
| Content type |  ``application/json``                              |
+--------------+----------------------------------------------------+
| Schema       | ``{ "desiredCapacity": <number> }``                |
+--------------+----------------------------------------------------+

Sample document: ::

     { "desiredCapacity": 3 }


.. _error_response_message:

Error response message
**********************

+--------------+----------------------------------------------------+
| Description  | contains further details (in addition to the       |
|              | response code) on server-side errors.provider).    |
+--------------+----------------------------------------------------+
| Content type |  ``application/json``                              |
+--------------+----------------------------------------------------+
| Schema       | ``{ "message": <string>, "detail": <string> }``    |
+--------------+----------------------------------------------------+

The ``message`` is a human-readable error message intended for presentation, 
whereas the ``detail`` attribute holds error details (such as a stack trace).

This is a sample error message: ::

  {
    "message": "failure to process pool get request",
    "detail": "... long stacktrace ..."
  }



.. _machine_pool_message:

Machine pool message
********************

+--------------+----------------------------------------------------+
| Description  | Describes the current status of the monitored      |
|              | machine pool.                                      |
+--------------+----------------------------------------------------+
| Content type |  ``application/json``                              |
+--------------+----------------------------------------------------+

The machine pool schema has the following structure: ::

   {
     "timestamp": <iso-8601 datetime>,
     "machines": [ <machine> ... ]
   }

Here, every ``<machine>`` is also a json document with the following structure: ::

  {
    "id": <string>,
    "state": <state>,
    "launchtime": <iso-8601 datetime>,
    "metadata": <jsonobject>
  } 

Here, ``launchtime`` may be ``null`` and ``metadata`` is an arbitrary JSON object.
The ``<state>`` is a string that may take on any of the following values:

+-------------+---------------------------------------------------------------------+
| State       | Description                                                         |
+=============+=====================================================================+
| REQUESTED   | Machine has been requested from the underlying infrastructure and   |
|             |	the request is pending fulfillment.                                 |
+-------------+---------------------------------------------------------------------+
| REJECTED    | Machine request was rejected by the underlying infrastructure.      |
+-------------+---------------------------------------------------------------------+
| PENDING     | Machine is in the process of being launched.                        |
+-------------+---------------------------------------------------------------------+
| RUNNING     | Machine is launched (boot process may not be completed).            |
+-------------+---------------------------------------------------------------------+
| OPERATIONAL | Machine is launched and reports itself as being operational.        |
+-------------+---------------------------------------------------------------------+
| TERMINATING | Machine is shutting down.                                           |
+-------------+---------------------------------------------------------------------+
| TERMINATED  | Machine is terminated.                                              |
+-------------+---------------------------------------------------------------------+
| STOPPING    | Machine is stopping.                                                |
+-------------+---------------------------------------------------------------------+
| STOPPED     | Machine is stopped.                                                 |
+-------------+---------------------------------------------------------------------+

Below is a sample machine pool document: ::


  {
    "timestamp": "2013-11-07T13:50:00Z",
    "machines": [
      {
        "id": "i-123456",
        "state": "PENDING",
        "launchtime": "2013-11-07T13:50:00.000Z",        
        "metadata": {
          "scaling-group": "mygroup"
        }
      },
      {
        "id": "i-123457",
        "state": "RUNNING",
        "launchtime": "2013-11-07T11:45:00.000Z",        
        "metadata": {
          "scaling-group": "mygroup",
          "primary": "true"
        }
      }
    ]
  }


