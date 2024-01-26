import os
import time
import glob
import re
import struct
from pathlib import Path
from collections import defaultdict

# The internal functions are cribbed from Pynq's xrfclk.
# This should get reworked to create a class.

lmk_devices = []
lmx_devices = []

def _spidev_bind(dev):
    (dev / 'driver_override').write_text('spidev')
    Path('/sys/bus/spi/drivers/spidev/bind').write_text(dev.name)

def _get_spidev_path(dev):
    spidev = list(dev.glob('spidev/*'))[0]
    return Path('/dev') / spidev.name
    
def _write_LMK_regs(reg_vals, lmk):

    """Write values to the LMK registers.

    This is an internal function.

    Parameters
    ----------
    reg_vals: list
        A list of 32-bit register values (LMK clock dependant number of values).
        LMK04208 (ZCU111) = 32 registers, num_bytes = 4
        LMK04832 (RFSoC2x2) = 125 registers, num_bytes = 3
    lmk: dictionary
        An instance of lmk_devices
        
    This function opens spi_device at /dev/spidevB.C and writes the register values stored in reg_vals.
    Number of bytes written is board dependant. 

    """   
    with open(lmk['spi_device'], 'rb+', buffering=0) as f:
        for v in reg_vals:
            data = struct.pack('>I', v)
            if lmk['num_bytes'] == 3:
                f.write(data[1:])
            else:
                f.write(data)

def _program_LMX(reg_vals, lmx):
    """Program an LMX. This adds the reset and final register 0 write.
    """
    reset_regs = [ 0x000002, 0x0 ]
    # reset
    _write_LMX_regs(reset_regs, lmx)
    # write registers
    _write_LMX_regs(reg_vals, lmx)
    # sleep 10 ms
    time.sleep(0.01)
    # write R0 a second time
    _write_LMX_regs([ reg_vals[112] ], lmx)
                
def _write_LMX_regs(reg_vals, lmx):
    """Write values to the LMX registers.

    This is an internal function. This does NOT do any
    of the full programming features like is done in xrfclk.
    Those are done in _program_LMX. This lets you use
    it to write arbitrary registers.

    Parameters
    ----------
    reg_vals: list
        A list of values to write (as 32-bit ints, just like register files)
        
    lmx: dictionary
        An instance of lmx_devices
        
    This function opens spi_device at /dev/spidevB.C and writes the register values stored in reg_vals.
    LMX must be reset before writing new values.
    """
    
    with open(lmx['spi_device'], 'rb+', buffering=0) as f:
        for v in reg_vals:
            data = struct.pack('>I', v)
            f.write(data[1:])
                
def _find_devices():
    """
    Internal function to find lmk and lmx devices from the device tree and populate /dev/spidevB.C
    
    Also fills global variables lmk_devices and lmx_devices.
    """
    global lmk_devices, lmx_devices
    
    # loop for each SPI device on the device tree
    for dev in Path('/sys/bus/spi/devices').glob('*'):
        # read the compatible string from the device tree, containing name of chip, e.g. 'ti,lmx2594'
        # strip the company name to store e.g. 'lmx2594'
        compatible = (dev / 'of_node' / 'compatible').read_text()[3:-1]
        
        # if not lmk/lmx, either non-clock SPI device or compatible is empty
        if compatible[:3] != 'lmk' and compatible[:3] != 'lmx':
            continue
        else:
            # call spidev_bind to bind /dev/spidevB.C
            if (dev / 'driver').exists():
                (dev / 'driver' / 'unbind').write_text(dev.name)
            _spidev_bind(dev)
            
            # sort devices into lmk_devices or lmx_devices
            if compatible[:3] == 'lmk':
                lmk_dict = {'spi_device' : _get_spidev_path(dev), 
                            'compatible' : compatible, 
                            'num_bytes' : struct.unpack('>I', (dev / 'of_node' / 'num_bytes').read_bytes())[0]}
                lmk_devices.append(lmk_dict)
            else:
                lmx_dict = {'spi_device' : _get_spidev_path(dev), 
                            'compatible' : compatible}
                lmx_devices.append(lmx_dict)
                
    if lmk_devices == []:
        raise RuntimeError("SPI path not set. LMK not found on device tree. Issue with BSP.")
    if lmx_devices == []:
        raise RuntimeError("SPI path not set. LMX not found on device tree. Issue with BSP.")

def _parse_tics(fn):
    """Parse the values from the TICS output given the filename.

    The Pynq `CHIPNAME_frequency.txt` idea is terrible
    because you have no idea what board it corresponds to,
    and the overall configuration isn't independent
    between the two.
        
    So we just take a filename and output the registers.

    """
    registers = []
    with open(fn, 'r') as f:
        lines = [l.rstrip("\n") for l in f]
        
        registers = []
        for i in lines:
            m = re.search('[\t]*(0x[0-9A-F]*)', i)
            registers.append(int(m.group(1), 16),)

    return registers

def lmx_sync():
    if lmk_devices == [] and lmx_devices == []:
        _find_devices()

    # SYNC on the ZCU111 is LMK.CLKOUT3, which is controlled
    # by R3 in the LMK. The powerdown bit is the top one.
    sync_regs =   [ 0x00148003 ]
    nosync_regs = [ 0x80148003 ]
    
    print("Turning on SYNC")
    for lmk in lmk_devices:
        _write_LMK_regs(sync_regs, lmk)
    print("Turning off SYNC")
    for lmk in lmk_devices:
        _write_LMX_regs(nosync_regs, lmk)
        
def set_rf_clks(lmkfn='ZCU111_LMK_24.txt',
                lmxfn='ZCU111_LMX.txt',
                sync=True):
    if lmk_devices == [] and lmx_devices == []:
        _find_devices()

    # configure them as in TICS files.
    # Note that SYNC should be OFF.
    lmk_regs = _parse_tics(lmkfn)
    for lmk in lmk_devices:
        _write_LMK_regs(lmk_regs, lmk)
    lmx_regs = _parse_tics(lmxfn)
    for lmx in lmx_devices:
        _program_LMX(lmx_regs, lmx)
    if sync:
        lmx_sync()
    
