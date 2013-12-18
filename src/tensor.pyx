from cython cimport boundscheck
from cython cimport cdivision
from cython cimport wraparound

from checkarray cimport check_shape_1d
from checkarray cimport create_or_check_shape_1d

"""This module defines fourth rank, isotropic tensor, which are
classically decomposed as the sum of a spherical and a deviatoric part

where

"""

def isotropic4(sph, dev, dim):
    """Create a fourth rank, isotropic tensor.

    Parameters
    ----------
    sph: float
        The spherical projection of the returned tensor.
    dev: float
        The deviatoric projection of the returned tensor.
    dim: int
        The dimension of the physical space on which the returned tensor
        operates.
    """
    return FourthRankIsotropicTensor(sph, dev, dim)

@boundscheck(False)
@wraparound(False)
cdef inline void c_apply_2D(double tr_coeff, double dev,
                            double[:] x, double[:] y):
    cdef double aux = tr_coeff * (x[0] + x[1])
    y[0] = aux + dev * x[0]
    y[1] = aux + dev * x[1]
    y[2] = dev * x[2]

@boundscheck(False)
@wraparound(False)
cdef inline void c_apply_3D(double tr_coeff, double dev,
                            double[:] x, double[:] y):
    cdef double aux = tr_coeff * (x[0] + x[1] + x[2])
    y[0] = aux + dev * x[0]
    y[1] = aux + dev * x[1]
    y[2] = aux + dev * x[2]
    y[3] = dev * x[3]
    y[4] = dev * x[4]
    y[5] = dev * x[5]

cdef class FourthRankIsotropicTensor:
    @cdivision(True)
    def __cinit__(self, double sph, double dev, int dim):
        self.dim = dim
        self.sym = (self.dim * (self.dim + 1)) / 2
        self.sph = sph
        self.dev = dev
        self.tr = (sph - dev) / <double> self.dim
        if dim == 2:
            self.static_c_apply = c_apply_2D
        elif dim == 3:
            self.static_c_apply = c_apply_3D
        else:
            raise ValueError('dim must be 2 or 3 (was {0})'.format(dim))

    def __repr__(self):
        return ('FourthRankIsotropicTensor(sph={0}, dev={1}, dim={2})'
                .format(self.sph, self.dev, self.dim))

    cdef inline void c_apply(self, double[:] x, double[:] y):
        self.static_c_apply(self.tr, self.dev, x, y)

    def apply(self, double[:] x, double[:] y=None):
        check_shape_1d(x, self.sym)
        y = create_or_check_shape_1d(y, self.sym)
        self.c_apply(x, y)
        return y
