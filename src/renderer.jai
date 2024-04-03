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

/* Anti-Aliasing */
ANTI_ALIASING :: true;
AA_SAMPLE_NUM :: 10;

/* Viewport data */
ASPECT_RATIO :: IMAGE_X / IMAGE_Y;
// How much the viewport captures
VIEWPORT_SIZE :: 2.0;
ZOOM :: 1;
VIEWPORT_HEIGHT :: Vector3.{0.0, VIEWPORT_SIZE, 0.0};
VIEWPORT_WIDTH :: Vector3.{VIEWPORT_SIZE * ASPECT_RATIO, 0.0, 0.0};
VIEWPORT_LOWER_LEFT :: Vector3.{-VIEWPORT_SIZE * ASPECT_RATIO / 2, -VIEWPORT_SIZE / 2, -ZOOM};
/******/

// TODO(Goose): Implement Perspective view
ORTHOGONAL_VIEW:: true;

// TODO(Goose): Investigate if camera location needs to be different than origin
/* Camera Data */
CAMERA_LOCATION :: Vector3.{0,0,0};

/**
* Verifies if there is a collision with an object at the given coordinates
*/
renderFragment :: (coords : Vector2) -> Vector3
{
    /* Generate a ray */
    #if ORTHOGONAL_VIEW
    {
        // TODO(Goose): Put this in a function with the view guard to calculate the values properly
        uv, fragmentLocation := getCoordinateData(coords);

        ray := Ray.{
            CAMERA_LOCATION,
            fragmentLocation - CAMERA_LOCATION
        };
    }
    // TODO(Goose): Generate PERSPECTIVE VIEW
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
            fragmentLocation := VIEWPORT_LOWER_LEFT + ((uv.x + random.x) * VIEWPORT_WIDTH) + ((uv.y + random.y)* VIEWPORT_HEIGHT);
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
            return Vector3.{0, 0, 0};
        }
        // gets the closest hit value to print on the fragment by iterating over all objects and gets the closest
        hasHit := false;
        closestHit: HitData;
        for SPHERES
        {
            hit, hitData := checkSphereCollision(ray, it);
            if hit && hitData.dist < closestHit.dist
            {
                hasHit = true;
                closestHit = hitData;
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
                direction := unit_vector(generateRandomVec3(-1.0, 1.0));
                // make sure we get our direction against the surface it hit
                // print("%\n", closestHit.normal);
                if dot_product(closestHit.normal, direction) < 0.0
                {
                    direction = -direction;
                }
                // print("% % %\n", closestHit.coordinates.x,closestHit.coordinates.y,closestHit.coordinates.z);
                // print("% % %\n", direction.x,direction.y,direction.z);
                nextRay := Ray.{
                    closestHit.coordinates,
                    direction 
                };

                // TODO(Goose): 0.5 is a magic number...
                return 0.5 * checkForCollisions(nextRay, currentDepth + 1);
            }
        }
    }

    /* Background colors */
    {
        unitDir := unit_vector(ray.direction);
        // transforms the direction to a positive value between [0,1]
        coord := 0.5 * (unitDir.y + 1.0);
        // applies the lerp
        //((1.0 - coord) * BACKGROUND_COLOR1) + (coord * BACKGROUND_COLOR2);
        // print("Bacground hit at depth: %\n", currentDepth);
        return lerp(BACKGROUND_COLOR1, BACKGROUND_COLOR2, coord);
    }
}

/* Returns the data associated with the given coordinate. uv and fragmentLocation in the viewport */
getCoordinateData :: (coords : Vector2) -> Vector2, Vector3
{
    #if ORTHOGONAL_VIEW
    {
        uv := Vector2.{coords.x / IMAGE_X, coords.y / IMAGE_Y};
        fragmentLocation := VIEWPORT_LOWER_LEFT + (uv.x * VIEWPORT_WIDTH) + (uv.y * VIEWPORT_HEIGHT);
        return uv, fragmentLocation;

    }
    else
    {
        // TODO(Goose): Generate PERSPECTIVE VIEW
        print("Perspective view not implemented. Implement me?");

    }
}
