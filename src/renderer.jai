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
AA_SAMPLE_NUM :: 10;

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
        closestHit: HitData;
        sphereHit : Sphere;
        for SPHERES
        {
            hit, hitData := checkSphereCollision(ray, it);
            if hit && hitData.dist < closestHit.dist
            {
                hasHit = true;
                closestHit = hitData;
                sphereHit = it;
            }
            //shows normal color
        }
        if hasHit
        {
            #if OUTPUT_NORMALS
            {
                return 0.5 * make_vector3(closestHit.normal.x + 1, closestHit.normal.y + 1, closestHit.normal.z + 1);
            }
            else
            {
                // TODO(Goose): make calculations for various types of materials
                /* Diffuse */
                if sphereHit.material ==
                {
                    case .DIFFUSE;
                        //TODO(Goose): make this in a function 
                        bounceDirection := closestHit.normal + generateRandomInUnitSphere();
                        if nearZero(bounceDirection)
                        {
                            bounceDirection = closestHit.normal;
                        }
                        bounceRay := Ray.{
                            closestHit.coordinates,
                            closestHit.normal + generateRandomInUnitSphere() // scattered direction
                        };
                        return LAMBERTIAN_DATA[sphereHit.materialId].attenuation * checkForCollisions(bounceRay, currentDepth + 1);

                    case .METAL;
                        //TODO(Goose): make this in a function 
                        reflectDirection := unit_vector(ray.direction - (2 * dot_product(ray.direction, closestHit.normal)) * closestHit.normal);
                        bounceRay := Ray.{
                            closestHit.coordinates,
                            reflectDirection
                        };
                        return LAMBERTIAN_DATA[sphereHit.materialId].attenuation * checkForCollisions(bounceRay, currentDepth + 1);

                    case .REFLECTIVE;
                        print("Implement Reflective material");
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
