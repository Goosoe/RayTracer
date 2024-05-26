#import "Basic";
#import "Math";
#import "Random";

#load "utils.jai";
#load "sphere.jai";
#load "material.jai";
#load "bounding_box.jai";

/* Output Data */
JPG_CHANNELS :: 3;
OUTPUT_NORMALS :: false;

/* Color Data */
BACKGROUND_COLOR1 :: Vector3.{0.8, 0.8, 0.8};
BACKGROUND_COLOR2 :: Vector3.{0.5, 0.7, 1.0};
RED :: Vector3.{1, 0, 0};
GREEN :: Vector3.{0, 1, 0};
BLUE :: Vector3.{0, 0, 1};
BLACK :: Vector3.{0, 0, 0};

/* Motion blur */
//For how long the shutter will stay "open". It will go from [0.0, SHUTTER_TIME]
MOTION_BLUR :: true;
SHUTTER_TIME :: 2;
/* Render Data */
MAX_RAYS :: 100;

/* Scene Data */
// ORIGIN :: Vector3.{0.0, 0.0, 0.0};

/* Camera Data */
CAMERA_LOCATION :: Vector3.{4, 1.5, 1.5};
CAMERA_LOOK_AT :: Vector3.{0, 0, 0};
CAMERA_UP :: Vector3.{0, 1, 0};
// Set this to 0 to not have defocus
CAMERA_DEFOCUS_ANGLE :: 0.0;
CAMERA_FOCUS_DIST :: 1;
// Vertical Degrees
FOV :: 80;

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

/** CAMERA **/
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

/** RAY **/
MAX_DIST :: 300.0;
// Using min_dist > 0 to avoid hits that are extremely close, solving shadow acne
MIN_DIST :: 0.001;



/** MULTI-THREADED VARIANT **/
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
/****************/

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
            #if MOTION_BLUR
            {
                shutterTime := random_get_within_range(0.0, SHUTTER_TIME);
            }
            else
            {
                shutterTime := 0.0;
            }
            fragmentLocation := getRandomAdjacentCoordinate(coords);
            point := CAMERA_LOCATION;
            if CAMERA_DEFOCUS_ANGLE > 0
            {
                point = sampleDefocusDisk();
            }
            ray := Ray.{
                point,
                fragmentLocation - point,
                shutterTime
            };
            /* TODO(Goose): Add texture color calculation herer*/
            color += checkForCollisions(ray);
        }
        return color / (AA_SAMPLE_NUM);
    }
    else    // NO ANTI_ALIASING
    {
        #if MOTION_BLUR
        {
            shutterTime := random_get_within_range(0.0, SHUTTER_TIME);
        }
        else
        {
            shutterTime := 0.0;
        }
        fragmentLocation := getCoordinate(coords);

        // this way, we avoid creating a random per fragment
        ray := Ray.{
            CAMERA_LOCATION,
            fragmentLocation - CAMERA_LOCATION,
            shutterTime
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
            return BLACK;
        }
        // gets the closest hit value to print on the fragment by iterating over all objects and gets the closest
        hasHit := false;
        hitData: HitData;
        sphereHit : Sphere;
        hasHit, hitData, sphereHit = checkBVHCollision(Sphere, ray);

        for MOVING_SPHERES
        {
            hit, lastHitData := checkMovingSphereCollision(ray, it);
            if hit && lastHitData.dist < hitData.dist
            {
                hasHit = true;
                hitData = lastHitData;
                sphereHit = it.sphere;
            }
        }
        //shows normal color
        if hasHit
        {
            #if OUTPUT_NORMALS
            {
                return 0.5 * make_vector3(hitData.normal.x + 1, hitData.normal.y + 1, hitData.normal.z + 1);
            }
            else
            {
                /* Diffuse */
                //TODO(Goose): This can be replaced by compile time Type verification. This is a solution "A la C"
                if sphereHit.material ==
                {
                    case .DIFFUSE;
                        bounceRay := getDiffuseRay(ray.shutterTime, hitData);
                //TODO(Goose): Replace this with a function on object.jai. It should calculate the material + texture color 
                        materialData := DIFFUSE_DATA[sphereHit.materialId];
                        return materialData.attenuation * checkForCollisions(bounceRay, currentDepth + 1) * getTextureAtUV(materialData.textureType, hitData.uv, hitData.coordinates, materialData.textureIdx);

                    case .METAL;
                        reflectRay := getReflectRay(ray, hitData, sphereHit);
                        materialData := METAL_DATA[sphereHit.materialId];
                        return materialData.attenuation * checkForCollisions(reflectRay, currentDepth + 1) * getTextureAtUV(materialData.textureType, hitData.uv, hitData.coordinates, materialData.textureIdx);

                    case .DIELECTRIC;
                        dielectricRay := getDielectricRay(ray, hitData, sphereHit);
                        materialData := DIELECTRIC_DATA[sphereHit.materialId];
                        return materialData.attenuation * checkForCollisions(dielectricRay, currentDepth + 1) * getTextureAtUV(materialData.textureType, hitData.uv, hitData.coordinates, materialData.textureIdx);

                    case .EMISSIVE;
                        print("Implement Emissive material");
                }
            }
        }
    }
        /* Cube Collisions */

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

setupCamera :: () 
{
    assert(CAMERA_FOCUS_DIST > 0.0, "CAMERA_FOCUS_DIST needs to be > 0.0");
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
