#import "Basic";
#import "Math";

/* Using the AABB bounding box algorithm*/

STATIC_OBJECT :: 0.0;
PAD_DELTA : float :  0.0001;


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

    // create bounding box
    outputBox := createBoundingBoxAux(box.quads[0]);
    for 1 .. BOX_NUM_OF_QUADS - 1
    {
        outputBox = createSurroundingBox(*outputBox, *createBoundingBoxAux(box.quads[it]));
    }
    //rotate 
        for i: 0 .. 1
        {
            for j: 0 .. 1
            {
                for k: 0 .. 1
                {
                    x := i * outputBox.max.x + ((1 - i) * outputBox.min.x);
                    y := i * outputBox.max.y + ((1 - j) * outputBox.min.y);
                    z := i * outputBox.max.z + ((1 - k) * outputBox.min.z);
                    rotX := box.cosTetha * x + box.sinTetha * z;
                    rotZ := -box.sinTetha * x + box.cosTetha * z;
                    newCoords := Vector3.{rotX, y, rotZ};

                    outputBox.min.x = min(outputBox.min.x, newCoords.x);
                    outputBox.max.x = max(outputBox.max.x, newCoords.x);
                    outputBox.min.y = min(outputBox.min.y, newCoords.y);
                    outputBox.max.y = max(outputBox.max.y, newCoords.y);
                    outputBox.min.z = min(outputBox.min.z, newCoords.z);
                    outputBox.max.z = max(outputBox.max.z, newCoords.z);
                }
            }
        }
    //translate
    outputBox.min += box.translate;
    outputBox.max += box.translate;
    // right now the "center" of the object is in the bottom left quad value. we want to offset it so it moves to the center of the bottom quad
    return outputBox;
}

createBoundingBoxAux :: (quad : AuxQuad) -> BoundingBox
{
    outputBox : BoundingBox;

    if quad.alignement ==
    {
        case PlaneAligned.XY;
            outputBox = BoundingBox.{
                Vector3.{quad.p1x0, quad.p2x0, quad.k - PAD_DELTA},
                Vector3.{quad.p1x1, quad.p2x1, quad.k + PAD_DELTA},
                STATIC_OBJECT
            };
        case PlaneAligned.XZ;
            outputBox = BoundingBox.{
                Vector3.{quad.p1x0, quad.k - PAD_DELTA, quad.p2x0},
                Vector3.{quad.p1x1, quad.k + PAD_DELTA, quad.p2x1},
                STATIC_OBJECT
            };
        case PlaneAligned.YZ;
            outputBox = BoundingBox.{
                Vector3.{quad.k - PAD_DELTA, quad.p1x0, quad.p2x0},
                Vector3.{quad.k + PAD_DELTA, quad.p1x1, quad.p2x1},
                STATIC_OBJECT
            };
    }
    return outputBox;
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
