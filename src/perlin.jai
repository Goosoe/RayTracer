/**
*   Perlin noise texture implementation that gives a marble like texture.
*/

#import "Basic";
#import "Math";

PERLIN_POINT_COUNT :: 256;

PerlinNoise :: struct
{
    xPerm : [PERLIN_POINT_COUNT] int;
    yPerm : [PERLIN_POINT_COUNT] int;
    zPerm : [PERLIN_POINT_COUNT] int;
    rand : [PERLIN_POINT_COUNT] Vector3;
}

makePerlinNoise :: () -> PerlinNoise
{
    permuteArray :: (arr : [] int)
    {
        for < PERLIN_POINT_COUNT - 1 .. 0
        {
            targetIdx : int = cast(int) random_get_within_range(0, cast(float)it);
            tempInt := arr[it];
            arr[it] = arr[targetIdx];
            arr[targetIdx] = tempInt;
        }
    }

    fillPermArrays :: (perlin : *PerlinNoise)
    {
        for 0 .. PERLIN_POINT_COUNT - 1 perlin.xPerm[it] = it;
        for 0 .. PERLIN_POINT_COUNT - 1 perlin.yPerm[it] = it;
        for 0 .. PERLIN_POINT_COUNT - 1 perlin.zPerm[it] = it;
        permuteArray(perlin.xPerm);
        permuteArray(perlin.yPerm);
        permuteArray(perlin.zPerm);
    }

    perlin := PerlinNoise.{};
    for 0 .. PERLIN_POINT_COUNT - 1 perlin.rand[it] = generateRandomVec3(-1, 1);

    fillPermArrays(*perlin);
    return perlin;
}


/* Gets a sum of *depth* linear interpolated noises with some added turbulence */
getPerlinTurbulence :: (texPerlin : *TexturePerlin, pos : Vector3, depth : int) -> float
{
    //TODO(Goose): There is a better way that we can do this... (arr of arrs)
    interp :: (arr: [2][2][2] Vector3, u: float, v: float, w: float) -> float
    {
        accum : float = 0.0;

        // Hermitian Smoothing
        uu : float = u * u * (3 - 2 * u);
        vv : float = v * v * (3 - 2 * v);
        ww : float = w * w * (3 - 2 * w);

        for i: 0..1
        {
            for j: 0..1
            {
                for k: 0..1
                {
                    vWeight : Vector3 = Vector3.{u - i, v - j, w - k};
                    accum += (i * uu + (1.0 - i) * (1.0 - uu)) *
                    (j * vv + (1.0 - j) * (1.0 - vv)) *
                    (k * ww + (1.0 - k) * (1.0 - ww)) *
                    dot_product(arr[i][j][k], vWeight);
                }
            }
        }
        return accum;
    }
    /* Linear interpolated noise, does not apply the scaling values*/
    getPerlinNoise :: (texPerlin : *TexturePerlin, pos : Vector3) -> float
    {

        u := pos.x - floor(pos.x);
        v := pos.y - floor(pos.y);
        w := pos.z - floor(pos.z);


        i := cast(int) floor(pos.x);
        j := cast(int) floor(pos.y);
        k := cast(int) floor(pos.z);

        //TODO(Goose): There is a better way that we can do this...
        arr : [2] [2] [2] Vector3;
        perlinNoise : *PerlinNoise = *texPerlin.perlin;
        for di: 0..1
        {
            for dj: 0..1
            {
                for dk: 0..1
                {
                    arr[di][dj][dk] =  perlinNoise.rand[
                        perlinNoise.xPerm[(i + di) & 255] ^
                        perlinNoise.yPerm[(j + dj) & 255] ^
                        perlinNoise.zPerm[(k + dk) & 255]
                    ];
                }
            }
        }
        return interp(arr, u, v, w);
    }

    accum : float = 0.0;
    weight : float = 1.0;
    tmpPos : Vector3 = pos;

    for 0..depth - 1
    {
        accum += weight * getPerlinNoise(texPerlin, tmpPos);
        weight *= 0.6;
        tmpPos *= 2;
    }

    return abs(accum);
}
