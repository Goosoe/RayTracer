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

generateRandomInUnitCircle :: () -> Vector3
{
    while true
    {
        res := Vector3.{
            random_get_within_range(0, 1),
            random_get_within_range(0, 1),
            0
        };
        if length_squared(res) < 1.0
        {
            return unit_vector(res);
        }
    }
    return Vector3.{0, 0, 0};
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
    return abs(vector.x) < NEAR_ZERO_VALUE && abs(vector.y) < NEAR_ZERO_VALUE && abs(vector.z) < NEAR_ZERO_VALUE;
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

radiansToDegree :: (radians : float) -> float
{
    return radians * 180 / PI;
}

degreeToRadian :: (degrees : float) -> float
{
    return degrees * PI / 180; 
}

getAxis :: (axis : int, vector : Vector3) -> float
{
    if axis == 0 return vector.x;
    if axis == 1 return vector.y;
    if axis == 2 return vector.z;
    assert(false, "Axis value must be between [0,2]");
    return -1;
}

/* Creates an empty bounding box with min and max with arbitrarily large values*/
createBoundingBox :: () -> BoundingBox
{
    return BoundingBox.{
        make_vector3(FLOAT32_MAX),
        make_vector3(FLOAT32_MIN),
        STATIC_OBJECT
    };
}
