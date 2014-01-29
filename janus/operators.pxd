cdef class Operator:
    # TODO rename
    #   - ncols -> isize
    #   - nrows -> osize
    cdef readonly int nrows, ncols

    cdef void c_apply(self, double[:] x, double[:] y)


cdef class AbstractStructuredOperator2D:
    cdef readonly int ishape0, ishape1, ishape2
    cdef readonly int oshape0, oshape1, oshape2
    cdef readonly tuple ishape, oshape

    cdef void c_apply(self, double[:, :, :] x, double[:, :, :] y)


cdef class BlockDiagonalOperator2D(AbstractStructuredOperator2D):
    cdef Operator[:, :] a_loc


cdef class FourthRankIsotropicTensor(Operator):
    cdef readonly int dim
    cdef readonly double sph, dev
    cdef double tr


cdef class FourthRankIsotropicTensor2D(FourthRankIsotropicTensor):
    pass


cdef class FourthRankIsotropicTensor3D(FourthRankIsotropicTensor):
    pass