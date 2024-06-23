/**
*   Perlin noise implementation
*/

#import "Basic";
#import "Math";

PERLIN_POINT_COUNT :: 256;

PerlinNoise :: struct
{
    xPerm : [PERLIN_POINT_COUNT] int;
    yPerm : [PERLIN_POINT_COUNT] int;
    zPerm : [PERLIN_POINT_COUNT] int;
    rand : [PERLIN_POINT_COUNT] float;
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
    for 0 .. PERLIN_POINT_COUNT - 1 perlin.rand[it] = random_get_zero_to_one();

    fillPermArrays(*perlin);
    return perlin;
}

getNoise :: (perlinNoise : *PerlinNoise, pos : Vector3) -> float
{
    a : int = cast(int)(4 * pos.x);
    a &= PERLIN_POINT_COUNT - 1;
    b : int = cast(int)(4 * pos.y);
    b &= PERLIN_POINT_COUNT - 1;
    c : int = cast(int)(4 * pos.z);
    c &= PERLIN_POINT_COUNT - 1;
    return perlinNoise.rand[perlinNoise.xPerm[a] ^ perlinNoise.xPerm[b] ^ perlinNoise.xPerm[c]];
}

/* Linear interpolated noise*/
getLinearNoise :: (perlinNoise : *PerlinNoise, pos : Vector3) -> float
{
        //     static double trilinear_interp(double c[2][2][2], double u, double v, double w) {
        //     auto accum = 0.0;
        //     for (int i=0; i < 2; i++)
        //         for (int j=0; j < 2; j++)
        //             for (int k=0; k < 2; k++)
        //                 accum += (i*u + (1-i)*(1-u))*
        //                         (j*v + (1-j)*(1-v))*
        //                         (k*w + (1-k)*(1-w))*c[i][j][k];
        //
        //     return accum;
        // }

//        auto u = p.x() - floor(p.x());
//             auto v = p.y() - floor(p.y());
//             auto w = p.z() - floor(p.z());
    u := pos.x - floor(pos.x);
    v := pos.y - floor(pos.y);
    w := pos.z - floor(pos.z);

    i := cast(int) floor(pos.x);
    j := cast(int) floor(pos.y);
    k := cast(int) floor(pos.z);

    arr := [6] float;
    // for arr
    // {
    //     it = 
    // }
    // for 0 .. 1
    // {
    //     perlinNoise.xPerm[it] ^ perlinNoise.xPerm[it + 2] ^ perlinNoise.xPerm[it + 4];
    // }
//
//             auto i = static_cast<int>(floor(p.x()));
//             auto j = static_cast<int>(floor(p.y()));
//             auto k = static_cast<int>(floor(p.z()));
//             double c[2][2][2];
//
//             for (int di=0; di < 2; di++)
//                 for (int dj=0; dj < 2; dj++)
//                     for (int dk=0; dk < 2; dk++)
//                         c[di][dj][dk] = ranfloat[
//                             perm_x[(i+di) & 255] ^
//                             perm_y[(j+dj) & 255] ^
//                             perm_z[(k+dk) & 255]
//                         ];
//
//             return trilinear_interp(c, u, v, w);
    a : int = cast(int)(4 * pos.x);
    a &= PERLIN_POINT_COUNT - 1;
    b : int = cast(int)(4 * pos.y);
    b &= PERLIN_POINT_COUNT - 1;
    c : int = cast(int)(4 * pos.z);
    c &= PERLIN_POINT_COUNT - 1;
    return perlinNoise.rand[perlinNoise.xPerm[a] ^ perlinNoise.xPerm[b] ^ perlinNoise.xPerm[c]];
}
