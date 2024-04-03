#import "Basic";
#import "Math";

/* Output Data */
JPG_CHANNELS :: 3;
OUTPUT_NORMALS :: true;

/* Color Data */
BACKGROUND_COLOR1 :: Vector3.{1.0, 1.0, 1.0};
BACKGROUND_COLOR2 :: Vector3.{0.5, 0.7, 1.0};
RED :: Vector3.{1, 0, 0};
GREEN :: Vector3.{0, 1, 0};
BLUE :: Vector3.{0, 0, 1};

/* Scene Data */
ORIGIN :: Vector3.{0.0, 0.0, 0.0};

/* Anti-Aliasing */
ANTI_ALIASING :: true;
AA_SAMPLE_NUM :: 4;

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

    #if ORTHOGONAL_VIEW
    {
        uv := Vector2.{coords.x / IMAGE_X, coords.y / IMAGE_Y};
        fragmentLocation := VIEWPORT_LOWER_LEFT + (uv.x * VIEWPORT_WIDTH) + (uv.y * VIEWPORT_HEIGHT);

        ray := Ray.{
            CAMERA_LOCATION,
            fragmentLocation - CAMERA_LOCATION
        };
    }
    else
    {
        print("Perspective view not implemented. Implement me?");
        return Vector3.{0, 0, 0};
    }
    // TODO(Goose): Generate ORTHO OR PERSPECTIVE VIEW
    //#if ORTHOGONAL_VIEW

    // renders the Spheres
    {
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

                return RED;
            }
        }
    }

    // background
    {
        unitDir := unit_vector(ray.direction);
        // transforms the direction to a positive value between [0,1]
        coord := 0.5 * (unitDir.y + 1.0);
        // applies the lerp
        //((1.0 - coord) * BACKGROUND_COLOR1) + (coord * BACKGROUND_COLOR2);
        return lerp(BACKGROUND_COLOR1, BACKGROUND_COLOR2, coord);
    }
}

// renderFragmentAliasing :: (ray : Ray) -> Vector3
// {
//     for 0..AA_SAMPLE_NUM
//     {
//
//     }
// }

// TODO(Goose): refactor and do a camera properly
// calculateImageRatio :: () -> Vector2
// {
//     smallerSide := min(IMAGE_X, IMAGE_Y);
//     return make_vector2(cast(float)IMAGE_X / smallerSide, cast(float)IMAGE_Y / smallerSide);
// }
