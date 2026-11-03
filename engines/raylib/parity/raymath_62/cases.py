"""raymath_62: the raymath functions helix-raylib takes from raylib 6.2 (DECISIONS 24) and not tested elsewhere: MatrixDecompose, which takes
its scale from the matrix's columns where 5.5 took the rows (QuaternionFromVector3ToVector3 is in core_62). shared/gen.py's syntax."""

MATRICES = ['NEW(Matrix, 0.8, -0.6, 0, 3, 0.6, 0.8, 0, -1, 0, 0, 2, 0.5, 0, 0, 0, 1)',
            'NEW(Matrix, 1, 2, 3, 4, 0.5, -1, 2, 1, 3, 0.25, -2, 0, 0.1, 0.2, 0.3, 1)',
            'MatrixMultiply(MatrixScale(2, 0.5, 3), MatrixMultiply(MatrixRotateXYZ(V3(0.3, -0.7, 1.1)), MatrixTranslate(1, -2, 3)))',
            'MatrixMultiply(MatrixScale(-1, 2, 1), MatrixRotateY(0.4))']

CASES = []
for k, m in enumerate(MATRICES):
    CASES.append(f'LET(dt{k}, Vector3, V3(0, 0, 0)); LET(dr{k}, Quaternion, NEW(Quaternion, 0, 0, 0, 1)); LET(ds{k}, Vector3, V3(0, 0, 0)); '
                 f'MatrixDecompose({m}, OUT(dt{k}), OUT(dr{k}), OUT(ds{k})); '
                 f'v3("decompose{k}t", dt{k}); v4("decompose{k}r", dr{k}); v3("decompose{k}s", ds{k});')
