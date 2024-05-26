#import "Basic";
#import "Math";

/**
* Has functions dedicated to get ray information and the objects that it might intersect in a scene 
*/

Ray :: struct
{
    origin : Vector3;
    direction : Vector3;
    // time of the shutter when ray is created. Used to simulate movement and thus, motion blur 
    shutterTime : float = 0;
}

HitData :: struct
{
    dist : float = MAX_DIST;
    coordinates := Vector3.{0, 0, 0};
    normal := Vector3.{0, 0, 0};
    uv := Vector2.{0, 0};
    frontFace := true;
}

pointAt :: (ray : Ray, point : float) -> Vector3
{
    return ray.origin + (point * ray.direction);
}

/** STATIC OBJECTS RAY CALCULATIONS **/

getDiffuseRay :: (rayTime : float, hitData : HitData) -> Ray
{
    bounceDirection := hitData.normal + generateRandomInUnitSphere();
    if nearZero(bounceDirection)
    {
        bounceDirection = hitData.normal;
    }
    return Ray.{
        hitData.coordinates,
        hitData.normal + generateRandomInUnitSphere(), // scattered direction
        rayTime
    };
}
/* Gets the reflection ray of a static object with Metal material*/
getReflectRay :: (ray : Ray, hitData : HitData, sphereHit : Sphere) -> Ray
{
    reflectDirection := unit_vector(ray.direction - (2 * dot_product(ray.direction, hitData.normal)) * hitData.normal);

    reflectRay := Ray.{
        hitData.coordinates,
        reflectDirection,
        ray.shutterTime
    };
    if METAL_DATA[sphereHit.materialId].fuzz > 0.0001 
    {
        reflectRay.direction += METAL_DATA[sphereHit.materialId].fuzz * generateRandomInUnitSphere();
    }
    return reflectRay;
}

/* Gets the reflection ray of a static object of material Type T*/
getReflectRay :: (ray : Ray, hitData : HitData, sphereHit : Sphere, $T : Type) -> Ray
{
    reflectDirection := unit_vector(ray.direction - (2 * dot_product(ray.direction, hitData.normal)) * hitData.normal);

    reflectRay := Ray.{
        hitData.coordinates,
        reflectDirection,
        ray.shutterTime
    };

    #if T ==
    {
        case MaterialMetal;
            if METAL_DATA[sphereHit.materialId].fuzz > 0.0001 
            {
                reflectRay.direction += METAL_DATA[sphereHit.materialId].fuzz * generateRandomInUnitSphere();
            }
            return reflectRay;

        case MaterialDielectric;
            return reflectRay;

        case;
            assert(false, "ReflectRay of type: % is not implemented", T);
            return Ray.{Vector3.{0,0,0}, Vector3.{0,0,0}, 0.0};
        }
        assert(false, "Shouldn't have gotten here");
}

/* Gets dielectric ray of a stsatic object */
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
         return getReflectRay(ray, hitData, sphereHit, MaterialDielectric);
     }

    return Ray.{
        hitData.coordinates,
        parallel + perpendicular,
        ray.shutterTime
    };
}

/** MOVING OBJECTS RAY CALCULATIONS **/

/* Gets the reflection ray of a static object with Metal material*/
getMovingReflectRay :: (ray : Ray, hitData : HitData, sphereHit : Sphere) -> Ray
{
    reflectDirection := unit_vector(ray.direction - (2 * dot_product(ray.direction, hitData.normal)) * hitData.normal);

    reflectRay := Ray.{
        hitData.coordinates,
        reflectDirection,
        ray.shutterTime
    };
    if METAL_DATA[sphereHit.materialId].fuzz > 0.0001 
    {
        reflectRay.direction += METAL_DATA[sphereHit.materialId].fuzz * generateRandomInUnitSphere();
    }
    return reflectRay;
}

/* Gets the reflection ray of a static object of material Type T*/
getMovingReflectRay :: (ray : Ray, hitData : HitData, sphereHit : Sphere, $T : Type) -> Ray
{
    reflectDirection := unit_vector(ray.direction - (2 * dot_product(ray.direction, hitData.normal)) * hitData.normal);

    reflectRay := Ray.{
        hitData.coordinates,
        reflectDirection,
        ray.shutterTime
    };

    #if T ==
    {
        case MaterialMetal;
            if METAL_DATA[sphereHit.materialId].fuzz > 0.0001 
            {
                reflectRay.direction += METAL_DATA[sphereHit.materialId].fuzz * generateRandomInUnitSphere();
            }
            return reflectRay;

        case MaterialDielectric;
            return reflectRay;

        case;
            assert(false, "ReflectRay of type: % is not implemented", T);
            return Ray.{Vector3.{0,0,0}, Vector3.{0,0,0}, 0.0};
        }
        assert(false, "Shouldn't have gotten here");
}

/* Gets dielectric ray of a stsatic object */
getMovingDielectricRay :: (ray : Ray, hitData : HitData, sphereHit : Sphere) -> Ray
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
         return getReflectRay(ray, hitData, sphereHit, MaterialDielectric);
     }

    return Ray.{
        hitData.coordinates,
        parallel + perpendicular,
        ray.shutterTime
    };
}
