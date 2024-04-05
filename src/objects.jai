#import "Basic";
#import "Math";

/**
* Has functions and structs that allows the user to query the scene
*/

/* Ray Data */
MAX_DIST :: 300.0;
// Using min_dist > 0 to avoid hits that are extremely close, solving shadow acne
MIN_DIST :: 0.001;

Ray :: struct
{
    origin : Vector3;
    direction : Vector3;
}

Sphere :: struct
{
    center : Vector3;
    radius : float;
    material : Materials;
    materialId : int; // id in material array
}

Materials :: enum u8
{
    DIFFUSE :: 0;
    METAL;
    REFLECTIVE;
    LIGHT;
}

/* Applies for Diffuse and Metal materials that use the true lambertian reflection algorithm*/
LambertianData :: struct
{
    attenuation : Vector3;
}


HitData :: struct
{
    //alias for t
    dist : float = MAX_DIST;
    coordinates := Vector3.{0, 0, 0};
    normal := Vector3.{0, 0, 0};
    frontFace := true;
}

// ObjectType :: enum s8
// {
//     SPHERE;
// }

pointAt :: (ray : Ray, point : float) -> Vector3
{
    return ray.origin + (point * ray.direction);
}

/**
* SPHERE DATA
*/
/**
* Verifies if the ray hit a sphere with the given properties
*/
checkSphereCollision :: (ray : Ray, sphere : Sphere) -> bool, HitData
{
    a, b := checkSphereCollision(ray, sphere.center, sphere.radius);
    return a, b;
}

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
