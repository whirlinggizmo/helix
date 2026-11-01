"""raymath: raylib 5.5's raymath.h against helix-ray's Raymath, every function over three inputs (shared/gen.py's syntax). Its
signatures are raymath.h's, written here; each case draws its arguments from SAMPLES by type, the k-th case shifting each argument's
pick by k, so zero vectors, opposite directions and a singular matrix meet each function somewhere. Functions with outs are written out
below. QuaternionFromVector3ToVector3 and MatrixDecompose are 6.2's, in core_62 and raymath_62."""

SIGNATURES = """
float Clamp(float value, float min, float max)
float Lerp(float start, float end, float amount)
float Normalize(float value, float start, float end)
float Remap(float value, float inputStart, float inputEnd, float outputStart, float outputEnd)
float Wrap(float value, float min, float max)
int FloatEquals(float x, float y)
Vector2 Vector2Zero(void)
Vector2 Vector2One(void)
Vector2 Vector2Add(Vector2 v1, Vector2 v2)
Vector2 Vector2AddValue(Vector2 v, float add)
Vector2 Vector2Subtract(Vector2 v1, Vector2 v2)
Vector2 Vector2SubtractValue(Vector2 v, float sub)
float Vector2Length(Vector2 v)
float Vector2LengthSqr(Vector2 v)
float Vector2DotProduct(Vector2 v1, Vector2 v2)
float Vector2Distance(Vector2 v1, Vector2 v2)
float Vector2DistanceSqr(Vector2 v1, Vector2 v2)
float Vector2Angle(Vector2 v1, Vector2 v2)
float Vector2LineAngle(Vector2 start, Vector2 end)
Vector2 Vector2Scale(Vector2 v, float scale)
Vector2 Vector2Multiply(Vector2 v1, Vector2 v2)
Vector2 Vector2Negate(Vector2 v)
Vector2 Vector2Divide(Vector2 v1, Vector2 v2)
Vector2 Vector2Normalize(Vector2 v)
Vector2 Vector2Transform(Vector2 v, Matrix mat)
Vector2 Vector2Lerp(Vector2 v1, Vector2 v2, float amount)
Vector2 Vector2Reflect(Vector2 v, Vector2 normal)
Vector2 Vector2Min(Vector2 v1, Vector2 v2)
Vector2 Vector2Max(Vector2 v1, Vector2 v2)
Vector2 Vector2Rotate(Vector2 v, float angle)
Vector2 Vector2MoveTowards(Vector2 v, Vector2 target, float maxDistance)
Vector2 Vector2Invert(Vector2 v)
Vector2 Vector2Clamp(Vector2 v, Vector2 min, Vector2 max)
Vector2 Vector2ClampValue(Vector2 v, float min, float max)
int Vector2Equals(Vector2 p, Vector2 q)
Vector2 Vector2Refract(Vector2 v, Vector2 n, float r)
Vector3 Vector3Zero(void)
Vector3 Vector3One(void)
Vector3 Vector3Add(Vector3 v1, Vector3 v2)
Vector3 Vector3AddValue(Vector3 v, float add)
Vector3 Vector3Subtract(Vector3 v1, Vector3 v2)
Vector3 Vector3SubtractValue(Vector3 v, float sub)
Vector3 Vector3Scale(Vector3 v, float scalar)
Vector3 Vector3Multiply(Vector3 v1, Vector3 v2)
Vector3 Vector3CrossProduct(Vector3 v1, Vector3 v2)
Vector3 Vector3Perpendicular(Vector3 v)
float Vector3Length(const Vector3 v)
float Vector3LengthSqr(const Vector3 v)
float Vector3DotProduct(Vector3 v1, Vector3 v2)
float Vector3Distance(Vector3 v1, Vector3 v2)
float Vector3DistanceSqr(Vector3 v1, Vector3 v2)
float Vector3Angle(Vector3 v1, Vector3 v2)
Vector3 Vector3Negate(Vector3 v)
Vector3 Vector3Divide(Vector3 v1, Vector3 v2)
Vector3 Vector3Normalize(Vector3 v)
Vector3 Vector3Project(Vector3 v1, Vector3 v2)
Vector3 Vector3Reject(Vector3 v1, Vector3 v2)
Vector3 Vector3Transform(Vector3 v, Matrix mat)
Vector3 Vector3RotateByQuaternion(Vector3 v, Quaternion q)
Vector3 Vector3RotateByAxisAngle(Vector3 v, Vector3 axis, float angle)
Vector3 Vector3MoveTowards(Vector3 v, Vector3 target, float maxDistance)
Vector3 Vector3Lerp(Vector3 v1, Vector3 v2, float amount)
Vector3 Vector3CubicHermite(Vector3 v1, Vector3 tangent1, Vector3 v2, Vector3 tangent2, float amount)
Vector3 Vector3Reflect(Vector3 v, Vector3 normal)
Vector3 Vector3Min(Vector3 v1, Vector3 v2)
Vector3 Vector3Max(Vector3 v1, Vector3 v2)
Vector3 Vector3Barycenter(Vector3 p, Vector3 a, Vector3 b, Vector3 c)
Vector3 Vector3Unproject(Vector3 source, Matrix projection, Matrix view)
Vector3 Vector3Invert(Vector3 v)
Vector3 Vector3Clamp(Vector3 v, Vector3 min, Vector3 max)
Vector3 Vector3ClampValue(Vector3 v, float min, float max)
int Vector3Equals(Vector3 p, Vector3 q)
Vector3 Vector3Refract(Vector3 v, Vector3 n, float r)
Vector4 Vector4Zero(void)
Vector4 Vector4One(void)
Vector4 Vector4Add(Vector4 v1, Vector4 v2)
Vector4 Vector4AddValue(Vector4 v, float add)
Vector4 Vector4Subtract(Vector4 v1, Vector4 v2)
Vector4 Vector4SubtractValue(Vector4 v, float add)
float Vector4Length(Vector4 v)
float Vector4LengthSqr(Vector4 v)
float Vector4DotProduct(Vector4 v1, Vector4 v2)
float Vector4Distance(Vector4 v1, Vector4 v2)
float Vector4DistanceSqr(Vector4 v1, Vector4 v2)
Vector4 Vector4Scale(Vector4 v, float scale)
Vector4 Vector4Multiply(Vector4 v1, Vector4 v2)
Vector4 Vector4Negate(Vector4 v)
Vector4 Vector4Divide(Vector4 v1, Vector4 v2)
Vector4 Vector4Normalize(Vector4 v)
Vector4 Vector4Min(Vector4 v1, Vector4 v2)
Vector4 Vector4Max(Vector4 v1, Vector4 v2)
Vector4 Vector4Lerp(Vector4 v1, Vector4 v2, float amount)
Vector4 Vector4MoveTowards(Vector4 v, Vector4 target, float maxDistance)
Vector4 Vector4Invert(Vector4 v)
int Vector4Equals(Vector4 p, Vector4 q)
float MatrixDeterminant(Matrix mat)
float MatrixTrace(Matrix mat)
Matrix MatrixTranspose(Matrix mat)
Matrix MatrixInvert(Matrix mat)
Matrix MatrixIdentity(void)
Matrix MatrixAdd(Matrix left, Matrix right)
Matrix MatrixSubtract(Matrix left, Matrix right)
Matrix MatrixMultiply(Matrix left, Matrix right)
Matrix MatrixTranslate(float x, float y, float z)
Matrix MatrixRotate(Vector3 axis, float angle)
Matrix MatrixRotateX(float angle)
Matrix MatrixRotateY(float angle)
Matrix MatrixRotateZ(float angle)
Matrix MatrixRotateXYZ(Vector3 angle)
Matrix MatrixRotateZYX(Vector3 angle)
Matrix MatrixScale(float x, float y, float z)
Matrix MatrixFrustum(double left, double right, double bottom, double top, double nearPlane, double farPlane)
Matrix MatrixPerspective(double fovY, double aspect, double nearPlane, double farPlane)
Matrix MatrixOrtho(double left, double right, double bottom, double top, double nearPlane, double farPlane)
Matrix MatrixLookAt(Vector3 eye, Vector3 target, Vector3 up)
Quaternion QuaternionAdd(Quaternion q1, Quaternion q2)
Quaternion QuaternionAddValue(Quaternion q, float add)
Quaternion QuaternionSubtract(Quaternion q1, Quaternion q2)
Quaternion QuaternionSubtractValue(Quaternion q, float sub)
Quaternion QuaternionIdentity(void)
float QuaternionLength(Quaternion q)
Quaternion QuaternionNormalize(Quaternion q)
Quaternion QuaternionInvert(Quaternion q)
Quaternion QuaternionMultiply(Quaternion q1, Quaternion q2)
Quaternion QuaternionScale(Quaternion q, float mul)
Quaternion QuaternionDivide(Quaternion q1, Quaternion q2)
Quaternion QuaternionLerp(Quaternion q1, Quaternion q2, float amount)
Quaternion QuaternionNlerp(Quaternion q1, Quaternion q2, float amount)
Quaternion QuaternionSlerp(Quaternion q1, Quaternion q2, float amount)
Quaternion QuaternionCubicHermiteSpline(Quaternion q1, Quaternion outTangent1, Quaternion q2, Quaternion inTangent2, float t)
Quaternion QuaternionFromVector3ToVector3(Vector3 from, Vector3 to)
Quaternion QuaternionFromMatrix(Matrix mat)
Matrix QuaternionToMatrix(Quaternion q)
Quaternion QuaternionFromAxisAngle(Vector3 axis, float angle)
Quaternion QuaternionFromEuler(float pitch, float yaw, float roll)
Vector3 QuaternionToEuler(Quaternion q)
Quaternion QuaternionTransform(Quaternion q, Matrix mat)
int QuaternionEquals(Quaternion p, Quaternion q)
"""

SAMPLES = {
    'float': ['0.37', '-1.25', '2.5', '0', '0.5'],
    'double': ['-1.5', '2', '0.1', '100', '-3'],
    'Vector2': ['V2(1.5, -2)', 'V2(-0.25, 3)', 'V2(0, 0)', 'V2(-1.5, 2)', 'V2(0.6, 0.8)'],
    'Vector3': ['V3(1, -2, 3)', 'V3(-0.5, 0.25, 2)', 'V3(0, 0, 0)', 'V3(0, 1, 0)', 'V3(-1, 2, -3)'],
    'Vector4': ['NEW(Vector4, 0.5, -1, 2, 0.25)', 'NEW(Vector4, -0.5, 0.5, 0.5, 0.5)', 'NEW(Vector4, 0, 0, 0, 0)',
                'NEW(Vector4, 0.182574, 0.365148, 0.547723, 0.730297)', 'NEW(Vector4, -0.182574, -0.365148, -0.547723, -0.730297)'],
    'Matrix': ['NEW(Matrix, 0.8, -0.6, 0, 3, 0.6, 0.8, 0, -1, 0, 0, 2, 0.5, 0, 0, 0, 1)',
               'NEW(Matrix, 1, 2, 3, 4, 0.5, -1, 2, 1, 3, 0.25, -2, 0, 0.1, 0.2, 0.3, 1)',
               'NEW(Matrix, 1, 2, 3, 4, 2, 4, 6, 8, 0, 1, 0, 1, 0, 0, 0, 1)',
               'NEW(Matrix, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 2, 0, 0, 0, 0, 1)',
               'NEW(Matrix, 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 2, 3, 1)'],
}
SAMPLES['Quaternion'] = SAMPLES['Vector4']
PRINT = {'float': 'num', 'int': 'num', 'Vector2': 'vec2', 'Vector3': 'v3', 'Vector4': 'v4', 'Quaternion': 'v4', 'Matrix': 'mat'}
# Arguments kept to values that mean something: a refraction's ratio; an unprojection's view invertible, as a singular one's inverse is
# float rounding's alone.
FIXED = {('Vector3Unproject', 'view'): ['NEW(Matrix, 0.8, -0.6, 0, 3, 0.6, 0.8, 0, -1, 0, 0, 2, 0.5, 0, 0, 0, 1)', 'NEW(Matrix, 0, -1, 0, 0, 1, 0, 0, 0, 0, 0, 1, 0, 1, 2, 3, 1)'],
         ('Vector2Refract', 'r'): ['0.66', '1.5', '1'], ('Vector3Refract', 'r'): ['0.66', '1.5', '1']}

# raylib 6.2's, taken where it fixed a bug (DECISIONS 24): in core_62 and raymath_62.
TAKEN = ['QuaternionFromVector3ToVector3', 'MatrixDecompose']

CASES = []
for sig in SIGNATURES.strip().split('\n'):
    ret, rest = sig.split(' ', 1)
    name, params = rest[:-1].split('(', 1)
    if name in TAKEN:
        continue
    params = [] if params.strip() in ('', 'void') else [p.strip().rsplit(' ', 1) for p in params.split(',')]
    params = [(t.replace("const ", ""), p) for t, p in params]
    for k in range(1 if not params else 3):
        args = []
        for i, (t, pname) in enumerate(params):
            pick = FIXED.get((name, pname), SAMPLES[t])
            args.append(pick[(i + k) % len(pick)])
        CASES.append(f'{PRINT[ret]}("{name.lower()}{k}", {name}({", ".join(args)}));')


def c(e):
    """A sample as C, for a case written apart for each side."""
    return '((' + e[4:e.index(',')] + '){ ' + e[e.index(',') + 2:-1] + ' })' if e.startswith('NEW') else e


def hx(e):
    """A sample as Haxe."""
    return e.replace('NEW(Vector4, ', 'new Vector4(').replace('NEW(Matrix, ', 'new Matrix(')


# The functions with outs.
for k, (a, b) in enumerate([('V3(1, 2, 0)', 'V3(0.5, 0.5, 2)'), ('V3(0, 3, 0)', 'V3(1, 1, 1)')]):
    CASES.append(f'LET(on{k}a, Vector3, {a}); LET(on{k}b, Vector3, {b}); Vector3OrthoNormalize(OUT(on{k}a), OUT(on{k}b)); '
                 f'v3("orthonormalize{k}a", on{k}a); v3("orthonormalize{k}b", on{k}b);')
for k, q in enumerate(SAMPLES['Quaternion']):
    CASES.append({'c': f'{{ Vector3 axis; float angle; QuaternionToAxisAngle({c(q)}, &axis, &angle); '
                       f'v3("toaxisangle{k}axis", axis); num("toaxisangle{k}angle", angle); }}',
                  'hx': f'{{ var axis = [new Vector3()], angle = [0.]; QuaternionToAxisAngle({hx(q)}, axis, angle); '
                        f'v3("toaxisangle{k}axis", axis[0]); num("toaxisangle{k}angle", angle[0]); }}'})
for k, v in enumerate(SAMPLES['Vector3'][:2]):
    CASES.append({'c': f'floats("tofloatv3{k}", Vector3ToFloatV({v}).v, 3);', 'hx': f'floats("tofloatv3{k}", Vector3ToFloatV({v}));'})
for k, m in enumerate(SAMPLES['Matrix'][:2]):
    CASES.append({'c': f'floats("tofloatvm{k}", MatrixToFloatV({c(m)}).v, 16);', 'hx': f'floats("tofloatvm{k}", MatrixToFloatV({hx(m)}));'})
