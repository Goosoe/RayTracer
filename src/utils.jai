#import "Basic";
#import "Math";
#import "Random";

/** Vector functions **/
generateRandomVec3 :: () -> Vector3
{
    return Vector3.{
        random_get_zero_to_one(),
        random_get_zero_to_one(),
        random_get_zero_to_one()
    };
}

generateRandomVec3 :: (min : float, max : float) -> Vector3
{
    return Vector3.{
        random_get_within_range(min, max),
        random_get_within_range(min, max),
        random_get_within_range(min, max)
    };
}

generateRandomInUnitSphere :: () -> Vector3
{
    while true
    {
        res := Vector3.{
            random_get_within_range(0, 1),
            random_get_within_range(0, 1),
            random_get_within_range(0, 1)
        };
        if length_squared(res) < 1.0
        {
            return unit_vector(res);
        }
    }
    return Vector3.{0, 0, 0};
}

nearZero :: (vector : Vector3) -> bool
{
    NEAR_ZERO_VALUE :: 0.00001;
    return vector.x < NEAR_ZERO_VALUE && vector.y < NEAR_ZERO_VALUE && vector.z < NEAR_ZERO_VALUE;
}


/** Gamma correction **/
linearToGamma :: (component : Vector3) -> Vector3
{
    return Vector3.{sqrt(component.x), sqrt(component.y), sqrt(component.z)};
}

gammaToLinear :: (component : Vector3) -> Vector3
{
    return Vector3.{component.x * component.x , component.y * component.y, component.z * component.z};
}
