/** 
*   File dedicated to the STATIC and MOVING Sphere functions.
*   I am separating STATIC and MOVING functions to keep modularity and 
*   to keep functions simple without any more branching. This hopefully will
*   keep the program more performant too.
*/

#import "Basic";
#import "Math";

/** DATA STRUCTS **/
Sphere :: struct
{
    center : Vector3;
    radius : float;
    material : Materials;
    materialId : int; // id in material array
}

MovingSphere :: struct
{
    sphere : Sphere;
    /* second center to interpolate sphere position at a time [0, SHUTTER_TIME]
    * goes from the center to center1
    */
    center1 : Vector3;
    // How long is the sphere going to take to go from center to center1. The smaller the value, the less motion blur it seems to have. 
    // To properly function, provide a number [0, SHUTTER_TIME]
    movingTime : float;
}

/** STATIC **/

/**
* Verifies if the ray hit a sphere with the given properties
*/
checkSphereCollision :: (ray : Ray, sphere : Sphere) -> bool, HitData
{
    a, b := checkSphereCollision(ray, sphere.center, sphere.radius);
    return a, b;
}

/**
* Verifies if the ray hit a sphere with the given properties
*/
checkSphereCollision :: (ray : Ray, center : Vector3, radius : float) -> bool, HitData
{
    // the sphere equation:
    // t*t*dot( B , B ) + 2*t*dot( B,A - C ) + dot( A-C,A - C ) - R*R = 0
    // t is the variable here that makes the this a quadratic function. 

    oc := ray.origin - center;
    a : float = dot_product(ray.direction, ray.direction);
    // b : float = 2 * dot_product(oc, ray.direction);
    b : float = dot_product(oc, ray.direction);
    c : float = dot_product(oc, oc) - (radius * radius);
    // discriminant from the quadratic formula
    // discriminant: float = b * b - 4 * a * c;
    discriminant: float = b * b -  a * c;
    // ray does not hit the Sphere
    if discriminant < 0
    {
        return false, HitData.{};
    }
    // this is the original quadratic function: (-b - sqrt(discriminant)) / (2.0 * a);
    // Note that the 2's and 4 were removed from the original function as they cance eachother in this case
    SIGNAL := s8.[1, -1];
    for SIGNAL
    {
        // IMPORTANT: negative calculations first
        root := (-b - (sqrt(discriminant) * it)) / a;
        //verifies if the hit is in front of the camera and is not too far away
        if root <= MIN_DIST || root >= MAX_DIST
        {
            continue;
        }
        hitCoord := pointAt(ray, root);
        normal := (hitCoord - center) / radius;
        frontFace := dot_product(ray.direction, normal) < 0;
        // guarantees that the normal is outwards facing
        if !frontFace then normal = -normal;
        return true, HitData.{root, hitCoord, normal, frontFace};
    }
    //root did not comply with defined dist values
    return false, HitData.{};
}
/***********************/


/** MOVING **/

/**
* Verifies if the ray hit a moving sphere with the given properties
*/
// checkMovingSphereCollision :: (ray : Ray, sphere : MovingSphere) -> bool, HitData
// {
//     a, b := checkMovingSphereCollision(ray, sphere.sphere.center, sphere.sphere.radius);
//     return a, b;
// }

/**
* Verifies if the ray hit moving a sphere with the given properties
*/
checkMovingSphereCollision :: (ray : Ray, sphere : MovingSphere) -> bool, HitData
{
    // the sphere equation:
    // t*t*dot( B , B ) + 2*t*dot( B,A - C ) + dot( A-C,A - C ) - R*R = 0
    // t is the variable here that makes the this a quadratic function. 

    radius := sphere.sphere.radius;
    oc := ray.origin - centerAtTime(sphere, ray.shutterTime);
    a : float = dot_product(ray.direction, ray.direction);
    // b : float = 2 * dot_product(oc, ray.direction);
    b : float = dot_product(oc, ray.direction);
    c : float = dot_product(oc, oc) - (radius * radius);
    // discriminant from the quadratic formula
    // discriminant: float = b * b - 4 * a * c;
    discriminant: float = b * b -  a * c;
    // ray does not hit the Sphere
    if discriminant < 0
    {
        return false, HitData.{};
    }
    // this is the original quadratic function: (-b - sqrt(discriminant)) / (2.0 * a);
    // Note that the 2's and 4 were removed from the original function as they cance eachother in this case
    SIGNAL := s8.[1, -1];
    for SIGNAL
    {
        // IMPORTANT: negative calculations first
        root := (-b - (sqrt(discriminant) * it)) / a;
        //verifies if the hit is in front of the camera and is not too far away
        if root <= MIN_DIST || root >= MAX_DIST
        {
            continue;
        }
        hitCoord := pointAt(ray, root);
        normal := (hitCoord - centerAtTime(sphere, ray.shutterTime)) / radius;
        frontFace := dot_product(ray.direction, normal) < 0;
        // guarantees that the normal is outwards facing
        if !frontFace then normal = -normal;
        return true, HitData.{root, hitCoord, normal, frontFace};
    }
    //root did not comply with defined dist values
    return false, HitData.{};
}

/* Interpolates the center at the given time. */
centerAtTime :: (sphere : MovingSphere, time : float) -> Vector3{
    if time >=  sphere.movingTime
    {
        return sphere.center1;
    }
    centerDiff := sphere.center1 - sphere.sphere.center;
    return sphere.sphere.center + (centerDiff * (time / SHUTTER_TIME));
}
