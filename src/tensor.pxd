# The signature of the static function allowing application of a fourth rank,
# isotropic tensor to a second rank, symmetric tensor.
ctypedef void (*isotropic4_apply_t)(double, double, double[:], double[:])

cdef class FourthRankIsotropicTensor:
    cdef int dim, sym
    cdef readonly double sph, dev
    cdef double tr
    cdef isotropic4_apply_t static_c_apply

    cdef inline void c_apply(self, double[:] x, double[:] y)