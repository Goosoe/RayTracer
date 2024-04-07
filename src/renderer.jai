#import "Basic";
#import "Math";

#load "utils.jai";

/* Output Data */
JPG_CHANNELS :: 3;
OUTPUT_NORMALS :: false;

/* Color Data */
BACKGROUND_COLOR1 :: Vector3.{1.0, 1.0, 1.0};
BACKGROUND_COLOR2 :: Vector3.{0.5, 0.7, 1.0};
RED :: Vector3.{1, 0, 0};
GREEN :: Vector3.{0, 1, 0};
BLUE :: Vector3.{0, 0, 1};

/* Render Data */
MAX_RAYS :: 50;

/* Scene Data */
ORIGIN :: Vector3.{0.0, 0.0, 0.0};

// TODO(Goose): Investigate if camera location needs to be different than origin
/* Camera Data */
CAMERA_Z_LOCATION :: 0;
CAMERA_LOCATION :: Vector3.{0,0, CAMERA_Z_LOCATION};


/* Anti-Aliasing */
ANTI_ALIASING :: true;
AA_SAMPLE_NUM :: 15;

/* Viewport data */
ASPECT_RATIO :: IMAGE_X / IMAGE_Y;
// How much the viewport captures
VIEWPORT_SIZE :: 2;
ZOOM :: 1;
VIEWPORT_HEIGHT :: Vector3.{0.0, VIEWPORT_SIZE, 0.0};
VIEWPORT_WIDTH :: Vector3.{VIEWPORT_SIZE * ASPECT_RATIO, 0.0, 0.0};
VIEWPORT_LOWER_LEFT :: Vector3.{-VIEWPORT_SIZE * ASPECT_RATIO / 2, -VIEWPORT_SIZE / 2, CAMERA_Z_LOCATION - ZOOM};
/******/

// TODO(Goose): Implement ORTHO view
PERSPECTIVE_VIEW:: true;


/**
* Verifies if there is a collision with an object at the given coordinates
*/
renderFragment :: (coords : Vector2) -> Vector3
{
    /* Generate a ray */
    #if PERSPECTIVE_VIEW
    {
        // TODO(Goose): Put this in a function with the view guard to calculate the values properly
        uv, fragmentLocation := getCoordinateData(coords);
        // uv = Vector2.{uv.x * ASPECT_RATIO, uv.y};

        ray := Ray.{
            CAMERA_LOCATION,
            fragmentLocation - CAMERA_LOCATION
        };
    }
    // TODO(Goose): Generate ORTHO VIEW
    else
    {
        print("Perspective view not implemented. Implement me?");
        return Vector3.{0, 0, 0};
    }

    /* Use Ray to see if it collides with anything in the defined scene, returns the color of the object hit*/
    #if ANTI_ALIASING
    {
        color := Vector3.{0, 0, 0};
        color += checkForCollisions(ray);
        // Randomizes a value around the original uv
        for 0 .. AA_SAMPLE_NUM - 1
        {
            random:= Vector2.{(-0.5 + random_get_zero_to_one()) / IMAGE_X, (-0.5 + random_get_zero_to_one())  / IMAGE_Y};
            fragmentLocation := VIEWPORT_LOWER_LEFT + (((uv.x) + random.x) * VIEWPORT_WIDTH) + ((uv.y + random.y)* VIEWPORT_HEIGHT);
            ray := Ray.{
                CAMERA_LOCATION,
                fragmentLocation - CAMERA_LOCATION
            };
            color += checkForCollisions(ray);
        }
        // Samples + Original value 
        return color / (AA_SAMPLE_NUM + 1);
        // print ("Color % % % \n", color.x,color.y,color.z);
    }
    else
    {
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

                // TODO(Goose): 0.5 is a magic number...
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
getCoordinateData :: (coords : Vector2) -> Vector2, Vector3
{
    #if PERSPECTIVE_VIEW
    {
        uv := Vector2.{coords.x / IMAGE_X, coords.y / IMAGE_Y};
        fragmentLocation := VIEWPORT_LOWER_LEFT + (uv.x * VIEWPORT_WIDTH) + (uv.y * VIEWPORT_HEIGHT);
        return uv, fragmentLocation;

    }
    else
    {
        // TODO(Goose): Generate ORTH VIEW
        print("Orthogonal view not implemented. Implement me?");

    }
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

getReflectRay :: (ray : Ray, hitData : HitData, sphereHit : Sphere, materialType : $T) -> Ray
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

    if sinTheta * refractionRatio > 1.0
    {
        return getReflectRay(ray, hitData, sphereHit, DielectricData);
    }

    return Ray.{
        hitData.coordinates,
        parallel + perpendicular
    };

}
