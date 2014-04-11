elastisys:scale cloud adapter REST API documentation
====================================================

This documentation covers the REST API that all 
`elastisys:scale <http://elastisys.com/scale>`_ cloud adapters 
are required to publish. 

A *cloud adapter* is a key component in an 
`elastisys:scale <http://elastisys.com/scale>`_ autoscaling setup. 

An elastisys:scale autoscaling system consists of two main parts: (1) 
an elastisys:scale autoscaler server and (2) a cloud adapter. The autoscaler
server collects monitoring data reported by the application from a monitoring 
database and applies scaling algorithms to, ultimately, emit a number of required 
VM instances to keep the auto-scaling-enabled service running smoothly. This
number is communicated over a secured (SSL) channel to the cloud adapter, 
which instructs the cloud infrastructure to add or remove VMs, as appropriate.
A schematical overview of the system is shown in the image below.

.. image:: images/autoscaler_components.png
  :width: 700px

So the main purpose of a cloud adapter is to handle communication with the 
targeted cloud provider, essentially translating the machine pool resize 
instructions suggested by the autoscaler to the particular protocol/API 
offered by the cloud provider. More specifically, a cloud adapter 
performs two primary tasks:

  * It answers requests about the members of the autoscaled machine pool.

  * It carries out machine pool resize requests suggested by the autoscaler
    by commissioning/decommissioning machine instances so that the number of
    *active* machines in the pool matches the desired pool size.

The interface between the autoscaler and the cloud adapter is a REST API.
All cloud adapters are required to implement this REST API and make it 
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

