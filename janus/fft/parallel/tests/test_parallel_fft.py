import numpy as np
import numpy.random
import pytest

import janus.fft.serial
import janus.fft.parallel

from mpi4py import MPI


@pytest.mark.parametrize('shape', [(31, 15),
                                   (31, 16),
                                   (32, 15),
                                   (32, 16)])
def test_r2c(shape):
    comm = MPI.COMM_WORLD
    root = 0
    rank = comm.rank

    janus.fft.parallel.init()
    pfft = janus.fft.parallel.create_real(shape, comm)

    # Root process gathers local n0 and offset
    local_sizes = comm.gather(sendobj=(pfft.rshape[0], pfft.offset0), root=root)

    # Root process creates global array, and scatters sub-arrays
    rglob = 2. * numpy.random.rand(*shape) - 1.
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
        sfft = janus.fft.serial.create_real(shape)
        actual = np.empty(sfft.cshape, dtype=np.float64)
        for cloc, (n0, offset0) in zip(clocs, local_sizes):
            actual[offset0:offset0 + n0] = cloc
        expected = sfft.r2c(rglob)
        norm = np.sqrt(np.sum((actual - expected)**2))
        assert norm == 0.
