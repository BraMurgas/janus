import numpy as np
import pytest

import janus.fft.serial
import janus.fft.parallel

from mpi4py import MPI


@pytest.mark.parametrize('shape', [(31, 15), (31, 16), (32, 15), (32, 16)])
def test_r2c(shape):
    comm = MPI.COMM_WORLD
    root = 0

    janus.fft.parallel.init()
    pfft = janus.fft.parallel.create_real(shape, comm)
    counts_and_displs = comm.gather(sendobj=(pfft.isize, pfft.idispl,
                                             pfft.osize, pfft.odispl),
                                    root=root)
    if comm.rank == root:
        np.random.seed(20150312)
        rglob = 2. * np.random.rand(*shape) - 1.
        icounts, idispls, ocounts, odispls = zip(*counts_and_displs)
    else:
        rglob = None
        icounts, idispls, ocounts, odispls = None, None, None, None
    rloc = np.empty(pfft.rshape, dtype=np.float64)
    comm.Scatterv([rglob, icounts, idispls, MPI.DOUBLE], rloc, root)
    cloc = np.empty(pfft.cshape, dtype=np.float64)
    pfft.r2c(rloc, cloc)
    if comm.rank == root:
        # TODO See Issue #7
        actual = np.empty((pfft.shape[0],) + pfft.cshape[1:],
                          dtype=np.float64)
    else:
        actual = None
    comm.Gatherv(cloc, [actual, ocounts, odispls, MPI.DOUBLE], root)

    if comm.rank == root:
        sfft = janus.fft.serial.create_real(shape)
        expected = sfft.r2c(rglob)
        norm = np.sqrt(np.sum((actual - expected)**2))
        assert norm == 0.
