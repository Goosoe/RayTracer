#import "Basic";
#import "Math";

BACKGROUND_COLOR1 :: Vector3.{1.0, 1.0, 1.0};
BACKGROUND_COLOR2 :: Vector3.{0.5, 0.7, 1.0};
ORIGIN :: Vector3.{0.0, 0.0, 0.0};
ANTI_ALIASING :: true;
AA_SAMPLE_NUM :: 4;

SPHERES := Sphere.[
    Sphere.{Vector3.{0, -100.5, -1}, 100},    // Big sphere to work as ground
    Sphere.{Vector3.{0, 0, -1}, 0.5},
];

Camera :: struct
{
    location := ORIGIN;
};

/**
* Verifies with the given ray if it hit anything and colors the fragment accordingly
*/
renderFragment :: (ray : Ray) -> Vector3
{
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
            return 0.5 * make_vector3(closestHit.normal.x + 1, closestHit.normal.y + 1, closestHit.normal.z + 1);
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

renderFragmentAliasing :: (ray : Ray) -> Vector3
{
    for 0..AA_SAMPLE_NUM
    {

    }
}

// TODO(Goose): refactor and do a camera properly
calculateImageRatio :: () -> Vector2
{
    smallerSide := min(IMAGE_X, IMAGE_Y);
    return make_vector2(cast(float)IMAGE_X / smallerSide, cast(float)IMAGE_Y / smallerSide);
}
