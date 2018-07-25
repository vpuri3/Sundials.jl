abstract type AbstactFunJac{J2} end
mutable struct FunJac{F, F2, J, P, J2, uType} <: AbstactFunJac{J2}
    fun::F
    fun2::F2
    jac::J
    p::P
    jac_prototype::J2
    u::uType
    du::uType
end
FunJac(fun,jac,p,jac_prototype,u,du) = FunJac(fun,nothing,jac,p,jac_prototype,u,du)

function cvodefunjac(t::Float64,
                     u::N_Vector,
                     du::N_Vector,
                     funjac::FunJac)
    funjac.fun(convert(Vector, du), convert(Vector, u), funjac.p, t)
    return CV_SUCCESS
end

function cvodefunjac2(t::Float64,
                     u::N_Vector,
                     du::N_Vector,
                     funjac::FunJac)
    funjac.fun2(convert(Vector, du), convert(Vector, u), funjac.p, t)
    return CV_SUCCESS
end

function cvodejac(t::realtype,
                  u::N_Vector,
                  du::N_Vector,
                  J::SUNMatrix,
                  funjac::AbstactFunJac{Nothing},
                  tmp1::N_Vector,
                  tmp2::N_Vector,
                  tmp3::N_Vector)
    funjac.jac(convert(Matrix, J), convert(Vector, u), funjac.p, t)
    return CV_SUCCESS
end

function cvodejac(t::realtype,
                  u::N_Vector,
                  du::N_Vector,
                  _J::SUNMatrix,
                  funjac::AbstactFunJac{<:SparseMatrixCSC},
                  tmp1::N_Vector,
                  tmp2::N_Vector,
                  tmp3::N_Vector)
    jac_prototype = funjac.jac_prototype
    J = convert(SparseMatrixCSC,_J)
    funjac.jac(jac_prototype, convert(Vector, u), funjac.p, t)
    J.nzval .= jac_prototype.nzval
    # Sundials resets the value pointers each time, so reset it too
    @. J.rowval = jac_prototype.rowval - 1
    @. J.colptr = jac_prototype.colptr - 1
    return CV_SUCCESS
end

function idasolfun(t::Float64, y::N_Vector, yp::N_Vector, r::N_Vector, funjac::FunJac)
    funjac.fun(convert(Vector, r), convert(Vector, yp), convert(Vector, y), funjac.p, t)
    return IDA_SUCCESS
end

function idajac(t::realtype,
                cj::realtype,
                x::N_Vector,
                dx::N_Vector,
                res::N_Vector,
                J::SUNMatrix,
                funjac::AbstactFunJac{Nothing},
                tmp1::N_Vector,
                tmp2::N_Vector,
                tmp3::N_Vector)
    funjac.jac(convert(Matrix, J), convert(Vector,dx),
               convert(Vector, x), funjac.p, cj, t)
    return IDA_SUCCESS
end

function idajac(t::realtype,
                cj::realtype,
                x::N_Vector,
                dx::N_Vector,
                res::N_Vector,
                _J::SUNMatrix,
                funjac::AbstactFunJac{<:SparseMatrixCSC},
                tmp1::N_Vector,
                tmp2::N_Vector,
                tmp3::N_Vector)

                jac_prototype = funjac.jac_prototype
                J = convert(SparseMatrixCSC,_J)
                funjac.jac(jac_prototype, convert(Vector,dx),
                            convert(Vector, x), funjac.p, cj, t)
                J.nzval .= jac_prototype.nzval
                # Sundials resets the value pointers each time, so reset it too
                @. J.rowval = jac_prototype.rowval - 1
                @. J.colptr = jac_prototype.colptr - 1

    return IDA_SUCCESS
end
