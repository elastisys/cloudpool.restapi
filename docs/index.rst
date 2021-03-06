elastisys:scale cloud pool REST API documentation (version 5.0.0)
===============================================================

This documentation covers version 5.0.0 of the REST API that all 
`elastisys:scale <http://elastisys.com/scale>`_ cloud pool endpoints
are required to publish. 

A *cloud pool* is a key component in an 
`elastisys:scale <http://elastisys.com/scale>`_ autoscaling setup. 

An elastisys:scale autoscaling system consists of two main parts: (1) 
an *autoscaler server* and (2) a *cloud pool*. The autoscaler
server collects monitoring data reported by the application from a monitoring 
database and applies scaling algorithms to, ultimately, emit a number of required 
VM instances to keep the auto-scaling-enabled service running smoothly. This
number is communicated over a secured (SSL) channel to the cloud pool, 
which instructs the cloud infrastructure to add or remove VMs, as appropriate.
A schematical overview of the system is shown in the image below.

.. image:: images/autoscaler_components_2.0.png
  :width: 700px


So a cloud pool manages an elastic pool of machines for a particular cloud
provider, handling communication with the cloud provider according to its
API. The cloud pool provides a cloud-neutral API to clients, such as the
autoscaler, with a number of management primitives for the machine pool. In 
general terms, these primitives allow clients to:

 * track the machine pool members and their states
 * modify the size of the machine pool (the cloud pool continuously 
   starts/stops machine instances so that the number of machines in 
   the pool matches the desired size set for the pool).

The interface between the autoscaler and the cloud pool is a REST API.
All cloud pool endpoints are required to implement this REST API and make it 
available over secure HTTP (HTTPS). The REST API is described in greater 
detail in the :doc:`api`.




Documentation:

.. toctree::
   :maxdepth: 4

   api



.. Indices and tables
.. ==================

.. * :ref:`genindex`
.. * :ref:`modindex`
.. * :ref:`search`

