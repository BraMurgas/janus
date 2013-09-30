from fftw cimport *

cimport cython
from cython.view cimport array

cdef int SIZEOF_DOUBLE = sizeof(double)
cdef int SIZEOF_COMPLEX = 2 * sizeof(double)
cdef str INVALID_SHAPE_LENGTH = 'length of shape must be {0} (was {1})'

cdef int padding(int n):
    if n % 2 == 0:
        return 2
    else:
        return 1

cdef class SerialFFT2D:
    cdef:
        double *buffer
        fftw_plan plan_r2c
        readonly tuple in_shape, out_shape
        int dim
        int padding
        int isize0, isize1, osize0, osize1

    @cython.boundscheck(False)
    def __cinit__(self, tuple size not None):
        self.dim = 2
        if len(size) != 2:
            raise ValueError(INVALID_SHAPE_LENGTH.format(self.dim, len(size)))
        self.isize0 = size[0]
        self.isize1 = size[1]
        self.in_shape = self.isize0, self.isize1
        self.osize0 = self.isize0
        self.osize1 = 2 * (self.isize1 / 2 + 1)
        self.out_shape = self.osize0, self.osize1
        self.padding = padding(self.isize1)

        self.buffer = fftw_alloc_real(self.osize0 * self.osize1)
        self.plan_r2c = fftw_plan_dft_r2c_2d(self.isize0, self.isize1,
                                             <double *> self.buffer,
                                             <fftw_complex *> self.buffer,
                                             FFTW_ESTIMATE)
        
    def __dealloc__(self):
        fftw_free(self.buffer)
        fftw_destroy_plan(self.plan_r2c)

    @cython.boundscheck(False)
    @cython.cdivision(True)
    @cython.wraparound(False)
    cpdef double[:, :] r2c(self, double[:, :] ain, double[:, :] aout = None):
        cdef:
            int i0, i1, s0, s1
            double *pbuf, *row, *cell

        # Copy ain to self.buffer, using C pointers increments.
        # Strides are expressed in terms of chars, not doubles.
        s0 = ain.strides[0] / SIZEOF_DOUBLE
        s1 = ain.strides[1] / SIZEOF_DOUBLE
        pbuf = self.buffer
        row = &ain[0, 0]
        for i0 in range(self.isize0):
            cell = row 
            for i1 in range(self.isize1):
                pbuf[0] = cell[0]
                pbuf += 1
                cell += s1
            row += s0
            pbuf += self.padding
        
        fftw_execute(self.plan_r2c)
        if aout is None:
            aout = array(shape=self.out_shape,
                         itemsize=SIZEOF_DOUBLE,
                         format='d')
        
        # Copy result from self.buffer to aout
        s0 = aout.strides[0] / SIZEOF_DOUBLE
        s1 = aout.strides[1] / SIZEOF_DOUBLE
        pbuf = self.buffer
        row = &aout[0, 0]
        for i0 in range(self.osize0):
            cell = row
            for i1 in range(self.osize1):
                cell[0] = pbuf[0]
                pbuf += 1
                cell += s1
            row += s0

        return aout
        
