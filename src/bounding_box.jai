#import "Basic";
#import "Math";

/* Using the AABB bounding box algorithm*/

STATIC_OBJECT :: 0.0;


BoundingBox :: struct //($T : Type)
{
    min : Vector3;
    max : Vector3;
    /* BoundingBox will use this value as the upper bount to calculate its position [0, time]
    * If the object is static, use STATIC_OBJECT value
    */
    time := STATIC_OBJECT;
    /* Bounding Box can hold a list of bounding boxes that it contains or a hittable object*/
    // objects : [..] T;
}

/**
* Creates a BoundingBox for a static Sphere object
*/ 
createSphereBoundingBox :: (sphere : Sphere) -> BoundingBox
{
    return BoundingBox.{
        sphere.center - make_vector3(sphere.radius, sphere.radius, sphere.radius),
        sphere.center + make_vector3(sphere.radius, sphere.radius, sphere.radius),
        STATIC_OBJECT
    };
}

/**
* Creates a BoundingBox for a moving Sphere object
*/ 
createSphereBoundingBox :: (sphere : MovingSphere) -> BoundingBox
{
    b1 := BoundingBox.{
        sphere.center - make_vector3(sphere.sphere.radius, sphere.sphere.radius, sphere.sphere.radius),
        sphere.center + make_vector3(sphere.sphere.radius, sphere.sphere.radius, sphere.sphere.radius),
        sphere.movingTime
    };

    b2 := BoundingBox.{
        sphere.center1 - make_vector3(sphere.radius, sphere.sphere.radius, sphere.sphere.radius),
        sphere.center1 + make_vector3(sphere.radius, sphere.sphere.radius, sphere.sphere.radius),
        sphere.movingTime
    };
    return createSurroundingBox(*b1, *b2);
}

/**
* Creates a BoundingBox for a static quad
*/
createQuadBoundingBox :: (quad : Quad) -> BoundingBox
{
    // if the quad is parallel to a duo of axis, add a padding for the bounding box. Because quads, being planes, and therefore 2D, might break the BVH algorithm if we send a plane box as well
    padBoundingBox :: (box : *BoundingBox)
    {
        PAD_DELTA : float :  0.0001;
        if abs(box.min.x - box.max.x) < PAD_DELTA
        {
            box.min.x -= PAD_DELTA;
            box.max.x += PAD_DELTA;
        }
        else if abs(box.min.y - box.max.y) < PAD_DELTA
        {
            box.min.y -= PAD_DELTA;
            box.max.y += PAD_DELTA;
        }
        else if abs(box.min.z - box.max.z) < PAD_DELTA
        {
            box.min.z -= PAD_DELTA;
            box.max.z += PAD_DELTA;
        }
    }
    // Compute the bounding box of all four vertices.
    b1 := BoundingBox.{quad.point, quad.point + quad.u + quad.v, STATIC_OBJECT};
    b2 := BoundingBox.{quad.point + quad.u, quad.point + quad.v, STATIC_OBJECT};

    bb := createSurroundingBox(*b1, *b2);
    padBoundingBox(*bb);
    return bb;
}

/**
* Creates a BoundingBox that encompasses two given bounding boxes
*/
createSurroundingBox :: (box1 : *BoundingBox, box2 : *BoundingBox) -> BoundingBox
{
    minVals := make_vector3(min(box1.min.x, box2.min.x),
        min(box1.min.y, box2.min.y),
        min(box1.min.z, box2.min.z));
    maxVals := make_vector3(max(box1.max.x, box2.max.x),
        max(box1.max.y, box2.max.y),
        max(box1.max.z, box2.max.z));
        return BoundingBox.{minVals, maxVals, max(box1.time, box2.time)};
}

/**
* Gets a ray and the limits of the box (tMin and tMax) and calculates if the ray goes through them 
*/
checkBoundingBoxCollision :: (ray : Ray, box : BoundingBox, tMin : float = 0.001, tMax : float = FLOAT32_MAX) -> bool
{
    for 0 .. 2
    {
        inverseDir : float = 1 / getAxis(it, ray.direction);
        t0 := (getAxis(it, box.min) - getAxis(it, ray.origin)) * inverseDir;
        t1 := (getAxis(it, box.max) - getAxis(it, ray.origin)) * inverseDir;
        if inverseDir < 0.0
        {
            Swap(*t0, *t1);
        }
        minVal := max(tMin, t0);
        maxVal := min(tMax, t1); 
        if maxVal <= minVal
        {
            return false;
        }
    }
    return true;
}
