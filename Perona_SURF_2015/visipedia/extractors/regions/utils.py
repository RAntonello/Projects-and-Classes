import numpy
from PIL import Image

#http://www.lfd.uci.edu/~gohlke/code/transformations.py.html
def affine_matrix_from_points(v0, v1, shear=True, scale=True, usesvd=True):
    """Return affine transform matrix to register two point sets.

    v0 and v1 are shape (ndims, \*) arrays of at least ndims non-homogeneous
    coordinates, where ndims is the dimensionality of the coordinate space.

    If shear is False, a similarity transformation matrix is returned.
    If also scale is False, a rigid/Euclidean transformation matrix
    is returned.

    By default the algorithm by Hartley and Zissermann [15] is used.
    If usesvd is True, similarity and Euclidean transformation matrices
    are calculated by minimizing the weighted sum of squared deviations
    (RMSD) according to the algorithm by Kabsch [8].
    Otherwise, and if ndims is 3, the quaternion based algorithm by Horn [9]
    is used, which is slower when using this Python implementation.

    The returned matrix performs rotation, translation and uniform scaling
    (if specified).

    >>> v0 = [[0, 1031, 1031, 0], [0, 0, 1600, 1600]]
    >>> v1 = [[675, 826, 826, 677], [55, 52, 281, 277]]
    >>> affine_matrix_from_points(v0, v1)
    array([[   0.14549,    0.00062,  675.50008],
           [   0.00048,    0.14094,   53.24971],
           [   0.     ,    0.     ,    1.     ]])
    >>> T = translation_matrix(numpy.random.random(3)-0.5)
    >>> R = random_rotation_matrix(numpy.random.random(3))
    >>> S = scale_matrix(random.random())
    >>> M = concatenate_matrices(T, R, S)
    >>> v0 = (numpy.random.rand(4, 100) - 0.5) * 20
    >>> v0[3] = 1
    >>> v1 = numpy.dot(M, v0)
    >>> v0[:3] += numpy.random.normal(0, 1e-8, 300).reshape(3, -1)
    >>> M = affine_matrix_from_points(v0[:3], v1[:3])
    >>> numpy.allclose(v1, numpy.dot(M, v0))
    True

    More examples in superimposition_matrix()

    """
    v0 = numpy.array(v0, dtype=numpy.float64, copy=True)
    v1 = numpy.array(v1, dtype=numpy.float64, copy=True)

    ndims = v0.shape[0]
    if ndims < 2 or v0.shape[1] < ndims or v0.shape != v1.shape:
        raise ValueError("input arrays are of wrong shape or type")

    # move centroids to origin
    t0 = -numpy.mean(v0, axis=1)
    M0 = numpy.identity(ndims+1)
    M0[:ndims, ndims] = t0
    v0 += t0.reshape(ndims, 1)
    t1 = -numpy.mean(v1, axis=1)
    M1 = numpy.identity(ndims+1)
    M1[:ndims, ndims] = t1
    v1 += t1.reshape(ndims, 1)

    if shear:
        # Affine transformation
        A = numpy.concatenate((v0, v1), axis=0)
        u, s, vh = numpy.linalg.svd(A.T)
        vh = vh[:ndims].T
        B = vh[:ndims]
        C = vh[ndims:2*ndims]
        t = numpy.dot(C, numpy.linalg.pinv(B))
        t = numpy.concatenate((t, numpy.zeros((ndims, 1))), axis=1)
        M = numpy.vstack((t, ((0.0,)*ndims) + (1.0,)))
    elif usesvd or ndims != 3:
        # Rigid transformation via SVD of covariance matrix
        u, s, vh = numpy.linalg.svd(numpy.dot(v1, v0.T))
        # rotation matrix from SVD orthonormal bases
        R = numpy.dot(u, vh)
        if numpy.linalg.det(R) < 0.0:
            # R does not constitute right handed system
            R -= numpy.outer(u[:, ndims-1], vh[ndims-1, :]*2.0)
            s[-1] *= -1.0
        # homogeneous transformation matrix
        M = numpy.identity(ndims+1)
        M[:ndims, :ndims] = R
    else:
        # Rigid transformation matrix via quaternion
        # compute symmetric matrix N
        xx, yy, zz = numpy.sum(v0 * v1, axis=1)
        xy, yz, zx = numpy.sum(v0 * numpy.roll(v1, -1, axis=0), axis=1)
        xz, yx, zy = numpy.sum(v0 * numpy.roll(v1, -2, axis=0), axis=1)
        N = [[xx+yy+zz, 0.0,      0.0,      0.0],
             [yz-zy,    xx-yy-zz, 0.0,      0.0],
             [zx-xz,    xy+yx,    yy-xx-zz, 0.0],
             [xy-yx,    zx+xz,    yz+zy,    zz-xx-yy]]
        # quaternion: eigenvector corresponding to most positive eigenvalue
        w, V = numpy.linalg.eigh(N)
        q = V[:, numpy.argmax(w)]
        q /= vector_norm(q)  # unit quaternion
        # homogeneous transformation matrix
        M = quaternion_matrix(q)

    if scale and not shear:
        # Affine transformation; scale is ratio of RMS deviations from centroid
        v0 *= v0
        v1 *= v1
        M[:ndims, :ndims] *= numpy.math.sqrt(numpy.sum(v1) / numpy.sum(v0))

    # move centroids back
    M = numpy.dot(numpy.linalg.inv(M1), numpy.dot(M, M0))
    M /= M[ndims, ndims]
    return M

def affine_matrix_from_points_steve(v0, v1, shear=True, scale=True, weights=None):
    """ 
    This function is currently redundant with affine_matrix_from_points() and is used to make sure it produces the 
    same output as Steve's feature extraction code.  Eventually we should merge these two functions.  
    """
    if v0 is None or v0.shape[0]==0: return (None,float("inf"),None)
    n = v0.shape[0]
    if n <= 1: shear = scale = usesvd = False
    elif n <= 2 and shear: shear = False
    if weights is None: weights = numpy.ones((n,1))
    w = weights/float(weights.sum())
    ww = numpy.tile(w,(1,2))
    if shear:
        # Least squares affine fit to n>=3 points
        ws = numpy.sqrt(weights)
        M = hstack((v0,numpy.ones((n,1)))) * numpy.tile(ws,(1,3))
        y = v1*numpy.tile(ws,(1,2))
        x = numpy.linalg.lstsq(M,y)  
        A = numpy.transpose(x[0])
    
    elif scale:
        # Least squares fit to align points using a scale, rotation, and translation
        mu1 = (v0*ww).sum(axis=0)
        mu2 = (v1*ww).sum(axis=0)
        X = v0-numpy.tile(mu1,(n,1))
        Y = v1-numpy.tile(mu2,(n,1))
        S = numpy.dot(numpy.transpose(X*ww),Y)
        [u,s,v] = numpy.linalg.svd(S)
        s_new = numpy.array([1,numpy.linalg.det(numpy.dot(u,v))])
        R = numpy.transpose(numpy.dot(numpy.dot(u,numpy.diag(s_new)),v))
        Xh = numpy.dot(X,numpy.transpose(R))
        scale = (Xh*ww*Y).sum()/max(0.00000001,(Xh*ww*Xh).sum())
        t = mu2 - numpy.dot(mu1,numpy.transpose(R))*scale
        A = numpy.hstack((R*scale,numpy.transpose(numpy.array([t]))))
    
    else:
        # Least squares fit to align points using just a translation
        mu1 = (v0*ww).sum(axis=0)
        mu2 = (v1*ww).sum(axis=0)
        A = numpy.hstack((numpy.eye(2,2),numpy.transpose([mu2 - mu1])))  
    
    preds = numpy.dot(numpy.hstack((v0,numpy.ones((n,1)))),numpy.transpose(A))
    return (A, ((v1-preds)*(v1-preds)*ww).sum(), preds)

def parse_geo_json(annotation, image_size=(1.0,1.0)):
    if 'visible' in annotation['properties'] and not annotation['properties']['visible']:
        converted_annotation = [0, 0, False]
    elif annotation['geometry']['type'] == 'Point':
        x,y = annotation['geometry']['coordinates']
        converted_annotation = [x*image_size[0], y*image_size[1], True]
    elif annotation['geometry']['type'] == 'Polygon':
        if 'type' in annotation['properties'] and annotation['properties']['type'] == 'Rectangle':
            upper_left, upper_right, lower_right, lower_left, _ = annotation['geometry']['coordinates'][0]
            x1, y1 = upper_left
            x2, y2 = lower_right
            converted_annotation = [(x1 + x2)*image_size[0] / 2., (y1 + y2)*image_size[1] / 2., True]
            #converted_annotation = [(x1 + x2)*image_size[0] / 2., (y1 + y2)*image_size[1] / 2., (x2 - x1)*image_size[0], (y2 - y1)*image_size[1], True]
        else:
            raise Exception("Not supported yet")
    else:
        raise Exception("Not supported yet")
        
    return converted_annotation

def encode_geo_json(x, y, visible, image_size=(1.0,1.0)):
    return {"type":"Feature", "properties":{"visible":visible}, "geometry" : { "type":"Point", "coordinates":[x/float(image_size[0]),y/float(image_size[1])]} }
