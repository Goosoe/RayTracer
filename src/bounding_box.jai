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

// MovingBoundingBox :: struct
// {
//     box : BoundingBox;
//     /* BoundingBox will use this value as the upper bount to calculate its position [0, time]*/
//     time : float;
// }

/**
* Creates a bounding box for a static object
*/ 
createSphereBoundingBox :: (sphere : Sphere) -> BoundingBox
{
    return BoundingBox.{
        sphere.center - make_vector3(sphere.radius, sphere.radius, sphere.radius),
        sphere.center + make_vector3(sphere.radius, sphere.radius, sphere.radius),
        STATIC_OBJECT
    };
}

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
    return createSurroundingBox(b1, b2);
}

/**
* Creates a BoundingBox that encompasses two given bounding boxes
*/
createSurroundingBox :: (box1 : BoundingBox, box2 : BoundingBox) -> BoundingBox
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
    // return true;
    // TODO: THIS IS NOT DOING THINGS PROPERLY
    for 0..2
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
        // print("% %\n", minVal, maxVal);
        if maxVal <= minVal
        {
            return false;
        }
    }
    return true;
}

//TODO(Goose):create function that takes two bounding boxes and makes a bigger one that encompasses them both. Useful for moving objects or to create hierarchies
