import numpy as np
import numpy.random as nprnd

from mpi4py import MPI
from nose.tools import assert_equal
from nose.tools import nottest
from parallelfft import *
from serialfft import *

def create_serial_fft(shape):
    if len(shape) == 2:
        return SerialRealFFT2D(*shape)
    elif len(shape) == 3:
        return SerialRealFFT3D(*shape)
    else:
        raise ValueError()

def create_parallel_fft(shape):
    if len(shape) == 2:
        return ParallelRealFFT2D(*shape)
    elif len(shape) == 3:
        return SerialRealFFT3D(*shape)
    else:
        raise ValueError()

@nottest
def do_test_r2c(shape):
    comm = MPI.COMM_WORLD
    root = 0
    rank = comm.rank

    init()
    pfft = ParallelRealFFT2D(*shape)

    # Root process gathers local n0 and offset
    local_sizes = comm.gather(sendobj=(pfft.rshape[0], pfft.offset0), root=root)

    # Root process creates global array, and scatters sub-arrays
    rglob = 2. * nprnd.rand(*shape) - 1.
    if rank == root:
        rlocs = [rglob[offset0:offset0 + n0] for n0, offset0 in local_sizes]
    else:
        rlocs = None
    rloc = comm.scatter(sendobj=rlocs, root=root)
    cloc = np.empty(pfft.cshape, dtype=np.float64)
    pfft.r2c(rloc, cloc)

    # Root process gathers results
    clocs = comm.gather(sendobj=cloc, root=root)

    # Root process computes serial FFT
    if rank == root:
        fft = SerialRealFFT2D(*shape)
        actual = np.empty(fft.cshape, dtype=np.float64)
        for cloc, (n0, offset0) in zip(clocs, local_sizes):
            actual[offset0:offset0 + n0] = cloc
        expected = fft.r2c(rglob)
        norm = np.sqrt(np.sum((actual - expected)**2))
        assert_equal(norm, 0.)

def test_transform():
   shapes = [(31, 15), (31, 16), (32, 15), (32, 16)]
   for shape in shapes:
       yield do_test_r2c, shape
