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
createBoundingBox :: (sphere : Sphere) -> BoundingBox
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
createBoundingBox :: (sphere : MovingSphere) -> BoundingBox
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
createBoundingBox :: (quad : Quad) -> BoundingBox
{
    // if the quad is parallel to a duo of axis, add a padding for the bounding box. Because quads, being planes, and therefore 2D, might break the BVH algorithm if we send a plane box as well
    outputBox : BoundingBox;
    PAD_DELTA : float :  0.0001;
    if quad.alignement ==
    {
        case PlaneAligned.XY;
            outputBox = BoundingBox.{Vector3.{quad.p1x0, quad.p2x0, quad.k - PAD_DELTA}, Vector3.{quad.p1x1, quad.p2x1, quad.k + PAD_DELTA}, STATIC_OBJECT};
        case PlaneAligned.XZ;
            outputBox = BoundingBox.{Vector3.{quad.p1x0, quad.k - PAD_DELTA, quad.p2x0}, Vector3.{quad.p1x1, quad.k + PAD_DELTA, quad.p2x1}, STATIC_OBJECT};
        case PlaneAligned.YZ;
            outputBox = BoundingBox.{Vector3.{quad.k - PAD_DELTA, quad.p1x0, quad.p2x0}, Vector3.{quad.k + PAD_DELTA, quad.p1x1, quad.p2x1}, STATIC_OBJECT};
    }
    return outputBox;
}

createBoundingBox :: (box : Box) -> BoundingBox
{
    outputBox1 : BoundingBox;
    outputBox2 : BoundingBox;

    PAD_DELTA : float :  0.0001;
    if box.quads[0].alignement ==
    {
        case PlaneAligned.XY;
            outputBox1 = BoundingBox.{
                Vector3.{box.quads[0].p1x0, box.quads[0].p2x0, box.quads[0].k - PAD_DELTA} + box.translate,
                Vector3.{box.quads[0].p1x1, box.quads[0].p2x1, box.quads[0].k + PAD_DELTA} + box.translate,
                STATIC_OBJECT
            };
        case PlaneAligned.XZ;
            outputBox1 = BoundingBox.{
                Vector3.{box.quads[0].p1x0, box.quads[0].k - PAD_DELTA, box.quads[0].p2x0} + box.translate,
                Vector3.{box.quads[0].p1x1, box.quads[0].k + PAD_DELTA, box.quads[0].p2x1} + box.translate,
                STATIC_OBJECT
            };
        case PlaneAligned.YZ;
            outputBox1 = BoundingBox.{
                Vector3.{box.quads[0].k - PAD_DELTA, box.quads[0].p1x0, box.quads[0].p2x0} + box.translate,
                Vector3.{box.quads[0].k + PAD_DELTA, box.quads[0].p1x1, box.quads[0].p2x1} + box.translate,
                STATIC_OBJECT
            };
    }
    for 1 .. BOX_NUM_OF_QUADS - 1
    {
        if box.quads[it].alignement ==
        {
            case PlaneAligned.XY;
                outputBox2 = BoundingBox.{
                    Vector3.{box.quads[it].p1x0, box.quads[it].p2x0, box.quads[it].k - PAD_DELTA} + box.translate,
                    Vector3.{box.quads[it].p1x1, box.quads[it].p2x1, box.quads[it].k + PAD_DELTA} + box.translate,
                    STATIC_OBJECT
                };
            case PlaneAligned.XZ;
                outputBox2 = BoundingBox.{
                    Vector3.{box.quads[it].p1x0, box.quads[it].k - PAD_DELTA, box.quads[it].p2x0} + box.translate,
                    Vector3.{box.quads[it].p1x1, box.quads[it].k + PAD_DELTA, box.quads[it].p2x1} + box.translate,
                    STATIC_OBJECT};
            case PlaneAligned.YZ;
                outputBox2 = BoundingBox.{
                    Vector3.{box.quads[it].k - PAD_DELTA, box.quads[it].p1x0, box.quads[it].p2x0} + box.translate,
                    Vector3.{box.quads[it].k + PAD_DELTA, box.quads[it].p1x1, box.quads[it].p2x1} + box.translate,
                    STATIC_OBJECT
                };
            outputBox1 = createSurroundingBox(*outputBox1, *outputBox2);
        }
    }
    return outputBox1;
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
checkBoundingBoxCollision :: (ray : Ray, box : BoundingBox, tMin : float = 0.0001, tMax : float = FLOAT32_MAX) -> bool
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
