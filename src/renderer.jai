#import "Basic";
#import "Math";

#load "utils.jai";

/* Output Data */
JPG_CHANNELS :: 3;
OUTPUT_NORMALS :: false;

/* Color Data */
BACKGROUND_COLOR1 :: Vector3.{0.8, 0.8, 0.8};
BACKGROUND_COLOR2 :: Vector3.{0.5, 0.7, 1.0};
RED :: Vector3.{1, 0, 0};
GREEN :: Vector3.{0, 1, 0};
BLUE :: Vector3.{0, 0, 1};

/* Render Data */
MAX_RAYS :: 100;

/* Scene Data */
// ORIGIN :: Vector3.{0.0, 0.0, 0.0};

/* Camera Data */
CAMERA_LOCATION :: Vector3.{13, 2, 3};
CAMERA_LOOK_AT :: Vector3.{0, 0, 0};
CAMERA_UP :: Vector3.{0, 1, 0};
CAMERA_DEFOCUS_ANGLE :: 0.0;
CAMERA_FOCUS_DIST :: 1;
// or defocus blur
//DEPTH_OF_FIELD :: Vector3.{0, 1, 0};
// Vertical Degrees
FOV :: 20;

/* Anti-Aliasing */
ANTI_ALIASING :: true;
AA_SAMPLE_NUM :: 100;

/* Viewport data */
ASPECT_RATIO :: cast(float)IMAGE_X / cast(float)IMAGE_Y;
// rad = deg * (pi / 180)
// viewport size =  2 * tan(rad / 2) * zoom
// How much the viewport captures
//TODO(Goose): Add zoom?
// ZOOM :: 1;
/******/

Camera :: struct
{
    // viewportSize : float;
    viewportHeight : Vector3;
    viewportWidth : Vector3;
    viewportLowerLeft : Vector3;
    defocusDiskU : Vector3;
    defocusDiskV : Vector3;
}

camera : Camera;

renderFragmentThread :: (group: *Thread_Group, thread: *Thread, work: *void) -> Thread_Continue_Status 
{
    fragmentData := cast(*FragmentData) work;
    color := renderFragment(fragmentData.coords);
    
    color = linearToGamma(color);

    ir : u8 = cast(u8)(255.99 * color.x);
    ig : u8 = cast(u8)(255.99 * color.y);
    ib : u8 = cast(u8)(255.99 * color.z);

    // No need to syncrhonize writes on this memory as there won't be any concurrent writing/reading 
    jpgData.data[fragmentData.jpgDataPos] = ir;
    jpgData.data[fragmentData.jpgDataPos + 1] = ig;
    jpgData.data[fragmentData.jpgDataPos + 2] = ib;
    return .CONTINUE;
}

/**
* Verifies if there is a collision with an object at the given coordinates
*/
renderFragment :: (coords : Vector2) -> Vector3
{
    /* Generate a ray */
    #if ANTI_ALIASING
    {
        color := Vector3.{0, 0, 0};
        // Randomizes a value around the original uv
        for 0 .. AA_SAMPLE_NUM - 1
        {
            fragmentLocation := getRandomAdjacentCoordinate(coords);
            point := CAMERA_LOCATION;
            if CAMERA_DEFOCUS_ANGLE > 0
            {
                point = sampleDefocusDisk();
            }
            ray := Ray.{
                point,
                fragmentLocation - point
            };
            color += checkForCollisions(ray);
        }
        return color / (AA_SAMPLE_NUM);
    }
    else
    {
        fragmentLocation := getCoordinate(coords);
        ray := Ray.{
            CAMERA_LOCATION,
            fragmentLocation - CAMERA_LOCATION
        };
        return checkForCollisions(ray);
    }
}

/* Use the given ray to see if it hit any of the objects in the scene */
checkForCollisions :: (ray : Ray, currentDepth : int = 0) -> Vector3
{
    /* Sphere collisions */
    {
        if currentDepth >= MAX_RAYS
        {
            // TODO(Goose): Magic number, change this
            return Vector3.{0, 0, 0};
        }
        // gets the closest hit value to print on the fragment by iterating over all objects and gets the closest
        hasHit := false;
        hitData: HitData;
        sphereHit : Sphere;
        for SPHERES
        {
            hit, lastHitData := checkSphereCollision(ray, it);
            if hit && lastHitData.dist < hitData.dist
            {
                hasHit = true;
                hitData = lastHitData;
                sphereHit = it;
            }
            //shows normal color
        }
        if hasHit
        {
#if OUTPUT_NORMALS
{
            return 0.5 * make_vector3(hitData.normal.x + 1, hitData.normal.y + 1, hitData.normal.z + 1);
}
else
{
                /* Diffuse */
            if sphereHit.material ==
            {
                case .DIFFUSE;
                    //TODO(Goose): make this a function?
                    bounceDirection := hitData.normal + generateRandomInUnitSphere();
                    if nearZero(bounceDirection)
                    {
                        bounceDirection = hitData.normal;
                    }
                    bounceRay := Ray.{
                        hitData.coordinates,
                        hitData.normal + generateRandomInUnitSphere() // scattered direction
                    };
                    return DIFFUSE_DATA[sphereHit.materialId].attenuation * checkForCollisions(bounceRay, currentDepth + 1);

                case .METAL;
                    //TODO(Goose): make this a function?
                    reflectRay := getReflectRay(ray, hitData, sphereHit);
                    return METAL_DATA[sphereHit.materialId].attenuation * checkForCollisions(reflectRay, currentDepth + 1);

                case .DIELECTRIC;
                     dielectricRay := getDielectricRay(ray, hitData, sphereHit);
                    return DIELECTRIC_DATA[sphereHit.materialId].attenuation * checkForCollisions(dielectricRay, currentDepth + 1);
                
                case .LIGHT;
                    print("Implement Light material");
                }
}
        }
    }
    /* Background colors */
    {
        rayDir := unit_vector(ray.direction);
        // transforms the direction to a positive value between [0,1]
        coord := 0.5 * (rayDir.y + 1.0);
        // applies the lerp
        //((1.0 - coord) * BACKGROUND_COLOR1) + (coord * BACKGROUND_COLOR2);
        // print("Bacground hit at depth: %\n", currentDepth);
        return lerp(BACKGROUND_COLOR1, BACKGROUND_COLOR2, coord);
    }
}

/* Returns the data associated with the given coordinate. uv and fragmentLocation in the viewport */
getRandomAdjacentCoordinate :: (coords : Vector2) -> Vector3
{
    uvOffset := Vector2.{(-0.5 + random_get_zero_to_one()) / IMAGE_X, (-0.5 + random_get_zero_to_one())  / IMAGE_Y};
    uv := Vector2.{coords.x / IMAGE_X, coords.y / IMAGE_Y};
    fragmentLocation := camera.viewportLowerLeft + ((uv.x  + uvOffset.x) * camera.viewportWidth) + ((uv.y + uvOffset.y) * camera.viewportHeight);
    return fragmentLocation;
}

/* Returns the data associated with the given coordinate. uv and fragmentLocation in the viewport */
getCoordinate :: (coords : Vector2) -> Vector3
{
    uv := Vector2.{coords.x / IMAGE_X, coords.y / IMAGE_Y};
    fragmentLocation := camera.viewportLowerLeft + (uv.x * camera.viewportWidth) + (uv.y * camera.viewportHeight);
    return fragmentLocation;
}

getReflectRay :: (ray : Ray, hitData : HitData, sphereHit : Sphere) -> Ray
{
    reflectDirection := unit_vector(ray.direction - (2 * dot_product(ray.direction, hitData.normal)) * hitData.normal);

    reflectRay := Ray.{
        hitData.coordinates,
        reflectDirection
    };
    if METAL_DATA[sphereHit.materialId].fuzz > 0.0001 
    {
        reflectRay.direction += METAL_DATA[sphereHit.materialId].fuzz * generateRandomInUnitSphere();
    }
    return reflectRay;
}

getReflectRay :: (ray : Ray, hitData : HitData, sphereHit : Sphere, $T : Type) -> Ray
{
    reflectDirection := unit_vector(ray.direction - (2 * dot_product(ray.direction, hitData.normal)) * hitData.normal);

    reflectRay := Ray.{
        hitData.coordinates,
        reflectDirection
    };

    #if T ==
    {
        case MetalData;
            if METAL_DATA[sphereHit.materialId].fuzz > 0.0001 
            {
                reflectRay.direction += METAL_DATA[sphereHit.materialId].fuzz * generateRandomInUnitSphere();
            }
            return reflectRay;

        case DielectricData;
            return reflectRay;

        case;
            assert(false, "ReflectRay of type: % is not implemented", materialType);
            return Ray.{Vector3.{0,0,0}, Vector3.{0,0,0}};
        }
        assert(false, "Shouldn't have gotten here");
}

getDielectricRay :: (ray : Ray, hitData : HitData, sphereHit : Sphere) -> Ray
{
    refractionRatio := DIELECTRIC_DATA[sphereHit.materialId].indexOfRefraction;
    assert(abs(refractionRatio) > 0.000001, "Index of Refraction cannot be 0, gotten index: %", refractionRatio);
    if hitData.frontFace 
    {
        refractionRatio = 1.0 /  DIELECTRIC_DATA[sphereHit.materialId].indexOfRefraction;
    }
    unitDirection := unit_vector(ray.direction);

    cosTheta := min(dot_product(-unitDirection, hitData.normal), 1.0);
    sinTheta := sqrt(1.0 - cosTheta * cosTheta);
    perpendicular := refractionRatio * (unitDirection + cosTheta * hitData.normal);
    parallel := -sqrt(abs(1.0 - length_squared(perpendicular))) * hitData.normal;

    // Use Schlick's approximation for reflectance. It gives a chance for reflecting instead of always refracting
     r0 := (1 - refractionRatio) / (1 + refractionRatio);
     r0 = r0 * r0;
     reflectance := r0 + ((1 - r0) * pow((1 - cosTheta), 5));

     if sinTheta * refractionRatio > 1.0 || reflectance > random_get_zero_to_one()
     {
         return getReflectRay(ray, hitData, sphereHit, DielectricData);
     }

    return Ray.{
        hitData.coordinates,
        parallel + perpendicular
    };
}

setupCamera :: () 
{
    // focalLength := length(CAMERA_LOCATION - CAMERA_LOOK_AT);
    viewportHeight := 2 * tan(degreeToRadian(FOV) / 2) * CAMERA_FOCUS_DIST;
    viewportSize := Vector2.{viewportHeight * ASPECT_RATIO, viewportHeight};
    w := unit_vector(CAMERA_LOCATION - CAMERA_LOOK_AT);
    u := unit_vector(cross_product(CAMERA_UP, w));
    v := cross_product(w, u);
    viewportU := viewportSize.x * u;
    viewportV := viewportSize.y * v;
    lowerLeft := CAMERA_LOCATION - (CAMERA_FOCUS_DIST * w) - (viewportU / 2) - (viewportV / 2);
    
    defocusRadius := CAMERA_FOCUS_DIST * tan(degreeToRadian(CAMERA_DEFOCUS_ANGLE / 2));
    defocusDiskU := u * defocusRadius;
    defocusDiskV := v * defocusRadius;

    camera = Camera.{
        viewportV,
        viewportU,
        lowerLeft,
        defocusDiskU,
        defocusDiskV
    };
    print("Camera set up! Current aspect ratio: %\n", ASPECT_RATIO);
}

sampleDefocusDisk :: () -> Vector3
{
    point := generateRandomInUnitCircle();
    return CAMERA_LOCATION + (point.x * camera.defocusDiskU) + (point.y * camera.defocusDiskV);
}
