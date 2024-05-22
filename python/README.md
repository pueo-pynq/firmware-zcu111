# Python files for ZCU111 MTS base project

Bitstream gets loaded by

```
>>> from zcumts import zcuMTS
>>> dev = zcuMTS()
>>> from zcumts import zcuMTS
[{'spi_device': PosixPath('/dev/spidev1.1'), 'compatible': 'lmk04208', 'num_bytes': 4}]
Turning on SYNC
Turning off SYNC
>>>
```

Note that the internal WISHBONE bus is actually accessed
via the serial port, so you need to add:

```
>>> sdv = SerialCOBSDevice('/dev/ttyPS1', 1000000)
```

and then internal WISHBONE registers can be accessed
via ``sdv.read`` and ``sdv.write``.
