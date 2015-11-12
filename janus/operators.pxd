cdef class AbstractOperator:
    cdef readonly int isize
    """The size of the input (`int`, read-only)."""

    cdef readonly int osize
    """The size of the output (`int`, read-only)."""

    cdef void c_apply(self, double[:] x, double[:] y)


cdef class AbstractLinearOperator(AbstractOperator):
    cdef void c_to_memoryview(self, double[:, :] out)


cdef class LinearOperator(AbstractLinearOperator):
    cdef double[:, :] a

    cdef void c_apply_transpose(self, double[:] x, double[:] y)

cdef class FourthRankIsotropicTensor(AbstractLinearOperator):
    cdef readonly int dim
    """The dimension of the physical space (`int`, read-only)."""

    cdef readonly double sph
    """The spherical projection of the tensor (`float`, read-only)."""

    cdef readonly double dev
    """The deviatoric projection of the tensor (`float`, read-only)."""

    cdef double tr


cdef class FourthRankIsotropicTensor2D(FourthRankIsotropicTensor):
    pass


cdef class FourthRankIsotropicTensor3D(FourthRankIsotropicTensor):
    pass

cdef class FourthRankCubicTensor2D(AbstractLinearOperator):
    cdef readonly int dim
    """The dimension of the physical space (`int`, read-only)."""

    cdef readonly double t11
    """The (1, 1) coefficient of the Mandel-Voigt matrix representation."""

    cdef readonly double t12
    """The (1, 2) coefficient of the Mandel-Voigt matrix representation."""

    cdef readonly double t13
    """The (1, 3) coefficient of the Mandel-Voigt matrix representation."""

    cdef readonly double t23
    """The (2, 3) coefficient of the Mandel-Voigt matrix representation."""

    cdef readonly double t33
    """The (3, 3) coefficient of the Mandel-Voigt matrix representation."""

cdef class AbstractStructuredOperator2D:
    cdef readonly int dim
    """The dimension of the structured grid (`int`, 2)."""

    cdef readonly int shape0
    """The first dimension of the input and output (`int`)."""

    cdef readonly int shape1
    """The second dimension of the input and output (`int`)."""

    cdef readonly int ishape2
    """The third dimension of the input (`int`)."""

    cdef readonly int oshape2
    """The third dimension of the output (`int`)."""

    cdef readonly tuple ishape
    """The shape of the input (tuple)."""

    cdef readonly tuple oshape
    """The shape of the output (tuple)."""

    cdef void c_apply(self, double[:, :, :] x, double[:, :, :] y)


cdef class AbstractStructuredOperator3D:
    cdef readonly int dim
    """The dimension of the structured grid (`int`, 3)."""

    cdef readonly int shape0
    """The first dimension of the input and output (`int`)."""

    cdef readonly int shape1
    """The second dimension of the input and output (`int`)."""

    cdef readonly int shape2
    """The third dimension of the input and output (`int`)."""

    cdef readonly int ishape3
    """The fourth dimension of the input (`int`)."""

    cdef readonly int oshape3
    """The fourth dimension of the output (`int`)."""

    cdef readonly tuple ishape
    """The shape of the input (tuple)."""

    cdef readonly tuple oshape
    """The shape of the output (tuple)."""

    cdef void c_apply(self, double[:, :, :, :] x, double[:, :, :, :] y)


cdef class BlockDiagonalOperator2D(AbstractStructuredOperator2D):
    cdef AbstractOperator[:, :] loc


cdef class BlockDiagonalOperator3D(AbstractStructuredOperator3D):
    cdef AbstractOperator[:, :, :] loc


cdef class BlockDiagonalLinearOperator2D(AbstractStructuredOperator2D):
    cdef double[:, :, :, :] a

    cdef void c_apply_transpose(self, double[:, :, :] x, double[:, :, :] y)


cdef class BlockDiagonalLinearOperator3D(AbstractStructuredOperator3D):
    cdef double[:, :, :, :, :] a

    cdef void c_apply_transpose(self, double[:, :, :, :] x,
                                double[:, :, :, :] y)
