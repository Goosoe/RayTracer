#import "Basic";
#import "Math";
#import "Random";

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
