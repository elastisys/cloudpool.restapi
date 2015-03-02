.. elastisys:scale cloud adapter REST API documentation master file, created by
   sphinx-quickstart on Thu Jan 30 14:51:57 2014.
   You can adapt this file completely to your liking, but it should at least
   contain the root `toctree` directive.

elastisys:scale cloud adapter REST API
======================================

All `elastisys:scale <http://elastisys.com/scale>`_ cloud adapters 
are required to publish the REST API described below. 

The primary purpose of the cloud adapter API is to serve as a bridge 
between an autoscaler and a certain cloud provider, allowing the autoscaler 
to operate in a cloud-neutral manner. As such, it focuses on primitives
for managing a dynamic collection of machines.


All API methods assume a ``Content-Type`` of ``application/json``.

The REST API should be made available over secure HTTP (HTTPS).



Terminology and machine state model
-----------------------------------
Cloud providers differ in how they refer to the computational
resources they provide. Some common terms are `instances`, `servers` and 
`VMs`/`virtual machines`.

The cloud adapter API strives to be as cloud-neutral as possible and 
simply refers to the computational resources being managed as **machines**. 
The logical group of machines that a cloud adapter manages is referred to
as its **machine pool**.


A cloud adapter needs to be able to report the execution state of its machine 
pool members in a cloud-neutral manner (see :ref:`get_machine_pool`). 
Since cloud providers differ quite a lot in the state models they use, the 
cloud adapter needs to map the cloud-native state of the machine to one of 
the **machine states** supported by the cloud adapter API. These states are 
described in the :ref:`machine state table <machine_state_table>` below.

.. _machine_state_table:

+-----------------+---------------------------------------------------------------------+
| Machine state   | Description                                                         |
+=================+=====================================================================+
| ``REQUESTED``   | The machine has been requested from the underlying infrastructure   |
|                 | and the request is pending fulfillment.                             |
+-----------------+---------------------------------------------------------------------+
| ``REJECTED``    | The machine request was rejected by the underlying infrastructure.  |
+-----------------+---------------------------------------------------------------------+
| ``PENDING``     | The machine is in the process of being launched.                    |
+-----------------+---------------------------------------------------------------------+
| ``RUNNING``     | The machine is launched. However, the boot process may not yet have |
|                 | completed and the machine may not be operational (the machine's     |
|                 | :ref:`service state <service_state_table>` may provide more         |
|                 | detailed state information).                                        |
+-----------------+---------------------------------------------------------------------+
| ``TERMINATING`` | The machine is in the process of being stopped/shut down.           |
+-----------------+---------------------------------------------------------------------+
| ``TERMINATED``  | The machine has been stopped/shut down.                             |
+-----------------+---------------------------------------------------------------------+

The diagram below illustrates the state transitions that describe the lifecycle of 
a machine.

.. image:: images/machinestates.png
  :width: 700px

The ``PENDING`` and ``RUNNING`` states are said to be the *active machine 
states*. Machines in an active state are executing. However, just because a machine 
is active doesn't necessarily mean that it is doing useful work. For example, it may
have failed to properly boot, it may have crashed or encountered a fatal bug.

There are cases where we need to be able to reason about the operational state of
the service running on the machine. For example, we may not want to register a running
machine to a load balancer until it is fully initialized and ready to accept requests.
To this end, a cloud adapter may include a :ref:`service state <service_state_table>` 
for a machine. Whereas the `machine state` should be viewed  as the execution 
state of the machine as reported by the cloud API, the **service state** of a machine
is the operational health of the service running on the machine.

A cloud adapter does not need to monitor the service state (health) of its machines,
although it could. However, a cloud adapter is required to be ready to receive 
service state updates (see :ref:`set_service_state`) for the machines in its pool 
and to include those states on subsequent queries about the pool members 
(:ref:`get_machine_pool`). A human operator or an external monitoring service should 
be able to set the service state for a certain machine. In case no service state
has been reported for a machine, the cloud adapter should report the machine as being
in a service state of ``UNKNOWN``.

The range of permissible service states are as follows:

.. _service_state_table:

+---------------------+---------------------------------------------------------------------+
| Service state       | Description                                                         |
+=====================+=====================================================================+
| ``BOOTING``         | The service is being bootstrapped and may not (yet) be operational. |
+---------------------+---------------------------------------------------------------------+
| ``IN_SERVICE``      | The service is operational and ready to accept work (health checks  |
|                     | pass).                                                              |
+---------------------+---------------------------------------------------------------------+
| ``UNHEALTHY``       | The service is not functioning properly (health checks fail).       |
+---------------------+---------------------------------------------------------------------+
| ``OUT_OF_SERVICE``  | The service is unhealthy and is in need of repair. It should be     |
|                     | considered out of service and not able to accept work until it      |
|                     | has recovered. When this service state is set for a machine, a      |  
|                     | replacement instance will be launched, as the machine is no         |
|                     | longer considered part of the active machine pool (even if it is    |
|                     | in machine state ``RUNNING``).                                      |
+---------------------+---------------------------------------------------------------------+
| ``UNKNOWN``         | The service state of the machine cannot be (or has not yet been)    |
|                     | determined.                                                         |
+---------------------+---------------------------------------------------------------------+

The ``OUT_OF_SERVICE`` state marks a machine pool member as being taken out of service
and awaiting troubleshooting. The cloud adapter should take measures to ensure that
a replacement machine is launched for any out-of-service machine.

Except for the ``OUT_OF_SERVICE`` state, service states are only informational 
"marker states" that, for example, can be used to monitor service health and
register machines with a load balancer as they become ``IN_SERVICE`` and unregister
them when in state ``UNHEALTHY`` or ``OUT_OF_SERVICE``.

At any time, the *effective size* of the machine pool should be interpreted as the
number of allocated machines that have not been marked out-of-service (awaiting 
troubleshooting/repair). That is, all machines in one of the machine states 
``REQUESTED``, ``PENDING``, or ``RUNNING`` and *not* being in service state 
``OUT_OF_SERVICE``.




Operations
----------


.. _get_machine_pool:

Get machine pool
****************
  
  - **Method**: ``GET /pool``
  - **Description**: Retrieves the current machine pool members.
    
    Note that the returned machines may be in any :ref:`machine state <machine_state_table>`
    (``REQUESTED``, ``RUNNING``, ``TERMINATED``, etc). The machines that are considered part of 
    the active pool are machines in machine states ``REQUESTED``, ``PENDING`` or
    ``RUNNING`` and that are *not* in service state ``OUT_OF_SERVICE``. The 
    :ref:`service state <service_state_table>` should be reported as ``UNKNOWN`` for machine instances that have 
    not had any service state reported (see :ref:`set_service_state`).
  - **Input**: None
  - **Output**: 
      - On success: HTTP response code 200 with a :ref:`machine_pool_message`
      - On error: HTTP response code 500 with an :ref:`error_response_message`



.. _get_pool_size:

Get pool size
*************

  - **Method**: ``GET /pool/size``
  - **Description**: Returns the current size of the machine pool -- both in terms of
    the desired size and the actual size (as these may differ at any time).
  - **Input**: None
  - **Output**: 
      - On success: HTTP response code 200 with a :ref:`pool_size_message`
      - On error: HTTP response code 500 with an :ref:`error_response_message`


.. _set_desired_size:

Set desired size
****************

  - **Method**: ``POST /pool/size``
  - **Description**: Sets the desired number of machines in the machine pool.
    This method is asynchronous and returns immediately after updating the
    desired size. There may be a delay before the changes take effect and
    are reflected in the machine pool.

    Note: the cloud adapter should take measures to ensure that requested 
    machines are recognized as pool members. The specific mechanism to mark 
    group members, which may depend on the features offered by the particular
    cloud API, is left to the implementation but could, for example, make use
    of tags.
  - **Input**: The desired number of machine instances in the pool as a :ref:`set_desired_size_message`.
  - **Output**:
      - On success: HTTP response code 200 without message content.
      - On error:    
          - on illegal input: code 400 with an :ref:`error_response_message`
          - otherwise: HTTP response code 500 with an :ref:`error_response_message`



.. _terminate_machine:

Terminate machine
*****************

  - **Method**: ``POST /pool/<machineId>/terminate``
  - **Description**: Terminates a particular machine pool member with id ``<machineId>``.
    The caller can control if a replacement machine is to be provisioned via the
    ``decrementDesiredSize``
    parameter. 
  - **Input**: A :ref:`terminate_machine_message`.
  - **Output**:
      - On success: HTTP response code 200 without message content.
      - On error:    
          - on illegal input: code 400 with an :ref:`error_response_message`
          - if the machine is not a pool member: code 404 with an :ref:`error_response_message`
          - otherwise: HTTP response code 500 with an :ref:`error_response_message`




.. _set_service_state:

Set service state
*****************

  - **Method**: ``POST /pool/<machineId>/serviceState``
  - **Description**:  Sets the service state of a machine pool member with
    id ``<machineId>``. Setting the service state has no side-effects, unless 
    the service state is set to ``OUT_OF_SERVICE``, in which case a replacement 
    machine will (eventually) be launched since out-of-service machines are not 
    considered effective members of the pool. An out-of-service machine can later 
    be taken back into service by another call to this method to re-set its service state.

    The specific mechanism to mark group 
    members, which may depend on the features offered by the particular cloud 
    API, is left to the implementation but could, for example, make use of tags.
  - **Input**: A :ref:`set_service_state_message`.
  - **Output**:
      - On success: HTTP response code 200 without message content.
      - On error:    
          - on illegal input: code 400 with an :ref:`error_response_message`
          - if the machine is not a pool member: code 404 with an :ref:`error_response_message`
          - otherwise: HTTP response code 500 with an :ref:`error_response_message`



.. _detach_machine:

Detach machine
**************

  - **Method**: ``POST /pool/<machineId>/detach``
  - **Description**: Removes a particular machine pool member with id ``<machineId>``
    from the pool without terminating it. 
    The machine keeps running but is no longer considered a pool member and,
    therefore, needs to be managed independently. The caller can control if 
    a replacement machine is to be provisioned via the ``decrementDesiredSize``
    parameter. 
  - **Input**: A :ref:`detach_machine_message`.
  - **Output**:
      - On success: HTTP response code 200 without message content.
      - On error:    
          - on illegal input: code 400 with an :ref:`error_response_message`
          - if the machine is not a pool member: code 404 with an :ref:`error_response_message`
          - otherwise: HTTP response code 500 with an :ref:`error_response_message`



.. _attach_machine:

Attach machine
**************


  - **Method**: ``POST /pool/<machineId>/attach``
  - **Description**: Attaches an already running machine with a given 
    ``<machineId>`` to the machine pool, growing the pool with a new member.
    This operation implies that the desired size of the group is incremented by one.
  - **Input**: None
  - **Output**:
      - On success: HTTP response code 200 without message content.
      - On error:    
          - on illegal input: code 400 with an :ref:`error_response_message`
          - if the machine does not exist: code 404 with an :ref:`error_response_message`
          - otherwise: HTTP response code 500 with an :ref:`error_response_message`




Messages
--------

.. _set_desired_size_message:

Set desired size message
************************

+--------------+-----------------------------------------------------------+
| Description  | A message used to request that the machine pool be        |
|              | resized to a desired number of machine instances.         |
+--------------+-----------------------------------------------------------+
| Schema       | ``{ "desiredSize": <number> }``                           |
+--------------+-----------------------------------------------------------+

Sample document: ::

     { "desiredSize": 3 }

States that we want three machine instances in the pool.

.. _error_response_message:

Error response message
**********************

+--------------+----------------------------------------------------+
| Description  | Contains further details (in addition to the HTTP  |
|              | response code) on server-side errors.              |
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

The machine pool schema has the following structure: ::

   {
     "timestamp": <iso-8601 datetime>,
     "machines": [ <machine> ... ]
   }

Here, every ``<machine>`` is also a json document with the following structure: ::

  {
    "id": <string>,
    "machineState": <machine state>,
    "serviceState": <service state>,
    "launchtime": <iso-8601 datetime>,
    "publicIps": [<ip-address>, ...],
    "privateIps": [<ip-address>, ...],
    "metadata": <jsonobject>
  } 

The attributes are to be interpreted as follows:
  
  * ``id``: The identifier of the machine.
  * ``machineState``: The execution state of the machine. See the 
    :ref:`machine state table <machine_state_table>` for the range of possible values.
  * ``serviceState``: The operational state of the service running on the machine.
    See the :ref:`service state table <service_state_table>` for the range of 
    possible values.
  * ``launchtime``: The launch time of the machine if it has been launched. If the machine
    is in a state where it hasn't been launched yet (``REQUESTED`` state) this attribute
    may be left out or set to ``null``.
  * ``publicIps``: The list of public IP addresses associated with this machine. Depending
    on the state of the machine, this list may be empty.
  * ``privateIps``: The list of private IP addresses associated with this machine. Depending
    on the state of the machine, this list may be empty.
  * ``metadata``: Additional cloud provider-specific meta data about the machine.
    This field is optional (may be ``null``).



Below is a sample machine pool document: ::

  {
    "timestamp": "2013-11-07T13:50:00.000Z",
    "machines": [
      {
        "id": "i-123456",
        "machineState": "RUNNING",
        "serviceState": "IN_SERVICE",
        "launchtime": "2013-11-07T14:50:00.000Z",
        "publicIps": ["54.211.230.169"],
        "privateIps": ["10.122.122.69"],
        "metadata": {
          "scaling-group": "mygroup"         
        }
      },
      {
        "id": "i-123457",
        "machineState": "PENDING",
        "serviceState": "BOOTING",
        "launchtime": "2013-11-07T13:49:50.000Z",        
        "publicIps": [],
        "privateIps": [],
        "metadata": {
          "scaling-group": "mygroup",
        }
      }
    ]
  }




.. _pool_size_message:

Pool size message
*****************

+--------------+---------------------------------------------------------------------------------------+
| Description  | Carries information about the pool size, both                                         |
|              | desired and actual size.                                                              |
+--------------+---------------------------------------------------------------------------------------+
| Schema       | ``{ "desiredSize": <number>, "allocated": <number>, "outOfService": <number> }``      |
+--------------+---------------------------------------------------------------------------------------+

The attributes are to be interpreted as follows:
  
  * ``desiredSize``: The last desired size set for the machine pool (see :ref:`set_desired_size`).
  * ``allocated``: The number of allocated machines in the pool (in one of 
    machine states ``REQUESTED``, ``PENDING``, ``RUNNING``)
  * ``outOfService``: The number of machines in the pool that are marked with 
    a ``OUT_OF_SERVICE`` service state.

Example: ::

   { "desiredSize": 3, "allocated": 4, "outOfService": 1 }



.. _terminate_machine_message:

Terminate machine message
*************************

+--------------+-----------------------------------------------------------------+
| Description  | Specifies if the desired size of the machine pool               |
|              | should be decremented after terminating the machine             |
|              | (that is, it controls if a replacement machine should           |
|              | be launched)                                                    |
+--------------+-----------------------------------------------------------------+
| Schema       | ``{ "decrementDesiredSize": <boolean> }``                       |
+--------------+-----------------------------------------------------------------+

The attributes are to be interpreted as follows:
  
  * ``decrementDesiredSize``: ``true`` if the desired pool size should 
    be decremented, ``false`` otherwise.

Example where a replacement machine is desired: ::

   { "decrementDesiredSize": false }



.. _detach_machine_message:

Detach machine message
**********************

+--------------+-----------------------------------------------------------------+
| Description  | Specifies if the desired size of the machine pool               |
|              | should be decremented after detaching the machine               |
|              | (that is, it controls if a replacement machine should           |
|              | be launched)                                                    |
+--------------+-----------------------------------------------------------------+
| Schema       | ``{ "decrementDesiredSize": <boolean> }``                       |
+--------------+-----------------------------------------------------------------+

The attributes are to be interpreted as follows:
  
  * ``decrementDesiredSize``: ``true`` if the desired pool size should 
    be decremented, ``false`` otherwise.

Example where a replacement machine is desired: ::

   { "decrementDesiredSize": false }



.. _set_service_state_message:

Set service state message
*************************

+--------------+-----------------------------------------------------------------+
| Description  | Specifies the service state to set for the machine.             |
+--------------+-----------------------------------------------------------------+
| Schema       | ``{ "serviceState": "<service state>" }``                       |
+--------------+-----------------------------------------------------------------+

The attributes are to be interpreted as follows:
  
  * ``serviceState``: The :ref:`service state <service_state_table>` to set.

Example where a replacement machine is desired: ::

   { "serviceState": "IN_SERVICE" }
